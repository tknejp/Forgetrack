import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/dashboard_card_assets.dart';
import '../../../../shared/widgets/stat_card.dart';

class TodayHeaderCard extends StatelessWidget {
  const TodayHeaderCard({
    super.key,
    required this.kcal,
    required this.kcalGoal,
    required this.kcalDiff,
    required this.progress,
    required this.progressPct,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final double kcal;
  final double kcalGoal;
  final double kcalDiff;
  final double progress;
  final int progressPct;
  final double protein;
  final double fat;
  final double carbs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RepaintBoundary(
      child: StatCard(
        icon: '🔥',
        label: '${l10n.caloriesTodayTitle} · ${l10n.headerToday}',
        domain: Tokens.calories,
        visualAssets: DashboardCardAssetResolver.forKind(
          DashboardCardKind.nutrition,
        ),
        initiallyExpanded: true,
        collapsible: false,
        stats: [
          StatStat(
            value: kcal.round().toString(),
            label: l10n.caloriesConsumed,
            unit: 'kcal',
          ),
          StatStat(
            value: kcalGoal.round().toString(),
            label: l10n.weightGoal,
            unit: 'kcal',
          ),
          StatStat(
            value: '${kcalDiff >= 0 ? '+' : ''}${kcalDiff.round()}',
            label: kcalDiff >= 0 ? l10n.caloriesBurned : l10n.caloriesRemaining,
            unit: 'kcal',
          ),
        ],
        progress: progress,
        badge: '$progressPct%',
        children: [
          const SizedBox(height: 10),
          const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
          const SizedBox(height: Tokens.spaceSm),
          Row(
            children: [
              Expanded(
                child: _MacroChip(
                  label: l10n.macroProtein,
                  value: protein,
                  color: Tokens.protein.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: l10n.macroFat,
                  value: fat,
                  color: Tokens.fat.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroChip(
                  label: l10n.macroCarbs,
                  value: carbs,
                  color: Tokens.carbs.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w600,
            color: ft.onSurfaceMuted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: value.round().toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0,
            ),
            children: [
              TextSpan(
                text: ' g',
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
