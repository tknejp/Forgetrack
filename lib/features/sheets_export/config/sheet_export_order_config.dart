/// Configuration of field export order.
/// Each field has a unique order number that determines its column position in the exported sheet.
/// Ordering is ascending, so lower numbers appear first.
abstract final class SheetExportOrderConfig {
  // ── Body ──────────────────────────────────────────────────────────────────
  static const int weight = 100;
  static const int bodyFat = 200;

  // ── Nutrition ─────────────────────────────────────────────────────────────
  static const int kcalIn = 300;
  static const int protein = 400;
  static const int carbs = 500;
  static const int fat = 600;
  static const int fiber = 700;
  static const int sugar = 800;
  static const int salt = 900;
  static const int saturatedFat = 1000;

  // ── Activity ──────────────────────────────────────────────────────────────
  static const int steps = 1100;
  static const int activeCalories = 1200;

  // ── Sleep ─────────────────────────────────────────────────────────────────
  static const int sleepMinutes = 1300;
  static const int sleepBedtime = 1400;
  static const int sleepWake = 1500;
}
