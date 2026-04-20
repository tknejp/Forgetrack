import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_log.dart';
import '../../models/nutrition_day_record.dart';
import '../kaloricke_tabulky_service.dart';

/// Isar-backed local store for daily KT nutrition records.
/// Keeps an in-memory cache so all reads are synchronous, while writes
/// are persisted to Isar.
class KtNutritionDatabase {
  Isar? _isar;
  final Map<String, KtDayNutrition> _cache = {};
  bool _opened = false;

  Future<void> open() async {
    if (_opened) {
      AppLog.ktDb.debug('open() skipped — already open');
      return;
    }

    _opened = true;
    final dir = await getApplicationDocumentsDirectory();
    AppLog.ktDb.info('Opening Isar store', payload: dir.path);
    _isar = await Isar.open(
      [NutritionDayRecordSchema],
      directory: dir.path,
    );
    await _loadCache();
    AppLog.ktDb.success(
      'Isar store ready',
      payload: '${_cache.length} cached day(s): ${_previewKeys(_cache.keys)}',
    );
  }

  Future<void> _loadCache() async {
    final records = await _isar!.nutritionDayRecords.where().findAll();
    for (final r in records) {
      _cache[r.dateKey] = _fromRecord(r);
    }
    AppLog.ktDb.info(
      'Cache loaded from Isar',
      payload: '${records.length} record(s): ${_previewKeys(records.map((r) => r.dateKey))}',
    );
  }

  // ─── Sync reads (from cache) ───────────────────────────────────────────────

  KtDayNutrition? getDay(DateTime date) {
    final key = _toKey(date);
    final nutrition = _cache[key];
    AppLog.ktDb.debug(
      'getDay($key) → ${nutrition == null ? 'MISS' : 'HIT'}',
      payload: nutrition == null ? null : _describeNutrition(nutrition),
    );
    return nutrition;
  }

  bool hasDay(DateTime date) => _cache.containsKey(_toKey(date));

  /// Returns all cached records in [start, end] inclusive.
  Map<String, KtDayNutrition> getRange(DateTime start, DateTime end) {
    final result = <String, KtDayNutrition>{};
    var d = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(endDay)) {
      final key = _toKey(d);
      final v = _cache[key];
      if (v != null) result[key] = v;
      d = d.add(const Duration(days: 1));
    }
    AppLog.ktDb.debug(
      'getRange(${_toKey(start)} → ${_toKey(end)}) → ${result.length} hit(s)',
      payload: _previewKeys(result.keys),
    );
    return result;
  }

  // ─── Async writes ──────────────────────────────────────────────────────────

  Future<void> saveDay(DateTime date, KtDayNutrition nutrition) async {
    final key = _toKey(date);
    AppLog.ktDb.info(
      'saveDay($key)',
      payload: _describeNutrition(nutrition),
    );
    _cache[key] = nutrition;
    final record = _toRecord(key, nutrition);
    await _isar!.writeTxn(() async {
      await _isar!.nutritionDayRecords.putByDateKey(record);
    });
    final persisted = await _isar!.nutritionDayRecords.getByDateKey(key);
    AppLog.ktDb.success(
      'saveDay($key) persisted=${persisted != null}',
      payload: persisted == null ? null : _describeNutrition(_fromRecord(persisted)),
    );
  }

  Future<void> clear() async {
    AppLog.ktDb.info('clear() removing ${_cache.length} cached day(s)');
    _cache.clear();
    await _isar!.writeTxn(() async {
      await _isar!.nutritionDayRecords.clear();
    });
    AppLog.ktDb.success('clear() done');
  }

  // ─── Mapping ───────────────────────────────────────────────────────────────

  KtDayNutrition _fromRecord(NutritionDayRecord r) => KtDayNutrition(
        calories: r.calories,
        protein: r.protein,
        fat: r.fat,
        carbs: r.carbs,
        fiber: r.fiber,
        sugar: r.sugar,
        salt: r.salt,
        saturatedFat: r.saturatedFat,
        drinkRegime: r.hydration,
        foodCount: r.foodCount,
        lastSyncedAt: r.syncedAt,
      );

  NutritionDayRecord _toRecord(String key, KtDayNutrition n) {
    final todayKey = _toKey(DateTime.now());
    return NutritionDayRecord()
      ..dateKey = key
      ..calories = n.calories
      ..protein = n.protein
      ..fat = n.fat
      ..carbs = n.carbs
      ..fiber = n.fiber
      ..sugar = n.sugar
      ..salt = n.salt
      ..saturatedFat = n.saturatedFat
      ..hydration = n.drinkRegime
      ..foodCount = n.foodCount
      ..inferredComplete = key != todayKey
      ..syncedAt = n.lastSyncedAt;
  }

  static String _toKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _describeNutrition(KtDayNutrition nutrition) {
    return 'kcal=${nutrition.calories}, '
        'P=${nutrition.protein}, '
        'F=${nutrition.fat}, '
        'C=${nutrition.carbs}, '
        'fiber=${nutrition.fiber}, '
        'foods=${nutrition.foodCount}, '
        'synced=${nutrition.lastSyncedAt.toIso8601String()}';
  }

  String _previewKeys(Iterable<String> keys, {int max = 8}) {
    final list = keys.toList()..sort();
    if (list.isEmpty) return '<none>';
    if (list.length <= max) return list.join(', ');
    final shown = list.take(max).join(', ');
    return '$shown ... (+${list.length - max} more)';
  }
}
