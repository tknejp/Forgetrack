import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../models/selected_period.dart';
import '../../../models/weight_card_data.dart';
import '../../../theme/app_theme.dart';

part 'weight_card/weight_card_chart.dart';
part 'weight_card/weight_card_detail.dart';
part 'weight_card/weight_card_header.dart';
part 'weight_card/weight_card_no_data_card.dart';

class WeightCard extends StatefulWidget {
  final WeightCardData data;

  const WeightCard({super.key, required this.data});

  @override
  State<WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<WeightCard> {
  bool _expanded = false;

  String _fmtW(double v) => v.toStringAsFixed(1);

  String _fmtSigned(double v) =>
      v >= 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    if (!d.hasData) {
      return _NoWeightDataCard(goalWeight: d.goalWeight);
    }

    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final progress = (d.goalWeight / d.mainValue!).clamp(0.0, 1.0);

    final mainLabel = d.periodType == PeriodType.day
        ? l10n.weightMainLabelDay
        : l10n.weightAverage;

    final trendLabel = switch (d.periodType) {
      PeriodType.day => l10n.weightVsPrevMeasure,
      PeriodType.week => l10n.weightVsPrevWeek,
      PeriodType.month || PeriodType.custom => l10n.weightVsPrevMonth,
    };

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
                _WeightCardHeader(expanded: _expanded),
                const SizedBox(height: 12),
                _WeightCardStatsRow(
                  mainLabel: mainLabel,
                  mainValue: d.mainValue!,
                  trendLabel: trendLabel,
                  trendValue: d.trendValue,
                  goalWeight: d.goalWeight,
                  trendColor: _trendColor(context, d.trendValue),
                  fmtW: _fmtW,
                  fmtSigned: _fmtSigned,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  color: tokens.body.accent,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                _WeightCardExpandedSection(
                  expanded: _expanded,
                  data: d,
                  locale: locale,
                  fmtW: _fmtW,
                  fmtSigned: _fmtSigned,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _trendColor(BuildContext context, double? trend) {
    if (trend == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.body;
    final goalingDown = widget.data.mainValue! >= widget.data.goalWeight;
    final isGood = goalingDown ? trend <= 0 : trend >= 0;
    return isGood ? section.accent : cs.error;
  }
}
