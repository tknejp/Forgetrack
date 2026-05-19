import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/logging/app_log.dart';

part 'kaloricke_tabulky_service/kt_diary_service.dart';
part 'kaloricke_tabulky_service/kt_nutrition_parser.dart';
part 'kaloricke_tabulky_service/kt_service_formatter.dart';
part 'kaloricke_tabulky_service/kt_session_client.dart';
part 'kaloricke_tabulky_service/kt_statistics_service.dart';

const _ktBaseUrl = 'https://www.kaloricketabulky.cz';
const _ktEmailKey = 'kt_email';
const _ktPasswordHashKey = 'kt_pwd_hash';

/// Auth-layer failure from KalorickeTabulky (cookie expired, 401,
/// re-login required). Treated as a transient [NetworkError] by
/// [classifyKtError]; consumers that want to pattern-match on severity
/// route the caught exception through the classifier.
///
/// **R.4 (2026-05-19) — KT methods stay bare (no [Result] wrap).** The
/// service already throws typed exceptions ([KtAuthException],
/// [KtApiException]) which `classifyKtError` maps to [AppError] at the
/// outermost boundary ([BackgroundSyncService] callback,
/// [KtSyncCoordinator] for foreground syncs). Migrating every method
/// to `Future<Result<T, AppError>>` would double the classification
/// surface for no consumer benefit — the typed exception IS the
/// boundary contract, the classifier maps it to the typed [AppError]
/// hierarchy exactly once.
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

class KtFoodstuff {
  final String title;
  final String unit;
  final double energy;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double salt;

  const KtFoodstuff({
    required this.title,
    required this.unit,
    required this.energy,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.salt = 0,
  });

  Map<String, dynamic> toJson() => {
        't': title,
        'u': unit,
        'e': energy,
        'p': protein,
        'f': fat,
        'c': carbs,
        'fb': fiber,
        's': sugar,
        'sl': salt,
      };

  factory KtFoodstuff.fromJson(Map<String, dynamic> json) => KtFoodstuff(
        title: (json['t'] ?? '') as String,
        unit: (json['u'] ?? '') as String,
        energy: (json['e'] as num?)?.toDouble() ?? 0,
        protein: (json['p'] as num?)?.toDouble() ?? 0,
        fat: (json['f'] as num?)?.toDouble() ?? 0,
        carbs: (json['c'] as num?)?.toDouble() ?? 0,
        fiber: (json['fb'] as num?)?.toDouble() ?? 0,
        sugar: (json['s'] as num?)?.toDouble() ?? 0,
        salt: (json['sl'] as num?)?.toDouble() ?? 0,
      );
}

class KtMeal {
  /// Time-of-day id from KT, "1".."6". Stable across nights so we can map to
  /// an emoji (breakfast/lunch/dinner/etc.) without brittle title matching.
  final String id;
  final String title;
  final double energyTotal;
  final List<KtFoodstuff> foodstuff;

  const KtMeal({
    required this.id,
    required this.title,
    required this.energyTotal,
    required this.foodstuff,
  });

  bool get hasFood => foodstuff.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        't': title,
        'e': energyTotal,
        'f': [for (final f in foodstuff) f.toJson()],
      };

  factory KtMeal.fromJson(Map<String, dynamic> json) => KtMeal(
        id: (json['id'] ?? '') as String,
        title: (json['t'] ?? '') as String,
        energyTotal: (json['e'] as num?)?.toDouble() ?? 0,
        foodstuff: [
          for (final raw in (json['f'] as List? ?? const []))
            if (raw is Map<String, dynamic>) KtFoodstuff.fromJson(raw),
        ],
      );
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

  /// Basal metabolic rate (kcal) reported by KT for this day. Zero when KT
  /// didn't return a balance block (older days, missing settings).
  final double basal;

  /// Per-meal breakdown extracted from the daily diary `times[]` array.
  /// Empty when the diary endpoint wasn't fetched (e.g. summary-only sync).
  final List<KtMeal> meals;

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
    this.basal = 0,
    this.meals = const [],
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
        'basal': basal,
        'meals': [for (final m in meals) m.toJson()],
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
        basal: (json['basal'] as num?)?.toDouble() ?? 0,
        meals: [
          for (final raw in (json['meals'] as List? ?? const []))
            if (raw is Map<String, dynamic>) KtMeal.fromJson(raw),
        ],
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
