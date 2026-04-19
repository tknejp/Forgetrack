import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';

class CalorieSummaryCard extends StatefulWidget {
  /// Calories consumed. When null (e.g. week/month mode), consumed and
  /// remaining are shown as "–".
  final double? consumed;
  final double? burned;
  final double goal;

  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  /// When provided, macro tiles show a progress bar vs goal.
  final double? proteinGoal;
  final double? fatGoal;
  final double? carbsGoal;

  /// Optional override for the card title. Defaults to l10n.caloriesTodayTitle.
  final String? title;

  const CalorieSummaryCard({
    super.key,
    this.consumed,
    this.burned,
    this.goal = 2000,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    this.proteinGoal,
    this.fatGoal,
    this.carbsGoal,
    this.title,
  });

  @override
  State<CalorieSummaryCard> createState() => _CalorieSummaryCardState();
}

class _CalorieSummaryCardState extends State<CalorieSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final section = tokens.nutrition;
    final l10n = context.l10n;
    final consumed = widget.consumed;
    final remaining =
        consumed != null ? widget.goal - consumed + (widget.burned ?? 0) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          boxShadow: [
            BoxShadow(
              color: tokens.subtleShadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.05,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: section.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(tokens.tileRadius),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: section.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title ?? l10n.caloriesTodayTitle,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: l10n.caloriesConsumed,
                      value: consumed != null
                          ? '${consumed.round()} kcal'
                          : '–',
                      color: section.accent,
                    ),
                    if (widget.burned != null)
                      _StatColumn(
                        label: l10n.caloriesBurned,
                        value: '${widget.burned!.round()} kcal',
                        color: section.accent,
                      ),
                    _StatColumn(
                      label: l10n.caloriesRemaining,
                      value: remaining != null
                          ? '${remaining.round()} kcal'
                          : '–',
                      color: remaining != null && remaining >= 0
                          ? section.accent
                          : cs.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: consumed != null
                      ? (consumed / widget.goal).clamp(0.0, 1.0)
                      : 0.0,
                  minHeight: 7,
                  color: consumed != null && consumed > widget.goal
                      ? cs.error
                      : section.accent,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Divider(color: cs.outlineVariant),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MacroTile(
                                label: l10n.macroProtein,
                                value: '${widget.protein.round()} g',
                                goal: widget.proteinGoal,
                                current: widget.protein,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroTile(
                                label: l10n.macroFat,
                                value: '${widget.fat.round()} g',
                                goal: widget.fatGoal,
                                current: widget.fat,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MacroTile(
                                label: l10n.macroCarbs,
                                value: '${widget.carbs.round()} g',
                                goal: widget.carbsGoal,
                                current: widget.carbs,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MacroTile(
                                label: l10n.macroFiber,
                                value: '${widget.fiber.round()} g',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;

  /// When provided together, a small progress bar is shown.
  final double? goal;
  final double? current;

  const _MacroTile({
    required this.label,
    required this.value,
    this.goal,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final showProgress = goal != null && goal! > 0 && current != null;
    final progress = showProgress
        ? (current! / goal!).clamp(0.0, 1.0)
        : 0.0;
    final isOver = showProgress && current! > goal!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          if (showProgress) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: isOver ? cs.error : cs.secondary,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ],
        ],
      ),
    );
  }
}
