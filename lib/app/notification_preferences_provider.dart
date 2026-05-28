import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_log.dart';
import '../core/services/fcm_service.dart';
import '../core/services/notification_preferences.dart';
import '../core/services/notification_service.dart';

class NotificationPreferencesProvider extends ChangeNotifier {
  bool _notificationsEnabled = false;
  final Map<NotificationCategory, bool> _categoryEnabled = {
    for (final c in NotificationCategory.values) c: true,
  };

  bool get notificationsEnabled => _notificationsEnabled;

  bool categoryEnabled(NotificationCategory category) =>
      _categoryEnabled[category] ?? true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled =
        prefs.getBool(NotificationPreferences.enabledPrefKey) ?? false;
    for (final c in NotificationCategory.values) {
      _categoryEnabled[c] = prefs.getBool(c.prefsKey) ?? true;
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;

    _notificationsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPreferences.enabledPrefKey, value);

    if (value) {
      // Single user-facing moment for the OS prompt: the toggle ON path.
      // NotificationService drives the Android POST_NOTIFICATIONS dialog;
      // FCM is wired up after that so its token refresh sees the granted
      // permission.
      await NotificationService.instance.requestNotificationPermissions();
    }

    try {
      await FcmService.instance.setNotificationsEnabled(value);
    } catch (e, st) {
      AppLog.app.error(
        'NotificationPreferencesProvider: failed to sync FCM preference',
        err: e,
        stackTrace: st,
      );
    }
  }

  Future<void> setCategoryEnabled(
    NotificationCategory category,
    bool value,
  ) async {
    if (_categoryEnabled[category] == value) return;

    _categoryEnabled[category] = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(category.prefsKey, value);
  }
}
