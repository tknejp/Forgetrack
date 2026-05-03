import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/logging/app_log.dart';
import 'app/notification_preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/background_sync_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/cosmetics/application/cosmetics_provider.dart';
import 'features/cosmetics/application/cosmetics_service.dart';
import 'features/cosmetics/config/cosmetics_config.dart';
import 'features/cosmetics/data/cosmetic_entitlements_source.dart';
import 'features/cosmetics/data/firestore_cosmetic_entitlements_source.dart';
import 'features/cosmetics/data/isar_cosmetics_repository.dart';
import 'features/cosmetics/data/local/cosmetics_database.dart';
import 'features/progression/application/progression_engine.dart';
import 'features/progression/data/firestore/firestore_progression_gateway.dart';
import 'features/progression/data/hybrid_progression_repository.dart';
import 'features/progression/data/local/progression_database.dart';
import 'features/progression/data/progression_repository_impl.dart';
import 'features/progression/application/progression_provider.dart';
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
import 'app/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.app.info('Forgetrack starting up');

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

  final calorieApi = CalorieApiService();
  final ktService = KalorickeTabulkyService();
  final ktDb = KtNutritionDatabase();
  await ktDb.open();

  final progressionDb = ProgressionDatabase();
  await progressionDb.open();

  final ktProvider = KalorickeTabulkyProvider(ktService, ktDb);
  final socialBackendState = await SocialFirebaseBootstrap.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localProgressionRepo = ProgressionRepositoryImpl(progressionDb);
  final progressionEngine = ProgressionEngine(
    repository: socialBackendState.isReady
        ? HybridProgressionRepository(
            local: localProgressionRepo,
            remote: FirestoreProgressionGateway(),
            userIdProvider: () {
              final user = FirebaseAuth.instance.currentUser;
              return user != null ? canonicalUid(user) : null;
            },
            prefs: prefs,
          )
        : localProgressionRepo,
  );
  // Musí být registrován před runApp – top-level handler pro FCM v background/terminated stavu
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  final socialRepository = socialBackendState.isReady
      ? FirestoreSocialRepository()
      : DisabledSocialRepository(reason: socialBackendState.message);
  final socialSession = SocialFirebaseSession(
    isEnabled: socialBackendState.isReady,
  );
  await NotificationService.instance.initialize();
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

  final goalsProvider = GoalsProvider();
  await goalsProvider.init();

  final devToolsProvider = DevToolsProvider();
  await devToolsProvider.init();

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
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: notificationPreferencesProvider),
        ChangeNotifierProvider.value(value: goalsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: fitnessProvider),
        ChangeNotifierProvider(create: (_) => CalorieProvider(calorieApi)),
        ChangeNotifierProvider.value(value: ktProvider),
        ChangeNotifierProvider(create: (_) => SheetsExportProvider()),
        ChangeNotifierProvider.value(value: devToolsProvider),
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
        ChangeNotifierProxyProvider4<GoalsProvider, FitnessProvider,
            KalorickeTabulkyProvider, CosmeticsProvider, ProgressionProvider>(
          create: (_) => ProgressionProvider(engine: progressionEngine),
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
        ChangeNotifierProxyProvider3<AuthProvider, ProgressionProvider,
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
      ],
      child: const ForgetrackApp(),
    ),
  );
}
