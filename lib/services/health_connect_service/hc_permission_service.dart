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
    HealthDataType.SLEEP_SESSION,
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
