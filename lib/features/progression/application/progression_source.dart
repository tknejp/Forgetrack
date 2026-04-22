import '../domain/progression_models.dart';

abstract class ProgressionSource {
  ProgressionGoalSet get currentGoals;
  ProgressionGoalSet goalsForPeriod(ProgressionPeriod period);
  List<ProgressionSnapshot> buildDailySnapshots();
  List<ProgressionSnapshot> buildWeeklySnapshots();
  String get auditSignature;
}
