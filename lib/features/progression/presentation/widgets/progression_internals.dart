import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/progression_provider.dart';
import '../../domain/progression_models.dart';
import '../quests/quest_daily_selection.dart';
import '../../../../shared/theme/design_tokens.dart';

// ── Shared scaffold ───────────────────────────────────────────────────────────

class ProgressionScaffold extends StatelessWidget {
  const ProgressionScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(bottom: false, child: child),
    );
  }
}

// ── Shared empty / error / loading primitives ─────────────────────────────────

class ProgressionEmptyLine extends StatelessWidget {
  const ProgressionEmptyLine(
      {super.key, required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              color: Tokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressionErrorBanner extends StatelessWidget {
  const ProgressionErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x22FBBF24),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: const Color(0x55FBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.4,
                color: Tokens.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressionLoadingBlock extends StatelessWidget {
  const ProgressionLoadingBlock({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }
}

// ── Shared date formatting ────────────────────────────────────────────────────

String progressionFormatDateTime(DateTime value, String locale) {
  return DateFormat('d MMM · HH:mm', locale).format(value);
}

// ── Shared view-data model ────────────────────────────────────────────────────

class ProgressionViewData {
  const ProgressionViewData({
    required this.profile,
    required this.xpSpan,
    required this.unlocked,
    required this.inProgress,
    required this.allQuests,
    required this.trackedDaysElapsed,
    required this.dailyGoalQuests,
    required this.dailyComboQuests,
    required this.weeklyQuests,
    required this.chapterQuests,
    required this.waitingChapterQuests,
    required this.longTermQuests,
    required this.lockedQuests,
    required this.completedQuests,
    required this.pendingRewards,
    required this.rewardHistory,
    required this.current,
    required this.best,
  });

  factory ProgressionViewData.from(ProgressionProvider progression) {
    final profile = progression.profile;
    final unlocked = progression.achievements
        .where((a) => a.unlocked)
        .toList(growable: false)
      ..sort((a, b) {
        final difficulty = _difficultyRank(b.difficulty)
            .compareTo(_difficultyRank(a.difficulty));
        if (difficulty != 0) return difficulty;
        final at = a.unlockedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.unlockedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final inProgress = progression.achievements
        .where((a) => !a.unlocked)
        .toList(growable: false)
      ..sort((a, b) {
        final difficulty = _difficultyRank(b.difficulty)
            .compareTo(_difficultyRank(a.difficulty));
        if (difficulty != 0) return difficulty;
        return b.progress.compareTo(a.progress);
      });
    final trackedDaysElapsed = _trackedDaysElapsed(progression);
    final dailyGoalQuests = selectDailyGoalQuestsForDate(
      progression.quests,
      DateTime.now(),
    );
    final dailyComboQuests = selectDailyComboQuestsForDate(
      progression.quests,
      DateTime.now(),
    );
    final dailyGoalQuestIds = {
      for (final quest in dailyGoalQuests) quest.id,
    };
    final dailyComboQuestIds = {
      for (final quest in dailyComboQuests) quest.id,
    };
    final weeklyQuests = compactQuestChainRepresentatives(
      progression.quests,
      bucket: ProgressionQuestDisplayBucket.weekly,
    );
    final chapterQuests = compactQuestChainRepresentatives(
      progression.quests,
      bucket: ProgressionQuestDisplayBucket.chapter,
    );
    final waitingChapterQuests = waitingChapterChainRepresentatives(
      progression.quests,
    );
    final longTermQuests = compactQuestChainRepresentatives(
      progression.quests,
      bucket: ProgressionQuestDisplayBucket.longTerm,
    );
    final lockedQuests = [
      for (final quest in progression.lockedQuests)
        if (_isExternallyGatedLockedQuest(
          quest: quest,
          allQuests: progression.quests,
          profile: profile,
          trackedDaysElapsed: trackedDaysElapsed,
        ))
          quest,
    ]..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        final bySortOrder = a.sortOrder.compareTo(b.sortOrder);
        if (bySortOrder != 0) return bySortOrder;
        return a.id.compareTo(b.id);
      });
    final completedQuests = [
      for (final quest in progression.completedQuests)
        if (!dailyGoalQuestIds.contains(quest.id) &&
            !dailyComboQuestIds.contains(quest.id) &&
            !isCurrentPeriodQuest(quest))
          quest,
    ]..sort((a, b) {
        if (a.isRewardClaimable != b.isRewardClaimable) {
          return a.isRewardClaimable ? -1 : 1;
        }
        final at = a.completedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.completedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final pendingRewards = [...progression.pendingRewards]
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final rewardHistory = [...progression.claimedRewards]..sort((a, b) {
        final aTime = a.claimedAt ?? a.unlockedAt;
        final bTime = b.claimedAt ?? b.unlockedAt;
        return bTime.compareTo(aTime);
      });

    return ProgressionViewData(
      profile: profile,
      xpSpan: (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30),
      unlocked: unlocked,
      inProgress: inProgress,
      allQuests: progression.quests,
      trackedDaysElapsed: trackedDaysElapsed,
      dailyGoalQuests: dailyGoalQuests,
      dailyComboQuests: dailyComboQuests,
      weeklyQuests: weeklyQuests,
      chapterQuests: chapterQuests,
      waitingChapterQuests: waitingChapterQuests,
      longTermQuests: longTermQuests,
      lockedQuests: lockedQuests,
      completedQuests: completedQuests,
      pendingRewards: pendingRewards,
      rewardHistory: rewardHistory,
      current: _topStreak(progression, best: false),
      best: _topStreak(progression, best: true),
    );
  }

  final ProgressionProfile profile;
  final int xpSpan;
  final List<ProgressionAchievement> unlocked;
  final List<ProgressionAchievement> inProgress;
  final List<ProgressionQuest> allQuests;
  final int trackedDaysElapsed;
  final List<ProgressionQuest> dailyGoalQuests;
  final List<ProgressionQuest> dailyComboQuests;
  final List<ProgressionQuest> weeklyQuests;
  final List<ProgressionQuest> chapterQuests;
  final List<ProgressionQuest> waitingChapterQuests;
  final List<ProgressionQuest> longTermQuests;
  final List<ProgressionQuest> lockedQuests;
  final List<ProgressionQuest> completedQuests;
  final List<ProgressionRewardGrant> pendingRewards;
  final List<ProgressionRewardGrant> rewardHistory;
  final ProgressionDomainStreak? current;
  final ProgressionDomainStreak? best;
}

class ProgressionDomainStreak {
  const ProgressionDomainStreak({
    required this.domain,
    required this.currentStreak,
    required this.bestStreak,
  });
  final ProgressionDomain domain;
  final int currentStreak;
  final int bestStreak;
}

// ── Private helpers used only by ProgressionViewData.from() ──────────────────

ProgressionDomainStreak? _topStreak(
  ProgressionProvider provider, {
  required bool best,
}) {
  ProgressionDomainStreak? winner;
  for (final domain in ProgressionDomain.values) {
    final streak = provider.streakForDomain(domain);
    final metric = best ? streak.bestStreak : streak.currentStreak;
    if (metric <= 0) continue;
    final candidate = ProgressionDomainStreak(
      domain: domain,
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
    );
    if (winner == null) {
      winner = candidate;
      continue;
    }
    final winning = best ? winner.bestStreak : winner.currentStreak;
    if (metric > winning) winner = candidate;
  }
  return winner;
}

bool _isExternallyGatedLockedQuest({
  required ProgressionQuest quest,
  required List<ProgressionQuest> allQuests,
  required ProgressionProfile profile,
  required int trackedDaysElapsed,
}) {
  if (quest.dailySequenceId != null) return false;

  final lockedByLevel =
      quest.minimumLevel != null && profile.level < quest.minimumLevel!;
  final lockedByTrackedDays = quest.minimumTrackedDays != null &&
      trackedDaysElapsed < quest.minimumTrackedDays!;
  if (!lockedByLevel && !lockedByTrackedDays) return false;

  for (final prerequisiteId in quest.prerequisiteQuestIds) {
    final prerequisite = _questById(allQuests, prerequisiteId);
    if (prerequisite == null || !prerequisite.isCompleted) {
      return false;
    }
  }
  return true;
}

ProgressionQuest? _questById(List<ProgressionQuest> quests, String questId) {
  for (final quest in quests) {
    if (quest.id == questId) return quest;
  }
  return null;
}

int _trackedDaysElapsed(ProgressionProvider provider) {
  DateTime? earliest;

  for (final evaluation in provider.evaluations) {
    final start = progressionDate(evaluation.period.start);
    if (earliest == null || start.isBefore(earliest)) {
      earliest = start;
    }
  }

  for (final grant in provider.rewardGrants) {
    final start = progressionDate(grant.period.start);
    if (earliest == null || start.isBefore(earliest)) {
      earliest = start;
    }
  }

  if (earliest == null) return 0;
  final currentDay = progressionDate(DateTime.now());
  return currentDay.difference(earliest).inDays + 1;
}

int _difficultyRank(ProgressionAchievementDifficulty difficulty) {
  switch (difficulty) {
    case ProgressionAchievementDifficulty.easy:
      return 0;
    case ProgressionAchievementDifficulty.medium:
      return 1;
    case ProgressionAchievementDifficulty.hard:
      return 2;
    case ProgressionAchievementDifficulty.extraHard:
      return 3;
    case ProgressionAchievementDifficulty.mythic:
      return 4;
  }
}
