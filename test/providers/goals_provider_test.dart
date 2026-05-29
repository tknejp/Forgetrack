import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:forgetrack/features/health_connect/application/goals_provider.dart';
import 'package:forgetrack/features/health_connect/application/nutrition_goals_gateway.dart';

/// Test double for the external nutrition goal source (#98).
class _FakeNutritionGoalsView implements NutritionGoalsView {
  _FakeNutritionGoalsView({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
  });

  @override
  final double calories;
  @override
  final double protein;
  @override
  final double fat;
  @override
  final double carbs;
  @override
  final double fiber;

  @override
  bool get hasData =>
      calories > 0 || protein > 0 || fat > 0 || carbs > 0 || fiber > 0;
}

class _FakeNutritionGoalsGateway implements NutritionGoalsGateway {
  _FakeNutritionGoalsGateway({this.available = true, this.view});

  bool available;
  NutritionGoalsView? view;

  @override
  bool get isAvailable => available;

  @override
  NutritionGoalsView? goalsForDate(DateTime day) => view;
}

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

  group('GoalsProvider nutrition source dispatch (#98)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    final today = DateTime.now();

    GoalsProvider build({
      required bool useKt,
      required _FakeNutritionGoalsGateway gateway,
    }) {
      return GoalsProvider(
        nutritionGoals: gateway,
        useExternalNutritionGoals: () => useKt,
      );
    }

    test('returns KT goals when source is KT and the gateway has data',
        () async {
      final gateway = _FakeNutritionGoalsGateway(
        view: _FakeNutritionGoalsView(
          calories: 2785,
          protein: 230,
          fat: 85,
          carbs: 275,
          fiber: 30,
        ),
      );
      final provider = build(useKt: true, gateway: gateway);
      await provider.init();
      // Local board still holds defaults.
      await provider.setDailyCalories(2000);
      await provider.setDailyProtein(150);

      expect(provider.dailyCalories, 2785);
      expect(provider.dailyProtein, 230);
      expect(provider.dailyFat, 85);
      expect(provider.dailyCarbs, 275);
      expect(provider.dailyFiber, 30);
      expect(provider.progressionDailyCaloriesForDate(today), 2785);
      expect(provider.progressionDailyFiberForDate(today), 30);
    });

    test('falls back to local when the gateway is unavailable', () async {
      final gateway = _FakeNutritionGoalsGateway(
        available: false,
        view: _FakeNutritionGoalsView(calories: 2785),
      );
      final provider = build(useKt: true, gateway: gateway);
      await provider.init();
      await provider.setDailyCalories(2100);

      expect(provider.dailyCalories, 2100);
      expect(provider.progressionDailyCaloriesForDate(today), 2100);
    });

    test('falls back to local when KT has no goals for the day (all-zero)',
        () async {
      final gateway = _FakeNutritionGoalsGateway(
        view: _FakeNutritionGoalsView(), // hasData == false
      );
      final provider = build(useKt: true, gateway: gateway);
      await provider.init();
      await provider.setDailyProtein(180);

      expect(provider.dailyProtein, 180);
    });

    test('steps + target weight stay local even under the KT source',
        () async {
      final gateway = _FakeNutritionGoalsGateway(
        view: _FakeNutritionGoalsView(calories: 2785),
      );
      final provider = build(useKt: true, gateway: gateway);
      await provider.init();
      await provider.setDailySteps(12000);
      await provider.setTargetWeight(82.5);

      expect(provider.dailySteps, 12000);
      expect(provider.targetWeight, 82.5);
    });

    test('flipping the source back to local restores local values',
        () async {
      var useKt = true;
      final gateway = _FakeNutritionGoalsGateway(
        view: _FakeNutritionGoalsView(calories: 2785),
      );
      final provider = GoalsProvider(
        nutritionGoals: gateway,
        useExternalNutritionGoals: () => useKt,
      );
      await provider.init();
      await provider.setDailyCalories(2100);

      expect(provider.dailyCalories, 2785); // KT source active

      useKt = false;
      expect(provider.dailyCalories, 2100); // local value intact
    });

    test('with no gateway wired, nutrition getters are always local',
        () async {
      final provider = GoalsProvider();
      await provider.init();
      await provider.setDailyCalories(2222);
      expect(provider.dailyCalories, 2222);
    });
  });
}
