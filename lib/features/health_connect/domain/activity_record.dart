import 'package:health/health.dart'; // lint-ignore: domain-purity — HealthWorkoutActivityType is the platform boundary token for activity classification

class StepsRecord {
  final DateTime date;
  final int steps;

  const StepsRecord({required this.date, required this.steps});
}

class ActivityRecord {
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final int? caloriesBurned;
  final double? distanceKm;

  const ActivityRecord({
    required this.startTime,
    required this.endTime,
    required this.type,
    this.caloriesBurned,
    this.distanceKm,
  });

  Duration get duration => endTime.difference(startTime);

  factory ActivityRecord.fromHealthPoint(HealthDataPoint point) {
    String type = 'Neznámá';
    int? calories;
    double? distanceKm;

    final v = point.value;
    if (v is WorkoutHealthValue) {
      type = v.workoutActivityType.name;
      if (v.totalEnergyBurned != null) calories = v.totalEnergyBurned!.round();
      if (v.totalDistance != null) distanceKm = v.totalDistance! / 1000;
    }

    return ActivityRecord(
      startTime: point.dateFrom,
      endTime: point.dateTo,
      type: type,
      caloriesBurned: calories,
      distanceKm: distanceKm,
    );
  }

}
