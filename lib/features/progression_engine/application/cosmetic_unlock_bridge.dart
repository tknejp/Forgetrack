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
      if (grant.event.rewardKind != RewardGrantKind.cosmetic) continue;
      final cosmeticId = grant.event.cosmeticId;
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
}
