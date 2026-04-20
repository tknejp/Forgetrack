import '../../core/app_log.dart';
import '../../services/kaloricke_tabulky_service.dart';
import '../../services/db/kt_nutrition_database.dart';

/// Pure aggregation helpers for [KalorickeTabulkyProvider].
///
/// All methods are static and operate on the supplied database + parameters.
/// Also provides shared date/key formatting utilities used by the sync layer.
class KtNutritionQueries {
  // ─── Date / key helpers ───────────────────────────────────────────────────

  static DateTime dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String storeKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static String describeNutrition(KtDayNutrition nutrition) =>
      'kcal=${nutrition.calories}, '
      'P=${nutrition.protein}, '
      'F=${nutrition.fat}, '
      'C=${nutrition.carbs}, '
      'fiber=${nutrition.fiber}, '
      'foods=${nutrition.foodCount}, '
      'synced=${nutrition.lastSyncedAt.toIso8601String()}';

  // ─── Average field ────────────────────────────────────────────────────────

  /// Average of [field] over [start, end], excluding today and days with no
  /// logged data. Returns null when no valid days are available.
  static double? avgField(
    KtNutritionDatabase db,
    DateTime start,
    DateTime end,
    double Function(KtDayNutrition) field,
    String fieldName,
  ) {
    final startKey = storeKey(start);
    final endKey = storeKey(end);
    final todayKey = storeKey(dateOnly(DateTime.now()));
    final days = db.getRange(start, end);

    // Exclude today (potentially incomplete) and days where nothing was logged.
    // Use foodCount > 0 OR calories > 0 as the "has data" check — foodstuffCount
    // may be missing from some API responses even when food was logged.
    final includedDays = days.entries
        .where((e) =>
            e.key != todayKey &&
            (e.value.foodCount > 0 || e.value.calories > 0))
        .toList();

    final excludedDays = days.entries
        .where((e) =>
            e.key == todayKey ||
            (e.value.foodCount == 0 && e.value.calories == 0))
        .toList();

    if (excludedDays.isNotEmpty) {
      AppLog.ktAvg.debug(
        'avgField($fieldName) excluded ${excludedDays.length} day(s)',
        payload: excludedDays
            .map((e) =>
                '${e.key}[today=${e.key == todayKey}, foods=${e.value.foodCount}, kcal=${e.value.calories}]')
            .join(', '),
      );
    }

    final values = includedDays.map((e) => field(e.value)).toList();

    if (values.isEmpty) {
      AppLog.ktAvg.debug(
        'avgField($fieldName) $startKey → $endKey → null',
        payload:
            'cachedDays=${days.length}, includedDays=0, todayKey=$todayKey',
      );
      return null;
    }

    final average = values.reduce((a, b) => a + b) / values.length;
    AppLog.ktAvg.info(
      'avgField($fieldName) $startKey → $endKey → avg=$average',
      payload: '${values.length} day(s): '
          '${includedDays.map((e) => '${e.key}[v=${field(e.value)}]').join(', ')}',
    );
    return average;
  }
}
