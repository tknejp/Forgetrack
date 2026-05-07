import 'package:isar/isar.dart';

part 'nutrition_day_record.g.dart';

@Collection()
class NutritionDayRecord {
  Id id = Isar.autoIncrement;

  /// ISO date key: 'yyyy-MM-dd'. Unique per day.
  @Index(unique: true, replace: true)
  late String dateKey;

  double calories = 0;
  double protein = 0;
  double fat = 0;
  double carbs = 0;
  double fiber = 0;
  double sugar = 0;
  double salt = 0;
  double saturatedFat = 0;
  double hydration = 0;
  int foodCount = 0;

  /// Basal metabolic rate (kcal) reported by KT for this day. 0 when unknown.
  double basal = 0;

  /// JSON-encoded list of [KtMeal] entries for the day. Empty string when no
  /// diary fetch has populated the per-meal breakdown.
  String mealsJson = '';

  /// True for days in the past (not today) — data considered complete.
  bool inferredComplete = false;

  @Index()
  late DateTime syncedAt;
}
