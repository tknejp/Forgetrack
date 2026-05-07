part of '../kaloricke_tabulky_service.dart';

class _KtDiaryService {
  final _KtSessionClient _sessionClient;
  final _KtNutritionParser _parser;

  const _KtDiaryService({
    required _KtSessionClient sessionClient,
    required _KtNutritionParser parser,
  })  : _sessionClient = sessionClient,
        _parser = parser;

  Future<KtDayNutrition> fetchDaySummary(DateTime date) async {
    _sessionClient.assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    AppLog.ktApi.debug('fetchDaySummary() for $dateString');

    final response = await _sessionClient.get(
      '$_ktBaseUrl/user/diary/summary/$dateString/get?format=json',
    );

    final body = _sessionClient.decodeJson(response.body, context: dateString);
    final code = body['code'];
    final message = (body['message'] ?? '').toString().trim();

    AppLog.ktApi.debug(
      'Diary summary response for $dateString: '
      'code=$code, message=${message.isEmpty ? "<empty>" : message}',
    );

    if (code == 0 || code == null) {
      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      AppLog.ktParse.debug(
        'Day summary raw for $dateString: '
        '${_describeFields(data, ['foodstuffEnergyTotal', 'items', 'itemsDynamic'])}; '
        'keys=${_previewKeys(data.keys)}',
      );
      final parsed = _parser.parseDaySummary(data);
      AppLog.ktApi.success(
        'Day summary loaded for $dateString',
        payload: 'kcal=${parsed.calories}, P=${parsed.protein}, '
            'F=${parsed.fat}, C=${parsed.carbs}, fiber=${parsed.fiber}',
      );
      return parsed;
    }

    final lowerMessage = message.toLowerCase();

    if (_sessionClient.looksLikeAuthProblem(lowerMessage)) {
      _sessionClient.invalidateSession();
      AppLog.ktApi.warn(
        'Auth problem while loading summary $dateString: $message',
      );
      throw KtAuthException(
        message.isNotEmpty ? message : 'Session expired',
      );
    }

    AppLog.ktApi.error(
      'Day summary failed for $dateString',
      payload: 'code=$code, message=$message',
    );

    throw KtApiException(
      'KT diary summary failed: code=$code'
      '${message.isNotEmpty ? ', message=$message' : ''}',
    );
  }

  Future<KtDayNutrition> fetchTodayNutrition() {
    AppLog.ktApi.debug('fetchTodayNutrition() called');
    return fetchDayNutritionMerged(DateTime.now());
  }

  Future<KtDayNutrition> fetchDayNutritionMerged(DateTime date) async {
    _sessionClient.assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    AppLog.ktApi.debug('fetchDayNutritionMerged() for $dateString');

    final results = await Future.wait([
      fetchDaySummary(date),
      fetchDayDiary(date),
    ]);
    final summary = results[0];
    final diary = results[1];

    final merged = KtDayNutrition(
      calories: summary.calories,
      protein: summary.protein,
      fat: summary.fat,
      carbs: summary.carbs,
      fiber: summary.fiber,
      sugar: summary.sugar,
      saturatedFat: summary.saturatedFat,
      salt: diary.salt,
      drinkRegime: diary.drinkRegime,
      foodCount: diary.foodCount,
      basal: summary.basal,
      meals: diary.meals,
      lastSyncedAt: DateTime.now(),
    );
    AppLog.ktApi.success(
      'fetchDayNutritionMerged() for $dateString',
      payload: _describeNutrition(merged),
    );
    return merged;
  }

  Future<KtDayNutrition> fetchDayDiary(DateTime date) async {
    _sessionClient.assertLoggedIn();

    final dateString = _formatDiaryDate(date);
    AppLog.ktApi.debug('fetchDayDiary() → GET $dateString');

    final response = await _sessionClient.get(
      '$_ktBaseUrl/user/diary/$dateString/get?format=json',
    );

    final body = _sessionClient.decodeJson(response.body, context: dateString);
    final code = body['code'];
    final message = (body['message'] ?? '').toString().trim();

    AppLog.ktApi.debug(
      'Day diary response for $dateString: '
      'code=$code, message=${message.isEmpty ? "<empty>" : message}',
    );

    if (code == 0 || code == null) {
      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      AppLog.ktParse.debug(
        'Day diary raw for $dateString: '
        '${_describeFields(data, [
              'energyTotal',
              'foodstuffEnergyTotal',
              'proteinTotal',
              'protein',
              'fatTotal',
              'fat',
              'carbohydrateTotal',
              'carbohydrate',
              'fiberTotal',
              'fiber',
              'foodstuffCount',
              'drinkRegime',
              'items',
              'itemsDynamic',
            ])}; keys=${_previewKeys(data.keys)}',
      );
      final parsed = _parser.parseDayDiary(data);
      AppLog.ktApi.success(
        'Day diary loaded for $dateString',
        payload: 'kcal=${parsed.calories}, P=${parsed.protein}, '
            'F=${parsed.fat}, C=${parsed.carbs}, fiber=${parsed.fiber}, '
            'sugar=${parsed.sugar}, salt=${parsed.salt}, '
            'drink=${parsed.drinkRegime}, foods=${parsed.foodCount}',
      );
      return parsed;
    }

    final lowerMessage = message.toLowerCase();

    if (_sessionClient.looksLikeAuthProblem(lowerMessage)) {
      _sessionClient.invalidateSession();
      AppLog.ktApi.warn('Auth problem while loading diary $dateString: $message');
      throw KtAuthException(
        message.isNotEmpty ? message : 'Session expired',
      );
    }

    AppLog.ktApi.error(
      'Day diary failed for $dateString',
      payload: 'code=$code, message=$message',
    );

    throw KtApiException(
      'KT day diary failed: code=$code'
      '${message.isNotEmpty ? ', message=$message' : ''}',
    );
  }
}
