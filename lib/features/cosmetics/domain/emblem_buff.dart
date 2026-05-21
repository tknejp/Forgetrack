// Emblem XP buff domain model — see docs/emblem_buffs/archive/plan.md.
//
// An [Emblem] in the catalog may carry a non-null [EmblemBuff]. At grant
// time the progression engine builds an [EmblemBuffContext] for the
// reward being granted and asks each equipped buff to resolve its
// percent contribution. Contributions are summed and applied additively
// (see locked design decisions in the plan).

import '../../health_connect/domain/player_goal.dart';
import 'cosmetic_catalog.dart';
import 'cosmetic_models.dart';

/// Granularity carrier — the *thing* a buff can target.
///
/// `RewardSourceKind` was too coarse (e.g. `nutritionXp` lumps all five
/// macro goals together); `GoalMetric` already has the right
/// resolution, so we re-use it inside [DailyGoalTarget] and add a
/// separate [ComboQuestTarget] variant for combo-bucket quest claims.
sealed class EmblemTarget {
  const EmblemTarget();
}

class DailyGoalTarget extends EmblemTarget {
  const DailyGoalTarget(this.metric);
  final GoalMetric metric;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyGoalTarget && other.metric == metric);

  @override
  int get hashCode => metric.hashCode;
}

class ComboQuestTarget extends EmblemTarget {
  const ComboQuestTarget();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ComboQuestTarget;

  @override
  int get hashCode => (ComboQuestTarget).hashCode;
}

/// Per-claim evaluation context handed to [EmblemBuff.resolvePercent].
class EmblemBuffContext {
  const EmblemBuffContext({
    required this.target,
    required this.rewardSourceKind,
  });

  final EmblemTarget target;
  final RewardSourceKind rewardSourceKind;
}

/// Sealed buff hierarchy attached to an [Emblem].
sealed class EmblemBuff {
  const EmblemBuff();

  /// Returns the percent contribution (0..100) this buff adds to the
  /// XP for the given claim context. `0` means "does not apply".
  int resolvePercent(EmblemBuffContext context);
}

class PerTargetEmblemBuff extends EmblemBuff {
  const PerTargetEmblemBuff({required this.target, required this.percent});

  final EmblemTarget target;
  final int percent;

  @override
  int resolvePercent(EmblemBuffContext context) =>
      context.target == target ? percent : 0;
}

/// Endgame buff that applies whenever the claim's [EmblemBuffContext.target]
/// is covered by some [PerTargetEmblemBuff] in the active catalogue.
///
/// "Covered" is derived from the catalog itself — [coveredTargets] walks
/// every [Emblem] cosmetic and collects the target of each
/// [PerTargetEmblemBuff] it carries. Adding a new per-target emblem to
/// the catalog automatically extends the blanket coverage; there is no
/// parallel list to keep in sync.
class BlanketEmblemBuff extends EmblemBuff {
  const BlanketEmblemBuff({required this.percent});

  final int percent;

  /// Every [EmblemTarget] that some [PerTargetEmblemBuff] in
  /// [CosmeticCatalog] currently buffs. Derived once on first read
  /// from the catalog — guaranteed to be in sync with the per-target
  /// emblems by construction. See class doc for rationale.
  static List<EmblemTarget> get coveredTargets => _coveredTargetsCache ??=
      List<EmblemTarget>.unmodifiable(_computeCoveredTargets());

  static List<EmblemTarget>? _coveredTargetsCache;

  static Iterable<EmblemTarget> _computeCoveredTargets() sync* {
    final seen = <EmblemTarget>{};
    for (final emblem in CosmeticCatalog().emblems) {
      final buff = emblem.buff;
      if (buff is PerTargetEmblemBuff && seen.add(buff.target)) {
        yield buff.target;
      }
    }
  }

  static bool covers(EmblemTarget target) => coveredTargets.contains(target);

  @override
  int resolvePercent(EmblemBuffContext context) =>
      covers(context.target) ? percent : 0;
}
