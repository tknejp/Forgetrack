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

/// Result returned by [CosmeticRevealEvaluator] for a single cosmetic.
///
/// Only [satisfiedConditions] and [totalConditions] are meaningful when
/// [state] is [CosmeticRevealState.partial]; they are zero otherwise.
class CosmeticRevealResult {
  const CosmeticRevealResult({
    required this.cosmeticId,
    required this.state,
    this.satisfiedConditions = 0,
    this.totalConditions = 0,
  });

  final String cosmeticId;
  final CosmeticRevealState state;

  /// Number of conditions already satisfied. Only meaningful for [CosmeticRevealState.partial].
  final int satisfiedConditions;

  /// Total number of conditions for the best-matching rule.
  final int totalConditions;

  @override
  String toString() =>
      'CosmeticRevealResult($cosmeticId, $state, $satisfiedConditions/$totalConditions)';
}
