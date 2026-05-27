import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/logging/app_log.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/data/local/cosmetics_database.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/goals_provider.dart';
import '../../../health_connect/data/local/health_database.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../nutrition/data/local/kt_nutrition_database.dart';
import '../../../onboarding/application/onboarding_provider.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../social/application/social_provider.dart';
import '../devtools_provider.dart';
import 'devtools_user_data_purge_service.dart';
import 'factory_reset_models.dart';
import 'google_account_reset_helper.dart';
import 'google_sheets_export_reset_helper.dart';
import 'health_connect_reset_helper.dart';
import 'kaloricke_tabulky_reset_helper.dart';

/// Bag of every dependency the orchestrator needs at run-time. Constructed
/// by the UI from `context.read<...>()` calls so the service itself stays
/// stateless and unit-testable with mocks.
class FactoryResetDeps {
  const FactoryResetDeps({
    required this.healthDatabase,
    required this.ktNutritionDatabase,
    required this.cosmeticsDatabase,
    required this.authProvider,
    required this.progressionEngineProvider,
    required this.cosmeticsProvider,
    required this.fitnessProvider,
    required this.kalorickeTabulkyProvider,
    required this.goalsProvider,
    required this.socialProvider,
    required this.devToolsProvider,
    required this.onboardingProvider,
  });

  final HealthDatabase healthDatabase;
  final KtNutritionDatabase ktNutritionDatabase;
  final CosmeticsDatabase cosmeticsDatabase;

  final AuthProvider authProvider;
  final ProgressionEngineProvider progressionEngineProvider;
  final CosmeticsProvider cosmeticsProvider;
  final FitnessProvider fitnessProvider;
  final KalorickeTabulkyProvider kalorickeTabulkyProvider;
  final GoalsProvider goalsProvider;
  final SocialProvider socialProvider;
  final DevToolsProvider devToolsProvider;
  final OnboardingProvider onboardingProvider;
}

/// Orchestrates the DevTools "factory / new player" reset.
///
/// Sequential, imperative, fail-soft: each step is wrapped in its own
/// try/catch. A failed step is reported through the progress callback and
/// in the final [FactoryResetReport] but does NOT abort the rest of the
/// flow — a partial reset is preferable to leaving the device in an
/// inconsistent half-wiped state.
///
/// Step order is deliberate (see [FactoryResetStep]). Two ordering
/// constraints worth flagging:
///   * `captureUid` runs *before* any signOut path so Firestore purge has
///     a uid to scope deletes to.
///   * `firestorePurge` runs *before* `firebaseSignOut`; once signed out
///     the security rules would reject the deletes.
class FactoryResetService {
  FactoryResetService({
    DevToolsUserDataPurgeService? userDataPurgeService,
    GoogleAccountResetHelper? googleHelper,
    GoogleSheetsExportResetHelper? sheetsHelper,
    HealthConnectResetHelper? healthHelper,
    KalorickeTabulkyResetHelper Function(KalorickeTabulkyProvider)?
        ktHelperFactory,
    Workmanager? workmanager,
    FirebaseAuth? firebaseAuth,
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
  })  : _userDataPurgeService =
            userDataPurgeService ?? DevToolsUserDataPurgeService(),
        _googleHelper = googleHelper ?? GoogleAccountResetHelper(),
        _sheetsHelper = sheetsHelper ?? const GoogleSheetsExportResetHelper(),
        _healthHelper = healthHelper ?? HealthConnectResetHelper(),
        _ktHelperFactory = ktHelperFactory ??
            ((p) => KalorickeTabulkyResetHelper(provider: p)),
        _workmanager = workmanager ?? Workmanager(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sharedPreferencesFactory =
            sharedPreferencesFactory ?? SharedPreferences.getInstance;

  final DevToolsUserDataPurgeService _userDataPurgeService;
  final GoogleAccountResetHelper _googleHelper;
  final GoogleSheetsExportResetHelper _sheetsHelper;
  final HealthConnectResetHelper _healthHelper;
  final KalorickeTabulkyResetHelper Function(KalorickeTabulkyProvider)
      _ktHelperFactory;
  final Workmanager _workmanager;
  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  /// Background-sync uniqueName must match the value used at registration
  /// in `BackgroundSyncService.register()` for cancellation to take effect.
  static const _kBackgroundSyncUniqueName = 'forgetrack.background_sync';

  Future<FactoryResetReport> run({
    required FactoryResetOptions options,
    required FactoryResetDeps deps,
    required void Function(FactoryResetProgress) onProgress,
  }) async {
    final startedAt = DateTime.now();
    AppLog.reset.info(
      'factory-reset: starting',
      payload:
          'purgeFirestore=${options.purgeFirestoreData} openHCSettings=${options.openHealthConnectSettings}',
    );

    final results = <FactoryResetStepResult>[];
    String? capturedUid;

    Future<void> runStep(
      FactoryResetStep step,
      Future<({String? note, bool skipped})> Function() body,
    ) async {
      onProgress(FactoryResetProgress(
        step: step,
        status: FactoryResetStepStatus.running,
      ));
      final stepStart = DateTime.now();
      try {
        final outcome = await body();
        final elapsed = DateTime.now().difference(stepStart);
        final status = outcome.skipped
            ? FactoryResetStepStatus.skipped
            : FactoryResetStepStatus.succeeded;
        AppLog.reset.success(
          'factory-reset: ${step.name} ${status.name}',
          payload: 'elapsedMs=${elapsed.inMilliseconds} note=${outcome.note}',
        );
        final result = FactoryResetStepResult(
          step: step,
          status: status,
          elapsed: elapsed,
          note: outcome.note,
        );
        results.add(result);
        onProgress(FactoryResetProgress(
          step: step,
          status: status,
          note: outcome.note,
        ));
      } catch (e, st) {
        final elapsed = DateTime.now().difference(stepStart);
        AppLog.reset.error(
          'factory-reset: ${step.name} FAILED',
          payload: 'elapsedMs=${elapsed.inMilliseconds}',
          err: e,
          stackTrace: st,
        );
        final result = FactoryResetStepResult(
          step: step,
          status: FactoryResetStepStatus.failed,
          elapsed: elapsed,
          errorMessage: e.toString(),
        );
        results.add(result);
        onProgress(FactoryResetProgress(
          step: step,
          status: FactoryResetStepStatus.failed,
          errorMessage: e.toString(),
        ));
      }
    }

    // 1. Cancel background sync — must happen before clearing state, so a
    //    racing 15-min tick doesn't repopulate prefs after we wipe them.
    await runStep(FactoryResetStep.cancelBackgroundSync, () async {
      await _workmanager.cancelByUniqueName(_kBackgroundSyncUniqueName);
      await _workmanager.cancelAll();
      return (note: 'WorkManager tasks cancelled', skipped: false);
    });

    // 2. Capture the current uid for downstream Firestore purge. Read it
    //    here before any signOut path nulls it.
    await runStep(FactoryResetStep.captureUid, () async {
      capturedUid = _firebaseAuth.currentUser?.uid;
      return (
        note: capturedUid == null ? 'no signed-in user' : 'uid=$capturedUid',
        skipped: false,
      );
    });

    // 3. Optional Firestore purge. Skipped when the toggle is off OR when
    //    no uid was captured (anonymous / signed-out state).
    await runStep(FactoryResetStep.firestorePurge, () async {
      if (!options.purgeFirestoreData) {
        return (note: 'opt-in disabled', skipped: true);
      }
      final uid = capturedUid;
      if (uid == null) {
        return (note: 'no uid — nothing to purge', skipped: true);
      }
      final report = await _userDataPurgeService.purgeForUid(uid);
      return (note: report.note, skipped: false);
    });

    // 4. KT logout — clears HTTP session, cookies, secure-storage creds,
    //    and the Isar nutrition cache via the existing provider flow.
    await runStep(FactoryResetStep.kalorickeTabulkyLogout, () async {
      final note = await _ktHelperFactory(deps.kalorickeTabulkyProvider)
          .logoutAndClear();
      return (note: note, skipped: false);
    });

    // 5. Google Sheets / Bushido export — local pointer to the Drive file.
    await runStep(FactoryResetStep.googleSheetsExportReset, () async {
      final removed = await _sheetsHelper.clearLocalExportState();
      return (note: 'prefs keys removed=$removed', skipped: false);
    });

    // 6. Disconnect Google account — revokes OAuth scopes (drive.file etc.)
    //    so a post-reset sign-in goes through the consent screen.
    await runStep(FactoryResetStep.googleAccountDisconnect, () async {
      final note = await _googleHelper.disconnectGoogle();
      return (note: note, skipped: false);
    });

    // 7. FirebaseAuth signOut. After this, Firestore writes/reads scoped
    //    to the captured uid would be rejected by security rules.
    await runStep(FactoryResetStep.firebaseSignOut, () async {
      await _googleHelper.firebaseSignOut();
      return (note: 'signed out', skipped: false);
    });

    // 8. Local Isar databases — every collection used by Forgetrack.
    await runStep(FactoryResetStep.clearLocalDatabases, () async {
      // V2 progression: wipe the engine ledger. This also clears the
      // in-memory celebration queue (devToolsWipeLedger resets
      // `_pendingCelebrations`).
      await deps.progressionEngineProvider.devToolsWipeLedger();
      // Cosmetics: clear the progression-sourced unlocks first, then
      // drop any remaining rows (manual devtools grants, entitlements).
      await deps.cosmeticsProvider.devToolsResetProgressionUnlocks();
      await deps.cosmeticsDatabase.clearAll();
      // Health + nutrition caches are independent.
      await deps.healthDatabase.clearAll();
      await deps.ktNutritionDatabase.clear();
      return (
        note: 'progression+cosmetics+health+nutrition wiped',
        skipped: false,
      );
    });

    // 9. SharedPreferences — wholesale clear is the simplest correct
    //    reset. Anything required at first launch (locale, notification
    //    pref) will be re-initialised from defaults by their providers.
    await runStep(FactoryResetStep.clearSharedPreferences, () async {
      final prefs = await _sharedPreferencesFactory();
      final keysBefore = prefs.getKeys().length;
      await prefs.clear();
      return (note: 'cleared $keysBefore keys', skipped: false);
    });

    // 10. SecureStorage — KT helper already covers `kt_email`/`kt_pwd_hash`;
    //     this is a defensive `deleteAll` to catch anything else stored
    //     under FlutterSecureStorage's default options.
    await runStep(FactoryResetStep.clearSecureStorage, () async {
      await _secureStorage.deleteAll();
      return (note: 'all secure-storage keys deleted', skipped: false);
    });

    // 11. Health Connect permission revoke. Never deletes records.
    await runStep(FactoryResetStep.healthConnectRevoke, () async {
      await _healthHelper.revokePermissions();
      return (note: 'permissions revoked', skipped: false);
    });

    // 12. Reset in-memory provider state so the UI doesn't need a full
    //     app restart to reflect the wipe.
    await runStep(FactoryResetStep.resetProviders, () async {
      await _resetProviders(deps);
      return (note: 'providers re-initialised', skipped: false);
    });

    // 13. Open Android settings as the final manual-verify step.
    await runStep(FactoryResetStep.openHealthConnectSettings, () async {
      if (!options.openHealthConnectSettings) {
        return (note: 'opt-in disabled', skipped: true);
      }
      await _healthHelper.openHealthConnectSettings();
      return (note: 'app settings opened', skipped: false);
    });

    final finishedAt = DateTime.now();
    final report = FactoryResetReport(
      results: results,
      totalElapsed: finishedAt.difference(startedAt),
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
    AppLog.reset.info(
      'factory-reset: done',
      payload:
          'totalMs=${report.totalElapsed.inMilliseconds} ok=${report.successCount} '
          'skipped=${report.skippedCount} failed=${report.failureCount}',
    );
    return report;
  }

  Future<void> _resetProviders(FactoryResetDeps deps) async {
    // Goals: re-read from the now-empty prefs. init() falls back to
    // defaults for any missing key.
    await deps.goalsProvider.init();

    // Cosmetics & Social: bind(null) so they drop the previous user's
    // state. The next sign-in re-binds them via the proxy provider.
    deps.cosmeticsProvider.bindUser(null);

    // Fitness: re-evaluate Health Connect permission state — after the
    // revoke step `hasPermissions` should drop to false.
    await deps.fitnessProvider.initialize();

    // KT provider was already reset by `KalorickeTabulkyResetHelper`.
    // Progression was already reset via devToolsResetEverything.
    // DevToolsProvider re-init pulls fresh values from prefs.
    await deps.devToolsProvider.init();

    // Re-read onboarding flag — `prefs.clear()` wiped it, so the welcome
    // screen reappears in the running session via the routing watcher.
    await deps.onboardingProvider.refresh();

    // SocialProvider rebinds reactively via the ProxyProvider once
    // AuthProvider's `isSignedIn` flips; nothing imperative needed.

    // Final evaluation against the post-reset state: ledger is empty,
    // sources have re-initialised from defaults. This guarantees
    // condition-only achievements (welcome_to_journey) re-emit even if the
    // ProxyProvider rebuild chain didn't trigger an evaluation with the
    // settled audit signature.
    await deps.progressionEngineProvider.refresh();
  }
}
