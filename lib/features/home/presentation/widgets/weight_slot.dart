import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/dashboard_card_assets.dart';
import '../../../../shared/widgets/detail_shortcut_button.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/presentation/widgets/hc_status_indicators.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import 'home_helpers.dart';

class WeightSlot extends StatelessWidget {
  const WeightSlot({
    super.key,
    required this.period,
    required this.barKey,
    required this.onOpenBody,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenBody;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fitness = context.watch<FitnessProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final weight = weightForPeriod(fitness, period);
    final prevWeight = previousWeightForPeriod(fitness, period);
    final weightChange =
        (weight != null && prevWeight != null) ? weight - prevWeight : null;

    return StatCard(
      icon: '⚖',
      label: l10n.weightTitle,
      subtitle: homeCardAverageSubtitle(l10n, period),
      domain: Tokens.weight,
      visualAssets:
          DashboardCardAssetResolver.forKind(DashboardCardKind.weight),
      stats: [
        StatStat(
          value: weight?.toStringAsFixed(1) ?? '--',
          label: period.type == PeriodType.day
              ? l10n.bodyCurrentWeight
              : l10n.weightAverage,
          unit: 'kg',
        ),
        StatStat(
          value: weightChange != null
              ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}'
              : '--',
          label: period.type == PeriodType.week
              ? l10n.weightVsPrevWeek
              : period.type == PeriodType.month
                  ? l10n.weightVsPrevMonth
                  : l10n.weightVsPrevMeasure,
          unit: 'kg',
        ),
      ],
      showProgress: false,
      xpData: xpPillForQuest(
        context: context,
        progression: progression,
        period: period,
        questNodeId: 'daily_weight_log_today',
        barKey: barKey,
        dayOnly: false,
      ),
      footer: HcCardStatusFooter.isActive(fitness)
          ? HcCardStatusFooter(fitness: fitness)
          : null,
      children: [
        if (streakInfoBlockForQuest(
              progression: progression,
              period: period,
              questNodeId: 'daily_weight_log_today',
            )
            case final block?) ...[
          const SizedBox(height: Tokens.spaceMd),
          block,
          const SizedBox(height: Tokens.spaceXs),
        ],
        DetailShortcutButton(onTap: onOpenBody, domain: Tokens.weight),
      ],
    );
  }
}
