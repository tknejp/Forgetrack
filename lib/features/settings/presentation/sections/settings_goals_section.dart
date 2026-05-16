import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../features/health_connect/application/goals_provider.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_widgets.dart';

/// Atwater factor — kcal yielded per gram of macronutrient. Used by the
/// macro-breakdown info row to flag when the user's protein / fat /
/// carbs targets don't line up with the calorie target.
const double _kKcalPerGramProtein = 4;
const double _kKcalPerGramFat = 9;
const double _kKcalPerGramCarbs = 4;

/// Tolerance band (kcal) for the "macros match the calorie goal"
/// info row — small drifts are common when goals are rounded.
const int _kMacroKcalToleranceKcal = 50;

/// Goals settings — one card grouping every player target.
///
/// Layout follows the natural shape of each domain. Sections that
/// carry a single tap-to-edit goal (Body, Sleep) render as a plain
/// settings tile, opening the edit dialog directly — no chevron, no
/// expand. Sections with multiple knobs (Activity, Nutrition) stay
/// behind an expandable header so the surface doesn't grow tall by
/// default. Each section's icon picks up the matching domain accent
/// so the goals screen scans the same way as the home dashboard.
class SettingsGoalsSection extends StatelessWidget {
  const SettingsGoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsProvider>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final intFormat = NumberFormat.decimalPattern(locale);
    final oneDecimal = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    );

    return SettingsCard(
      children: [
        _ActivityGoalsTile(
          goals: goals,
          l10n: l10n,
          intFormat: intFormat,
        ),
        const SettingsTileDivider(indent: 0),
        _BodyGoalTile(
          goals: goals,
          l10n: l10n,
          oneDecimal: oneDecimal,
        ),
        const SettingsTileDivider(indent: 0),
        _NutritionGoalsTile(
          goals: goals,
          l10n: l10n,
          intFormat: intFormat,
        ),
        const SettingsTileDivider(indent: 0),
        _SleepGoalTile(
          goals: goals,
          l10n: l10n,
          oneDecimal: oneDecimal,
        ),
      ],
    );
  }
}

/// Multi-goal activity section: daily steps + weekly active minutes.
/// Stays expandable so two unrelated time scopes don't clutter the
/// collapsed view.
class _ActivityGoalsTile extends StatelessWidget {
  const _ActivityGoalsTile({
    required this.goals,
    required this.l10n,
    required this.intFormat,
  });

  final GoalsProvider goals;
  final AppLocalizations l10n;
  final NumberFormat intFormat;

  @override
  Widget build(BuildContext context) {
    final accent = Tokens.active;
    return SettingsExpandableTile(
      icon: Icons.directions_run_rounded,
      iconColor: accent.color,
      iconBackgroundColor: accent.dim,
      label: l10n.settingsGoalsActivityHeader,
      summary: '${intFormat.format(goals.dailySteps)} ${l10n.goalUnitSteps} · '
          '${intFormat.format(goals.weeklyActivityMins)} ${l10n.goalUnitMins}/wk',
      children: [
        _ChildGoalTile(
          icon: Icons.directions_walk_rounded,
          accent: accent,
          label: l10n.goalDailySteps,
          valueText: intFormat.format(goals.dailySteps),
          unit: l10n.goalUnitSteps,
          onTap: () => _editIntGoal(
            context,
            title: l10n.goalDailySteps,
            initialValue: goals.dailySteps,
            unit: l10n.goalUnitSteps,
            onSave: (value) =>
                context.read<GoalsProvider>().setDailySteps(value),
          ),
        ),
        const SettingsTileDivider(),
        _ChildGoalTile(
          icon: Icons.timer_outlined,
          accent: accent,
          label: l10n.goalWeeklyActivity,
          valueText: intFormat.format(goals.weeklyActivityMins),
          unit: l10n.goalUnitMins,
          onTap: () => _editIntGoal(
            context,
            title: l10n.goalWeeklyActivity,
            initialValue: goals.weeklyActivityMins,
            unit: l10n.goalUnitMins,
            onSave: (value) =>
                context.read<GoalsProvider>().setWeeklyActivityMins(value),
          ),
        ),
      ],
    );
  }
}

/// Single-goal body section. Renders as a plain settings tile — tap
/// straight into the edit dialog, no expand affordance to fish past.
class _BodyGoalTile extends StatelessWidget {
  const _BodyGoalTile({
    required this.goals,
    required this.l10n,
    required this.oneDecimal,
  });

  final GoalsProvider goals;
  final AppLocalizations l10n;
  final NumberFormat oneDecimal;

  @override
  Widget build(BuildContext context) {
    final accent = Tokens.weight;
    return SettingsTile(
      icon: Icons.monitor_weight_outlined,
      iconColor: accent.color,
      iconBackgroundColor: accent.dim,
      label: l10n.settingsGoalsBodyHeader,
      subtitle: l10n.goalTargetWeight,
      trailing: _EditableValuePill(
        text: '${oneDecimal.format(goals.targetWeight)} kg',
      ),
      onTap: () => _editDoubleGoal(
        context,
        title: l10n.goalTargetWeight,
        initialValue: goals.targetWeight,
        unit: 'kg',
        fractionDigits: 1,
        onSave: (value) =>
            context.read<GoalsProvider>().setTargetWeight(value),
      ),
    );
  }
}

/// Multi-goal nutrition section. Expanded body lists kcal + four
/// macros + a derived "kcal from macros" reconciliation row.
class _NutritionGoalsTile extends StatelessWidget {
  const _NutritionGoalsTile({
    required this.goals,
    required this.l10n,
    required this.intFormat,
  });

  final GoalsProvider goals;
  final AppLocalizations l10n;
  final NumberFormat intFormat;

  @override
  Widget build(BuildContext context) {
    final accent = Tokens.calories;
    final summary = l10n.settingsGoalsNutritionSummary(
      intFormat.format(goals.dailyCalories.round()),
      intFormat.format(goals.dailyProtein.round()),
      intFormat.format(goals.dailyFat.round()),
      intFormat.format(goals.dailyCarbs.round()),
      intFormat.format(goals.dailyFiber.round()),
    );
    return SettingsExpandableTile(
      icon: Icons.restaurant_outlined,
      iconColor: accent.color,
      iconBackgroundColor: accent.dim,
      label: l10n.settingsGoalsNutritionHeader,
      summary: summary,
      children: [
        _ChildGoalTile(
          icon: Icons.local_fire_department_outlined,
          accent: accent,
          label: l10n.goalDailyCalories,
          valueText: intFormat.format(goals.dailyCalories.round()),
          unit: l10n.goalUnitKcal,
          onTap: () => _editDoubleGoal(
            context,
            title: l10n.goalDailyCalories,
            initialValue: goals.dailyCalories,
            unit: l10n.goalUnitKcal,
            fractionDigits: 0,
            onSave: (value) =>
                context.read<GoalsProvider>().setDailyCalories(value),
          ),
        ),
        const SettingsTileDivider(),
        _ChildGoalTile(
          icon: Icons.fitness_center,
          accent: Tokens.protein,
          label: l10n.goalDailyProtein,
          valueText: intFormat.format(goals.dailyProtein.round()),
          unit: l10n.goalUnitG,
          onTap: () => _editDoubleGoal(
            context,
            title: l10n.goalDailyProtein,
            initialValue: goals.dailyProtein,
            unit: l10n.goalUnitG,
            fractionDigits: 0,
            onSave: (value) =>
                context.read<GoalsProvider>().setDailyProtein(value),
          ),
        ),
        const SettingsTileDivider(),
        _ChildGoalTile(
          icon: Icons.water_drop_outlined,
          accent: Tokens.fat,
          label: l10n.goalDailyFat,
          valueText: intFormat.format(goals.dailyFat.round()),
          unit: l10n.goalUnitG,
          onTap: () => _editDoubleGoal(
            context,
            title: l10n.goalDailyFat,
            initialValue: goals.dailyFat,
            unit: l10n.goalUnitG,
            fractionDigits: 0,
            onSave: (value) =>
                context.read<GoalsProvider>().setDailyFat(value),
          ),
        ),
        const SettingsTileDivider(),
        _ChildGoalTile(
          icon: Icons.grain,
          accent: Tokens.carbs,
          label: l10n.goalDailyCarbs,
          valueText: intFormat.format(goals.dailyCarbs.round()),
          unit: l10n.goalUnitG,
          onTap: () => _editDoubleGoal(
            context,
            title: l10n.goalDailyCarbs,
            initialValue: goals.dailyCarbs,
            unit: l10n.goalUnitG,
            fractionDigits: 0,
            onSave: (value) =>
                context.read<GoalsProvider>().setDailyCarbs(value),
          ),
        ),
        const SettingsTileDivider(),
        _ChildGoalTile(
          icon: Icons.spa_outlined,
          accent: accent,
          label: l10n.goalDailyFiber,
          valueText: intFormat.format(goals.dailyFiber.round()),
          unit: l10n.goalUnitG,
          onTap: () => _editDoubleGoal(
            context,
            title: l10n.goalDailyFiber,
            initialValue: goals.dailyFiber,
            unit: l10n.goalUnitG,
            fractionDigits: 0,
            onSave: (value) =>
                context.read<GoalsProvider>().setDailyFiber(value),
          ),
        ),
        const SettingsTileDivider(),
        _MacroKcalBreakdownTile(
          dailyCalories: goals.dailyCalories,
          dailyProtein: goals.dailyProtein,
          dailyFat: goals.dailyFat,
          dailyCarbs: goals.dailyCarbs,
          intFormat: intFormat,
        ),
      ],
    );
  }
}

/// Single-goal sleep section — same flat-tile treatment as Body.
class _SleepGoalTile extends StatelessWidget {
  const _SleepGoalTile({
    required this.goals,
    required this.l10n,
    required this.oneDecimal,
  });

  final GoalsProvider goals;
  final AppLocalizations l10n;
  final NumberFormat oneDecimal;

  @override
  Widget build(BuildContext context) {
    final accent = Tokens.sleep;
    return SettingsTile(
      icon: Icons.bedtime_outlined,
      iconColor: accent.color,
      iconBackgroundColor: accent.dim,
      label: l10n.settingsGoalsSleepHeader,
      subtitle: l10n.goalSleepHours,
      trailing: _EditableValuePill(
        text: '${oneDecimal.format(goals.sleepHours)} ${l10n.goalUnitHours}',
      ),
      onTap: () => _editDoubleGoal(
        context,
        title: l10n.goalSleepHours,
        initialValue: goals.sleepHours,
        unit: l10n.goalUnitHours,
        fractionDigits: 1,
        onSave: (value) =>
            context.read<GoalsProvider>().setSleepHours(value),
      ),
    );
  }
}

/// Child row inside an expandable section. Same shape as `SettingsTile`
/// but accepts a domain accent so the value pill picks up the macro /
/// metric colour, not the global primary. Compact vertical padding so
/// the nutrition section doesn't grow to half a screen when expanded.
class _ChildGoalTile extends StatelessWidget {
  const _ChildGoalTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.valueText,
    required this.unit,
    required this.onTap,
  });

  final IconData icon;
  final Domain accent;
  final String label;
  final String valueText;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: accent.color,
      iconBackgroundColor: accent.dim,
      label: label,
      trailing: _EditableValuePill(
        text: '$valueText $unit',
        accent: accent.color,
      ),
      onTap: onTap,
      compact: true,
    );
  }
}

/// Trailing pill rendered on every goal row. Visually combines the
/// current value with the edit affordance so the tap target reads
/// as "tap this number to change it".
class _EditableValuePill extends StatelessWidget {
  const _EditableValuePill({required this.text, this.accent});

  final String text;

  /// When null falls back to the theme primary; section-coloured
  /// rows pass their domain accent so the pill matches the section.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = accent ?? cs.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: tt.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Icon(Icons.edit_outlined, size: 15, color: cs.onSurfaceVariant),
      ],
    );
  }
}

/// Read-only footer inside the nutrition section showing the kcal
/// total implied by the current macro targets. When that total drifts
/// from the calorie goal beyond a small tolerance band, the trailing
/// caption flags it — common pitfall when bumping one macro without
/// recomputing kcal.
class _MacroKcalBreakdownTile extends StatelessWidget {
  const _MacroKcalBreakdownTile({
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyFat,
    required this.dailyCarbs,
    required this.intFormat,
  });

  final double dailyCalories;
  final double dailyProtein;
  final double dailyFat;
  final double dailyCarbs;
  final NumberFormat intFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final fromMacros = dailyProtein * _kKcalPerGramProtein +
        dailyFat * _kKcalPerGramFat +
        dailyCarbs * _kKcalPerGramCarbs;
    final delta = (fromMacros - dailyCalories).round();
    final isAligned = delta.abs() <= _kMacroKcalToleranceKcal;
    final trailingColor =
        isAligned ? cs.onSurfaceVariant : Tokens.danger;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined,
              size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.settingsGoalsMacroBreakdownLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.settingsGoalsMacroBreakdownMismatch(delta.abs()),
                  style: tt.bodySmall?.copyWith(
                    fontSize: 11,
                    color: trailingColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${intFormat.format(fromMacros.round())} ${l10n.goalUnitKcal}',
            style: tt.labelLarge?.copyWith(
              color: trailingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit-dialog helpers ──────────────────────────────────────────────

Future<void> _editIntGoal(
  BuildContext context, {
  required String title,
  required int initialValue,
  required String unit,
  required Future<void> Function(int) onSave,
}) async {
  final result = await showGoalValueDialog(
    context,
    title: title,
    initialText: initialValue.toString(),
    unit: unit,
    isDecimal: false,
  );
  if (result == null) return;
  final parsed = int.tryParse(result);
  if (parsed != null && parsed > 0) {
    await onSave(parsed);
  }
}

Future<void> _editDoubleGoal(
  BuildContext context, {
  required String title,
  required double initialValue,
  required String unit,
  required int fractionDigits,
  required Future<void> Function(double) onSave,
}) async {
  final result = await showGoalValueDialog(
    context,
    title: title,
    initialText: initialValue.toStringAsFixed(fractionDigits),
    unit: unit,
    isDecimal: fractionDigits > 0,
  );
  if (result == null) return;
  final parsed = double.tryParse(result.replaceAll(',', '.'));
  if (parsed != null && parsed > 0) {
    await onSave(parsed);
  }
}
