part of '../weight_card.dart';

class _WeightCardHeader extends StatelessWidget {
  final bool expanded;

  const _WeightCardHeader({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final section = tokens.body;
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: section.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(tokens.tileRadius),
          ),
          child: Icon(Icons.monitor_weight, color: section.accent),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.weightTitle,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WeightCardStatsRow extends StatelessWidget {
  final String mainLabel;
  final double mainValue;
  final String trendLabel;
  final double? trendValue;
  final double goalWeight;
  final Color trendColor;
  final String Function(double) fmtW;
  final String Function(double) fmtSigned;

  const _WeightCardStatsRow({
    required this.mainLabel,
    required this.mainValue,
    required this.trendLabel,
    required this.trendValue,
    required this.goalWeight,
    required this.trendColor,
    required this.fmtW,
    required this.fmtSigned,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.body;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatColumn(
          label: mainLabel,
          value: '${fmtW(mainValue)} kg',
          color: section.accent,
        ),
        _StatColumn(
          label: trendLabel,
          value: trendValue != null ? '${fmtSigned(trendValue!)} kg' : '–',
          color: trendColor,
        ),
        _StatColumn(
          label: context.l10n.weightGoal,
          value: '${fmtW(goalWeight)} kg',
          color: cs.onSurface,
        ),
      ],
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
