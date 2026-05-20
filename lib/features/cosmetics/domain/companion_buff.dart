import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/domain/progression/catalog/reward_source_kind.dart';

import 'companion_buff_config.dart';

export 'companion_buff_config.dart';
export 'package:forgetrack/domain/progression/catalog/progression_domain.dart'
    show ProgressionDomain;
export 'package:forgetrack/domain/progression/catalog/reward_source_kind.dart'
    show RewardSourceKind;

/// Per-grant context the engine assembles when asking a
/// [CompanionBuff] to resolve its effective percent. Pure data — no
/// engine types — so cosmetics can declare the API surface without
/// reaching into progression internals.
///
/// Fields default to neutral values; the engine populates only what
/// each rule cares about (`streakDomain` + `currentStreak` for Ember
/// / Lantern, `isWeeklyQuestSource` for Raven, `chapterChainPosition`
/// for Lynx). Buffs that don't care about a particular axis simply
/// ignore the corresponding field.
class CompanionBuffContext {
  const CompanionBuffContext({
    required this.rewardSourceKind,
    this.streakDomain,
    this.currentStreak = 0,
    this.isWeeklyQuestSource = false,
    this.chapterChainPosition,
  });

  /// Tag carried on the granting [XpReward] / [BonusXpReward] — see
  /// [RewardSourceKind]. Read by buffs that match on the granting
  /// XP bucket ([FlatCompanionBuff], Raven, Lynx).
  final RewardSourceKind rewardSourceKind;

  /// Domain the granting reward contributes a streak to, or `null`
  /// for rewards that should not participate in streak math (quests,
  /// combos, chapters, meta). Read by streak-scaling buffs (Ember,
  /// Lantern) — they treat `null` as "skip this reward". Carried as
  /// part of the reward, not derived from the node, so the buff and
  /// the streak chip always agree on which grants count.
  final ProgressionDomain? streakDomain;

  /// Length of the player's active streak in [streakDomain]. Zero
  /// when [streakDomain] is null or no streak is active in that
  /// domain.
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

/// Sealed buff a [Companion] catalog row may carry.
///
/// Buffs are **self-matching**: [resolvePercent] returns 0 whenever
/// the context does not match the buff's intended bucket, and the
/// effective percent otherwise. Callers (the engine grant path and
/// the pill projection) therefore never need to peek at the buff's
/// internals — they just multiply the percent into the scaled XP.
/// This keeps adding a new variant a single-file change.
sealed class CompanionBuff {
  const CompanionBuff();

  /// Effective bonus percent given the granting context. Returning
  /// 0 means "no bonus for this grant" — either the buff's match
  /// predicate failed (wrong source kind / wrong streak domain /
  /// pre-condition unmet) or a dynamic variant resolved to zero on
  /// the current tier.
  int resolvePercent(CompanionBuffContext ctx);
}

/// Static buff — matches by [RewardSourceKind]. Returns [percent]
/// for every reward whose `sourceKind` equals [kind], or for every
/// reward when [kind] is [RewardSourceKind.allXp] (mythic Dragonling).
final class FlatCompanionBuff extends CompanionBuff {
  const FlatCompanionBuff({required this.kind, required this.percent});

  /// The source bucket this buff applies to. `allXp` matches every
  /// kind.
  final RewardSourceKind kind;

  /// Bonus added to the granted XP (e.g. `8` → multiplier 1.08).
  final int percent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    if (kind != RewardSourceKind.allXp && kind != ctx.rewardSourceKind) {
      return 0;
    }
    return percent;
  }
}

/// Ember Sprite buff — applies to **every reward that contributes to
/// a streak**, scaling its percent with the length of that domain's
/// streak. Each main-5 daily-goal card therefore evaluates the buff
/// against its own streak: a 14-day steps streak yields a different
/// bonus than a 2-day sleep streak on the same player.
///
/// Rewards with [CompanionBuffContext.streakDomain] == null (quests,
/// combos, chapters, meta) get 0 — streaks are a daily-goal property
/// by design, encoded in the data, not in widget code.
///
/// Tier thresholds use *current* streak — a fresh reset returns the
/// floor tier, a 100-day veteran lands in the secret legendary tier.
final class StreakLengthCompanionBuff extends CompanionBuff {
  const StreakLengthCompanionBuff({
    this.tier0Percent = CompanionBuffPercents.emberTier0,
    this.tier1Percent = CompanionBuffPercents.emberTier1,
    this.tier2Percent = CompanionBuffPercents.emberTier2,
    this.tier3Percent = CompanionBuffPercents.emberTier3,
    this.tier4Percent = CompanionBuffPercents.emberTier4,
    this.legendaryPercent = CompanionBuffPercents.emberLegendary,
  });

  /// Returned for streaks 0–1 days (no streak / just reset).
  final int tier0Percent;

  /// Returned for streaks 2–6 days.
  final int tier1Percent;

  /// Returned for streaks 7–13 days.
  final int tier2Percent;

  /// Returned for streaks 14–20 days.
  final int tier3Percent;

  /// Returned for streaks 21–99 days. The advertised cap.
  final int tier4Percent;

  /// Returned for streaks 100+ days. Intentionally undocumented in
  /// player-facing copy — a quiet reward for the kind of devotion
  /// the rest of the catalog cannot describe.
  final int legendaryPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    if (ctx.streakDomain == null) return 0;
    final s = ctx.currentStreak;
    if (s >= CompanionBuffPercents.streakLegendaryThreshold) {
      return legendaryPercent;
    }
    if (s >= CompanionBuffPercents.emberTier4Threshold) return tier4Percent;
    if (s >= CompanionBuffPercents.emberTier3Threshold) return tier3Percent;
    if (s >= CompanionBuffPercents.emberTier2Threshold) return tier2Percent;
    if (s >= CompanionBuffPercents.emberTier1Threshold) return tier1Percent;
    return tier0Percent;
  }
}

/// Lantern Golem buff — flat percent **once a streak threshold is
/// crossed**. Like [StreakLengthCompanionBuff] the buff applies per
/// streak: each main-5 card unlocks the bonus independently the
/// first time its own streak reaches [minStreak]. Rewards with no
/// [CompanionBuffContext.streakDomain] return 0.
///
/// The legendary 100-day tier mirrors Ember Sprite — kept silent in
/// copy, surfaced only at the player's milestone.
final class StreakThresholdFlatCompanionBuff extends CompanionBuff {
  const StreakThresholdFlatCompanionBuff({
    required this.percent,
    required this.minStreak,
    this.legendaryPercent = CompanionBuffPercents.lanternLegendary,
  });

  /// Bonus applied at and above [minStreak] but below the legendary
  /// threshold.
  final int percent;

  /// Streak length at which the buff first activates. Below this
  /// the buff resolves to 0 (the chip will surface a "locked"
  /// variant so the mechanic is discoverable).
  final int minStreak;

  /// Bonus applied at and above
  /// [CompanionBuffPercents.streakLegendaryThreshold]. Undocumented
  /// in player-facing copy.
  final int legendaryPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    if (ctx.streakDomain == null) return 0;
    final s = ctx.currentStreak;
    if (s >= CompanionBuffPercents.streakLegendaryThreshold) {
      return legendaryPercent;
    }
    if (s < minStreak) return 0;
    return percent;
  }
}

/// Ruin Raven buff — different percents for daily vs weekly quest
/// claims. Net daily-total XP from the buff lands close to a flat
/// [FlatCompanionBuff] of the same rarity tier, but the player gets
/// a noticeably bigger swing on weekly close — matches the flavor
/// "seen most often after a weekly quest is closed".
final class WeeklyEmphasisCompanionBuff extends CompanionBuff {
  const WeeklyEmphasisCompanionBuff({
    this.dailyPercent = CompanionBuffPercents.ravenDaily,
    this.weeklyPercent = CompanionBuffPercents.ravenWeekly,
  });

  /// Bonus applied to daily-bucket quest claims.
  final int dailyPercent;

  /// Bonus applied to weekly-bucket quest claims.
  final int weeklyPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    if (ctx.rewardSourceKind != RewardSourceKind.questXp) return 0;
    return ctx.isWeeklyQuestSource ? weeklyPercent : dailyPercent;
  }
}

/// Cave Lynx buff — bonus grows with how deep the player is in the
/// current chapter chain. Resets to [openerPercent] when a new
/// chapter chain begins, so the player gets a fresh "ascending"
/// arc per chapter rather than a single permanent ramp.
final class ChapterDepthCompanionBuff extends CompanionBuff {
  const ChapterDepthCompanionBuff({
    this.openerPercent = CompanionBuffPercents.lynxOpener,
    this.midPercent = CompanionBuffPercents.lynxMid,
    this.deepPercent = CompanionBuffPercents.lynxDeep,
  });

  /// Returned for the chapter opener (chain position 0 or 1).
  final int openerPercent;

  /// Returned for mid-chain steps (positions 2–3).
  final int midPercent;

  /// Returned for the deep steps + finale (position 4+).
  final int deepPercent;

  @override
  int resolvePercent(CompanionBuffContext ctx) {
    if (ctx.rewardSourceKind != RewardSourceKind.chapterXp) return 0;
    final pos = ctx.chapterChainPosition;
    if (pos == null) return openerPercent;
    if (pos >= 4) return deepPercent;
    if (pos >= 2) return midPercent;
    return openerPercent;
  }
}
