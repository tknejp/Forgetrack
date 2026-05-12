import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/progression_domain.dart';
import '../widgets/progression_primitives.dart';
import '../../application/progression_engine_provider.dart';
import '../../domain/catalog/progression_node_catalog.dart';
import '../../domain/models/progression_node_definition.dart';

/// Compact row used inside the "ZAMÄŒENÃ‰ QUESTY" section.
///
/// Mirrors the V1 `_LockedQuestRow`: leading quest asset (or domain
/// icon fallback) Â· title Â· "VyÅ¾aduje level X" subtitle Â· trailing
/// lock glyph. No claim affordance â€” these rows are informational
/// until the gating level is reached.
class EngineLockedQuestRow extends StatelessWidget {
  const EngineLockedQuestRow({
    super.key,
    required this.quest,
    required this.l10n,
  });

  final EngineQuestProgress quest;
  final AppLocalizations l10n;

  /// Subtitle picked from whichever gate is actually blocking this
  /// quest. Prereq takes priority over level â€” the player must finish
  /// the previous chapter before the level requirement matters anyway,
  /// so leading with the chapter name is more actionable than "Reach
  /// level X". Falls back to the level hint when no prereq is set or
  /// the prereq node is missing from the catalog.
  String _resolveSubtitle(AppLocalizations l10n) {
    final prereqId = quest.prereqGateNodeId;
    if (prereqId != null) {
      final prereqNode = ProgressionNodeCatalog.definitionForId(prereqId);
      final title = _titleForNode(prereqNode, l10n);
      if (title != null && title.isNotEmpty) {
        return l10n.progQuestDetailCompleteQuest(title);
      }
    }
    return l10n.progQuestDetailRequiresLevel(quest.levelGate ?? 0);
  }

  static String? _titleForNode(ProgressionNode? node, AppLocalizations l10n) {
    return switch (node) {
      QuestNode(:final titleKey) => titleKey(l10n),
      AchievementNode(:final titleKey) => titleKey(l10n),
      MilestoneNode(:final titleKey) => titleKey(l10n),
      LevelMilestoneNode(:final titleKey) => titleKey(l10n),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final domain = quest.domain ?? ProgressionDomain.steps;
    final subtitle = _resolveSubtitle(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _LockedLeading(
            assetKey: quest.node.assetKey,
            domain: domain,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.node.titleKey(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Tokens.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: Tokens.onSurfaceFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.lock_rounded,
            size: 16,
            color: Tokens.onSurfaceFaint.withValues(alpha: 0.82),
          ),
        ],
      ),
    );
  }
}

class _LockedLeading extends StatelessWidget {
  const _LockedLeading({
    required this.assetKey,
    required this.domain,
    required this.size,
  });

  final String? assetKey;
  final ProgressionDomain domain;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = assetKey;
    if (asset == null || asset.isEmpty) {
      return ProgDomIco(domain: domain, size: size);
    }
    return Opacity(
      opacity: 0.62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ProgDomIco(domain: domain, size: size),
        ),
      ),
    );
  }
}
