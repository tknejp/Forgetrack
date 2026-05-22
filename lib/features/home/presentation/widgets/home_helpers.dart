import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/selected_period.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../../../shared/widgets/xp_sparkle_overlay.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/goals_provider.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/progression_domain_chrome.dart';
import '../../../progression_engine/presentation/widgets/quest_streak_chip.dart';
import '../../../progression_engine/presentation/widgets/quest_streak_info_block.dart';

/// Layout-decision values derived from `FitnessProvider` +
/// `KalorickeTabulkyProvider`. Drives which card slots collapse into
/// prompts vs. render their real content. Using a Dart 3 record gives
/// structural equality for free, so `Selector2` skips rebuilding when
/// the underlying state hasn't changed in a layout-relevant way.
typedef CardVisibility = ({
  bool showHcPrompt,
  bool showHcOfflineBanner,
  bool hcUnavailable,
  bool showKtPrompt,
  bool showKtOfflineBanner,
  bool ktLoggedIn,
  bool ktSyncError,
  bool hasCachedHcData,
  bool hasCachedKtData,
});

/// Per-card XP pill data for [questNodeId], a V2 [QuestNode] id.
///
/// Daily quests are inherently `TodayScope` in V2, so the pill only
/// makes sense when the user is looking at the current period —
/// historic days never have claim state to surface.
XpClaimPillData? xpPillForQuest({
  required BuildContext context,
  required ProgressionEngineProvider progression,
  required SelectedPeriod period,
  required String questNodeId,
  required GlobalKey barKey,
  bool dayOnly = true,
}) {
  if (dayOnly && period.type != PeriodType.day) return null;
  if (!period.isCurrentPeriod) return null;

  final quest = findDailyQuest(progression, questNodeId);
  if (quest == null) return null;
  final preview = quest.previewXp;
  final companionBonus = progression.projectedCompanionBuffBonusFor(quest.node);
  final emblemBonus = progression.projectedEmblemBuffBonusFor(quest.node);

  if (quest.isCompleted) {
    return XpClaimPillData.claimed(
      preview,
      companionBonus: companionBonus,
      emblemBonus: emblemBonus,
    );
  }
  if (quest.isAvailableForClaim) {
    final claimId = quest.nodeId;
    return XpClaimPillData.claimable(
      preview,
      companionBonus: companionBonus,
      emblemBonus: emblemBonus,
      onTap: (center) {
        XpSparkleLauncher.launchToKey(
          context,
          from: center,
          targetKey: barKey,
        );
        unawaited(progression.claimNode(nodeId: claimId));
      },
    );
  }
  if (preview > 0) {
    return XpClaimPillData.locked(
      preview,
      companionBonus: companionBonus,
      emblemBonus: emblemBonus,
    );
  }
  return null;
}

/// Resolves the pedagogic streak info block for a main-five home card.
QuestStreakInfoBlock? streakInfoBlockForQuest({
  required ProgressionEngineProvider progression,
  required SelectedPeriod period,
  required String questNodeId,
}) {
  if (!period.isCurrentPeriod) return null;
  final quest = findDailyQuest(progression, questNodeId);
  if (quest == null) return null;
  final domain = streakDomainOfRewards(quest.node.rewards);
  if (domain == null) return null;
  final summary = progression.streakForDomain(domain);
  return QuestStreakInfoBlock(
    currentStreak: summary.currentStreak,
    bestStreak: summary.bestStreak,
    accent: domain.color,
    buff: progression.equippedCompanionBuff,
    resolvedPercent: progression.projectedStreakBuffPercentFor(quest.node),
  );
}

EngineQuestProgress? findDailyQuest(
  ProgressionEngineProvider progression,
  String questNodeId,
) {
  for (final q in progression.allDailyQuests) {
    if (q.nodeId == questNodeId) return q;
  }
  return null;
}

double? weightForPeriod(FitnessProvider fitness, SelectedPeriod period) {
  switch (period.type) {
    case PeriodType.day:
      return fitness.weightForDate(period.start)?.weight;
    case PeriodType.week:
      return fitness.weekAvgWeight(period.start);
    case PeriodType.month:
      return fitness.monthAvgWeight(period.referenceDate);
    case PeriodType.custom:
      return fitness.monthAvgWeight(period.referenceDate);
  }
}

double? previousWeightForPeriod(
    FitnessProvider fitness, SelectedPeriod period) {
  switch (period.type) {
    case PeriodType.day:
      return fitness.previousWeightBefore(period.start);
    case PeriodType.week:
      return fitness.weekAvgWeight(
        period.start.subtract(const Duration(days: 7)),
      );
    case PeriodType.month:
      final ref = period.referenceDate;
      return fitness.monthAvgWeight(DateTime(ref.year, ref.month - 1, 1));
    case PeriodType.custom:
      return null;
  }
}

bool hasCachedHcData(FitnessProvider fitness) {
  return fitness.stepsHistory.isNotEmpty ||
      fitness.weightHistory.isNotEmpty ||
      fitness.sleepHistory.isNotEmpty ||
      fitness.activities.isNotEmpty;
}

String fmtSleep(Duration? duration) {
  if (duration == null) return '--';
  final hours = duration.inHours;
  final minutes = duration.inMinutes - hours * 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

int activityGoalForPeriod(GoalsProvider goals, SelectedPeriod period) {
  final weekly = goals.weeklyActivityMins;

  switch (period.type) {
    case PeriodType.day:
      return goals.dailyActivityMins;
    case PeriodType.week:
      if (weekly <= 0) return 0;
      return weekly;
    case PeriodType.month:
    case PeriodType.custom:
      if (weekly <= 0) return 0;
      return weekly * 4;
  }
}
