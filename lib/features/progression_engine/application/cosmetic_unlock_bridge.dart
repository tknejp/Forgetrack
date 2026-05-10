import 'dart:async';

import '../../../core/logging/app_log.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../domain/models/ledger_event.dart';
import '../domain/models/progression_resolution_result.dart';

const _log = AppLogger('ENGINE', scope: 'cosmeticBridge');

/// Bridges the new engine's cosmetic reward grants into the
/// CosmeticsProvider unlock pipeline. When the engine emits a
/// [RewardGrantEvent] of kind cosmetic, this bridge calls
/// `cosmeticsProvider.unlock(cosmeticId, sourceType, sourceId)` so
/// the cosmetic becomes available in inventory + drives the unlock
/// celebration via the existing cosmetics infrastructure.
///
/// Idempotent at the cosmetics layer (re-unlocking is a no-op).
/// Until bound the bridge silently drops events.
class CosmeticUnlockBridge {
  CosmeticsProvider? _cosmetics;

  void bindCosmetics(CosmeticsProvider provider) {
    _cosmetics = provider;
  }

  /// Dispatch every cosmetic-kind reward grant in [result] to the
  /// cosmetics provider. Source type tags ('engineNode' /
  /// 'engineLevel' / 'engineRelic' …) match the legacy
  /// CosmeticUnlockSource convention so devtools / inventory views
  /// can render them consistently.
  Future<void> dispatch(ProgressionResolutionResult result) async {
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
  }
}
