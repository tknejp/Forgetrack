import 'package:flutter/material.dart';

import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/domain/companion_buff.dart';

/// Compact streak chip rendered on a main-five daily-goal card to
/// surface both the per-card streak count and — when the equipped
/// companion's buff resolves to a non-zero percent for this domain —
/// the live bonus the player will pick up on their next claim.
///
/// Three visual states share a single chip so the card layout never
/// shifts:
///
/// * **plain** — no companion buff, or the equipped buff doesn't
///   affect streak XP. Renders `🔥 12d` with a muted flame icon.
/// * **live** — the equipped streak buff resolves to `percent > 0`
///   for this domain. Renders `🔥 12d · +10 %` with the flame
///   emoji tinted in the rarity accent so the buff's contribution
///   reads instantly without parsing the number.
/// * **locked** — the equipped streak buff is a threshold-flat
///   variant (Lantern Golem) and this domain's streak is below the
///   activation point. Renders `🔒 12d · +30 % od 7d` so the
///   unlock condition becomes discoverable from the chip itself.
///
/// Callers pass the **resolved percent** (already evaluated through
/// `buff.resolvePercent`) so the widget stays presentation-only;
/// resolution logic lives in `RewardGrantService` /
/// `ProgressionEngineProvider.projectedCompanionBuffBonusFor`.
class QuestStreakChip extends StatelessWidget {
  const QuestStreakChip({
    super.key,
    required this.streakDays,
    required this.accent,
    this.buff,
    this.resolvedPercent = 0,
  });

  /// This domain's current streak length. Always rendered — even at
  /// 0 — because the chip is also the player's only on-card view of
  /// "did my streak survive yesterday".
  final int streakDays;

  /// Accent colour used for the flame tint (live) and the percent
  /// text. Conventionally the card's domain colour.
  final Color accent;

  /// Equipped companion buff, or null when no companion is equipped
  /// or the equipped buff is not streak-related. Determines the
  /// chip's visual state when combined with [resolvedPercent].
  final CompanionBuff? buff;

  /// The percent `buff` resolved to for this card's streak (already
  /// run through `buff.resolvePercent` by the caller). When the buff
  /// is a [StreakThresholdFlatCompanionBuff] **and** this is 0, the
  /// chip switches to the locked variant so the threshold copy
  /// surfaces.
  final int resolvedPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isThresholdBuff = buff is StreakThresholdFlatCompanionBuff;
    final isLocked = isThresholdBuff && resolvedPercent <= 0;
    final isLive = resolvedPercent > 0;

    final iconColor = isLive ? accent : Colors.white.withValues(alpha: 0.55);
    final emoji = isLocked ? '🔒' : '🔥';

    final String label;
    if (isLocked) {
      final threshold = (buff as StreakThresholdFlatCompanionBuff).minStreak;
      final percent = (buff as StreakThresholdFlatCompanionBuff).percent;
      label = l10n.questStreakChipLocked(streakDays, percent, threshold);
    } else if (isLive) {
      label = l10n.questStreakChipWithBonus(streakDays, resolvedPercent);
    } else {
      label = l10n.questStreakChipDays(streakDays);
    }

    final textColor =
        isLive ? accent : Colors.white.withValues(alpha: 0.78);
    final borderAlpha = isLive ? 0.32 : 0.20;
    final fillAlpha = isLive ? 0.15 : 0.10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: fillAlpha),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: accent.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // lint-ignore: l10n-literal — emoji symbol, locale-invariant.
          Text(
            emoji,
            style: TextStyle(
              fontSize: 11,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns the [ProgressionDomain] this quest contributes a streak
/// to, derived from any `streakDomain`-tagged XP reward on the node.
/// Returns null when no reward carries one — those nodes (quests,
/// combos, chapters, meta) deliberately stay out of the streak chip
/// flow.
///
/// Kept as a top-level helper so both [QuestStreakChip] callers and
/// the engine card layout share a single rule for "is this a
/// main-five daily goal card".
ProgressionDomain? streakDomainOfRewards(Iterable<RewardDefinition> rewards) {
  for (final r in rewards) {
    final domain = switch (r) {
      XpReward(:final streakDomain) => streakDomain,
      BonusXpReward(:final streakDomain) => streakDomain,
      _ => null,
    };
    if (domain != null) return domain;
  }
  return null;
}
