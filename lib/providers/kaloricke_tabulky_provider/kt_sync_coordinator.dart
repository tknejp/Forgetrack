import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/app_log.dart';
import '../../services/kaloricke_tabulky_service.dart';
import '../../services/db/kt_nutrition_database.dart';
import 'kt_nutrition_queries.dart';

/// The result of a successful sync operation.
typedef KtSyncOutcome = ({KtDayNutrition? today, DateTime lastSyncedAt});

/// Owns the network + DB sync flows for [KalorickeTabulkyProvider].
///
/// Methods return [KtSyncOutcome] on success and throw on failure, letting
/// the provider apply the outcome to its own state and call notifyListeners.
/// Auth errors ([KtAuthException]) always propagate unchanged.
class KtSyncCoordinator {
  KtSyncCoordinator(this._service, this._db);

  final KalorickeTabulkyService _service;
  final KtNutritionDatabase _db;

  bool _historyFetchInProgress = false;

  // ─── Recent-days sync ─────────────────────────────────────────────────────

  /// Fetches today from the API, then back-fills the past 7 days if any are
  /// not yet synced within the current calendar day.
  Future<KtSyncOutcome> syncRecentDays() async {
    final now = DateTime.now();
    final today = KtNutritionQueries.dateOnly(now);
    final todayKey = KtNutritionQueries.storeKey(today);

    AppLog.ktProvider.info('_syncRecentDays() started', payload: todayKey);

    final todayData = await _service.fetchDayNutritionMerged(today);
    await _db.saveDay(today, todayData);

    AppLog.ktProvider.success(
      '_syncRecentDays() today saved',
      payload: '$todayKey: ${KtNutritionQueries.describeNutrition(todayData)}',
    );

    for (int i = 1; i <= 7; i++) {
      final day = today.subtract(Duration(days: i));
      final dayKey = KtNutritionQueries.storeKey(day);
      final existing = _db.getDay(day);
      final syncedToday = existing != null &&
          KtNutritionQueries.storeKey(
                KtNutritionQueries.dateOnly(existing.lastSyncedAt),
              ) ==
              todayKey;

      if (!syncedToday) {
        try {
          final data = await _service.fetchDayNutritionMerged(day);
          await _db.saveDay(day, data);
          AppLog.ktProvider.debug(
            '_syncRecentDays() history day saved',
            payload: '$dayKey: ${KtNutritionQueries.describeNutrition(data)}',
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
    return (today: todayData, lastSyncedAt: now);
  }

  // ─── Range sync ───────────────────────────────────────────────────────────

  /// Syncs every day in [start, end] (inclusive). Returns [KtSyncOutcome] if
  /// at least one day succeeded, null if the range was empty / all soft errors
  /// cancelled each other out, or throws on total failure or auth error.
  Future<KtSyncOutcome?> syncRange(
    DateTime start,
    DateTime end, {
    required String reason,
  }) async {
    final normalizedStart = KtNutritionQueries.dateOnly(start);
    final normalizedEnd = KtNutritionQueries.dateOnly(end);
    final today = KtNutritionQueries.dateOnly(DateTime.now());
    final startKey = KtNutritionQueries.storeKey(normalizedStart);
    final endKey = KtNutritionQueries.storeKey(normalizedEnd);
    final now = DateTime.now();

    AppLog.ktProvider.info(
      '_syncRange() started',
      payload: '$reason: $startKey -> $endKey',
    );

    Object? firstSoftError;
    int successCount = 0;
    KtDayNutrition? todayResult;
    var day = normalizedStart;

    while (!day.isAfter(normalizedEnd)) {
      final dayKey = KtNutritionQueries.storeKey(day);
      try {
        final data = await _service.fetchDayNutritionMerged(day);
        await _db.saveDay(day, data);
        if (KtNutritionQueries.dateOnly(day) == today) {
          todayResult = data;
        }
        successCount++;
        AppLog.ktProvider.debug(
          '_syncRange() saved',
          payload: '$dayKey: ${KtNutritionQueries.describeNutrition(data)}',
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
    final finalToday = todayResult ?? cachedToday;

    if (successCount > 0) {
      AppLog.ktProvider.success(
        '_syncRange() finished',
        payload: '$reason: saved $successCount day(s)',
      );
      return (today: finalToday, lastSyncedAt: now);
    }

    AppLog.ktProvider.warn(
      '_syncRange() finished without successful saves',
      payload: '$reason: $startKey -> $endKey',
    );

    if (firstSoftError is KtApiException) throw firstSoftError;
    if (firstSoftError != null) throw KtApiException(firstSoftError.toString());

    // Empty range or zero days with no errors — no-op.
    return null;
  }

  // ─── Background history fetch ─────────────────────────────────────────────

  /// Starts background fetch of days 8–30 if not already running and the
  /// store does not yet have that history.
  ///
  /// [onLoaded] is called (on the calling isolate) when the fetch completes so
  /// the provider can call notifyListeners without the coordinator depending on
  /// ChangeNotifier directly.
  void triggerInitialHistoryIfNeeded({
    required bool Function() isLoggedIn,
    required VoidCallback onLoaded,
  }) {
    if (_historyFetchInProgress) {
      AppLog.ktProvider
          .debug('_triggerInitialHistoryIfNeeded() skipped — already running');
      return;
    }
    if (!_storeNeedsHistory()) {
      AppLog.ktProvider.debug(
          '_triggerInitialHistoryIfNeeded() skipped — history up to date');
      return;
    }
    AppLog.ktProvider.info(
        '_triggerInitialHistoryIfNeeded() scheduling background history sync');
    unawaited(_fetchInitialHistory(isLoggedIn: isLoggedIn, onLoaded: onLoaded));
  }

  Future<void> _fetchInitialHistory({
    required bool Function() isLoggedIn,
    required VoidCallback onLoaded,
  }) async {
    _historyFetchInProgress = true;
    AppLog.ktProvider.info('_fetchInitialHistory() started (days 8–30)');
    try {
      final today = KtNutritionQueries.dateOnly(DateTime.now());
      for (int i = 8; i <= 30; i++) {
        if (!isLoggedIn()) return;
        final day = today.subtract(Duration(days: i));
        final dayKey = KtNutritionQueries.storeKey(day);
        if (!_db.hasDay(day)) {
          try {
            final data = await _service.fetchDayNutritionMerged(day);
            await _db.saveDay(day, data);
            AppLog.ktProvider.debug(
              '_fetchInitialHistory() saved',
              payload:
                  '$dayKey: ${KtNutritionQueries.describeNutrition(data)}',
            );
          } catch (e) {
            AppLog.ktProvider
                .warn('_fetchInitialHistory() failed for $dayKey: $e');
          }
        } else {
          AppLog.ktProvider.debug(
              '_fetchInitialHistory() skipped $dayKey — already cached');
        }
      }
      onLoaded();
    } finally {
      AppLog.ktProvider.success('_fetchInitialHistory() finished');
      _historyFetchInProgress = false;
    }
  }

  // ─── Store state check ────────────────────────────────────────────────────

  bool _storeNeedsHistory() {
    // day8 is the oldest day syncRecentDays won't cover (it syncs today + 7 past).
    final day8 =
        KtNutritionQueries.dateOnly(DateTime.now()).subtract(const Duration(days: 8));
    final needsHistory = !_db.hasDay(day8);
    AppLog.ktProvider.debug(
      '_storeNeedsHistory() → $needsHistory',
      payload: 'day8=${KtNutritionQueries.storeKey(day8)}',
    );
    return needsHistory;
  }
}
