class AppConstants {
  AppConstants._();

  static const String appName = 'Forgetrack';

  // --- Google Sheets ---
  static const String sheetsTitle = 'Forgetrack Data';
  static const String stepsSheet = 'Kroky';
  static const String activitiesSheet = 'Aktivity';
  static const String caloriesSheet = 'Kalorie';

  // SharedPreferences key pro uložené spreadsheetId
  static const String prefSpreadsheetId = 'spreadsheet_id';

  // --- Kalorické API (Open Food Facts) ---
  // Lze nahradit jiným REST endpointem (kaloricketabulky.cz apod.)
  static const String foodApiBase = 'https://world.openfoodfacts.org';
  static const int foodSearchPageSize = 20;

  // --- Health Connect ---
  static const int defaultHistoryDays = 7;
}
