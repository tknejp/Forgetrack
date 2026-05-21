import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user consent for Sentry crash reporting / breadcrumbs.
///
/// Default ON per agreed policy: first run gets opt-in semantics with the
/// switch pre-checked. User can disable any time in Settings; disabling
/// requires a restart to fully detach (Sentry can't be hot-toggled).
class SentryConsentProvider extends ChangeNotifier {
  static const String _enabledKey = 'sentry.collection_enabled';
  static const String _seenKey = 'sentry.consent_seen';

  bool _enabled = true;
  bool _seenDialog = false;

  bool get enabled => _enabled;
  bool get hasSeenDialog => _seenDialog;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _seenDialog = prefs.getBool(_seenKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> markDialogSeen() async {
    if (_seenDialog) return;
    _seenDialog = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
