import 'package:flutter/foundation.dart';
import '../models/activity_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_card_data.dart';
import '../models/weight_record.dart';
import '../services/health_connect_service.dart';

enum FitnessAccessState {
  checking,
  unavailable,
  permissionRequired,
  ready,
}

class FitnessProvider extends ChangeNotifier {
  final HealthConnectService _service;

  FitnessProvider(this._service);

  // ─── Concurrency guard ────────────────────────────────────────────────────
  bool _inFlight = false;

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _hasInitialized = false;
  bool _isRefreshing = false;
  bool _isHealthConnectAvailable = false;
  bool _hasPermissions = false;
  String? _errorMessage;
  DateTime? _lastSyncedAt;

  /// 30-day step records, oldest first.
  List<StepsRecord> _stepsHistory = [];

  /// 30 daily active-calorie totals (kcal), oldest first.
  List<double> _activeCaloriesHistory = [];

  /// Weight readings in the last 30 days, oldest first.
  List<WeightRecord> _weightHistory = [];

  /// Most recent body fat percentage, or null if unavailable.
  double? _latestBodyFat;

  /// Workout/activity records for the last 30 days, newest first.
  List<ActivityRecord> _activities = [];

  /// True when the WORKOUT Health Connect permission has been verified as
  /// granted. False means either denied or not yet checked.
  bool _workoutPermissionGranted = false;

  /// Aggregated sleep record for last night, or null if unavailable.
  SleepRecord? _todaySleep;

  /// Sleep records for the last 7 nights, newest first.
  List<SleepRecord> _sleepHistory = [];

  // ─── Public getters ───────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  bool get isRefreshing => _isRefreshing;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;
  bool get hasPermissions => _hasPermissions;

  // UI should render from this state so "permission required" is never shown
  // before the startup availability/permission check has actually finished.
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

  /// Today's step count (last record in 30-day history).
  int get todaySteps =>
      _stepsHistory.isNotEmpty ? _stepsHistory.last.steps : 0;

  /// Sum of steps in the most recent 7 records.
  int get stepsWeekTotal {
    if (_stepsHistory.isEmpty) return 0;
    final slice = _stepsHistory.length >= 7
        ? _stepsHistory.sublist(_stepsHistory.length - 7)
        : _stepsHistory;
    return slice.fold(0, (sum, r) => sum + r.steps);
  }

  /// Sum of all steps in the 30-day history.
  int get stepsMonthTotal =>
      _stepsHistory.fold(0, (sum, r) => sum + r.steps);

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
      _activeCaloriesHistory.fold<double>(0.0, (sum, v) => sum + v);

  // ─── Latest weight ────────────────────────────────────────────────────────

  double? get latestWeight =>
      _weightHistory.isNotEmpty ? _weightHistory.last.weight : null;

  // ─── Date-range queries ───────────────────────────────────────────────────

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _inRange(DateTime d, DateTime start, DateTime end) {
    final date = DateTime(d.year, d.month, d.day);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// Steps for a specific date. Returns 0 if no record for that day.
  int stepsForDate(DateTime date) {
    final r = _stepsHistory
        .where((r) => _sameDay(r.date, date))
        .firstOrNull;
    return r?.steps ?? 0;
  }

  /// Average steps per day for records within [start, end] (inclusive).
  /// Uses only days that have a record — days with no data are excluded.
  int stepsAvgForRange(DateTime start, DateTime end) {
    final records =
        _stepsHistory.where((r) => _inRange(r.date, start, end)).toList();
    if (records.isEmpty) return 0;
    final total = records.fold(0, (s, r) => s + r.steps);
    return (total / records.length).round();
  }

  /// Steps records within [start, end], for passing to chart widgets.
  List<StepsRecord> stepsHistoryForRange(DateTime start, DateTime end) =>
      _stepsHistory.where((r) => _inRange(r.date, start, end)).toList();

  /// Active calories burned on a specific date.
  /// Aligns with _stepsHistory by index (both are 30-day same-order arrays).
  double activeCaloriesBurnedForDate(DateTime date) {
    final idx =
        _stepsHistory.indexWhere((r) => _sameDay(r.date, date));
    if (idx < 0 || idx >= _activeCaloriesHistory.length) return 0;
    return _activeCaloriesHistory[idx];
  }

  /// Average active calories burned per day for records within [start, end].
  double activeCaloriesBurnedAvgForRange(DateTime start, DateTime end) {
    final indices = <int>[];
    for (var i = 0; i < _stepsHistory.length; i++) {
      if (_inRange(_stepsHistory[i].date, start, end)) indices.add(i);
    }
    if (indices.isEmpty) return 0;
    var total = 0.0;
    for (final idx in indices) {
      if (idx < _activeCaloriesHistory.length) {
        total += _activeCaloriesHistory[idx];
      }
    }
    return total / indices.length;
  }

  /// Weight records within [start, end], for passing to chart widgets.
  List<WeightRecord> weightHistoryForRange(DateTime start, DateTime end) =>
      _weightHistory.where((r) => _inRange(r.date, start, end)).toList();

  /// Last known weight within [start, end], plus trend (end minus start).
  /// Falls back to the global latest weight when the period has no records.
  ({double? lastKnown, double? trend}) weightMetricsForRange(
      DateTime start, DateTime end) {
    final records = weightHistoryForRange(start, end);
    if (records.isEmpty) return (lastKnown: latestWeight, trend: null);
    final lastKnown = records.last.weight;
    final trend =
        records.length >= 2 ? records.last.weight - records.first.weight : null;
    return (lastKnown: lastKnown, trend: trend);
  }

  /// Sleep record for the night that ends on [date] (wake-time date).
  SleepRecord? sleepForDate(DateTime date) =>
      _sleepHistory.where((r) => _sameDay(r.wakeTime, date)).firstOrNull;

  // ─── Weight aggregation ───────────────────────────────────────────────────

  /// Last recorded weight strictly before [date].
  double? previousWeightBefore(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final before = _weightHistory
        .where((r) => DateTime(r.date.year, r.date.month, r.date.day)
            .isBefore(day))
        .toList();
    return before.isNotEmpty ? before.last.weight : null;
  }

  /// Average weight for the 7-day week starting on [weekStart] (Monday).
  double? weekAvgWeight(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final records = weightHistoryForRange(weekStart, end);
    if (records.isEmpty) return null;
    return records.map((r) => r.weight).reduce((a, b) => a + b) /
        records.length;
  }

  /// Average weight for the calendar month containing [monthRef].
  double? monthAvgWeight(DateTime monthRef) {
    final start = DateTime(monthRef.year, monthRef.month, 1);
    final end = DateTime(monthRef.year, monthRef.month + 1, 0);
    final records = weightHistoryForRange(start, end);
    if (records.isEmpty) return null;
    return records.map((r) => r.weight).reduce((a, b) => a + b) /
        records.length;
  }

  /// Last [maxPoints] weight records as chart points, oldest first.
  List<WeightChartPoint> dailyWeightChart(int maxPoints) {
    final src = _weightHistory.length > maxPoints
        ? _weightHistory.sublist(_weightHistory.length - maxPoints)
        : _weightHistory;
    return src
        .map((r) => WeightChartPoint(date: r.date, weight: r.weight))
        .toList();
  }

  /// Weight chart points within [start, end], oldest first.
  ///
  /// If multiple measurements exist for the same day, only the last one
  /// for that day is used so week/month charts stay readable and stable.
  List<WeightChartPoint> weightChartForRange(DateTime start, DateTime end) {
    final records = weightHistoryForRange(start, end);
    if (records.isEmpty) return const [];

    final latestPerDay = <DateTime, WeightRecord>{};
    for (final record in records) {
      final day = DateTime(record.date.year, record.date.month, record.date.day);
      latestPerDay[day] = record;
    }

    final days = latestPerDay.keys.toList()..sort();
    return [
      for (final day in days)
        WeightChartPoint(
          date: day,
          weight: latestPerDay[day]!.weight,
        ),
    ];
  }

  /// Weekly average weights for chart, last [weeks] weeks, oldest first.
  /// Weeks with no data are omitted.
  List<WeightChartPoint> weeklyWeightChart(int weeks) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final currentWeekStart =
        todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
    final result = <WeightChartPoint>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final ws = currentWeekStart.subtract(Duration(days: 7 * i));
      final avg = weekAvgWeight(ws);
      if (avg != null) result.add(WeightChartPoint(date: ws, weight: avg));
    }
    return result;
  }

  /// Monthly average weights for chart, last [months] months, oldest first.
  /// Months with no data are omitted.
  List<WeightChartPoint> monthlyWeightChart(int months) {
    final today = DateTime.now();
    final result = <WeightChartPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final ref = DateTime(today.year, today.month - i, 1);
      final avg = monthAvgWeight(ref);
      if (avg != null) result.add(WeightChartPoint(date: ref, weight: avg));
    }
    return result;
  }

  // ─── Sleep history ────────────────────────────────────────────────────────

  /// Average sleep duration for nights whose wake-time falls in [start, end].
  Duration? avgSleepForRange(DateTime start, DateTime end) {
    final records =
        _sleepHistory.where((r) => _inRange(r.wakeTime, start, end)).toList();
    if (records.isEmpty) return null;
    final totalSec =
        records.fold(0, (s, r) => s + r.totalDuration.inSeconds);
    return Duration(seconds: (totalSec / records.length).round());
  }

  // ─── Public methods ───────────────────────────────────────────────────────

  /// Checks HC availability and the core permissions needed to enter the app.
  /// Safe to call multiple times — ignores concurrent calls.
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

      // Check without prompting — only fetch if permissions already exist.
      final perms = await _service.hasPermissions();
      _hasPermissions = perms == true;
      if (_hasPermissions) await _fetchData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _hasInitialized = true;
      _isLoading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Shows the Health Connect permission dialog. On grant, fetches data.
  Future<void> requestPermissions() async {
    if (_inFlight) return;
    _inFlight = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isHealthConnectAvailable = await _service.isAvailable(forceRefresh: true);
      if (!_isHealthConnectAvailable) return;

      _hasPermissions = await _service.requestPermissions();
      if (_hasPermissions) await _fetchData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _hasInitialized = true;
      _isLoading = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Refreshes health data. If HC is unavailable or permissions are missing,
  /// re-runs initialize() so the UI state is brought up to date.
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
      await _fetchData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isRefreshing = false;
      _inFlight = false;
      notifyListeners();
    }
  }

  /// Opens the Play Store page for Health Connect.
  Future<void> installHealthConnect() => _service.installHealthConnect();

  /// Requests the WORKOUT permission and, if granted, fetches activity data.
  Future<void> requestWorkoutPermission() async {
    if (_inFlight) return;
    _inFlight = true;
    notifyListeners();
    try {
      final granted = await _service.requestWorkoutPermission();
      _workoutPermissionGranted = granted;
      if (granted) {
        final now = DateTime.now();
        _activities = await _service.getActivities(
          now.subtract(const Duration(days: 30)),
          now,
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

  Future<void> _fetchData() async {
    const days = 30;
    try {
      _stepsHistory = await _service.getStepsHistory(days);
    } catch (_) {
      _stepsHistory = [];
    }
    try {
      _activeCaloriesHistory = await _service.getActiveCaloriesHistory(days);
    } catch (_) {
      _activeCaloriesHistory = [];
    }
    try {
      _weightHistory = await _service.getWeightHistory(days);
    } catch (_) {
      _weightHistory = [];
    }
    try {
      _latestBodyFat = await _service.getLatestBodyFat();
    } catch (_) {
      _latestBodyFat = null;
    }
    try {
      final hasPerm = await _service.hasWorkoutPermission();
      _workoutPermissionGranted = hasPerm == true;
    } catch (_) {
      _workoutPermissionGranted = false;
    }
    if (_workoutPermissionGranted) {
      try {
        final now = DateTime.now();
        _activities = await _service.getActivities(
          now.subtract(const Duration(days: 30)),
          now,
        );
      } catch (_) {
        _activities = [];
      }
    } else {
      _activities = [];
    }
    try {
      final now = DateTime.now();
      final futures = List.generate(7, (i) async {
        try {
          return await _service.getSleepForNight(
              now.subtract(Duration(days: i)));
        } catch (_) {
          return null;
        }
      });
      final results = await Future.wait(futures);
      _sleepHistory = results.whereType<SleepRecord>().toList();
      _todaySleep = _sleepHistory.isNotEmpty ? _sleepHistory.first : null;
    } catch (_) {
      _sleepHistory = [];
      _todaySleep = null;
    }
    _lastSyncedAt = DateTime.now();
  }
}
