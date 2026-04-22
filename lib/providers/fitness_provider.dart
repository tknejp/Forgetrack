import 'package:flutter/foundation.dart';
import '../models/activity_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_card_data.dart';
import '../models/weight_record.dart';
import '../services/health_connect_service.dart';
import '../services/db/health_database.dart';
import 'fitness_provider/fitness_queries.dart';

enum FitnessAccessState {
  checking,
  unavailable,
  permissionRequired,
  ready,
}

class FitnessProvider extends ChangeNotifier {
  static const int _defaultHistoryDays = 30;
  static const int _extendedHistoryDays = 365;

  final HealthConnectService _service;
  final HealthDatabase _db;

  FitnessProvider(this._service, this._db);

  // ─── Concurrency guard ────────────────────────────────────────────────────
  bool _inFlight = false;

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _hasInitialized = false;
  bool _isRefreshing = false;
  bool _isHealthConnectAvailable = false;
  bool _hasPermissions = false;
  bool _hasHistoricalDataAccess = false;
  bool _historyPermissionDeniedThisSession = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  List<StepsRecord> _stepsHistory = [];
  List<double> _activeCaloriesHistory = [];
  List<WeightRecord> _weightHistory = [];
  double? _latestBodyFat;
  List<ActivityRecord> _activities = [];
  bool _workoutPermissionGranted = false;
  SleepRecord? _todaySleep;
  List<SleepRecord> _sleepHistory = [];

  // ─── Public getters ───────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  bool get isRefreshing => _isRefreshing;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;
  bool get hasPermissions => _hasPermissions;
  bool get hasHistoricalDataAccess => _hasHistoricalDataAccess;

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
  SleepRecord? get todaySleep => _todaySleep;
  List<SleepRecord> get sleepHistory => _sleepHistory;

  // ─── Computed step totals ─────────────────────────────────────────────────

  int get todaySteps => _stepsHistory.isNotEmpty ? _stepsHistory.last.steps : 0;

  int get stepsWeekTotal {
    if (_stepsHistory.isEmpty) return 0;
    final slice = _stepsHistory.length >= 7
        ? _stepsHistory.sublist(_stepsHistory.length - 7)
        : _stepsHistory;
    return slice.fold(0, (sum, r) => sum + r.steps);
  }

  int get stepsMonthTotal => _recentStepsHistory(_defaultHistoryDays)
      .fold(0, (sum, r) => sum + r.steps);

  // ─── Computed calorie totals ──────────────────────────────────────────────

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

  // ─── Latest weight ────────────────────────────────────────────────────────

  double? get latestWeight =>
      _weightHistory.isNotEmpty ? _weightHistory.last.weight : null;

  // ─── Date-range queries (delegated to FitnessQueries) ─────────────────────

  int stepsForDate(DateTime date) =>
      FitnessQueries.stepsForDate(_stepsHistory, date);

  int stepsAvgForRange(DateTime start, DateTime end) =>
      FitnessQueries.stepsAvgForRange(_stepsHistory, start, end);

  List<StepsRecord> stepsHistoryForRange(DateTime start, DateTime end) =>
      FitnessQueries.stepsHistoryForRange(_stepsHistory, start, end);

  double activeCaloriesBurnedForDate(DateTime date) =>
      FitnessQueries.activeCaloriesBurnedForDate(
          _stepsHistory, _activeCaloriesHistory, date);

  double activeCaloriesBurnedAvgForRange(DateTime start, DateTime end) =>
      FitnessQueries.activeCaloriesBurnedAvgForRange(
          _stepsHistory, _activeCaloriesHistory, start, end);

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

  // ─── Weight aggregation (delegated to FitnessQueries) ─────────────────────

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

  // ─── Sleep history ────────────────────────────────────────────────────────

  Duration? avgSleepForRange(DateTime start, DateTime end) =>
      FitnessQueries.avgSleepForRange(_sleepHistory, start, end);

  // ─── Public methods ───────────────────────────────────────────────────────

  /// Checks HC availability and permissions, then loads data from the local
  /// DB cache. No Health Connect data reads — safe on every app start/resume.
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
        _loadFromDb();
      } else {
        _hasHistoricalDataAccess = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
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
        await _fetchFromHC();
      } else {
        _hasHistoricalDataAccess = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _hasInitialized = true;
      _isLoading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Fetches fresh data from HC and updates the DB.
  ///
  /// Quota error → silent failure: DB data preserved, [lastSyncedAt] unchanged.
  /// Other errors → [errorMessage] set as usual.
  Future<void> refresh() async {
    if (_inFlight) return;
    if (!_isHealthConnectAvailable || !_hasPermissions) {
      await initialize();
      return;
    }
    _inFlight = true;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _refreshHistoryAccess(interactive: true);
      await _fetchFromHC();
    } on _QuotaExceededException {
      // Quota exhausted — serve existing DB data, do not touch _lastSyncedAt.
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isRefreshing = false;
      _inFlight = false;
      notifyListeners();
    }
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

  // ─── Private ──────────────────────────────────────────────────────────────

  /// Synchronous — HealthDatabase pre-loads everything from Isar in open().
  void _loadFromDb() {
    _stepsHistory = _db.stepsHistory;
    _activeCaloriesHistory = _db.caloriesHistory;
    _weightHistory = _db.weightHistory;
    _latestBodyFat = _db.latestBodyFat;
    _workoutPermissionGranted = _db.workoutPermission;
    _activities = _db.activities;
    _sleepHistory = _db.sleepHistory;
    _todaySleep = _sleepHistory.isNotEmpty ? _sleepHistory.first : null;
    _lastSyncedAt = _db.lastSyncedAt;
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

  /// Fetches all data from HC. On success, persists to DB and stamps sync time.
  /// Throws [_QuotaExceededException] so [refresh] can handle it silently.
  Future<void> _fetchFromHC() async {
    final days = _historyLookbackDays;

    try {
      _stepsHistory = await _service.getStepsHistory(days);
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      _stepsHistory = [];
    }
    try {
      _activeCaloriesHistory = await _service.getActiveCaloriesHistory(days);
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      _activeCaloriesHistory = [];
    }
    try {
      _weightHistory = await _service.getWeightHistory(days);
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      _weightHistory = [];
    }
    try {
      _latestBodyFat = await _service.getLatestBodyFat();
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      _latestBodyFat = null;
    }
    try {
      _workoutPermissionGranted = await _service.hasWorkoutPermission() == true;
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      _workoutPermissionGranted = false;
    }
    if (_workoutPermissionGranted) {
      try {
        final now = DateTime.now();
        _activities = await _service.getActivities(
          now.subtract(Duration(days: days - 1)),
          now,
        );
      } catch (e) {
        if (_isQuotaError(e)) throw const _QuotaExceededException();
        _activities = [];
      }
    } else {
      _activities = [];
    }
    try {
      _sleepHistory = await _service.getSleepHistory(days);
      _todaySleep = _sleepHistory.isNotEmpty ? _sleepHistory.first : null;
    } catch (e) {
      if (_isQuotaError(e)) throw const _QuotaExceededException();
      _sleepHistory = [];
      _todaySleep = null;
    }

    // All HC calls succeeded — persist and stamp the sync time.
    _lastSyncedAt = DateTime.now();
    await _db.saveAll(
      steps: _stepsHistory,
      calories: _activeCaloriesHistory,
      weight: _weightHistory,
      sleep: _sleepHistory,
      activities: _activities,
      workoutPermission: _workoutPermissionGranted,
      latestBodyFat: _latestBodyFat,
      lastSyncedAt: _lastSyncedAt!,
    );
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
}

class _QuotaExceededException implements Exception {
  const _QuotaExceededException();
}
