import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/xp_sparkle_overlay.dart';
import '../application/progression_engine_provider.dart';
import 'sections/next_chapter_locked_teaser.dart';
import 'sections/quest_section_panel.dart';
import 'widgets/engine_backfill_section.dart';
import 'widgets/engine_chapter_card.dart';
import 'widgets/engine_completed_quest_card.dart';
import 'widgets/engine_locked_quest_row.dart';
import 'widgets/engine_long_term_card.dart';
import 'widgets/engine_quest_card.dart';
import 'widgets/engine_quest_section.dart';
import 'widgets/expanded_quest_scope.dart';

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
  ///
  /// Stored as a [ValueNotifier] so that toggling expansion does NOT
  /// rebuild [QuestsScreenV2] — only the two cards involved in the flip
  /// rebuild via [ExpandedQuestScope]'s aspect-based notification.
  /// Previously a `String?` field flipped via `setState`, which
  /// invalidated the whole screen build (~90 ms per tap, 2026-05-22
  /// trace) because every card got new constructor closures.
  final ValueNotifier<String?> _expandedNodeId = ValueNotifier(null);

  GlobalKey _pillKeyFor(String nodeId) =>
      _pillKeys.putIfAbsent(nodeId, () => GlobalKey(debugLabel: nodeId));

  void _toggleExpanded(String nodeId) {
    _expandedNodeId.value =
        _expandedNodeId.value == nodeId ? null : nodeId;
  }

  @override
  void dispose() {
    _expandedNodeId.dispose();
    super.dispose();
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
    final nextLocked = provider.nextLockedChapter;

    // Phase 1.1 perf fix: build a flat list of ListView children so
    // each card is its own lazy mount unit. `ListView(children: [...])`
    // uses `SliverChildListDelegate` whose lazy element creation runs
    // per top-level child — when each top-level child is a SECTION
    // containing N cards in a Column, mounting the section eagerly
    // mounts all N cards in one frame. Pre-Phase-1.1 trace: 4 BUILDs
    // per scroll-jank frame inside a single LAYOUT pass = a section
    // boundary entering the cache window. By splatting each section's
    // header, hint, empty-line, cards, and spacers as top-level
    // entries, lazy mounting now runs PER-CARD as it crosses the cache
    // boundary, spreading the build cost across many scroll ticks.
    final items = <Widget>[];

    if (chapters.isNotEmpty || nextLocked != null) {
      items.addAll(_buildChapterItems(
        chapters: chapters,
        nextLocked: nextLocked,
        provider: provider,
        l10n: l10n,
      ));
      items.add(const SizedBox(height: Tokens.spaceXl));
    }

    items.addAll(buildQuestSectionItems(
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
      streakFor: (q) => provider.streakForObjective(q.node.objectiveId),
      onToggleExpanded: _toggleExpanded,
      chainResolver: provider.chainQuestsFor,
      companionBuffBonusFor: (q) =>
          provider.projectedCompanionBuffBonusFor(q.node),
      emblemBuffBonusFor: (q) =>
          provider.projectedEmblemBuffBonusFor(q.node),
      equippedCompanionBuff: provider.equippedCompanionBuff,
      streakBuffPercentFor: (q) =>
          provider.projectedStreakBuffPercentFor(q.node),
    ));
    items.add(const SizedBox(height: Tokens.spaceXl));

    items.addAll(buildQuestSectionItems(
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
      streakFor: (q) => provider.streakForObjective(q.node.objectiveId),
      onToggleExpanded: _toggleExpanded,
      companionBuffBonusFor: (q) =>
          provider.projectedCompanionBuffBonusFor(q.node),
      emblemBuffBonusFor: (q) =>
          provider.projectedEmblemBuffBonusFor(q.node),
      equippedCompanionBuff: provider.equippedCompanionBuff,
      streakBuffPercentFor: (q) =>
          provider.projectedStreakBuffPercentFor(q.node),
    ));

    if (longTerm.isNotEmpty) {
      items.add(const SizedBox(height: Tokens.spaceXl));
      items.addAll(_buildLongTermItems(
        entries: longTerm,
        provider: provider,
        l10n: l10n,
      ));
    }

    if (locked.isNotEmpty) {
      items.add(const SizedBox(height: Tokens.spaceXl));
      items.addAll(_buildLockedItems(quests: locked, l10n: l10n));
    }

    items.add(const SizedBox(height: Tokens.spaceXl));
    items.addAll(_buildCompletedItems(entries: completed, l10n: l10n));

    items.add(const SizedBox(height: Tokens.spaceXl));
    items.add(EngineBackfillSection(barKey: widget.barKey, l10n: l10n));

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
                // Wrap the ListView in a ValueListenableBuilder whose
                // `child` is the ListView itself, so the cards built
                // inside it are kept stable across expand toggles. The
                // builder rebuilds only the ExpandedQuestScope on each
                // tick of `_expandedNodeId`; the scope's
                // [InheritedModel] aspect-based notification then marks
                // only the two affected cards dirty (the old + new
                // expanded ids).
                child: ValueListenableBuilder<String?>(
                  valueListenable: _expandedNodeId,
                  builder: (context, expandedId, child) {
                    return ExpandedQuestScope(
                      expandedNodeId: expandedId,
                      child: child!,
                    );
                  },
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
                    children: items,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Per-section item builders ──────────────────────────────────────
  //
  // Each helper returns a flat List<Widget> the screen splats into
  // ListView.children. Items: section header row, optional hint, then
  // each card (with inline spacers between them). Keeping these as
  // methods on State — not standalone widget classes — is what makes
  // every card a top-level ListView entry. A widget class wrapping
  // cards in a Column would re-collapse mounting back to "all cards in
  // one shot" (the pre-Phase-1.1 jank).

  List<Widget> _buildChapterItems({
    required List<EngineQuestProgress> chapters,
    required EngineQuestProgress? nextLocked,
    required ProgressionEngineProvider provider,
    required AppLocalizations l10n,
  }) {
    final items = <Widget>[
      EngineQuestSection(
        label: l10n.progQuestsChapterHeader,
        color: Tokens.accent,
        countLabel: chapters.length == 1
            ? null
            : l10n.progQuestsActiveCount(chapters.length),
        isEmpty: true,
        children: const [],
      ),
    ];

    for (var i = 0; i < chapters.length; i++) {
      if (i > 0) items.add(const SizedBox(height: Tokens.spaceSm));
      final c = chapters[i];
      items.add(
        EngineChapterCard(
          key: ValueKey(c.nodeId),
          quest: c,
          chain: provider.chainQuestsFor(c.node.chainId ?? ''),
          l10n: l10n,
          pillKey: _pillKeyFor(c.nodeId),
          onClaim: _claimQuest,
          onToggle: () => _toggleExpanded(c.nodeId),
          companionBuffBonus: provider.projectedCompanionBuffBonusFor(c.node),
        ),
      );
    }

    if (nextLocked != null) {
      if (chapters.isNotEmpty) {
        items.add(const SizedBox(height: Tokens.spaceSm));
      }
      items.add(NextChapterLockedTeaser(quest: nextLocked, l10n: l10n));
    }

    return items;
  }

  List<Widget> _buildLongTermItems({
    required List<EngineLongTermEntry> entries,
    required ProgressionEngineProvider provider,
    required AppLocalizations l10n,
  }) {
    final items = <Widget>[
      EngineQuestSection(
        label: l10n.progQuestsLongTermHeader,
        color: Tokens.accent,
        countLabel: entries.length <= 1
            ? null
            : l10n.progQuestsActiveCount(entries.length),
        isEmpty: true,
        children: const [],
      ),
    ];

    for (var i = 0; i < entries.length; i++) {
      if (i > 0) items.add(const SizedBox(height: Tokens.spaceSm));
      final e = entries[i];
      items.add(
        EngineLongTermCard(
          key: ValueKey(e.quest.nodeId),
          entry: e,
          chain: provider.chainQuestsFor(e.quest.node.chainId ?? ''),
          l10n: l10n,
          pillKey: _pillKeyFor(e.quest.nodeId),
          onClaim: _claimQuest,
          onToggle: () => _toggleExpanded(e.quest.nodeId),
          companionBuffBonus:
              provider.projectedCompanionBuffBonusFor(e.quest.node),
        ),
      );
    }

    return items;
  }

  List<Widget> _buildCompletedItems({
    required List<EngineCompletedEntry> entries,
    required AppLocalizations l10n,
  }) {
    final items = <Widget>[
      EngineQuestSection(
        label: l10n.progQuestsCompletedHeader,
        color: Tokens.onSurfaceMuted,
        countLabel: entries.isEmpty
            ? null
            : l10n.progQuestsCompletedCount(entries.length),
        isEmpty: true,
        children: const [],
      ),
      // Breathing room between the section header row and the first
      // entry card. Mirrors the gap the section's internal
      // `SizedBox(10)` leaves when children render — kept here so the
      // empty state and entry list start at the same offset.
      const SizedBox(height: 10),
    ];

    if (entries.isEmpty) {
      items.add(
        EngineQuestEmptyLine(
          title: l10n.progQuestsEmptyCompletedTitle,
          caption: l10n.progQuestsEmptyCompletedCaption,
        ),
      );
    } else {
      for (var i = 0; i < entries.length; i++) {
        if (i > 0) items.add(const SizedBox(height: 6));
        final e = entries[i];
        items.add(
          EngineCompletedQuestCard(
            key: ValueKey(e.representative.nodeId),
            entry: e,
            l10n: l10n,
            pillKey: _pillKeyFor(e.representative.nodeId),
            onClaim: _claimQuest,
            onToggle: () => _toggleExpanded(e.representative.nodeId),
          ),
        );
      }
    }

    return items;
  }

  List<Widget> _buildLockedItems({
    required List<EngineQuestProgress> quests,
    required AppLocalizations l10n,
  }) {
    final items = <Widget>[
      EngineQuestSection(
        label: l10n.progQuestsLockedHeader,
        color: Tokens.onSurfaceMuted,
        countLabel: null,
        isEmpty: true,
        children: const [],
      ),
    ];

    for (var i = 0; i < quests.length; i++) {
      if (i > 0) items.add(const SizedBox(height: 6));
      items.add(EngineLockedQuestRow(quest: quests[i], l10n: l10n));
    }

    return items;
  }
}
