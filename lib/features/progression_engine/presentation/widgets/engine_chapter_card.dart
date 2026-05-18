import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/progression/player/player_quest_lifecycle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../domain/progression_domain.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/catalog/content/quest_assets.dart';
import '../../domain/models/progression_node_definition.dart';
import '../../domain/models/reward_definition.dart';
import 'engine_companion_pill.dart';

/// Chapter quest card with parallax-style background, large chapter
/// icon, and a horizontal chain preview row beneath the progress bar.
///
/// Functionally a peer of [EngineQuestCard] but specialised for the
/// chapter display bucket. Kept as a separate file because the layout
/// ergonomics differ enough (background image, full-width row of chain
/// dots) that a single configurable card would just be noisier.
class EngineChapterCard extends StatelessWidget {
  const EngineChapterCard({
    super.key,
    required this.quest,
    required this.chain,
    required this.l10n,
    required this.enabled,
    required this.pillKey,
    required this.onClaim,
    this.isExpanded = false,
    this.onToggle,
  });

  final EngineQuestProgress quest;

  /// Full chain in chainOrder. Used to render the row of dots
  /// beneath the progress bar (one dot per step).
  final List<EngineQuestProgress> chain;

  final AppLocalizations l10n;
  final bool enabled;
  final GlobalKey pillKey;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final quest = this.quest;
    final domain = quest.domain ?? ProgressionDomain.activity;
    final accent = domain.color;
    final chapterId = quest.node.chapterId ?? quest.node.chainId ?? '';
    final bgAsset = chapterBgAssetFor(chapterId);
    final isLocked = quest.levelGate != null;

    // Direct non-XP rewards authored on this step (typically the
    // finale's emblem). Drives the companion pill under the XP pill.
    final directNonXpRewards = [
      for (final r in quest.node.rewards)
        if (r is! XpReward) r,
    ];
    // Chain finale non-XP rewards â€” surfaced in the expanded body so
    // even when the active step is XP-only the player can see what's
    // waiting at the end (e.g. emblem_forest_mark on forest_trial_finale).
    final finaleRewards = chain.isEmpty
        ? const <RewardDefinition>[]
        : [
            for (final r in chain.last.node.rewards)
              if (r is! XpReward) r,
          ];
    // Chapter cards are always expandable when the player can interact
    // (not level-locked) â€” the chapter wraps a multi-step chain so
    // there's always something useful in the expanded body: the full
    // description, the chain context, and the finale reward. The
    // original "only expand for non-XP" rule made pure-XP steps look
    // unfinished and hid where the chain was heading.
    final canExpand = !isLocked && onToggle != null;

    return GestureDetector(
      onTap: canExpand ? onToggle : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(Tokens.questCardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF111423),
          image: bgAsset.isEmpty
              ? null
              : DecorationImage(
                  image: AssetImage(bgAsset),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: isLocked ? 0.62 : 0.42),
                    BlendMode.darken,
                  ),
                ),
          borderRadius: BorderRadius.circular(Tokens.questCardRadius),
          border: Border.all(
            color: isExpanded
                ? Tokens.accent.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChapterIcon(
                  node: quest.node,
                  size: isExpanded
                      ? Tokens.questAssetExpanded
                      : Tokens.questAssetCollapsed,
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.node.titleKey(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        quest.node.descriptionKey(l10n),
                        // No clamp when expanded â€” chapter step
                        // descriptions tend to spill past two lines
                        // and a "..." in the open state told the
                        // player nothing about what comes next.
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                // Right column: lock chip when level-gated, otherwise
                // XP pill on top with an optional reward pill below
                // for chapters that carry a non-XP reward (finale
                // emblem / cosmetic). The pill replaces the legacy
                // chevron â€” chapters with only XP have no expand
                // affordance at all (user rule).
                if (isLocked)
                  _LockChip(level: quest.levelGate!, l10n: l10n)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      XpClaimPill(key: pillKey, data: _pillData()),
                      // The companion pill below the XP pill surfaces
                      // a non-XP reward directly on *this* step (e.g.
                      // finale emblem) â€” distinct from the chain
                      // finale reward, which the expanded body shows
                      // separately. The pill also doubles as the
                      // expand arrow so the player has a clear tap
                      // target on rewarded steps.
                      if (canExpand && directNonXpRewards.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        EngineCompanionPill(
                          badge: badgeForReward(directNonXpRewards.first),
                          expanded: isExpanded,
                          onTap: onToggle!,
                          accent: accent,
                        ),
                      ] else if (canExpand) ...[
                        // No direct reward to badge â€” show a plain
                        // chevron so the card still has a visible
                        // expand affordance. Without this, pure-XP
                        // chapter steps would look unexpandable even
                        // though tapping the row works.
                        const SizedBox(height: 4),
                        ExpandChevron(
                          expanded: isExpanded,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 18,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            // Chain preview between the title row and the progress bar
            // (V1 layout) so the player sees their position in the
            // chain at a glance â€” the progress bar still belongs
            // immediately above the next visual primitive.
            if (chain.length > 1) ...[
              const SizedBox(height: Tokens.spaceSm),
              Padding(
                padding: EdgeInsets.only(
                  left: (isExpanded
                          ? Tokens.questAssetExpanded
                          : Tokens.questAssetCollapsed) +
                      Tokens.spaceMd,
                ),
                child: EngineChapterChainPreview(
                  chain: chain,
                  currentNodeId: quest.node.id,
                  accent: accent,
                  l10n: l10n,
                ),
              ),
            ],
            const SizedBox(height: Tokens.spaceSm),
            if (!isLocked) _ProgressRow(quest: quest, accent: accent),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: Tokens.spaceSm),
                      child: _ChapterExpandedDetails(
                        quest: quest,
                        accent: accent,
                        finaleRewards: finaleRewards,
                        // Chapter title comes from the chain's open
                        // node (chainOrder 0) — the chapter's own
                        // titleKey lives there, not on per-step nodes.
                        // Used as the expanded-body eyebrow so the
                        // player sees "Stezka poutníka" instead of a
                        // redundant step number that just mirrors the
                        // chain dots above.
                        chapterTitle: chain.isEmpty
                            ? null
                            : chain.first.node.titleKey(l10n),
                        l10n: l10n,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  XpClaimPillData _pillData() {
    return switch (quest.lifecycle) {
      QuestClaimed(:final finalXp) => XpClaimPillData.claimed(finalXp),
      QuestCompletedPendingClaim(:final previewXp) when enabled =>
        XpClaimPillData.claimable(
          previewXp,
          onTap: (center) => onClaim(quest, from: center),
        ),
      QuestCompletedPendingClaim(:final previewXp) =>
        XpClaimPillData.locked(previewXp),
      QuestAvailable() || QuestLocked() =>
        XpClaimPillData.locked(quest.previewXp),
    };
  }
}

/// Replacement for the XP claim pill when the chapter card is gated
/// by a [LevelAtLeast] unlock condition the player hasn't reached.
/// Shows a lock glyph + "Lv 10" so the player knows what to aim for
/// without expanding the card.
class _LockChip extends StatelessWidget {
  const _LockChip({required this.level, required this.l10n});

  final int level;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.progChapterLockedLabel(level),
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterIcon extends StatelessWidget {
  const _ChapterIcon({required this.node, required this.size});

  final Quest node;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = node.assetKey;
    if (asset == null || asset.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child:
              const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.quest, required this.accent});

  final EngineQuestProgress quest;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context);

    // Same treatment as `EngineQuestCard._ProgressRow`: a completed
    // step (pinned by the chapter walker until midnight) replaces
    // the progress bar with a single "Splněno" line. Without this
    // the card kept showing a full progress bar + "1 / 1" label
    // after claim, which read like the chain was still actively
    // tracking instead of resting on its claimed step.
    if (quest.lifecycle is QuestClaimed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: accent.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.progQuestStatusClaimed,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: accent.withValues(alpha: 0.92),
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressBar(
          value: quest.progress,
          color: accent,
          glow: accent.withValues(alpha: 0.34),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _label(locale),
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w700,
              color: accent.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }

  String _label(String locale) {
    final actual = _formatNumber(quest.actualValue, locale);
    final target = _formatNumber(quest.targetValue, locale);
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

/// Horizontal chain visualization beneath the chapter card. Renders
/// one node per chain step with a small connector between dots; the
/// active step gets a glow ring, completed steps a check.
class EngineChapterChainPreview extends StatelessWidget {
  const EngineChapterChainPreview({
    super.key,
    required this.chain,
    required this.currentNodeId,
    required this.accent,
    required this.l10n,
  });

  final List<EngineQuestProgress> chain;
  final String currentNodeId;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chain.length; i++) ...[
              if (i > 0) _Connector(color: accent),
              _ChainNode(
                quest: chain[i],
                isCurrent: chain[i].node.id == currentNodeId,
                accent: accent,
                l10n: l10n,
              ),
            ],
          ],
        );
        if (!constraints.maxWidth.isFinite) {
          return Align(alignment: Alignment.centerLeft, child: row);
        }
        return SizedBox(
          width: constraints.maxWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: row,
            ),
          ),
        );
      },
    );
  }
}

class _ChainNode extends StatelessWidget {
  const _ChainNode({
    required this.quest,
    required this.isCurrent,
    required this.accent,
    required this.l10n,
  });

  final EngineQuestProgress quest;
  final bool isCurrent;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final completed = quest.lifecycle is QuestClaimed;
    // "Locked future" = not completed AND not the currently active step.
    // These render a lock glyph in place of any label so the player
    // doesn't read distant milestones (1M / 5M) as actionable. Explicit
    // chainStepIcon still wins so finale shields / opener arrows stay
    // legible.
    final isLocked = !completed && !isCurrent;
    final ring = isCurrent
        ? accent
        : completed
            ? accent.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.18);
    final fill = isCurrent
        ? accent.withValues(alpha: 0.28)
        : completed
            ? accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.05);

    final iconForStep = quest.node.chainStepIcon;
    final label = quest.node.chainStepLabelKey?.call(l10n);
    final glyphColor =
        isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.72);

    Widget glyph;
    double horizontalPadding = 0;
    if (completed) {
      glyph = Icon(Icons.check_rounded, size: 12, color: accent);
    } else if (isLocked && iconForStep == null) {
      // V1 parity: locked steps without an explicit icon collapse to a
      // small lock glyph instead of showing their target value.
      glyph = Icon(
        Icons.lock_rounded,
        size: 11,
        color: Colors.white.withValues(alpha: 0.48),
      );
    } else if (iconForStep != null) {
      glyph = Icon(iconForStep, size: 12, color: glyphColor);
    } else if (label != null && label.isNotEmpty) {
      // Text-bearing pill â€” give the label some horizontal room so the
      // dot stretches into a small pill (e.g. "100K", "25K") instead of
      // overflowing a fixed 22-wide circle.
      horizontalPadding = 5;
      glyph = Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: glyphColor,
          height: 1,
        ),
      );
    } else {
      glyph = Text(
        '·',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: glyphColor,
          height: 1,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        // Pill shape â€” collapses to a circle when content is a single
        // glyph (22Ã—22), stretches horizontally when the label needs
        // it. Drops the hard-coded width: 22.
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ring, width: isCurrent ? 1.6 : 1),
        boxShadow: isCurrent
            ? [BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 8)]
            : null,
      ),
      child: glyph,
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: color.withValues(alpha: 0.32),
    );
  }
}

/// Details panel revealed when the player expands a chapter card.
/// Mirrors the daily/weekly card's [_ExpandedDetails] but adds the
/// chain step label as a header line.
class _ChapterExpandedDetails extends StatelessWidget {
  const _ChapterExpandedDetails({
    required this.quest,
    required this.accent,
    required this.finaleRewards,
    required this.chapterTitle,
    required this.l10n,
  });

  final EngineQuestProgress quest;
  final Color accent;

  /// Non-XP rewards on the chain's finale step. Surfaced as a "Po
  /// dokonÄenÃ­ kapitoly" block so the player can see what waits at
  /// the end (emblem, relic, cosmetic) even while working a mid-chain
  /// step that only carries XP.
  final List<RewardDefinition> finaleRewards;

  /// Localized chapter title (e.g. "Stezka poutníka"). Rendered as
  /// the expanded-body eyebrow so the player learns which chapter
  /// they're inside without crowding the collapsed card. Replaces
  /// the previous chainStepLabel eyebrow, which only restated the
  /// chain-dot number already visible in the chain row above.
  final String? chapterTitle;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final lockedHint = quest.node.lockedHintKey?.call(l10n);

    final hasTitle = chapterTitle != null && chapterTitle!.isNotEmpty;
    final hasLockedHint = lockedHint != null && lockedHint.isNotEmpty;
    final hasFinale = finaleRewards.isNotEmpty;
    if (!hasTitle && !hasLockedHint && !hasFinale) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Text(
              chapterTitle!.toUpperCase(),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: 1.1,
              ),
            ),
            if (hasLockedHint || hasFinale) const SizedBox(height: 6),
          ],
          if (hasLockedHint) ...[
            _DetailLine(
              icon: Icons.lock_outline_rounded,
              color: Colors.white.withValues(alpha: 0.78),
              text: lockedHint,
            ),
            if (hasFinale) const SizedBox(height: 8),
          ],
          if (hasFinale) ...[
            Text(
              l10n.progQuestChainFinaleReward.toUpperCase(),
              style: const TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            // Rich reward rows â€” each shows the resolved cosmetic asset
            // (e.g. forest emblem), the localized name, and a chevron
            // that opens a read-only preview sheet. Lets the player
            // inspect what's waiting at the finale before they unlock
            // it, instead of staring at an anonymous icon chip.
            for (var i = 0; i < finaleRewards.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              EngineRewardDetailRow(
                reward: finaleRewards[i],
                l10n: l10n,
                unlocked: false,
                accent: accent,
                onTap: () => showEngineRewardPreviewSheet(
                  context,
                  reward: finaleRewards[i],
                  unlocked: false,
                  accent: accent,
                  l10n: l10n,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
