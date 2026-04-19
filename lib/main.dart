import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_log.dart';
import 'providers/auth_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/fitness_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/kaloricke_tabulky_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/calorie_api_service.dart';
import 'services/google_auth_service.dart';
import 'services/health_connect_service.dart';
import 'services/kaloricke_tabulky_service.dart';
import 'services/kt_nutrition_database.dart';

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

  await GoogleAuthService.instance.init();
  AppLog.app.debug('Google auth initialized');

  final healthService = HealthConnectService();
  final fitnessProvider = FitnessProvider(healthService);
  final calorieApi = CalorieApiService();
  final ktService = KalorickeTabulkyService();
  final ktDb = KtNutritionDatabase();
  await ktDb.open();

  final ktProvider = KalorickeTabulkyProvider(ktService, ktDb);
  AppLog.app.info('Providers ready — launching KT initialize()');
  unawaited(ktProvider.initialize());

  final goalsProvider = GoalsProvider();
  await goalsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: goalsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: fitnessProvider),
        ChangeNotifierProvider(create: (_) => CalorieProvider(calorieApi)),
        ChangeNotifierProvider.value(value: ktProvider),
      ],
      child: const ForgetrackApp(),
    ),
  );
}
