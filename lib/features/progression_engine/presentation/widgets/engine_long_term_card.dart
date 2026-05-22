import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/progression/player/player_quest_lifecycle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';
import '../widgets/progression_primitives.dart';
import '../../application/progression_engine_provider.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'engine_chapter_card.dart' show EngineChapterChainPreview;
import 'engine_companion_pill.dart';
import 'engine_reward_chip.dart';
import 'expanded_quest_scope.dart';

/// Long-term goal card.
///
/// Variant of [EngineQuestCard] specialised for the
/// "DLOUHODOBÃ‰ CÃLE" section. The differences from a daily/weekly
/// card:
///
/// - **Reward chip strip** under the description row that surfaces
///   every non-XP reward across the primary quest **and** any
///   companion node that shares the same objective. This is the V2
///   aggregate-display rule (Q rule: quest + achievement on the same
///   objective should not duplicate UI).
/// - **"TakÃ© odemkne"** panel revealed when the card is expanded.
///   Lists each companion node (typically the achievement on the
///   same objective) with its badge emoji, title, and its own reward
///   chips so the player sees the full picture.
class EngineLongTermCard extends StatelessWidget {
  const EngineLongTermCard({
    super.key,
    required this.entry,
    required this.chain,
    required this.l10n,
    required this.pillKey,
    required this.onClaim,
    this.onToggle,
    this.companionBuffBonus = 0,
  });

  final EngineLongTermEntry entry;

  /// Full chain (in chainOrder) the active quest belongs to, used to
  /// render the dot/connector row beneath the description. Empty list
  /// or one-element list when the quest is not part of a chain — the
  /// preview row hides.
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
  /// screen, mirroring the quest + chapter card pattern.
  final int companionBuffBonus;

  @override
  Widget build(BuildContext context) {
    final quest = entry.quest;
    final isExpanded = ExpandedQuestScope.isExpanded(context, quest.nodeId);
    final domain = quest.domain ?? ProgressionDomain.steps;
    final accent = domain.color;

    final directNonXpRewards = [
      for (final r in quest.node.rewards)
        if (r is! XpReward) r,
    ];
    // Chain-finale non-XP rewards (e.g. Worldwalker frame on the
    // chain's last step) — surfaced as a "Po dokonÄenÃ­ Å™ady" block
    // so a mid-chain step still advertises what waits at the end.
    final finaleRewards = chain.isEmpty
        ? const <RewardDefinition>[]
        : [
            for (final r in chain.last.node.rewards)
              if (r is! XpReward) r,
          ];
    // First chain step the player hasn't yet touched. Drives the
    // expanded panel's "Next step locked because…" hint so chained
    // long-term quests never look stuck without explanation.
    EngineQuestProgress? nextLockedStep;
    for (final q in chain) {
      final lifecycle = q.lifecycle;
      final isUntouched =
          lifecycle is QuestLocked || lifecycle is QuestAvailable;
      if (isUntouched && q.nodeId != quest.nodeId) {
        nextLockedStep = q;
        break;
      }
    }
    final hasExtraContent = entry.companions.isNotEmpty ||
        directNonXpRewards.isNotEmpty ||
        finaleRewards.isNotEmpty ||
        nextLockedStep != null ||
        chain.length > 1;
    final canExpand = hasExtraContent && onToggle != null;

    // Per-card RepaintBoundary — see [engine_quest_card.dart] for the
    // rationale (scroll + sibling expand isolation).
    return RepaintBoundary(
      child: GestureDetector(
        onTap: canExpand ? onToggle : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(Tokens.questCardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF111423),
          borderRadius: BorderRadius.circular(Tokens.questCardRadius),
          border: Border.all(
            color: isExpanded
                ? Tokens.accent.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            // Single static drop shadow — the previous conditional
            // accent glow re-rasterized a 22 px Gaussian blur per
            // frame of the expand animation. See engine_quest_card.dart
            // for the same change + rationale.
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Leading(
                  node: quest.node,
                  domain: domain,
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        quest.node.descriptionKey(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                // Right column: XP pill on top, companion pill(s) below.
                // The companion pill replaces the legacy stand-alone
                // chevron — it's both the "extra reward exists" hint
                // and the expand toggle.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    XpClaimPill(
                      key: pillKey,
                      data: _pillData(companionBonus: companionBuffBonus),
                    ),
                    if (canExpand) ...[
                      const SizedBox(height: 4),
                      ..._buildCompanionPills(
                        directNonXp: directNonXpRewards,
                        accent: accent,
                        isExpanded: isExpanded,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Chain preview row — same visual as the chapter card so
            // chained long-term goals (lifetime steps, XP milestones,
            // reward hunter) read the same as chapter chains. Hidden
            // for orphan long-term quests with no chain.
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
            _ProgressRow(quest: quest, accent: accent),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Tokens.spaceSm),
                        child: _LongTermExpanded(
                          entry: entry,
                          quest: quest,
                          accent: accent,
                          nextLockedStep: nextLockedStep,
                          finaleRewards: finaleRewards,
                          l10n: l10n,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Stack of [EngineCompanionPill]s rendered under the XP pill.
  ///
  /// One pill per companion node (capped at 2 to keep the right
  /// column tidy — overflow surfaces in the expanded panel). When the
  /// quest has no companions but carries a non-XP direct reward, a
  /// single fallback pill is rendered using the reward kind's emoji.
  List<Widget> _buildCompanionPills({
    required List<RewardDefinition> directNonXp,
    required Color accent,
    required bool isExpanded,
  }) {
    final pills = <Widget>[];
    final tap = onToggle ?? () {};

    for (final c in entry.companions.take(2)) {
      if (pills.isNotEmpty) pills.add(const SizedBox(height: 4));
      pills.add(EngineCompanionPill(
        badge: badgeForCompanion(c),
        expanded: isExpanded,
        onTap: tap,
        accent: accent,
      ));
    }
    if (pills.isEmpty && directNonXp.isNotEmpty) {
      pills.add(EngineCompanionPill(
        badge: badgeForReward(directNonXp.first),
        expanded: isExpanded,
        onTap: tap,
        accent: accent,
      ));
    }
    return pills;
  }

  XpClaimPillData _pillData({required int companionBonus}) {
    final quest = entry.quest;
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

/// Combined expanded-body content for the long-term card. Stacks
/// (in order, only the populated chunks):
///
/// 1. **Next-step hint** — names the first locked chain step and
///    explains the gate (uses node's `lockedHintKey` when authored,
///    otherwise the generic "complete the previous step" copy). Keeps
///    chained long-term quests from looking stuck without
///    explanation.
/// 2. **Companion list** ("TakÃ© odemkne") — sibling nodes that share
///    the active step's objective. Each row opens the V2 companion
///    detail sheet.
/// 3. **Chain finale rewards** — non-XP rewards on the chain's last
///    step (e.g. Worldwalker frame). Surfaced as a chip strip under
///    a "Chapter finale reward" header so the player can see what
///    waits at the end while working a mid-chain step.
class _LongTermExpanded extends StatelessWidget {
  const _LongTermExpanded({
    required this.entry,
    required this.quest,
    required this.accent,
    required this.nextLockedStep,
    required this.finaleRewards,
    required this.l10n,
  });

  final EngineLongTermEntry entry;
  final EngineQuestProgress quest;
  final Color accent;
  final EngineQuestProgress? nextLockedStep;
  final List<RewardDefinition> finaleRewards;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];

    if (nextLockedStep != null) {
      blocks.add(_NextStepHint(node: nextLockedStep!.node, l10n: l10n));
    }

    if (entry.companions.isNotEmpty) {
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: Tokens.spaceSm));
      blocks.add(_AlsoUnlocks(
        companions: entry.companions,
        quest: quest,
        accent: accent,
        l10n: l10n,
      ));
    }

    if (finaleRewards.isNotEmpty) {
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: Tokens.spaceSm));
      blocks.add(_FinaleRewards(rewards: finaleRewards, accent: accent, l10n: l10n));
    }

    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

/// Inline hint naming the first locked chain step and the reason it
/// can't be worked on yet. Falls back to the authored
/// [Quest.lockedHintKey] when set (e.g. "VyÅ¾aduje level 10"),
/// otherwise the generic "SplÅˆ pÅ™edchozÃ­ krok" copy.
class _NextStepHint extends StatelessWidget {
  const _NextStepHint({required this.node, required this.l10n});

  final Quest node;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final authoredHint = node.lockedHintKey?.call(l10n);
    final hint = (authoredHint != null && authoredHint.isNotEmpty)
        ? authoredHint
        : l10n.progQuestNextStepLocked;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.48),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.progQuestNextStep}: ${node.titleKey(l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: Tokens.onSurfaceMuted,
                    height: 1.4,
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

/// Companions block — same shape as the legacy "TakÃ© odemkne" panel
/// kept its own class so the [_LongTermExpanded] orchestrator only
/// stitches blocks together.
class _AlsoUnlocks extends StatelessWidget {
  const _AlsoUnlocks({
    required this.companions,
    required this.quest,
    required this.accent,
    required this.l10n,
  });

  final List<ProgressionEntry> companions;
  final EngineQuestProgress quest;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Resolve completion state once for the whole companion list so
    // each row doesn't punch through to the provider in its own build.
    final completed =
        context.read<ProgressionEngineProvider>().completedNodeIds;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.progQuestsLongTermAlsoUnlocks.toUpperCase(),
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w900,
              color: Tokens.onSurfaceMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < companions.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _CompanionRow(
              node: companions[i],
              quest: quest,
              accent: accent,
              l10n: l10n,
              isUnlocked: completed.contains(companions[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Po dokonÄenÃ­ Å™ady" block — surfaces the chain's last step's
/// non-XP rewards as chips. Mirrors the chapter card's "PO DOKONÄŒENÃ
/// KAPITOLY" footer so the player sees what's waiting at the end
/// regardless of which step they're currently working on.
class _FinaleRewards extends StatelessWidget {
  const _FinaleRewards({
    required this.rewards,
    required this.accent,
    required this.l10n,
  });

  final List<RewardDefinition> rewards;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < rewards.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            EngineRewardDetailRow(
              reward: rewards[i],
              l10n: l10n,
              unlocked: false,
              accent: accent,
              onTap: () => showEngineRewardPreviewSheet(
                context,
                reward: rewards[i],
                unlocked: false,
                accent: accent,
                l10n: l10n,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompanionRow extends StatelessWidget {
  const _CompanionRow({
    required this.node,
    required this.quest,
    required this.accent,
    required this.l10n,
    required this.isUnlocked,
  });

  final ProgressionEntry node;
  final EngineQuestProgress quest;
  final Color accent;
  final AppLocalizations l10n;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final emoji = badgeForCompanion(node);
    final nonXp = [
      for (final r in node.rewards)
        if (r is! XpReward) r,
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showEngineCompanionDetailSheet(
        context,
        node: node,
        actualValue: quest.actualValue,
        targetValue: quest.targetValue,
        progress: quest.progress,
        isUnlocked: isUnlocked,
        accent: accent,
        l10n: l10n,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.titleKey(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (nonXp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  EngineRewardChipStrip(
                    rewards: nonXp,
                    accent: Tokens.onSurfaceMuted,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ],
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.node,
    required this.domain,
    required this.size,
  });

  final Quest node;
  final ProgressionDomain domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = node.assetKey;
    if (asset == null || asset.isEmpty) {
      return ProgDomIco(domain: domain, size: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ProgDomIco(domain: domain, size: size),
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
            _progressLabel(locale),
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

  String _progressLabel(String locale) {
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
