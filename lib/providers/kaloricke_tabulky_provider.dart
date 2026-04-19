import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_log.dart';
import '../services/kaloricke_tabulky_service.dart';
import '../services/kt_nutrition_database.dart';

class KalorickeTabulkyProvider extends ChangeNotifier {
  final KalorickeTabulkyService _service;
  final KtNutritionDatabase _db;

  KalorickeTabulkyProvider(this._service, this._db);

  // ─── State ─────────────────────────────────────────────────────────────────

  bool _isInitializing = false;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _historyFetchInProgress = false;

  String? _authError;
  String? _syncError;
  String? _loggedInEmail;
  DateTime? _lastSyncedAt;

  KtDayNutrition? _today;

  // ─── Public getters ────────────────────────────────────────────────────────

  bool get isLoggedIn => _service.isLoggedIn;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  String? get authError => _authError;
  String? get syncError => _syncError;
  String? get loggedInEmail => _loggedInEmail;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  bool get hasLoadedToday => _today != null;
  bool get hasTodayData => _today?.hasData ?? false;

  double get todayCalories => _today?.calories ?? 0;
  double get todayProtein => _today?.protein ?? 0;
  double get todayFat => _today?.fat ?? 0;
  double get todayCarbs => _today?.carbs ?? 0;
  double get todayFiber => _today?.fiber ?? 0;
  double get todaySugar => _today?.sugar ?? 0;
  double get todaySalt => _today?.salt ?? 0;
  double get todaySaturatedFat => _today?.saturatedFat ?? 0;

  // ─── History getters ───────────────────────────────────────────────────────

  KtDayNutrition? nutritionForDate(DateTime date) => _db.getDay(date);

  /// Average daily calories over [start, end], excluding today and days with
  /// nothing logged. Returns null when no valid days are available.
  double? avgCaloriesForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.calories, 'calories');

  double? avgProteinForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.protein, 'protein');

  double? avgFatForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.fat, 'fat');

  double? avgCarbsForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.carbs, 'carbs');

  double? avgFiberForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.fiber, 'fiber');

  double? avgSugarForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.sugar, 'sugar');

  double? avgSaltForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.salt, 'salt');

  double? avgSaturatedFatForRange(DateTime start, DateTime end) =>
      _avgField(start, end, (d) => d.saturatedFat, 'saturatedFat');

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitializing) {
      AppLog.ktProvider.debug('initialize() skipped — already running');
      return;
    }

    AppLog.ktProvider.info('initialize() started');
    _isInitializing = true;
    _authError = null;
    _syncError = null;

    // Show cached today immediately so the UI isn't empty during network fetch.
    _loadTodayFromStore(reason: 'initialize-start');
    notifyListeners();

    try {
      final restored = await _service.restoreSession();
      AppLog.ktProvider.info('restoreSession → $restored');
      if (!restored) return;

      _loggedInEmail = await _service.storedEmail();
      await _syncRecentDays();
      _triggerInitialHistoryIfNeeded();
    } on KtAuthException catch (e) {
      AppLog.ktProvider.warn('initialize() auth error: ${e.message}');
      _authError = e.message;
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      AppLog.ktProvider.warn('initialize() API error: ${e.message}');
      _syncError = e.message;
      _loadTodayFromStore(reason: 'initialize-api-error');
    } catch (e) {
      AppLog.ktProvider.warn('initialize() unexpected error: $e');
      _syncError = e.toString();
      _loadTodayFromStore(reason: 'initialize-unexpected-error');
    } finally {
      AppLog.ktProvider.info(
        'initialize() finished',
        payload: 'loggedIn=$isLoggedIn, todayLoaded=${_today != null}, '
            'syncError=$_syncError, lastSyncedAt=${_lastSyncedAt?.toIso8601String()}',
      );
      _isInitializing = false;
      notifyListeners();
    }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    if (_isLoading) {
      AppLog.ktProvider.debug('login() skipped — already running');
      return;
    }

    AppLog.ktProvider.info('login() started');
    _isLoading = true;
    _authError = null;
    _syncError = null;
    notifyListeners();

    try {
      await _service.login(email, password);
      _loggedInEmail = email;
      await _syncRecentDays();
      _triggerInitialHistoryIfNeeded();
    } on KtAuthException catch (e) {
      AppLog.ktProvider.warn('login() auth error: ${e.message}');
      _authError = e.message;
      _today = null;
    } on KtApiException catch (e) {
      AppLog.ktProvider.warn('login() API error: ${e.message}');
      _syncError = e.message;
      _today = null;
    } catch (e) {
      AppLog.ktProvider.warn('login() unexpected error: $e');
      _syncError = e.toString();
      _today = null;
    } finally {
      AppLog.ktProvider.info(
        'login() finished',
        payload: 'loggedIn=$isLoggedIn, todayLoaded=${_today != null}, syncError=$_syncError',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    AppLog.ktProvider.info('logout() started');
    await _service.logout();
    await _db.clear();
    _resetLocalData();
    AppLog.ktProvider.success('logout() finished');
    notifyListeners();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (!isLoggedIn) {
      AppLog.ktProvider.debug('refresh() skipped — not logged in');
      return;
    }
    if (_isRefreshing) {
      AppLog.ktProvider.debug('refresh() skipped — already running');
      return;
    }

    AppLog.ktProvider.info('refresh() started');
    _isRefreshing = true;
    _syncError = null;
    notifyListeners();

    try {
      await _syncRecentDays();
    } on KtAuthException catch (e) {
      AppLog.ktProvider.warn('refresh() auth error: ${e.message}');
      _authError = e.message;
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      AppLog.ktProvider.warn('refresh() API error: ${e.message}');
      _syncError = e.message;
    } catch (e) {
      AppLog.ktProvider.warn('refresh() unexpected error: $e');
      _syncError = e.toString();
    } finally {
      AppLog.ktProvider.info(
        'refresh() finished',
        payload: 'todayLoaded=${_today != null}, syncError=$_syncError, '
            'lastSyncedAt=${_lastSyncedAt?.toIso8601String()}',
      );
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ─── Sync internals ────────────────────────────────────────────────────────

  Future<void> refreshRange(DateTime start, DateTime end) async {
    if (!isLoggedIn) {
      AppLog.ktProvider.debug('refreshRange() skipped â€” not logged in');
      return;
    }
    if (_isRefreshing) {
      AppLog.ktProvider.debug('refreshRange() skipped â€” already running');
      return;
    }

    final rangeStart = _dateOnly(start);
    final rangeEnd = _dateOnly(end);
    final normalizedStart =
        rangeStart.isAfter(rangeEnd) ? rangeEnd : rangeStart;
    final normalizedEnd = rangeStart.isAfter(rangeEnd) ? rangeStart : rangeEnd;

    AppLog.ktProvider.info(
      'refreshRange() started',
      payload:
          '${_storeKey(normalizedStart)} -> ${_storeKey(normalizedEnd)}',
    );
    _isRefreshing = true;
    _syncError = null;
    notifyListeners();

    try {
      await _syncRange(
        normalizedStart,
        normalizedEnd,
        reason: 'manual-range-refresh',
      );
    } on KtAuthException catch (e) {
      AppLog.ktProvider.warn('refreshRange() auth error: ${e.message}');
      _authError = e.message;
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      AppLog.ktProvider.warn('refreshRange() API error: ${e.message}');
      _syncError = e.message;
    } catch (e) {
      AppLog.ktProvider.warn('refreshRange() unexpected error: $e');
      _syncError = e.toString();
    } finally {
      AppLog.ktProvider.info(
        'refreshRange() finished',
        payload: 'todayLoaded=${_today != null}, syncError=$_syncError, '
            'lastSyncedAt=${_lastSyncedAt?.toIso8601String()}',
      );
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Always fetches today. Fetches past 7 days only when not already synced
  /// within the same calendar day.
  Future<void> _syncRecentDays() async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final todayKey = _storeKey(today);

    AppLog.ktProvider.info('_syncRecentDays() started', payload: todayKey);
    final todayData = await _service.fetchDayNutritionMerged(today);
    await _db.saveDay(today, todayData);
    _today = todayData;
    _lastSyncedAt = now;
    _authError = null;
    _syncError = null;
    AppLog.ktProvider.success(
      '_syncRecentDays() today saved',
      payload: '$todayKey: ${_describeNutrition(todayData)}',
    );

    for (int i = 1; i <= 7; i++) {
      final day = today.subtract(Duration(days: i));
      final dayKey = _storeKey(day);
      final existing = _db.getDay(day);
      final syncedToday = existing != null &&
          _storeKey(_dateOnly(existing.lastSyncedAt)) == todayKey;
      if (!syncedToday) {
        try {
          final data = await _service.fetchDayNutritionMerged(day);
          await _db.saveDay(day, data);
          AppLog.ktProvider.debug(
            '_syncRecentDays() history day saved',
            payload: '$dayKey: ${_describeNutrition(data)}',
          );
        } catch (e) {
          AppLog.ktProvider
              .warn('_syncRecentDays() failed for history $dayKey: $e');
        }
      } else {
        AppLog.ktProvider
            .debug('_syncRecentDays() skipped $dayKey — already synced today');
      }
    }
    AppLog.ktProvider.success('_syncRecentDays() finished');
  }

  Future<void> _syncRange(
    DateTime start,
    DateTime end, {
    required String reason,
  }) async {
    final normalizedStart = _dateOnly(start);
    final normalizedEnd = _dateOnly(end);
    final today = _dateOnly(DateTime.now());
    final startKey = _storeKey(normalizedStart);
    final endKey = _storeKey(normalizedEnd);
    final now = DateTime.now();

    AppLog.ktProvider.info(
      '_syncRange() started',
      payload: '$reason: $startKey -> $endKey',
    );

    Object? firstSoftError;
    int successCount = 0;
    var day = normalizedStart;

    while (!day.isAfter(normalizedEnd)) {
      final dayKey = _storeKey(day);
      try {
        final data = await _service.fetchDayNutritionMerged(day);
        await _db.saveDay(day, data);
        if (_dateOnly(day) == today) {
          _today = data;
        }
        successCount++;
        AppLog.ktProvider.debug(
          '_syncRange() saved',
          payload: '$dayKey: ${_describeNutrition(data)}',
        );
      } on KtAuthException {
        rethrow;
      } catch (e) {
        firstSoftError ??= e;
        AppLog.ktProvider.warn('_syncRange() failed for $dayKey: $e');
      }
      day = day.add(const Duration(days: 1));
    }

    final cachedToday = _db.getDay(today);
    if (cachedToday != null) {
      _today = cachedToday;
    }

    if (successCount > 0) {
      _lastSyncedAt = now;
      _authError = null;
      _syncError = null;
      AppLog.ktProvider.success(
        '_syncRange() finished',
        payload: '$reason: saved $successCount day(s)',
      );
      return;
    }

    AppLog.ktProvider.warn(
      '_syncRange() finished without successful saves',
      payload: '$reason: $startKey -> $endKey',
    );

    if (firstSoftError is KtApiException) {
      throw firstSoftError;
    }
    if (firstSoftError != null) {
      throw KtApiException(firstSoftError.toString());
    }
  }

  /// Starts background fetch of days 8–30.
  /// Guarded so only one fetch runs at a time.
  void _triggerInitialHistoryIfNeeded() {
    if (_historyFetchInProgress) {
      AppLog.ktProvider
          .debug('_triggerInitialHistoryIfNeeded() skipped — already running');
      return;
    }
    if (!_storeNeedsHistory()) {
      AppLog.ktProvider
          .debug('_triggerInitialHistoryIfNeeded() skipped — history up to date');
      return;
    }
    AppLog.ktProvider
        .info('_triggerInitialHistoryIfNeeded() scheduling background history sync');
    unawaited(_fetchInitialHistory());
  }

  Future<void> _fetchInitialHistory() async {
    _historyFetchInProgress = true;
    AppLog.ktProvider.info('_fetchInitialHistory() started (days 8–30)');
    try {
      final today = _dateOnly(DateTime.now());
      for (int i = 8; i <= 30; i++) {
        if (!isLoggedIn) return;
        final day = today.subtract(Duration(days: i));
        final dayKey = _storeKey(day);
        if (!_db.hasDay(day)) {
          try {
            final data = await _service.fetchDayNutritionMerged(day);
            await _db.saveDay(day, data);
            AppLog.ktProvider.debug(
              '_fetchInitialHistory() saved',
              payload: '$dayKey: ${_describeNutrition(data)}',
            );
          } catch (e) {
            AppLog.ktProvider
                .warn('_fetchInitialHistory() failed for $dayKey: $e');
          }
        } else {
          AppLog.ktProvider
              .debug('_fetchInitialHistory() skipped $dayKey — already cached');
        }
      }
      notifyListeners();
    } finally {
      AppLog.ktProvider.success('_fetchInitialHistory() finished');
      _historyFetchInProgress = false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool _storeNeedsHistory() {
    // day8 is the oldest day _syncRecentDays won't cover (it syncs today + 7 past).
    final day8 = _dateOnly(DateTime.now()).subtract(const Duration(days: 8));
    final needsHistory = !_db.hasDay(day8);
    AppLog.ktProvider.debug(
      '_storeNeedsHistory() → $needsHistory',
      payload: 'day8=${_storeKey(day8)}',
    );
    return needsHistory;
  }

  void _loadTodayFromStore({required String reason}) {
    final today = _dateOnly(DateTime.now());
    final todayKey = _storeKey(today);
    final cached = _db.getDay(today);
    if (cached == null) {
      AppLog.ktProvider.debug(
          '_loadTodayFromStore($reason) → MISS for $todayKey');
      return;
    }

    _today = cached;
    _lastSyncedAt = cached.lastSyncedAt;
    AppLog.ktProvider.info(
      '_loadTodayFromStore($reason) → HIT $todayKey',
      payload: _describeNutrition(cached),
    );
  }

  void _resetLocalData({bool keepErrors = false}) {
    _loggedInEmail = null;
    _today = null;
    _lastSyncedAt = null;

    if (!keepErrors) {
      _authError = null;
      _syncError = null;
    }
  }

  double? _avgField(
    DateTime start,
    DateTime end,
    double Function(KtDayNutrition) field,
    String fieldName,
  ) {
    final startKey = _storeKey(start);
    final endKey = _storeKey(end);
    final todayKey = _storeKey(_dateOnly(DateTime.now()));
    final days = _db.getRange(start, end);

    // Exclude today (potentially incomplete) and days where nothing was logged.
    // Use foodCount > 0 OR calories > 0 as the "has data" check — foodstuffCount
    // may be missing from some API responses even when food was logged.
    final includedDays = days.entries
        .where((e) =>
            e.key != todayKey &&
            (e.value.foodCount > 0 || e.value.calories > 0))
        .toList();

    final excludedDays = days.entries
        .where((e) =>
            e.key == todayKey ||
            (e.value.foodCount == 0 && e.value.calories == 0))
        .toList();

    if (excludedDays.isNotEmpty) {
      AppLog.ktAvg.debug(
        'avgField($fieldName) excluded ${excludedDays.length} day(s)',
        payload: excludedDays
            .map((e) => '${e.key}[today=${e.key == todayKey}, foods=${e.value.foodCount}, kcal=${e.value.calories}]')
            .join(', '),
      );
    }

    final values = includedDays.map((e) => field(e.value)).toList();

    if (values.isEmpty) {
      AppLog.ktAvg.debug(
        'avgField($fieldName) $startKey → $endKey → null',
        payload: 'cachedDays=${days.length}, includedDays=0, todayKey=$todayKey',
      );
      return null;
    }

    final average = values.reduce((a, b) => a + b) / values.length;
    AppLog.ktAvg.info(
      'avgField($fieldName) $startKey → $endKey → avg=$average',
      payload: '${values.length} day(s): '
          '${includedDays.map((e) => '${e.key}[v=${field(e.value)}]').join(', ')}',
    );
    return average;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String _storeKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _describeNutrition(KtDayNutrition nutrition) {
    return 'kcal=${nutrition.calories}, '
        'P=${nutrition.protein}, '
        'F=${nutrition.fat}, '
        'C=${nutrition.carbs}, '
        'fiber=${nutrition.fiber}, '
        'foods=${nutrition.foodCount}, '
        'synced=${nutrition.lastSyncedAt.toIso8601String()}';
  }
}
