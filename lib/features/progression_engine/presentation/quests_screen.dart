import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/xp_sparkle_overlay.dart';
import '../application/progression_engine_provider.dart';
import '../domain/catalog/engine_catalog_context.dart';
import 'widgets/engine_completed_quests_section.dart';
import 'widgets/engine_quest_card.dart';
import 'widgets/engine_quest_section.dart';
import 'widgets/engine_reward_history_feed.dart';
import '../../../shared/widgets/section_head.dart';

/// V2 quests screen.
///
/// Replaces the legacy 2 081-LOC
/// `progression/presentation/quests/quests_screen.dart`. Scope today
/// is daily + weekly quests with manual claim; chapters / combos /
/// long-term content land here once the rest of Phase 3 ports them.
///
/// The screen is intentionally thin: read
/// [ProgressionEngineProvider.currentDailyQuests] /
/// [ProgressionEngineProvider.currentWeeklyQuests], render one
/// [EngineQuestCard] per entry, forward taps on the gold pill back to
/// [ProgressionEngineProvider.claimNode]. The XP sparkle launches from
/// here (not the card) so it can target the progression bar key passed
/// in from the shell.
class QuestsScreenV2 extends StatefulWidget {
  const QuestsScreenV2({
    super.key,
    required this.barKey,
    required this.outerController,
    this.topContentInset = 0,
  });

  /// Key of the progression bar in the shell header — sparkle target
  /// when the player claims XP.
  final GlobalKey barKey;

  /// PageController driving the shell — kept for parity with the
  /// legacy screen even though we don't read it today.
  final PageController outerController;

  final double topContentInset;

  @override
  State<QuestsScreenV2> createState() => _QuestsScreenV2State();
}

class _QuestsScreenV2State extends State<QuestsScreenV2> {
  /// One key per quest pill so the sparkle can launch from the exact
  /// pill the player tapped.
  final Map<String, GlobalKey> _pillKeys = {};

  /// One-at-a-time card expansion (V1 parity). Null when no card is
  /// open. Tapping the same id collapses; tapping another switches.
  String? _expandedNodeId;

  GlobalKey _pillKeyFor(String nodeId) =>
      _pillKeys.putIfAbsent(nodeId, () => GlobalKey(debugLabel: nodeId));

  void _toggleExpanded(String nodeId) {
    setState(() {
      _expandedNodeId = _expandedNodeId == nodeId ? null : nodeId;
    });
  }

  Offset? _centerOfKey(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) +
        Offset(box.size.width / 2, box.size.height / 2);
  }

  Future<void> _claimQuest(
    EngineQuestProgress quest, {
    Offset? from,
  }) async {
    final provider = context.read<ProgressionEngineProvider>();
    final input = provider.currentInput;
    if (input == null) return;

    final origin = from ?? _centerOfKey(_pillKeyFor(quest.nodeId));
    if (origin != null) {
      XpSparkleLauncher.launchToKey(
        context,
        from: origin,
        targetKey: widget.barKey,
      );
    }

    await provider.claimNode(
      nodeId: quest.nodeId,
      input: input,
      catalogContext:
          provider.currentCatalogContext ?? const EngineCatalogContext(),
    );
  }

  Future<void> _claimAll(List<EngineQuestProgress> claimable) async {
    final provider = context.read<ProgressionEngineProvider>();
    final input = provider.currentInput;
    if (input == null || claimable.isEmpty) return;

    final origins = [
      for (final q in claimable) _centerOfKey(_pillKeyFor(q.nodeId)),
    ].whereType<Offset>().toList(growable: false);

    if (origins.isNotEmpty) {
      XpSparkleLauncher.launchManyToKey(
        context,
        fromPoints: origins,
        targetKey: widget.barKey,
      );
    }

    final ctx =
        provider.currentCatalogContext ?? const EngineCatalogContext();

    // Sequential — each claim advances the ledger and the engine's
    // idempotency bookkeeping. Parallel claims would race on
    // appendEvents.
    for (final quest in claimable) {
      await provider.claimNode(
        nodeId: quest.nodeId,
        input: input,
        catalogContext: ctx,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ProgressionEngineProvider>();
    final daily = provider.currentDailyQuests;
    final weekly = provider.currentWeeklyQuests;

    if (provider.isLoading && provider.ledger == null) {
      return Scaffold(
        backgroundColor: Tokens.bg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding:
                EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              EngineQuestLoadingBlock(height: 180),
              SizedBox(height: Tokens.spaceMd),
              EngineQuestLoadingBlock(height: 220),
            ],
          ),
        ),
      );
    }

    final dailyClaimable = daily.where((q) => q.isAvailableForClaim).toList();
    final weeklyClaimable =
        weekly.where((q) => q.isAvailableForClaim).toList();
    final dailyActive = daily.where((q) => !q.isCompleted).toList();
    final weeklyActive = weekly.where((q) => !q.isCompleted).toList();

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (provider.error != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    14, widget.topContentInset + 8, 14, 0),
                child: EngineQuestErrorBanner(message: provider.error!),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.refresh,
                color: Tokens.accent,
                backgroundColor: Tokens.surface,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    14,
                    provider.error != null
                        ? 16
                        : widget.topContentInset + 16,
                    14,
                    28,
                  ),
                  children: [
                    QuestSectionPanel(
                      header: l10n.progQuestsDailyGoalsHeader,
                      color: Tokens.steps.color,
                      countLabel: dailyActive.isEmpty
                          ? null
                          : l10n.progQuestsActiveCount(dailyActive.length),
                      emptyTitle: l10n.progQuestsEmptyActiveTitle,
                      emptyCaption: l10n.progQuestsEmptyActiveCaption,
                      claimAllLabel: l10n.progQuestClaimAll,
                      l10n: l10n,
                      quests: dailyActive,
                      claimable: dailyClaimable,
                      enabled: !provider.isEvaluating,
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
                      onClaimAll: _claimAll,
                      streakFor: (q) =>
                          provider.streakForObjective(q.node.objectiveId),
                      expandedNodeId: _expandedNodeId,
                      onToggleExpanded: _toggleExpanded,
                    ),
                    const SizedBox(height: Tokens.spaceXl),
                    QuestSectionPanel(
                      header: l10n.progQuestsWeeklyHeader,
                      color: Tokens.calories.color,
                      countLabel: weeklyActive.isEmpty
                          ? null
                          : l10n.progQuestsActiveCount(weeklyActive.length),
                      emptyTitle: l10n.progQuestsEmptyActiveTitle,
                      emptyCaption: l10n.progQuestsEmptyActiveCaption,
                      claimAllLabel: l10n.progQuestClaimAll,
                      l10n: l10n,
                      quests: weeklyActive,
                      claimable: weeklyClaimable,
                      enabled: !provider.isEvaluating,
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
                      onClaimAll: _claimAll,
                      streakFor: (q) =>
                          provider.streakForObjective(q.node.objectiveId),
                      expandedNodeId: _expandedNodeId,
                      onToggleExpanded: _toggleExpanded,
                    ),
                    const SizedBox(height: Tokens.spaceXl),
                    EngineCompletedQuestsSection(
                      completed: provider.completedQuests,
                      l10n: l10n,
                      resolveDomain: provider.domainForNodeId,
                    ),
                    const SizedBox(height: Tokens.spaceXl),
                    SectionHead(
                      label: l10n.progRewardsSectionLabel,
                      caption: l10n.progRewardsSectionCaption,
                      accent: Tokens.calories.color,
                    ),
                    const SizedBox(height: Tokens.spaceSm),
                    EngineRewardHistoryFeed(
                      grants: provider.rewardHistory,
                      l10n: l10n,
                      resolveNode: provider.nodeById,
                      resolveDomain: provider.domainForNodeId,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header row + list of [EngineQuestCard]s for one quest bucket
/// (daily or weekly). Public so tests can render a section in
/// isolation without spinning up the whole screen.
class QuestSectionPanel extends StatelessWidget {
  const QuestSectionPanel({
    super.key,
    required this.header,
    required this.color,
    required this.countLabel,
    required this.emptyTitle,
    required this.emptyCaption,
    required this.claimAllLabel,
    required this.l10n,
    required this.quests,
    required this.claimable,
    required this.enabled,
    required this.pillKeyFor,
    required this.onClaim,
    required this.onClaimAll,
    this.streakFor,
    this.expandedNodeId,
    this.onToggleExpanded,
  });

  final String header;
  final Color color;
  final String? countLabel;
  final String emptyTitle;
  final String emptyCaption;
  final String claimAllLabel;
  final AppLocalizations l10n;
  final List<EngineQuestProgress> quests;
  final List<EngineQuestProgress> claimable;
  final bool enabled;
  final GlobalKey Function(String nodeId) pillKeyFor;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;
  final Future<void> Function(List<EngineQuestProgress> quests) onClaimAll;

  /// Resolves the streak summary for a given quest. Used by the card
  /// to render a 🔥 chip and the best-streak detail line. Optional —
  /// tests can pass null to skip the streak path.
  final EngineStreakSummary Function(EngineQuestProgress quest)? streakFor;

  /// Id of the currently expanded card (one-at-a-time). Owned by the
  /// screen; the panel just forwards it to each card.
  final String? expandedNodeId;

  /// Tap handler for card expansion. When null, cards render without
  /// the expand chevron and ignore taps.
  final void Function(String nodeId)? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: EngineQuestSection(
                label: header,
                color: color,
                countLabel: countLabel,
                isEmpty: true,
                children: const [],
              ),
            ),
            if (claimable.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: Tokens.spaceSm),
                child: _ClaimAllButton(
                  label: claimAllLabel,
                  enabled: enabled,
                  onTap: () => onClaimAll(claimable),
                ),
              ),
          ],
        ),
        if (quests.isEmpty)
          EngineQuestEmptyLine(title: emptyTitle, caption: emptyCaption)
        else
          Column(
            children: [
              for (var i = 0; i < quests.length; i++) ...[
                if (i > 0) const SizedBox(height: Tokens.spaceSm),
                EngineQuestCard(
                  quest: quests[i],
                  l10n: l10n,
                  enabled: enabled,
                  pillKey: pillKeyFor(quests[i].nodeId),
                  onClaim: onClaim,
                  streak: streakFor?.call(quests[i]),
                  isExpanded: expandedNodeId == quests[i].nodeId,
                  onToggle: onToggleExpanded == null
                      ? null
                      : () => onToggleExpanded!(quests[i].nodeId),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _ClaimAllButton extends StatelessWidget {
  const _ClaimAllButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFFBD2E);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Tokens.radiusIcon),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: enabled ? color : Tokens.onSurfaceFaint,
          ),
        ),
      ),
    );
  }
}
