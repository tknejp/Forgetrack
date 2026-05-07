import 'package:flutter/services.dart';

class HealthConnectSettingsLauncher {
  const HealthConnectSettingsLauncher._();

  static const _channel = MethodChannel('forgetrack/health_connect_settings');

  static Future<bool> openSettings() async {
    final opened = await _channel.invokeMethod<bool>('openSettings');
    return opened ?? false;
  }
}
