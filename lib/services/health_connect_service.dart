import 'package:health/health.dart';
import '../models/activity_record.dart';

class HealthConnectService {
  final Health _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static final _permissions = _types.map((_) => HealthDataAccess.READ).toList();

  /// Vrátí true pokud je Health Connect nainstalováno a aktuální.
  Future<bool> isAvailable() async {
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Otevře instalaci / aktualizaci Health Connect ze systémového obchodu.
  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
  }

  /// Požádá o oprávnění ke čtení zdravotních dat.
  /// Vrátí true pokud byla všechna oprávnění udělena.
  Future<bool> requestPermissions() async {
    return await _health.requestAuthorization(_types, permissions: _permissions);
  }

  /// Celkový počet kroků pro daný den.
  Future<int> getStepsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return await _health.getTotalStepsInInterval(start, end) ?? 0;
  }

  /// Kroky za posledních [days] dní (nejstarší → nejnovější).
  Future<List<StepsRecord>> getStepsHistory(int days) async {
    final now = DateTime.now();
    final records = <StepsRecord>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = await getStepsForDate(date);
      records.add(StepsRecord(date: date, steps: steps));
    }
    return records;
  }

  /// Tréninky/aktivity v daném rozsahu.
  Future<List<ActivityRecord>> getActivities(
      DateTime start, DateTime end) async {
    final points = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.WORKOUT],
    );
    return points
        .map(ActivityRecord.fromHealthPoint)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Průměrná tepová frekvence za dnes.
  Future<double?> getTodayAvgHeartRate() async {
    final start = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    final end = DateTime.now();
    final points = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.HEART_RATE],
    );
    if (points.isEmpty) return null;
    final values = points
        .map((p) => (p.value as NumericHealthValue).numericValue.toDouble())
        .toList();
    return values.reduce((a, b) => a + b) / values.length;
  }
}
