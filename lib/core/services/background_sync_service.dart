import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../logging/app_log.dart';
import '../../features/health_connect/application/fitness_provider.dart';
import '../../features/health_connect/data/health_connect_service.dart';
import '../../features/health_connect/data/local/health_database.dart';
import '../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../features/nutrition/application/kaloricke_tabulky_provider/kt_sync_coordinator.dart';
import '../../features/nutrition/data/kaloricke_tabulky_service.dart';
import '../../features/nutrition/data/local/kt_nutrition_database.dart';
import '../../features/progression/application/progression_engine.dart';
import '../../features/progression/data/local/progression_database.dart';
import '../../features/progression/data/progression_repository_impl.dart';
import '../../features/progression/data/provider_progression_source.dart';
import '../../features/progression/presentation/progression_l10n.dart';
import '../../firebase_options.dart';
import '../../l10n/app_localizations.dart';
import '../../features/health_connect/application/goals_provider.dart';
import 'notification_service.dart';

const _taskTag = 'forgetrack_sync';
const _taskName = 'forgetrack.background_sync';
const _prefLastReminderKey = 'last_goal_reminder_date';

// Android WorkManager minimum je 15 minut.
// Reálně to Android může spustit později podle baterie, Doze režimu a systému.
const _syncInterval = Duration(minutes: 15);

const _maxQuestNotificationsPerRun = 3;
const _maxAchievementNotificationsPerRun = 3;

/// Entry point volaný WorkManagerem v background isolatu.
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    HealthDatabase? healthDb;
    KtNutritionDatabase? ktDb;
    ProgressionDatabase? progressionDb;

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

      // ── Databáze ──────────────────────────────────────────────────────────
      healthDb = HealthDatabase();
      await healthDb.open();

      ktDb = KtNutritionDatabase();
      await ktDb.open();

      progressionDb = ProgressionDatabase();
      await progressionDb.open();

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

      // ── Progression: stav před synchem ────────────────────────────────────
      final engine = ProgressionEngine(
        repository: ProgressionRepositoryImpl(progressionDb),
      );

      final stateBefore = await engine.load();

      final prevGrantKeys = stateBefore.questRewardGrants
          .map((g) => g.rewardKey)
          .toSet();

      final prevAchievementIds = stateBefore.achievements
          .where((a) => a.unlocked)
          .map((a) => a.id)
          .toSet();

      // ── Progression sync ──────────────────────────────────────────────────
      final source = ProviderProgressionSource(
        goalsProvider: goalsProvider,
        fitnessProvider: fitnessProvider,
        nutritionProvider: ktProvider,
      );

      final stateAfter = await engine.sync(source);

      // ── Lokalizace notifikací ─────────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('selected_language_code') ?? 'cs';

      final l10n = await AppLocalizations.delegate.load(
        Locale(langCode),
      );

      final progressionL10n = ProgressionL10n(l10n);

      // ── Notifikace: nové questy ───────────────────────────────────────────
      final newGrants = stateAfter.questRewardGrants
          .where((g) => !prevGrantKeys.contains(g.rewardKey))
          .take(_maxQuestNotificationsPerRun)
          .toList();

      for (var i = 0; i < newGrants.length; i++) {
        final grant = newGrants[i];

        final quest = stateAfter.quests
            .where((q) => q.id == grant.questId)
            .firstOrNull;

        final title = quest != null
            ? progressionL10n.questTitle(quest)
            : 'Quest';

        await NotificationService.instance.showQuestCompleted(
          title,
          grant.xpGranted,
          index: i,
        );
      }

      // ── Notifikace: nové achievementy ─────────────────────────────────────
      final newAchievements = stateAfter.achievements
          .where((a) => a.unlocked && !prevAchievementIds.contains(a.id))
          .take(_maxAchievementNotificationsPerRun)
          .toList();

      for (var i = 0; i < newAchievements.length; i++) {
        final achievement = newAchievements[i];

        await NotificationService.instance.showAchievementUnlocked(
          progressionL10n.achievementTitle(achievement),
          progressionL10n.achievementDescription(achievement),
          index: i,
        );
      }

      // ── Denní připomínka cílů ─────────────────────────────────────────────
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

      return true;
    } catch (e, st) {
      AppLog.app.error(
        'BackgroundSyncService: task failed task=$taskName',
        err: e,
        stackTrace: st,
      );

      // Záměrně true:
      // - WorkManager nebude točit retry loop.
      // - Pro testovací/soukromou appku je to bezpečnější.
      //
      // Do budoucna můžeš vracet false jen pro dočasné síťové chyby.
      return true;
    } finally {
        await _closeDatabases(
          healthDb: healthDb,
          ktDb: ktDb,
          progressionDb: progressionDb,
        );
      }
    }
  );
}

Future<void> _maybeShowGoalReminder(SharedPreferences prefs) async {
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
  required ProgressionDatabase? progressionDb,
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

  try {
    await progressionDb?.close();
  } catch (e, st) {
    AppLog.app.error(
      'BackgroundSyncService: failed to close ProgressionDatabase',
      err: e,
      stackTrace: st,
    );
  }
}

class BackgroundSyncService {
  BackgroundSyncService._();

  static Future<void> register() async {
    if (!Platform.isAndroid) {
      AppLog.app.debug(
        'BackgroundSyncService: skipped registration on non-Android platform',
      );
      return;
    }

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
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );

    AppLog.app.debug('BackgroundSyncService: registered periodic task');
  }
}