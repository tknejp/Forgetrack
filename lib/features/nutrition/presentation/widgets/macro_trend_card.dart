import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/trend_chart.dart';
import 'macro_detail_row.dart';
import 'trend_chart_helper.dart';

/// Macro axis used by [MacroTrendCard] and the nutrition screen's selector
/// state. Public so the screen can keep the selected axis in its `State`.
enum MacroAxis { protein, fat, carbs }

/// Wraps a [TrendChart] with a P/F/C toggle row above the chart so the same
/// card slot doubles as three "macro-axis" trends. Tap-to-bar maps back to a
/// date via [onBarTap]; horizontal scrolling is enabled so month-mode
/// (~30 bars) stays readable.
class MacroTrendCard extends StatelessWidget {
  const MacroTrendCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.axis,
    required this.domain,
    required this.macroLabel,
    required this.avg,
    required this.goal,
    required this.bars,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.sugar,
    required this.saturatedFat,
    required this.salt,
    required this.proteinGoal,
    required this.fatGoal,
    required this.carbsGoal,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onAxisChange,
    required this.onBarTap,
  });

  final String title;
  final String subtitle;
  final MacroAxis axis;
  final Domain domain;
  final String macroLabel;
  final double avg;
  final double goal;
  final List<ChartBar> bars;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double saturatedFat;
  final double salt;
  final double proteinGoal;
  final double fatGoal;
  final double carbsGoal;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<MacroAxis> onAxisChange;
  final ValueChanged<int> onBarTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final safeAvg = avg.isFinite ? avg : 0.0;
    final safeGoal = goal.isFinite ? goal : 0.0;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: domain.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleExpanded,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: domain.dim,
                      borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                      border: Border.all(
                        color: domain.color.withValues(alpha: 0.27),
                      ),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      size: 18,
                      color: domain.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeBody,
                            fontWeight: FontWeight.w700,
                            color: ft.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$macroLabel Â· $subtitle',
                          style: TextStyle(
                            fontSize: Tokens.fontSizeCaption,
                            fontWeight: FontWeight.w500,
                            color: ft.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ExpandChevron(expanded: expanded),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              child: expanded
                  ? RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Tokens.spaceMd),
                          Row(
                            children: [
                              for (final option in MacroAxis.values) ...[
                                Expanded(
                                  child: _MacroAxisChip(
                                    axis: option,
                                    selected: option == axis,
                                    onTap: () => onAxisChange(option),
                                  ),
                                ),
                                if (option != MacroAxis.values.last)
                                  const SizedBox(width: 6),
                              ],
                            ],
                          ),
                          const SizedBox(height: Tokens.spaceMd),
                          TrendChartHelper(
                            bars: bars,
                            domain: domain,
                            referenceValue: safeGoal > 0 ? safeGoal : null,
                            onBarTap: onBarTap,
                            scrollableMinBarWidth: 34,
                          ),
                          if (safeGoal > 0) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _MacroLegend(
                                  label: l10n.weightAverage,
                                  value: '${safeAvg.round()} g',
                                  color: domain.color,
                                ),
                                const SizedBox(width: 16),
                                _MacroLegend(
                                  label: l10n.weightGoal,
                                  value: '${safeGoal.round()} g',
                                  color: ft.onSurfaceMuted,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: Tokens.spaceMd),
                          Divider(color: ft.divider, height: 1),
                          const SizedBox(height: Tokens.spaceXs),
                          MacroDetailRow(
                            label: l10n.macroProtein,
                            value: protein,
                            goal: proteinGoal,
                            unit: 'g',
                            color: Tokens.protein.color,
                          ),
                          MacroDetailRow(
                            label: l10n.macroFat,
                            value: fat,
                            goal: fatGoal,
                            unit: 'g',
                            color: Tokens.fat.color,
                          ),
                          MacroDetailRow(
                            label: l10n.macroCarbs,
                            value: carbs,
                            goal: carbsGoal,
                            unit: 'g',
                            color: Tokens.carbs.color,
                          ),
                          MacroDetailRow(
                            label: l10n.macroFiber,
                            value: fiber,
                            goal: 0,
                            unit: 'g',
                            color: ft.onSurfaceMuted,
                          ),
                          MacroDetailRow(
                            label: l10n.macroSugar,
                            value: sugar,
                            goal: 0,
                            unit: 'g',
                            color: ft.onSurfaceMuted,
                          ),
                          MacroDetailRow(
                            label: l10n.macroSaturatedFat,
                            value: saturatedFat,
                            goal: 0,
                            unit: 'g',
                            color: ft.onSurfaceMuted,
                          ),
                          MacroDetailRow(
                            label: l10n.macroSalt,
                            value: salt,
                            goal: 0,
                            unit: 'g',
                            color: ft.onSurfaceMuted,
                            isLast: true,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroAxisChip extends StatelessWidget {
  const _MacroAxisChip({
    required this.axis,
    required this.selected,
    required this.onTap,
  });

  final MacroAxis axis;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = switch (axis) {
      MacroAxis.protein => Tokens.protein,
      MacroAxis.fat => Tokens.fat,
      MacroAxis.carbs => Tokens.carbs,
    };
    final label = switch (axis) {
      MacroAxis.protein => l10n.macroProtein,
      MacroAxis.fat => l10n.macroFat,
      MacroAxis.carbs => l10n.macroCarbs,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? domain.dim : ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? domain.color.withValues(alpha: 0.55) : ft.cardBorder,
          ),
          boxShadow: selected
              ? [BoxShadow(color: domain.glow, blurRadius: Tokens.glowSm)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? domain.color : ft.onSurfaceMuted,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  const _MacroLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w600,
            color: ft.onSurfaceMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: ft.onSurface,
          ),
        ),
      ],
    );
  }
}
