import 'package:flutter/foundation.dart';

import '../../../progression/domain/progression_models.dart' show ProgressionDomain;
import 'objective_metric.dart';
import 'objective_operator.dart';
import 'objective_scope.dart';

export '../../../progression/domain/progression_models.dart' show ProgressionDomain;

/// Pure machine-readable condition. **No UI, no rewards, no rarity, no
/// display strings.** Display lives on [ProgressionNode], rewards live
/// on the node that references this objective.
///
/// Multiple nodes may reference the same objective id — that is the
/// whole point: "lifetime steps >= 10M" is one condition; the quest
/// reward, the achievement unlock and the milestone are three nodes
/// pointing at it. The evaluator computes the outcome once.
@immutable
class ObjectiveDefinition {
  const ObjectiveDefinition({
    required this.id,
    required this.metric,
    required this.scope,
    required this.operator,
    required this.targetValue,
    this.domain,
    this.upperTargetValue,
    this.toleranceRatio = 0,
    this.debugLabel,
  });

  final String id;
  final ObjectiveMetric metric;
  final ObjectiveScope scope;
  final ObjectiveOperator operator;
  final double targetValue;

  /// Optional domain tag (steps / nutrition / sleep / activity /
  /// body). Used by streak-by-domain aggregation and by display
  /// helpers that want to colour or icon objectives consistently.
  /// Cross-domain objectives (totalXp, rewardCount) leave this null.
  final ProgressionDomain? domain;

  /// Required for [ObjectiveOperator.betweenInclusive], otherwise null.
  final double? upperTargetValue;

  /// Required for the tolerance operators, otherwise 0.
  final double toleranceRatio;

  /// Human-readable label for debug overlays / catalog listings. NEVER
  /// shown to the player — that is what `ProgressionNode.titleKey` is
  /// for. Optional; falls back to [id] when null.
  final String? debugLabel;
}
