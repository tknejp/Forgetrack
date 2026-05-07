part of '../kaloricke_tabulky_service.dart';

class _KtNutritionParser {
  KtDayNutrition parseDaySummary(Map<String, dynamic> data) {
    final summaryMetrics = _parseSummaryMetrics(data);

    double calories = _parseDouble(data['foodstuffEnergyTotal']);
    if (calories == 0) {
      calories = summaryMetrics['total'] ?? 0;
    }

    final balance = data['balance'];
    final basal = balance is Map
        ? _parseDouble(balance['basal'])
        : 0.0;

    final parsed = KtDayNutrition(
      calories: calories,
      protein: summaryMetrics['protein'] ?? 0,
      fat: summaryMetrics['fat'] ?? 0,
      carbs: summaryMetrics['carbohydrate'] ?? 0,
      fiber: summaryMetrics['fiber'] ?? 0,
      sugar: summaryMetrics['sugar'] ?? 0,
      saturatedFat: summaryMetrics['saturatedFattyAcid'] ?? 0,
      basal: basal,
    );
    AppLog.ktParse.debug(
      '_parseDaySummary() → ${_describeNutrition(parsed)}',
      payload: _describeFields(
        data,
        ['foodstuffEnergyTotal', 'items', 'itemsDynamic', 'balance'],
      ),
    );
    return parsed;
  }

  List<KtMeal> parseMeals(Map<String, dynamic> data) {
    final times = data['times'];
    if (times is! List) return const [];

    final result = <KtMeal>[];
    for (final raw in times) {
      if (raw is! Map) continue;
      final id = (raw['id'] ?? '').toString();
      final title = (raw['title'] ?? '').toString();
      final energyTotal = _parseDouble(raw['energyTotal']);
      final foodList = raw['foodstuff'];
      final foodstuffs = <KtFoodstuff>[];
      if (foodList is List) {
        for (final f in foodList) {
          if (f is! Map) continue;
          foodstuffs.add(KtFoodstuff(
            title: (f['title'] ?? '').toString(),
            unit: (f['unit'] ?? '').toString(),
            energy: _parseDouble(f['energy']),
            protein: _parseDouble(f['protein']),
            fat: _parseDouble(f['fat']),
            carbs: _parseDouble(f['carbohydrate']),
            fiber: _parseDouble(f['fiber']),
            sugar: _parseDouble(f['sugar']),
            salt: _parseDouble(f['salt']),
          ));
        }
      }
      result.add(KtMeal(
        id: id,
        title: title,
        energyTotal: energyTotal,
        foodstuff: foodstuffs,
      ));
    }
    return result;
  }

  KtDayNutrition parseDayDiary(Map<String, dynamic> data) {
    final summaryMetrics = _parseSummaryMetrics(data);
    var usedSummaryFallback = false;

    double calories = _parseDouble(data['energyTotal']);
    if (calories == 0) {
      calories = _parseDouble(data['foodstuffEnergyTotal']);
      if (calories != 0) {
        usedSummaryFallback = true;
      }
    }
    if (calories == 0) {
      calories = summaryMetrics['total'] ?? 0;
      if (calories != 0) {
        usedSummaryFallback = true;
      }
    }

    double protein = _parseDouble(data['proteinTotal']);
    if (protein == 0) {
      protein = _parseDouble(data['protein']);
    }
    if (protein == 0) {
      protein = summaryMetrics['protein'] ?? 0;
      if (protein != 0) {
        usedSummaryFallback = true;
      }
    }

    double fat = _parseDouble(data['fatTotal']);
    if (fat == 0) {
      fat = _parseDouble(data['fat']);
    }
    if (fat == 0) {
      fat = summaryMetrics['fat'] ?? 0;
      if (fat != 0) {
        usedSummaryFallback = true;
      }
    }

    double carbs = _parseDouble(data['carbohydrateTotal']);
    if (carbs == 0) {
      carbs = _parseDouble(data['carbohydrate']);
    }
    if (carbs == 0) {
      carbs = summaryMetrics['carbohydrate'] ?? 0;
      if (carbs != 0) {
        usedSummaryFallback = true;
      }
    }

    double fiber = _parseDouble(data['fiberTotal']);
    if (fiber == 0) {
      fiber = _parseDouble(data['fiber']);
    }
    if (fiber == 0) {
      fiber = summaryMetrics['fiber'] ?? 0;
      if (fiber != 0) {
        usedSummaryFallback = true;
      }
    }

    double sugar = _parseDouble(data['sugarTotal']);
    if (sugar == 0) {
      sugar = summaryMetrics['sugar'] ?? 0;
      if (sugar != 0) {
        usedSummaryFallback = true;
      }
    }

    double saturatedFat = _parseDouble(data['saturatedFattyAcidTotal']);
    if (saturatedFat == 0) {
      saturatedFat = summaryMetrics['saturatedFattyAcid'] ?? 0;
      if (saturatedFat != 0) {
        usedSummaryFallback = true;
      }
    }

    if (calories == 0 && protein == 0 && fat == 0 && carbs == 0) {
      AppLog.ktParse.warn(
        '_parseDayDiary: all macros zero after all fallbacks',
        payload: 'data keys=${data.keys.toList()}',
      );
    }

    final parsed = KtDayNutrition(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      fiber: fiber,
      sugar: sugar,
      salt: _parseDouble(data['saltTotal']),
      saturatedFat: saturatedFat,
      drinkRegime: _parseDouble(data['drinkRegime']),
      foodCount: _parseInt(data['foodstuffCount']),
      meals: parseMeals(data),
      lastSyncedAt: DateTime.now(),
    );
    AppLog.ktParse.debug(
      '_parseDayDiary() → ${_describeNutrition(parsed)}',
      payload: 'summaryFallback=$usedSummaryFallback, '
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
            'sugarTotal',
            'saltTotal',
            'saturatedFattyAcidTotal',
            'drinkRegime',
            'foodstuffCount',
            'items',
            'itemsDynamic',
          ])}',
    );
    return parsed;
  }

  Map<String, double> _parseSummaryMetrics(Map<String, dynamic> data) {
    final metrics = <String, double>{};

    void addMetric(dynamic rawEntry) {
      if (rawEntry is! Map) {
        return;
      }

      final code = rawEntry['code']?.toString();
      if (code == null || code.isEmpty) {
        return;
      }

      final value = _parseSummaryMetricValue(rawEntry);
      final existing = metrics[code];

      if (existing == null || existing == 0 || value != 0) {
        metrics[code] = value;
      }
    }

    void addMetrics(dynamic rawEntries) {
      if (rawEntries is! List) {
        return;
      }

      for (final entry in rawEntries) {
        if (entry is List) {
          addMetrics(entry);
        } else {
          addMetric(entry);
        }
      }
    }

    addMetrics(data['items']);
    addMetrics(data['itemsDynamic']);
    return metrics;
  }

  double _parseSummaryMetricValue(Map rawEntry) {
    final actualValue = _parseDouble(rawEntry['actualValue']);
    final actual = _parseDouble(rawEntry['actual']);

    if (actualValue != 0) {
      return actualValue;
    }
    if (actual != 0) {
      return actual;
    }
    if (rawEntry.containsKey('actualValue')) {
      return actualValue;
    }
    return actual;
  }

  int parseTimestampMs(dynamic raw) {
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse('$raw') ?? 0;
  }

  int _parseInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(_cleanNumString(value.toString())) ?? 0.0;
  }

  String _cleanNumString(String raw) {
    return raw
        .replaceAll('\u00a0', '')
        .replaceAll('\u202f', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
  }
}
