/// How a locked cosmetic is presented to the player.
///
/// The evaluator derives this from the catalog definition, unlock rules, owned
/// cosmetics, and the progression snapshot. The UI never computes reveal state
/// itself — it only consumes [CosmeticRevealResult].
enum CosmeticRevealState {
  /// Player owns this cosmetic. Shown normally.
  unlocked,

  /// Locked, but the cosmetic's name and type are shown. Standard locked
  /// presentation with a generic hint when available.
  visibleLocked,

  /// Locked and not yet revealed. Shown as a ??? placeholder without name,
  /// asset, or unlock condition. Used for prestige / compound rewards the
  /// player hasn't made meaningful progress toward.
  hidden,

  /// Locked, but the player has partially satisfied a compound unlock rule.
  /// Shown with the cosmetic's real name and a "{satisfied}/{total}" progress
  /// indicator. Never shown for single-condition rules.
  partial,
}

/// A single row in a companion unlock requirements checklist.
///
/// [conditionId] is the stable id from [CosmeticUnlockCondition.id]:
///   - `'level_at_least_N'` for a level gate
///   - `'owns_<cosmeticId>'` for a relic ownership requirement
///
/// The UI translates [conditionId] to a localised label; the domain carries
/// only the raw id so the evaluator stays free of Flutter/l10n imports.
class CosmeticRevealConditionRow {
  const CosmeticRevealConditionRow({
    required this.conditionId,
    required this.met,
  });

  final String conditionId;
  final bool met;
}

/// Result returned by [CosmeticRevealEvaluator] for a single cosmetic.
///
/// Only [satisfiedConditions] and [totalConditions] are meaningful when
/// [state] is [CosmeticRevealState.partial]; they are zero otherwise.
///
/// [conditionRows] is populated for companion cosmetics whose state is
/// [CosmeticRevealState.visibleLocked] or [CosmeticRevealState.partial] —
/// it drives the requirements checklist in the details sheet.
class CosmeticRevealResult {
  const CosmeticRevealResult({
    required this.cosmeticId,
    required this.state,
    this.satisfiedConditions = 0,
    this.totalConditions = 0,
    this.conditionRows,
  });

  final String cosmeticId;
  final CosmeticRevealState state;

  /// Number of conditions already satisfied. Only meaningful for [CosmeticRevealState.partial].
  final int satisfiedConditions;

  /// Total number of conditions for the best-matching rule.
  final int totalConditions;

  /// Per-condition checklist rows. Non-null for companion cosmetics when
  /// [state] is [visibleLocked] or [partial].
  final List<CosmeticRevealConditionRow>? conditionRows;

  @override
  String toString() =>
      'CosmeticRevealResult($cosmeticId, $state, $satisfiedConditions/$totalConditions)';
}
