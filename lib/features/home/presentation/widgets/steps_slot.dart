import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/dashboard_card_assets.dart';
import '../../../../shared/widgets/detail_shortcut_button.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/goals_provider.dart';
import '../../../health_connect/presentation/widgets/hc_status_indicators.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import 'home_helpers.dart';

class StepsSlot extends StatelessWidget {
  const StepsSlot({
    super.key,
    required this.period,
    required this.barKey,
    required this.onOpenSteps,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenSteps;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final steps = period.type == PeriodType.day
        ? fitness.stepsForDate(period.start)
        : fitness.stepsAvgForRange(period.start, period.end);
    final stepsGoal = goals.dailySteps;
    final stepsRatio = stepsGoal > 0 ? steps / stepsGoal : 0.0;
    final stepsProgress = stepsRatio.clamp(0.0, 1.0);
    final stepsPct = (stepsRatio * 100).round();
    final stepsLeft = (stepsGoal - steps).clamp(0, stepsGoal);

    return StatCard(
          icon: '🥾',
          label: l10n.stepsTitle,
          subtitle: homeCardAverageSubtitle(l10n, period),
          domain: Tokens.steps,
          visualAssets:
              DashboardCardAssetResolver.forKind(DashboardCardKind.steps),
          stats: [
            StatStat(
              value: fmt.format(steps),
              label: l10n.stepsTitle,
              goal: stepsGoal > 0 ? fmt.format(stepsGoal) : null,
            ),
            StatStat(value: fmt.format(stepsGoal), label: l10n.stepsGoal),
            StatStat(
              value: period.type == PeriodType.day
                  ? fmt.format(stepsLeft)
                  : '--',
              label:
                  period.type == PeriodType.day ? l10n.stepsRemaining : '',
            ),
          ],
          progress: stepsProgress,
          badge: '$stepsPct%',
          xpData: xpPillForQuest(
            context: context,
            progression: progression,
            period: period,
            questNodeId: 'daily_steps_today',
            barKey: barKey,
          ),
          footer: HcCardStatusFooter.isActive(fitness)
              ? HcCardStatusFooter(fitness: fitness)
              : null,
          children: [
            if (streakInfoBlockForQuest(
                  progression: progression,
                  period: period,
                  questNodeId: 'daily_steps_today',
                )
                case final block?) ...[
              const SizedBox(height: Tokens.spaceMd),
              block,
              const SizedBox(height: Tokens.spaceXs),
            ],
            DetailShortcutButton(onTap: onOpenSteps, domain: Tokens.steps),
          ],
        );
  }
}
