part of '../weight_card.dart';

class _WeightCardExpandedSection extends StatelessWidget {
  final bool expanded;
  final WeightCardData data;
  final String locale;
  final String Function(double) fmtW;

  const _WeightCardExpandedSection({
    required this.expanded,
    required this.data,
    required this.locale,
    required this.fmtW,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 220),
      crossFadeState:
          expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 12),
            _WeightCardDetailContent(
              data: data,
              locale: locale,
              fmtW: fmtW,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightCardDetailContent extends StatelessWidget {
  final WeightCardData data;
  final String locale;
  final String Function(double) fmtW;

  const _WeightCardDetailContent({
    required this.data,
    required this.locale,
    required this.fmtW,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.periodType == PeriodType.day) ...[
          if (data.bodyFatPercent != null) ...[
            _BodyCompositionTiles(
              weight: data.mainValue!,
              bodyFat: data.bodyFatPercent!,
              fmtW: fmtW,
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (data.periodType != PeriodType.day &&
            (data.periodMin != null || data.periodMax != null)) ...[
          Row(
            children: [
              if (data.periodMin != null)
                Expanded(
                  child: _DetailTile(
                    label: l10n.weightMin,
                    value: '${fmtW(data.periodMin!)} kg',
                  ),
                ),
              if (data.periodMin != null && data.periodMax != null)
                const SizedBox(width: 8),
              if (data.periodMax != null)
                Expanded(
                  child: _DetailTile(
                    label: l10n.weightMax,
                    value: '${fmtW(data.periodMax!)} kg',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (data.chartPoints.length >= 2) ...[
          SizedBox(
            height: 96,
            child: _WeightChart(
              points: data.chartPoints,
              mode: data.chartMode,
              locale: locale,
            ),
          ),
        ],
      ],
    );
  }
}

class _BodyCompositionTiles extends StatelessWidget {
  final double weight;
  final double bodyFat;
  final String Function(double) fmtW;

  const _BodyCompositionTiles({
    required this.weight,
    required this.bodyFat,
    required this.fmtW,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final leanMass = weight * (1 - bodyFat / 100);
    final fatMass = weight * (bodyFat / 100);

    return Row(
      children: [
        Expanded(
          child: _DetailTile(
            label: l10n.weightBodyFat,
            value: '${bodyFat.toStringAsFixed(1)} %',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailTile(
            label: l10n.weightLeanMass,
            value: '${fmtW(leanMass)} kg',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailTile(
            label: l10n.weightFatMass,
            value: '${fmtW(fatMass)} kg',
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
