import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/companion_buff.dart';

/// Player-facing label for a [CompanionBuff]. Flat buffs render
/// "+8 % XP z aktivit"; dynamic buffs render their own range or
/// per-cadence variant per spec §"Discoverability v UI" on card #91.
///
/// Kept as a top-level function (not a method on [CompanionBuff])
/// so the domain layer stays free of l10n concerns. Callers in
/// presentation pass the localizer; the result is a ready-to-render
/// string.
String formatCompanionBuff(AppLocalizations l10n, CompanionBuff buff) {
  return switch (buff) {
    FlatCompanionBuff(:final kind, :final percent) =>
      l10n.cosmeticBuffFlat(percent, _buffSourceLabel(l10n, kind)),
    StreakLengthCompanionBuff(
      :final floorPercent,
      :final longStreakPercent,
    ) =>
      l10n.cosmeticBuffEmber(floorPercent, longStreakPercent),
    WeeklyEmphasisCompanionBuff(:final dailyPercent, :final weeklyPercent) =>
      l10n.cosmeticBuffRaven(dailyPercent, weeklyPercent),
    ChapterDepthCompanionBuff(:final openerPercent, :final deepPercent) =>
      l10n.cosmeticBuffLynx(openerPercent, deepPercent),
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
/// for: the unlocked-state details sheet, the hero header pop-out,
/// the hero detail profile.
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
            Icons.auto_awesome_rounded,
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
