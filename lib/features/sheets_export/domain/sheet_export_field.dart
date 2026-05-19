// TODO(domain-model): this file lives in `domain/` but imports providers from
// `application/` (FitnessProvider, KalorickeTabulkyProvider), violating the
// "domain stays pure" rule in docs/architecture.md §3. Out of scope for the
// active domain-model refactor — see docs/domain_model/proposal.md §1.1.
// Future fix: either move this catalog to `application/`, or refactor
// `SheetExportField.resolve` to take HealthSnapshot + NutritionSnapshot
// arguments instead of provider handles.
import 'package:meta/meta.dart';

import '../../../l10n/app_localizations.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../config/sheet_export_order_config.dart';

/// Snapshot of providers needed to resolve a field value for a given date.
/// Bundled so [SheetExportField.resolve] keeps a stable, testable signature.
@immutable
class SheetExportDataSources {
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider nutrition;

  const SheetExportDataSources({
    required this.fitness,
    required this.nutrition,
  });
}

/// Logical category used to group fields in the picker UI.
enum SheetExportCategory { activity, body, sleep, nutrition }

/// One exportable column. [key] is the stable persistence id (never shown in
/// the UI). [header] and [label] resolve to user-facing, localized strings.
/// [legacyHeaders] lists old headers that should be renamed in place on the
/// sheet when encountered (schema migration).
@immutable
class SheetExportField {
  final String key;
  final int order;
  final String Function(AppLocalizations l10n) header;
  final String Function(AppLocalizations l10n) label;
  final String Function(AppLocalizations l10n)? description;
  final List<String> legacyHeaders;
  final SheetExportCategory category;

  /// Resolves the value for [date] from the provider snapshot.
  /// Return `null` to write an empty cell (preserves existing value on merge).
  final Object? Function(DateTime date, SheetExportDataSources src) resolve;

  const SheetExportField({
    required this.key,
    required this.order,
    required this.header,
    required this.label,
    required this.category,
    required this.resolve,
    this.description,
    this.legacyHeaders = const [],
  });
}

/// Static catalog of every field that can be exported. New fields go here —
/// the screen, provider, and merge engine adapt automatically.
///
/// [order] defines the stable column order in the sheet. The date column is
/// always column A; the remaining columns are emitted in ascending [order].
abstract final class SheetExportFields {
  static final List<SheetExportField> all = [
    // ── Body ─────────────────────────────────────────────────────────────────
    SheetExportField(
      key: 'weight',
      order: SheetExportOrderConfig.weight,
      header: (l) => l.exportHeaderWeight,
      label: (l) => l.exportFieldWeight,
      description: (l) => l.exportFieldWeightDesc,
      legacyHeaders: const ['weight_kg'],
      category: SheetExportCategory.body,
      resolve: (d, s) {
        final w = s.fitness.weightForDate(d)?.weight;
        if (w == null) return null;
        return double.parse(w.toStringAsFixed(1));
      },
    ),
    SheetExportField(
      key: 'body_fat',
      order: SheetExportOrderConfig.bodyFat,
      header: (l) => l.exportHeaderBodyFat,
      label: (l) => l.exportFieldBodyFat,
      description: (l) => l.exportFieldBodyFatDesc,
      legacyHeaders: const ['body_fat_pct'],
      category: SheetExportCategory.body,
      resolve: (d, s) => s.fitness.weightForDate(d)?.bodyFat,
    ),

    // ── Nutrition (Kalorické tabulky) ────────────────────────────────────────
    SheetExportField(
      key: 'kcal_in',
      order: SheetExportOrderConfig.kcalIn,
      header: (l) => l.exportHeaderKcalIn,
      label: (l) => l.exportFieldKcalIn,
      description: (l) => l.exportFieldKcalInDesc,
      legacyHeaders: const ['calories_in_kcal'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.calories),
    ),
    SheetExportField(
      key: 'protein',
      order: SheetExportOrderConfig.protein,
      header: (l) => l.exportHeaderProtein,
      label: (l) => l.exportFieldProtein,
      legacyHeaders: const ['protein_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.protein),
    ),
    SheetExportField(
      key: 'carbs',
      order: SheetExportOrderConfig.carbs,
      header: (l) => l.exportHeaderCarbs,
      label: (l) => l.exportFieldCarbs,
      legacyHeaders: const ['carbs_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.carbs),
    ),
    SheetExportField(
      key: 'fat',
      order: SheetExportOrderConfig.fat,
      header: (l) => l.exportHeaderFat,
      label: (l) => l.exportFieldFat,
      legacyHeaders: const ['fat_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.fat),
    ),
    SheetExportField(
      key: 'fiber',
      order: SheetExportOrderConfig.fiber,
      header: (l) => l.exportHeaderFiber,
      label: (l) => l.exportFieldFiber,
      legacyHeaders: const ['fiber_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.fiber),
    ),
    SheetExportField(
      key: 'sugar',
      order: SheetExportOrderConfig.sugar,
      header: (l) => l.exportHeaderSugar,
      label: (l) => l.exportFieldSugar,
      legacyHeaders: const ['sugar_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.sugar),
    ),
    SheetExportField(
      key: 'salt',
      order: SheetExportOrderConfig.salt,
      header: (l) => l.exportHeaderSalt,
      label: (l) => l.exportFieldSalt,
      legacyHeaders: const ['salt_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) => _roundToInt(s.nutrition.nutritionForDate(d)?.salt),
    ),
    SheetExportField(
      key: 'saturated_fat',
      order: SheetExportOrderConfig.saturatedFat,
      header: (l) => l.exportHeaderSaturatedFat,
      label: (l) => l.exportFieldSaturatedFat,
      legacyHeaders: const ['saturated_fat_g'],
      category: SheetExportCategory.nutrition,
      resolve: (d, s) =>
          _roundToInt(s.nutrition.nutritionForDate(d)?.saturatedFat),
    ),

    // ── Activity ─────────────────────────────────────────────────────────────
    SheetExportField(
      key: 'steps',
      order: SheetExportOrderConfig.steps,
      header: (l) => l.exportHeaderSteps,
      label: (l) => l.exportFieldSteps,
      legacyHeaders: const ['steps'],
      category: SheetExportCategory.activity,
      resolve: (d, s) => s.fitness.stepsForDate(d),
    ),
    SheetExportField(
      key: 'active_calories',
      order: SheetExportOrderConfig.activeCalories,
      header: (l) => l.exportHeaderActiveCalories,
      label: (l) => l.exportFieldActiveCalories,
      description: (l) => l.exportFieldActiveCaloriesDesc,
      legacyHeaders: const ['active_calories_kcal'],
      category: SheetExportCategory.activity,
      resolve: (d, s) {
        final v = s.fitness.activeCaloriesBurnedForDate(d);
        return v == 0 ? null : double.parse(v.toStringAsFixed(1));
      },
    ),

    // ── Sleep ────────────────────────────────────────────────────────────────
    SheetExportField(
      key: 'sleep_minutes',
      order: SheetExportOrderConfig.sleepMinutes,
      header: (l) => l.exportHeaderSleepDuration,
      label: (l) => l.exportFieldSleepDuration,
      description: (l) => l.exportFieldSleepDurationDesc,
      legacyHeaders: const ['sleep_minutes'],
      category: SheetExportCategory.sleep,
      resolve: (d, s) {
        final sleep = s.fitness.sleepForDate(d);
        if (sleep == null) return null;
        final minutes = sleep.totalDuration.inMinutes;
        final hours = minutes ~/ 60;
        final mins = minutes % 60;
        return '$hours:${mins.toString().padLeft(2, '0')}';
      },
    ),
    SheetExportField(
      key: 'sleep_bedtime',
      order: SheetExportOrderConfig.sleepBedtime,
      header: (l) => l.exportHeaderSleepBedtime,
      label: (l) => l.exportFieldSleepBedtime,
      legacyHeaders: const ['sleep_bedtime'],
      category: SheetExportCategory.sleep,
      resolve: (d, s) {
        final r = s.fitness.sleepForDate(d);
        return r == null ? null : _hhmm(r.sleepStart);
      },
    ),
    SheetExportField(
      key: 'sleep_wake',
      order: SheetExportOrderConfig.sleepWake,
      header: (l) => l.exportHeaderSleepWake,
      label: (l) => l.exportFieldSleepWake,
      legacyHeaders: const ['sleep_wake'],
      category: SheetExportCategory.sleep,
      resolve: (d, s) {
        final r = s.fitness.sleepForDate(d);
        return r == null ? null : _hhmm(r.wakeTime);
      },
    ),
  ];

  static SheetExportField? byKey(String key) {
    for (final f in all) {
      if (f.key == key) return f;
    }
    return null;
  }

  static List<SheetExportField> byCategory(SheetExportCategory c) =>
      all.where((f) => f.category == c).toList(growable: false);

  static String categoryLabel(SheetExportCategory c, AppLocalizations l10n) =>
      switch (c) {
        SheetExportCategory.activity => l10n.exportCategoryActivity,
        SheetExportCategory.body => l10n.exportCategoryBody,
        SheetExportCategory.sleep => l10n.exportCategorySleep,
        SheetExportCategory.nutrition => l10n.exportCategoryNutrition,
      };

  // ── helpers ────────────────────────────────────────────────────────────────

  static int? _roundToInt(double? v) {
    if (v == null || v == 0) return null;
    return v.round();
  }

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
