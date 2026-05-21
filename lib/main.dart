import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'core/logging/app_log.dart';
import 'app/notification_preferences_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, Settings;
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
import 'features/cosmetics/application/food_trigger_provider.dart';
import 'features/cosmetics/config/cosmetics_config.dart';
import 'features/cosmetics/data/cosmetic_entitlements_source.dart';
import 'features/cosmetics/data/firestore_cosmetic_entitlements_source.dart';
import 'features/cosmetics/data/isar_cosmetics_repository.dart';
import 'features/cosmetics/data/local/cosmetics_database.dart';
import 'features/progression_engine/application/progression_engine.dart';
import 'features/progression_engine/application/progression_engine_provider.dart';
import 'features/progression_engine/data/firestore_progression_engine_gateway.dart';
import 'features/progression_engine/data/hybrid_progression_engine_repository.dart';
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
import 'features/nutrition/application/kaloricke_tabulky_provider.dart';
import 'features/nutrition/data/kaloricke_tabulky_service.dart';
import 'features/nutrition/data/local/kt_nutrition_database.dart';
import 'features/health_connect/application/fitness_provider.dart';
import 'features/home/application/home_card_order_provider.dart';
import 'features/cosmetics/application/emblem_board_provider.dart';
import 'features/health_connect/data/health_connect_service.dart';
import 'features/health_connect/data/local/health_database.dart';
import 'features/health_connect/application/goals_provider.dart';
import 'features/health_connect/data/goal_history_firestore_gateway.dart';
import 'features/devtools/application/devtools_provider.dart';
import 'features/devtools/application/factory_reset/factory_reset_service.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'app/locale_provider.dart';
import 'app/player_provider.dart';
import 'domain/journal/journal_event.dart';
import 'domain/player/level_curve.dart';

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

  final ktService = KalorickeTabulkyService();
  final ktDb = KtNutritionDatabase();
  await ktDb.open();

  // Phase 4 + 6: the V2 engine's Isar store + repository.
  // Database open is async and slow on cold start, so kick it off
  // here. Engine + (optional) cloud-sync wrapper are constructed
  // below once we know whether the Firebase backend is up.
  final progressionEngineDb = ProgressionEngineDatabase();
  await progressionEngineDb.open();
  final progressionEngineLocalRepo =
      IsarProgressionEngineRepository(progressionEngineDb);

  final ktProvider = KalorickeTabulkyProvider(ktService, ktDb);

  // Single source of truth for network availability — backs the home
  // offline banner and lets data-source providers decide whether to
  // surface "you're offline" instead of "connect this source" when a
  // restore fails.
  final connectivityProvider = ConnectivityProvider();
  unawaited(connectivityProvider.init());

  final homeCardOrderProvider = HomeCardOrderProvider();
  await homeCardOrderProvider.init();
  final emblemBoardProvider = EmblemBoardProvider();
  await emblemBoardProvider.init();
  final socialBackendState = await SocialFirebaseBootstrap.ensureInitialized();
  // Once Firebase is up, gate Firestore's network on real connectivity so
  // the SDK doesn't burn battery retrying gRPC streams under Doze / airplane
  // mode / dead Wi-Fi. Reads still serve from cache while offline.
  if (Firebase.apps.isNotEmpty) {
    // Defensively explicit: persistence is on by default on iOS/Android but
    // off on web. Setting it here documents the intent and survives any
    // future platform expansion. Must be set before the first Firestore
    // read/write (FirestoreNetworkGate is the first consumer below).
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
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

  // Now that we know whether Firebase is up, decide if the engine
  // pushes ledger events to Firestore. Hybrid wraps the local repo;
  // ProgressionEngineProvider receives both refs (the wrapper as the
  // repository, plus a typed cloud-sync handle for `bindCloudUser` /
  // pull-and-merge calls). Without Firestore the local repo is used
  // directly and cloudSync stays null — engine behaves exactly as
  // before the V2 sync work.
  final progressionEngineCloudSync = socialBackendState.isReady
      ? HybridProgressionEngineRepository(
          local: progressionEngineLocalRepo,
          cloud: FirestoreProgressionEngineGateway(),
        )
      : null;
  final progressionEngineRepo =
      progressionEngineCloudSync ?? progressionEngineLocalRepo;
  final progressionEngineV2 = ProgressionEngine(
    repository: progressionEngineRepo,
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

  final goalsProvider = GoalsProvider(
    gateway: socialBackendState.isReady
        ? GoalHistoryFirestoreGateway()
        : null,
  );
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
        ChangeNotifierProvider(
          // Eager: AuthProvider listens to FirebaseAuth state changes from
          // construction time. If we let it stay lazy, Firestore-dependent
          // providers downstream (Social, Cosmetics) wait for first widget
          // read before they even start their cold-start hydration round-trip,
          // so the home screen briefly renders empty until streams catch up.
          lazy: false,
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider.value(value: fitnessProvider),
        ChangeNotifierProvider.value(value: ktProvider),
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider.value(value: homeCardOrderProvider),
        ChangeNotifierProvider.value(value: emblemBoardProvider),
        ChangeNotifierProvider(create: (_) => SheetsExportProvider()),
        ChangeNotifierProvider.value(value: bushidoExportProvider),
        ChangeNotifierProvider.value(value: devToolsProvider),
        ChangeNotifierProvider.value(value: onboardingProvider),
        ChangeNotifierProxyProvider<AuthProvider, CosmeticsProvider>(
          // Eager so cosmetic entitlements load + Isar state hydrate kick off
          // immediately at app boot rather than at first widget read.
          lazy: false,
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
        // bind() update sees it in scope. Source dependencies: auth (uid
        // for cloud sync) + goals + fitness + nutrition + cosmetics.
        ChangeNotifierProxyProvider5<
            AuthProvider,
            GoalsProvider,
            FitnessProvider,
            KalorickeTabulkyProvider,
            CosmeticsProvider,
            ProgressionEngineProvider>(
          // Eager: provider's constructor calls `_hydrate()` which loads the
          // Isar ledger. We want that running in parallel with Cosmetics +
          // Social so the home header doesn't wait on it.
          lazy: false,
          create: (_) => ProgressionEngineProvider(
            engine: progressionEngineV2,
            repository: progressionEngineRepo,
            cloudSync: progressionEngineCloudSync,
          ),
          update: (_, auth, goals, fitness, kt, cosmetics, provider) {
            provider!.bind(
              goalsProvider: goals,
              fitnessProvider: fitness,
              nutritionProvider: kt,
              cosmeticsProvider: cosmetics,
              emblemBoardProvider: emblemBoardProvider,
              authUid: auth.isSignedIn ? auth.user?.id : null,
            );
            return provider;
          },
        ),
        // Phase 5 of the domain refactor: Player is computed from
        // the Journal via Player.fromJournal, not read-through over
        // the engine's pre-computed profile. The proxy passes the
        // ledger's reward grants + the LevelCurve so the provider's
        // applySnapshot routes through the canonical derivation.
        // ProgressionEngineProvider's EngineProfile getter runs the
        // same XP sum (via Player.totalXpFromGrants) so the two
        // consumers stay in lockstep without a provider cycle.
        ChangeNotifierProxyProvider2<AuthProvider, ProgressionEngineProvider,
            PlayerProvider>(
          // Lazy: no Phase 5 consumer reads PlayerProvider yet, so
          // deferring creation until first read keeps startup cost
          // flat while the scaffolding is in place.
          create: (_) => PlayerProvider(),
          update: (_, auth, engine, provider) {
            final identity = auth.user;
            provider!.applySnapshot(
              uid: identity?.id ?? '',
              rewardGrants:
                  engine.ledger?.rewardGrants ?? const <RewardGrantEvent>[],
              levelCurve: const LevelCurve(),
              joinedAt: engine.joinedAt,
              displayName: identity?.displayName,
              photoUrl: identity?.photoUrl,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider3<AuthProvider, ProgressionEngineProvider,
            CosmeticsProvider, SocialProvider>(
          // Eager: starts Firestore session reconcile + friend / profile
          // stream subscriptions during boot. Without this, the hero profile
          // header on the home screen sees a blank avatar for 100-500 ms
          // until a widget first reads SocialProvider and triggers create().
          lazy: false,
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
        // Companion food triggers (Monster Energy easter egg, future
        // cow / hen). Declared after Calorie + Cosmetics + Engine so
        // context.read sees them during eager create(). Lazy: false
        // so prefs hydration starts at boot, not at first widget read
        // — without that the gold dot / claim pill miss their initial
        // paint on the home screen.
        ChangeNotifierProvider<FoodTriggerProvider>(
          lazy: false,
          create: (ctx) {
            final p = FoodTriggerProvider(
              nutritionProvider: ctx.read<KalorickeTabulkyProvider>(),
              cosmeticsProvider: ctx.read<CosmeticsProvider>(),
              grant: ({required int amount, required String periodKey}) =>
                  ctx.read<ProgressionEngineProvider>()
                      .grantCompanionTriggerXp(
                        amount: amount,
                        periodKey: periodKey,
                      ),
            );
            unawaited(p.init());
            return p;
          },
        ),
      ],
      child: const ForgetrackApp(),
    ),
  );
}
