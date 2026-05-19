import 'package:forgetrack/domain/progression/catalog/reward_source_kind.dart';

export 'package:forgetrack/domain/progression/catalog/reward_source_kind.dart'
    show RewardSourceKind;

/// Per-grant context the engine assembles when asking a
/// [CompanionBuff] to resolve its effective percent. Pure data — no
/// engine types — so cosmetics can declare the API surface without
/// reaching into progression internals.
///
/// Fields default to neutral values; the engine populates only what
/// each rule cares about (`currentStreak` for Ember, `isWeeklyQuest`
/// for Raven, `chapterChainPosition` for Lynx). Flat buffs ignore
/// the context entirely.
class CompanionBuffContext {
  const CompanionBuffContext({
    required this.rewardSourceKind,
    this.currentStreak = 0,
    this.isWeeklyQuestSource = false,
    this.chapterChainPosition,
  });

  /// Tag carried on the granting [XpReward] / [BonusXpReward] — see
  /// [RewardSourceKind].
  final RewardSourceKind rewardSourceKind;

  /// Current daily-streak length (days). Read by streak-scaling
  /// buffs (Ember Sprite). Zero when no streak is active.
  final int currentStreak;

  /// True when the granting node is a weekly-bucket quest. Read by
  /// weekly-emphasis buffs (Ruin Raven).
  final bool isWeeklyQuestSource;

  /// Position of the granting chapter quest inside its chain (0-based
  /// for the opener, then 1 / 2 / 3 / …; the finale lands at the
  /// step count + 1). Null when the granting node is not part of a
  /// chapter chain. Read by chapter-depth buffs (Cave Lynx).
  final int? chapterChainPosition;
}

/// Sealed buff a [Companion] catalog row may carry. The engine reads
/// `kind` to filter which rewards the buff applies to (or treats
/// every reward as a match when `kind == allXp`), then invokes
/// [resolvePercent] to produce the effective bonus.
///
/// Phase 1 ships [FlatCompanionBuff] for 7 of 10 companions. Three
/// dynamic variants — [StreakLengthCompanionBuff],
/// [WeeklyEmphasisCompanionBuff], [ChapterDepthCompanionBuff] — back
/// the three flavor-driven mechanics from the card (Ember Sprite,
/// Ruin Raven, Cave Lynx).
sealed class CompanionBuff {
  const CompanionBuff();

  /// Source kind the buff targets. `allXp` matches every kind.
  RewardSourceKind get kind;

  /// Effective bonus percent given the granting context. Returning
  /// 0 means "no bonus this frame" (e.g. a dynamic rule whose
  /// pre-conditions don't hold).
  int resolvePercent(CompanionBuffContext ctx);
}

/// Static buff — single constant percent.
final class FlatCompanionBuff extends CompanionBuff {
  const FlatCompanionBuff({required this.kind, required this.percent});

  @override
  final RewardSourceKind kind;

  /// Bonus added to the granted XP (e.g. `8` → multiplier 1.08).
  final int percent;

  @override
  int resolvePercent(CompanionBuffContext ctx) => percent;
}

/// Ember Sprite buff — bonus scales with current streak length.
///
/// Floor protects the player when a streak resets so the buff is
/// never worse than "no buff"; cap keeps the uncommon-tier buff from
/// overshadowing rare / epic flat buffs at higher tiers.
final class StreakLengthCompanionBuff extends CompanionBuff {
  const StreakLengthCompanionBuff({
    this.floorPercent = 3,
    this.shortStreakPercent = 6,
    this.mediumStreakPercent = 9,
    this.longStreakPercent = 12,
  });

  @override
  RewardSourceKind get kind => RewardSourceKind.streakXp;

  /// Returned for streaks 1–3 days (or 0, i.e. just reset).
  final int floorPercent;

  /// Returned for streaks 4–7 days.
  final int shortStreakPercent;

  /// Returned for streaks 8–14 days.
  final int mediumStreakPercent;

  /// Returned for streaks 15+ days. Cap.
  final int longStreakPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    final s = ctx.currentStreak;
    if (s >= 15) return longStreakPercent;
    if (s >= 8) return mediumStreakPercent;
    if (s >= 4) return shortStreakPercent;
    return floorPercent;
  }
}

/// Ruin Raven buff — different percents for daily vs weekly quest
/// claims. Net daily-total XP from the buff lands close to a flat
/// [FlatCompanionBuff] of the same rarity tier, but the player gets
/// a noticeably bigger swing on weekly close — matches the flavor
/// "seen most often after a weekly quest is closed".
final class WeeklyEmphasisCompanionBuff extends CompanionBuff {
  const WeeklyEmphasisCompanionBuff({
    this.dailyPercent = 5,
    this.weeklyPercent = 30,
  });

  @override
  RewardSourceKind get kind => RewardSourceKind.questXp;

  /// Bonus applied to daily-bucket quest claims.
  final int dailyPercent;

  /// Bonus applied to weekly-bucket quest claims.
  final int weeklyPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) =>
      ctx.isWeeklyQuestSource ? weeklyPercent : dailyPercent;
}

/// Cave Lynx buff — bonus grows with how deep the player is in the
/// current chapter chain. Resets to [openerPercent] when a new
/// chapter chain begins, so the player gets a fresh "ascending"
/// arc per chapter rather than a single permanent ramp.
final class ChapterDepthCompanionBuff extends CompanionBuff {
  const ChapterDepthCompanionBuff({
    this.openerPercent = 25,
    this.midPercent = 40,
    this.deepPercent = 65,
  });

  @override
  RewardSourceKind get kind => RewardSourceKind.chapterXp;

  /// Returned for the chapter opener (chain position 0 or 1).
  final int openerPercent;

  /// Returned for mid-chain steps (positions 2–3).
  final int midPercent;

  /// Returned for the deep steps + finale (position 4+).
  final int deepPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    final pos = ctx.chapterChainPosition;
    if (pos == null) return openerPercent;
    if (pos >= 4) return deepPercent;
    if (pos >= 2) return midPercent;
    return openerPercent;
  }
}
