class AppConstants {
  AppConstants._();

  static const String appName = 'Forgetrack';
  static const String appVersion = '1.0.0';

  // --- Google Sheets ---
  static const String sheetsTitle = 'Forgetrack Data';
  static const String stepsSheet = 'Kroky';
  static const String activitiesSheet = 'Aktivity';
  static const String caloriesSheet = 'Kalorie';

  /// Single canonical sheet/tab used by the unified export-by-date pipeline.
  static const String exportSheetName = 'Forgetrack';

  /// Header for the merge-key column. Always column A.
  static const String exportDateColumn = 'date';

  // SharedPreferences key pro uložené spreadsheetId
  static const String prefSpreadsheetId = 'spreadsheet_id';

  // --- Kalorické API (Open Food Facts) ---
  // Lze nahradit jiným REST endpointem (kaloricketabulky.cz apod.)
  static const String foodApiBase = 'https://world.openfoodfacts.org';
  static const int foodSearchPageSize = 20;

  // --- Health Connect ---
  static const int defaultHistoryDays = 30;

  // --- Default goals (until user-configurable settings are added) ---
  static const int dailyStepGoal = 10000;
  static const int weeklyStepGoal = 70000;
  static const int monthlyStepGoal = 300000;
  static const double defaultCalorieGoal = 2000;
  static const double defaultWeightGoal = 75.0;
}
