import 'package:app_settings/app_settings.dart' show AppSettings;
import 'package:health/health.dart';

import '../../../../core/logging/app_log.dart';

/// Health Connect / Forgetrack contract: HC stores user-owned data and
/// MUST be treated as read-only. This helper never calls delete or write
/// APIs. It only:
///
/// 1. Asks the `health` plugin to revoke the permissions Forgetrack holds
///    over the data types it reads (steps, calories, sleep, etc.). On
///    Android this delegates to the Health Connect framework; the user's
///    actual records remain untouched.
/// 2. Optionally opens Android Health Connect / app settings so the user
///    can verify or revoke any permissions the framework didn't drop
///    automatically.
class HealthConnectResetHelper {
  HealthConnectResetHelper({Health? health}) : _health = health ?? Health();

  final Health _health;

  /// Calls `Health().revokePermissions()`. Idempotent and safe even when
  /// no permissions are granted — the plugin handles the no-op internally.
  Future<void> revokePermissions() async {
    AppLog.reset.info('health-connect: revokePermissions start');
    await _health.revokePermissions();
    AppLog.reset.success('health-connect: revokePermissions ok');
  }

  /// Opens the app-info screen so the user can verify Health Connect
  /// permissions for Forgetrack and revoke any leftovers manually. The
  /// `app_settings` package doesn't expose a dedicated Health Connect
  /// entry, so this is the closest portable fallback — Android's
  /// app-info page lists Health Connect under Permissions and links into
  /// the Health Connect framework's per-app screen.
  Future<void> openHealthConnectSettings() async {
    AppLog.reset.info('health-connect: opening app settings (HC fallback)');
    await AppSettings.openAppSettings();
    AppLog.reset.success('health-connect: app settings opened');
  }
}
