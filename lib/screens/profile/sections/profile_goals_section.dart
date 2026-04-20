import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/goals_provider.dart';
import '../dialogs/profile_dialogs.dart';
import '../widgets/profile_settings_widgets.dart';

class ProfileGoalsSection extends StatelessWidget {
  const ProfileGoalsSection({super.key});

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

    return ProfileSettingsCard(
      children: [
        ProfileExpandableTile(
          icon: Icons.directions_walk,
          label: l10n.screenActivities,
          summary:
              '${intFormat.format(goals.dailySteps)} ${l10n.goalUnitSteps} / '
              '${intFormat.format(goals.weeklyActivityMins)} ${l10n.goalUnitMins}',
          initiallyExpanded: true,
          children: [
            _GoalTile(
              icon: Icons.directions_walk,
              label: l10n.goalDailySteps,
              value: _GoalValue(
                value: intFormat.format(goals.dailySteps),
                unit: l10n.goalUnitSteps,
              ),
              onTap: () => _editIntGoal(
                context,
                title: l10n.goalDailySteps,
                initialValue: goals.dailySteps,
                unit: l10n.goalUnitSteps,
                onSave: (value) =>
                    context.read<GoalsProvider>().setDailySteps(value),
              ),
            ),
            const ProfileTileDivider(),
            _GoalTile(
              icon: Icons.timer_outlined,
              label: l10n.goalWeeklyActivity,
              value: _GoalValue(
                value: intFormat.format(goals.weeklyActivityMins),
                unit: l10n.goalUnitMins,
              ),
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
        const ProfileTileDivider(indent: 0),
        ProfileExpandableTile(
          icon: Icons.monitor_weight_outlined,
          label: l10n.screenBody,
          summary: '${oneDecimal.format(goals.targetWeight)} kg',
          children: [
            _GoalTile(
              icon: Icons.monitor_weight_outlined,
              label: l10n.goalTargetWeight,
              value: _GoalValue(
                value: oneDecimal.format(goals.targetWeight),
                unit: 'kg',
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
            ),
          ],
        ),
        const ProfileTileDivider(indent: 0),
        ProfileExpandableTile(
          icon: Icons.restaurant_outlined,
          label: l10n.screenNutrition,
          summary:
              '${intFormat.format(goals.dailyCalories.round())} ${l10n.goalUnitKcal} / '
              '${intFormat.format(goals.dailyProtein.round())}/'
              '${intFormat.format(goals.dailyFat.round())}/'
              '${intFormat.format(goals.dailyCarbs.round())} ${l10n.goalUnitG}',
          children: [
            _GoalTile(
              icon: Icons.local_fire_department_outlined,
              label: l10n.goalDailyCalories,
              value: _GoalValue(
                value: intFormat.format(goals.dailyCalories.round()),
                unit: l10n.goalUnitKcal,
              ),
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
            const ProfileTileDivider(),
            _GoalTile(
              icon: Icons.fitness_center,
              label: l10n.goalDailyProtein,
              value: _GoalValue(
                value: intFormat.format(goals.dailyProtein.round()),
                unit: l10n.goalUnitG,
              ),
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
            const ProfileTileDivider(),
            _GoalTile(
              icon: Icons.water_drop_outlined,
              label: l10n.goalDailyFat,
              value: _GoalValue(
                value: intFormat.format(goals.dailyFat.round()),
                unit: l10n.goalUnitG,
              ),
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
            const ProfileTileDivider(),
            _GoalTile(
              icon: Icons.grain,
              label: l10n.goalDailyCarbs,
              value: _GoalValue(
                value: intFormat.format(goals.dailyCarbs.round()),
                unit: l10n.goalUnitG,
              ),
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
          ],
        ),
        const ProfileTileDivider(indent: 0),
        ProfileExpandableTile(
          icon: Icons.bedtime_outlined,
          label: l10n.sleepTitle,
          summary:
              '${oneDecimal.format(goals.sleepHours)} ${l10n.goalUnitHours}',
          children: [
            _GoalTile(
              icon: Icons.bedtime_outlined,
              label: l10n.goalSleepHours,
              value: _GoalValue(
                value: oneDecimal.format(goals.sleepHours),
                unit: l10n.goalUnitHours,
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
            ),
          ],
        ),
      ],
    );
  }

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
    if (result == null) {
      return;
    }

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
    if (result == null) {
      return;
    }

    final parsed = double.tryParse(result.replaceAll(',', '.'));
    if (parsed != null && parsed > 0) {
      await onSave(parsed);
    }
  }
}

class _GoalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback onTap;

  const _GoalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsTile(
      icon: icon,
      label: label,
      trailing: value,
      onTap: onTap,
      compact: true,
    );
  }
}

class _GoalValue extends StatelessWidget {
  final String value;
  final String unit;

  const _GoalValue({
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value $unit',
          style: tt.labelLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        Icon(Icons.edit_outlined, size: 15, color: cs.onSurfaceVariant),
      ],
    );
  }
}
