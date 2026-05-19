import '../../cosmetics/domain/cosmetic_unlock_snapshot.dart';
import '../domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import '../domain/repository/ledger_snapshot.dart';

/// V2 â†’ [CosmeticUnlockSnapshot] adapter.
///
/// Drives the cosmetics inventory's partial-reveal UI (the
/// "still locked, X/Y conditions met" hints rendered by
/// `CosmeticRevealEvaluator`). Cosmetics own the *unlock state* â€” V2
/// is the source of truth for the *counters* the reveal evaluator reads.
///
/// Counters are derived from the engine ledger plus the static catalog:
/// quest counts walk [LedgerSnapshot.nodeCompletions] filtered to
/// [Quest] ids, "active days" is the distinct calendar-day count
/// across every ledger event, and level comes from the resolved
/// profile.
///
/// Perfect-day / perfect-week counters stay at 0 until V2 grows an
/// equivalent metric; the legacy implementation also returned 0 for
/// these so behaviour is preserved.
class CosmeticRevealSnapshotBuilder {
  const CosmeticRevealSnapshotBuilder();

  CosmeticUnlockSnapshot build({
    required int level,
    required LedgerSnapshot? ledger,
    required Set<String> ownedCosmeticIds,
  }) {
    if (ledger == null) {
      return CosmeticUnlockSnapshot(
        level: level,
        activeDaysCount: 0,
        completedDailyQuests: 0,
        completedWeeklyQuests: 0,
        totalCompletedQuests: 0,
        firstDailyQuestEver: false,
        firstWeeklyQuestEver: false,
        perfectDaysCount: 0,
        perfectWeeksCount: 0,
        ownedCosmeticIds: ownedCosmeticIds,
      );
    }

    var dailyCount = 0;
    var weeklyCount = 0;
    var totalCount = 0;
    for (final event in ledger.nodeCompletions) {
      final bucket = _bucketByQuestId[event.nodeId];
      if (bucket == null) continue;
      totalCount++;
      if (bucket == QuestDisplayBucket.daily) {
        dailyCount++;
      } else if (bucket == QuestDisplayBucket.weekly) {
        weeklyCount++;
      }
    }

    final activeDays = <DateTime>{};
    for (final event in ledger.nodeCompletions) {
      activeDays.add(_dateOf(event.timestamp));
    }
    for (final grant in ledger.rewardGrants) {
      activeDays.add(_dateOf(grant.timestamp));
    }

    return CosmeticUnlockSnapshot(
      level: level,
      activeDaysCount: activeDays.length,
      completedDailyQuests: dailyCount,
      completedWeeklyQuests: weeklyCount,
      totalCompletedQuests: totalCount,
      firstDailyQuestEver: dailyCount >= 1,
      firstWeeklyQuestEver: weeklyCount >= 1,
      perfectDaysCount: 0,
      perfectWeeksCount: 0,
      ownedCosmeticIds: ownedCosmeticIds,
    );
  }

  static DateTime _dateOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Quest id â†’ display bucket. Computed once from the static catalog
  /// since the catalog is const.
  static final Map<String, QuestDisplayBucket> _bucketByQuestId = {
    for (final node in const ProgressionEntryCatalog().build())
      if (node is Quest) node.id: node.displayBucket,
  };
}
