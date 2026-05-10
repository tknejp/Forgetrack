import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/logging/app_log.dart';

/// Clears every locally-cached piece of Google Sheets export state.
///
/// Forgetrack does NOT delete the user's Google Spreadsheet file from Drive
/// — that is the user's data. This helper only removes the app's local
/// reference (saved `spreadsheet_id`) so a post-reset export goes through
/// the full create-or-pick flow against a fresh OAuth grant.
///
/// In-memory state on `SheetsExportProvider` and `BushidoExportProvider` is
/// reset by the orchestrator's "resetProviders" step; this helper only
/// touches persistent storage.
class GoogleSheetsExportResetHelper {
  const GoogleSheetsExportResetHelper();

  Future<int> clearLocalExportState() async {
    final prefs = await SharedPreferences.getInstance();
    var removed = 0;

    // Both the main export feature and the Bushido coach-log export reuse
    // the same key (AppConstants.prefSpreadsheetId) — single removal covers
    // both. If a future feature adds a new key, register it here.
    if (prefs.containsKey(AppConstants.prefSpreadsheetId)) {
      await prefs.remove(AppConstants.prefSpreadsheetId);
      removed += 1;
    }

    AppLog.reset.success(
      'sheets-export: cleared local state',
      payload: 'keysRemoved=$removed',
    );
    return removed;
  }
}
