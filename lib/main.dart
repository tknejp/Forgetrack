import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'core/logging/app_log.dart';
import 'app/notification_preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/services/background_sync_service.dart';
import 'core/services/connectivity_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firestore_network_gate.dart';
import 'core/services/notification_service.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/celebration/application/celebration_controller.dart';
import 'features/cosmetics/application/cosmetics_provider.dart';
import 'features/cosmetics/application/cosmetics_service.dart';
import 'features/cosmetics/config/cosmetics_config.dart';
import 'features/cosmetics/data/cosmetic_entitlements_source.dart';
import 'features/cosmetics/data/firestore_cosmetic_entitlements_source.dart';
import 'features/cosmetics/data/isar_cosmetics_repository.dart';
import 'features/cosmetics/data/local/cosmetics_database.dart';
import 'features/progression_engine/application/progression_engine.dart';
import 'features/progression_engine/application/progression_engine_provider.dart';
import 'features/progression_engine/data/isar_progression_engine_repository.dart';
import 'features/progression_engine/data/local/progression_engine_database.dart';
import 'features/coach_log_export/application/bushido_export_provider.dart';
import 'features/coach_log_export/data/bushido_export_data_builder.dart';
import 'features/coach_log_export/data/bushido_fitness_source_adapter.dart';
import 'features/coach_log_export/data/bushido_nutrition_source_adapter.dart';
import 'features/coach_log_export/data/bushido_sheets_service.dart';
import 'features/sheets_export/application/sheets_export_provider.dart';
import 'features/social/application/social_provider.dart';
import 'features/social/data/social_firebase_bootstrap.dart';
import 'features/social/data/social_firebase_session.dart';
import 'features/social/data/social_repository_disabled.dart';
import 'features/social/data/social_repository_firestore.dart';
import 'features/nutrition/application/calorie_provider.dart';
import 'features/nutrition/application/kaloricke_tabulky_provider.dart';
import 'features/nutrition/data/calorie_api_service.dart';
import 'features/nutrition/data/kaloricke_tabulky_service.dart';
import 'features/nutrition/data/local/kt_nutrition_database.dart';
import 'features/health_connect/application/fitness_provider.dart';
import 'features/health_connect/data/health_connect_service.dart';
import 'features/health_connect/data/local/health_database.dart';
import 'features/health_connect/application/goals_provider.dart';
import 'features/devtools/application/devtools_provider.dart';
import 'features/devtools/application/factory_reset/factory_reset_service.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'app/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.app.info('Forgetrack starting up');

  // Debug builds: keep screen awake so Android Doze doesn't drop the
  // VM-service connection or trigger Firestore reconnect storms while
  // we're actively debugging. Never enabled in release.
  if (kDebugMode) {
    unawaited(WakelockPlus.enable());
  }

  AppLog.app.info('APP START TEST');
  AppLog.app.warn('APP WARN TEST');
  AppLog.app.error('APP ERROR TEST');

  await Future.wait([
    initializeDateFormatting('cs', null),
    initializeDateFormatting('en', null),
  ]);

  final localeProvider = LocaleProvider();
  await localeProvider.init();
  final notificationPreferencesProvider = NotificationPreferencesProvider();
  await notificationPreferencesProvider.init();

  final healthService = HealthConnectService();
  final healthDb = HealthDatabase();
  await healthDb.open();
  final fitnessProvider = FitnessProvider(healthService, healthDb);
  await fitnessProvider.initialize();
  unawaited(fitnessProvider.refreshOnAppOpen(force: true));

  final calorieApi = CalorieApiService();
  final ktService = KalorickeTabulkyService();
  final ktDb = KtNutritionDatabase();
  await ktDb.open();

  // Phase 4 + 6: the V2 engine's Isar store + repository + engine.
  // The provider is constructed inside MultiProvider so it can bind
  // to live source providers via ChangeNotifierProxyProvider4.
  final progressionEngineDb = ProgressionEngineDatabase();
  await progressionEngineDb.open();
  final progressionEngineRepo =
      IsarProgressionEngineRepository(progressionEngineDb);
  final progressionEngineV2 = ProgressionEngine(
    repository: progressionEngineRepo,
  );

  final ktProvider = KalorickeTabulkyProvider(ktService, ktDb);

  // Single source of truth for network availability — backs the home
  // offline banner and lets data-source providers decide whether to
  // surface "you're offline" instead of "connect this source" when a
  // restore fails.
  final connectivityProvider = ConnectivityProvider();
  unawaited(connectivityProvider.init());
  final socialBackendState = await SocialFirebaseBootstrap.ensureInitialized();
  // Once Firebase is up, gate Firestore's network on real connectivity so
  // the SDK doesn't burn battery retrying gRPC streams under Doze / airplane
  // mode / dead Wi-Fi. Reads still serve from cache while offline.
  if (Firebase.apps.isNotEmpty) {
    unawaited(FirestoreNetworkGate().start());
  }
  // Musí být registrován před runApp – top-level handler pro FCM v background/terminated stavu
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  final socialRepository = socialBackendState.isReady
      ? FirestoreSocialRepository()
      : DisabledSocialRepository(reason: socialBackendState.message);
  final socialSession = SocialFirebaseSession(
    isEnabled: socialBackendState.isReady,
  );
  await NotificationService.instance.initialize(
    requestPermissions: notificationPreferencesProvider.notificationsEnabled,
  );
  unawaited(FcmService.instance.initialize());
  unawaited(BackgroundSyncService.register());

  // Navigace z tapu na notifikaci při studeném startu
  final launchDetails = await NotificationService.instance.getLaunchDetails();
  if (launchDetails != null) {
    NotificationService.instance.handleNotificationTap(launchDetails);
  }

  // Při změně locale sync do Firestore, aby Cloud Functions mohly lokalizovat push notifikace
  localeProvider.addListener(() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      unawaited(FcmService.instance.saveLocale(
        canonicalUid(user),
        localeProvider.locale?.languageCode ?? 'cs',
      ));
    }
  });

  AppLog.app.info('Providers ready, launching KT initialize()');
  unawaited(ktProvider.initialize());

  final bushidoExportProvider = BushidoExportProvider(
    sheets: BushidoSheetsService(),
    dataBuilder: BushidoExportDataBuilder(
      fitness: BushidoFitnessSourceAdapter(fitnessProvider),
      nutrition: BushidoNutritionSourceAdapter(ktProvider),
    ),
    refreshFitness: fitnessProvider.refreshRange,
    refreshNutrition: ktProvider.refreshRange,
  );

  final goalsProvider = GoalsProvider();
  await goalsProvider.init();

  final devToolsProvider = DevToolsProvider();
  await devToolsProvider.init();

  final onboardingProvider = OnboardingProvider();
  await onboardingProvider.init();

  // Cosmetics: Isar-backed local persistence. Firestore sync lands in a
  // later phase (mirror progression's hybrid pattern when it does).
  final cosmeticsDatabase = CosmeticsDatabase();
  await cosmeticsDatabase.open();
  final cosmeticsConfig = CosmeticsConfig.standard();
  final cosmeticsRepository = IsarCosmeticsRepository(
    database: cosmeticsDatabase,
    config: cosmeticsConfig,
  );
  final cosmeticsService = CosmeticsService(
    repository: cosmeticsRepository,
    config: cosmeticsConfig,
  );
  final cosmeticEntitlementsSource = socialBackendState.isReady
      ? FirestoreCosmeticEntitlementsSource()
      : const NoopCosmeticEntitlementsSource();

  runApp(
    MultiProvider(
      providers: [
        // Plain (non-ChangeNotifier) singletons used by DevTools factory
        // reset. Exposed via Provider.value so they can be read from
        // BuildContext alongside the existing notifier providers.
        Provider<HealthDatabase>.value(value: healthDb),
        Provider<KtNutritionDatabase>.value(value: ktDb),
        Provider<ProgressionEngineDatabase>.value(value: progressionEngineDb),
        Provider<CosmeticsDatabase>.value(value: cosmeticsDatabase),
        Provider<FactoryResetService>(create: (_) => FactoryResetService()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: notificationPreferencesProvider),
        ChangeNotifierProvider.value(value: goalsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: fitnessProvider),
        ChangeNotifierProvider(create: (_) => CalorieProvider(calorieApi)),
        ChangeNotifierProvider.value(value: ktProvider),
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider(create: (_) => SheetsExportProvider()),
        ChangeNotifierProvider.value(value: bushidoExportProvider),
        ChangeNotifierProvider.value(value: devToolsProvider),
        ChangeNotifierProvider.value(value: onboardingProvider),
        ChangeNotifierProxyProvider<AuthProvider, CosmeticsProvider>(
          create: (_) => CosmeticsProvider(
            service: cosmeticsService,
            entitlementsSource: cosmeticEntitlementsSource,
          ),
          update: (_, auth, provider) {
            provider!.bindUser(auth.isSignedIn ? auth.user?.id : null);
            return provider;
          },
        ),
        // V2 progression engine — declared after CosmeticsProvider so its
        // bind() update sees it in scope. Source dependencies: goals +
        // fitness + nutrition + cosmetics.
        ChangeNotifierProxyProvider4<GoalsProvider, FitnessProvider,
            KalorickeTabulkyProvider, CosmeticsProvider,
            ProgressionEngineProvider>(
          create: (_) => ProgressionEngineProvider(
            engine: progressionEngineV2,
            repository: progressionEngineRepo,
          ),
          update: (_, goals, fitness, kt, cosmetics, provider) {
            provider!.bind(
              goalsProvider: goals,
              fitnessProvider: fitness,
              nutritionProvider: kt,
              cosmeticsProvider: cosmetics,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider3<AuthProvider, ProgressionEngineProvider,
            CosmeticsProvider, SocialProvider>(
          create: (_) => SocialProvider(
            repository: socialRepository,
            session: socialSession,
            backendState: socialBackendState,
          ),
          update: (_, auth, progression, cosmetics, provider) {
            provider!.bind(
              authProvider: auth,
              progressionProvider: progression,
              cosmeticsProvider: cosmetics,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<ProgressionEngineProvider,
            CosmeticsProvider, CelebrationController>(
          create: (_) => CelebrationController(),
          update: (_, progression, cosmetics, controller) {
            controller!.bind(progression: progression, cosmetics: cosmetics);
            return controller;
          },
        ),
      ],
      child: const ForgetrackApp(),
    ),
  );
}
