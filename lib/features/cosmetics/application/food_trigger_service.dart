import '../../nutrition/domain/calorie_entry.dart';
import '../domain/cosmetic_models.dart';

/// Snapshot of what a companion's [FoodTriggerReward] is owed against
/// today's nutrition log, after subtracting whatever was already
/// claimed earlier on the same day.
///
/// Held as plain data so the UI can decide on its own how to surface
/// it (hidden when [claimableXp] is 0, pill + dot when positive) and
/// the service stays a pure function.
class FoodTriggerSnapshot {
  const FoodTriggerSnapshot({
    required this.companion,
    required this.matchedEntryCount,
    required this.sampleEntryName,
    required this.grossXp,
    required this.alreadyClaimedXp,
    required this.claimableXp,
  });

  /// The companion this snapshot was computed for. Carried so callers
  /// don't have to thread the equipped-companion lookup separately
  /// when invoking [FoodTriggerService.claim].
  final Companion companion;

  /// Number of distinct [CalorieEntry] rows whose food name matched
  /// the trigger's keyword set today.
  final int matchedEntryCount;

  /// Name of one of the matched entries, for UI flavor ("Plechovka
  /// cinkla: Monster Energy Ultra Red"). Empty when no matches.
  final String sampleEntryName;

  /// XP the companion would owe with no cap and nothing previously
  /// claimed: `perEntryXp × matchedEntryCount`. Exposed for UI copy
  /// that explains why the cap was hit ("3 plechovky · max 75 XP").
  final int grossXp;

  /// XP already claimed today for this companion's trigger. Subtracted
  /// from the capped gross to get [claimableXp].
  final int alreadyClaimedXp;

  /// XP the player can claim *right now*. Zero means "nothing to
  /// show" — UI hides the pill and the chevron dot when this is 0.
  /// The pill is the only surface; locked / claimed states are
  /// intentionally invisible per the product call ("ukázat jen
  /// claimable").
  final int claimableXp;

  bool get hasClaimable => claimableXp > 0;
}

/// Pure evaluator for [FoodTriggerReward]. No I/O, no storage — the
/// caller passes today's log + already-claimed total and receives a
/// snapshot it can act on. Persistence of "already claimed" lives in
/// the provider that wraps this service.
///
/// Future variants of [FoodTriggerReward] (per-meal, macro-driven,
/// streak-driven) extend the same `switch` here; the rest of the
/// pipeline (provider, UI, grant path) does not have to change.
class FoodTriggerService {
  const FoodTriggerService();

  /// Build a snapshot for [companion] against [todayLog].
  ///
  /// Returns null when the companion has no [Companion.foodTrigger]
  /// — callers can skip the UI entirely in that branch. A returned
  /// snapshot with `claimableXp == 0` (no matches, or daily cap
  /// already reached) is also valid and intentionally distinct from
  /// null: it means "trigger exists, just nothing right now".
  FoodTriggerSnapshot? evaluate({
    required Companion companion,
    required List<CalorieEntry> todayLog,
    required int alreadyClaimedXpToday,
  }) {
    final trigger = companion.foodTrigger;
    if (trigger == null) return null;

    var matchCount = 0;
    var sample = '';
    for (final entry in todayLog) {
      if (trigger.matchesEntry(entry.food.name)) {
        matchCount += 1;
        if (sample.isEmpty) sample = entry.food.name;
      }
    }

    final gross = trigger.perEntryXp * matchCount;
    final capped =
        gross > trigger.perDayMaxXp ? trigger.perDayMaxXp : gross;
    var claimable = capped - alreadyClaimedXpToday;
    if (claimable < 0) claimable = 0;

    return FoodTriggerSnapshot(
      companion: companion,
      matchedEntryCount: matchCount,
      sampleEntryName: sample,
      grossXp: gross,
      alreadyClaimedXp: alreadyClaimedXpToday,
      claimableXp: claimable,
    );
  }
}
