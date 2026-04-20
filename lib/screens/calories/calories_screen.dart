import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/goals_provider.dart';
import '../../providers/kaloricke_tabulky_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar_action.dart';
import '../../widgets/screen_meta_footer.dart';
import '../profile/profile_screen.dart';

// ─── Period enum ──────────────────────────────────────────────────────────────

enum _Period { today, sevenDays, thirtyDays }

// ─── Screen ───────────────────────────────────────────────────────────────────

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<KalorickeTabulkyProvider>(
      builder: (context, kt, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(l10n.screenNutrition),
            actions: const [ProfileAvatarAction()],
          ),
          body: _buildBody(context, kt),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, KalorickeTabulkyProvider kt) {
    if (kt.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!kt.isLoggedIn) {
      return _NotConnectedState(
        onGoToSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      );
    }
    if (kt.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _NutritionDataView(kt: kt);
  }
}

// ─── Not connected ────────────────────────────────────────────────────────────

class _NotConnectedState extends StatelessWidget {
  final VoidCallback onGoToSettings;

  const _NotConnectedState({required this.onGoToSettings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined,
                size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 20),
            Text(
              l10n.screenNutrition,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ktLoginPrompt,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.ktGoToSettings),
              onPressed: onGoToSettings,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main data view (stateful — holds selected period) ────────────────────────

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

  ({
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? sugar,
    double? salt,
    double? saturatedFat,
  }) _resolveValues() {
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

    // avgXForRange already excludes today and zero-data days.
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
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final goals = context.watch<GoalsProvider>();
    final kt = widget.kt;
    final v = _resolveValues();
    final isAvg = _period != _Period.today;
    final hasData = v.calories != null;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // ── Header + sync time ──────────────────────────────────────────────

          // ── Error banners ───────────────────────────────────────────────────
          if (kt.syncError != null) ...[
            _ErrorBanner(
              message: l10n.ktSyncError,
              onRetry: () => kt.refresh(),
              retryLabel: l10n.ktRetry,
            ),
            const SizedBox(height: 12),
          ],
          if (kt.authError != null) ...[
            _ErrorBanner(
              message: kt.authError!,
              onRetry: null,
              retryLabel: null,
            ),
            const SizedBox(height: 12),
          ],

          // ── Period selector ─────────────────────────────────────────────────
          _PeriodSelector(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),

          // ── Data or empty state ─────────────────────────────────────────────
          if (!hasData) ...[
            _period == _Period.today
                ? const _NoDiaryDataCard()
                : _NoHistoryDataCard(message: l10n.nutritionNoHistoryData),
          ] else ...[
            _CalorieCard(
              calories: v.calories,
              goal: goals.dailyCalories,
              isAverage: isAvg,
            ),
            const SizedBox(height: 12),
            _MacrosCard(
              protein: v.protein,
              proteinGoal: goals.dailyProtein,
              fat: v.fat,
              fatGoal: goals.dailyFat,
              carbs: v.carbs,
              carbsGoal: goals.dailyCarbs,
              isAverage: isAvg,
            ),
            const SizedBox(height: 12),
            _SecondaryNutrientsCard(
              fiber: v.fiber,
              sugar: v.sugar,
              salt: v.salt,
              saturatedFat: v.saturatedFat,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.tune, size: 16),
                label: Text(l10n.nutritionGoalsTitle),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ),
          ],

          if (kt.lastSyncedAt != null) ...[
            const SizedBox(height: 14),
            ScreenMetaFooter(
              text: l10n.ktSyncedAt(
                DateFormat('HH:mm', locale).format(kt.lastSyncedAt!),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<_Period>(
      segments: [
        ButtonSegment(value: _Period.today, label: Text(l10n.stepsToday)),
        ButtonSegment(
          value: _Period.sevenDays,
          label: Text(l10n.nutritionPeriod7d),
        ),
        ButtonSegment(
          value: _Period.thirtyDays,
          label: Text(l10n.nutritionPeriod30d),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

// ─── Calorie card with goal progress ─────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  final double? calories;
  final double goal;
  final bool isAverage;

  const _CalorieCard({
    required this.calories,
    required this.goal,
    required this.isAverage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = context.tokens.nutrition.accent;
    final l10n = context.l10n;
    final hasValue = calories != null;
    final progress = hasValue ? (calories! / goal).clamp(0.0, 1.0) : 0.0;
    final isOver = hasValue && calories! > goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: accent, size: 28),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: hasValue ? '${calories!.round()}' : '–',
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      TextSpan(
                        text: ' kcal',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${goal.round()} kcal',
                      style:
                          tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.stepsGoal,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: isOver ? cs.error : accent,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: cs.surfaceContainerHighest,
            ),
            const SizedBox(height: 6),
            Text(
              isAverage
                  ? l10n.caloriesAvgPerDay
                  : isOver
                      ? '${(calories! - goal).round()} kcal over ${l10n.stepsGoal.toLowerCase()}'
                      : '${(goal - calories!).round()} kcal ${l10n.caloriesRemaining.toLowerCase()}',
              style: tt.bodySmall?.copyWith(
                color: isOver ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Primary macros card (protein / fat / carbs with goal progress) ───────────

class _MacrosCard extends StatelessWidget {
  final double? protein;
  final double proteinGoal;
  final double? fat;
  final double fatGoal;
  final double? carbs;
  final double carbsGoal;
  final bool isAverage;

  const _MacrosCard({
    required this.protein,
    required this.proteinGoal,
    required this.fat,
    required this.fatGoal,
    required this.carbs,
    required this.carbsGoal,
    required this.isAverage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            _MacroGoalRow(
              icon: Icons.fitness_center,
              label: l10n.macroProtein,
              value: protein,
              goal: proteinGoal,
              isAverage: isAverage,
            ),
            const _RowDivider(),
            _MacroGoalRow(
              icon: Icons.water_drop_outlined,
              label: l10n.macroFat,
              value: fat,
              goal: fatGoal,
              isAverage: isAverage,
            ),
            const _RowDivider(),
            _MacroGoalRow(
              icon: Icons.grain,
              label: l10n.macroCarbs,
              value: carbs,
              goal: carbsGoal,
              isAverage: isAverage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroGoalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? value;
  final double goal;
  final bool isAverage;

  const _MacroGoalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
    required this.isAverage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasValue = value != null;
    final progress = hasValue ? (value! / goal).clamp(0.0, 1.0) : 0.0;
    final isOver = hasValue && value! > goal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.secondary),
              const SizedBox(width: 10),
              Text(label, style: tt.bodyMedium),
              if (isAverage) ...[
                const SizedBox(width: 4),
                Text(
                  '∅',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              Text(
                hasValue
                    ? '${value!.round()} / ${goal.round()} g'
                    : '– / ${goal.round()} g',
                style: tt.bodySmall?.copyWith(
                  color: isOver ? cs.error : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            color: isOver ? cs.error : cs.secondary,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

// ─── Secondary nutrients card (fiber / sugar / salt / saturated fat) ──────────

class _SecondaryNutrientsCard extends StatelessWidget {
  final double? fiber;
  final double? sugar;
  final double? salt;
  final double? saturatedFat;

  const _SecondaryNutrientsCard({
    this.fiber,
    this.sugar,
    this.salt,
    this.saturatedFat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <({IconData icon, String label, double value})>[];

    if (fiber != null) {
      rows.add(
          (icon: Icons.eco_outlined, label: l10n.macroFiber, value: fiber!));
    }
    if (sugar != null) {
      rows.add((
        icon: Icons.water_drop_outlined,
        label: l10n.macroSugar,
        value: sugar!
      ));
    }
    if (salt != null) {
      rows.add(
          (icon: Icons.science_outlined, label: l10n.macroSalt, value: salt!));
    }
    if (saturatedFat != null) {
      rows.add((
        icon: Icons.layers_outlined,
        label: l10n.macroSaturatedFat,
        value: saturatedFat!
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const _RowDivider(),
              _NutrientRow(
                icon: rows[i].icon,
                label: rows[i].label,
                value: rows[i].value,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;

  const _NutrientRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: tt.bodyMedium),
          const Spacer(),
          Text(
            value < 10 ? '${value.toStringAsFixed(1)} g' : '${value.round()} g',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Row divider ──────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 44,
      endIndent: 0,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

// ─── No diary data placeholder ────────────────────────────────────────────────

class _NoDiaryDataCard extends StatelessWidget {
  const _NoDiaryDataCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.no_meals, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              l10n.ktNoDiaryData,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No history data placeholder ──────────────────────────────────────────────

class _NoHistoryDataCard extends StatelessWidget {
  final String message;

  const _NoHistoryDataCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
              ),
              onPressed: onRetry,
              child: Text(retryLabel ?? ''),
            ),
        ],
      ),
    );
  }
}
