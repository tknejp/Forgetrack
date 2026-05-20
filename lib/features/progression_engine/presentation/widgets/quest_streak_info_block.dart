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
    final rows = _buildRows(l10n);

    // Two-column layout: fixed-width icon gutter + flexible text
    // column. Splitting concepts (streak / bonus / next tier / best)
    // into separate single-purpose rows reads as a scannable
    // stat-table instead of a wall of bullet-joined copy.
    final textStyle = TextStyle(
      fontSize: Tokens.fontSizeMicro,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.55),
      height: 1.3,
    );
    const iconColumnWidth = 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: iconColumnWidth,
                child: Text(rows[i].icon, style: textStyle),
              ),
              Expanded(
                child: Text(
                  rows[i].text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds the ordered list of `(icon, text)` rows the widget will
  /// render. Each row carries a single concept:
  ///
  ///   1. Current streak count (always).
  ///   2. Bonus state — only when a streak buff is equipped:
  ///      * locked (🔒) below activation,
  ///      * live (⚡) at any payout tier below the cap,
  ///      * cap (⚡) at the highest visible tier,
  ///      * legendary (🌟) once the silent 100-day milestone is hit.
  ///   3. Next-tier hint (↗) — only for live tiers when a further
  ///      tier exists below the legendary milestone.
  ///   4. Best streak (🏆) — only when the player isn't already on
  ///      their personal record.
  List<_StreakInfoRow> _buildRows(AppLocalizations l10n) {
    final rows = <_StreakInfoRow>[
      _StreakInfoRow(
        icon: '🔥',
        text: l10n.progStreakInfoPlainHeadline(currentStreak),
      ),
    ];

    final bonusRow = _resolveBonusRow(l10n);
    if (bonusRow != null) rows.add(bonusRow);

    final nextTierRow = _resolveNextTierRow(l10n);
    if (nextTierRow != null) rows.add(nextTierRow);

    if (bestStreak > 0 && bestStreak != currentStreak) {
      rows.add(_StreakInfoRow(
        icon: '🏆',
        text: l10n.progStreakInfoBest(bestStreak),
      ));
    }
    return rows;
  }

  _StreakInfoRow? _resolveBonusRow(AppLocalizations l10n) {
    final b = buff;
    if (b == null) return null;
    if (b is! StreakLengthCompanionBuff &&
        b is! StreakThresholdFlatCompanionBuff) {
      return null;
    }

    // Legendary milestone — surface only when the buff math actually
    // resolves to the silent threshold so the reveal stays a discovery.
    if (resolvedPercent >= CompanionBuffPercents.streakLegendaryThreshold) {
      return _StreakInfoRow(
        icon: '🌟',
        text: l10n.progStreakInfoLegendarySubtitle(resolvedPercent),
      );
    }

    if (resolvedPercent > 0) {
      // At the highest visible tier the cap line carries both the
      // "no further upgrades" + current bonus copy in one string;
      // sub-cap tiers show just the bare bonus value, paired with a
      // next-tier hint in a separate row below.
      final atCap = _nextVisibleTier() == null;
      return _StreakInfoRow(
        icon: '⚡',
        text: atCap
            ? l10n.progStreakInfoLiveCap(resolvedPercent)
            : l10n.progStreakInfoLiveBonus(resolvedPercent),
      );
    }

    // Locked — buff equipped but resolved percent is 0. The unlock
    // condition is the same for both streak buff variants once we
    // derive (daysToUnlock, percentAtUnlock); the only difference is
    // which threshold to compare against.
    final unlock = _resolveUnlockCondition(b);
    if (unlock == null) return null;
    return _StreakInfoRow(
      icon: '🔒',
      text: l10n.progStreakInfoLockedSubtitle(
        unlock.daysToUnlock,
        unlock.percentAtUnlock,
      ),
    );
  }

  _StreakInfoRow? _resolveNextTierRow(AppLocalizations l10n) {
    if (resolvedPercent <= 0) return null;
    if (resolvedPercent >= CompanionBuffPercents.streakLegendaryThreshold) {
      return null;
    }
    final next = _nextVisibleTier();
    if (next == null) return null;
    return _StreakInfoRow(
      icon: '↗',
      text: l10n.progStreakInfoLiveNextTier(next.percent, next.threshold),
    );
  }

  _UnlockCondition? _resolveUnlockCondition(CompanionBuff b) {
    switch (b) {
      case StreakLengthCompanionBuff():
        // Ember sits in tier 0 below the tier-1 threshold.
        final daysToUnlock =
            CompanionBuffPercents.emberTier1Threshold - currentStreak;
        if (daysToUnlock <= 0) return null;
        return _UnlockCondition(
          daysToUnlock: daysToUnlock,
          percentAtUnlock: CompanionBuffPercents.emberTier1,
        );
      case StreakThresholdFlatCompanionBuff(:final minStreak, :final percent):
        final daysToUnlock = minStreak - currentStreak;
        if (daysToUnlock <= 0) return null;
        return _UnlockCondition(
          daysToUnlock: daysToUnlock,
          percentAtUnlock: percent,
        );
      case FlatCompanionBuff():
      case WeeklyEmphasisCompanionBuff():
      case ChapterDepthCompanionBuff():
        return null;
    }
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

class _StreakInfoRow {
  const _StreakInfoRow({required this.icon, required this.text});
  final String icon;
  final String text;
}

class _UnlockCondition {
  const _UnlockCondition({
    required this.daysToUnlock,
    required this.percentAtUnlock,
  });
  final int daysToUnlock;
  final int percentAtUnlock;
}

class _NextTier {
  const _NextTier({required this.threshold, required this.percent});
  final int threshold;
  final int percent;
}
