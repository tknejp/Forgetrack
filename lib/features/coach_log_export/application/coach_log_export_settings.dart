import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user preferences for the coach-log export feature.
///
/// Currently a single opt-in toggle: whether a quick "export current week"
/// action is surfaced on the overview header. Default OFF — the export lives
/// in Settings → Coach Log Export and is a niche power-user flow; only people
/// who run it every week want it one tap away, so we don't clutter the
/// overview for everyone else.
class CoachLogExportSettings extends ChangeNotifier {
  static const String _quickButtonKey =
      'coach_log_export.overview_quick_button';

  bool _showOverviewQuickButton = false;

  /// Whether the overview header shows a one-tap "export current week" icon.
  bool get showOverviewQuickButton => _showOverviewQuickButton;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _showOverviewQuickButton = prefs.getBool(_quickButtonKey) ?? false;
  }

  Future<void> setShowOverviewQuickButton(bool value) async {
    if (_showOverviewQuickButton == value) return;
    _showOverviewQuickButton = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickButtonKey, value);
  }
}
