import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/activity_record.dart';
import '../services/health_connect_service.dart';

class FitnessProvider extends ChangeNotifier {
  final HealthConnectService _service;

  FitnessProvider(this._service);

  List<StepsRecord> _stepsHistory = [];
  List<ActivityRecord> _activities = [];
  double? _avgHeartRate;
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _error;

  List<StepsRecord> get stepsHistory => _stepsHistory;
  List<ActivityRecord> get activities => _activities;
  double? get avgHeartRate => _avgHeartRate;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get error => _error;

  int get todaySteps =>
      _stepsHistory.isNotEmpty ? _stepsHistory.last.steps : 0;

  /// Požádá o oprávnění a načte data.
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final available = await _service.isAvailable();
      if (!available) {
        _error = 'Health Connect není k dispozici na tomto zařízení.';
        return;
      }

      _hasPermission = await _service.requestPermissions();
      if (_hasPermission) await _fetchData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!_hasPermission) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _fetchData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    _stepsHistory = await _service.getStepsHistory(AppConstants.defaultHistoryDays);
    _activities = await _service.getActivities(
      now.subtract(Duration(days: AppConstants.defaultHistoryDays)),
      now,
    );
    _avgHeartRate = await _service.getTodayAvgHeartRate();
  }
}
