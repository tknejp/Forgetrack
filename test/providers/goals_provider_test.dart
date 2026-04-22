import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:forgetrack/providers/goals_provider.dart';

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

    test('applies weekly activity changes to the current week immediately',
        () async {
      final provider = GoalsProvider();
      await provider.init();

      await provider.setWeeklyActivityMins(240);

      final now = DateTime.now();
      expect(provider.progressionWeeklyActivityMinsForWeek(now), 240);
    });
  });
}
