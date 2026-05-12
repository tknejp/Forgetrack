import '../../../../l10n/app_localizations.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/catalog/level_milestone_specs.dart';
import '../../../progression_engine/presentation/adapters/engine_achievement_view.dart';
import '../../domain/journey_levels.dart';
import '../../domain/journey_models.dart';

/// Builds the [JourneyCheckpoint] lists used by the Hero preview, the detail
/// map and the milestone feed. All three views read from the same V2
/// progression engine snapshot so glyphs, dates and labels stay consistent.
///
/// Streak / XP events are intentionally omitted — they fluctuate often and
/// would clutter the journey timeline. Streaks remain visible through their
/// own section on the Hero/Profile screen.
///
/// Level milestone timestamps come from the matching `level_<N>` achievement
/// node's completion event in the V2 ledger. There are no fake or
/// synthesised dates: a milestone without a real timestamp simply gets
/// `null`, which the feed honours by sorting it after dated entries.
///
/// TODO(journey): Replace with a dedicated journey ledger
/// (`GET /journey/events`) once the backend persists level-up, title-unlock
/// and streak-milestone timestamps independently of the achievement table.
abstract final class JourneyAdapter {
  static const int _startLevel = 1;
  static const int _maxLevel = 100;
  static const int _targetMapNodeCount = 30;

  /// The complete static map spine, bottom-to-top in level order.
  /// Sourced from [kJourneyMapAnchors] — the single source of truth for
  /// which levels appear as map anchors. Lives in the journey feature
  /// since "which levels surface on the map" is a journey-display rule
  /// layered on top of the engine catalog.
  static List<int> get _staticMilestoneLevels => kJourneyMapAnchors;

  /// Compact node list for the Hero preview card, derived from the same static
  /// milestone spine as the full map.
  static List<JourneyCheckpoint> buildPreview(
    ProgressionEngineProvider provider,
    AppLocalizations l10n,
  ) {
    final map = buildMilestoneMap(provider, l10n);
    return _nearbyPreviewMilestones(map);
  }

  /// Stable milestone map: level 100 at the top, level 1 at the bottom.
  ///
  /// This intentionally excludes achievements and quests so the map length and
  /// node positions never change when historical feed events are added.
  static List<JourneyCheckpoint> buildMilestoneMap(
    ProgressionEngineProvider provider,
    AppLocalizations l10n,
  ) {
    final currentLevel = _clampLevel(provider.profile.level);
    final achievementViews = buildEngineAchievementViews(provider, l10n);
    final anchors = _buildMilestoneAnchorsFromViews(
      provider: provider,
      l10n: l10n,
      achievementViews: achievementViews,
    );
    final anchorCheckpoints = <JourneyCheckpoint>[];

    for (var i = 0; i < anchors.length; i++) {
      final anchor = anchors[i];
      anchorCheckpoints.add(
        _checkpointForAnchor(
          anchor,
          l10n,
          totalXp: provider.profile.totalXp,
          mapProgress: _anchorProgressAtIndex(i, anchors.length),
          mapUnlockedThroughPointId: anchor.isCurrent ? currentLevel : null,
        ),
      );
    }

    final sideEventLimit =
        (_targetMapNodeCount - anchorCheckpoints.length).clamp(0, 999).toInt();
    final sideEvents = _buildMapSideEvents(
      achievementViews,
      l10n,
      limit: sideEventLimit,
      currentLevel: currentLevel,
      anchorCount: anchors.length,
    );

    return [
      ...anchorCheckpoints,
      ...sideEvents,
    ]..sort(_compareMapCheckpoints);
  }

  /// Data-only version of the static map spine. Useful when a caller needs
  /// levels/titles/status without Journey UI labels.
  static List<JourneyMilestoneAnchor> buildMilestoneAnchors(
    ProgressionEngineProvider provider,
    AppLocalizations l10n,
  ) {
    return _buildMilestoneAnchorsFromViews(
      provider: provider,
      l10n: l10n,
      achievementViews: buildEngineAchievementViews(provider, l10n),
    );
  }

  /// Backwards-compatible map entry point. Prefer [buildMilestoneMap] for new
  /// map callers; [buildFeed] remains the historical event source.
  static List<JourneyCheckpoint> buildFull(
    ProgressionEngineProvider provider,
    AppLocalizations l10n,
  ) =>
      buildMilestoneMap(provider, l10n);

  /// Flat list of milestone events for the detail-screen feed.
  ///
  /// Sorted newest-first, all entries are unlocked. Includes:
  /// - reached title-breakpoint level milestones,
  /// - non-level achievements,
  /// - completed quests.
  ///
  /// Start checkpoint is intentionally not included in the feed; it is a map
  /// origin, not a timeline event with a persisted timestamp.
  static List<JourneyCheckpoint> buildFeed(
    ProgressionEngineProvider provider,
    AppLocalizations l10n,
  ) {
    final profile = provider.profile;
    final achievementViews = buildEngineAchievementViews(provider, l10n);
    final levelDates = _levelUnlockDates(achievementViews);
    final dated = <_DatedCp>[];
    final undated = <JourneyCheckpoint>[];

    // Achievements, excluding level achievements.
    for (final view in achievementViews) {
      if (!view.unlocked || view.unlockedAt == null) continue;
      if (view.levelTarget != null) continue;

      dated.add(
        _DatedCp(
          view.unlockedAt!,
          JourneyCheckpoint(
            id: 'feed_ach_${view.id}',
            type: JourneyEventType.achievement,
            label: view.display.title(l10n),
            sublabel: l10n.journeyEventAchievementUnlocked,
            description: view.display.description(l10n),
            unlockedAt: view.unlockedAt,
            emoji: view.display.badgeEmoji,
            accentColorValue: view.display.accentColor.toARGB32(),
            achievementDifficultyLabel: view.display.rarity.label(l10n),
            isUnlocked: true,
          ),
        ),
      );
    }

    // Quests.
    for (final q in provider.allCompletedQuests) {
      dated.add(
        _DatedCp(
          q.completedAt,
          JourneyCheckpoint(
            id: 'feed_quest_${q.node.id}',
            type: JourneyEventType.quest,
            label: q.node.titleKey(l10n),
            sublabel: l10n.journeyEventQuestCompleted,
            description: q.node.descriptionKey(l10n),
            unlockedAt: q.completedAt,
            isUnlocked: true,
          ),
        ),
      );
    }

    // Level/title milestones.
    //
    // Each milestone is a single row: "Level X · Title".
    // No separate title event is emitted.
    for (final bp in kJourneyTitleBreakpoints) {
      if (bp > profile.level) break;

      final at = levelDates[bp];
      final cp = _breakpointMilestone(
        level: bp,
        unlockedAt: at,
        isUnlocked: true,
        idSuffix: 'feed_',
        l10n: l10n,
      );

      if (at != null) {
        dated.add(_DatedCp(at, cp, timelineRank: bp));
      } else {
        undated.add(cp);
      }
    }

    dated.sort(_compareFeedDatedCheckpoints);
    undated.sort(_compareUndatedFeedCheckpoints);

    return [
      ...dated.map((d) => d.cp),
      ...undated,
    ];
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Maps level → unlockedAt for every unlocked level achievement available.
  static Map<int, DateTime> _levelUnlockDates(
    List<EngineAchievementView> achievementViews,
  ) {
    final out = <int, DateTime>{};

    for (final view in achievementViews) {
      final lvl = view.levelTarget;
      if (lvl == null) continue;
      if (!view.unlocked || view.unlockedAt == null) continue;

      // Multiple achievements may map to the same level defensively; keep the
      // earliest known timestamp.
      final existing = out[lvl];
      if (existing == null || view.unlockedAt!.isBefore(existing)) {
        out[lvl] = view.unlockedAt!;
      }
    }

    return out;
  }

  static List<JourneyMilestoneAnchor> _buildMilestoneAnchorsFromViews({
    required ProgressionEngineProvider provider,
    required AppLocalizations l10n,
    required List<EngineAchievementView> achievementViews,
  }) {
    final currentLevel = _clampLevel(provider.profile.level);
    final currentAnchorLevel = _currentStaticMilestoneFor(currentLevel);
    final nextAnchorLevel = _nextStaticMilestoneAfter(currentLevel);
    final levelDates = _levelUnlockDates(achievementViews);

    return _staticMilestoneLevels.reversed.map((level) {
      final isUnlocked = level <= currentLevel;
      final title = levelMilestoneAtOrBelow(level).titleKey(l10n);

      return JourneyMilestoneAnchor(
        level: level,
        title: title,
        emoji: journeyEmojiForLevel(level),
        isUnlocked: isUnlocked,
        isCurrent: level == currentAnchorLevel,
        isNext: level == nextAnchorLevel,
        unlockedAt: isUnlocked ? levelDates[level] : null,
      );
    }).toList(growable: false);
  }

  static List<JourneyCheckpoint> _buildMapSideEvents(
    List<EngineAchievementView> achievementViews,
    AppLocalizations l10n, {
    required int limit,
    required int currentLevel,
    required int anchorCount,
  }) {
    if (limit <= 0) return const [];

    final dated = <_DatedCp>[];

    for (final view in achievementViews) {
      if (!view.unlocked || view.unlockedAt == null) continue;

      // Level achievements are already represented by the static title path.
      if (view.levelTarget != null) continue;

      dated.add(_DatedCp(
        view.unlockedAt!,
        JourneyCheckpoint(
          id: 'map_ach_${view.id}',
          type: JourneyEventType.achievement,
          label: view.display.title(l10n),
          sublabel: l10n.journeyEventAchievementUnlocked,
          description: view.display.description(l10n),
          unlockedAt: view.unlockedAt,
          emoji: view.display.badgeEmoji,
          accentColorValue: view.display.accentColor.toARGB32(),
          achievementDifficultyLabel: view.display.rarity.label(l10n),
          isUnlocked: true,
          isPathAnchor: false,
          mapPointId: _sideEventPointId(
            index: dated.length,
            total: limit,
            currentLevel: currentLevel,
          ),
        ),
      ));
    }

    if (dated.isEmpty) return const [];

    // Keep the map readable at roughly 30 nodes: newest side events are most
    // relevant, then placed oldest-to-newest from start toward current level.
    dated.sort((a, b) => b.at.compareTo(a.at));
    final selected = dated.take(limit).toList(growable: false)
      ..sort((a, b) => a.at.compareTo(b.at));

    final currentAnchorLevel = _currentStaticMilestoneFor(currentLevel);
    final currentAnchorIndex =
        _staticMilestoneLevels.reversed.toList().indexOf(currentAnchorLevel);
    final currentProgress = _anchorProgressAtIndex(
      currentAnchorIndex < 0 ? anchorCount - 1 : currentAnchorIndex,
      anchorCount,
    );

    final bottomProgress = 0.96;
    final topProgress = (currentProgress + 0.08).clamp(0.12, 0.90).toDouble();
    final span = bottomProgress - topProgress;

    return List<JourneyCheckpoint>.generate(selected.length, (index) {
      final cp = selected[index].cp;
      final t = selected.length == 1 ? 1.0 : index / (selected.length - 1);
      final progress = (bottomProgress - (span * t)).clamp(0.04, 0.98);

      return JourneyCheckpoint(
        id: cp.id,
        type: cp.type,
        label: cp.label,
        sublabel: cp.sublabel,
        description: cp.description,
        unlockedAt: cp.unlockedAt,
        levelNumber: cp.levelNumber,
        title: cp.title,
        emoji: cp.emoji,
        accentColorValue: cp.accentColorValue,
        achievementDifficultyLabel: cp.achievementDifficultyLabel,
        isUnlocked: cp.isUnlocked,
        isCurrent: cp.isCurrent,
        isNext: cp.isNext,
        isPathAnchor: false,
        mapPointId: _sideEventPointId(
          index: index,
          total: selected.length,
          currentLevel: currentLevel,
        ),
        mapProgress: progress.toDouble(),
        mapSide: _sideBiasForId(cp.id),
      );
    }, growable: false);
  }

  static int _clampLevel(int level) {
    if (level < _startLevel) return _startLevel;
    if (level > _maxLevel) return _maxLevel;
    return level;
  }

  static int _currentStaticMilestoneFor(int currentLevel) {
    var currentAnchor = _startLevel;
    for (final level in _staticMilestoneLevels) {
      if (level > currentLevel) break;
      currentAnchor = level;
    }
    return currentAnchor;
  }

  static int? _nextStaticMilestoneAfter(int currentLevel) {
    for (final level in _staticMilestoneLevels) {
      if (level > currentLevel) return level;
    }
    return null;
  }

  static double _anchorProgressAtIndex(int index, int count) {
    if (count <= 1) return 0.5;
    return index / (count - 1);
  }

  static int _sideEventPointId({
    required int index,
    required int total,
    required int currentLevel,
  }) {
    final maxPoint = currentLevel.clamp(_startLevel, _maxLevel);
    if (total <= 1) return maxPoint;
    final t = index / (total - 1);
    return (_startLevel + ((maxPoint - _startLevel) * t))
        .round()
        .clamp(_startLevel, _maxLevel);
  }

  static int _compareMapCheckpoints(JourneyCheckpoint a, JourneyCheckpoint b) {
    final byProgress = (a.mapProgress ?? 1.0).compareTo(b.mapProgress ?? 1.0);
    if (byProgress != 0) return byProgress;
    if (a.isPathAnchor != b.isPathAnchor) return a.isPathAnchor ? -1 : 1;
    return a.id.compareTo(b.id);
  }

  static int _compareFeedDatedCheckpoints(_DatedCp a, _DatedCp b) {
    final byDate = b.at.compareTo(a.at);
    if (byDate != 0) return byDate;

    // Level achievements can be backfilled with the same unlock timestamp
    // when the profile is evaluated after several levels were already earned.
    // In that case, keep the timeline intuitive by showing later levels first.
    final byRank = b.timelineRank.compareTo(a.timelineRank);
    if (byRank != 0) return byRank;

    return a.cp.id.compareTo(b.cp.id);
  }

  static int _compareUndatedFeedCheckpoints(
    JourneyCheckpoint a,
    JourneyCheckpoint b,
  ) {
    final byLevel = (b.levelNumber ?? 0).compareTo(a.levelNumber ?? 0);
    if (byLevel != 0) return byLevel;
    return a.id.compareTo(b.id);
  }

  static double _sideBiasForId(String id) {
    final hash = _stableHash(id);
    final direction = hash.isEven ? -1.0 : 1.0;
    final magnitude = 0.52 + ((hash % 7) * 0.12);
    return direction * magnitude;
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static List<JourneyCheckpoint> _nearbyPreviewMilestones(
    List<JourneyCheckpoint> map,
  ) {
    if (map.isEmpty) return const [];

    final indexes = <int>[];
    void addIndex(int index) {
      if (index < 0 || index >= map.length || indexes.contains(index)) return;
      if (indexes.length >= 5) return;
      indexes.add(index);
    }

    final currentIndex = map.indexWhere((cp) => cp.isCurrent);
    final focusIndex = currentIndex >= 0
        ? currentIndex
        : map.indexWhere((cp) => cp.isPathAnchor && cp.isUnlocked);
    final nextIndex = map.indexWhere((cp) => cp.isPathAnchor && cp.isNext);

    addIndex(nextIndex);
    addIndex(focusIndex);

    for (var i = focusIndex + 1; i < map.length && indexes.length < 5; i++) {
      if (map[i].isPathAnchor && map[i].isUnlocked) addIndex(i);
    }

    for (var i = focusIndex - 1; i >= 0 && indexes.length < 5; i--) {
      if (map[i].isPathAnchor && !map[i].isUnlocked) addIndex(i);
    }

    indexes.sort();
    return indexes.map((i) => map[i]).toList(growable: false);
  }

  static JourneyCheckpoint _checkpointForAnchor(
    JourneyMilestoneAnchor anchor,
    AppLocalizations l10n, {
    required int totalXp,
    required double mapProgress,
    required int? mapUnlockedThroughPointId,
  }) {
    if (anchor.level == _startLevel) {
      return _startCheckpoint(
        anchor,
        l10n,
        mapProgress: mapProgress,
        mapUnlockedThroughPointId: mapUnlockedThroughPointId,
      );
    }

    return JourneyCheckpoint(
      id: 'level_${anchor.level}',
      type: JourneyEventType.titleMilestone,
      label: l10n.journeyLevelWithTitle(anchor.level, anchor.title),
      description: anchor.isCurrent ? l10n.journeyTotalXp(totalXp) : null,
      unlockedAt: anchor.unlockedAt,
      levelNumber: anchor.level,
      title: anchor.title,
      emoji: anchor.emoji,
      isUnlocked: anchor.isUnlocked,
      isCurrent: anchor.isCurrent,
      isNext: anchor.isNext,
      mapPointId: anchor.level,
      mapUnlockedThroughPointId: mapUnlockedThroughPointId,
      mapProgress: mapProgress,
    );
  }

  /// Permanent bottom node that gives the map a clear origin.
  static JourneyCheckpoint _startCheckpoint(
    JourneyMilestoneAnchor anchor,
    AppLocalizations l10n, {
    required double mapProgress,
    required int? mapUnlockedThroughPointId,
  }) {
    return JourneyCheckpoint(
      id: 'start',
      type: JourneyEventType.level,
      label: l10n.journeyStartLabel,
      sublabel: l10n.journeyStartSublabel(anchor.level, anchor.title),
      description: l10n.journeyStartDescription,
      unlockedAt: anchor.unlockedAt,
      levelNumber: anchor.level,
      title: anchor.title,
      emoji: anchor.emoji,
      isUnlocked: true,
      isCurrent: anchor.isCurrent,
      isNext: anchor.isNext,
      mapPointId: 0,
      mapUnlockedThroughPointId: mapUnlockedThroughPointId,
      mapProgress: mapProgress,
    );
  }

  /// Single source for level/title milestone nodes.
  static JourneyCheckpoint _breakpointMilestone({
    required int level,
    required DateTime? unlockedAt,
    required bool isUnlocked,
    required AppLocalizations l10n,
    String idSuffix = '',
  }) {
    final title = levelMilestoneAtOrBelow(level).titleKey(l10n);

    return JourneyCheckpoint(
      id: '${idSuffix}level_$level',
      type: JourneyEventType.titleMilestone,
      label: l10n.journeyLevelWithTitle(level, title),
      sublabel: null,
      unlockedAt: unlockedAt,
      levelNumber: level,
      title: title,
      emoji: journeyEmojiForLevel(level),
      isUnlocked: isUnlocked,
    );
  }
}

class _DatedCp {
  const _DatedCp(
    this.at,
    this.cp, {
    this.timelineRank = 0,
  });

  final DateTime at;
  final JourneyCheckpoint cp;
  final int timelineRank;
}
