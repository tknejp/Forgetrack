import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/calorie_provider.dart';
import 'providers/fitness_provider.dart';
import 'services/calorie_api_service.dart';
import 'services/google_auth_service.dart';
import 'services/health_connect_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializuj GoogleSignIn před buildem widgetů, aby _authSub
  // byl připraven dřív než AuthProvider začne poslouchat onAuthChanged.
  await GoogleAuthService.instance.init();

  final healthService = HealthConnectService();
  final calorieApi = CalorieApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => FitnessProvider(healthService),
        ),
        ChangeNotifierProvider(
          create: (_) => CalorieProvider(calorieApi),
        ),
      ],
      child: const ForgetrackApp(),
    ),
  );
}
