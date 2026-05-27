import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../errors/app_error.dart';
import '../errors/firebase_error_classifier.dart';
import '../errors/kt_error_classifier.dart';
import '../logging/app_log.dart';
import '../../features/devtools/application/devtools_sync_logger.dart';
import '../../features/devtools/domain/devtools_sync_event.dart';
import '../../features/health_connect/application/fitness_provider.dart';
import '../../features/health_connect/data/health_connect_service.dart';
import '../../features/health_connect/data/local/health_database.dart';
import '../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../features/nutrition/application/kaloricke_tabulky_provider/kt_sync_coordinator.dart';
import '../../features/nutrition/data/kaloricke_tabulky_service.dart';
import '../../features/nutrition/data/local/kt_nutrition_database.dart';
import '../../firebase_options.dart';
import '../../features/health_connect/application/goals_provider.dart';
import '../../features/progression_engine/application/background_progression_notifier.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

const _taskTag = 'forgetrack_sync';
const _taskName = 'forgetrack.background_sync';
const _prefLastReminderKey = 'last_goal_reminder_date';

// Android WorkManager minimum je 15 minut.
// Reálně to Android může spustit později podle baterie, Doze režimu a systému.
const _syncInterval = Duration(minutes: 15);

// Phase 22 (legacy V1 progression cleanup, 2026-05-19): the V1
// engine.sync(source) + quest/achievement notification flow was
// removed when lib/features/progression/ was deleted. The V2 engine
// (lib/features/progression_engine/) is the canonical progression
// system on every UI surface since V2 plan Phase 6 — the V1
// background-sync path had been writing to a divergent ledger and
// surfacing stale notifications. Bringing V2 progression
// notifications back is a scoped future feature, tracked in
// docs/domain_model/archive/follow_ups.md §2.26.

/// Entry point volaný WorkManagerem v background isolatu.
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    HealthDatabase? healthDb;
    KtNutritionDatabase? ktDb;
    bool sendDebugNotifs = false;

    final bgSyncStart = DateTime.now();
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await NotificationService.instance.initialize(
        requestPermissions: false,
      );

      // ── Debug notification flags (SharedPreferences, read-only) ──────────
      {
        final dp = await SharedPreferences.getInstance();
        sendDebugNotifs = (dp.getBool('devtools_access_granted_last_known') ??
                false) &&
            (dp.getBool('devtools_debug_mode') ?? false) &&
            (dp.getBool('devtools_bg_debug_notifications_enabled') ?? false);
      }
      if (sendDebugNotifs) {
        await NotificationService.instance.showDebugNotification(
          title: '[DevTools] BG sync started',
          body: taskName,
        );
      }

      // ── Databáze ──────────────────────────────────────────────────────────
      healthDb = HealthDatabase();
      await healthDb.open();

      ktDb = KtNutritionDatabase();
      await ktDb.open();

      // ── Health Connect: background-safe refresh ───────────────────────────
      final fitnessProvider = FitnessProvider(
        HealthConnectService(),
        healthDb,
      );

      await fitnessProvider.initialize();

      // Pozor:
      // Pro Health Connect background read musí mít appka Android permission:
      // android.permission.health.READ_HEALTH_DATA_IN_BACKGROUND
      // a uživatel ji musí povolit.
      await fitnessProvider.refreshBackground();

      // Pokud initialize() znamená "načti z DB/cache", je to použitelné.
      // Lepší by ale bylo mít explicitní metodu reloadFromCache()/loadFromDatabase().
      await fitnessProvider.initialize();

      // ── KT: obnova session + sync dnešního dne ────────────────────────────
      final ktService = KalorickeTabulkyService();
      final ktProvider = KalorickeTabulkyProvider(ktService, ktDb);

      final sessionRestored = await ktService.restoreSession();

      if (sessionRestored) {
        final today = DateTime.now();
        final ktSync = KtSyncCoordinator(ktService, ktDb);

        await ktSync.syncRange(
          today,
          today,
          reason: 'background',
        );
      }

      // Důležité: musí se počkat, než provider načte data z cache/DB.
      ktProvider.loadFromCache();

      // ── Goals ─────────────────────────────────────────────────────────────
      final goalsProvider = GoalsProvider();
      await goalsProvider.init();

      // ── V2 progression: quest + achievement push notifications ───────────
      //
      // Trello #80. Runs the V2 engine against the current ledger from the
      // background isolate so newly-completed quests / unlocked achievements
      // surface as system notifications without requiring the user to open
      // the app. Idempotent: the engine's append path is keyed by eventKey,
      // so WorkManager retries against an unchanged state produce no
      // duplicates. See `BackgroundProgressionNotifier` for the full design
      // notes (counter scope, cosmetic-dispatch trade-off, spam cap).
      await const BackgroundProgressionNotifier().notifyForNewCompletions(
        fitness: fitnessProvider,
        nutrition: ktProvider,
        goals: goalsProvider,
      );

      // ── Denní připomínka cílů ─────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      //
      // Pozor:
      // Tohle není přesné plánování. WorkManager nemusí běžet mezi 18–20.
      // Pro spolehlivou denní připomínku je lepší scheduled local notification.
      //
      // Nechávám zde jako fallback, ale nespoléhal bych se na to jako na hlavní mechanismus.
      await _maybeShowGoalReminder(prefs);

      AppLog.app.debug(
        'BackgroundSyncService: task completed task=$taskName',
      );

      await DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
        timestamp: bgSyncStart,
        source: 'background',
        feature: 'all',
        result: 'success',
        durationMs: DateTime.now().difference(bgSyncStart).inMilliseconds,
      ));

      if (sendDebugNotifs) {
        final durationS = DateTime.now().difference(bgSyncStart).inSeconds;
        await NotificationService.instance.showDebugNotification(
          title: '[DevTools] BG sync done',
          body: '${durationS}s — $taskName',
        );
      }

      return true;
    } catch (e, st) {
      // Phase 18 of the domain refactor (`docs/domain_model/
      // migration_plan.md` §Phase 18) replaces the previous blanket
      // `return true` with typed `AppError` classification:
      //
      //   - Transient → return true so WorkManager schedules a retry.
      //   - Permanent → return false so WorkManager skips the retry
      //     window (we'd just burn another cycle on the same broken
      //     state). Logged at `error` level so the failure is
      //     visible in DevTools / crash reports instead of being
      //     silently swallowed.
      final error = _classifyBackgroundSyncError(e, st);

      if (error.isTransient) {
        AppLog.app.warn(
          'BackgroundSyncService: transient failure '
          'task=$taskName error=${error.label}',
          payload: e.toString(),
        );
      } else {
        AppLog.app.error(
          'BackgroundSyncService: permanent failure '
          'task=$taskName error=${error.label}',
          err: e,
          stackTrace: st,
        );
      }

      await DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
        timestamp: bgSyncStart,
        source: 'background',
        feature: 'all',
        result: 'failure',
        durationMs: DateTime.now().difference(bgSyncStart).inMilliseconds,
        errorMessage: '${error.label}: ${e.toString()}',
      ));

      if (sendDebugNotifs) {
        final errMsg = '${error.isTransient ? "transient" : "permanent"}: '
            '${error.label}';
        await NotificationService.instance.showDebugNotification(
          title: '[DevTools] BG sync failed',
          body:
              errMsg.length > 80 ? '${errMsg.substring(0, 80)}…' : errMsg,
        );
      }

      // Result-based decision: transient → WorkManager retries on its
      // own backoff schedule. Permanent → skip; nothing we can do this
      // window. Old behaviour was unconditional `return true` which hid
      // permanent failures behind silent retries.
      return error.isTransient;
    } finally {
      await _closeDatabases(
        healthDb: healthDb,
        ktDb: ktDb,
      );
    }
  });
}

/// Classifies an exception caught by [backgroundSyncCallback] into
/// the typed [AppError] hierarchy so the WorkManager retry decision
/// becomes pattern-matchable on `isTransient`.
///
/// Order of dispatch:
///   1. KT-specific exceptions ([KtAuthException], [KtApiException])
///      — classified by [classifyKtError].
///   2. Firebase / Firestore exceptions — classified by
///      [classifyFirebaseError].
///   3. Anything else → catch-all [UpstreamError] (`isTransient:
///      true` so WorkManager retries — unknown failures are assumed
///      worth one more attempt before we silently give up).
AppError _classifyBackgroundSyncError(Object error, StackTrace stackTrace) {
  if (error is KtAuthException || error is KtApiException) {
    return classifyKtError(error, stackTrace, endpoint: 'bg.sync');
  }
  if (error is FirebaseException) {
    return classifyFirebaseError(error, stackTrace, endpoint: 'bg.sync');
  }
  return UpstreamError(
    originalError: error,
    stackTrace: stackTrace,
    context: 'bg.sync',
  );
}

Future<void> _maybeShowGoalReminder(SharedPreferences prefs) async {
  if (!await NotificationPreferences.areEnabled()) {
    return;
  }

  final now = DateTime.now();

  if (now.hour < 18 || now.hour >= 20) {
    return;
  }

  final todayKey = _dateKey(now);

  if (prefs.getString(_prefLastReminderKey) == todayKey) {
    return;
  }

  await NotificationService.instance.showGoalReminder();
  await prefs.setString(_prefLastReminderKey, todayKey);
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}

Future<void> _closeDatabases({
  required HealthDatabase? healthDb,
  required KtNutritionDatabase? ktDb,
}) async {
  try {
    await healthDb?.close(clearMemoryCache: true);
  } catch (e, st) {
    AppLog.app.error(
      'BackgroundSyncService: failed to close HealthDatabase',
      err: e,
      stackTrace: st,
    );
  }

  try {
    await ktDb?.close(clearMemoryCache: true);
  } catch (e, st) {
    AppLog.app.error(
      'BackgroundSyncService: failed to close KtNutritionDatabase',
      err: e,
      stackTrace: st,
    );
  }
}

class BackgroundSyncService {
  BackgroundSyncService._();

  // ─── Debug/diagnostic constants (read-only) ──────────────────────────────
  static const String debugTaskId = _taskTag;
  static const String debugTaskName = _taskName;
  static const Duration debugSyncInterval = _syncInterval;

  static Future<void> register() async {
    if (!Platform.isAndroid) {
      AppLog.app.debug(
        'BackgroundSyncService: skipped registration on non-Android platform',
      );
      return;
    }

    try {
      await Workmanager().initialize(
        backgroundSyncCallback,
      );

      await Workmanager().registerPeriodicTask(
        _taskTag,
        _taskName,
        frequency: _syncInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

      AppLog.app.debug('BackgroundSyncService: registered periodic task');
    } catch (e, st) {
      AppLog.app.error(
        'BackgroundSyncService: registration failed',
        err: e,
        stackTrace: st,
      );
    }
  }

  /// Schedules a one-off run of the same background sync callback. Used by
  /// the DevTools "Trigger one-off background task" action — Android still
  /// enforces system-level delays (Doze, battery saver, network gate), but
  /// the task usually fires within a few seconds on an unblocked device
  /// and lets the tester verify the WorkManager path end-to-end without
  /// waiting for the 15-minute periodic window.
  static Future<void> triggerOneOffSync() async {
    if (!Platform.isAndroid) {
      AppLog.app.debug(
        'BackgroundSyncService: one-off trigger skipped on non-Android platform',
      );
      return;
    }
    try {
      // Initialize is idempotent — the periodic registerPeriodicTask
      // already ran at boot via [register]. We call it again to defend
      // against a path where the user lands in DevTools before the
      // initial boot sequence completed.
      await Workmanager().initialize(backgroundSyncCallback);

      await Workmanager().registerOneOffTask(
        '${_taskTag}_oneoff_${DateTime.now().millisecondsSinceEpoch}',
        _taskName,
        constraints: Constraints(networkType: NetworkType.connected),
        initialDelay: const Duration(seconds: 2),
      );
      AppLog.app.info('BackgroundSyncService: one-off task scheduled');
    } catch (e, st) {
      AppLog.app.error(
        'BackgroundSyncService: one-off trigger failed',
        err: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
