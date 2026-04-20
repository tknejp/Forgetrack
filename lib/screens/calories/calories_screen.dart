import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/goals_provider.dart';
import '../../providers/kaloricke_tabulky_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_level_app_bar.dart';
import '../profile/profile_screen.dart';

part 'calories_screen/nutrition_body.dart';
part 'calories_screen/nutrition_sections.dart';
part 'calories_screen/nutrition_cards.dart';

enum _Period { today, sevenDays, thirtyDays }

typedef _NutritionValues = ({
  double? calories,
  double? protein,
  double? fat,
  double? carbs,
  double? fiber,
  double? sugar,
  double? salt,
  double? saturatedFat,
});

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<KalorickeTabulkyProvider>(
      builder: (context, kt, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: TopLevelAppBar(
            title: l10n.screenNutrition,
            subtitle: buildTopLevelHeaderSubtitle(
              context,
              syncCopy: AppHeaderSyncCopy.nutrition,
              syncedAt: kt.lastSyncedAt,
            ),
          ),
          body: _NutritionBody(kt: kt),
        );
      },
    );
  }
}

class _NutritionDataView extends StatefulWidget {
  final KalorickeTabulkyProvider kt;

  const _NutritionDataView({required this.kt});

  @override
  State<_NutritionDataView> createState() => _NutritionDataViewState();
}

class _NutritionDataViewState extends State<_NutritionDataView> {
  _Period _period = _Period.today;

  Future<void> _onRefresh() {
    final kt = widget.kt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _Period.today:
        return kt.refresh();
      case _Period.sevenDays:
        return kt.refreshRange(today.subtract(const Duration(days: 7)), today);
      case _Period.thirtyDays:
        return kt.refreshRange(today.subtract(const Duration(days: 30)), today);
    }
  }

  _NutritionValues _resolveValues() {
    final kt = widget.kt;

    if (_period == _Period.today) {
      if (!kt.hasTodayData) {
        return (
          calories: null,
          protein: null,
          fat: null,
          carbs: null,
          fiber: null,
          sugar: null,
          salt: null,
          saturatedFat: null,
        );
      }
      return (
        calories: kt.todayCalories,
        protein: kt.todayProtein,
        fat: kt.todayFat,
        carbs: kt.todayCarbs,
        fiber: kt.todayFiber,
        sugar: kt.todaySugar,
        salt: kt.todaySalt,
        saturatedFat: kt.todaySaturatedFat,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysBack = _period == _Period.sevenDays ? 7 : 30;
    final start = today.subtract(Duration(days: daysBack));

    return (
      calories: kt.avgCaloriesForRange(start, today),
      protein: kt.avgProteinForRange(start, today),
      fat: kt.avgFatForRange(start, today),
      carbs: kt.avgCarbsForRange(start, today),
      fiber: kt.avgFiberForRange(start, today),
      sugar: kt.avgSugarForRange(start, today),
      salt: kt.avgSaltForRange(start, today),
      saturatedFat: kt.avgSaturatedFatForRange(start, today),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsProvider>();
    final values = _resolveValues();

    return _NutritionContentList(
      kt: widget.kt,
      period: _period,
      values: values,
      dailyCaloriesGoal: goals.dailyCalories,
      dailyProteinGoal: goals.dailyProtein,
      dailyFatGoal: goals.dailyFat,
      dailyCarbsGoal: goals.dailyCarbs,
      onRefresh: _onRefresh,
      onPeriodChanged: (period) => setState(() => _period = period),
      onOpenGoals: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
    );
  }
}
