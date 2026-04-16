import 'package:health/health.dart';
import 'package:intl/intl.dart';

class StepsRecord {
  final DateTime date;
  final int steps;

  const StepsRecord({required this.date, required this.steps});

  List<Object?> toSheetRow() => [
        DateFormat('yyyy-MM-dd').format(date),
        steps,
      ];
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

  List<Object?> toSheetRow() {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return [
      fmt.format(startTime),
      type,
      duration.inMinutes,
      caloriesBurned,
      distanceKm?.toStringAsFixed(2),
    ];
  }
}
