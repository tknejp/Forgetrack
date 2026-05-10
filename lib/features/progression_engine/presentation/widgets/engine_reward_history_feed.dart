import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression/domain/models/core_models.dart';
import '../../../progression/presentation/widgets/progression_primitives.dart';
import '../../domain/models/ledger_event.dart';
import '../../domain/models/objective_definition.dart' show ProgressionDomain;
import '../../domain/models/progression_node_definition.dart';

/// Chronological feed of recent reward grants from the engine ledger.
///
/// Each row is one [RewardGrantEvent] resolved against the catalog so
/// we can show the source quest's title + domain icon. Rows are
/// already sorted newest-first by [ProgressionEngineProvider.rewardHistory].
class EngineRewardHistoryFeed extends StatelessWidget {
  const EngineRewardHistoryFeed({
    super.key,
    required this.grants,
    required this.l10n,
    required this.resolveNode,
    required this.resolveDomain,
  });

  final List<RewardGrantEvent> grants;
  final AppLocalizations l10n;

  /// Resolves a node id to its catalog definition so the row can show
  /// the quest title. Pass `provider.nodeById` here.
  final ProgressionNode? Function(String nodeId) resolveNode;

  /// Resolves the visual domain for a ledger entry. Pass
  /// `provider.domainForNodeId` so the row's icon + accent colour
  /// match the source objective.
  final ProgressionDomain Function(String nodeId) resolveDomain;

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          l10n.progRewardsEmptyTitle,
          style: const TextStyle(
            fontSize: Tokens.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: Tokens.onSurfaceMuted,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < grants.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _RewardHistoryRow(
            grant: grants[i],
            l10n: l10n,
            node: resolveNode(grants[i].nodeId),
            domain: resolveDomain(grants[i].nodeId),
          ),
        ],
      ],
    );
  }
}

class _RewardHistoryRow extends StatelessWidget {
  const _RewardHistoryRow({
    required this.grant,
    required this.l10n,
    required this.node,
    required this.domain,
  });

  final RewardGrantEvent grant;
  final AppLocalizations l10n;
  final ProgressionNode? node;
  final ProgressionDomain domain;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final accent = domain.color;
    final title = node?.titleKey(l10n) ?? grant.nodeId;
    final subtitle = _subtitle();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ProgDomIco(domain: domain, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  l10n.progRewardsUnlockedAt(_formatTime(grant.timestamp, locale)),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RewardBadge(text: subtitle, accent: accent),
        ],
      ),
    );
  }

  String _subtitle() {
    switch (grant.rewardKind) {
      case RewardGrantKind.xp:
        return '+${grant.xpAmount ?? 0} XP';
      case RewardGrantKind.cosmetic:
        return '✨';
      case RewardGrantKind.chapterUnlock:
        return '🗺️';
      case RewardGrantKind.companionAvailability:
        return '🧝';
      case RewardGrantKind.title:
        return '🏷️';
      case RewardGrantKind.emblem:
        return '🛡️';
      case RewardGrantKind.relic:
        return '🪨';
    }
  }

}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

String _formatTime(DateTime value, String locale) {
  return DateFormat('d MMM · HH:mm', locale).format(value);
}
