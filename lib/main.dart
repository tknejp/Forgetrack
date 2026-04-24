import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/progression/application/progression_engine.dart';
import 'features/progression/data/local/progression_database.dart';
import 'features/progression/data/progression_repository_impl.dart';
import 'features/progression/presentation/progression_provider.dart';
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
import 'providers/goals_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/time_theme_provider.dart';

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

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final timeThemeProvider = TimeThemeProvider();
  await timeThemeProvider.init();

  final healthService = HealthConnectService();
  final healthDb = HealthDatabase();
  await healthDb.open();
  final fitnessProvider = FitnessProvider(healthService, healthDb);

  final calorieApi = CalorieApiService();
  final ktService = KalorickeTabulkyService();
  final ktDb = KtNutritionDatabase();
  await ktDb.open();

  final progressionDb = ProgressionDatabase();
  await progressionDb.open();

  final ktProvider = KalorickeTabulkyProvider(ktService, ktDb);
  final progressionEngine = ProgressionEngine(
    repository: ProgressionRepositoryImpl(progressionDb),
  );
  final socialBackendState = await SocialFirebaseBootstrap.ensureInitialized();
  final socialRepository = socialBackendState.isReady
      ? FirestoreSocialRepository()
      : DisabledSocialRepository(reason: socialBackendState.message);
  final socialSession = SocialFirebaseSession(
    isEnabled: socialBackendState.isReady,
  );
  AppLog.app.info('Providers ready, launching KT initialize()');
  unawaited(ktProvider.initialize());

  final goalsProvider = GoalsProvider();
  await goalsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: timeThemeProvider),
        ChangeNotifierProvider.value(value: goalsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: fitnessProvider),
        ChangeNotifierProvider(create: (_) => CalorieProvider(calorieApi)),
        ChangeNotifierProvider.value(value: ktProvider),
        ChangeNotifierProvider(create: (_) => SheetsExportProvider()),
        ChangeNotifierProxyProvider3<GoalsProvider, FitnessProvider,
            KalorickeTabulkyProvider, ProgressionProvider>(
          create: (_) => ProgressionProvider(engine: progressionEngine),
          update: (_, goals, fitness, kt, provider) {
            provider!.bind(
              goalsProvider: goals,
              fitnessProvider: fitness,
              nutritionProvider: kt,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider2<AuthProvider, ProgressionProvider,
            SocialProvider>(
          create: (_) => SocialProvider(
            repository: socialRepository,
            session: socialSession,
            backendState: socialBackendState,
          ),
          update: (_, auth, progression, provider) {
            provider!.bind(
              authProvider: auth,
              progressionProvider: progression,
            );
            return provider;
          },
        ),
      ],
      child: const ForgetrackApp(),
    ),
  );
}
