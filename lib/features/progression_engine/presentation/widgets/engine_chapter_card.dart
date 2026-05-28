import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/progression/player/player_quest_lifecycle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/catalog/content/quest_assets.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_policies.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'engine_companion_pill.dart';
import 'expandable_quest_card.dart';
import 'expanded_quest_scope.dart';

/// Maps the pure-domain [ChainStepIcon] enum to the Material `Icons.…`
/// constant the chain preview row renders. The enum lives in
/// `lib/domain/progression/catalog/quest_policies.dart` so the Quest
/// catalog row can stay free of [IconData] (a Flutter type).
IconData? _chainStepIconData(ChainStepIcon? icon) {
  switch (icon) {
    case null:
      return null;
    case ChainStepIcon.opener:
      return Icons.play_arrow_rounded;
    case ChainStepIcon.finale:
      return Icons.shield_rounded;
    case ChainStepIcon.comboFlag:
      return Icons.flag_rounded;
  }
}

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
    required this.pillKey,
    required this.onClaim,
    this.onToggle,
    this.companionBuffBonus = 0,
    this.missingChapterName,
  });

  final EngineQuestProgress quest;

  /// Full chain in chainOrder. Used to render the row of dots
  /// beneath the progress bar (one dot per step).
  final List<EngineQuestProgress> chain;

  final AppLocalizations l10n;
  final GlobalKey pillKey;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;

  /// Tap handler for the entire card. Expanded state itself is pulled
  /// from [ExpandedQuestScope] inside [build] so toggling expansion
  /// only marks the two affected cards dirty.
  final VoidCallback? onToggle;

  /// Projected companion-buff bonus surfaced as a chip beside the
  /// headline pill. Defaults to 0 (chip hidden). Owner: parent
  /// screen, which has access to the engine provider.
  final int companionBuffBonus;

  /// Display-name of the previous chapter the player still needs to
  /// finish. Non-null only on the 50% "partial opener" projection
  /// where the prereq gate is the missing condition. Owned by the
  /// screen because resolving the name requires a provider lookup.
  final String? missingChapterName;

  @override
  Widget build(BuildContext context) {
    final quest = this.quest;
    final isExpanded = ExpandedQuestScope.isExpanded(context, quest.nodeId);
    final domain = quest.domain ?? ProgressionDomain.activity;
    final accent = domain.color;
    final chapterId = quest.node.chapterId ?? quest.node.chainId ?? '';
    final bgAsset = chapterBgAssetFor(chapterId);
    // Partial-opener projection: 2-gate chapter where one of two
    // unlock conditions is met but not both. Surfaces in the active
    // chapter section at 50% progress with a hint banner pointing at
    // the missing gate — the opener still auto-claims only when both
    // gates pass. See ProgressionEngineProvider._partialOpenerProgress.
    final isPartialOpener = quest.node is ChapterOpener &&
        (quest.levelGate != null || quest.prereqGateNodeId != null);
    // Lock chip path is reserved for the legacy "level-gate only"
    // chapter card. Partial openers DON'T use it (they own the 50%
    // hint banner instead), and fully locked chapters now live in
    // the NextChapterLockedTeaser, not this card.
    final isLocked = quest.levelGate != null && !isPartialOpener;
    // Asset size + description maxLines locked to the collapsed values
    // across expand state — resizing the icon and re-wrapping the
    // description during `AnimatedSize` was forcing a header relayout
    // per frame that read as a micro-stutter at the start of the
    // animation. The expanded panel surfaces additional content below
    // without touching anything in the collapsed area.
    const assetSize = Tokens.questAssetCollapsed;

    // Direct non-XP rewards authored on this step (typically the
    // finale's emblem). Drives the companion pill under the XP pill.
    final directNonXpRewards = [
      for (final r in quest.node.rewards)
        if (r is! XpReward) r,
    ];
    // Chain finale non-XP rewards — surfaced in the expanded body so
    // even when the active step is XP-only the player can see what's
    // waiting at the end (e.g. emblem_forest_mark on forest_trial_finale).
    final finaleRewards = chain.isEmpty
        ? const <RewardDefinition>[]
        : [
            for (final r in chain.last.node.rewards)
              if (r is! XpReward) r,
          ];
    // Chapter cards are always expandable when the player can interact
    // (not level-locked) — the chapter wraps a multi-step chain so
    // there's always something useful in the expanded body: the full
    // description, the chain context, and the finale reward. The
    // original "only expand for non-XP" rule made pure-XP steps look
    // unfinished and hid where the chain was heading.
    final canExpand = !isLocked && onToggle != null;

    return ExpandableQuestCard(
      nodeId: quest.nodeId,
      onToggle: onToggle,
      canExpand: canExpand,
      collapsedBorderColor: Colors.white.withValues(alpha: 0.08),
      shadows: const [
        // Drop shadow blur reduced from 14 to Tokens.glowSm (8) because
        // the chapter card's `AnimatedSize` body re-grows the silhouette
        // every frame of the expand animation, forcing the shadow to
        // re-rasterize. A 14 px Gaussian blur on a card-sized rect
        // pushed the 120 Hz raster budget over 8.3 ms; the smaller
        // blur keeps it within. See Phase 0.2 of the UI refactor plan.
        BoxShadow(
          color: Color(0x52000000), // black 32%
          blurRadius: Tokens.glowSm,
          offset: Offset(0, 6),
        ),
      ],
      // Background image covers the entire card via a STATIC
      // DecoratedBox inside the template's ClipRRect — the same
      // pattern HeroProgressionHeader uses for its cosmetic
      // background. The outer AnimatedContainer keeps only color +
      // border + shadow + radius, so no per-frame BoxDecoration.lerp
      // touches the DecorationImage. The image just re-paints as a
      // textured quad as the card grows under AnimatedSize — a
      // near-constant GPU cost.
      //
      // `opacity` over `BlendMode.darken`: opacity is a single shader
      // multiply (cheap), BlendMode.darken is a per-pixel min-blend
      // pipeline op (was the Phase 0.3 suspect). The dark card color
      // shows through at 1 - opacity to give the darkened-art look.
      // Tweak these values if the art reads too bright / too dim.
      backgroundDecoration: bgAsset.isEmpty
          ? null
          : BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgAsset),
                fit: BoxFit.cover,
                opacity: isLocked ? 0.30 : 0.52,
              ),
            ),
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChapterIcon(node: quest.node, size: assetSize),
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
                  // Clamped to 2 lines + ellipsis in both states so the
                  // header doesn't reflow when the card expands (the
                  // re-wrap was a per-frame layout cost during
                  // `AnimatedSize`). The full description belongs in
                  // the expanded body if a future revision wants it
                  // surfaced.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
          // Right column: lock chip when level-gated, otherwise XP pill
          // on top with an optional reward pill below for chapters that
          // carry a non-XP reward (finale emblem / cosmetic). The pill
          // replaces the legacy chevron — chapters with only XP have no
          // expand affordance at all (user rule).
          if (isLocked)
            _LockChip(level: quest.levelGate!, l10n: l10n)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                XpClaimPill(
                  key: pillKey,
                  data: _pillData(companionBonus: companionBuffBonus),
                ),
                // The companion pill below the XP pill surfaces a non-XP
                // reward directly on *this* step (e.g. finale emblem) —
                // distinct from the chain finale reward, which the
                // expanded body shows separately. The pill also doubles
                // as the expand arrow so the player has a clear tap
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
                  // No direct reward to badge — show a plain chevron so
                  // the card still has a visible expand affordance.
                  // Without this, pure-XP chapter steps would look
                  // unexpandable even though tapping the row works.
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
      // Chain preview between the title row and the progress bar (V1
      // layout) so the player sees their position in the chain at a
      // glance — the progress bar still belongs immediately above the
      // next visual primitive.
      chainPreview: chain.length > 1
          ? Padding(
              padding: EdgeInsets.only(
                top: Tokens.spaceSm,
                left: assetSize + Tokens.spaceMd,
              ),
              child: EngineChapterChainPreview(
                chain: chain,
                currentNodeId: quest.node.id,
                accent: accent,
                l10n: l10n,
              ),
            )
          : null,
      progressRow: isLocked
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: Tokens.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPartialOpener) ...[
                    _PartialOpenerHint(
                      levelGate: quest.levelGate,
                      missingChapterName: missingChapterName,
                      accent: accent,
                      l10n: l10n,
                    ),
                    const SizedBox(height: Tokens.spaceSm),
                  ],
                  _ProgressRow(quest: quest, accent: accent),
                ],
              ),
            ),
      expandedBody: _ChapterExpandedDetails(
        quest: quest,
        accent: accent,
        finaleRewards: finaleRewards,
        // Chapter title comes from the chain's open node (chainOrder 0)
        // — the chapter's own titleKey lives there, not on per-step
        // nodes. Used as the expanded-body eyebrow so the player sees
        // "Stezka poutníka" instead of a redundant step number that
        // just mirrors the chain dots above.
        chapterTitle: chain.isEmpty
            ? null
            : chain.first.node.titleKey(l10n),
        l10n: l10n,
      ),
    );
  }


  XpClaimPillData _pillData({required int companionBonus}) {
    return switch (quest.lifecycle) {
      QuestClaimed(:final finalXp) => XpClaimPillData.claimed(finalXp),
      QuestCompletedPendingClaim(:final previewXp) =>
        XpClaimPillData.claimable(
          previewXp,
          onTap: (center) => onClaim(quest, from: center),
          companionBonus: companionBonus,
        ),
      QuestAvailable() || QuestLocked() =>
        XpClaimPillData.locked(quest.previewXp,
            companionBonus: companionBonus),
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

/// Inline hint banner for partial-opener chapter cards (one of two
/// unlock conditions met). Surfaces "Chybí: Dosáhni úrovně X" or
/// "Chybí: Dokonči `<chapter>`" so the player sees the missing gate
/// without expanding the card. Rendered above the 50% progress bar.
class _PartialOpenerHint extends StatelessWidget {
  const _PartialOpenerHint({
    required this.levelGate,
    required this.missingChapterName,
    required this.accent,
    required this.l10n,
  });

  final int? levelGate;
  final String? missingChapterName;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final String detail;
    if (levelGate != null) {
      detail = l10n.progChapterHintReachLevel(levelGate!);
    } else if (missingChapterName != null) {
      detail = l10n.progChapterHintFinishChapter(missingChapterName!);
    } else {
      detail = l10n.progChapterHintGeneric;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.spaceSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: accent.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_open_rounded,
            size: 13,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.progChapterHintHeader}: ',
                    style: TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.66),
                      letterSpacing: 0.6,
                    ),
                  ),
                  TextSpan(
                    text: detail,
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

    final iconForStep = _chainStepIconData(quest.node.chainStepIcon);
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
      // Text-bearing pill — give the label some horizontal room so the
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
        // Pill shape — collapses to a circle when content is a single
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

    // No surrounding container chrome — the previous black-tinted box
    // with white-8% border felt like a panel sitting on top of the
    // chapter art. A thin hairline divider above the content reads as
    // a continuation of the card, matching the daily-quests divider
    // pattern in HeroProgressionHeader's expanded section.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 10),
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
            color: Colors.white.withValues(alpha: 0.82),
            text: lockedHint,
          ),
          if (hasFinale) const SizedBox(height: 8),
        ],
        if (hasFinale) ...[
          Text(
            l10n.progQuestChainFinaleReward.toUpperCase(),
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.72),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          // Rich reward rows — each shows the resolved cosmetic asset
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
