import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  NotificationPreferences._();

  static const enabledPrefKey = 'notifications_enabled';

  static Future<bool> areEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledPrefKey) ?? true;
  }
}
