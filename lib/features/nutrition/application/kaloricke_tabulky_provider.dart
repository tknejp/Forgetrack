import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_log.dart';
import '../data/kaloricke_tabulky_service.dart';
import '../data/local/kt_nutrition_database.dart';
import 'kaloricke_tabulky_provider/kt_nutrition_queries.dart';
import 'kaloricke_tabulky_provider/kt_sync_coordinator.dart';
import '../../devtools/application/devtools_sync_logger.dart';
import '../../devtools/domain/devtools_sync_event.dart';

class KtNutritionRangeSummary {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double salt;
  final double saturatedFat;
  final int validDays;
  final int excludedDays;

  const KtNutritionRangeSummary({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.salt,
    required this.saturatedFat,
    required this.validDays,
    required this.excludedDays,
  });

  bool get hasData => validDays > 0;
}

class KalorickeTabulkyProvider extends ChangeNotifier {
  static const Duration _appOpenRefreshMinInterval = Duration(minutes: 5);

  final KalorickeTabulkyService _service;
  final KtNutritionDatabase _db;
  late final KtSyncCoordinator _sync;

  KalorickeTabulkyProvider(this._service, this._db) {
    _sync = KtSyncCoordinator(_service, _db);
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  bool _isInitializing = false;
  bool _isLoading = false;
  bool _isRefreshing = false;

  String? _authError;
  String? _syncError;
  String? _loggedInEmail;
  DateTime? _lastSyncedAt;
  DateTime? _lastAppOpenRefreshAttemptAt;

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

  /// True when the local DB has at least one cached day. Surfaces the
  /// "use saved data" affordance on the home prompt card when the user
  /// is logged out but has previously synced.
  bool get hasCachedNutrition => _db.debugCacheCount > 0;

  // ─── Debug/diagnostic getters (read-only, no side effects) ─────────────────

  int get debugNutritionCacheCount => _db.debugCacheCount;
  String? get debugNutritionFirstDateKey => _db.debugCacheFirstDateKey;
  String? get debugNutritionLastDateKey => _db.debugCacheLastDateKey;

  double get todayCalories => _today?.calories ?? 0;
  double get todayProtein => _today?.protein ?? 0;
  double get todayFat => _today?.fat ?? 0;
  double get todayCarbs => _today?.carbs ?? 0;
  double get todayFiber => _today?.fiber ?? 0;
  double get todaySugar => _today?.sugar ?? 0;
  double get todaySalt => _today?.salt ?? 0;
  double get todaySaturatedFat => _today?.saturatedFat ?? 0;
  double get todayDrinkRegime => _today?.drinkRegime ?? 0;
  double get todayBasal => _today?.basal ?? 0;
  List<KtMeal> get todayMeals => _today?.meals ?? const [];

  List<KtMeal> mealsForDate(DateTime date) =>
      _db.getDay(date)?.meals ?? const [];

  double basalForDate(DateTime date) => _db.getDay(date)?.basal ?? 0;

  double drinkRegimeForDate(DateTime date) =>
      _db.getDay(date)?.drinkRegime ?? 0;

  // ─── History getters ───────────────────────────────────────────────────────

  KtDayNutrition? nutritionForDate(DateTime date) => _db.getDay(date);

  Map<String, KtDayNutrition> nutritionRange(DateTime start, DateTime end) =>
      _db.getRange(start, end);

  /// Average daily nutrition over [start, end], excluding today and days with
  /// nothing logged.
  ///
  /// This is optimized for UI cards: it calls `_db.getRange()` only once and
  /// computes all macro averages from the same cached range.
  KtNutritionRangeSummary? nutritionSummaryForRange(
    DateTime start,
    DateTime end,
  ) {
    final normalizedStart = KtNutritionQueries.dateOnly(start);
    final normalizedEnd = KtNutritionQueries.dateOnly(end);

    final days = _db.getRange(normalizedStart, normalizedEnd);
    if (days.isEmpty) return null;

    final todayKey = KtNutritionQueries.storeKey(
      KtNutritionQueries.dateOnly(DateTime.now()),
    );

    final valid = <KtDayNutrition>[];
    var excludedDays = 0;

    for (final entry in days.entries) {
      final isToday = entry.key == todayKey;
      final day = entry.value;

      if (isToday || !day.hasData) {
        excludedDays++;
        continue;
      }

      valid.add(day);
    }

    if (valid.isEmpty) return null;

    double avg(double Function(KtDayNutrition day) pick) {
      final total = valid.fold<double>(0, (sum, day) => sum + pick(day));
      return total / valid.length;
    }

    return KtNutritionRangeSummary(
      calories: avg((d) => d.calories),
      protein: avg((d) => d.protein),
      fat: avg((d) => d.fat),
      carbs: avg((d) => d.carbs),
      fiber: avg((d) => d.fiber),
      sugar: avg((d) => d.sugar),
      salt: avg((d) => d.salt),
      saturatedFat: avg((d) => d.saturatedFat),
      validDays: valid.length,
      excludedDays: excludedDays,
    );
  }

  /// Average daily calories over [start, end], excluding today and days with
  /// nothing logged. Returns null when no valid days are available.
  ///
  /// Kept for compatibility. Prefer [nutritionSummaryForRange] in UI when
  /// multiple fields are needed.
  double? avgCaloriesForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.calories,
        'calories',
      );

  double? avgProteinForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.protein,
        'protein',
      );

  double? avgFatForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.fat,
        'fat',
      );

  double? avgCarbsForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.carbs,
        'carbs',
      );

  double? avgFiberForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.fiber,
        'fiber',
      );

  double? avgSugarForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.sugar,
        'sugar',
      );

  double? avgSaltForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.salt,
        'salt',
      );

  double? avgSaturatedFatForRange(DateTime start, DateTime end) =>
      KtNutritionQueries.avgField(
        _db,
        start,
        end,
        (d) => d.saturatedFat,
        'saturatedFat',
      );

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
      await _doSyncRecentDays();
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
            'syncError=$_syncError, '
            'lastSyncedAt=${_lastSyncedAt?.toIso8601String()}',
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
      await _doSyncRecentDays();
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
        payload:
            'loggedIn=$isLoggedIn, todayLoaded=${_today != null}, syncError=$_syncError',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    AppLog.ktProvider.info('logout() started');
    await _service.logout();
    // Keep the local DB intact so the user can still view previously
    // synced nutrition via the "Show saved data" affordance on the home
    // prompt card. A full wipe stays available via factory reset.
    _resetLocalData();
    AppLog.ktProvider.success('logout() finished');
    notifyListeners();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> refreshOnAppOpen({bool force = false}) async {
    final now = DateTime.now();
    final lastAttempt = _lastAppOpenRefreshAttemptAt;

    if (!force &&
        lastAttempt != null &&
        now.difference(lastAttempt) < _appOpenRefreshMinInterval) {
      AppLog.ktProvider.debug(
        'refreshOnAppOpen() skipped — throttled',
        payload: 'lastAttempt=${lastAttempt.toIso8601String()}',
      );
      return;
    }

    _lastAppOpenRefreshAttemptAt = now;

    if (_isInitializing) {
      AppLog.ktProvider.debug(
        'refreshOnAppOpen() skipped — initialize already running',
      );
      return;
    }

    if (!isLoggedIn) {
      AppLog.ktProvider.info(
        'refreshOnAppOpen() restoring session before refresh',
      );
      await initialize();
      return;
    }

    await refresh(source: 'app_open');
  }

  Future<void> refresh({String source = 'manual'}) async {
    if (!isLoggedIn) {
      AppLog.ktProvider.debug('refresh() skipped — not logged in');
      return;
    }
    if (_isRefreshing) {
      AppLog.ktProvider.debug('refresh() skipped — already running');
      return;
    }

    AppLog.ktProvider.info('refresh() started');
    final syncStart = DateTime.now();
    _isRefreshing = true;
    _syncError = null;
    notifyListeners();

    String? syncError;
    try {
      await _doSyncRecentDays();
    } on KtAuthException catch (e) {
      AppLog.ktProvider.warn('refresh() auth error: ${e.message}');
      _authError = e.message;
      syncError = 'auth: ${e.message}';
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      AppLog.ktProvider.warn('refresh() API error: ${e.message}');
      _syncError = e.message;
      syncError = 'api: ${e.message}';
    } catch (e) {
      AppLog.ktProvider.warn('refresh() unexpected error: $e');
      _syncError = e.toString();
      syncError = e.toString();
    } finally {
      AppLog.ktProvider.info(
        'refresh() finished',
        payload: 'todayLoaded=${_today != null}, syncError=$_syncError, '
            'lastSyncedAt=${_lastSyncedAt?.toIso8601String()}',
      );
      _isRefreshing = false;
      notifyListeners();
    }

    unawaited(
      DevToolsSyncLogger.instance.record(
        DevToolsSyncEvent(
          timestamp: syncStart,
          source: source,
          feature: 'nutrition',
          result: syncError != null ? 'failure' : 'success',
          durationMs: DateTime.now().difference(syncStart).inMilliseconds,
          errorMessage: syncError,
        ),
      ),
    );
  }

  Future<void> refreshRange(DateTime start, DateTime end) async {
    if (!isLoggedIn) {
      AppLog.ktProvider.debug('refreshRange() skipped — not logged in');
      return;
    }
    if (_isRefreshing) {
      AppLog.ktProvider.debug('refreshRange() skipped — already running');
      return;
    }

    final rangeStart = KtNutritionQueries.dateOnly(start);
    final rangeEnd = KtNutritionQueries.dateOnly(end);
    final normalizedStart =
        rangeStart.isAfter(rangeEnd) ? rangeEnd : rangeStart;
    final normalizedEnd = rangeStart.isAfter(rangeEnd) ? rangeStart : rangeEnd;

    AppLog.ktProvider.info(
      'refreshRange() started',
      payload:
          '${KtNutritionQueries.storeKey(normalizedStart)} -> ${KtNutritionQueries.storeKey(normalizedEnd)}',
    );

    final syncStart = DateTime.now();
    _isRefreshing = true;
    _syncError = null;
    notifyListeners();

    String? syncError;
    try {
      await _doSyncRange(
        normalizedStart,
        normalizedEnd,
        reason: 'manual-range-refresh',
      );
    } on KtAuthException catch (e) {
      AppLog.ktProvider.warn('refreshRange() auth error: ${e.message}');
      _authError = e.message;
      syncError = 'auth: ${e.message}';
      await _service.logout();
      _resetLocalData(keepErrors: true);
    } on KtApiException catch (e) {
      AppLog.ktProvider.warn('refreshRange() API error: ${e.message}');
      _syncError = e.message;
      syncError = 'api: ${e.message}';
    } catch (e) {
      AppLog.ktProvider.warn('refreshRange() unexpected error: $e');
      _syncError = e.toString();
      syncError = e.toString();
    } finally {
      AppLog.ktProvider.info(
        'refreshRange() finished',
        payload: 'todayLoaded=${_today != null}, syncError=$_syncError, '
            'lastSyncedAt=${_lastSyncedAt?.toIso8601String()}',
      );
      _isRefreshing = false;
      notifyListeners();
    }

    unawaited(
      DevToolsSyncLogger.instance.record(
        DevToolsSyncEvent(
          timestamp: syncStart,
          source: 'manual',
          feature: 'nutrition',
          result: syncError != null ? 'failure' : 'success',
          durationMs: DateTime.now().difference(syncStart).inMilliseconds,
          errorMessage: syncError,
          extra: {
            'rangeStart': KtNutritionQueries.storeKey(normalizedStart),
            'rangeEnd': KtNutritionQueries.storeKey(normalizedEnd),
          },
        ),
      ),
    );
  }

  // ─── Sync delegation ───────────────────────────────────────────────────────

  Future<void> _doSyncRecentDays() async {
    final outcome = await _sync.syncRecentDays();
    _today = outcome.today;
    _lastSyncedAt = outcome.lastSyncedAt;
    _authError = null;
    _syncError = null;
  }

  Future<void> _doSyncRange(
    DateTime start,
    DateTime end, {
    required String reason,
  }) async {
    final outcome = await _sync.syncRange(start, end, reason: reason);
    if (outcome != null) {
      _today = outcome.today;
      _lastSyncedAt = outcome.lastSyncedAt;
      _authError = null;
      _syncError = null;
    }
  }

  void _triggerInitialHistoryIfNeeded() {
    _sync.triggerInitialHistoryIfNeeded(
      isLoggedIn: () => isLoggedIn,
      onLoaded: notifyListeners,
    );
  }

  // ─── Local helpers ─────────────────────────────────────────────────────────

  /// Načte dnešní data z in-memory cache DB bez síťového volání.
  /// Určeno pro background isolat, kde je DB již naplněna přes KtSyncCoordinator.
  void loadFromCache() => _loadTodayFromStore(reason: 'background-cache');

  void _loadTodayFromStore({required String reason}) {
    final today = KtNutritionQueries.dateOnly(DateTime.now());
    final todayKey = KtNutritionQueries.storeKey(today);
    final cached = _db.getDay(today);
    if (cached == null) {
      AppLog.ktProvider
          .debug('_loadTodayFromStore($reason) → MISS for $todayKey');
      return;
    }

    _today = cached;
    _lastSyncedAt = cached.lastSyncedAt;
    AppLog.ktProvider.info(
      '_loadTodayFromStore($reason) → HIT $todayKey',
      payload: KtNutritionQueries.describeNutrition(cached),
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
}
