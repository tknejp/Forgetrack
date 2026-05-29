import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../features/health_connect/application/goals_provider.dart';
import '../../../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../../features/nutrition/application/nutrition_goals_source_provider.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/section_head.dart';
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

/// Goals settings — one stacked card per domain, nutrition first.
///
/// Every goal is laid out flat and visible (no expand-to-reveal): the
/// screen is its own page reached from the settings hub, so vertical
/// space is cheap and scannability beats compactness. Each domain card
/// is introduced by a [SectionHead] in the matching domain accent, so
/// the goals screen reads the same way as the home dashboard.
///
/// The nutrition card carries the "goals from Kalorické Tabulky" switch
/// (#98) inline at the top, so the user can flip the source without
/// hopping to the KT settings card. When the switch is on (and KT is
/// connected) the calorie + macro rows below show the KT-sourced values
/// read-only.
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

    final ktConnected = context.watch<KalorickeTabulkyProvider>().isLoggedIn;
    // #98: when nutrition goals are sourced from KT (and KT is connected),
    // the nutrition rows show the KT-sourced values read-only — editing
    // the local board would have no effect while the source is KT.
    final nutritionFromKt =
        context.watch<NutritionGoalsSourceProvider>().usesKt && ktConnected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Nutrition (first) ──
        _GoalGroupHeader(
          label: l10n.settingsGoalsNutritionHeader,
          accent: Tokens.calories.color,
        ),
        SettingsCard(
          children: [
            _KtGoalsSourceSwitch(
              connected: ktConnected,
              usesKt: nutritionFromKt,
            ),
            const SettingsTileDivider(indent: 0),
            if (nutritionFromKt) ...[
              _NutritionKtSourceNote(message: l10n.nutritionGoalsSourceKtHint),
              const SettingsTileDivider(indent: 0),
            ],
            _ChildGoalTile(
              icon: Icons.local_fire_department_outlined,
              accent: Tokens.calories,
              label: l10n.goalDailyCalories,
              valueText: intFormat.format(goals.dailyCalories.round()),
              unit: l10n.goalUnitKcal,
              editable: !nutritionFromKt,
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
              editable: !nutritionFromKt,
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
              editable: !nutritionFromKt,
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
              editable: !nutritionFromKt,
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
              accent: Tokens.calories,
              label: l10n.goalDailyFiber,
              valueText: intFormat.format(goals.dailyFiber.round()),
              unit: l10n.goalUnitG,
              editable: !nutritionFromKt,
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
        ),
        const SizedBox(height: 18),

        // ── Activity ──
        _GoalGroupHeader(
          label: l10n.settingsGoalsActivityHeader,
          accent: Tokens.active.color,
        ),
        SettingsCard(
          children: [
            _ChildGoalTile(
              icon: Icons.directions_walk_rounded,
              accent: Tokens.active,
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
              icon: Icons.directions_run_rounded,
              accent: Tokens.active,
              label: l10n.goalDailyActivity,
              valueText: intFormat.format(goals.dailyActivityMins),
              unit: l10n.goalUnitMins,
              onTap: () => _editIntGoal(
                context,
                title: l10n.goalDailyActivity,
                initialValue: goals.dailyActivityMins,
                unit: l10n.goalUnitMins,
                onSave: (value) =>
                    context.read<GoalsProvider>().setDailyActivityMins(value),
              ),
            ),
            const SettingsTileDivider(),
            _ChildGoalTile(
              icon: Icons.timer_outlined,
              accent: Tokens.active,
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
        ),
        const SizedBox(height: 18),

        // ── Body ──
        _GoalGroupHeader(
          label: l10n.settingsGoalsBodyHeader,
          accent: Tokens.weight.color,
        ),
        SettingsCard(
          children: [
            _ChildGoalTile(
              icon: Icons.monitor_weight_outlined,
              accent: Tokens.weight,
              label: l10n.goalTargetWeight,
              valueText: oneDecimal.format(goals.targetWeight),
              unit: 'kg',
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalTargetWeight,
                initialValue: goals.targetWeight,
                unit: 'kg',
                fractionDigits: 1,
                onSave: (value) =>
                    context.read<GoalsProvider>().setTargetWeight(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Sleep ──
        _GoalGroupHeader(
          label: l10n.settingsGoalsSleepHeader,
          accent: Tokens.sleep.color,
        ),
        SettingsCard(
          children: [
            _ChildGoalTile(
              icon: Icons.bedtime_outlined,
              accent: Tokens.sleep,
              label: l10n.goalSleepHours,
              valueText: oneDecimal.format(goals.sleepHours),
              unit: l10n.goalUnitHours,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalSleepHours,
                initialValue: goals.sleepHours,
                unit: l10n.goalUnitHours,
                fractionDigits: 1,
                onSave: (value) =>
                    context.read<GoalsProvider>().setSleepHours(value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Domain group header above each goals card. Thin wrapper over
/// [SectionHead] with the standard left inset + spacing used between
/// the label and its card.
class _GoalGroupHeader extends StatelessWidget {
  const _GoalGroupHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: Tokens.spaceSm),
      child: SectionHead(label: label, accent: accent),
    );
  }
}

/// The "goals from Kalorické Tabulky" switch (#98), rendered inline at the
/// top of the nutrition card so the source can be flipped without leaving
/// the goals screen. Disabled (with a connect prompt) until KT is linked.
class _KtGoalsSourceSwitch extends StatelessWidget {
  const _KtGoalsSourceSwitch({required this.connected, required this.usesKt});

  final bool connected;
  final bool usesKt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSwitchTile(
      icon: Icons.sync,
      label: l10n.nutritionGoalsSourceSwitchTitle,
      subtitle: connected
          ? l10n.nutritionGoalsSourceSwitchSubtitle
          : l10n.nutritionGoalsSourceConnectKt,
      value: usesKt,
      enabled: connected,
      onChanged: (on) => context.read<NutritionGoalsSourceProvider>().setSource(
            on ? NutritionGoalsSource.kt : NutritionGoalsSource.local,
          ),
    );
  }
}

/// Read-only info row shown atop the nutrition card when goals are
/// sourced from KT (#98) — explains why the rows below can't be edited.
class _NutritionKtSourceNote extends StatelessWidget {
  const _NutritionKtSourceNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
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
    this.editable = true,
  });

  final IconData icon;
  final Domain accent;
  final String label;
  final String valueText;
  final String unit;
  final VoidCallback onTap;

  /// When false the row is non-tappable and the value pill drops its edit
  /// affordance — used when nutrition goals are sourced from KT (#98).
  final bool editable;

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
        editable: editable,
      ),
      onTap: editable ? onTap : null,
      compact: true,
    );
  }
}

/// Trailing pill rendered on every goal row. Visually combines the
/// current value with the edit affordance so the tap target reads
/// as "tap this number to change it".
class _EditableValuePill extends StatelessWidget {
  const _EditableValuePill({required this.text, this.accent, this.editable = true});

  final String text;

  /// When null falls back to the theme primary; section-coloured
  /// rows pass their domain accent so the pill matches the section.
  final Color? accent;

  /// When false the edit pencil is dropped — the value is read-only
  /// (e.g. nutrition goals sourced from KT, #98).
  final bool editable;

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
        if (editable) ...[
          const SizedBox(width: 5),
          Icon(Icons.edit_outlined, size: 15, color: cs.onSurfaceVariant),
        ],
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
