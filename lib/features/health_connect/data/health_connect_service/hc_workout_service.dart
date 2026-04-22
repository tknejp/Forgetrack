import 'package:health/health.dart';

import '../../domain/activity_record.dart';
import 'hc_read_client.dart';

class HcWorkoutService {
  HcWorkoutService(this._client);

  final HcReadClient _client;

  Future<List<ActivityRecord>> getActivities(
    DateTime start,
    DateTime end,
  ) async {
    final points = await _client.fetchData(
      label: 'WORKOUT',
      start: start,
      end: end,
      types: const [HealthDataType.WORKOUT],
    );

    final result = points
        .map(ActivityRecord.fromHealthPoint)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    _client.logInfo(
      'getActivities(): ${result.length} workout records from=${_client.fmt(start)} to=${_client.fmt(end)}',
    );

    return result;
  }
}
