import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/dashboard_card_assets.dart';
import '../../../../shared/widgets/detail_shortcut_button.dart';
import '../../../../shared/widgets/macro_row.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../health_connect/application/goals_provider.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import 'home_helpers.dart';
import 'kt_card_status_footer.dart';
import 'nutrition_detail_tile.dart';

class CaloriesSlot extends StatelessWidget {
  const CaloriesSlot({
    super.key,
    required this.period,
    required this.barKey,
    required this.onOpenNutrition,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenNutrition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final isCurrentDay =
        period.type == PeriodType.day && period.isCurrentPeriod;
    final dayNutrition = period.type == PeriodType.day
        ? kt.nutritionForDate(period.start)
        : null;
    final nutritionSummary = period.type == PeriodType.day
        ? null
        : kt.nutritionSummaryForRange(period.start, period.end);

    final kcal = period.type == PeriodType.day
        ? (dayNutrition?.calories ?? (isCurrentDay ? kt.todayCalories : 0.0))
        : (nutritionSummary?.calories ?? 0.0);
    final kcalGoal = goals.dailyCalories;
    final kcalProgress = kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final kcalDiff = kcal - kcalGoal;
    final kcalPct = kcalGoal > 0 ? ((kcal / kcalGoal) * 100).round() : 0;

    final protein = period.type == PeriodType.day
        ? (dayNutrition?.protein ?? (isCurrentDay ? kt.todayProtein : 0.0))
        : (nutritionSummary?.protein ?? 0.0);
    final fat = period.type == PeriodType.day
        ? (dayNutrition?.fat ?? (isCurrentDay ? kt.todayFat : 0.0))
        : (nutritionSummary?.fat ?? 0.0);
    final carbs = period.type == PeriodType.day
        ? (dayNutrition?.carbs ?? (isCurrentDay ? kt.todayCarbs : 0.0))
        : (nutritionSummary?.carbs ?? 0.0);
    final fiber = period.type == PeriodType.day
        ? (dayNutrition?.fiber ?? (isCurrentDay ? kt.todayFiber : 0.0))
        : (nutritionSummary?.fiber ?? 0.0);
    final nutritionHasDetails =
        kcal > 0 || protein > 0 || fat > 0 || carbs > 0 || fiber > 0;
    final remainingToTarget = kcalGoal - kcal;

    final footerActive = KtCardStatusFooter.isActive(kt);

    return StatCard(
          icon: '🔥',
          label: period.type == PeriodType.day
              ? l10n.caloriesTodayTitle
              : l10n.caloriesAvgPerDay,
          domain: Tokens.calories,
          visualAssets:
              DashboardCardAssetResolver.forKind(DashboardCardKind.nutrition),
          stats: [
            StatStat(
              value: fmt.format(kcal.round()),
              label: l10n.caloriesConsumed,
              unit: 'kcal',
            ),
            StatStat(
              value: fmt.format(kcalGoal.round()),
              label: l10n.weightGoal,
              unit: 'kcal',
            ),
            StatStat(
              value:
                  '${kcalDiff >= 0 ? '+' : ''}${fmt.format(kcalDiff.round())}',
              label:
                  kcalDiff >= 0 ? l10n.caloriesBurned : l10n.caloriesRemaining,
              unit: 'kcal',
            ),
          ],
          progress: kcalProgress,
          badge: '$kcalPct%',
          xpData: xpPillForQuest(
            context: context,
            progression: progression,
            period: period,
            questNodeId: 'daily_calories_today',
            barKey: barKey,
          ),
          footer: footerActive
              ? KtCardStatusFooter(
                  kt: kt,
                  onSyncRetry: () =>
                      kt.refreshRange(period.start, period.end),
                )
              : null,
          children: [
            if (streakInfoBlockForQuest(
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_calories_today',
                )
                case final block?) ...[
              const SizedBox(height: Tokens.spaceMd),
              block,
              const SizedBox(height: Tokens.spaceXs),
            ],
            const SizedBox(height: Tokens.spaceMd),
            if (nutritionHasDetails) ...[
              MacroRow(
                label: l10n.macroProtein,
                value: protein,
                goal: goals.dailyProtein,
                unit: 'g',
                domain: Tokens.protein,
                xpData: xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_protein_today',
                  barKey: barKey,
                ),
              ),
              MacroRow(
                label: l10n.macroCarbs,
                value: carbs,
                goal: goals.dailyCarbs,
                unit: 'g',
                domain: Tokens.carbs,
                xpData: xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_carbs_today',
                  barKey: barKey,
                ),
              ),
              MacroRow(
                label: l10n.macroFat,
                value: fat,
                goal: goals.dailyFat,
                unit: 'g',
                domain: Tokens.fat,
                xpData: xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_fat_today',
                  barKey: barKey,
                ),
              ),
              MacroRow(
                label: 'Fiber',
                value: fiber,
                goal: goals.dailyFiber,
                unit: 'g',
                domain: Tokens.calories,
                isLast: true,
                xpData: xpPillForQuest(
                  context: context,
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_fiber_today',
                  barKey: barKey,
                ),
              ),
              const SizedBox(height: Tokens.spaceMd),
              NutritionDetailTile(
                label: l10n.caloriesRemaining,
                value: '${remainingToTarget.abs().round()} kcal',
                color: remainingToTarget >= 0
                    ? Tokens.calories.color
                    : Tokens.danger,
              ),
            ],
            DetailShortcutButton(
              onTap: onOpenNutrition,
              domain: Tokens.calories,
            ),
          ],
        );
  }
}
