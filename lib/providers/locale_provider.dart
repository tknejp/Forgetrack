import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's selected locale and persists the choice across restarts.
///
/// A null [locale] means "follow the device system locale".
class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'selected_language_code';

  Locale? _locale;

  /// The currently selected locale, or null for system default.
  Locale? get locale => _locale;

  /// Loads the persisted locale from SharedPreferences.
  /// Call this once before [runApp].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      _locale = Locale(code);
    }
  }

  /// Sets and persists a new locale. Pass null to follow the system locale.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
  }
}
