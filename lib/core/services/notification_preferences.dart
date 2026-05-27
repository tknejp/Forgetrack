import 'package:shared_preferences/shared_preferences.dart';

enum NotificationCategory {
  progression('notif_category_progression'),
  social('notif_category_social'),
  reminders('notif_category_reminders');

  const NotificationCategory(this.prefsKey);

  final String prefsKey;
}

class NotificationPreferences {
  NotificationPreferences._();

  static const enabledPrefKey = 'notifications_enabled';

  static Future<bool> areEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledPrefKey) ?? true;
  }

  static Future<bool> isCategoryEnabled(NotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(category.prefsKey) ?? true;
  }

  /// Returns true only when the master toggle AND the per-category toggle are
  /// both on. Single entry point for `NotificationService` / `FcmService`
  /// callers so a category opt-out short-circuits at the same place as the
  /// master switch.
  static Future<bool> isAllowed(NotificationCategory category) async {
    if (!await areEnabled()) return false;
    return isCategoryEnabled(category);
  }
}
