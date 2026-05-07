import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:forgetrack/core/logging/app_log.dart';
import '../domain/weight_card_data.dart';
import '../data/health_connect_service.dart';
import '../data/local/health_database.dart';
import '../domain/activity_record.dart';
import '../domain/sleep_record.dart';
import '../domain/weight_record.dart';
import 'fitness_provider/fitness_queries.dart';
import '../../devtools/application/devtools_sync_logger.dart';
import '../../devtools/domain/devtools_sync_event.dart';

enum FitnessAccessState {
  checking,
  unavailable,
  permissionRequired,
  ready,
}

class FitnessProvider extends ChangeNotifier {
  static const int _defaultHistoryDays = 30;
  static const int _extendedHistoryDays = 365;
  static const int _normalRefreshDays = 7;
  static const Duration _appOpenRefreshMinInterval = Duration(minutes: 5);

  final HealthConnectService _service;
  final HealthDatabase _db;

  FitnessProvider(this._service, this._db);

  // --- Concurrency guard ----------------------------------------------------
  bool _inFlight = false;
  StreamSubscription<void>? _dbChangeSubscription;
  DateTime? _lastAppOpenRefreshAttemptAt;

  // --- State ----------------------------------------------------------------
  bool _isLoading = false;
  bool _hasInitialized = false;
  bool _isRefreshing = false;
  bool _isHealthConnectAvailable = false;
  bool _hasPermissions = false;
  bool _hasHistoricalDataAccess = false;
  bool _hasBackgroundDataAccess = false;
  bool _historyPermissionDeniedThisSession = false;
  bool _backgroundPermissionDeniedThisSession = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  List<StepsRecord> _stepsHistory = [];
  List<double> _activeCaloriesHistory = [];
  List<double> _basalCaloriesHistory = [];
  List<WeightRecord> _weightHistory = [];
  double? _latestBodyFat;
  List<ActivityRecord> _activities = [];
  bool _workoutPermissionGranted = false;
  SleepRecord? _todaySleep;
  List<SleepRecord> _sleepHistory = [];

  // --- Debug / pipeline diagnostics (diagnostic-only, no production effect) -
  String? _debugLastRefreshSource;
  DateTime? _debugLastRefreshStartedAt;
  DateTime? _debugLastRefreshCompletedAt;
  int? _debugLastRefreshDurationMs;
  String? _debugLastRefreshError;
  int? _debugTodayStepsBeforeRefresh;
  int? _debugTodayStepsAfterRefresh;
  int? _debugLastRecordStepsBefore;
  DateTime? _debugLastRecordDateBefore;
  int? _debugLastRecordStepsAfter;
  DateTime? _debugLastRecordDateAfter;
  int? _debugLastFetchedTodaySteps;
  int? _debugLastQueryDays;
  DateTime? _debugLastDbWatcherFiredAt;
  int? _debugDbWatcherTodaySteps;

  // --- Public getters -------------------------------------------------------
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  bool get isRefreshing => _isRefreshing;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;
  bool get hasPermissions => _hasPermissions;
  bool get hasHistoricalDataAccess => _hasHistoricalDataAccess;
  bool get hasBackgroundDataAccess => _hasBackgroundDataAccess;

  FitnessAccessState get accessState {
    if (!_hasInitialized || _isLoading) return FitnessAccessState.checking;
    if (!_isHealthConnectAvailable) return FitnessAccessState.unavailable;
    if (!_hasPermissions) return FitnessAccessState.permissionRequired;
    return FitnessAccessState.ready;
  }

  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  List<StepsRecord> get stepsHistory => _stepsHistory;
  List<ActivityRecord> get activities => _activities;
  bool get workoutPermissionGranted => _workoutPermissionGranted;
  List<WeightRecord> get weightHistory => _weightHistory;
  double? get latestBodyFat => _latestBodyFat;
  double? get latestBodyWater =>
      _weightHistory.where((r) => r.bodyWater != null).lastOrNull?.bodyWater;
  SleepRecord? get todaySleep => _todaySleep;
  List<SleepRecord> get sleepHistory => _sleepHistory;

  // --- Debug/diagnostic getters (read-only, no side effects) --------------
  int get debugStepsRecordCount => _stepsHistory.length;
  int get debugWeightRecordCount => _weightHistory.length;
  int get debugSleepRecordCount => _sleepHistory.length;
  int get debugActivitiesCount => _activities.length;
  DateTime? get debugStepsFirstDate =>
      _stepsHistory.isNotEmpty ? _stepsHistory.first.date : null;
  DateTime? get debugStepsLastDate =>
      _stepsHistory.isNotEmpty ? _stepsHistory.last.date : null;

  /// How many weight records have a non-null bodyFat value stored in-record.
  int get debugWeightWithBodyFatCount =>
      _weightHistory.where((r) => r.bodyFat != null).length;

  /// Weight first / last date (or null when empty).
  DateTime? get debugWeightFirstDate =>
      _weightHistory.isNotEmpty ? _weightHistory.first.date : null;
  DateTime? get debugWeightLastDate =>
      _weightHistory.isNotEmpty ? _weightHistory.last.date : null;

  /// Last <=5 weight records: date, kg, bodyFat%. Cheap slice - no DB access.
  List<({String dateKey, double kg, double? fatPct})>
      get debugWeightRecordsPreview {
    const limit = 5;
    final src = _weightHistory.length > limit
        ? _weightHistory.sublist(_weightHistory.length - limit)
        : _weightHistory;
    return [
      for (final r in src)
        (dateKey: _fmtDateKey(r.date), kg: r.weight, fatPct: r.bodyFat)
    ];
  }

  // Pipeline debug getters - all cheap in-memory reads.
  String? get debugLastRefreshSource => _debugLastRefreshSource;
  DateTime? get debugLastRefreshStartedAt => _debugLastRefreshStartedAt;
  DateTime? get debugLastRefreshCompletedAt => _debugLastRefreshCompletedAt;
  int? get debugLastRefreshDurationMs => _debugLastRefreshDurationMs;
  String? get debugLastRefreshError => _debugLastRefreshError;
  int? get debugTodayStepsBeforeRefresh => _debugTodayStepsBeforeRefresh;
  int? get debugTodayStepsAfterRefresh => _debugTodayStepsAfterRefresh;
  int? get debugLastRecordStepsBefore => _debugLastRecordStepsBefore;
  DateTime? get debugLastRecordDateBefore => _debugLastRecordDateBefore;
  int? get debugLastRecordStepsAfter => _debugLastRecordStepsAfter;
  DateTime? get debugLastRecordDateAfter => _debugLastRecordDateAfter;
  int? get debugLastFetchedTodaySteps => _debugLastFetchedTodaySteps;
  int? get debugLastQueryDays => _debugLastQueryDays;
  DateTime? get debugLastDbWatcherFiredAt => _debugLastDbWatcherFiredAt;
  int? get debugDbWatcherTodaySteps => _debugDbWatcherTodaySteps;

  /// Today's steps by date matching (vs todaySteps which uses .last position).
  int get debugTodayStepsDateMatch => stepsForDate(DateTime.now());

  /// Last <=5 step records: (dateKey, steps). Cheap slice - no DB access.
  List<({String dateKey, int steps})> get debugStepRecordsPreview {
    const limit = 5;
    final src = _stepsHistory.length > limit
        ? _stepsHistory.sublist(_stepsHistory.length - limit)
        : _stepsHistory;
    return [
      for (final r in src) (dateKey: _fmtDateKey(r.date), steps: r.steps)
    ];
  }

  /// Today's steps by date matching (vs positional .last).
  int get todaySteps => stepsForDate(DateTime.now());

  int get stepsWeekTotal {
    if (_stepsHistory.isEmpty) return 0;
    final slice = _stepsHistory.length >= 7
        ? _stepsHistory.sublist(_stepsHistory.length - 7)
        : _stepsHistory;
    return slice.fold(0, (sum, r) => sum + r.steps);
  }

  int get stepsMonthTotal => _recentStepsHistory(_defaultHistoryDays)
      .fold(0, (sum, r) => sum + r.steps);

  // --- Computed calorie totals ----------------------------------------------

  double get activeCaloriesBurnedToday =>
      _activeCaloriesHistory.isNotEmpty ? _activeCaloriesHistory.last : 0;

  double get activeCaloriesBurnedWeek {
    if (_activeCaloriesHistory.isEmpty) return 0;
    final slice = _activeCaloriesHistory.length >= 7
        ? _activeCaloriesHistory.sublist(_activeCaloriesHistory.length - 7)
        : _activeCaloriesHistory;
    return slice.fold<double>(0.0, (sum, v) => sum + v);
  }

  double get activeCaloriesBurnedMonth =>
      _recentCaloriesHistory(_defaultHistoryDays)
          .fold<double>(0.0, (sum, v) => sum + v);

  double get basalCaloriesBurnedToday =>
      _basalCaloriesHistory.isNotEmpty ? _basalCaloriesHistory.last : 0;

  // --- Latest weight --------------------------------------------------------

  double? get latestWeight =>
      _weightHistory.isNotEmpty ? _weightHistory.last.weight : null;

  // --- Date-range queries (delegated to FitnessQueries) ---------------------

  int stepsForDate(DateTime date) =>
      FitnessQueries.stepsForDate(_stepsHistory, date);

  int stepsAvgForRange(DateTime start, DateTime end) =>
      FitnessQueries.stepsAvgForRange(_stepsHistory, start, end);

  List<StepsRecord> stepsHistoryForRange(DateTime start, DateTime end) =>
      FitnessQueries.stepsHistoryForRange(_stepsHistory, start, end);

  double activeCaloriesBurnedForDate(DateTime date) =>
      FitnessQueries.activeCaloriesBurnedForDate(
          _stepsHistory, _activeCaloriesHistory, date);

  double basalCaloriesBurnedForDate(DateTime date) =>
      FitnessQueries.activeCaloriesBurnedForDate(
          _stepsHistory, _basalCaloriesHistory, date);

  double activeCaloriesBurnedAvgForRange(DateTime start, DateTime end) =>
      FitnessQueries.activeCaloriesBurnedAvgForRange(
          _stepsHistory, _activeCaloriesHistory, start, end);

  double basalCaloriesBurnedAvgForRange(DateTime start, DateTime end) =>
      FitnessQueries.activeCaloriesBurnedAvgForRange(
          _stepsHistory, _basalCaloriesHistory, start, end);

  List<WeightRecord> weightHistoryForRange(DateTime start, DateTime end) =>
      FitnessQueries.weightHistoryForRange(_weightHistory, start, end);

  WeightRecord? weightForDate(DateTime date) =>
      FitnessQueries.weightForDate(_weightHistory, date);

  ({double? lastKnown, double? trend}) weightMetricsForRange(
          DateTime start, DateTime end) =>
      FitnessQueries.weightMetricsForRange(
          _weightHistory, latestWeight, start, end);

  SleepRecord? sleepForDate(DateTime date) =>
      FitnessQueries.sleepForDate(_sleepHistory, date);

  // --- Weight aggregation (delegated to FitnessQueries) ---------------------

  double? previousWeightBefore(DateTime date) =>
      FitnessQueries.previousWeightBefore(_weightHistory, date);

  double? weekAvgWeight(DateTime weekStart) =>
      FitnessQueries.weekAvgWeight(_weightHistory, weekStart);

  double? monthAvgWeight(DateTime monthRef) =>
      FitnessQueries.monthAvgWeight(_weightHistory, monthRef);

  List<WeightChartPoint> dailyWeightChart(int maxPoints) =>
      FitnessQueries.dailyWeightChart(_weightHistory, maxPoints);

  List<WeightChartPoint> weightChartForRange(DateTime start, DateTime end) =>
      FitnessQueries.weightChartForRange(_weightHistory, start, end);

  List<WeightChartPoint> weeklyWeightChart(int weeks) =>
      FitnessQueries.weeklyWeightChart(_weightHistory, weeks);

  List<WeightChartPoint> monthlyWeightChart(int months) =>
      FitnessQueries.monthlyWeightChart(_weightHistory, months);

  // --- Sleep history --------------------------------------------------------

  Duration? avgSleepForRange(DateTime start, DateTime end) =>
      FitnessQueries.avgSleepForRange(_sleepHistory, start, end);

  // --- Public methods -------------------------------------------------------

  /// Checks HC availability and permissions, then loads data from the local
  /// DB cache. No Health Connect data reads - safe on every app start/resume.
  /// Also sets up live DB watchers so UI updates when background task writes data.
  Future<void> initialize() async {
    if (_inFlight) return;
    _inFlight = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isHealthConnectAvailable = await _service.isAvailable(
        forceRefresh: _hasInitialized && !_isHealthConnectAvailable,
      );
      if (!_isHealthConnectAvailable) return;

      final perms = await _service.hasPermissions();
      _hasPermissions = perms == true;
      if (_hasPermissions) {
        await _refreshHistoryAccess(interactive: false);
        await _refreshBackgroundAccess(interactive: false);
        _loadFromDb();

        // Set up live DB watcher - when background task writes data, reload it.
        _dbChangeSubscription?.cancel();
        _dbChangeSubscription = _db.watchForChanges().listen((_) {
          _debugLastDbWatcherFiredAt = DateTime.now();
          _loadFromDb();
          _debugDbWatcherTodaySteps = todaySteps;
          notifyListeners();
        });
      } else {
        _hasHistoricalDataAccess = false;
        _hasBackgroundDataAccess = false;
      }
    } catch (e, st) {
      _errorMessage = e.toString();
      AppLog.health.error(
        'FitnessProvider.initialize() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      _hasInitialized = true;
      _isLoading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Shows the HC permission dialog. On grant, fetches from HC and caches.
  Future<void> requestPermissions() async {
    if (_inFlight) return;
    _inFlight = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isHealthConnectAvailable =
          await _service.isAvailable(forceRefresh: true);
      if (!_isHealthConnectAvailable) return;

      _hasPermissions = await _service.requestPermissions();
      if (_hasPermissions) {
        await _refreshHistoryAccess(interactive: true);
        await _refreshBackgroundAccess(interactive: true);
        await _fetchFromHC();
      } else {
        _hasHistoricalDataAccess = false;
        _hasBackgroundDataAccess = false;
      }
    } catch (e, st) {
      _errorMessage = e.toString();
      AppLog.health.error(
        'FitnessProvider.requestPermissions() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      _hasInitialized = true;
      _isLoading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  Future<void> refreshOnAppOpen({bool force = false}) async {
    final now = DateTime.now();
    final lastAttempt = _lastAppOpenRefreshAttemptAt;

    if (!force &&
        lastAttempt != null &&
        now.difference(lastAttempt) < _appOpenRefreshMinInterval) {
      AppLog.health.debug(
        'refreshOnAppOpen() skipped - throttled',
        payload: 'lastAttempt=${lastAttempt.toIso8601String()}',
      );
      return;
    }

    _lastAppOpenRefreshAttemptAt = now;

    if (!_hasInitialized || !_isHealthConnectAvailable || !_hasPermissions) {
      await initialize();
    }

    if (!_isHealthConnectAvailable || !_hasPermissions) {
      AppLog.health.debug(
        'refreshOnAppOpen() skipped - Health Connect not ready',
        payload:
            'available=$_isHealthConnectAvailable permissions=$_hasPermissions',
      );
      return;
    }

    AppLog.health.info('refreshOnAppOpen() started');
    await refreshBackground(source: 'app_open');
    AppLog.health.info('refreshOnAppOpen() finished');
  }

  /// Fetches fresh data from HC and updates the DB.
  ///
  /// Quota error -> silent failure: DB data preserved, [lastSyncedAt] unchanged.
  /// Other errors -> [errorMessage] set as usual.
  Future<void> refresh() async {
    if (_inFlight) return;
    if (!_isHealthConnectAvailable || !_hasPermissions) {
      await initialize();
      return;
    }
    final syncStart = DateTime.now();
    final stepsBefore = todaySteps;
    final lastRecordBefore = _stepsHistory.lastOrNull;

    _debugLastRefreshSource = 'manual';
    _debugLastRefreshStartedAt = syncStart;
    _debugLastRefreshCompletedAt = null;
    _debugTodayStepsBeforeRefresh = stepsBefore;
    _debugLastRecordStepsBefore = lastRecordBefore?.steps;
    _debugLastRecordDateBefore = lastRecordBefore?.date;
    _debugLastRefreshError = null;
    _debugLastFetchedTodaySteps = null;
    _debugLastQueryDays = null;

    _inFlight = true;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    String? syncError;
    try {
      await _refreshHistoryAccess(interactive: true);
      _debugLastQueryDays = _historyLookbackDays;
      await _fetchFromHC();
      _loadFromDb();
      _debugLastFetchedTodaySteps = stepsForDate(DateTime.now());
    } on _QuotaExceededException {
      syncError = 'quota_exceeded';
      _debugLastRefreshError = syncError;
    } catch (e, st) {
      _errorMessage = e.toString();
      syncError = e.toString();
      _debugLastRefreshError = syncError;
      AppLog.health.error(
        'FitnessProvider.refresh() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      final completedAt = DateTime.now();
      _debugLastRefreshCompletedAt = completedAt;
      _debugLastRefreshDurationMs =
          completedAt.difference(syncStart).inMilliseconds;
      _debugTodayStepsAfterRefresh = todaySteps;
      _debugLastRecordStepsAfter = _stepsHistory.lastOrNull?.steps;
      _debugLastRecordDateAfter = _stepsHistory.lastOrNull?.date;
      _isRefreshing = false;
      _inFlight = false;
      notifyListeners();
    }

    unawaited(DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
      timestamp: syncStart,
      source: 'manual',
      feature: 'health',
      result: syncError != null ? 'failure' : 'success',
      durationMs: DateTime.now().difference(syncStart).inMilliseconds,
      errorMessage: syncError,
      extra: {
        'stepsBefore': stepsBefore,
        'stepsAfter': todaySteps,
        'stepsDateMatch': debugTodayStepsDateMatch,
        'lastRecordDate': _stepsHistory.lastOrNull != null
            ? _fmtDateKey(_stepsHistory.lastOrNull!.date)
            : null,
        'lastRecordSteps': _stepsHistory.lastOrNull?.steps,
        'recordCount': debugStepsRecordCount,
        'queryDays': _debugLastQueryDays,
        'fetchedTodaySteps': _debugLastFetchedTodaySteps,
      },
    )));
  }

  /// Background-safe variant of [refresh] - never shows interactive dialogs.
  /// Safe to call from a WorkManager isolate.
  Future<void> refreshBackground({String source = 'background'}) async {
    if (_inFlight) return;
    if (!_isHealthConnectAvailable || !_hasPermissions) {
      await initialize();
      return;
    }
    final syncStart = DateTime.now();
    final stepsBefore = todaySteps;
    final lastRecordBefore = _stepsHistory.lastOrNull;

    _debugLastRefreshSource = source;
    _debugLastRefreshStartedAt = syncStart;
    _debugLastRefreshCompletedAt = null;
    _debugTodayStepsBeforeRefresh = stepsBefore;
    _debugLastRecordStepsBefore = lastRecordBefore?.steps;
    _debugLastRecordDateBefore = lastRecordBefore?.date;
    _debugLastRefreshError = null;
    _debugLastFetchedTodaySteps = null;
    _debugLastQueryDays = null;

    _inFlight = true;
    _isRefreshing = true;
    notifyListeners();

    String? syncError;
    try {
      await _refreshHistoryAccess(interactive: false);
      await _refreshBackgroundAccess(interactive: false);
      if (source == 'background' && !_hasBackgroundDataAccess) {
        syncError = 'background_permission_missing';
        _debugLastRefreshError = syncError;
        AppLog.health.warn(
          'FitnessProvider.refreshBackground() skipped - missing Health Connect background permission',
        );
        _loadFromDb();
      } else {
        _debugLastQueryDays = _historyLookbackDays;
        await _fetchFromHC();
        _loadFromDb();
        _debugLastFetchedTodaySteps = stepsForDate(DateTime.now());
      }
    } on _QuotaExceededException {
      syncError = 'quota_exceeded';
      _debugLastRefreshError = syncError;
    } catch (e, st) {
      syncError = e.toString();
      _debugLastRefreshError = syncError;
      AppLog.health.error(
        'FitnessProvider.refreshBackground() failed',
        err: e,
        stackTrace: st,
      );
    } finally {
      final completedAt = DateTime.now();
      _debugLastRefreshCompletedAt = completedAt;
      _debugLastRefreshDurationMs =
          completedAt.difference(syncStart).inMilliseconds;
      _debugTodayStepsAfterRefresh = todaySteps;
      _debugLastRecordStepsAfter = _stepsHistory.lastOrNull?.steps;
      _debugLastRecordDateAfter = _stepsHistory.lastOrNull?.date;
      _isRefreshing = false;
      _inFlight = false;
      notifyListeners();
    }

    unawaited(DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
      timestamp: syncStart,
      source: source,
      feature: 'health',
      result: syncError != null ? 'failure' : 'success',
      durationMs: DateTime.now().difference(syncStart).inMilliseconds,
      errorMessage: syncError,
      extra: {
        'stepsBefore': stepsBefore,
        'stepsAfter': todaySteps,
        'stepsDateMatch': stepsForDate(DateTime.now()),
        'lastRecordDate': _stepsHistory.lastOrNull != null
            ? _fmtDateKey(_stepsHistory.lastOrNull!.date)
            : null,
        'lastRecordSteps': _stepsHistory.lastOrNull?.steps,
        'recordCount': debugStepsRecordCount,
        'queryDays': _debugLastQueryDays,
        'fetchedTodaySteps': _debugLastFetchedTodaySteps,
      },
    )));
  }

  Future<void> refreshRange(DateTime start, DateTime end) async {
    if (_inFlight) return;

    if (!_isHealthConnectAvailable || !_hasPermissions) {
      await initialize();

      if (!_isHealthConnectAvailable || !_hasPermissions) {
        return;
      }
    }

    final syncStart = DateTime.now();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    _debugLastRefreshSource = 'range';
    _debugLastRefreshStartedAt = syncStart;
    _debugLastRefreshCompletedAt = null;
    _debugLastRefreshError = null;
    _debugLastQueryDays =
        normalizedEnd.difference(normalizedStart).inDays.abs() + 1;

    _inFlight = true;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    String? syncError;

    try {
      await _refreshHistoryAccess(interactive: true);
      await _fetchOverviewRangeFromHC(normalizedStart, normalizedEnd);
      _loadFromDb();
      _debugLastFetchedTodaySteps = stepsForDate(DateTime.now());
    } on _QuotaExceededException {
      syncError = 'quota_exceeded';
      _debugLastRefreshError = syncError;

      // Preserve UI from existing DB cache.
      _loadFromDb();
    } catch (e, st) {
      syncError = e.toString();
      _errorMessage = syncError;
      _debugLastRefreshError = syncError;
      AppLog.health.error(
        'FitnessProvider.refreshRange() failed',
        err: e,
        stackTrace: st,
      );

      // Preserve UI from existing DB cache if fetch partially failed.
      _loadFromDb();
    } finally {
      final completedAt = DateTime.now();
      _debugLastRefreshCompletedAt = completedAt;
      _debugLastRefreshDurationMs =
          completedAt.difference(syncStart).inMilliseconds;
      _debugTodayStepsAfterRefresh = todaySteps;
      _debugLastRecordStepsAfter = _stepsHistory.lastOrNull?.steps;
      _debugLastRecordDateAfter = _stepsHistory.lastOrNull?.date;

      _isRefreshing = false;
      _inFlight = false;
      notifyListeners();
    }

    unawaited(
      DevToolsSyncLogger.instance.record(
        DevToolsSyncEvent(
          timestamp: syncStart,
          source: 'manual',
          feature: 'health',
          result: syncError != null ? 'failure' : 'success',
          durationMs: DateTime.now().difference(syncStart).inMilliseconds,
          errorMessage: syncError,
          extra: {
            'rangeStart': _fmtDateKey(normalizedStart),
            'rangeEnd': _fmtDateKey(normalizedEnd),
            'stepsAfter': todaySteps,
            'stepsDateMatch': debugTodayStepsDateMatch,
            'lastRecordDate': _stepsHistory.lastOrNull != null
                ? _fmtDateKey(_stepsHistory.lastOrNull!.date)
                : null,
            'lastRecordSteps': _stepsHistory.lastOrNull?.steps,
            'recordCount': debugStepsRecordCount,
            'queryDays': _debugLastQueryDays,
          },
        ),
      ),
    );
  }

  Future<void> installHealthConnect() => _service.installHealthConnect();

  /// Requests the WORKOUT permission and, if granted, fetches activities and
  /// persists them to the DB.
  Future<void> requestWorkoutPermission() async {
    if (_inFlight) return;
    _inFlight = true;
    notifyListeners();
    try {
      final granted = await _service.requestWorkoutPermission();
      _workoutPermissionGranted = granted;
      if (granted) {
        await _refreshHistoryAccess(interactive: true);
        final now = DateTime.now();
        _activities = await _service.getActivities(
          now.subtract(Duration(days: _historyLookbackDays - 1)),
          now,
        );
        await _db.saveActivitiesAndPermission(
          activities: _activities,
          workoutPermission: true,
        );
      }
    } catch (_) {
      _workoutPermissionGranted = false;
    } finally {
      _inFlight = false;
      notifyListeners();
    }
  }

  // --- Private --------------------------------------------------------------

  /// Synchronous - HealthDatabase pre-loads everything from Isar in open().
  void _loadFromDb() {
    _stepsHistory = _db.stepsHistory;
    _activeCaloriesHistory = _db.caloriesHistory;
    _basalCaloriesHistory = _db.basalCaloriesHistory;
    _weightHistory = _db.weightHistory;
    _latestBodyFat = _db.latestBodyFat;
    _workoutPermissionGranted = _db.workoutPermission;
    _activities = _db.activities;
    _sleepHistory = _db.sleepHistory;
    _todaySleep = _sleepHistory.isNotEmpty ? _sleepHistory.first : null;
    _lastSyncedAt = _db.lastSyncedAt;
    AppLog.app.warn(
      'FitnessProvider(${identityHashCode(this)}): _loadFromDb from '
      'HealthDatabase(${identityHashCode(_db)}) - '
      'dbSteps=${_db.stepsHistory.length}, '
      'dbLast=${_db.stepsHistory.isEmpty ? "none" : "${_fmtDateKey(_db.stepsHistory.last.date)}=${_db.stepsHistory.last.steps}"}, '
      'dbToday=${_db.stepsHistory.where((r) => _fmtDateKey(r.date) == _fmtDateKey(DateTime.now())).map((r) => r.steps).toList()}, '
      'providerSteps=${_stepsHistory.length}, '
      'providerLast=${_stepsHistory.isEmpty ? "none" : "${_fmtDateKey(_stepsHistory.last.date)}=${_stepsHistory.last.steps}"}, '
      'providerToday=${_stepsHistory.where((r) => _fmtDateKey(r.date) == _fmtDateKey(DateTime.now())).map((r) => r.steps).toList()}',
    );
  }

  Future<void> _refreshHistoryAccess({required bool interactive}) async {
    if (!_hasPermissions) {
      _hasHistoricalDataAccess = false;
      return;
    }

    final available = await _service.isHistoryPermissionAvailable();
    if (!available) {
      _hasHistoricalDataAccess = false;
      _historyPermissionDeniedThisSession = false;
      return;
    }

    var authorized = await _service.hasHistoryPermission();
    if (!authorized && interactive && !_historyPermissionDeniedThisSession) {
      authorized = await _service.requestHistoryPermissionIfAvailable();
      _historyPermissionDeniedThisSession = !authorized;
    }

    if (authorized) {
      _historyPermissionDeniedThisSession = false;
    }

    _hasHistoricalDataAccess = authorized;
  }

  Future<void> _refreshBackgroundAccess({required bool interactive}) async {
    if (!_hasPermissions) {
      _hasBackgroundDataAccess = false;
      return;
    }

    final available = await _service.isBackgroundPermissionAvailable();
    if (!available) {
      _hasBackgroundDataAccess = false;
      _backgroundPermissionDeniedThisSession = false;
      return;
    }

    var authorized = await _service.hasBackgroundPermission();
    if (!authorized && interactive && !_backgroundPermissionDeniedThisSession) {
      authorized = await _service.requestBackgroundPermissionIfAvailable();
      _backgroundPermissionDeniedThisSession = !authorized;
    }

    if (authorized) {
      _backgroundPermissionDeniedThisSession = false;
    }

    _hasBackgroundDataAccess = authorized;
  }

  /// Fetches recent data from Health Connect and safely merges successful
  /// metric groups into the local DB.
  ///
  /// Safety rules:
  /// - no full-table clear during normal refresh
  /// - failed metric groups are skipped
  /// - existing cached data is preserved on failure
  /// - quota errors are captured but do not overwrite cache with empty/zero data
  Future<void> _fetchFromHC({int? daysOverride}) async {
    final days = daysOverride ?? _normalRefreshDays;
    final syncTime = DateTime.now();

    var anySuccess = false;
    var anyFailure = false;

    final succeededGroups = <String>[];
    final failedGroups = <String>[];

    List<StepsRecord>? fetchedSteps;

    // --- Steps --------------------------------------------------------------
    try {
      fetchedSteps = await _service.getStepsHistory(days);
      fetchedSteps = _preserveCachedStepsOnSuspiciousZeroRead(fetchedSteps);

      AppLog.health.info(
        'Health sync steps fetched',
        payload: _stepsSummary(fetchedSteps),
      );

      if (fetchedSteps.isNotEmpty) {
        await _db.saveStepsPartial(fetchedSteps);
        succeededGroups.add('steps');
        anySuccess = true;
      } else {
        // Empty can be valid, but normal refresh must not wipe old cache.
        failedGroups.add('steps_empty_skipped');
        anyFailure = true;
      }
    } catch (e, st) {
      failedGroups.add(_isQuotaError(e) ? 'steps_quota' : 'steps_error');
      anyFailure = true;
      AppLog.health.error(
        'Health sync steps failed',
        err: e,
        stackTrace: st,
      );
    }

    // --- Active calories ----------------------------------------------------
    try {
      final calories = await _service.getActiveCaloriesHistory(days);
      var basalCalories = <double>[];
      try {
        basalCalories = await _service.getBasalCaloriesHistory(days);
      } catch (e) {
        failedGroups.add(
            _isQuotaError(e) ? 'basalCalories_quota' : 'basalCalories_error');
      }

      // Current calorie model is index-aligned to step dates.
      // If steps failed, do not guess date keys for calories in this refactor.
      if ((calories.isNotEmpty || basalCalories.isNotEmpty) &&
          fetchedSteps != null &&
          fetchedSteps.isNotEmpty) {
        await _db.saveCaloriesPartial(
          dateReference: fetchedSteps,
          calories: calories,
          basalCalories: basalCalories,
        );
        succeededGroups.add('calories');
        anySuccess = true;
      } else {
        failedGroups.add('calories_empty_or_no_date_reference_skipped');
        anyFailure = true;
      }
    } catch (e) {
      failedGroups.add(_isQuotaError(e) ? 'calories_quota' : 'calories_error');
      anyFailure = true;
    }

    // --- Weight -------------------------------------------------------------
    try {
      final weight = await _service.getWeightHistory(days);

      if (weight.isNotEmpty) {
        await _db.saveWeightPartial(weight);
        succeededGroups.add('weight');
        anySuccess = true;
      } else {
        // Empty weight is common; preserve existing cache.
        failedGroups.add('weight_empty_skipped');
      }
    } catch (e) {
      failedGroups.add(_isQuotaError(e) ? 'weight_quota' : 'weight_error');
      anyFailure = true;
    }

    // --- Latest body fat ----------------------------------------------------
    try {
      final latestBodyFat = await _service.getLatestBodyFat();

      if (latestBodyFat != null) {
        _latestBodyFat = latestBodyFat;
        await _db.updateMeta(latestBodyFat: latestBodyFat);
        succeededGroups.add('bodyFat');
        anySuccess = true;
      }
    } catch (e) {
      failedGroups.add(_isQuotaError(e) ? 'bodyFat_quota' : 'bodyFat_error');
      anyFailure = true;
    }

    // --- Workout permission + activities ------------------------------------
    try {
      final workoutPermission = await _service.hasWorkoutPermission() == true;
      _workoutPermissionGranted = workoutPermission;
      await _db.updateMeta(workoutPermission: workoutPermission);

      if (workoutPermission) {
        try {
          final now = DateTime.now();
          final activities = await _service.getActivities(
            now.subtract(Duration(days: days - 1)),
            now,
          );

          if (activities.isNotEmpty) {
            await _db.saveActivitiesPartial(activities);
            succeededGroups.add('activities');
            anySuccess = true;
          } else {
            // Empty activities can be valid. Preserve existing cache.
            failedGroups.add('activities_empty_skipped');
          }
        } catch (e) {
          failedGroups.add(
            _isQuotaError(e) ? 'activities_quota' : 'activities_error',
          );
          anyFailure = true;
        }
      }
    } catch (e) {
      failedGroups.add(
        _isQuotaError(e)
            ? 'workoutPermission_quota'
            : 'workoutPermission_error',
      );
      anyFailure = true;
    }

    // --- Sleep --------------------------------------------------------------
    try {
      final sleep = await _service.getSleepHistory(days);

      if (sleep.isNotEmpty) {
        await _db.saveSleepPartial(sleep);
        succeededGroups.add('sleep');
        anySuccess = true;
      } else {
        // Empty sleep can happen; preserve existing cache.
        failedGroups.add('sleep_empty_skipped');
      }
    } catch (e) {
      failedGroups.add(_isQuotaError(e) ? 'sleep_quota' : 'sleep_error');
      anyFailure = true;
    }

    if (!anySuccess) {
      _debugLastRefreshError = failedGroups.isEmpty
          ? 'health_sync_no_successful_groups'
          : 'health_sync_failed: ${failedGroups.join(",")}';
      throw Exception(_debugLastRefreshError);
    }

    _lastSyncedAt = syncTime;

    await _db.updateMeta(
      lastSyncedAt: _lastSyncedAt!,
      workoutPermission: _workoutPermissionGranted,
      latestBodyFat: _latestBodyFat,
    );

    _loadFromDb();

    _debugLastRefreshError =
        anyFailure ? 'partial_success failed=${failedGroups.join(",")}' : null;

    _debugLastFetchedTodaySteps = stepsForDate(DateTime.now());
    _debugLastQueryDays = days;
  }

  Future<void> _fetchOverviewRangeFromHC(DateTime start, DateTime end) async {
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day);
    final rangeEndExclusive = rangeEnd.add(const Duration(days: 1));

    List<StepsRecord> steps;
    List<double> calories;
    List<double> basalCalories;
    List<WeightRecord> weight;
    List<SleepRecord> sleep;
    double? latestBodyFat;

    try {
      steps = await _service.getStepsHistoryForRange(
        rangeStart,
        rangeEndExclusive,
      );
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      rethrow;
    }

    try {
      calories = await _service.getActiveCaloriesHistoryForRange(
        rangeStart,
        rangeEndExclusive,
      );
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      rethrow;
    }

    try {
      basalCalories = await _service.getBasalCaloriesHistoryForRange(
        rangeStart,
        rangeEndExclusive,
      );
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      basalCalories = const [];
    }

    try {
      weight = await _service.getWeightHistoryForRange(
        rangeStart,
        rangeEndExclusive,
      );
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      rethrow;
    }

    try {
      sleep = await _service.getSleepHistoryForRange(
        rangeStart,
        rangeEndExclusive,
      );
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      rethrow;
    }

    try {
      latestBodyFat = await _service.getLatestBodyFat(lookbackDays: 365);
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      rethrow;
    }

    steps = steps
        .where((r) => _isDateInInclusiveRange(r.date, rangeStart, rangeEnd))
        .toList();

    weight = weight
        .where((r) => _isDateInInclusiveRange(r.date, rangeStart, rangeEnd))
        .toList();

    sleep = sleep
        .where((r) => _isDateInInclusiveRange(r.wakeTime, rangeStart, rangeEnd))
        .toList();

    // Calories are positional/aligned with the fetched steps range.
    // If HC returned one extra day because of exclusive end handling, trim it.
    if (calories.length > steps.length) {
      calories = calories.sublist(0, steps.length);
    }
    if (basalCalories.length > steps.length) {
      basalCalories = basalCalories.sublist(0, steps.length);
    }

    _lastSyncedAt = DateTime.now();

    await _db.saveOverviewRange(
      steps: steps,
      calories: calories,
      basalCalories: basalCalories,
      weight: weight,
      sleep: sleep,
      latestBodyFat: latestBodyFat,
      lastSyncedAt: _lastSyncedAt!,
    );

    _loadFromDb();
  }

  bool _isDateInInclusiveRange(
    DateTime value,
    DateTime start,
    DateTime end,
  ) {
    final day = DateTime(value.year, value.month, value.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  List<StepsRecord> _preserveCachedStepsOnSuspiciousZeroRead(
    List<StepsRecord> fetched,
  ) {
    if (fetched.isEmpty || _stepsHistory.isEmpty) return fetched;

    final cachedByKey = {
      for (final record in _stepsHistory) _fmtDateKey(record.date): record
    };
    var preservedCount = 0;

    final merged = [
      for (final record in fetched)
        if (record.steps == 0 &&
            (cachedByKey[_fmtDateKey(record.date)]?.steps ?? 0) > 0)
          () {
            preservedCount++;
            return cachedByKey[_fmtDateKey(record.date)]!;
          }()
        else
          record,
    ];

    if (preservedCount > 0) {
      AppLog.health.warn(
        'Preserved cached step rows after zero Health Connect read',
        payload: 'preserved=$preservedCount fetched=${_stepsSummary(fetched)} '
            'merged=${_stepsSummary(merged)}',
      );
    }

    return merged;
  }

  String _stepsSummary(List<StepsRecord> records) {
    if (records.isEmpty) return 'count=0';

    final todayKey = _fmtDateKey(DateTime.now());
    final today = records
        .where((record) => _fmtDateKey(record.date) == todayKey)
        .map((record) => record.steps)
        .toList();
    final total = records.fold<int>(0, (sum, record) => sum + record.steps);
    final nonZero = records.where((record) => record.steps > 0).length;

    return 'count=${records.length}, '
        'first=${_fmtDateKey(records.first.date)}=${records.first.steps}, '
        'last=${_fmtDateKey(records.last.date)}=${records.last.steps}, '
        'today=$today, nonZero=$nonZero, total=$total';
  }

  int get _historyLookbackDays =>
      _hasHistoricalDataAccess ? _extendedHistoryDays : _defaultHistoryDays;

  List<StepsRecord> _recentStepsHistory(int days) {
    if (_stepsHistory.length <= days) return _stepsHistory;
    return _stepsHistory.sublist(_stepsHistory.length - days);
  }

  List<double> _recentCaloriesHistory(int days) {
    if (_activeCaloriesHistory.length <= days) return _activeCaloriesHistory;
    return _activeCaloriesHistory.sublist(_activeCaloriesHistory.length - days);
  }

  static bool _isQuotaError(Object e) =>
      e.toString().toLowerCase().contains('quota exceeded');

  static String _fmtDateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

class _QuotaExceededException implements Exception {
  const _QuotaExceededException();
}
