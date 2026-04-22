import '../domain/progression_models.dart';

abstract class ProgressionSource {
  ProgressionGoalSet get goals;
  List<ProgressionSnapshot> buildDailySnapshots();
  List<ProgressionSnapshot> buildWeeklySnapshots();
  String get auditSignature;
}
