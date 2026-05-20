import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:forgetrack/features/health_connect/application/goals_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoalsProvider progression goal history', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('applies daily calorie changes to the current day immediately',
        () async {
      final provider = GoalsProvider();
      await provider.init();

      await provider.setDailyCalories(2785);
      await provider.setDailyProtein(230);

      final today = DateTime.now();
      expect(provider.progressionDailyCaloriesForDate(today), 2785);
      expect(provider.progressionDailyProteinForDate(today), 230);
    });

    test('daily activity goal defaults to 30 and round-trips through prefs',
        () async {
      final first = GoalsProvider();
      await first.init();
      expect(first.dailyActivityMins, 30);

      await first.setDailyActivityMins(45);
      expect(first.dailyActivityMins, 45);

      final reloaded = GoalsProvider();
      await reloaded.init();
      expect(reloaded.dailyActivityMins, 45);
      expect(
        reloaded.progressionDailyActivityMinsForDate(DateTime.now()),
        45,
      );
    });

    test('applies weekly activity changes to the current week immediately',
        () async {
      final provider = GoalsProvider();
      await provider.init();

      await provider.setWeeklyActivityMins(240);

      final now = DateTime.now();
      expect(provider.progressionWeeklyActivityMinsForWeek(now), 240);
    });

    test('migrates stale delayed goal history to today on init', () async {
      final today = DateTime.now();
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      SharedPreferences.setMockInitialValues({
        'goal_daily_calories': 2785.0,
        'goal_daily_protein': 230.0,
        'goal_daily_calories_history':
            '[{"effectiveFrom":"1970-01-01T00:00:00.000","value":2000.0},{"effectiveFrom":"${tomorrow.toIso8601String()}","value":2785.0}]',
        'goal_daily_protein_history':
            '[{"effectiveFrom":"1970-01-01T00:00:00.000","value":150.0},{"effectiveFrom":"${tomorrow.toIso8601String()}","value":230.0}]',
      });

      final provider = GoalsProvider();
      await provider.init();

      expect(provider.progressionDailyCaloriesForDate(today), 2785);
      expect(provider.progressionDailyProteinForDate(today), 230);
    });
  });
}
