import 'package:flutter/services.dart';

import 'fitness_provider.dart';

class HealthConnectSettingsLauncher {
  const HealthConnectSettingsLauncher._();

  static const _channel = MethodChannel('forgetrack/health_connect_settings');

  static Future<bool> openSettings() async {
    final opened = await _channel.invokeMethod<bool>('openSettings');
    return opened ?? false;
  }
}

/// Single source of truth for the "user tapped a Health Connect CTA"
/// flow. Used by every HC entry point (home prompt card, in-card
/// footer, detail-screen banner) so the install / request / settings
/// branching stays consistent across surfaces.
///
/// Order of preference:
/// 1. HC isn't installed → route to the Play Store install flow.
/// 2. User already denied the in-app prompt this session → the HC
///    plugin won't show it again, so deep-link straight to HC
///    settings where they can still grant access. Re-`initialize()`
///    afterwards to pick up the result.
/// 3. Otherwise → ask the plugin to show its system prompt.
Future<void> runHcAccessFlow(FitnessProvider fitness) async {
  if (fitness.accessState == FitnessAccessState.unavailable) {
    await fitness.installHealthConnect();
    return;
  }
  if (fitness.lastRequestDenied) {
    await HealthConnectSettingsLauncher.openSettings();
    await fitness.initialize();
    // initialize() only reads from the local DB cache. When the user
    // just granted permissions externally that cache is still empty,
    // so pull a fresh HC sync so the cards populate immediately
    // instead of staying blank until the next pull-to-refresh. Cheap
    // no-op if permissions are still denied (refresh() short-circuits).
    if (fitness.hasPermissions) {
      await fitness.refresh();
    }
    return;
  }
  await fitness.requestPermissions();
}
