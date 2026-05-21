/// Catalog-side declaration that a [Companion] grants bonus XP for
/// specific foods appearing in the player's nutrition log.
///
/// Distinct from [CompanionBuff]: a buff *multiplies* XP that the
/// progression engine already grants from some other claim (daily
/// goal, quest, chapter, …). A food trigger is a **standalone grant**
/// driven by what is in the player's calorie log on a given day — no
/// passive engine grant to multiply. Keeping the two concerns apart
/// means existing buff plumbing (chip widget, exhaustive switches,
/// coverage tests) stays untouched.
///
/// Sealed so future variants (per-meal trigger, macro-threshold
/// trigger, weekly-streak food trigger) slot in without callers
/// peeking at internals — they only need [resolveClaim] /
/// [matchesEntry] semantics, which every variant must implement.
sealed class FoodTriggerReward {
  const FoodTriggerReward();

  /// True when the given food name (raw, as stored on the calorie
  /// entry) is a match for this trigger. Used by the service to
  /// count today's matches.
  bool matchesEntry(String foodName);

  /// XP per matching entry. Caps are applied by the service, not
  /// here — keeping the math centralised so the service is the
  /// single seat of "how much was already claimed today".
  int get perEntryXp;

  /// Hard ceiling for a single day's claim, regardless of how many
  /// matching entries the player logs. Prevents farming by spamming
  /// the same food.
  int get perDayMaxXp;
}

/// Trigger that matches by case-insensitive substring against any of
/// [keywords]. The match runs over the raw food title the player
/// saw when they logged the entry — KT foodstuff titles today, any
/// future nutrition source the provider plugs in tomorrow. The data
/// layer's normalisation (or lack of it) is exactly what the
/// catalog row authors against.
///
/// Multiple keywords are OR-ed — useful for cs/en synonyms ("mléko"
/// + "milk") or brand/category alternates ("monster", "monster
/// energy"). The first non-empty match wins for diagnostics; the
/// service does not weight one keyword over another.
final class FoodKeywordTrigger extends FoodTriggerReward {
  const FoodKeywordTrigger({
    required this.keywords,
    required this.perEntryXp,
    required this.perDayMaxXp,
  })  : assert(perEntryXp > 0, 'perEntryXp must be positive'),
        assert(perDayMaxXp >= perEntryXp,
            'perDayMaxXp must allow at least one full entry grant');

  /// Substrings checked case-insensitively against `food.name`.
  /// Catalog authors pick the most natural surface form (cs preferred
  /// for cs-only foods, brand name verbatim for branded items).
  final List<String> keywords;

  @override
  final int perEntryXp;

  @override
  final int perDayMaxXp;

  @override
  bool matchesEntry(String foodName) {
    if (foodName.isEmpty) return false;
    final hay = foodName.toLowerCase();
    for (final kw in keywords) {
      if (kw.isEmpty) continue;
      if (hay.contains(kw.toLowerCase())) return true;
    }
    return false;
  }
}
