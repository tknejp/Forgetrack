import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression/domain/models/core_models.dart';
import '../../../progression/presentation/widgets/progression_primitives.dart';
import '../../application/progression_engine_provider.dart';
import 'engine_quest_section.dart';

/// Completed-quests rollup section, used twice on the V2 quests
/// screen: once for permanent completions ("Splněné cíle" — chapter,
/// weekly, long-term) and once for today's daily-goal claims
/// ("Nedávné odměny"). Header / empty-state strings are configurable
/// so the same widget serves both surfaces with V1-matching copy.
///
/// Default-shows the most recent [compactLimit] entries; reveals the
/// full list when the player taps "Show all (N)".
class EngineCompletedQuestsSection extends StatefulWidget {
  const EngineCompletedQuestsSection({
    super.key,
    required this.completed,
    required this.l10n,
    required this.resolveDomain,
    required this.header,
    required this.headerColor,
    required this.emptyTitle,
    required this.emptyCaption,
    this.compactLimit = 3,
  });

  final List<EngineCompletedQuest> completed;
  final AppLocalizations l10n;

  /// Resolves the visual domain for a completed quest. Pass
  /// `provider.domainForNodeId` so each row's icon matches its source
  /// objective.
  final ProgressionDomain Function(String nodeId) resolveDomain;

  /// Section header label (e.g. "Splněné cíle" or "Nedávné odměny").
  final String header;

  /// Accent color for the header row.
  final Color headerColor;

  /// Empty-state title shown when [completed] is empty.
  final String emptyTitle;

  /// Empty-state caption shown beneath the title.
  final String emptyCaption;

  /// Number of rows shown before the "Show all" affordance kicks in.
  final int compactLimit;

  @override
  State<EngineCompletedQuestsSection> createState() =>
      _EngineCompletedQuestsSectionState();
}

class _EngineCompletedQuestsSectionState
    extends State<EngineCompletedQuestsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.completed.length;
    final shown = _showAll
        ? widget.completed
        : widget.completed.take(widget.compactLimit).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: EngineQuestSection(
                label: widget.header,
                color: widget.headerColor,
                countLabel: total == 0
                    ? null
                    : widget.l10n.progQuestsCompletedCount(total),
                isEmpty: true,
                children: const [],
              ),
            ),
          ],
        ),
        if (total == 0)
          EngineQuestEmptyLine(
            title: widget.emptyTitle,
            caption: widget.emptyCaption,
          )
        else
          Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _CompletedRow(
                  entry: shown[i],
                  l10n: widget.l10n,
                  domain: widget.resolveDomain(shown[i].nodeId),
                ),
              ],
            ],
          ),
        if (total > widget.compactLimit && !_showAll) ...[
          const SizedBox(height: Tokens.spaceSm),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showAll = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                widget.l10n.progShowAllCount(total),
                style: const TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w700,
                  color: Tokens.accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompletedRow extends StatelessWidget {
  const _CompletedRow({
    required this.entry,
    required this.l10n,
    required this.domain,
  });

  final EngineCompletedQuest entry;
  final AppLocalizations l10n;
  final ProgressionDomain domain;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final accent = domain.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ProgDomIco(domain: domain, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.node.titleKey(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.progRewardsUnlockedAt(
                    DateFormat('d MMM · HH:mm', locale)
                        .format(entry.completedAt),
                  ),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Per V1 parity: claimed quests show a soft success-toned
          // check, not the gold "+XP" pill. The pill is reserved for
          // active claimable rows.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Tokens.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
              border: Border.all(
                color: Tokens.success.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 14,
              color: Tokens.success.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
