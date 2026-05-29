import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_log.dart';

/// Where the player's nutrition goals (calories + macros) come from.
///
///   * [local] — the local goal board (`GoalsProvider`), the default and
///     pre-#98 behaviour.
///   * [kt] — per-day goals pulled from the Kalorické Tabulky API. Falls
///     back to [local] when KT is not connected or has no goals for a day.
enum NutritionGoalsSource {
  local,
  kt;

  static NutritionGoalsSource fromKey(String? raw) {
    return NutritionGoalsSource.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => NutritionGoalsSource.local,
    );
  }
}

/// Persists + exposes the nutrition goal source flag (Trello #98).
///
/// Mirrors the shape of `NotificationPreferencesProvider`: a thin
/// `ChangeNotifier` over a single SharedPreferences key. Read by
/// `GoalsProvider` (via a `bool` resolver wired in `main.dart`) to decide
/// whether the five nutrition getters dispatch to the KT gateway.
class NutritionGoalsSourceProvider extends ChangeNotifier {
  static const String prefsKey = 'nutrition_goals_source';

  NutritionGoalsSource _source = NutritionGoalsSource.local;

  NutritionGoalsSource get source => _source;
  bool get usesKt => _source == NutritionGoalsSource.kt;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _source = NutritionGoalsSource.fromKey(prefs.getString(prefsKey));
    AppLog.app.info('nutritionGoalsSource: init → ${_source.name}');
  }

  Future<void> setSource(NutritionGoalsSource value) async {
    if (_source == value) return;
    _source = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, value.name);
    AppLog.app.info('nutritionGoalsSource: set → ${value.name}');
  }
}
