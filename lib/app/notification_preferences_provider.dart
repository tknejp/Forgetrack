import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_log.dart';
import '../core/services/fcm_service.dart';
import '../core/services/notification_preferences.dart';
import '../core/services/notification_service.dart';

class NotificationPreferencesProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled =
        prefs.getBool(NotificationPreferences.enabledPrefKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;

    _notificationsEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPreferences.enabledPrefKey, value);

    if (value) {
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
}
