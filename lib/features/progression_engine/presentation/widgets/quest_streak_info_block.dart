import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/domain/companion_buff.dart';

/// Pedagogic info block rendered inside the expanded detail of a
/// main-five daily-goal card. Explains what the streak number on
/// the card actually means, and — when a streak buff is equipped —
/// surfaces the live tier, the next tier's threshold, and the
/// locked-until-streak-X states so the buff mechanic is discoverable
/// without leaving the card.
///
/// The block is intentionally **only rendered on main-five cards**
/// (caller decides via the presence of a [ProgressionDomain] streak
/// tag on the quest's rewards). Combos / chapter steps / weekly
/// quests / long-term goals never participate in streaks and adding
/// a "no streak here" disclaimer would be noise.
///
/// Four visual modes share one widget so the expanded-card layout
/// stays predictable across states:
///
/// * **legendary** — current streak ≥ 100. Special gold-tinted
///   reveal. Triggered only when a streak buff is equipped and its
///   resolved percent matches the silent 100 % milestone.
/// * **live** — Ember tier ≥ 1 OR Lantern past threshold. Reads as
///   "+X % bonus XP" + next-tier hint when one exists below the
///   legendary milestone, otherwise just the current percent (cap).
/// * **locked** — buff equipped but resolved percent is 0 (Ember
///   tier 0 with streak 0–1 OR Lantern below threshold). Shows the
///   unlock condition in copy.
/// * **plain** — no streak buff equipped (or a non-streak buff like
///   Forest Fox). Just the current-streak sentence; the buff isn't
///   the player's main lever for this card.
class QuestStreakInfoBlock extends StatelessWidget {
  const QuestStreakInfoBlock({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.accent,
    this.buff,
    this.resolvedPercent = 0,
  });

  /// This card's domain streak length. Drives every variant's copy.
  final int currentStreak;

  /// Best streak ever recorded for this card's domain. Surfaced as a
  /// secondary line so the player sees the record they're chasing.
  /// Hidden when zero so fresh players don't get a "Best: 0" line.
  final int bestStreak;

  /// Card accent (per-domain colour) used for the streak number,
  /// flame icon tint, and the live-tier headline.
  final Color accent;

  /// Equipped companion buff, or null when no companion is equipped.
  /// Only [StreakLengthCompanionBuff] / [StreakThresholdFlatCompanionBuff]
  /// drive a non-plain variant; every other buff falls through to
  /// the plain mode.
  final CompanionBuff? buff;

  /// Pre-resolved percent for this card's streak — already run
  /// through `buff.resolvePercent` by the caller (provider). The
  /// widget never re-resolves so the chip / banner / engine grant
  /// path all read the same number.
  final int resolvedPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _resolveState();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: state.tint.withValues(alpha: state.fillAlpha),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(
          color: state.tint.withValues(alpha: state.borderAlpha),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(state.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.headline(l10n),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: state.tint,
                  ),
                ),
              ),
            ],
          ),
          if (state.subtitle(l10n) case final String subtitle) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Tokens.onSurfaceMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (bestStreak > 0 && bestStreak != currentStreak) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                l10n.progStreakInfoBest(bestStreak),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StreakBannerState _resolveState() {
    // Legendary tier is read off the resolved percent rather than
    // the streak length so renames to the silent milestone don't
    // require touching the UI — if the buff math says "100", we
    // surface the legendary banner.
    final isLegendaryPayout = buff != null &&
        resolvedPercent >= CompanionBuffPercents.streakLegendaryThreshold;

    if (isLegendaryPayout) {
      return _StreakBannerState(
        emoji: '🌟',
        tint: Tokens.xp,
        fillAlpha: 0.14,
        borderAlpha: 0.40,
        headline: (l10n) =>
            l10n.progStreakInfoLegendaryHeadline(currentStreak),
        subtitle: (l10n) =>
            l10n.progStreakInfoLegendarySubtitle(resolvedPercent),
      );
    }

    // Locked variants — streak buff equipped but resolved percent
    // is still 0. Each streak buff reports its unlock condition via
    // a switch on the sealed type.
    if (buff != null && resolvedPercent <= 0) {
      switch (buff!) {
        case StreakLengthCompanionBuff():
          // Ember sits in tier 0 below the tier-1 threshold (2 d).
          final daysToUnlock =
              CompanionBuffPercents.emberTier1Threshold - currentStreak;
          if (daysToUnlock > 0) {
            return _lockedState(
              daysToUnlock: daysToUnlock,
              percentAtUnlock: CompanionBuffPercents.emberTier1,
              unlockStreak: CompanionBuffPercents.emberTier1Threshold,
            );
          }
        case StreakThresholdFlatCompanionBuff(:final minStreak, :final percent):
          final daysToUnlock = minStreak - currentStreak;
          if (daysToUnlock > 0) {
            return _lockedState(
              daysToUnlock: daysToUnlock,
              percentAtUnlock: percent,
              unlockStreak: minStreak,
            );
          }
        // Non-streak buffs fall through to plain mode — they don't
        // care about per-domain streak so a "locked" state would be
        // misleading.
        case FlatCompanionBuff():
        case WeeklyEmphasisCompanionBuff():
        case ChapterDepthCompanionBuff():
          break;
      }
    }

    // Live variant — streak buff equipped and paying out a non-zero
    // percent below the legendary milestone.
    if (buff != null && resolvedPercent > 0) {
      final next = _nextVisibleTier();
      return _StreakBannerState(
        emoji: '🔥',
        tint: accent,
        fillAlpha: 0.12,
        borderAlpha: 0.30,
        headline: (l10n) =>
            l10n.progStreakInfoLiveHeadline(currentStreak, resolvedPercent),
        subtitle: (l10n) => next == null
            ? l10n.progStreakInfoLiveCap(resolvedPercent)
            : l10n.progStreakInfoLiveNextTier(
                next.percent,
                next.threshold,
              ),
      );
    }

    // Plain mode — no streak buff equipped (or a non-streak buff).
    // Keeps the pedagogy ("X dní v řadě splněno") without claiming
    // a bonus the player isn't actually earning.
    return _StreakBannerState(
      emoji: currentStreak > 0 ? '🔥' : '·',
      tint: currentStreak > 0
          ? accent
          : Colors.white.withValues(alpha: 0.55),
      fillAlpha: 0.08,
      borderAlpha: 0.20,
      headline: (l10n) => l10n.progStreakInfoPlainHeadline(currentStreak),
      subtitle: (l10n) => null,
    );
  }

  _StreakBannerState _lockedState({
    required int daysToUnlock,
    required int percentAtUnlock,
    required int unlockStreak,
  }) {
    return _StreakBannerState(
      emoji: '🔒',
      tint: Colors.white.withValues(alpha: 0.55),
      fillAlpha: 0.06,
      borderAlpha: 0.18,
      headline: (l10n) => l10n.progStreakInfoLockedHeadline(currentStreak),
      subtitle: (l10n) => l10n.progStreakInfoLockedSubtitle(
        daysToUnlock,
        percentAtUnlock,
        unlockStreak,
      ),
    );
  }

  /// Next *visible* tier above the current resolved percent. Returns
  /// null at or above the cap. Legendary (100 %) is intentionally
  /// invisible — the player discovers it by reaching the milestone,
  /// not by reading a hint.
  _NextTier? _nextVisibleTier() {
    final b = buff;
    if (b is StreakLengthCompanionBuff) {
      const tiers = <(int threshold, int percent)>[
        (
          CompanionBuffPercents.emberTier1Threshold,
          CompanionBuffPercents.emberTier1,
        ),
        (
          CompanionBuffPercents.emberTier2Threshold,
          CompanionBuffPercents.emberTier2,
        ),
        (
          CompanionBuffPercents.emberTier3Threshold,
          CompanionBuffPercents.emberTier3,
        ),
        (
          CompanionBuffPercents.emberTier4Threshold,
          CompanionBuffPercents.emberTier4,
        ),
      ];
      for (final (threshold, percent) in tiers) {
        if (percent > resolvedPercent) {
          return _NextTier(threshold: threshold, percent: percent);
        }
      }
      return null;
    }
    // Lantern Golem is flat — no next tier after activation.
    return null;
  }
}

class _StreakBannerState {
  const _StreakBannerState({
    required this.emoji,
    required this.tint,
    required this.fillAlpha,
    required this.borderAlpha,
    required this.headline,
    required this.subtitle,
  });

  final String emoji;
  final Color tint;
  final double fillAlpha;
  final double borderAlpha;
  final String Function(AppLocalizations l10n) headline;
  final String? Function(AppLocalizations l10n) subtitle;
}

class _NextTier {
  const _NextTier({required this.threshold, required this.percent});
  final int threshold;
  final int percent;
}
