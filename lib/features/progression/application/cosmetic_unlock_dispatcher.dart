import '../../../core/logging/app_log.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../domain/cosmetic_reward_table.dart';
import 'progression_engine.dart';

const _log = AppLogger('COSMETICS', scope: 'dispatch');

/// Diffs two [ProgressionEngineState] snapshots and dispatches cosmetic
/// unlocks for newly unlocked achievements and freshly reached levels.
///
/// Dependency direction: `progression` → `cosmetics`. The cosmetics feature
/// knows nothing about progression; this dispatcher is the only seam.
///
/// `unlock` is idempotent at the cosmetics repository layer (re-unlocking
/// an already-unlocked cosmetic is a no-op), so accidental double dispatch
/// is harmless.
class CosmeticUnlockDispatcher {
  CosmeticUnlockDispatcher({
    CosmeticRewardTable table = const CosmeticRewardTable(),
  }) : _table = table;

  final CosmeticRewardTable _table;
  CosmeticsProvider? _cosmetics;

  /// Wires the dispatcher to the live [CosmeticsProvider]. Until bound,
  /// [dispatch] is a no-op (we don't queue — unlocks earned while signed
  /// out / unbound are simply not dispatched).
  void bindCosmetics(CosmeticsProvider provider) {
    _cosmetics = provider;
  }

  Future<void> dispatch({
    ProgressionEngineState? previous,
    required ProgressionEngineState current,
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

    final prevUnlockedAchievementIds = previous == null
        ? current.achievements.where((a) => a.unlocked).map((a) => a.id).toSet()
        : previous.achievements
            .where((a) => a.unlocked)
            .map((a) => a.id)
            .toSet();

    final newlyUnlockedAchievements = current.achievements
        .where((a) => a.unlocked && !prevUnlockedAchievementIds.contains(a.id))
        .toList(growable: false);

    final prevLevel = previous?.profile.level ?? 0;
    final currentLevel = current.profile.level;
    final unlockedCosmeticIds =
        cosmetics.state?.unlocked.keys.toSet() ?? const <String>{};
    final pendingLevelUnlocks = <MapEntry<int, String>>[];

    for (var level = 1; level <= currentLevel; level++) {
      for (final cosmeticId in _table.cosmeticsForLevel(level)) {
        if (!unlockedCosmeticIds.contains(cosmeticId)) {
          pendingLevelUnlocks.add(MapEntry(level, cosmeticId));
        }
      }
    }

    if (newlyUnlockedAchievements.isEmpty &&
        prevLevel == currentLevel &&
        pendingLevelUnlocks.isEmpty) {
      _log.debug('dispatch — no progression changes since last sync');
      return;
    }

    _log.info(
      'dispatch — checking unlocks',
      payload:
          'achievements=${newlyUnlockedAchievements.length} levelDelta=$prevLevel→$currentLevel uid=${cosmetics.currentUid}',
    );

    for (final achievement in newlyUnlockedAchievements) {
      for (final cosmeticId in _table.cosmeticsForAchievement(achievement.id)) {
        await _unlock(
          cosmetics,
          cosmeticId: cosmeticId,
          sourceType: CosmeticUnlockSource.achievement.name,
          sourceId: achievement.id,
        );
      }
    }

    for (final entry in pendingLevelUnlocks) {
      await _unlock(
        cosmetics,
        cosmeticId: entry.value,
        sourceType: CosmeticUnlockSource.progressionLevel.name,
        sourceId: 'level_${entry.key}',
      );
    }
  }

  Future<void> _unlock(
    CosmeticsProvider cosmetics, {
    required String cosmeticId,
    required String sourceType,
    String? sourceId,
  }) async {
    final alreadyUnlocked =
        cosmetics.state?.unlocked.containsKey(cosmeticId) ?? false;
    _log.info(
      'unlock attempt',
      payload:
          'id=$cosmeticId source=$sourceType:${sourceId ?? '-'} alreadyUnlocked=$alreadyUnlocked',
    );
    try {
      await cosmetics.unlock(
        cosmeticId,
        sourceType: sourceType,
        sourceId: sourceId,
      );
      // CosmeticsProvider catches CosmeticsException and stores it in
      // errorMessage; surface it here so a bad mapping is visible in logs.
      final error = cosmetics.errorMessage;
      if (error != null) {
        _log.warn(
          'unlock reported error',
          payload: 'id=$cosmeticId source=$sourceType code=$error',
        );
      }
    } catch (e, st) {
      _log.error(
        'unlock crashed',
        payload: 'id=$cosmeticId source=$sourceType',
        err: e,
        stackTrace: st,
      );
    }
  }
}
