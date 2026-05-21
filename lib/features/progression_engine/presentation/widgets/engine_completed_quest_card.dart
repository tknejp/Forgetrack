import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/progression/player/player_quest_lifecycle.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/features/progression_engine/domain/progression_domain_chrome.dart';
import '../widgets/progression_primitives.dart';
import '../../application/progression_engine_provider.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'engine_chapter_card.dart' show EngineChapterChainPreview;
import 'engine_companion_pill.dart';

/// Compact, expandable card rendered inside the DOKONČENÉ QUESTY
/// section. One card per [EngineCompletedEntry] — a single quest or
/// an aggregated chain.
///
/// Collapsed layout:
///
/// ```
/// [asset] Title                               [+750 XP] [chevron]
///         Dokončeno 12 kvě · 23:11
/// ```
///
/// The pill goes "claimable" (gold + clickable, sparkle to the bar
/// key) when [EngineCompletedEntry.hasClaimable] is true, otherwise
/// "claimed" (greyed, check icon, total XP credited).
///
/// Expanded layout adds — beneath the title row:
///
/// 1. Description.
/// 2. Chain preview row (only when the entry represents an actual
///    chain — single-quest entries skip it).
/// 3. Companion list ("Také odemkne") with the same row vocabulary as
///    the long-term card. Tapping a companion opens
///    [showEngineCompanionDetailSheet].
class EngineCompletedQuestCard extends StatelessWidget {
  const EngineCompletedQuestCard({
    super.key,
    required this.entry,
    required this.l10n,
    required this.pillKey,
    required this.onClaim,
    this.isExpanded = false,
    this.onToggle,
  });

  final EngineCompletedEntry entry;
  final AppLocalizations l10n;

  /// Sparkle target key for the gold pill. Single key per entry —
  /// the screen still owns the pill key map.
  final GlobalKey pillKey;

  /// Called when the player taps the gold pill on a still-claimable
  /// entry. The parent runs `provider.claimNode(...)` exactly like
  /// the active quest cards.
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;

  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final quest = entry.representative;
    final domain = quest.domain ?? ProgressionDomain.steps;
    final accent = domain.color;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = _formatDate(entry.lastEventAt, locale);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(Tokens.questCardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF111423),
          borderRadius: BorderRadius.circular(Tokens.questCardRadius),
          border: Border.all(
            // Gold-tinted border only while a claim is pending —
            // already-claimed entries blend into the neutral card
            // background so the eye lands on rows that still owe the
            // player XP.
            color: entry.hasClaimable
                ? Tokens.xp.withValues(alpha: isExpanded ? 0.42 : 0.32)
                : (isExpanded
                    ? Tokens.accent.withValues(alpha: 0.32)
                    : Colors.white.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            // Gold glow only on claimable entries — those still owe
            // the player XP and deserve the visual nudge. Claimed
            // entries get the regular shadow only so they read as
            // archived rather than "look at me".
            if (entry.hasClaimable)
              BoxShadow(
                color: Tokens.xp.withValues(alpha: isExpanded ? 0.26 : 0.14),
                blurRadius: isExpanded ? Tokens.glowXl : 16,
                offset: const Offset(0, 6),
              )
            else if (isExpanded)
              BoxShadow(
                color: Tokens.accent.withValues(alpha: 0.18),
                blurRadius: Tokens.glowXl,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Leading(
                  node: quest.node,
                  domain: domain,
                  size: Tokens.questAssetCollapsed,
                  dimmed: !entry.hasClaimable,
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.node.titleKey(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: entry.hasClaimable
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.progRewardsUnlockedAt(dateLabel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeMicro,
                          fontWeight: FontWeight.w600,
                          color: Tokens.onSurfaceMuted,
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
                    color: Tokens.onSurfaceMuted,
                    size: 20,
                  ),
                ],
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: Tokens.spaceMd),
                      child: _ExpandedBody(
                        entry: entry,
                        accent: accent,
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
    if (entry.hasClaimable) {
      // First claimable step drives the tap — claim handlers walk the
      // chain top-down and claim what's available. We pass the
      // earliest-by-chainOrder claimable step so prereq chains advance
      // step by step.
      final claimable = entry.chainQuests.isEmpty
          ? entry.representative
          : entry.chainQuests.firstWhere( // lint-ignore: widget-no-logic — earliest-claimable step pick on the provider-built chain list
              (q) => q.lifecycle is QuestCompletedPendingClaim,
              orElse: () => entry.representative,
            );
      return XpClaimPillData.claimable(
        entry.pendingXp == 0 ? claimable.previewXp : entry.pendingXp,
        onTap: (center) => onClaim(claimable, from: center),
      );
    }
    // Fully claimed — show the credited XP total (sum across chain
    // steps) in the muted "claimed" pill style.
    return XpClaimPillData.claimed(entry.totalXpClaimed);
  }

  static String _formatDate(DateTime ts, String locale) {
    return DateFormat('d MMM · HH:mm', locale).format(ts);
  }
}

/// Leading asset that mirrors the long-term card's leading but greys
/// out for claimed entries — matches the user's "zeÅ¡edne jako zamÄenÃ½
/// quest" intent. Claimable entries stay at full opacity to draw the
/// eye to the gold pill on the right.
class _Leading extends StatelessWidget {
  const _Leading({
    required this.node,
    required this.domain,
    required this.size,
    required this.dimmed,
  });

  final Quest node;
  final ProgressionDomain domain;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final asset = node.assetKey;
    final inner = asset == null || asset.isEmpty
        ? ProgDomIco(domain: domain, size: size)
        : ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.3),
            child: Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ProgDomIco(domain: domain, size: size),
            ),
          );
    if (!dimmed) return inner;
    return Opacity(opacity: 0.55, child: inner);
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.entry,
    required this.accent,
    required this.l10n,
  });

  final EngineCompletedEntry entry;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final quest = entry.representative;
    final description = quest.node.descriptionKey(l10n);
    final nextStep = _nextLockedStep();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.78),
            height: 1.45,
          ),
        ),
        // Chain preview — only renders when the entry is an actual
        // chain. For single-quest entries we skip it; there's nothing
        // to show.
        if (entry.isChain) ...[
          const SizedBox(height: Tokens.spaceSm),
          EngineChapterChainPreview(
            chain: entry.chainQuests,
            currentNodeId: quest.node.id,
            accent: accent,
            l10n: l10n,
          ),
        ],
        // Surface the next-but-locked chain step. The chain row above
        // already shows it as a ðŸ”’ dot; this line names the step and
        // explains why it's not yet active so the player isn't left
        // guessing whether the chain is broken.
        if (nextStep != null) ...[
          const SizedBox(height: Tokens.spaceSm),
          _NextStepHint(node: nextStep.node, l10n: l10n),
        ],
        if (entry.companions.isNotEmpty) ...[
          const SizedBox(height: Tokens.spaceSm),
          _Companions(
            companions: entry.companions,
            quest: quest,
            accent: accent,
            l10n: l10n,
          ),
        ],
      ],
    );
  }

  /// The first chain step the player has not yet touched — i.e. the
  /// next ðŸ”’ dot in the chain preview. Returns null when every chain
  /// step has been claimed / is claimable (player has reached the
  /// end of the authored chain) or when the entry isn't a chain.
  EngineQuestProgress? _nextLockedStep() {
    if (!entry.isChain) return null;
    for (final q in entry.chainQuests) {
      // Anything that isn't claimed yet AND isn't already pending
      // claim is the "next locked step" — covers both
      // QuestLocked (gates unmet) and QuestAvailable (in progress).
      final lifecycle = q.lifecycle;
      if (lifecycle is QuestLocked || lifecycle is QuestAvailable) {
        return q;
      }
    }
    return null;
  }
}

class _NextStepHint extends StatelessWidget {
  const _NextStepHint({required this.node, required this.l10n});

  final Quest node;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Prefer the node's own lockedHint when authors set one (chapter
    // open uses "VyÅ¾aduje level 10"). Otherwise fall back to the
    // generic "complete the previous step" copy.
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

class _Companions extends StatelessWidget {
  const _Companions({
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
            l10n.progQuestsLongTermAlsoUnlocks,
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: Tokens.onSurfaceMuted,
              letterSpacing: 0.6,
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
  });

  final ProgressionEntry node;
  final EngineQuestProgress quest;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = context
        .read<ProgressionEngineProvider>()
        .completedNodeIds
        .contains(node.id);
    final emoji = badgeForCompanion(node);

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
            child: Text(
              node.titleKey(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
