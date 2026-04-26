import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/debug_metric_overrides.dart';

class DevToolsProvider extends ChangeNotifier {
  static const _prefDebugMode = 'devtools_debug_mode';
  static const _prefOverrides = 'devtools_overrides';
  static const _prefBgDebugNotifications =
      'devtools_bg_debug_notifications_enabled';
  static const _prefAccessGranted = 'devtools_access_granted_last_known';

  bool _debugModeEnabled = false;
  bool _bgDebugNotificationsEnabled = false;
  DebugMetricOverrides _overrides = DebugMetricOverrides.empty;

  bool get isDebugModeEnabled => _debugModeEnabled;
  bool get isBgDebugNotificationsEnabled => _bgDebugNotificationsEnabled;
  DebugMetricOverrides get overrides => _overrides;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _debugModeEnabled = prefs.getBool(_prefDebugMode) ?? false;
    _bgDebugNotificationsEnabled =
        prefs.getBool(_prefBgDebugNotifications) ?? false;

    final overridesJson = prefs.getString(_prefOverrides);
    if (overridesJson != null) {
      try {
        final decoded = jsonDecode(overridesJson) as Map<String, dynamic>;
        _overrides = DebugMetricOverrides.fromJson(decoded);
      } catch (_) {
        _overrides = DebugMetricOverrides.empty;
      }
    }
  }

  Future<void> setDebugModeEnabled(bool value) async {
    if (_debugModeEnabled == value) return;
    _debugModeEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDebugMode, value);
  }

  Future<void> setBgDebugNotificationsEnabled(bool value) async {
    if (_bgDebugNotificationsEnabled == value) return;
    _bgDebugNotificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBgDebugNotifications, value);
  }

  /// Persists a flag that the background isolate reads to confirm developer
  /// access is currently active. Call when DevTools screen is opened.
  Future<void> markAccessGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefAccessGranted, true);
    } catch (_) {}
  }

  Future<void> setOverrides(DebugMetricOverrides overrides) async {
    _overrides = overrides;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (overrides.isEmpty) {
      await prefs.remove(_prefOverrides);
    } else {
      await prefs.setString(_prefOverrides, jsonEncode(overrides.toJson()));
    }
  }

  Future<void> clearOverrides() async {
    await setOverrides(DebugMetricOverrides.empty);
  }
}
