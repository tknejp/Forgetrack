import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/progression/catalog/ids.dart';
import '../../../domain/progression/player/player_quest_lifecycle.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/xp_sparkle_overlay.dart';
import '../application/progression_engine_provider.dart';
import 'widgets/engine_backfill_section.dart';
import 'widgets/engine_chapter_card.dart';
import 'widgets/engine_completed_quest_card.dart';
import 'widgets/engine_locked_quest_row.dart';
import 'widgets/engine_long_term_card.dart';
import 'widgets/engine_quest_card.dart';
import 'widgets/engine_quest_section.dart';

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
    if (provider.currentContext == null) return;

    final origin = from ?? _centerOfKey(_pillKeyFor(quest.nodeId));
    if (origin != null) {
      XpSparkleLauncher.launchToKey(
        context,
        from: origin,
        targetKey: widget.barKey,
      );
    }

    await provider.claimNode(nodeId: quest.nodeId);
  }

  Future<void> _claimAll(List<EngineQuestProgress> claimable) async {
    final provider = context.read<ProgressionEngineProvider>();
    if (provider.currentContext == null || claimable.isEmpty) return;

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

    // Sequential — each claim advances the ledger and the engine's
    // idempotency bookkeeping. Parallel claims would race on
    // appendEvents. The provider rebuilds the engine input from the
    // latest ledger on every claim, so per-iteration counters
    // (totalRewardCount, nodeCompletionCounts, …) stay accurate even
    // when one step's claim should unlock the next.
    for (final quest in claimable) {
      await provider.claimNode(nodeId: quest.nodeId);
    }

    // Cascade pass: a claim in the loop above can satisfy an objective
    // that only becomes available *after* the previous claim's grants
    // hit the ledger (e.g. `reward_count_first` triggers once the first
    // XP grant lands). Without this, the badge would correctly report
    // "1 to claim" but the screen wouldn't show a row to act on. Drain
    // any freshly-available nodes here so the loop is idempotent.
    var safety = 0;
    while (provider.pendingClaimNodeIds.isNotEmpty && safety < 8) {
      final cascade = provider.pendingClaimNodeIds.toList();
      for (final id in cascade) {
        await provider.claimNode(nodeId: id);
      }
      safety++;
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

    // Phase 7: lifecycle reads route through the PlayerQuestCatalog
    // projection. The bucket lists (`daily`, `weekly`) come from
    // engine-ordered output; the catalog is the lifecycle authority.
    // Looking up via `catalog.byId(...)` instead of `q.lifecycle`
    // proves the projection is wired and establishes the pattern
    // Phase 8 / Phase 13 will follow for achievements + chapters.
    final catalog = provider.playerQuestCatalog;
    PlayerQuestLifecycle lifecycleOf(EngineQuestProgress q) =>
        catalog.byId(QuestId(q.node.id.value))?.lifecycle ??
            const QuestLocked();
    final dailyClaimable =
        daily.where((q) => lifecycleOf(q) is QuestCompletedPendingClaim).toList();
    final weeklyClaimable =
        weekly.where((q) => lifecycleOf(q) is QuestCompletedPendingClaim).toList();
    // Daily slot is sticky for the whole day: claimed cards stay in the
    // section reading as "done" until midnight rolls a new rotation, so
    // we pass the full list (no QuestClaimed filter). The count label
    // uses unclaimed quests only.
    final dailyUnclaimed = daily.where((q) => lifecycleOf(q) is! QuestClaimed).toList();
    // Weekly section now mirrors long-term / chapter rules: a quest
    // that's claimable-but-not-claimed moves to DOKONČENÉ so the row
    // doesn't double-list. Daily stays as-is (claimable still shows
    // in the daily section so the player can claim from the active
    // surface).
    final weeklyActive = weekly
        .where((q) => switch (lifecycleOf(q)) {
              QuestAvailable() || QuestLocked() => true,
              QuestCompletedPendingClaim() || QuestClaimed() => false,
            })
        .toList();
    final chapters = provider.currentChapterQuests;
    final longTerm = provider.currentLongTermQuests;
    final locked = provider.lockedQuests;
    final completed = provider.completedEntries;

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
                    if (chapters.isNotEmpty ||
                        provider.nextLockedChapter != null) ...[
                      _ChapterSection(
                        chapters: chapters,
                        chainResolver: provider.chainQuestsFor,
                        l10n: l10n,
                        enabled: !provider.isEvaluating,
                        pillKeyFor: _pillKeyFor,
                        onClaim: _claimQuest,
                        expandedNodeId: _expandedNodeId,
                        onToggleExpanded: _toggleExpanded,
                        nextLocked: provider.nextLockedChapter,
                      ),
                      const SizedBox(height: Tokens.spaceXl),
                    ],
                    QuestSectionPanel(
                      header: l10n.progQuestsDailyTasksHeader,
                      color: Tokens.steps.color,
                      countLabel: dailyUnclaimed.isEmpty
                          ? null
                          : l10n.progQuestsActiveCount(dailyUnclaimed.length),
                      emptyTitle: l10n.progQuestsEmptyActiveTitle,
                      emptyCaption: l10n.progQuestsEmptyActiveCaption,
                      claimAllLabel: l10n.progQuestClaimAll,
                      l10n: l10n,
                      hint: l10n.progQuestsDailyTasksHint,
                      quests: daily,
                      claimable: dailyClaimable,
                      enabled: !provider.isEvaluating,
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
                      onClaimAll: _claimAll,
                      streakFor: (q) =>
                          provider.streakForObjective(q.node.objectiveId),
                      expandedNodeId: _expandedNodeId,
                      onToggleExpanded: _toggleExpanded,
                      chainResolver: provider.chainQuestsFor,
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
                    if (longTerm.isNotEmpty) ...[
                      const SizedBox(height: Tokens.spaceXl),
                      _LongTermSection(
                        entries: longTerm,
                        chainResolver: provider.chainQuestsFor,
                        l10n: l10n,
                        enabled: !provider.isEvaluating,
                        pillKeyFor: _pillKeyFor,
                        onClaim: _claimQuest,
                        expandedNodeId: _expandedNodeId,
                        onToggleExpanded: _toggleExpanded,
                      ),
                    ],
                    if (locked.isNotEmpty) ...[
                      const SizedBox(height: Tokens.spaceXl),
                      _LockedSection(quests: locked, l10n: l10n),
                    ],
                    const SizedBox(height: Tokens.spaceXl),
                    _CompletedSection(
                      entries: completed,
                      l10n: l10n,
                      enabled: !provider.isEvaluating,
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
                      onClaimAll: _claimAll,
                      expandedNodeId: _expandedNodeId,
                      onToggleExpanded: _toggleExpanded,
                    ),
                    const SizedBox(height: Tokens.spaceXl),
                    EngineBackfillSection(
                      barKey: widget.barKey,
                      l10n: l10n,
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
    this.hint,
    this.chainResolver,
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

  /// Optional caption line rendered below the section header — used
  /// by the daily section to hint that quests rotate at midnight.
  final String? hint;

  /// Resolves the full chain (in chainOrder) for a given chainId.
  /// When present, combo daily quests render the chain-dot preview
  /// like chapter cards do. Tests can pass null to skip the lookup.
  final List<EngineQuestProgress> Function(String chainId)? chainResolver;

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
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(
                left: 2, right: 2, bottom: Tokens.spaceXs),
            child: Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Tokens.onSurfaceMuted,
                  ),
            ),
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
                  // Combo daily quests carry a chainId; the resolver
                  // returns the full chain so the card renders the
                  // chain-dot preview row. Non-combo cards pass an
                  // empty chain and skip the row entirely.
                  chain: () {
                    final chainId = quests[i].node.chainId;
                    if (chainId == null || chainResolver == null) {
                      return const <EngineQuestProgress>[];
                    }
                    return chainResolver!(chainId);
                  }(),
                  // Daily-section cards (steps domain accent) surface
                  // the "rotate at midnight" hint when today's quest
                  // is already done; weekly + chapter cards opt out.
                  showCompletedTodayBadge: color == Tokens.steps.color,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Top-of-screen "Journey Chapters" section. Renders one
/// [EngineChapterCard] per active chapter, each with the chain
/// preview pulled via [chainResolver]. Chapter quests are auto-claim
/// (open + finale) or manual-claim (steps); the screen routes claim
/// taps through the same handler the daily/weekly cards use.
class _ChapterSection extends StatelessWidget {
  const _ChapterSection({
    required this.chapters,
    required this.chainResolver,
    required this.l10n,
    required this.enabled,
    required this.pillKeyFor,
    required this.onClaim,
    required this.expandedNodeId,
    required this.onToggleExpanded,
    this.nextLocked,
  });

  final List<EngineQuestProgress> chapters;
  final List<EngineQuestProgress> Function(String chainId) chainResolver;
  final AppLocalizations l10n;
  final bool enabled;
  final GlobalKey Function(String nodeId) pillKeyFor;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;
  final String? expandedNodeId;
  final void Function(String nodeId) onToggleExpanded;

  /// Compact teaser for the next-up locked chapter. Renders below the
  /// active chapter cards as a single low-info row ("Odemkne se na
  /// úrovni 30") so the player sees what's coming after they finish
  /// the current chapter without spoiling the upcoming content.
  final EngineQuestProgress? nextLocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EngineQuestSection(
          label: l10n.progQuestsChapterHeader,
          color: Tokens.accent,
          countLabel: chapters.length == 1
              ? null
              : l10n.progQuestsActiveCount(chapters.length),
          isEmpty: true,
          children: const [],
        ),
        for (var i = 0; i < chapters.length; i++) ...[
          if (i > 0) const SizedBox(height: Tokens.spaceSm),
          EngineChapterCard(
            quest: chapters[i],
            chain: chainResolver(chapters[i].node.chainId ?? ''),
            l10n: l10n,
            enabled: enabled,
            pillKey: pillKeyFor(chapters[i].nodeId),
            onClaim: onClaim,
            isExpanded: expandedNodeId == chapters[i].nodeId,
            onToggle: () => onToggleExpanded(chapters[i].nodeId),
          ),
        ],
        if (nextLocked != null) ...[
          if (chapters.isNotEmpty) const SizedBox(height: Tokens.spaceSm),
          _NextChapterLockedTeaser(quest: nextLocked!, l10n: l10n),
        ],
      ],
    );
  }
}

/// Compact "next chapter is coming" tile rendered at the tail of the
/// JOURNEY section. Shows the chapter's icon (greyed), title, and a
/// single hint line — no chain dots, no rewards, no XP pill. The
/// player learns *what* is next and *when* it unlocks without seeing
/// the actual chapter content yet.
class _NextChapterLockedTeaser extends StatelessWidget {
  const _NextChapterLockedTeaser({required this.quest, required this.l10n});

  final EngineQuestProgress quest;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final node = quest.node;
    final asset = node.assetKey;
    final level = quest.levelGate;
    final hint = level != null
        ? l10n.progChapterLockedLabel(level)
        : l10n.progQuestsEmptyLockedTitle;

    return Container(
      padding: const EdgeInsets.all(Tokens.questCardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF111423),
        borderRadius: BorderRadius.circular(Tokens.questCardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (asset != null && asset.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  // Greyscale matrix — chapter art is decorative until
                  // the player unlocks it.
                  0.33, 0.33, 0.33, 0, 0,
                  0.33, 0.33, 0.33, 0, 0,
                  0.33, 0.33, 0.33, 0, 0,
                  0, 0, 0, 0.55, 0,
                ]),
                child: Image.asset(asset, width: 44, height: 44, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white, size: 22),
            ),
          const SizedBox(width: Tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.titleKey(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "VEDLEJŠÍ ÚKOLY KAPITOLY" section — narrative side quests tied
/// to the currently-active chapter. One card per uncompleted side
/// quest; cards disappear individually as they're claimed, and the
/// whole section retires when the chapter finale completes.
/// "DLOUHODOBÉ CÍLE" section. Renders one [EngineLongTermCard] per
/// long-term quest entry. The card aggregates rewards from companion
/// nodes (achievements sharing the same objective), so the player
/// sees XP + items + companion achievements as one row.
class _LongTermSection extends StatelessWidget {
  const _LongTermSection({
    required this.entries,
    required this.chainResolver,
    required this.l10n,
    required this.enabled,
    required this.pillKeyFor,
    required this.onClaim,
    required this.expandedNodeId,
    required this.onToggleExpanded,
  });

  final List<EngineLongTermEntry> entries;
  final List<EngineQuestProgress> Function(String chainId) chainResolver;
  final AppLocalizations l10n;
  final bool enabled;
  final GlobalKey Function(String nodeId) pillKeyFor;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;
  final String? expandedNodeId;
  final void Function(String nodeId) onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EngineQuestSection(
          label: l10n.progQuestsLongTermHeader,
          color: Tokens.accent,
          countLabel: entries.length <= 1
              ? null
              : l10n.progQuestsActiveCount(entries.length),
          isEmpty: true,
          children: const [],
        ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: Tokens.spaceSm),
          EngineLongTermCard(
            entry: entries[i],
            chain: chainResolver(entries[i].quest.node.chainId ?? ''),
            l10n: l10n,
            enabled: enabled,
            pillKey: pillKeyFor(entries[i].quest.nodeId),
            onClaim: onClaim,
            isExpanded: expandedNodeId == entries[i].quest.nodeId,
            onToggle: () => onToggleExpanded(entries[i].quest.nodeId),
          ),
        ],
      ],
    );
  }
}

/// "DOKONČENÉ QUESTY" section. Renders one
/// [EngineCompletedQuestCard] per [EngineCompletedEntry] from the
/// provider. Chains aggregate to a single row whose chain preview
/// grows a dot per progressed step.
class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.entries,
    required this.l10n,
    required this.enabled,
    required this.pillKeyFor,
    required this.onClaim,
    required this.onClaimAll,
    required this.expandedNodeId,
    required this.onToggleExpanded,
  });

  final List<EngineCompletedEntry> entries;
  final AppLocalizations l10n;
  final bool enabled;
  final GlobalKey Function(String nodeId) pillKeyFor;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;
  final Future<void> Function(List<EngineQuestProgress> quests) onClaimAll;
  final String? expandedNodeId;
  final void Function(String nodeId) onToggleExpanded;

  /// Flattens every claimable-but-not-yet-claimed step across all
  /// entries — used by the section's "Vyzvednout vše" button so the
  /// player can drain pending claims in one tap. For non-chain
  /// entries the representative is the only candidate; chain entries
  /// can contribute multiple steps if more than one is simultaneously
  /// claimable.
  List<EngineQuestProgress> get _allClaimable {
    final out = <EngineQuestProgress>[];
    for (final e in entries) {
      final source = e.chainQuests.isEmpty ? [e.representative] : e.chainQuests;
      for (final q in source) {
        if (q.lifecycle is QuestCompletedPendingClaim) out.add(q);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final claimable = _allClaimable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Three-column header row matching the legacy V1 quests
        // screen: section title on the left (filling remaining
        // space), count text in the middle, claim-all pill on the
        // right with a 12 px gap. Keeping the count outside the
        // section widget lets the pill keep its full visual weight
        // without crowding the title row.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: EngineQuestSection(
                label: l10n.progQuestsCompletedHeader,
                color: Tokens.onSurfaceMuted,
                countLabel: null,
                isEmpty: true,
                children: const [],
              ),
            ),
            if (entries.isNotEmpty)
              Text(
                l10n.progQuestsCompletedCount(entries.length),
                style: const TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: Tokens.onSurfaceMuted,
                ),
              ),
            if (claimable.length > 1) ...[
              const SizedBox(width: 12),
              _ClaimAllButton(
                label: l10n.progRewardsClaimAll,
                enabled: enabled,
                onTap: () => onClaimAll(claimable),
              ),
            ],
          ],
        ),
        // Breathing room between the section header row (with the
        // claim-all pill) and the first entry card.
        const SizedBox(height: 10),
        if (entries.isEmpty)
          EngineQuestEmptyLine(
            title: l10n.progQuestsEmptyCompletedTitle,
            caption: l10n.progQuestsEmptyCompletedCaption,
          )
        else
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            EngineCompletedQuestCard(
              entry: entries[i],
              l10n: l10n,
              enabled: enabled,
              pillKey: pillKeyFor(entries[i].representative.nodeId),
              onClaim: onClaim,
              isExpanded:
                  expandedNodeId == entries[i].representative.nodeId,
              onToggle: () =>
                  onToggleExpanded(entries[i].representative.nodeId),
            ),
          ],
      ],
    );
  }
}

/// "ZAMČENÉ QUESTY" section. Renders one [EngineLockedQuestRow] per
/// level-gated quest from [ProgressionEngineProvider.lockedQuests].
/// V1 parity — the chapter quest (e.g. Lesní zkouška) lives here as a
/// compact row until the player reaches its required level, instead
/// of rendering a full chapter card up top.
class _LockedSection extends StatelessWidget {
  const _LockedSection({required this.quests, required this.l10n});

  final List<EngineQuestProgress> quests;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EngineQuestSection(
          label: l10n.progQuestsLockedHeader,
          color: Tokens.onSurfaceMuted,
          countLabel: null,
          isEmpty: true,
          children: const [],
        ),
        Column(
          children: [
            for (var i = 0; i < quests.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              EngineLockedQuestRow(quest: quests[i], l10n: l10n),
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
        // Sized to match the section header text height — V2's
        // EngineQuestSection has an icon (14 px) + caption text, so
        // a pill with the legacy 10/7 padding looked taller than the
        // header row and broke vertical alignment. 8/3 with the micro
        // font keeps the pill readable but lets it sit on the same
        // baseline as the title and count text.
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w800,
            color: enabled ? color : Tokens.onSurfaceFaint,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
