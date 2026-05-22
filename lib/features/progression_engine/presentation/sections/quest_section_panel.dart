import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/domain/companion_buff.dart';
import '../../application/progression_engine_provider.dart';
import '../widgets/engine_quest_card.dart';
import '../widgets/engine_quest_section.dart';

/// Builds the flat list of widgets for one quest section (daily /
/// weekly). Used by both [QuestSectionPanel.build] (wrapping in a
/// Column for standalone / test use) and `QuestsScreenV2`
/// (splatting items directly into the ListView so each card is its
/// own lazy entry — Phase 1.1 perf fix). Keeping a single helper
/// keeps the widget-form and the screen-form visually identical and
/// prevents drift.
List<Widget> buildQuestSectionItems({
  required String header,
  required Color color,
  required String? countLabel,
  required String emptyTitle,
  required String emptyCaption,
  required AppLocalizations l10n,
  required List<EngineQuestProgress> quests,
  required GlobalKey Function(String nodeId) pillKeyFor,
  required Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim,
  EngineStreakSummary Function(EngineQuestProgress quest)? streakFor,
  void Function(String nodeId)? onToggleExpanded,
  String? hint,
  List<EngineQuestProgress> Function(String chainId)? chainResolver,
  int Function(EngineQuestProgress quest)? companionBuffBonusFor,
  int Function(EngineQuestProgress quest)? emblemBuffBonusFor,
  CompanionBuff? equippedCompanionBuff,
  int Function(EngineQuestProgress quest)? streakBuffPercentFor,
}) {
  final items = <Widget>[
    EngineQuestSection(
      label: header,
      color: color,
      countLabel: countLabel,
      isEmpty: true,
      children: const [],
    ),
  ];

  if (hint != null) {
    items.add(_QuestSectionHint(hint: hint));
  }

  if (quests.isEmpty) {
    items.add(EngineQuestEmptyLine(title: emptyTitle, caption: emptyCaption));
    return items;
  }

  for (var i = 0; i < quests.length; i++) {
    if (i > 0) items.add(const SizedBox(height: Tokens.spaceSm));
    final q = quests[i];
    items.add(
      EngineQuestCard(
        key: ValueKey(q.nodeId),
        quest: q,
        l10n: l10n,
        pillKey: pillKeyFor(q.nodeId),
        onClaim: onClaim,
        streak: streakFor?.call(q),
        onToggle: onToggleExpanded == null
            ? null
            : () => onToggleExpanded(q.nodeId),
        chain: () {
          final chainId = q.node.chainId;
          if (chainId == null || chainResolver == null) {
            return const <EngineQuestProgress>[];
          }
          return chainResolver(chainId);
        }(),
        showCompletedTodayBadge: color == Tokens.steps.color,
        companionBuffBonus: companionBuffBonusFor?.call(q) ?? 0,
        emblemBuffBonus: emblemBuffBonusFor?.call(q) ?? 0,
        equippedCompanionBuff: equippedCompanionBuff,
        streakBuffPercent: streakBuffPercentFor?.call(q) ?? 0,
      ),
    );
  }

  return items;
}

/// Hint caption rendered below a section header. Pulled out into its
/// own widget so the [Theme.of] read doesn't force [buildQuestSectionItems]
/// to take a BuildContext — the items are built once during the screen's
/// build, but each item gets its own BuildContext at mount time.
class _QuestSectionHint extends StatelessWidget {
  const _QuestSectionHint({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 2, right: 2, bottom: Tokens.spaceXs),
      child: Text(
        hint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Tokens.onSurfaceMuted,
            ),
      ),
    );
  }
}

/// Header row + list of [EngineQuestCard]s for one quest bucket
/// (daily or weekly). Public so tests can render a section in
/// isolation without spinning up the whole screen.
///
/// The screen itself doesn't compose this widget — it calls
/// [buildQuestSectionItems] directly and splats the result into the
/// ListView so each card becomes its own lazy-mounted entry (Phase
/// 1.1 perf fix). This widget remains for stand-alone use (widget
/// tests, previews) and wraps the same helper output in a Column.
class QuestSectionPanel extends StatelessWidget {
  const QuestSectionPanel({
    super.key,
    required this.header,
    required this.color,
    required this.countLabel,
    required this.emptyTitle,
    required this.emptyCaption,
    required this.l10n,
    required this.quests,
    required this.pillKeyFor,
    required this.onClaim,
    this.streakFor,
    this.onToggleExpanded,
    this.hint,
    this.chainResolver,
    this.companionBuffBonusFor,
    this.emblemBuffBonusFor,
    this.equippedCompanionBuff,
    this.streakBuffPercentFor,
  });

  final String header;
  final Color color;
  final String? countLabel;
  final String emptyTitle;
  final String emptyCaption;
  final AppLocalizations l10n;
  final List<EngineQuestProgress> quests;
  final GlobalKey Function(String nodeId) pillKeyFor;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;

  final EngineStreakSummary Function(EngineQuestProgress quest)? streakFor;

  final int Function(EngineQuestProgress quest)? companionBuffBonusFor;

  final int Function(EngineQuestProgress quest)? emblemBuffBonusFor;

  final CompanionBuff? equippedCompanionBuff;

  final int Function(EngineQuestProgress quest)? streakBuffPercentFor;

  final void Function(String nodeId)? onToggleExpanded;

  final String? hint;

  final List<EngineQuestProgress> Function(String chainId)? chainResolver;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buildQuestSectionItems(
        header: header,
        color: color,
        countLabel: countLabel,
        emptyTitle: emptyTitle,
        emptyCaption: emptyCaption,
        l10n: l10n,
        quests: quests,
        pillKeyFor: pillKeyFor,
        onClaim: onClaim,
        streakFor: streakFor,
        onToggleExpanded: onToggleExpanded,
        hint: hint,
        chainResolver: chainResolver,
        companionBuffBonusFor: companionBuffBonusFor,
        emblemBuffBonusFor: emblemBuffBonusFor,
        equippedCompanionBuff: equippedCompanionBuff,
        streakBuffPercentFor: streakBuffPercentFor,
      ),
    );
  }
}
