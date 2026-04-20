part of '../kaloricke_tabulky_service.dart';

class _KtStatisticsService {
  final _KtSessionClient _sessionClient;
  final _KtNutritionParser _parser;

  const _KtStatisticsService({
    required _KtSessionClient sessionClient,
    required _KtNutritionParser parser,
  })  : _sessionClient = sessionClient,
        _parser = parser;

  Future<Map<String, double>> fetchEnergyRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _sessionClient.assertLoggedIn();

    final startString = _formatRangeDate(start);
    final endString = _formatRangeDate(end);

    AppLog.ktApi.debug('fetchEnergyRange() $startString → $endString');

    final response = await _sessionClient.get(
      '$_ktBaseUrl/statistic/energy/$startString/$endString/get?format=json',
    );

    final body = _sessionClient.decodeJson(
      response.body,
      context: '$startString → $endString',
    );
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final values = (data['values'] as List<dynamic>?) ?? const [];

    final result = {
      for (final raw in values)
        if (raw is Map<String, dynamic> && raw['description'] != null)
          raw['description'] as String:
              _parser._parseDouble(raw['value']),
    };

    AppLog.ktApi.success(
      'Energy range loaded $startString → $endString',
      payload: 'items=${result.length}',
    );

    return result;
  }

  Future<Map<String, KtDayNutrition>> fetchNutrientsRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _sessionClient.assertLoggedIn();

    final startString = _formatRangeDate(start);
    final endString = _formatRangeDate(end);

    AppLog.ktApi.debug('fetchNutrientsRange() $startString → $endString');

    final url =
        '$_ktBaseUrl/statistic/nutrients/$startString/$endString/get?format=json';
    final headers = _sessionClient.buildGetHeaders();
    AppLog.ktApi.info(
      'Nutrient fetch request',
      payload: 'method=GET, url=$url, headers=${_describeHeaders(headers)}',
    );

    final response = await _sessionClient.get(url, headers: headers);
    AppLog.ktApi.info(
      'Nutrient fetch response',
      payload: 'status=${response.statusCode}, body=${response.body}',
    );

    final body = _sessionClient.decodeJson(
      response.body,
      context: '$startString → $endString',
    );
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final list = (data['nutrientsValues'] as List<dynamic>?) ?? const [];
    AppLog.ktParse.debug(
      'Nutrients range raw: records=${list.length}, keys=${_previewKeys(data.keys)}',
    );

    final result = <String, KtDayNutrition>{};

    for (final rawRecord in list) {
      if (rawRecord is! Map<String, dynamic>) {
        continue;
      }

      final timestampMs = _parser.parseTimestampMs(rawRecord['createdDate']);
      final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      final day = _formatRangeDate(dt);

      final nutrition = KtDayNutrition(
        calories: 0,
        protein: _parser._parseDouble((rawRecord['protein'] as Map?)?['value']),
        fat: _parser._parseDouble((rawRecord['fat'] as Map?)?['value']),
        carbs: _parser._parseDouble((rawRecord['carbs'] as Map?)?['value']),
        fiber: 0,
      );
      result[day] = nutrition;
      AppLog.ktParse.debug(
        'Nutrients range day $day: '
        '${_describeFields(rawRecord, ['createdDate', 'protein', 'fat', 'carbs'])} -> '
        '${_describeNutrition(nutrition)}',
      );
    }

    AppLog.ktApi.success(
      'Nutrients range loaded $startString → $endString',
      payload: 'days=${result.length}, preview=${_previewNutritionRange(result)}',
    );

    return result;
  }
}
