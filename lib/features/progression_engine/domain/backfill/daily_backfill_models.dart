import 'package:meta/meta.dart';

import '../../../health_connect/domain/activity_record.dart';
import '../activity_claim/activity_claim_state.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';

/// How [DailyGoalClaimItem.actualValue] / [DailyGoalClaimItem.targetValue]
/// should be formatted for display. Mirrors
/// [EngineQuestValueUnit] semantics but separate so callers don't need
/// to import the provider header just for the enum.
enum DailyGoalValueUnit {
  /// Render as a plain integer count (steps, kcal, grams).
  count,

  /// Stored in minutes; render as `H h` for the user (sleep goal).
  minutes,

  /// Boolean-ish 0/1 with no unit (weight logged today).
  flag,
}

/// One daily-goal row inside a backfill day card. Resolved from the
/// catalog objective (target / operator / tolerance), the player's
/// historical data, and the engine's ledger (claim state).
@immutable
class DailyGoalClaimItem {
  const DailyGoalClaimItem({
    required this.node,
    required this.domain,
    required this.actualValue,
    required this.targetValue,
    required this.valueUnit,
    required this.isMet,
    required this.previewXp,
    required this.isClaimed,
    required this.isWithinWindow,
    required this.hasData,
  });

  /// Catalog node — UI resolves the title via `node.titleKey(l10n)`
  /// and pulls any other node-level fields (asset, description) on
  /// demand. Provider can't depend on the l10n delegate.
  final Quest node;

  String get nodeId => node.id;

  /// Visual domain (steps / nutrition / sleep / body / activity) so the
  /// row picks up the right icon + accent.
  final ProgressionDomain domain;

  /// Player's measured value for this day.
  final double actualValue;
  final double targetValue;
  final DailyGoalValueUnit valueUnit;

  /// True when the objective resolves as satisfied (operator + target
  /// + tolerance applied). Independent of claim state — a goal can be
  /// met but not yet claimed, or claimed even though the underlying
  /// data is missing today (an old grant).
  final bool isMet;

  /// XP the player would receive if they claimed now (level-scaled).
  /// When [isClaimed] is true this is the originally granted amount
  /// from the ledger, so the value stays stable across level-ups.
  final int previewXp;

  /// True when a claim ledger event exists with `periodKey == "yyyy-MM-dd"`
  /// for this node.
  final bool isClaimed;

  /// True when the day falls inside [HistoricalClaimWindow]. Outside
  /// the window the pill renders as locked even if the goal was met.
  final bool isWithinWindow;

  /// False when the underlying data source has no record for this day
  /// (e.g. nutrition for a day the player didn't log anything). Lets
  /// the UI suppress dead "0 / 2000 kcal" rows that aren't actionable.
  final bool hasData;

  /// Convenience: can the player tap the pill *right now*?
  bool get isClaimable => isMet && !isClaimed && isWithinWindow && previewXp > 0;
}

/// One daily-section quest row inside a backfill day card — daily
/// challenge, combo chain step, or chapter side quest that was
/// offered on this day via [QuestOfferedEvent]. Compact compared to
/// [DailyGoalClaimItem]: no actual / target value (the underlying
/// objective handles satisfaction internally) — just title + pill.
@immutable
class DailyQuestClaimItem {
  const DailyQuestClaimItem({
    required this.node,
    required this.domain,
    required this.isCompleted,
    required this.isAvailableForClaim,
    required this.previewXp,
    required this.isClaimed,
    required this.isWithinWindow,
  });

  /// Catalog node — UI resolves `node.titleKey(l10n)` etc.
  final Quest node;

  String get nodeId => node.id;

  /// Domain inherited from the bound objective for icon / accent.
  final ProgressionDomain domain;

  /// Engine flag — true when the bound objective has fired its
  /// completion event for the relevant period.
  final bool isCompleted;

  /// Engine flag — true when the manual-claim pill should fire.
  /// Subsumed by [isClaimable] (which also gates on window + xp).
  final bool isAvailableForClaim;

  /// Level-scaled XP the player would receive on claim. Frozen on the
  /// granted amount once [isClaimed] is true so a level-up doesn't
  /// retroactively change the "+N XP" pill the player saw.
  final int previewXp;

  /// True when the matching [NodeClaimEvent] is in the ledger.
  final bool isClaimed;

  /// True when [DailyBackfillEntry.date] is inside
  /// [HistoricalClaimWindow]. Outside the window the pill renders as
  /// locked even if the quest is otherwise available.
  final bool isWithinWindow;

  /// Can the player tap the pill right now?
  bool get isClaimable =>
      isAvailableForClaim && !isClaimed && isWithinWindow && previewXp > 0;
}

/// One day in the backfill section. Aggregates per-goal rows + per-
/// activity rows so the card can render both in a single expanded body
/// and compute footer totals (claim-all XP, pending count) in one
/// place.
@immutable
class DailyBackfillEntry {
  const DailyBackfillEntry({
    required this.date,
    required this.isWithinWindow,
    required this.dailyGoals,
    required this.dailyQuests,
    required this.activities,
  });

  /// Calendar day this entry summarises (00:00 local).
  final DateTime date;

  /// Whether [date] falls inside [HistoricalClaimWindow]. Rolls up
  /// down into each [DailyGoalClaimItem.isWithinWindow] and every
  /// [ActivityClaimState.isWithinWindow] so the UI can also use the
  /// day-level flag as a quick "anything actionable today" check.
  final bool isWithinWindow;

  final List<DailyGoalClaimItem> dailyGoals;
  final List<DailyQuestClaimItem> dailyQuests;
  final List<ActivityClaimState> activities;

  /// Records exposed by the activity rows — convenient when the
  /// "Claim all" footer wants to feed them straight to
  /// `claimActivity`.
  Iterable<ActivityRecord> get activityRecords =>
      activities.map((a) => a.record);

  /// Sum of XP the player would *gain* by tapping "Claim all" on this
  /// day: every claimable goal + every claimable quest + every
  /// claimable activity.
  int get claimableXp {
    var sum = 0;
    for (final g in dailyGoals) {
      if (g.isClaimable) sum += g.previewXp;
    }
    for (final q in dailyQuests) {
      if (q.isClaimable) sum += q.previewXp;
    }
    for (final a in activities) {
      if (a.isClaimable) sum += a.previewXp;
    }
    return sum;
  }

  /// Sum of XP already credited on this day (pills currently in the
  /// claimed state). Drives the "+150 / +320 XP" header summary.
  int get claimedXp {
    var sum = 0;
    for (final g in dailyGoals) {
      if (g.isClaimed) sum += g.previewXp;
    }
    for (final q in dailyQuests) {
      if (q.isClaimed) sum += q.previewXp;
    }
    for (final a in activities) {
      if (a.isClaimed) sum += a.previewXp;
    }
    return sum;
  }

  /// Count of pending claim affordances. Drives the count chip in the
  /// collapsed header.
  int get pendingCount {
    var n = 0;
    for (final g in dailyGoals) {
      if (g.isClaimable) n += 1;
    }
    for (final q in dailyQuests) {
      if (q.isClaimable) n += 1;
    }
    for (final a in activities) {
      if (a.isClaimable) n += 1;
    }
    return n;
  }

  /// True when the day has at least one met goal *or* one quest
  /// offered *or* one activity — i.e. there is something to surface to
  /// the player. Empty days (player didn't log anything and the
  /// rotation didn't pick anything either) can be hidden by the
  /// caller.
  bool get hasAnyContent {
    for (final g in dailyGoals) {
      if (g.hasData) return true;
    }
    if (dailyQuests.isNotEmpty) return true;
    return activities.isNotEmpty;
  }
}

