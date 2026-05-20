import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/domain/cosmetic_catalog.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetic_details_sheet.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_asset_thumb.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';

/// Compact pill rendered beneath the XP pill on quest cards that have
/// a companion node (achievement / milestone sharing the same
/// objective) or a non-XP direct reward.
///
/// Content: the companion's badge glyph + a chevron. The whole pill is
/// a tap target — taps bubble to the parent so the card expand can be
/// toggled. Replaces the standalone chevron — when no companion / no
/// extra reward exists, the card isn't expandable at all.
///
/// Fallback emoji: 🎁 for non-achievement extras (direct cosmetic / item
/// rewards on the quest itself, milestone companions without their own
/// emoji).
class EngineCompanionPill extends StatelessWidget {
  const EngineCompanionPill({
    super.key,
    required this.badge,
    required this.expanded,
    required this.onTap,
    this.accent = Tokens.accent,
  });

  /// Single-glyph badge (typically an emoji from Achievement /
  /// LevelMilestone; defaults to 🎁 for non-emoji extras).
  final String badge;

  /// Drives the chevron rotation — true when the parent card is
  /// expanded.
  final bool expanded;

  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.expand_more_rounded,
                size: 14,
                color: accent.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves the badge glyph for a companion entry. Achievement nodes
/// carry an emoji explicitly; level milestones carry their level emoji;
/// everything else falls back to 🎁 so the player still gets a visual
/// "this is an extra reward" hint.
String badgeForCompanion(ProgressionEntry node) {
  return switch (node) {
    Achievement(:final badgeEmoji) => badgeEmoji,
    LevelMilestone(:final emoji) => emoji,
    _ => '🎁',
  };
}

/// Resolves the badge glyph for a direct non-XP reward on the quest
/// itself (when the quest carries a cosmetic / item without a
/// companion node). Matches the reward kind icon vocabulary used by
/// the chip strip but in emoji form for the pill.
String badgeForReward(RewardDefinition reward) {
  return switch (reward) {
    XpReward() => '⚡',
    BonusXpReward() => '\u{2728}', // ✨ sparkle for bonus XP
    CosmeticReward() => '🎨',
    ChapterUnlockReward() => '📖',
    CompanionAvailabilityReward() => '🤝',
    TitleReward() => '🎖️',
    EmblemReward() => '🏅',
    RelicReward() => '💎',
  };
}

/// Modal bottom sheet styled to match the legacy achievement detail
/// (`hero_screen.dart#_AchievementDetailsSheet`). Triggered by tapping
/// a companion row in the long-term card's expanded panel.
///
/// Differences from the legacy V1 sheet:
/// - Reads V2 [ProgressionEntry] + the bound objective's actual /
///   target / progress passed in by the caller (companion shares the
///   long-term quest's objective).
/// - Resolves each non-XP reward against [CosmeticCatalog] so the row
///   shows the **real** cosmetic name (e.g. "KÃ¡men Roklin", "RÃ¡meÄek
///   Worldwalker") instead of a generic palette glyph.
/// - No social actions (share / pin) yet — these depend on the V2
///   migration of social. The detail stays read-only until the
///   companion unlocks.
Future<void> showEngineCompanionDetailSheet(
  BuildContext context, {
  required ProgressionEntry node,
  required double actualValue,
  required double targetValue,
  required double progress,
  required bool isUnlocked,
  required Color accent,
  required AppLocalizations l10n,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _CompanionDetailSheet(
      node: node,
      actualValue: actualValue,
      targetValue: targetValue,
      progress: progress,
      isUnlocked: isUnlocked,
      accent: accent,
      l10n: l10n,
    ),
  );
}

class _CompanionDetailSheet extends StatelessWidget {
  const _CompanionDetailSheet({
    required this.node,
    required this.actualValue,
    required this.targetValue,
    required this.progress,
    required this.isUnlocked,
    required this.accent,
    required this.l10n,
  });

  final ProgressionEntry node;
  final double actualValue;
  final double targetValue;
  final double progress;
  final bool isUnlocked;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final badge = badgeForCompanion(node);
    final locale = Localizations.localeOf(context).toString();
    final nonXp = [
      for (final r in node.rewards)
        if (r is! XpReward) r,
    ];
    final progressLabel = _formatProgressLabel(locale);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final color = isUnlocked ? accent : Tokens.onSurfaceMuted;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceLg),
            // Header row — matches legacy _AchievementDetailsSheet:
            // emoji badge in colored circle, title + summary, status
            // pill on the right.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BadgeCircle(emoji: badge, color: color, unlocked: isUnlocked),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.titleKey(l10n),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: Tokens.spaceXs),
                      Text(
                        progressLabel,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                _StatusPill(
                  label: isUnlocked
                      ? l10n.progAchievementStatusUnlocked
                      : l10n.progAchievementStatusInProgress,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceLg),
            Text(
              node.descriptionKey(l10n),
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.45,
                color: Tokens.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(label: node.rarity.label(l10n), color: color),
                _InfoPill(label: progressLabel, color: color),
              ],
            ),
            const SizedBox(height: 14),
            _ProgressBlock(
              progress: isUnlocked ? 1 : progress,
              label: progressLabel,
              color: color,
            ),
            // Reward rows — one per non-XP reward authored on the
            // companion. Each row resolves the cosmetic by id and
            // shows its real name + asset, not just the palette glyph
            // we used before.
            if (nonXp.isNotEmpty) ...[
              const SizedBox(height: Tokens.spaceLg),
              Text(
                l10n.progQuestsLongTermAlsoUnlocks.toUpperCase(),
                style: const TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w900,
                  color: Tokens.onSurfaceMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < nonXp.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                EngineRewardDetailRow(
                  reward: nonXp[i],
                  l10n: l10n,
                  unlocked: isUnlocked,
                  accent: color,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatProgressLabel(String locale) {
    final actual = _formatNumber(actualValue, locale);
    final target = _formatNumber(targetValue, locale);
    return '$actual / $target';
  }

  String _formatNumber(double value, String locale) {
    final safe = value.isFinite ? value : 0;
    final isWhole = safe.truncateToDouble() == safe;
    if (isWhole) {
      return NumberFormat.decimalPattern(locale).format(safe.toInt());
    }
    return safe.toStringAsFixed(1);
  }
}

/// Round emoji badge in a colored ring. Mirrors V1's
/// `_AchievementEmojiBadge` look so the V2 detail reads as the same
/// surface even though it lives in a different module.
class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({
    required this.emoji,
    required this.color,
    required this.unlocked,
  });

  final String emoji;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: unlocked ? 0.14 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: unlocked ? 0.40 : 0.22),
          width: 1.5,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 16)]
            : null,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.progress,
    required this.label,
    required this.color,
  });

  final double progress;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressBar(
            value: progress,
            color: color,
            glow: color.withValues(alpha: 0.35),
            height: 4,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-reward row in the detail sheet's "TakÃ© odemkne" block and on
/// finale-reward expand panels (chapter / long-term).
///
/// Resolves the reward against [CosmeticCatalog] so the row shows the
/// real localized cosmetic name (e.g. "KÃ¡men Roklin") instead of the
/// generic palette / diamond glyph we use in collapsed chip strips.
/// Falls back to a generic reward-kind label when the id is not in the
/// cosmetics catalog (chapter unlocks, RPG-only types).
///
/// Tappable when [onTap] is set — finale reward blocks pass
/// [showEngineRewardPreviewSheet] so the player can inspect the
/// cosmetic asset and metadata even while it's still locked.
class EngineRewardDetailRow extends StatelessWidget {
  const EngineRewardDetailRow({
    super.key,
    required this.reward,
    required this.l10n,
    required this.unlocked,
    required this.accent,
    this.onTap,
  });

  final RewardDefinition reward;
  final AppLocalizations l10n;
  final bool unlocked;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lookup = _lookupCosmetic(reward);
    final name = lookup?.name(l10n) ?? _fallbackName(reward);
    final rarity = lookup?.rarity.label(l10n);
    final typeLabel = lookup?.type.label(l10n) ?? _kindLabel(reward, l10n);
    final subtitle = rarity == null ? typeLabel : '$typeLabel · $rarity';
    final cosmeticId = _cosmeticIdOf(reward);
    final opacity = unlocked ? 1.0 : 0.74;

    final tap = onTap;
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
            // Real cosmetic art when we can resolve it — otherwise a
            // type-appropriate placeholder glyph. Keeps the row useful
            // even for reward ids that ship without an image yet.
            if (cosmeticId != null)
              CosmeticAssetThumb(
                cosmeticId: cosmeticId,
                size: 38,
                borderRadius: 8,
                dimmed: !unlocked,
                fallbackIcon: _iconForReward(reward),
                fallbackColor: accent,
              )
            else
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(_iconForReward(reward),
                    size: 18, color: accent.withValues(alpha: 0.92)),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      fontWeight: FontWeight.w600,
                      color: Tokens.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (tap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ] else if (!unlocked) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }

  /// Returns the cosmetic id when the reward references one, otherwise
  /// null so the row falls back to the typed icon.
  String? _cosmeticIdOf(RewardDefinition r) {
    return switch (r) {
      CosmeticReward(:final cosmeticId) => cosmeticId,
      EmblemReward(:final emblemId) => emblemId,
      TitleReward(:final titleId) => titleId,
      RelicReward(:final relicId) => relicId,
      CompanionAvailabilityReward(:final companionId) => companionId,
      _ => null,
    };
  }

  /// Localized type label when the cosmetic id isn't in the catalog —
  /// chapter unlocks, generic XP, or deleted entries. Mirrors the
  /// catalog [CosmeticType] vocabulary so the row reads consistently.
  String _kindLabel(RewardDefinition r, AppLocalizations l10n) {
    return switch (r) {
      XpReward() => 'XP',
      BonusXpReward() => 'XP',
      CosmeticReward() => l10n.cosmeticTypeFrame,
      ChapterUnlockReward() => l10n.progQuestsChapterHeader,
      CompanionAvailabilityReward() => l10n.cosmeticTypeCompanion,
      TitleReward() => l10n.cosmeticTypeTitleFlair,
      EmblemReward() => l10n.cosmeticTypeEmblem,
      RelicReward() => l10n.cosmeticTypeRelic,
    };
  }

  Cosmetic? _lookupCosmetic(RewardDefinition r) {
    final id = switch (r) {
      CosmeticReward(:final cosmeticId) => cosmeticId,
      EmblemReward(:final emblemId) => emblemId,
      TitleReward(:final titleId) => titleId,
      RelicReward(:final relicId) => relicId,
      CompanionAvailabilityReward(:final companionId) => companionId,
      _ => null,
    };
    if (id == null) return null;
    return const CosmeticCatalog().byId(id);
  }

  static IconData _iconForReward(RewardDefinition r) {
    return switch (r) {
      XpReward() => Icons.bolt_rounded,
      BonusXpReward() => Icons.bolt_rounded,
      CosmeticReward() => Icons.card_giftcard_rounded,
      ChapterUnlockReward() => Icons.menu_book_rounded,
      CompanionAvailabilityReward() => Icons.groups_2_rounded,
      TitleReward() => Icons.workspace_premium_rounded,
      EmblemReward() => Icons.military_tech_rounded,
      RelicReward() => Icons.diamond_rounded,
    };
  }

  /// Last-resort label when the catalog has no entry for the id —
  /// either the cosmetic was deleted or the reward type ships its own
  /// id space (chapter unlocks). Falls back to the raw id so the row
  /// is still readable rather than blank.
  String _fallbackName(RewardDefinition r) {
    return switch (r) {
      CosmeticReward(:final cosmeticId) => cosmeticId,
      EmblemReward(:final emblemId) => emblemId,
      TitleReward(:final titleId) => titleId,
      RelicReward(:final relicId) => relicId,
      CompanionAvailabilityReward(:final companionId) => companionId,
      ChapterUnlockReward(:final chapterId) => chapterId,
      XpReward() => 'XP',
      BonusXpReward() => 'XP',
    };
  }
}

/// Reward preview sheet for chain finale rewards.
///
/// When the reward resolves to a cosmetic via [CosmeticCatalog], we
/// open the canonical [CosmeticDetailsSheet] so the inventory and the
/// quest screen share one detail surface — locked finale rewards show
/// the cosmetic's `unlockHint` (e.g. "DokonÄi LesnÃ­ zkouÅ¡ku") instead
/// of a redundant bespoke layout. Falls back to a minimal local sheet
/// only when the reward has no cosmetic backing (chapter unlocks, raw
/// XP previews).
Future<void> showEngineRewardPreviewSheet(
  BuildContext context, {
  required RewardDefinition reward,
  required bool unlocked,
  required Color accent,
  required AppLocalizations l10n,
}) {
  final cosmeticId = switch (reward) {
    CosmeticReward(:final cosmeticId) => cosmeticId,
    EmblemReward(:final emblemId) => emblemId,
    TitleReward(:final titleId) => titleId,
    RelicReward(:final relicId) => relicId,
    CompanionAvailabilityReward(:final companionId) => companionId,
    _ => null,
  };
  final definition =
      cosmeticId == null ? null : const CosmeticCatalog().byId(cosmeticId);
  final cosmeticsState = context.read<CosmeticsProvider>().state;
  if (definition != null && cosmeticsState != null) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CosmeticDetailsSheet(
        definition: definition,
        state: cosmeticsState,
        l10n: l10n,
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RewardPreviewSheet(
      reward: reward,
      unlocked: unlocked,
      accent: accent,
      l10n: l10n,
    ),
  );
}

class _RewardPreviewSheet extends StatelessWidget {
  const _RewardPreviewSheet({
    required this.reward,
    required this.unlocked,
    required this.accent,
    required this.l10n,
  });

  final RewardDefinition reward;
  final bool unlocked;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cosmeticId = switch (reward) {
      CosmeticReward(:final cosmeticId) => cosmeticId,
      EmblemReward(:final emblemId) => emblemId,
      TitleReward(:final titleId) => titleId,
      RelicReward(:final relicId) => relicId,
      CompanionAvailabilityReward(:final companionId) => companionId,
      _ => null,
    };
    final lookup =
        cosmeticId == null ? null : const CosmeticCatalog().byId(cosmeticId);
    final name = lookup?.name(l10n) ??
        switch (reward) {
          CosmeticReward(:final cosmeticId) => cosmeticId,
          EmblemReward(:final emblemId) => emblemId,
          TitleReward(:final titleId) => titleId,
          RelicReward(:final relicId) => relicId,
          CompanionAvailabilityReward(:final companionId) => companionId,
          ChapterUnlockReward(:final chapterId) => chapterId,
          XpReward() => 'XP',
          BonusXpReward() => 'XP',
        };
    final typeLabel = lookup?.type.label(l10n) ??
        switch (reward) {
          XpReward() => 'XP',
          BonusXpReward() => 'XP',
          CosmeticReward() => l10n.cosmeticTypeFrame,
          ChapterUnlockReward() => l10n.progQuestsChapterHeader,
          CompanionAvailabilityReward() => l10n.cosmeticTypeCompanion,
          TitleReward() => l10n.cosmeticTypeTitleFlair,
          EmblemReward() => l10n.cosmeticTypeEmblem,
          RelicReward() => l10n.cosmeticTypeRelic,
        };
    final rarity = lookup?.rarity.label(l10n);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final color = unlocked ? accent : Tokens.onSurfaceMuted;

    final fallbackIcon = switch (reward) {
      XpReward() => Icons.bolt_rounded,
      BonusXpReward() => Icons.bolt_rounded,
      CosmeticReward() => Icons.card_giftcard_rounded,
      ChapterUnlockReward() => Icons.menu_book_rounded,
      CompanionAvailabilityReward() => Icons.groups_2_rounded,
      TitleReward() => Icons.workspace_premium_rounded,
      EmblemReward() => Icons.military_tech_rounded,
      RelicReward() => Icons.diamond_rounded,
    };

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: Tokens.spaceLg),
            if (cosmeticId != null)
              CosmeticAssetThumb(
                cosmeticId: cosmeticId,
                size: 140,
                borderRadius: 20,
                dimmed: !unlocked,
                fallbackIcon: fallbackIcon,
                fallbackColor: color,
              )
            else
              Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child:
                    Icon(fallbackIcon, size: 56, color: color),
              ),
            const SizedBox(height: Tokens.spaceLg),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _InfoPill(label: typeLabel, color: color),
                if (rarity != null) _InfoPill(label: rarity, color: color),
                _InfoPill(
                  label: unlocked
                      ? l10n.progAchievementStatusUnlocked
                      : l10n.progAchievementStatusInProgress,
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Localized label for a [CosmeticType] — used by the detail sheet's
/// reward rows so each cosmetic reads as e.g. "RÃ¡meÄek Â· VzÃ¡cnÃ½".
extension _CosmeticTypeLabel on CosmeticType {
  String label(AppLocalizations l10n) {
    return switch (this) {
      CosmeticType.frame => l10n.cosmeticTypeFrame,
      CosmeticType.relic => l10n.cosmeticTypeRelic,
      CosmeticType.background => l10n.cosmeticTypeBackground,
      CosmeticType.emblem => l10n.cosmeticTypeEmblem,
      CosmeticType.companion => l10n.cosmeticTypeCompanion,
      CosmeticType.titleFlair => l10n.cosmeticTypeTitleFlair,
      CosmeticType.mapEffect => l10n.cosmeticTypeMapEffect,
    };
  }
}
