import 'package:flutter/foundation.dart';

import '../services/kaloricke_tabulky_service.dart';

class KalorickeTabulkyProvider extends ChangeNotifier {
  final KalorickeTabulkyService _service;

  KalorickeTabulkyProvider(this._service);

  // ─── State ─────────────────────────────────────────────────────────────────

  bool _isInitializing = false;
  bool _isLoading = false;
  bool _isRefreshing = false;

  String? _authError;
  String? _syncError;
  String? _loggedInEmail;
  DateTime? _lastSyncedAt;

  bool _hasLoadedToday = false;
  KtDayNutrition _today = KtDayNutrition.empty;

  // ─── Public getters ────────────────────────────────────────────────────────

  bool get isLoggedIn => _service.isLoggedIn;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  String? get authError => _authError;
  String? get syncError => _syncError;
  String? get loggedInEmail => _loggedInEmail;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  bool get hasLoadedToday => _hasLoadedToday;
  bool get hasTodayData => _today.hasData;

  double get todayCalories => _today.calories;
  double get todayProtein => _today.protein;
  double get todayFat => _today.fat;
  double get todayCarbs => _today.carbs;
  double get todayFiber => _today.fiber;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitializing) return;

    _isInitializing = true;
    _authError = null;
    _syncError = null;
    notifyListeners();

    try {
      final restored = await _service.restoreSession();
      if (!restored) return;

      _loggedInEmail = await _service.storedEmail();
      await _fetchTodayData();
    } on KtAuthException catch (e) {
      _authError = e.message;
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      _syncError = e.message;
    } catch (e) {
      _syncError = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    if (_isLoading) return;

    _isLoading = true;
    _authError = null;
    _syncError = null;
    notifyListeners();

    try {
      await _service.login(email, password);
      _loggedInEmail = email;
      await _fetchTodayData();
    } on KtAuthException catch (e) {
      _authError = e.message;
      _resetNutritionOnly();
    } on KtApiException catch (e) {
      _syncError = e.message;
      _resetNutritionOnly();
    } catch (e) {
      _syncError = e.toString();
      _resetNutritionOnly();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _authError = null;
    _syncError = null;
    _resetLocalData();
    notifyListeners();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (!isLoggedIn || _isRefreshing) return;

    _isRefreshing = true;
    _syncError = null;
    notifyListeners();

    try {
      await _fetchTodayData();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  Future<void> _fetchTodayData() async {
    try {
      final nutrition = await _service.fetchTodayNutrition();

      _today = nutrition;
      _hasLoadedToday = true;
      _lastSyncedAt = DateTime.now();
      _authError = null;
      _syncError = null;
    } on KtAuthException catch (e) {
      _authError = e.message;
      _syncError = null;
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      _syncError = e.message;
      _authError = null;
      _hasLoadedToday = false;
    } catch (e) {
      _syncError = e.toString();
      _authError = null;
      _hasLoadedToday = false;
    }
  }

  void _resetNutritionOnly() {
    _today = KtDayNutrition.empty;
    _hasLoadedToday = false;
    _lastSyncedAt = null;
  }

  void _resetLocalData({bool keepErrors = false}) {
    _loggedInEmail = null;
    _today = KtDayNutrition.empty;
    _hasLoadedToday = false;
    _lastSyncedAt = null;

    if (!keepErrors) {
      _authError = null;
      _syncError = null;
    }
  }
}