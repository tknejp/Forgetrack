import '../progression_models.dart';

class ProgressionRewardFinalizationPolicy {
  const ProgressionRewardFinalizationPolicy({
    this.dailyGraceWindow = const Duration(hours: 3),
    this.weeklyGraceWindow = const Duration(hours: 3),
  });

  final Duration dailyGraceWindow;
  final Duration weeklyGraceWindow;

  bool canFinalizeReward({
    required ProgressionPeriod period,
    required DateTime evaluatedAt,
  }) {
    return !finalizationCutoffFor(period).isAfter(evaluatedAt);
  }

  DateTime finalizationCutoffFor(ProgressionPeriod period) {
    return switch (period.kind) {
      ProgressionPeriodKind.day => progressionDate(
          period.end,
        ).add(const Duration(days: 1)).add(dailyGraceWindow),
      ProgressionPeriodKind.week => progressionDate(
          period.end,
        ).add(const Duration(days: 1)).add(weeklyGraceWindow),
    };
  }
}
