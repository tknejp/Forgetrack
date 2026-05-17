import 'dart:async';

import '../../../core/logging/app_log.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../domain/models/ledger_event.dart';
import '../domain/models/progression_resolution_result.dart';
import '../domain/repository/ledger_snapshot.dart';
import 'cosmetic_reveal_snapshot_builder.dart';

const _log = AppLogger('ENGINE', scope: 'cosmeticBridge');

/// Bridges the V2 engine's cosmetic reward grants into the
/// CosmeticsProvider unlock pipeline.
///
/// Two responsibilities:
///
/// 1. When the engine emits a [RewardGrantEvent] of kind cosmetic, call
///    `cosmeticsProvider.unlock(cosmeticId, sourceType, sourceId)` so
///    the cosmetic becomes available in inventory and drives the
///    unlock celebration via the existing cosmetics infrastructure.
/// 2. Refresh the cosmetics reveal snapshot (level / quest counters /
///    active-days) so the inventory's partial-reveal UI reads V2 state
///    instead of the legacy progression engine.
///
/// Idempotent at the cosmetics layer (re-unlocking is a no-op).
/// Until bound the bridge silently drops events.
class CosmeticUnlockBridge {
  CosmeticUnlockBridge({
    CosmeticRevealSnapshotBuilder snapshotBuilder =
        const CosmeticRevealSnapshotBuilder(),
  }) : _snapshotBuilder = snapshotBuilder;

  CosmeticsProvider? _cosmetics;
  final CosmeticRevealSnapshotBuilder _snapshotBuilder;

  void bindCosmetics(CosmeticsProvider provider) {
    _cosmetics = provider;
  }

  /// Dispatch every cosmetic-kind reward grant in [result] to the
  /// cosmetics provider, then refresh the cosmetics reveal snapshot
  /// from the engine's ledger so the partial-reveal UI sees the just-
  /// updated counters.
  ///
  /// Source type tags ('engineNode' / 'engineLevel' / 'engineRelic' …)
  /// match the legacy CosmeticUnlockSource convention so devtools /
  /// inventory views can render them consistently.
  Future<void> dispatch(
    ProgressionResolutionResult result, {
    LedgerSnapshot? ledger,
    int? level,
  }) async {
    final cosmetics = _cosmetics;
    if (cosmetics == null) {
      _log.debug('dispatch skipped — no CosmeticsProvider bound');
      return;
    }
    if (cosmetics.currentUid == null) {
      _log.debug('dispatch skipped — no uid bound on CosmeticsProvider');
      return;
    }

    for (final grant in result.grantedRewards) {
      // Two grant kinds map to a cosmetics inventory unlock:
      //  * `cosmetic` — every Tier-1 reward (frame / relic / background
      //    / emblem / title) carries its cosmetic id directly.
      //  * `companionAvailability` — manual-claim companion nodes
      //    emit this kind when the player claims; the `companionId`
      //    is the same string as the companion's cosmetic id (see
      //    `companions_content.dart` — id == companionId by
      //    construction). Without this branch the claim animation
      //    runs but the inventory entry never flips to unlocked,
      //    leaving the companion permanently un-equippable.
      final cosmeticId = _cosmeticIdForUnlock(grant.event);
      if (cosmeticId == null) continue;
      try {
        await cosmetics.unlock(
          cosmeticId,
          sourceType: 'engineNode',
          sourceId: grant.event.nodeId,
        );
      } catch (e, st) {
        _log.error(
          'unlock crashed',
          payload: 'id=$cosmeticId node=${grant.event.nodeId}',
          err: e,
          stackTrace: st,
        );
      }
    }

    // Refresh the reveal snapshot after unlocks land so condition
    // checks like `ownsCosmetic(...)` immediately see the new state.
    if (ledger != null && level != null) {
      final owned = cosmetics.state?.unlocked.keys.toSet() ?? const <String>{};
      cosmetics.cacheSnapshot(
        _snapshotBuilder.build(
          level: level,
          ledger: ledger,
          ownedCosmeticIds: owned,
        ),
      );
    }
  }

  /// Walks the entire ledger and re-applies every cosmetic reward grant
  /// to the bound CosmeticsProvider.
  ///
  /// Use this after a cloud pull-and-merge: the engine's `evaluate()`
  /// only emits grants for events it just produced, so historical
  /// cosmetic grants that arrived in the merged ledger never reach the
  /// CosmeticsProvider via the normal [dispatch] path. Without this
  /// step a fresh install or second device would have the engine
  /// ledger restored but the cosmetics inventory still empty.
  ///
  /// Idempotent — `cosmetics.unlock` is a no-op when the cosmetic is
  /// already in the unlocked set.
  Future<void> reapplyHistoricalCosmetics(LedgerSnapshot ledger) async {
    final cosmetics = _cosmetics;
    if (cosmetics == null || cosmetics.currentUid == null) {
      _log.debug('reapplyHistoricalCosmetics skipped — no cosmetics binding');
      return;
    }

    var applied = 0;
    for (final grant in ledger.rewardGrants) {
      final cosmeticId = _cosmeticIdForUnlock(grant);
      if (cosmeticId == null) continue;
      if (cosmetics.state?.unlocked.containsKey(cosmeticId) ?? false) continue;
      try {
        await cosmetics.unlock(
          cosmeticId,
          sourceType: 'engineNode',
          sourceId: grant.nodeId,
        );
        applied++;
      } catch (e, st) {
        _log.error(
          'reapply unlock crashed',
          payload: 'id=$cosmeticId node=${grant.nodeId}',
          err: e,
          stackTrace: st,
        );
      }
    }
    if (applied > 0) {
      _log.info(
        'historical cosmetic grants reapplied',
        payload: 'applied=$applied total=${ledger.rewardGrants.length}',
      );
    }
  }

  /// Returns the cosmetic id to unlock for a reward grant, or null when
  /// the grant doesn't represent a wearable inventory entry (XP,
  /// chapter unlock). Companion-availability grants resolve to the
  /// companion id, which doubles as the cosmetic id by catalog
  /// construction.
  static String? _cosmeticIdForUnlock(RewardGrantEvent event) {
    switch (event.rewardKind) {
      case RewardGrantKind.cosmetic:
        return event.cosmeticId;
      case RewardGrantKind.companionAvailability:
        return event.companionId;
      case RewardGrantKind.xp:
      case RewardGrantKind.chapterUnlock:
      case RewardGrantKind.title:
      case RewardGrantKind.emblem:
      case RewardGrantKind.relic:
        return null;
    }
  }
}
