import 'package:flutter/foundation.dart';
import '../models/activity_record.dart';
import '../models/sleep_record.dart';
import '../models/weight_record.dart';
import '../services/health_connect_service.dart';

class FitnessProvider extends ChangeNotifier {
  final HealthConnectService _service;

  FitnessProvider(this._service);

  // ─── Concurrency guard ────────────────────────────────────────────────────
  bool _inFlight = false;

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isLoading = false;
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

  /// Aggregated sleep record for last night, or null if unavailable.
  SleepRecord? _todaySleep;

  // ─── Public getters ───────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isHealthConnectAvailable => _isHealthConnectAvailable;
  bool get hasPermissions => _hasPermissions;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  List<StepsRecord> get stepsHistory => _stepsHistory;
  List<ActivityRecord> get activities => _activities;
  List<WeightRecord> get weightHistory => _weightHistory;
  double? get latestBodyFat => _latestBodyFat;
  SleepRecord? get todaySleep => _todaySleep;

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

  // ─── Public methods ───────────────────────────────────────────────────────

  /// Checks HC availability and existing permissions. Fetches data if both
  /// are satisfied. Safe to call multiple times — ignores concurrent calls.
  Future<void> initialize() async {
    if (_inFlight) return;
    _inFlight = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isHealthConnectAvailable = await _service.isAvailable();
      if (!_isHealthConnectAvailable) return;

      // Check without prompting — only fetch if permissions already exist.
      final perms = await _service.hasPermissions();
      _hasPermissions = perms == true;
      if (_hasPermissions) await _fetchData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
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
      _hasPermissions = await _service.requestPermissions();
      if (_hasPermissions) await _fetchData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
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
      final now = DateTime.now();
      _activities = await _service.getActivities(
        now.subtract(const Duration(days: 30)),
        now,
      );
    } catch (_) {
      _activities = [];
    }
    try {
      _todaySleep = await _service.getSleepForNight(DateTime.now());
    } catch (_) {
      _todaySleep = null;
    }
    _lastSyncedAt = DateTime.now();
  }
}
