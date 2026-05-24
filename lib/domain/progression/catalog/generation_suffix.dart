/// Generation suffix helpers for combo chain repeatability.
///
/// Combo chains are pre-allocated in [kComboGenerationCount]
/// generations. Generation 1 ids are the canonical template strings
/// (e.g. `combo_balanced_step_1`, `combo_balanced`). Generations 2..N
/// suffix `@<gen>` to the node id, chain id, and objective id
/// (e.g. `combo_balanced_step_1@2`, `combo_balanced@2`,
/// `combo_balanced_step_1_obj@2`).
///
/// Why pre-allocate instead of dynamic overlay: the catalog is a
/// const-time static singleton consulted from many sites. Pre-allocation
/// keeps every lookup O(1) and resolver / display logic generation-
/// oblivious — generation N nodes look identical to generation 1 nodes
/// to every consumer except for their distinct ids and prereqs.
///
/// Triple-combo achievements rely on [templateIdOf] in the evaluator's
/// `LifetimeCompletionsAmongMetric` branch so completions across every
/// generation roll up to the same lifetime tally.
library;

/// Separator between the template id and the generation index.
const String kGenerationSuffixSeparator = '@';

/// Number of pre-allocated combo chain generations. Each generation
/// adds 13 step / finale nodes across the three chains. At minimum
/// 13 days per generation (combo step `CooldownDays(1)`), so 50 gens
/// covers ~1.8 years of perfect daily play — comfortably past the
/// `triple_combo_100` ceiling (≈ 15 gens). Bump in a content drop if
/// telemetry shows anyone approaching the cap.
const int kComboGenerationCount = 50;

/// Strips a `@<gen>` suffix and returns the template id. For ids that
/// were never suffixed (generation 1 ids, every non-combo node id),
/// returns the id unchanged.
String templateIdOf(String id) {
  final i = id.indexOf(kGenerationSuffixSeparator);
  if (i < 0) return id;
  return id.substring(0, i);
}

/// Appends a `@<gen>` suffix to the template id. Returns the template
/// unchanged for `gen == 1` so generation 1 keeps the canonical id
/// (back-compatible with every ledger event emitted before this lands).
String withGenerationSuffix(String templateId, int gen) {
  if (gen <= 1) return templateId;
  return '$templateId$kGenerationSuffixSeparator$gen';
}

/// Parses the generation index out of a suffixed id. Returns 1 when
/// the id has no suffix (canonical generation).
int generationOf(String id) {
  final i = id.indexOf(kGenerationSuffixSeparator);
  if (i < 0) return 1;
  final tail = id.substring(i + 1);
  return int.tryParse(tail) ?? 1;
}
