import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Extended theme choice that adds an automatic time-of-day option on top of
/// Flutter's standard [ThemeMode] values.
enum AppThemeMode {
  system,   // Follow device brightness
  light,    // Always light
  dark,     // Always dark
  dynamic,  // Auto light/dark + palette driven by time of day
}

/// Manages the app's theme choice and persists it across restarts.
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'theme_mode';

  AppThemeMode _choice = AppThemeMode.system;

  AppThemeMode get choice => _choice;

  /// The Flutter [ThemeMode] for the current choice.
  ///
  /// For [AppThemeMode.dynamic] this returns [ThemeMode.system] as a
  /// placeholder — [ForgetrackApp] overrides it with the time-based value.
  ThemeMode get mode => switch (_choice) {
    AppThemeMode.system  => ThemeMode.system,
    AppThemeMode.light   => ThemeMode.light,
    AppThemeMode.dark    => ThemeMode.dark,
    AppThemeMode.dynamic => ThemeMode.system,
  };

  /// Loads the persisted choice from SharedPreferences.
  /// Call once before [runApp].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _choice = switch (saved) {
      'light'   => AppThemeMode.light,
      'dark'    => AppThemeMode.dark,
      'dynamic' => AppThemeMode.dynamic,
      _         => AppThemeMode.system,
    };
  }

  /// Sets and persists a new theme choice.
  Future<void> setChoice(AppThemeMode choice) async {
    if (_choice == choice) return;
    _choice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, choice.name);
  }
}
