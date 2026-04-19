import 'package:flutter/material.dart';
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

    return ProfileSettingsCard(
      children: [
        ProfileSettingsTile(
          icon: Icons.directions_walk,
          label: l10n.goalDailySteps,
          trailing: _GoalValue(
            value: goals.dailySteps.toString(),
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
        ProfileSettingsTile(
          icon: Icons.monitor_weight_outlined,
          label: l10n.goalTargetWeight,
          trailing: _GoalValue(
            value: goals.targetWeight.toStringAsFixed(1),
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
        const ProfileTileDivider(),
        ProfileSettingsTile(
          icon: Icons.local_fire_department_outlined,
          label: l10n.goalDailyCalories,
          trailing: _GoalValue(
            value: goals.dailyCalories.round().toString(),
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
        ProfileSettingsTile(
          icon: Icons.fitness_center,
          label: l10n.goalDailyProtein,
          trailing: _GoalValue(
            value: goals.dailyProtein.round().toString(),
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
        ProfileSettingsTile(
          icon: Icons.water_drop_outlined,
          label: l10n.goalDailyFat,
          trailing: _GoalValue(
            value: goals.dailyFat.round().toString(),
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
        ProfileSettingsTile(
          icon: Icons.grain,
          label: l10n.goalDailyCarbs,
          trailing: _GoalValue(
            value: goals.dailyCarbs.round().toString(),
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
        const ProfileTileDivider(),
        ProfileSettingsTile(
          icon: Icons.bedtime_outlined,
          label: l10n.goalSleepHours,
          trailing: _GoalValue(
            value: goals.sleepHours.toStringAsFixed(1),
            unit: l10n.goalUnitHours,
          ),
          onTap: () => _editDoubleGoal(
            context,
            title: l10n.goalSleepHours,
            initialValue: goals.sleepHours,
            unit: l10n.goalUnitHours,
            fractionDigits: 1,
            onSave: (value) => context.read<GoalsProvider>().setSleepHours(value),
          ),
        ),
        const ProfileTileDivider(),
        ProfileSettingsTile(
          icon: Icons.timer_outlined,
          label: l10n.goalWeeklyActivity,
          trailing: _GoalValue(
            value: goals.weeklyActivityMins.toString(),
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
          style: tt.bodyMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.edit_outlined, size: 16, color: cs.onSurfaceVariant),
      ],
    );
  }
}
