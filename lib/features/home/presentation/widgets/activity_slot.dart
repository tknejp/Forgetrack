import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/dashboard_card_assets.dart';
import '../../../../shared/widgets/detail_shortcut_button.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/xp_sparkle_overlay.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/goals_provider.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import 'activity_claims_list.dart';
import 'home_helpers.dart';

class ActivitySlot extends StatelessWidget {
  const ActivitySlot({
    super.key,
    required this.period,
    required this.barKey,
    required this.onOpenActivities,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final VoidCallback onOpenActivities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat('#,##0', locale);
    final fitness = context.watch<FitnessProvider>();
    final goals = context.watch<GoalsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();

    final periodActivities = fitness.activities.where((activity) { // lint-ignore: widget-no-logic — UI period slice for overview chart aggregates
      final start = activity.startTime;
      final day = DateTime(start.year, start.month, start.day);
      return !day.isBefore(period.start) && !day.isAfter(period.end);
    }).toList(growable: false);
    final activeMinutes = periodActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.duration.inMinutes,
    );
    final activityGoal = activityGoalForPeriod(goals, period);
    final activityProgress = activityGoal > 0
        ? (activeMinutes / activityGoal).clamp(0.0, 1.0)
        : 0.0;

    return StatCard(
      icon: '⚡',
      label: l10n.activitiesActiveMins,
      domain: Tokens.activityCard,
      visualAssets:
          DashboardCardAssetResolver.forKind(DashboardCardKind.activity),
      stats: [
        StatStat(
          value: fmt.format(activeMinutes),
          label: l10n.activitiesActiveMins,
          unit: 'min',
        ),
        StatStat(
          value: fmt.format(activityGoal),
          label: l10n.stepsGoal,
          unit: 'min',
        ),
        StatStat(
          value: fmt.format(periodActivities.length),
          label: l10n.activitiesWorkouts,
        ),
      ],
      progress: activityProgress,
      badge: '${(activityProgress * 100).round()}%',
      xpData: xpPillForQuest(
        context: context,
        progression: progression,
        period: period,
        questNodeId: 'daily_activity_today',
        barKey: barKey,
        dayOnly: false,
      ),
      children: [
        if (streakInfoBlockForQuest(
              progression: progression,
              period: period,
              questNodeId: 'daily_activity_today',
            )
            case final block?) ...[
          const SizedBox(height: Tokens.spaceMd),
          block,
          const SizedBox(height: Tokens.spaceXs),
        ],
        if (period.type == PeriodType.day) ...[
          ActivityClaimsList(
            claims: progression.activityClaimsForDate(
              date: period.start,
              activities: periodActivities,
            ),
            header: l10n.homeActivityClaimsHeader,
            onClaim: (record, center) {
              XpSparkleLauncher.launchToKey(
                context,
                from: center,
                targetKey: barKey,
              );
              unawaited(progression.claimActivity(record));
            },
          ),
        ],
        DetailShortcutButton(
          onTap: onOpenActivities,
          domain: Tokens.activityCard,
        ),
      ],
    );
  }
}
