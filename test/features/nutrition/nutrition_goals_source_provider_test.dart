import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:forgetrack/features/nutrition/application/nutrition_goals_source_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionGoalsSourceProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to local when no pref is stored', () async {
      final provider = NutritionGoalsSourceProvider();
      await provider.init();
      expect(provider.source, NutritionGoalsSource.local);
      expect(provider.usesKt, isFalse);
    });

    test('setSource persists, notifies, and round-trips through prefs',
        () async {
      final provider = NutritionGoalsSourceProvider();
      await provider.init();

      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setSource(NutritionGoalsSource.kt);
      expect(provider.usesKt, isTrue);
      expect(notified, 1);

      // No-op when unchanged → no extra notification.
      await provider.setSource(NutritionGoalsSource.kt);
      expect(notified, 1);

      final reloaded = NutritionGoalsSourceProvider();
      await reloaded.init();
      expect(reloaded.source, NutritionGoalsSource.kt);
    });

    test('fromKey is tolerant of unknown / null values', () {
      expect(NutritionGoalsSource.fromKey('kt'), NutritionGoalsSource.kt);
      expect(NutritionGoalsSource.fromKey('local'), NutritionGoalsSource.local);
      expect(NutritionGoalsSource.fromKey(null), NutritionGoalsSource.local);
      expect(NutritionGoalsSource.fromKey('garbage'),
          NutritionGoalsSource.local);
    });
  });
}
