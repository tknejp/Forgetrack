part of '../kaloricke_tabulky_service.dart';

String _maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) {
    return '***';
  }

  final local = parts[0];
  final domain = parts[1];
  final maskedLocal = local.length <= 2
      ? '${local[0]}*'
      : '${local[0]}***${local[local.length - 1]}';
  return '$maskedLocal@$domain';
}

String _shortBody(String body, {int max = 300}) {
  final normalized =
      body.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= max) {
    return normalized;
  }
  return '${normalized.substring(0, max)}...';
}

String _previewKeys(Iterable<Object?> keys, {int max = 12}) {
  final list = keys.map((key) => '$key').toList()..sort();
  if (list.isEmpty) {
    return '<none>';
  }
  if (list.length <= max) {
    return list.join(', ');
  }
  final shown = list.take(max).join(', ');
  return '$shown ... (+${list.length - max} more)';
}

String _describeValue(dynamic value) {
  if (value == null) {
    return 'null';
  }
  if (value is Map) {
    return 'Map(keys=${_previewKeys(value.keys)})';
  }
  if (value is List) {
    return 'List(len=${value.length})';
  }
  if (value is String) {
    return '"${_shortBody(value, max: 80)}"';
  }
  return '$value';
}

String _describeFields(Map<String, dynamic> data, List<String> keys) {
  return keys.map((key) => '$key=${_describeValue(data[key])}').join(', ');
}

String _describeNutrition(KtDayNutrition nutrition) {
  return 'kcal=${nutrition.calories}, '
      'P=${nutrition.protein}, '
      'F=${nutrition.fat}, '
      'C=${nutrition.carbs}, '
      'fiber=${nutrition.fiber}, '
      'sugar=${nutrition.sugar}, '
      'salt=${nutrition.salt}, '
      'satFat=${nutrition.saturatedFat}, '
      'drink=${nutrition.drinkRegime}, '
      'foods=${nutrition.foodCount}, '
      'hasData=${nutrition.hasData}';
}

String _previewNutritionRange(Map<String, KtDayNutrition> result, {int max = 5}) {
  if (result.isEmpty) {
    return '<none>';
  }
  final keys = result.keys.toList()..sort();
  final preview =
      keys.take(max).map((key) => '$key(${_describeNutrition(result[key]!)})');
  final joined = preview.join('; ');
  if (keys.length <= max) {
    return joined;
  }
  return '$joined; ... (+${keys.length - max} more)';
}

String _describeHeaders(Map<String, String> headers) {
  if (headers.isEmpty) {
    return '{}';
  }

  final described = <String, String>{};
  headers.forEach((key, value) {
    described[key] = key.toLowerCase() == 'cookie' ? '<present>' : value;
  });
  return described.toString();
}

String _formatRangeDate(DateTime dt) {
  return '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

String _formatDiaryDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year.toString().padLeft(4, '0')}';
}
