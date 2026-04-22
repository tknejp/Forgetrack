part of '../calories_screen.dart';

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
                        text: hasValue ? '${calories!.round()}' : '-',
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
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                    : '- / ${goal.round()} g',
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
        (icon: Icons.eco_outlined, label: l10n.macroFiber, value: fiber!),
      );
    }
    if (sugar != null) {
      rows.add(
        (
          icon: Icons.water_drop_outlined,
          label: l10n.macroSugar,
          value: sugar!,
        ),
      );
    }
    if (salt != null) {
      rows.add(
        (
          icon: Icons.science_outlined,
          label: l10n.macroSalt,
          value: salt!,
        ),
      );
    }
    if (saturatedFat != null) {
      rows.add(
        (
          icon: Icons.layers_outlined,
          label: l10n.macroSaturatedFat,
          value: saturatedFat!,
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 44,
      endIndent: 0,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.5),
    );
  }
}
