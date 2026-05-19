import 'package:forgetrack/domain/journal/journal.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';

import '../../cosmetics/domain/companion_buff.dart';
import '../domain/evaluator/reward_grant_planner.dart';
import '../domain/models/engine_evaluation_context.dart';
import '../domain/policy/level_policy.dart';

/// Daily soft-cap on the bonus XP a companion buff may contribute,
/// expressed as a fraction of total XP granted today (level-scaled
/// base + companion bonus, summed). At 0.25 a player can't gain more
/// than 25 % of their daily XP from the equipped companion — keeps
/// any one buff (incl. allXp endgame buffs) from dominating the loop.
const double _kDailyBuffShareCap = 0.25;

/// Builds [RewardGrantEvent]s from planned grants. XP rewards are
/// scaled at append time using the running level — the same logic
/// the legacy engine applies, lifted here so V2 stays compatible
/// with the existing level / multiplier curve.
///
/// Additionally applies the equipped companion's [CompanionBuff]
/// multiplicatively to base + bonus XP per the matching
/// [RewardSourceKind]. The buff bonus is gated by
/// `player.rpgModeEnabled` and respects a 25 % daily share cap so
/// the player never gains more than 1/4 of their daily XP from the
/// buff alone.
class RewardGrantService {
  const RewardGrantService({
    this.levelPolicy = const ProgressionLevelPolicy(),
  });

  final ProgressionLevelPolicy levelPolicy;

  /// Builds reward events for one planning batch. The caller passes
  /// `runningClaimedXp` so XP scaling reflects already-claimed XP
  /// from earlier nodes in the same run (and from prior runs).
  ///
  /// [context] supplies the companion buff (if any), the streak +
  /// chain inputs the dynamic buff rules consume, and the journal
  /// the daily soft-cap accountant reads to seed today's running
  /// totals. May be null when called from a code path that does not
  /// have a context yet — buffs are simply skipped in that case.
  ///
  /// Returns the events plus the new running-XP total.
  ({List<RewardGrantEvent> events, int runningClaimedXp}) build({
    required List<PlannedRewardGrant> planned,
    required int runningClaimedXp,
    required DateTime timestamp,
    EngineEvaluationContext? context,
  }) {
    final events = <RewardGrantEvent>[];
    var running = runningClaimedXp;

    // Seed today's totals from prior journal events so the cap
    // accountant sees XP banked earlier in the same calendar day
    // before this build call.
    final accountant = _DailyBuffAccountant.seed(
      journal: context?.journal,
      anchor: timestamp,
    );

    for (final p in planned) {
      final event = _buildOne(
        p,
        runningXp: running,
        timestamp: timestamp,
        context: context,
        accountant: accountant,
      );
      events.add(event);
      final eventXp = event.xpAmount ?? 0;
      if (eventXp > 0) {
        accountant.note(
          totalXp: eventXp,
          bonusXp: event.companionBuffBonusXp ?? 0,
        );
        running += eventXp;
      }
    }

    return (events: events, runningClaimedXp: running);
  }

  RewardGrantEvent _buildOne(
    PlannedRewardGrant planned, {
    required int runningXp,
    required DateTime timestamp,
    required EngineEvaluationContext? context,
    required _DailyBuffAccountant accountant,
  }) {
    final reward = planned.reward;
    return switch (reward) {
      XpReward(:final amount, :final sourceKind) => _buildXpEvent(
          planned: planned,
          runningXp: runningXp,
          timestamp: timestamp,
          baseAmount: amount,
          sourceKind: sourceKind,
          context: context,
          accountant: accountant,
        ),
      BonusXpReward(:final amount, :final sourceKind) => _buildXpEvent(
          planned: planned,
          runningXp: runningXp,
          timestamp: timestamp,
          baseAmount: amount,
          sourceKind: sourceKind,
          context: context,
          accountant: accountant,
        ),
      CosmeticReward(:final cosmeticId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.cosmetic,
          periodKey: planned.periodKey,
          cosmeticId: cosmeticId,
        ),
      ChapterUnlockReward(:final chapterId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.chapterUnlock,
          periodKey: planned.periodKey,
          chapterId: chapterId,
        ),
      CompanionAvailabilityReward(:final companionId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.companionAvailability,
          periodKey: planned.periodKey,
          companionId: companionId,
        ),
      TitleReward(:final titleId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.title,
          periodKey: planned.periodKey,
          titleId: titleId,
        ),
      EmblemReward(:final emblemId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.emblem,
          periodKey: planned.periodKey,
          emblemId: emblemId,
        ),
      RelicReward(:final relicId) => RewardGrantEvent(
          eventKey: planned.eventKey,
          timestamp: timestamp,
          nodeId: planned.node.id,
          rewardOrdinal: planned.rewardOrdinal,
          rewardKind: RewardGrantKind.relic,
          periodKey: planned.periodKey,
          relicId: relicId,
        ),
    };
  }

  RewardGrantEvent _buildXpEvent({
    required PlannedRewardGrant planned,
    required int runningXp,
    required DateTime timestamp,
    required int baseAmount,
    required RewardSourceKind? sourceKind,
    required EngineEvaluationContext? context,
    required _DailyBuffAccountant accountant,
  }) {
    final level = levelPolicy.levelForXp(runningXp);
    final scaled = levelPolicy.scaledRewardXp(baseXp: baseAmount, level: level);
    final multiplier = levelPolicy.rewardMultiplierForLevel(level);

    final bonus = _resolveCompanionBuffBonus(
      scaledBase: scaled,
      sourceKind: sourceKind,
      node: planned.node,
      context: context,
      accountant: accountant,
    );

    return RewardGrantEvent(
      eventKey: planned.eventKey,
      timestamp: timestamp,
      nodeId: planned.node.id,
      rewardOrdinal: planned.rewardOrdinal,
      rewardKind: RewardGrantKind.xp,
      periodKey: planned.periodKey,
      xpAmount: scaled + bonus,
      levelAtGrant: level,
      multiplierAtGrant: multiplier,
      companionBuffBonusXp: bonus > 0 ? bonus : null,
    );
  }

  /// Computes the companion-buff bonus XP for one XP-bearing reward.
  /// Returns 0 when:
  ///   * no companion is equipped,
  ///   * the equipped companion has no buff,
  ///   * RPG mode is off,
  ///   * the reward has no [sourceKind] (defensive — coverage test
  ///     blocks this at the catalog level),
  ///   * the buff's kind doesn't match the reward's source (and isn't
  ///     `allXp`),
  ///   * the dynamic rule returns a non-positive percent,
  ///   * the 25 % daily share cap would be exceeded.
  int _resolveCompanionBuffBonus({
    required int scaledBase,
    required RewardSourceKind? sourceKind,
    required ProgressionEntry node,
    required EngineEvaluationContext? context,
    required _DailyBuffAccountant accountant,
  }) {
    if (context == null) return 0;
    if (!context.player.rpgModeEnabled) return 0;
    final buff = context.equippedCompanionBuff;
    if (buff == null) return 0;
    if (sourceKind == null) return 0;
    if (buff.kind != RewardSourceKind.allXp && buff.kind != sourceKind) {
      return 0;
    }

    final isWeekly = node is Quest && node.displayBucket == QuestDisplayBucket.weekly;
    final chainPos = (node is Quest && node.chapterId != null)
        ? node.chainOrder
        : null;

    final percent = buff.resolvePercent(
      CompanionBuffContext(
        rewardSourceKind: sourceKind,
        currentStreak: context.maxCurrentStreak,
        isWeeklyQuestSource: isWeekly,
        chapterChainPosition: chainPos,
      ),
    );
    if (percent <= 0) return 0;

    final rawBonus = (scaledBase * percent / 100).round();
    if (rawBonus <= 0) return 0;

    return accountant.allowBonus(scaledBase: scaledBase, rawBonus: rawBonus);
  }
}

/// Tracks today's running XP + bonus totals so the soft-cap calculator
/// can clamp each new buff bonus before it pushes the share over
/// [_kDailyBuffShareCap].
class _DailyBuffAccountant {
  _DailyBuffAccountant({
    required this.totalXpToday,
    required this.bonusXpToday,
  });

  /// Seed from the journal's prior events for the same calendar day
  /// as [anchor]. Journal events older than today contribute nothing
  /// to the cap (it's a daily window).
  factory _DailyBuffAccountant.seed({
    required Journal? journal,
    required DateTime anchor,
  }) {
    if (journal == null) {
      return _DailyBuffAccountant(totalXpToday: 0, bonusXpToday: 0);
    }
    final today = _dayAnchor(anchor);
    var total = 0;
    var bonus = 0;
    for (final e in journal.events) {
      if (e is! RewardGrantEvent) continue;
      if (e.rewardKind != RewardGrantKind.xp) continue;
      if (_dayAnchor(e.timestamp) != today) continue;
      total += e.xpAmount ?? 0;
      bonus += e.companionBuffBonusXp ?? 0;
    }
    return _DailyBuffAccountant(totalXpToday: total, bonusXpToday: bonus);
  }

  int totalXpToday;
  int bonusXpToday;

  /// Returns the bonus that may be granted, clamped so the post-grant
  /// share never exceeds [_kDailyBuffShareCap]. Solving
  /// `(bonusXpToday + b) / (totalXpToday + scaledBase + b) <= cap`
  /// for `b` yields the headroom expression below.
  int allowBonus({required int scaledBase, required int rawBonus}) {
    // (bonus + b) <= cap * (total + base + b)
    // bonus + b <= cap*total + cap*base + cap*b
    // (1 - cap)*b <= cap*total + cap*base - bonus
    // b <= (cap*(total + base) - bonus) / (1 - cap)
    final headroom = (_kDailyBuffShareCap * (totalXpToday + scaledBase) -
            bonusXpToday) /
        (1 - _kDailyBuffShareCap);
    if (headroom <= 0) return 0;
    final cappedBonus = headroom.floor();
    return rawBonus <= cappedBonus ? rawBonus : cappedBonus;
  }

  void note({required int totalXp, required int bonusXp}) {
    totalXpToday += totalXp;
    bonusXpToday += bonusXp;
  }

  static DateTime _dayAnchor(DateTime t) {
    final local = t.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
