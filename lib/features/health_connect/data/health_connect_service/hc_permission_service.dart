import 'package:health/health.dart';

import 'hc_read_client.dart';

/// Manages permission policy, checks, and request flows for Health Connect.
///
/// This is a high-risk seam — permission semantics must be preserved exactly.
/// All permission constants are co-located here to avoid split-brain drift.
class HcPermissionService {
  HcPermissionService(this._client);

  final HcReadClient _client;

  // Core permissions required for the app to leave the permission gate.
  // Optional scopes (workouts, sleep, body fat) are fetched opportunistically
  // and already degrade gracefully to empty/no-data states.
  static const List<HealthDataType> _requiredReadTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
  ];

  // Additional scopes requested for richer screens, but not used to block
  // the entire app when they are missing.
  //
  // On Android, the `health` plugin enriches WORKOUT reads by querying
  // distance and total-calorie records for each exercise session. If those
  // extra permissions are not granted, the workout fetch can fail and come
  // back empty even though WORKOUT itself is allowed.
  static const List<HealthDataType> _workoutReadTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  static const List<HealthDataType> _optionalReadTypes = [
    ..._workoutReadTypes,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_WATER_MASS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
  ];

  static const List<HealthDataAccess> _requiredReadPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static const List<HealthDataAccess> _optionalReadPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  static const List<HealthDataAccess> _workoutReadPermissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool?> hasPermissions() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final result = await _client.pluginHasPermissions(
        _requiredReadTypes,
        permissions: _requiredReadPermissions,
      );
      _client.logInfo('hasPermissions(required read types) => $result');
      return result;
    } catch (e, st) {
      _client.logError('hasPermissions(required read types) failed', e, st);
      rethrow;
    }
  }

  Future<bool> requestPermissions() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final requestedTypes = <HealthDataType>[
        ..._requiredReadTypes,
        ..._optionalReadTypes,
      ];
      final requestedPermissions = <HealthDataAccess>[
        ..._requiredReadPermissions,
        ..._optionalReadPermissions,
      ];

      _client.logInfo('Requesting permissions for read types: $requestedTypes');

      final granted = await _client.pluginRequestAuthorization(
        requestedTypes,
        permissions: requestedPermissions,
      );

      _client.logInfo('requestPermissions(read types) => $granted');

      final after = await _client.pluginHasPermissions(
        _requiredReadTypes,
        permissions: _requiredReadPermissions,
      );

      _client.logInfo(
        'hasPermissions(required read types) after request => $after',
      );

      return after == true;
    } catch (e, st) {
      _client.logError('requestPermissions(read types) failed', e, st);
      rethrow;
    }
  }

  Future<bool?> hasWorkoutPermission() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final result = await _client.pluginHasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('hasWorkoutPermission() => $result');
      return result;
    } catch (e, st) {
      _client.logError('hasWorkoutPermission() failed', e, st);
      rethrow;
    }
  }

  Future<bool> requestWorkoutPermission() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final before = await _client.pluginHasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('WORKOUT permission before request => $before');

      final granted = await _client.pluginRequestAuthorization(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('WORKOUT requestAuthorization => $granted');

      final after = await _client.pluginHasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('WORKOUT permission after request => $after');

      return after == true;
    } catch (e, st) {
      _client.logError('requestWorkoutPermission() failed', e, st);
      rethrow;
    }
  }

  Future<void> ensureWorkoutPermission() async {
    final hasPermission = await hasWorkoutPermission();
    if (hasPermission == true) return;
    _client.logWarning('WORKOUT permission missing');
    throw StateError('WORKOUT permission not granted');
  }

  Future<bool> isHistoryPermissionAvailable() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final result = await _client.pluginIsHealthDataHistoryAvailable();
      _client.logInfo('isHistoryPermissionAvailable() => $result');
      return result;
    } catch (e, st) {
      _client.logError('isHistoryPermissionAvailable() failed', e, st);
      return false;
    }
  }

  Future<bool> hasHistoryPermission() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final available = await _client.pluginIsHealthDataHistoryAvailable();
      if (!available) {
        _client.logInfo(
          'hasHistoryPermission() => false (feature unavailable)',
        );
        return false;
      }

      final result = await _client.pluginIsHealthDataHistoryAuthorized();
      _client.logInfo('hasHistoryPermission() => $result');
      return result;
    } catch (e, st) {
      _client.logError('hasHistoryPermission() failed', e, st);
      return false;
    }
  }

  Future<bool> requestHistoryPermissionIfAvailable() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final available = await _client.pluginIsHealthDataHistoryAvailable();
      if (!available) {
        _client.logInfo(
          'requestHistoryPermissionIfAvailable() skipped: feature unavailable',
        );
        return false;
      }

      final before = await _client.pluginIsHealthDataHistoryAuthorized();
      _client.logInfo('History permission before request => $before');
      if (before) return true;

      final granted =
          await _client.pluginRequestHealthDataHistoryAuthorization();
      _client.logInfo(
        'requestHealthDataHistoryAuthorization() => $granted',
      );

      final after = await _client.pluginIsHealthDataHistoryAuthorized();
      _client.logInfo('History permission after request => $after');
      return after;
    } catch (e, st) {
      _client.logError(
        'requestHistoryPermissionIfAvailable() failed',
        e,
        st,
      );
      return false;
    }
  }

  Future<bool> isBackgroundPermissionAvailable() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final result = await _client.pluginIsHealthDataInBackgroundAvailable();
      _client.logInfo('isBackgroundPermissionAvailable() => $result');
      return result;
    } catch (e, st) {
      _client.logError('isBackgroundPermissionAvailable() failed', e, st);
      return false;
    }
  }

  Future<bool> hasBackgroundPermission() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final available = await _client.pluginIsHealthDataInBackgroundAvailable();
      if (!available) {
        _client.logInfo(
          'hasBackgroundPermission() => false (feature unavailable)',
        );
        return false;
      }

      final result = await _client.pluginIsHealthDataInBackgroundAuthorized();
      _client.logInfo('hasBackgroundPermission() => $result');
      return result;
    } catch (e, st) {
      _client.logError('hasBackgroundPermission() failed', e, st);
      return false;
    }
  }

  Future<bool> requestBackgroundPermissionIfAvailable() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      final available = await _client.pluginIsHealthDataInBackgroundAvailable();
      if (!available) {
        _client.logInfo(
          'requestBackgroundPermissionIfAvailable() skipped: feature unavailable',
        );
        return false;
      }

      final before = await _client.pluginIsHealthDataInBackgroundAuthorized();
      _client.logInfo('Background permission before request => $before');
      if (before) return true;

      final granted =
          await _client.pluginRequestHealthDataInBackgroundAuthorization();
      _client.logInfo(
        'requestHealthDataInBackgroundAuthorization() => $granted',
      );

      final after = await _client.pluginIsHealthDataInBackgroundAuthorized();
      _client.logInfo('Background permission after request => $after');
      return after;
    } catch (e, st) {
      _client.logError(
        'requestBackgroundPermissionIfAvailable() failed',
        e,
        st,
      );
      return false;
    }
  }

  Future<void> debugWorkoutPermissionFlow() async {
    await _client.ensureConfigured();
    await _client.assertAvailable();

    try {
      _client.logInfo('debugWorkoutPermissionFlow() started');

      final before = await _client.pluginHasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('WORKOUT hasPermissions BEFORE => $before');

      final requested = await _client.pluginRequestAuthorization(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('WORKOUT requestAuthorization => $requested');

      final after = await _client.pluginHasPermissions(
        _workoutReadTypes,
        permissions: _workoutReadPermissions,
      );
      _client.logInfo('WORKOUT hasPermissions AFTER => $after');
    } catch (e, st) {
      _client.logError('debugWorkoutPermissionFlow() failed', e, st);
      rethrow;
    }
  }
}
