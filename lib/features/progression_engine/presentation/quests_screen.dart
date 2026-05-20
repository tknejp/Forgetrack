import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/xp_sparkle_overlay.dart';
import '../../cosmetics/domain/companion_buff.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import '../application/progression_engine_provider.dart';
import '../domain/catalog/progression_node_catalog.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ProgressionEngineProvider>();
    final daily = provider.currentDailyQuests;

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

    // Phase 19 of the domain refactor moved lifecycle filtering off
    // this build() and into the provider as per-bucket projections:
    // `currentDailyUnclaimedQuests`, `currentWeeklyActiveQuests`.
    // The widget reads hot lists and only switches on `q.lifecycle`
    // for per-card rendering. Domain semantics (which lifecycle stays
    // in the daily slot, which weekly moves to DOKONČENÉ) are
    // documented on the provider getters. The legacy claimable
    // slices were used by the now-removed "Vyzvednout vše" header
    // pill — taps are per-card again.
    final dailyUnclaimed = provider.currentDailyUnclaimedQuests;
    final weeklyActive = provider.currentWeeklyActiveQuests;
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
                        pillKeyFor: _pillKeyFor,
                        onClaim: _claimQuest,
                        expandedNodeId: _expandedNodeId,
                        onToggleExpanded: _toggleExpanded,
                        nextLocked: provider.nextLockedChapter,
                        companionBuffBonusFor: (q) =>
                            provider.projectedCompanionBuffBonusFor(q.node),
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
                      l10n: l10n,
                      hint: l10n.progQuestsDailyTasksHint,
                      quests: daily,
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
                      streakFor: (q) =>
                          provider.streakForObjective(q.node.objectiveId),
                      expandedNodeId: _expandedNodeId,
                      onToggleExpanded: _toggleExpanded,
                      chainResolver: provider.chainQuestsFor,
                      companionBuffBonusFor: (q) =>
                          provider.projectedCompanionBuffBonusFor(q.node),
                      equippedCompanionBuff: provider.equippedCompanionBuff,
                      streakBuffPercentFor: (q) =>
                          provider.projectedStreakBuffPercentFor(q.node),
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
                      l10n: l10n,
                      quests: weeklyActive,
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
                      streakFor: (q) =>
                          provider.streakForObjective(q.node.objectiveId),
                      expandedNodeId: _expandedNodeId,
                      onToggleExpanded: _toggleExpanded,
                      companionBuffBonusFor: (q) =>
                          provider.projectedCompanionBuffBonusFor(q.node),
                      equippedCompanionBuff: provider.equippedCompanionBuff,
                      streakBuffPercentFor: (q) =>
                          provider.projectedStreakBuffPercentFor(q.node),
                    ),
                    if (longTerm.isNotEmpty) ...[
                      const SizedBox(height: Tokens.spaceXl),
                      _LongTermSection(
                        entries: longTerm,
                        chainResolver: provider.chainQuestsFor,
                        l10n: l10n,
                        pillKeyFor: _pillKeyFor,
                        onClaim: _claimQuest,
                        expandedNodeId: _expandedNodeId,
                        onToggleExpanded: _toggleExpanded,
                        companionBuffBonusFor: (q) =>
                            provider.projectedCompanionBuffBonusFor(q.node),
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
                      pillKeyFor: _pillKeyFor,
                      onClaim: _claimQuest,
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
    required this.l10n,
    required this.quests,
    required this.pillKeyFor,
    required this.onClaim,
    this.streakFor,
    this.expandedNodeId,
    this.onToggleExpanded,
    this.hint,
    this.chainResolver,
    this.companionBuffBonusFor,
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

  /// Resolves the streak summary for a given quest. Used by the card
  /// to render a 🔥 chip and the best-streak detail line. Optional —
  /// tests can pass null to skip the streak path.
  final EngineStreakSummary Function(EngineQuestProgress quest)? streakFor;

  /// Resolves the projected companion-buff bonus for a given quest
  /// — driven by [ProgressionEngineProvider.projectedCompanionBuffBonusFor]
  /// at the screen layer. The card renders a small chip beside the
  /// XP pill when this returns > 0. Optional — tests pass null and
  /// the bonus chip stays hidden.
  final int Function(EngineQuestProgress quest)? companionBuffBonusFor;

  /// The player's equipped companion buff. Threaded into each card
  /// so its streak chip can switch between plain / live / locked
  /// visual states without re-reading the provider.
  final CompanionBuff? equippedCompanionBuff;

  /// Resolves the streak-buff percent for a given quest, evaluated
  /// against that quest's own streak domain. Wired from
  /// [ProgressionEngineProvider.projectedStreakBuffPercentFor].
  final int Function(EngineQuestProgress quest)? streakBuffPercentFor;

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
        EngineQuestSection(
          label: header,
          color: color,
          countLabel: countLabel,
          isEmpty: true,
          children: const [],
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
                  key: ValueKey(quests[i].nodeId),
                  quest: quests[i],
                  l10n: l10n,
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
                  companionBuffBonus:
                      companionBuffBonusFor?.call(quests[i]) ?? 0,
                  equippedCompanionBuff: equippedCompanionBuff,
                  streakBuffPercent:
                      streakBuffPercentFor?.call(quests[i]) ?? 0,
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
    required this.pillKeyFor,
    required this.onClaim,
    required this.expandedNodeId,
    required this.onToggleExpanded,
    this.nextLocked,
    this.companionBuffBonusFor,
  });

  final List<EngineQuestProgress> chapters;
  final List<EngineQuestProgress> Function(String chainId) chainResolver;
  final AppLocalizations l10n;
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

  /// Resolves the projected companion-buff bonus per chapter quest.
  /// Wired from the screen with
  /// `provider.projectedCompanionBuffBonusFor(quest.node)`.
  final int Function(EngineQuestProgress quest)? companionBuffBonusFor;

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
            key: ValueKey(chapters[i].nodeId),
            quest: chapters[i],
            chain: chainResolver(chapters[i].node.chainId ?? ''),
            l10n: l10n,
            pillKey: pillKeyFor(chapters[i].nodeId),
            onClaim: onClaim,
            isExpanded: expandedNodeId == chapters[i].nodeId,
            onToggle: () => onToggleExpanded(chapters[i].nodeId),
            companionBuffBonus:
                companionBuffBonusFor?.call(chapters[i]) ?? 0,
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
    final prereqId = quest.prereqGateNodeId;
    // Prefer the prereq hint (= "Dokonči [previous chapter finale]")
    // when the chapter is gated by a cross-chapter NodeCompleted
    // condition rather than a level threshold. Mirrors
    // `EngineLockedQuestRow._resolveSubtitle`. Falls back to the level
    // hint, then to a generic "soon" copy so the teaser never reads
    // as the empty-locked-section title (Trello #66 follow-up — the
    // old fallback to `progQuestsEmptyLockedTitle` rendered as "Teď
    // tu nejsou žádné zamčené questy", which is a section header, not
    // a per-chapter caption).
    String? prereqTitle;
    if (prereqId != null) {
      final node = ProgressionEntryCatalog.definitionForId(prereqId);
      prereqTitle = switch (node) {
        Quest(:final titleKey) => titleKey(l10n),
        Achievement(:final titleKey) => titleKey(l10n),
        Milestone(:final titleKey) => titleKey(l10n),
        LevelMilestone(:final titleKey) => titleKey(l10n),
        _ => null,
      };
    }
    final String hint;
    if (prereqTitle != null && prereqTitle.isNotEmpty) {
      hint = l10n.progQuestDetailCompleteQuest(prereqTitle);
    } else if (level != null) {
      hint = l10n.progChapterLockedLabel(level);
    } else {
      hint = l10n.progChapterLockedSoon;
    }

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
    required this.pillKeyFor,
    required this.onClaim,
    required this.expandedNodeId,
    required this.onToggleExpanded,
    this.companionBuffBonusFor,
  });

  final List<EngineLongTermEntry> entries;
  final List<EngineQuestProgress> Function(String chainId) chainResolver;
  final AppLocalizations l10n;
  final GlobalKey Function(String nodeId) pillKeyFor;
  final Future<void> Function(EngineQuestProgress quest, {Offset? from})
      onClaim;
  final String? expandedNodeId;
  final void Function(String nodeId) onToggleExpanded;

  /// Resolves the projected companion-buff bonus per long-term
  /// quest. Wired from the screen the same way the chapter section
  /// and quest panels do.
  final int Function(EngineQuestProgress quest)? companionBuffBonusFor;

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
            key: ValueKey(entries[i].quest.nodeId),
            entry: entries[i],
            chain: chainResolver(entries[i].quest.node.chainId ?? ''),
            l10n: l10n,
            pillKey: pillKeyFor(entries[i].quest.nodeId),
            onClaim: onClaim,
            isExpanded: expandedNodeId == entries[i].quest.nodeId,
            onToggle: () => onToggleExpanded(entries[i].quest.nodeId),
            companionBuffBonus:
                companionBuffBonusFor?.call(entries[i].quest) ?? 0,
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
    required this.pillKeyFor,
    required this.onClaim,
    required this.expandedNodeId,
    required this.onToggleExpanded,
  });

  final List<EngineCompletedEntry> entries;
  final AppLocalizations l10n;
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
          label: l10n.progQuestsCompletedHeader,
          color: Tokens.onSurfaceMuted,
          countLabel: entries.isEmpty
              ? null
              : l10n.progQuestsCompletedCount(entries.length),
          isEmpty: true,
          children: const [],
        ),
        // Breathing room between the section header row and the
        // first entry card. Mirrors the gap the section's internal
        // `SizedBox(10)` leaves when children render — kept here so
        // the empty state and entry list start at the same offset.
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
              key: ValueKey(entries[i].representative.nodeId),
              entry: entries[i],
              l10n: l10n,
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

