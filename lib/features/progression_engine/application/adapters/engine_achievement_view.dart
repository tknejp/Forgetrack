import 'package:flutter/foundation.dart';

import '../../../../domain/progression/player/player_achievement_lifecycle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/display/progression_display_models.dart';
import '../../domain/display/progression_display_resolver.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../progression_engine_provider.dart';

/// Display-ready view of a V2 [Achievement] paired with the
/// player's current state from the ledger and the latest evaluator
/// outcomes.
///
/// Hero and Journey surfaces iterate these instead of reading
/// low-level engine state directly. The visual data is delegated to
/// [ProgressionDisplayResolver] so accent, badge emoji and
/// description copy match the social and quests screens.
@immutable
class EngineAchievementView {
  const EngineAchievementView({
    required this.node,
    required this.display,
    required this.unlocked,
    required this.unlockedAt,
    required this.currentValue,
    required this.targetValue,
    required this.progress,
    required this.levelTarget,
    this.isLockedByConditions = false,
    this.previewXp = 0,
  });

  /// Catalog entry this view wraps.
  final Achievement node;

  /// Resolver-derived display data (title, description, accent
  /// colour, emoji, subject label).
  final NodeDisplay display;

  final bool unlocked;
  final DateTime? unlockedAt;

  /// Current measured value for the bound objective. 0 for
  /// condition-only achievements.
  final int currentValue;

  /// Target value for the bound objective. 0 when the achievement is
  /// condition-driven only (welcome / level milestones / etc.).
  final int targetValue;

  /// 0..1 progress ratio. 1.0 when [unlocked], 0 when [targetValue]
  /// is 0 and the achievement is still locked.
  final double progress;

  /// For ids matching `level_<N>`, the encoded level number.
  /// Null for non-level achievements.
  final int? levelTarget;

  /// Phase 8 bridge field â€” true when the engine resolved this
  /// achievement to `NodeState.locked` (unlock conditions failed).
  /// Distinguishes locked-by-conditions rows from in-progress rows
  /// so the [lifecycle] getter can route to [AchievementLocked]
  /// instead of [AchievementInProgress]. Defaults to false for
  /// backwards compat with construction sites that haven't been
  /// updated yet.
  final bool isLockedByConditions;

  /// Phase 8 bridge field â€” level-scaled XP the player would receive
  /// (or did receive) for unlocking this achievement, computed via
  /// `ProgressionLevelPolicy.scaledRewardXp`. Mirrors
  /// `EngineQuestProgress.previewXp`. Drives
  /// [AchievementUnlocked.finalXp] in the lifecycle bridge. Defaults
  /// to 0 for construction sites that haven't wired the catalog
  /// reward XP yet.
  final int previewXp;

  String get id => node.id;

  /// Phase 8 bridge: derives the [PlayerAchievementLifecycle] sealed
  /// discriminator from the engine flags. Widgets pattern-match on
  /// the sealed type instead of inspecting `unlocked` /
  /// `isLockedByConditions` directly. Mapping precedence:
  ///
  ///   - `unlocked == true`         â†’ [AchievementUnlocked]
  ///   - `isLockedByConditions == true` â†’ [AchievementLocked]
  ///   - otherwise                   â†’ [AchievementInProgress]
  ///
  /// **Precedence rationale.** Unlike Phase 6 quests (where Locked
  /// wins over Claimed because side-quests of closed chapters must
  /// stay classified as locked even after the player finished them),
  /// achievements never re-lock â€” once the ledger has a completion
  /// event, the row is idempotently Unlocked. So Unlocked wins over
  /// Locked here. The 4-row mapping table is pinned by
  /// `test/features/progression_engine/engine_achievement_view_lifecycle_test.dart`.
  ///
  /// Phase 16+ retires this bridge once the engine produces
  /// `PlayerAchievement` directly.
  PlayerAchievementLifecycle get lifecycle {
    if (unlocked) {
      return AchievementUnlocked(
        finalXp: previewXp,
        unlockedAt: unlockedAt,
      );
    }
    if (isLockedByConditions) return const AchievementLocked();
    return AchievementInProgress(
      actual: currentValue.toDouble(),
      target: targetValue.toDouble(),
    );
  }
}

/// Builds the achievement view list for the hero screen and journey
/// adapter from the V2 provider. Returns one entry per
/// [Achievement] in the catalog whose display data the resolver
/// can produce.
List<EngineAchievementView> buildEngineAchievementViews(
  ProgressionEngineProvider provider,
  AppLocalizations l10n,
) {
  const resolver = ProgressionDisplayResolver();
  final completed = provider.completedNodeIds;
  final locked = provider.lockedNodeIds;

  final out = <EngineAchievementView>[];
  for (final node in provider.achievements) {
    final display = resolver.nodeDisplay(node.id, l10n);
    if (display == null) continue;

    final unlocked = completed.contains(node.id);
    final unlockedAt =
        unlocked ? provider.earliestCompletionAt(node.id) : null;

    final objective = provider.objectiveById(node.objectiveId);
    final target = objective?.targetValue.toInt() ?? 0;
    final actualRaw = provider.objectiveActualValue(node.objectiveId);
    final actual = actualRaw.isFinite ? actualRaw.round() : 0;

    final double progress;
    if (unlocked) {
      progress = 1.0;
    } else if (target <= 0) {
      progress = 0.0;
    } else {
      progress = (actual / target).clamp(0.0, 1.0).toDouble();
    }

    // Phase 8 bridge wiring. The catalog row's first XpReward drives
    // the previewXp value through the provider's public level-scaling
    // helper â€” same math the engine uses for quest preview pills. The
    // locked set comes from the engine resolver's NodeState classification
    // (a node failing its unlock conditions lands in [lockedNodeIds]).
    final baseXp = node.rewards
        .whereType<XpReward>()
        .fold<int>(0, (sum, r) => sum + r.amount);
    final previewXp = provider.scaledRewardXp(baseXp: baseXp);

    out.add(EngineAchievementView(
      node: node,
      display: display,
      unlocked: unlocked,
      unlockedAt: unlockedAt,
      currentValue: actual,
      targetValue: target,
      progress: progress,
      levelTarget: _levelTargetFromId(node.id),
      isLockedByConditions: !unlocked && locked.contains(node.id),
      previewXp: previewXp,
    ));
  }
  return out;
}

/// Returns `N` for `level_<N>` ids, otherwise null.
int? _levelTargetFromId(String id) {
  final match = _levelIdPattern.firstMatch(id);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

final RegExp _levelIdPattern = RegExp(r'^level_(\d+)$');
