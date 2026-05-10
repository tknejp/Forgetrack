import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../../progression/domain/models/core_models.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/catalog/content/quest_assets.dart';
import '../../domain/models/progression_node_definition.dart';

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
    final domain = quest.domain ?? ProgressionDomain.activity;
    final accent = domain.color;
    final chapterId = quest.node.chapterId ?? quest.node.chainId ?? '';
    final bgAsset = chapterBgAssetFor(chapterId);

    return GestureDetector(
      onTap: onToggle,
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
                    Colors.black.withValues(alpha: 0.42),
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
                _ChapterIcon(node: quest.node, size: 44),
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
                        maxLines: isExpanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                XpClaimPill(key: pillKey, data: _pillData()),
                if (onToggle != null) ...[
                  const SizedBox(width: 6),
                  ExpandChevron(
                    expanded: isExpanded,
                    color: Colors.white.withValues(alpha: 0.78),
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: Tokens.spaceSm),
            _ProgressRow(quest: quest, accent: accent),
            if (chain.length > 1) ...[
              const SizedBox(height: Tokens.spaceSm),
              EngineChapterChainPreview(
                chain: chain,
                currentNodeId: quest.node.id,
                accent: accent,
                l10n: l10n,
              ),
            ],
          ],
        ),
      ),
    );
  }

  XpClaimPillData _pillData() {
    if (quest.isCompleted) {
      return XpClaimPillData.claimed(quest.previewXp);
    }
    if (quest.isAvailableForClaim && enabled) {
      return XpClaimPillData.claimable(
        quest.previewXp,
        onTap: (center) => onClaim(quest, from: center),
      );
    }
    return XpClaimPillData.locked(quest.previewXp);
  }
}

class _ChapterIcon extends StatelessWidget {
  const _ChapterIcon({required this.node, required this.size});

  final QuestNode node;
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
    final pct = (quest.progress * 100).clamp(0, 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _label(locale),
                style: const TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: Tokens.onSurfaceMuted,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w800,
                color: accent.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(
          value: quest.progress,
          color: accent,
          glow: accent.withValues(alpha: 0.34),
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
    final completed = quest.isCompleted;
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

    final label = quest.node.chainStepLabelKey?.call(l10n) ?? '·';

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: isCurrent ? 1.6 : 1),
        boxShadow: isCurrent
            ? [BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 8)]
            : null,
      ),
      child: completed
          ? Icon(Icons.check_rounded, size: 12, color: accent)
          : Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.72),
                height: 1,
              ),
            ),
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
