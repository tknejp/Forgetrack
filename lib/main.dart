import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/fitness_provider.dart';
import 'providers/kaloricke_tabulky_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/calorie_api_service.dart';
import 'services/google_auth_service.dart';
import 'services/health_connect_service.dart';
import 'services/kaloricke_tabulky_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    initializeDateFormatting('cs', null),
    initializeDateFormatting('en', null),
  ]);

  final localeProvider = LocaleProvider();
  await localeProvider.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  await GoogleAuthService.instance.init();

  final healthService = HealthConnectService();
  final calorieApi = CalorieApiService();
  final ktService = KalorickeTabulkyService();

  final ktProvider = KalorickeTabulkyProvider(ktService);
  unawaited(ktProvider.initialize());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FitnessProvider(healthService)),
        ChangeNotifierProvider(create: (_) => CalorieProvider(calorieApi)),
        ChangeNotifierProvider.value(value: ktProvider),
      ],
      child: const ForgetrackApp(),
    ),
  );
}