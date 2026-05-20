import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/companion_buff.dart';

/// Player-facing label for a [CompanionBuff]. Flat buffs render
/// "+8 % XP za nutrici"; dynamic buffs render their own range or
/// per-cadence variant per spec §"Discoverability v UI" on card #91.
///
/// Kept as a top-level function (not a method on [CompanionBuff])
/// so the domain layer stays free of l10n concerns. Callers in
/// presentation pass the localizer; the result is a ready-to-render
/// string.
///
/// NB: streak-buff copy is intentionally framed as "+min–max % per
/// streak" because the buff resolves against each main-5 card's
/// own streak — the player will see the live tier on each card via
/// the streak chip, the chip-level summary just advertises the band.
String formatCompanionBuff(AppLocalizations l10n, CompanionBuff buff) {
  return switch (buff) {
    FlatCompanionBuff(:final kind, :final percent) =>
      l10n.cosmeticBuffFlat(percent, _buffSourceLabel(l10n, kind)),
    StreakLengthCompanionBuff(
      :final tier1Percent,
      :final tier4Percent,
    ) =>
      l10n.cosmeticBuffEmber(tier1Percent, tier4Percent),
    StreakThresholdFlatCompanionBuff(
      :final percent,
      :final minStreak,
    ) =>
      l10n.cosmeticBuffLanternThreshold(percent, minStreak),
    WeeklyEmphasisCompanionBuff(:final dailyPercent, :final weeklyPercent) =>
      l10n.cosmeticBuffRaven(dailyPercent, weeklyPercent),
    ChapterDepthCompanionBuff(:final openerPercent, :final deepPercent) =>
      l10n.cosmeticBuffLynx(openerPercent, deepPercent),
  };
}

/// Headline + subtitle copy pair for the full-width banner. Headline
/// is the punchy number ("+8 % XP …"); subtitle either explains a
/// dynamic mechanic or carries the generic "passive while equipped"
/// hint for flat buffs.
class CompanionBuffBannerCopy {
  const CompanionBuffBannerCopy({required this.headline, required this.subtitle});

  final String headline;
  final String subtitle;
}

/// Banner copy for [CompanionBuff]. Streak buffs (Ember Sprite,
/// Lantern Golem) intentionally stay in their **range / activation**
/// form here — the banner lives on the companion details sheet,
/// where the buff is summarised once for the whole companion. The
/// per-card live tier shows on each main-5 card's streak chip
/// instead, so a player who is sitting at +20 % on steps and 0 % on
/// sleep is never told they are at a single number.
///
/// [currentChapterChainPosition] still drives a live Lynx headline
/// because chapter depth is a single global value (only one chain
/// is active at a time).
CompanionBuffBannerCopy formatCompanionBuffBanner(
  AppLocalizations l10n,
  CompanionBuff buff, {
  int? currentChapterChainPosition,
}) {
  return switch (buff) {
    FlatCompanionBuff(:final kind, :final percent) => CompanionBuffBannerCopy(
        headline: l10n.cosmeticBuffFlat(percent, _buffSourceLabel(l10n, kind)),
        subtitle: l10n.cosmeticBuffBannerFlatSubtitle,
      ),
    StreakLengthCompanionBuff(
      :final tier1Percent,
      :final tier4Percent,
    ) =>
      CompanionBuffBannerCopy(
        headline: l10n.cosmeticBuffEmberHeadlineRange(
          tier1Percent,
          tier4Percent,
        ),
        subtitle: l10n.cosmeticBuffEmberSubtitle(tier4Percent),
      ),
    StreakThresholdFlatCompanionBuff(
      :final percent,
      :final minStreak,
    ) =>
      CompanionBuffBannerCopy(
        headline: l10n.cosmeticBuffLanternThresholdHeadline(percent, minStreak),
        subtitle: l10n.cosmeticBuffLanternThresholdSubtitle(minStreak),
      ),
    WeeklyEmphasisCompanionBuff(:final dailyPercent, :final weeklyPercent) =>
      CompanionBuffBannerCopy(
        headline: l10n.cosmeticBuffRaven(dailyPercent, weeklyPercent),
        subtitle: l10n.cosmeticBuffRavenSubtitle,
      ),
    ChapterDepthCompanionBuff(:final openerPercent, :final deepPercent) =>
      () {
        if (currentChapterChainPosition != null) {
          final live = buff.resolvePercent(
            CompanionBuffContext(
              rewardSourceKind: RewardSourceKind.chapterXp,
              chapterChainPosition: currentChapterChainPosition,
            ),
          );
          return CompanionBuffBannerCopy(
            headline: l10n.cosmeticBuffLynxHeadlineLive(live),
            subtitle: l10n.cosmeticBuffLynxSubtitle(deepPercent),
          );
        }
        return CompanionBuffBannerCopy(
          headline:
              l10n.cosmeticBuffLynxHeadlineRange(openerPercent, deepPercent),
          subtitle: l10n.cosmeticBuffLynxSubtitle(deepPercent),
        );
      }(),
  };
}

String _buffSourceLabel(AppLocalizations l10n, RewardSourceKind kind) {
  return switch (kind) {
    RewardSourceKind.activityXp => l10n.cosmeticBuffSourceActivityXp,
    RewardSourceKind.nutritionXp => l10n.cosmeticBuffSourceNutritionXp,
    RewardSourceKind.sleepXp => l10n.cosmeticBuffSourceSleepXp,
    RewardSourceKind.streakXp => l10n.cosmeticBuffSourceStreakXp,
    RewardSourceKind.questXp => l10n.cosmeticBuffSourceQuestXp,
    RewardSourceKind.chapterXp => l10n.cosmeticBuffSourceChapterXp,
    RewardSourceKind.allXp => l10n.cosmeticBuffSourceAllXp,
  };
}

/// Renders a buff label as a single-line chip tinted with the
/// passed [color] (typically the companion's rarity color). Suitable
/// for: the hero header pop-out, the hero detail profile.
///
/// For the companion details sheet use [CompanionBuffBanner] —
/// full-width, XP-tinted, prioritized presentation.
class CompanionBuffChip extends StatelessWidget {
  const CompanionBuffChip({
    super.key,
    required this.buff,
    required this.color,
    this.compact = false,
  });

  final CompanionBuff buff;
  final Color color;

  /// Tighter padding / smaller text for placement inside an already
  /// dense header (e.g. the hero card chrome).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = formatCompanionBuff(l10n, buff);
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pets_rounded,
            size: compact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: compact ? 5 : 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width banner emphasizing the companion's XP bonus as the
/// prioritized information in the details sheet. Uses [Tokens.xp]
/// (amber/gold) instead of the companion rarity color — the banner
/// represents XP gain, not rarity flex; rarity tinting stays on the
/// other tags and the cosmetic asset frame.
///
/// Headline carries the punchy number; subtitle explains either the
/// dynamic mechanic (Ember / Raven / Lynx) or the generic passive
/// nature for flat buffs.
///
/// Pass [currentChapterChainPosition] to switch the Cave Lynx
/// headline from the opener → deep range form to a live bracket
/// value reflecting the active chapter chain. Streak buffs (Ember /
/// Lantern) stay in their range / activation form here by design —
/// per-card live tiers belong on the streak chip, not on the
/// once-per-companion banner.
class CompanionBuffBanner extends StatelessWidget {
  const CompanionBuffBanner({
    super.key,
    required this.buff,
    this.currentChapterChainPosition,
  });

  final CompanionBuff buff;
  final int? currentChapterChainPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = formatCompanionBuffBanner(
      l10n,
      buff,
      currentChapterChainPosition: currentChapterChainPosition,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Tokens.xp.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.xp.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.pets_rounded,
            size: 22,
            color: Tokens.xp,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.headline,
                  style: const TextStyle(
                    color: Tokens.xp,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.subtitle,
                  style: const TextStyle(
                    color: Tokens.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
