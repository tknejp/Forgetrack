import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/app_log.dart';

part 'kaloricke_tabulky_service/kt_diary_service.dart';
part 'kaloricke_tabulky_service/kt_nutrition_parser.dart';
part 'kaloricke_tabulky_service/kt_service_formatter.dart';
part 'kaloricke_tabulky_service/kt_session_client.dart';
part 'kaloricke_tabulky_service/kt_statistics_service.dart';

const _ktBaseUrl = 'https://www.kaloricketabulky.cz';
const _ktEmailKey = 'kt_email';
const _ktPasswordHashKey = 'kt_pwd_hash';

class KtAuthException implements Exception {
  final String message;
  const KtAuthException(this.message);

  @override
  String toString() => 'KtAuthException: $message';
}

class KtApiException implements Exception {
  final String message;
  const KtApiException(this.message);

  @override
  String toString() => 'KtApiException: $message';
}

class KtDayNutrition {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double salt;
  final double saturatedFat;
  final double drinkRegime;
  final int foodCount;
  final DateTime lastSyncedAt;

  KtDayNutrition({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    this.sugar = 0,
    this.salt = 0,
    this.saturatedFat = 0,
    this.drinkRegime = 0,
    this.foodCount = 0,
    DateTime? lastSyncedAt,
  }) : lastSyncedAt = lastSyncedAt ?? DateTime(0);

  bool get hasData => foodCount > 0 || calories > 0 || protein > 0;

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
        'salt': salt,
        'saturatedFat': saturatedFat,
        'drinkRegime': drinkRegime,
        'foodCount': foodCount,
        'lastSyncedAt': lastSyncedAt.millisecondsSinceEpoch,
      };

  factory KtDayNutrition.fromJson(Map<String, dynamic> json) => KtDayNutrition(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
        salt: (json['salt'] as num?)?.toDouble() ?? 0,
        saturatedFat: (json['saturatedFat'] as num?)?.toDouble() ?? 0,
        drinkRegime: (json['drinkRegime'] as num?)?.toDouble() ?? 0,
        foodCount: (json['foodCount'] as num?)?.toInt() ?? 0,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncedAt'] as int)
            : null,
      );
}

class KalorickeTabulkyService {
  late final _KtNutritionParser _parser;
  late final _KtSessionClient _sessionClient;
  late final _KtDiaryService _diaryService;
  late final _KtStatisticsService _statisticsService;

  KalorickeTabulkyService({
    http.Client? client,
    FlutterSecureStorage? storage,
  }) {
    _parser = _KtNutritionParser();
    _sessionClient = _KtSessionClient(
      client: client,
      storage: storage,
    );
    _diaryService = _KtDiaryService(
      sessionClient: _sessionClient,
      parser: _parser,
    );
    _statisticsService = _KtStatisticsService(
      sessionClient: _sessionClient,
      parser: _parser,
    );
  }

  bool get isLoggedIn => _sessionClient.isLoggedIn;

  Future<void> login(String email, String password) {
    return _sessionClient.login(email, password);
  }

  Future<bool> restoreSession() {
    return _sessionClient.restoreSession();
  }

  Future<String?> storedEmail() {
    return _sessionClient.storedEmail();
  }

  Future<void> logout() {
    return _sessionClient.logout();
  }

  Future<KtDayNutrition> fetchDaySummary(DateTime date) {
    return _diaryService.fetchDaySummary(date);
  }

  Future<KtDayNutrition> fetchTodayNutrition() {
    return _diaryService.fetchTodayNutrition();
  }

  Future<KtDayNutrition> fetchDayNutritionMerged(DateTime date) {
    return _diaryService.fetchDayNutritionMerged(date);
  }

  Future<KtDayNutrition> fetchDayDiary(DateTime date) {
    return _diaryService.fetchDayDiary(date);
  }

  Future<Map<String, double>> fetchEnergyRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _statisticsService.fetchEnergyRange(
      start: start,
      end: end,
    );
  }

  Future<Map<String, KtDayNutrition>> fetchNutrientsRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _statisticsService.fetchNutrientsRange(
      start: start,
      end: end,
    );
  }
}
