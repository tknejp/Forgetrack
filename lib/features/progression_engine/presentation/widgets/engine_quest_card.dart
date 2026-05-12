import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/xp_claim_pill.dart';
import '../../domain/progression_domain.dart';
import '../widgets/progression_primitives.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/models/progression_node_definition.dart';
import '../../domain/models/reward_definition.dart';
import 'engine_companion_pill.dart';

/// One quest card in the V2 quests screen.
///
/// Layout (collapsed): leading asset Â· title + description (+ optional
/// streak chip) Â· XP pill Â· expand chevron, then the progress row. When
/// [isExpanded] is true an extra panel reveals the full description, an
/// XP-scaling line, and the locked hint when the node has one.
///
/// Stateless â€” the parent owns the claim flow, the pill key for the
/// sparkle target, *and* the one-at-a-time expansion state (V1
/// pattern). The card surfaces taps via [onToggle] but never mutates
/// state on its own.
class EngineQuestCard extends StatelessWidget {
  const EngineQuestCard({
    super.key,
    required this.quest,
    required this.l10n,
    required this.enabled,
    required this.pillKey,
    required this.onClaim,
    this.streak,
    this.isExpanded = false,
    this.onToggle,
  });

  final EngineQuestProgress quest;
  final AppLocalizations l10n;

  /// False while a refresh / claim is in flight â€” disables the pill.
  final bool enabled;

  /// Key used by the parent's sparkle launcher to target this pill.
  final GlobalKey pillKey;

  /// Fired when the player taps the claimable pill. The parent reads
  /// the pill centre via [pillKey] and triggers [ProgressionEngineProvider.claimNode].
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;

  /// Streak summary for this quest's objective. Null when the objective
  /// has no streak (lifetime / weekly scopes); a chip shows only when
  /// [EngineStreakSummary.currentStreak] > 0.
  final EngineStreakSummary? streak;

  /// True when the player has tapped this card open. Owned by the
  /// parent so only one card is expanded at a time (V1 parity).
  final bool isExpanded;

  /// Tap handler for the entire card. Null disables expansion (e.g.
  /// completed quests in the rollup row).
  final VoidCallback? onToggle;

  /// Non-XP rewards on this quest. Surface as chips so future quests
  /// carrying cosmetic/title/emblem/relic/chapter/companion payloads
  /// render without a screen change; today's catalog still ships
  /// XP-only quests so this is normally empty.
  List<RewardDefinition> get _nonXpRewards => [
        for (final r in quest.node.rewards)
          if (r is! XpReward) r,
      ];

  bool get _hasNonXpReward => _nonXpRewards.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final domain = quest.domain ?? ProgressionDomain.steps;
    final accent = domain.color;
    final streakValue = streak?.currentStreak ?? 0;

    // V1 quest cards expanded for any meta info; V2 cards only expand
    // when there's an actual extra reward to surface (rule from the
    // user: "Quest cards nepÅ¯jdou expandovat pokud neobsahujÃ­ odmÄ›nu
    // navÃ­c mimo XP"). Today's daily/weekly quests in the catalog ship
    // XP-only â€” no companion / no item â€” so they're collapsed-only.
    final canExpand = _hasNonXpReward && onToggle != null;

    return GestureDetector(
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (isExpanded)
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestLeading(
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
                      if (streakValue > 0) ...[
                        const SizedBox(height: 6),
                        _StreakChip(days: streakValue, accent: accent),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                // Right column: XP pill on top, optional companion
                // pill below when the quest carries a non-XP reward.
                // No standalone chevron â€” the pill itself doubles as
                // the expand affordance.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    XpClaimPill(key: pillKey, data: _pillData()),
                    if (canExpand) ...[
                      const SizedBox(height: 4),
                      EngineCompanionPill(
                        badge: badgeForReward(_nonXpRewards.first),
                        expanded: isExpanded,
                        onTap: onToggle!,
                        accent: accent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceSm),
            _ProgressRow(quest: quest, accent: accent),
            // Animate the expand block â€” `AnimatedSize` smooths the
            // height transition; the conditional child collapses to
            // an empty box so cards without anything in the expanded
            // panel don't reserve space.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: Tokens.spaceSm),
                      child: _ExpandedDetails(
                        quest: quest,
                        streak: streak,
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
    if (quest.isCompleted) {
      // After a successful claim the ledger has the actually-granted
      // XP; the pill mirrors V1 (greyed-out check + final XP value).
      return XpClaimPillData.claimed(quest.previewXp);
    }
    if (quest.isAvailableForClaim && enabled) {
      return XpClaimPillData.claimable(
        quest.previewXp,
        onTap: (center) => onClaim(quest, from: center),
      );
    }
    // Either the objective isn't satisfied yet, or a refresh/claim is
    // in flight â€” show the locked pill with the would-be XP.
    return XpClaimPillData.locked(quest.previewXp);
  }
}

/// Compact streak chip rendered inside the title column when the
/// quest's objective has an active streak. Mirrors V1's fire chip.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, required this.accent});

  final int days;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ðŸ”¥', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$days',
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail panel revealed when the player expands a quest card.
/// Shows the XP-scaling info (base Ã— level multiplier â†’ preview),
/// the locked hint when set, and the streak record when present.
class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.quest,
    required this.streak,
    required this.accent,
    required this.l10n,
  });

  final EngineQuestProgress quest;
  final EngineStreakSummary? streak;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final lockedHint = quest.node.lockedHintKey?.call(l10n);
    final bestStreak = streak?.bestStreak ?? 0;

    // The XP value already lives on the pill in the title row â€” repeating
    // it inside the expanded panel only adds noise. The panel keeps just
    // the streak record and any locked hint authored on the node.
    final rows = <Widget>[];
    if (bestStreak > 0) {
      rows.add(_DetailLine(
        icon: Icons.local_fire_department_rounded,
        color: accent,
        text: l10n.progStreakBestDetail(bestStreak),
      ));
    }
    if (lockedHint != null && lockedHint.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 6));
      rows.add(_DetailLine(
        icon: Icons.lock_outline_rounded,
        color: Tokens.onSurfaceMuted,
        text: lockedHint,
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

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
        children: rows,
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
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: Tokens.onSurfaceMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
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

/// Leading visual on a quest card. Renders [QuestNode.assetKey] when set,
/// falling back to [ProgDomIco] (the domain icon tile) when the node
/// doesn't carry one. Asset failure (missing PNG, decode error) also
/// degrades to the icon â€” the screen never goes blank because of a
/// stale asset path.
class _QuestLeading extends StatelessWidget {
  const _QuestLeading({
    required this.node,
    required this.domain,
    required this.size,
  });

  final QuestNode node;
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
        errorBuilder: (_, __, ___) =>
            ProgDomIco(domain: domain, size: size),
      ),
    );
  }
}
