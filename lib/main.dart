import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'features/progression/application/progression_engine.dart';
import 'features/progression/data/local/progression_database.dart';
import 'features/progression/data/progression_repository_impl.dart';
import 'features/progression/presentation/progression_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/fitness_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/kaloricke_tabulky_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/sheets_export_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/time_theme_provider.dart';
import 'services/calorie_api_service.dart';
import 'services/google_auth_service.dart';
import 'services/health_connect_service.dart';
import 'services/db/health_database.dart';
import 'services/kaloricke_tabulky_service.dart';
import 'services/db/kt_nutrition_database.dart';

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

  // Don't block app startup on lightweight Google auth restore.
  // On Android this can surface UI (Credential Manager / One Tap), which would
  // otherwise delay runApp() and prevent Health Connect from loading on a cold start.
  unawaited(GoogleAuthService.instance.initialize());
  AppLog.app.debug('Google auth initialization started');

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
  AppLog.app.info('Providers ready — launching KT initialize()');
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
      ],
      child: const ForgetrackApp(),
    ),
  );
}
