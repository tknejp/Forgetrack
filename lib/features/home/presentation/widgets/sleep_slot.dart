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

class SleepSlot extends StatelessWidget {
  const SleepSlot({
    super.key,
    required this.period,
    required this.barKey,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final sleep = period.type == PeriodType.day
        ? fitness.sleepForDate(period.start)
        : null;
    final avgSleep = period.type != PeriodType.day
        ? fitness.avgSleepForRange(period.start, period.end)
        : null;
    final sleepDuration = sleep?.totalDuration ?? avgSleep;
    final sleepGoalMinutes = goals.sleepHours * 60;
    final sleepRatio = sleepDuration != null && sleepGoalMinutes > 0
        ? sleepDuration.inMinutes / sleepGoalMinutes
        : 0.0;
    final sleepProgress = sleepRatio.clamp(0.0, 1.0);
    final sleepPct = (sleepRatio * 100).round();

    return StatCard(
      icon: '🌙',
      label: l10n.sleepTitle,
      subtitle: homeCardAverageSubtitle(l10n, period),
      domain: Tokens.sleep,
      visualAssets:
          DashboardCardAssetResolver.forKind(DashboardCardKind.sleep),
      stats: [
        StatStat(value: fmtSleep(sleepDuration), label: l10n.sleepDuration),
        StatStat(
          value: sleep?.sleepStart != null
              ? DateFormat('HH:mm', locale).format(sleep!.sleepStart)
              : '--',
          label: l10n.sleepFellAsleep,
        ),
        StatStat(
          value: sleep?.wakeTime != null
              ? DateFormat('HH:mm', locale).format(sleep!.wakeTime)
              : '--',
          label: l10n.sleepWokeUp,
        ),
      ],
      progress: sleepProgress,
      badge: sleepDuration != null ? '$sleepPct%' : null,
      xpData: xpPillForQuest(
        context: context,
        progression: progression,
        period: period,
        questNodeId: 'daily_sleep_today',
        barKey: barKey,
      ),
      footer: HcCardStatusFooter.isActive(fitness)
          ? HcCardStatusFooter(fitness: fitness)
          : null,
      children: [
        if (streakInfoBlockForQuest(
              progression: progression,
              period: period,
              questNodeId: 'daily_sleep_today',
            )
            case final block?) ...[
          const SizedBox(height: Tokens.spaceMd),
          block,
          const SizedBox(height: Tokens.spaceXs),
        ],
        DetailShortcutButton(onTap: onOpenSleep, domain: Tokens.sleep),
      ],
    );
  }
}
