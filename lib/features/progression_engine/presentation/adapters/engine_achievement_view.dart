import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/display/progression_display_models.dart';
import '../../domain/display/progression_display_resolver.dart';
import '../../domain/models/progression_node_definition.dart';

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

  String get id => node.id;
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

    out.add(EngineAchievementView(
      node: node,
      display: display,
      unlocked: unlocked,
      unlockedAt: unlockedAt,
      currentValue: actual,
      targetValue: target,
      progress: progress,
      levelTarget: _levelTargetFromId(node.id),
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
