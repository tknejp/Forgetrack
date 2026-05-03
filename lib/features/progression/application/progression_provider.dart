import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../devtools/application/devtools_sync_logger.dart';
import '../../devtools/domain/devtools_sync_event.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/notification_service.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../application/cosmetic_unlock_dispatcher.dart';
import '../application/progression_engine.dart';
import '../data/provider_progression_source.dart';
import '../domain/cosmetic_reward_table.dart';
import '../domain/progression_level_config.dart';
import '../domain/progression_models.dart';
import '../presentation/progression_l10n.dart';

class ProgressionDomainRangeSummary {
  const ProgressionDomainRangeSummary({
    required this.earnedXp,
    required this.grantCount,
  });

  final int earnedXp;
  final int grantCount;
}

class ProgressionStreakView {
  const ProgressionStreakView({
    required this.currentStreak,
    required this.bestStreak,
    this.latestPeriodStart,
    this.lastAchievedPeriodStart,
  });

  const ProgressionStreakView.empty()
      : currentStreak = 0,
        bestStreak = 0,
        latestPeriodStart = null,
        lastAchievedPeriodStart = null;

  final int currentStreak;
  final int bestStreak;
  final DateTime? latestPeriodStart;
  final DateTime? lastAchievedPeriodStart;
}

enum ProgressionCelebrationKind {
  levelMilestone,
  achievementUnlocked,
  cosmeticUnlocked,
}

class ProgressionCelebrationEvent {
  const ProgressionCelebrationEvent({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.level,
    this.achievement,
    this.cosmeticIds = const [],
  });

  final String id;
  final ProgressionCelebrationKind kind;
  final DateTime createdAt;
  final int? level;
  final ProgressionAchievement? achievement;
  final List<String> cosmeticIds;
}

class ProgressionProvider extends ChangeNotifier {
  ProgressionProvider({
    required ProgressionEngine engine,
    CosmeticUnlockDispatcher? cosmeticUnlockDispatcher,
    CosmeticRewardTable cosmeticRewardTable = const CosmeticRewardTable(),
  })  : _engine = engine,
        _cosmeticUnlockDispatcher =
            cosmeticUnlockDispatcher ?? CosmeticUnlockDispatcher(),
        _cosmeticRewardTable = cosmeticRewardTable {
    unawaited(_hydrate());
  }

  final ProgressionEngine _engine;
  final CosmeticUnlockDispatcher _cosmeticUnlockDispatcher;
  final CosmeticRewardTable _cosmeticRewardTable;

  ProgressionEngineState? _state;
  ProviderProgressionSource? _source;
  final List<ProgressionCelebrationEvent> _celebrationQueue = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _refreshQueued = false;
  String? _error;
  String? _lastRequestedSignature;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastEvaluatedAt => _state?.lastEvaluatedAt;
  List<ProgressionCelebrationEvent> get pendingCelebrations =>
      List.unmodifiable(_celebrationQueue);

  ProgressionCelebrationEvent? takeNextCelebration() {
    if (_celebrationQueue.isEmpty) return null;
    return _celebrationQueue.removeAt(0);
  }

  ProgressionProfile get profile =>
      _state?.profile ??
      const ProgressionProfile(
        totalXp: 0,
        level: 1,
        levelFloorXp: 0,
        nextLevelXp: 250,
        xpIntoLevel: 0,
      );

  List<ProgressionEvaluation> get evaluations =>
      _state?.evaluations ?? const [];
  List<ProgressionRewardGrant> get rewardGrants =>
      _state?.rewardGrants ?? const [];
  List<ProgressionQuestRewardGrant> get questRewardGrants =>
      _state?.questRewardGrants ?? const [];
  List<ProgressionRewardGrant> get pendingRewards =>
      rewardGrants.where((grant) => grant.isUnlocked).toList(growable: false);
  List<ProgressionRewardGrant> get claimedRewards =>
      rewardGrants.where((grant) => grant.isClaimed).toList(growable: false);
  List<ProgressionQuestRewardGrant> get pendingQuestRewards => questRewardGrants
      .where((grant) => grant.isUnlocked)
      .toList(growable: false);
  List<ProgressionQuestRewardGrant> get claimedQuestRewards => questRewardGrants
      .where((grant) => grant.isClaimed)
      .toList(growable: false);
  List<ProgressionAchievement> get achievements =>
      _state?.achievements ?? const [];
  List<ProgressionQuest> get quests => _state?.quests ?? const [];
  List<ProgressionQuest> get highlightedQuests =>
      quests.where((quest) => quest.isHighlighted).toList();
  List<ProgressionQuest> get availableQuests => quests
      .where((quest) => quest.status == ProgressionQuestStatus.available)
      .toList();
  List<ProgressionQuest> get activeQuests => quests
      .where((quest) => quest.status == ProgressionQuestStatus.active)
      .toList();
  List<ProgressionQuest> get lockedQuests => quests
      .where((quest) => quest.status == ProgressionQuestStatus.locked)
      .toList();
  List<ProgressionQuest> get completedQuests => quests
      .where((quest) => quest.status == ProgressionQuestStatus.completed)
      .toList();
  List<ProgressionQuest> get journeyQuests => quests
      .where((quest) => quest.category == ProgressionQuestCategory.journey)
      .toList();
  List<ProgressionQuest> get dailyQuests => quests
      .where((quest) => quest.category == ProgressionQuestCategory.daily)
      .toList();
  List<ProgressionQuest> get weeklyQuests => quests
      .where((quest) => quest.category == ProgressionQuestCategory.weekly)
      .toList();
  List<ProgressionQuest> get chainQuests => quests
      .where((quest) => quest.category == ProgressionQuestCategory.chain)
      .toList();

  ProgressionQuest? questById(String questId) {
    for (final quest in quests) {
      if (quest.id == questId) {
        return quest;
      }
    }
    return null;
  }

  ProgressionStreakView streakForRule(String ruleId) {
    final summary = _state?.streaksByRuleId[ruleId];
    if (summary == null) return const ProgressionStreakView.empty();
    return ProgressionStreakView(
      currentStreak: summary.currentStreak,
      bestStreak: summary.bestStreak,
      latestPeriodStart: summary.latestPeriodStart,
      lastAchievedPeriodStart: summary.lastAchievedPeriodStart,
    );
  }

  ProgressionStreakView streakForDomain(ProgressionDomain domain) {
    final summary = _state?.streaksByDomain[domain];
    if (summary == null) return const ProgressionStreakView.empty();
    return ProgressionStreakView(
      currentStreak: summary.currentStreak,
      bestStreak: summary.bestStreak,
      latestPeriodStart: summary.latestPeriodStart,
      lastAchievedPeriodStart: summary.lastAchievedPeriodStart,
    );
  }

  // ---------------------------------------------------------------------------
  // Devtools — never call from production code paths.
  // ---------------------------------------------------------------------------

  /// Wipes the local + cloud progression ledger and refreshes the provider
  /// state. Resets the user back to level 1 / 0 XP. Used by the in-app
  /// devtools panel only.
  Future<void> devToolsResetProgression() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      _state = await _engine.devToolsResetLedger();
      _error = null;
      // Force the next bind() to re-trigger a real evaluation rather than
      // dedupe by signature.
      _lastRequestedSignature = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Wipes the ledger and inserts a synthetic claimed grant equal to [xp],
  /// then refreshes the provider state. Resulting profile is exactly [xp]
  /// total XP at the policy-derived level.
  Future<void> devToolsSetTotalXp(int xp) async {
    _isRefreshing = true;
    notifyListeners();
    try {
      final prevState = _state;
      _state = await _engine.devToolsSetTotalXp(xp);
      _error = null;
      _lastRequestedSignature = null;
      final cosmeticDispatch = await _cosmeticUnlockDispatcher.dispatch(
        previous: prevState,
        current: _state!,
      );
      _queueCelebrations(
        previous: prevState,
        current: _state!,
        cosmeticDispatch: cosmeticDispatch,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Inserts a synthetic achievement unlock and re-dispatches cosmetics.
  Future<void> devToolsGrantAchievement(String achievementId) async {
    _isRefreshing = true;
    notifyListeners();
    try {
      final prevState = _state;
      _state = await _engine.devToolsGrantAchievement(achievementId);
      _error = null;
      _lastRequestedSignature = null;
      final cosmeticDispatch = await _cosmeticUnlockDispatcher.dispatch(
        previous: prevState,
        current: _state!,
      );
      _queueCelebrations(
        previous: prevState,
        current: _state!,
        cosmeticDispatch: cosmeticDispatch,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void bind({
    required GoalsProvider goalsProvider,
    required FitnessProvider fitnessProvider,
    required KalorickeTabulkyProvider nutritionProvider,
    CosmeticsProvider? cosmeticsProvider,
  }) {
    _source = ProviderProgressionSource(
      goalsProvider: goalsProvider,
      fitnessProvider: fitnessProvider,
      nutritionProvider: nutritionProvider,
    );

    if (cosmeticsProvider != null) {
      _cosmeticUnlockDispatcher.bindCosmetics(cosmeticsProvider);
    }

    final signature = _source!.auditSignature;
    if (_lastRequestedSignature == signature) {
      return;
    }

    _lastRequestedSignature = signature;
    unawaited(refresh());
  }

  Future<void> refresh() async {
    final source = _source;
    if (source == null) return;

    if (_isRefreshing) {
      _refreshQueued = true;
      return;
    }

    final syncStart = DateTime.now();
    _isRefreshing = true;
    notifyListeners();

    // Snapshot před synchem pro diff notifikací
    final prevGrantKeys =
        _state?.questRewardGrants.map((g) => g.rewardKey).toSet() ?? {};
    final prevUnlockedIds = _state?.achievements
            .where((a) => a.unlocked)
            .map((a) => a.id)
            .toSet() ??
        {};
    final prevState = _state;
    final hadState = _state != null;

    String? syncError;
    try {
      _state = await _engine.sync(source);
      _error = null;
      if (hadState) {
        unawaited(
            _emitProgressionNotifications(prevGrantKeys, prevUnlockedIds));
      }
      final cosmeticDispatch = await _cosmeticUnlockDispatcher.dispatch(
        previous: prevState,
        current: _state!,
      );
      if (hadState) {
        _queueCelebrations(
          previous: prevState,
          current: _state!,
          cosmeticDispatch: cosmeticDispatch,
        );
      }
    } catch (error) {
      _error = error.toString();
      syncError = error.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }

    unawaited(DevToolsSyncLogger.instance.record(DevToolsSyncEvent(
      timestamp: syncStart,
      source: 'foreground',
      feature: 'progression',
      result: syncError != null ? 'failure' : 'success',
      durationMs: DateTime.now().difference(syncStart).inMilliseconds,
      errorMessage: syncError,
      extra: {
        'level': profile.level,
        'totalXp': profile.totalXp,
      },
    )));

    final latestSignature = _source?.auditSignature;
    if (_refreshQueued || latestSignature != _lastRequestedSignature) {
      _refreshQueued = false;
      _lastRequestedSignature = latestSignature;
      unawaited(refresh());
    }
  }

  Future<void> claimReward(String rewardKey) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final prevState = _state;
      _state = await _engine.claimReward(rewardKey);
      _error = null;
      await _afterStateChange(prevState, _state!);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> claimAllRewards() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final prevState = _state;
      _state = await _engine.claimAllRewards();
      _error = null;
      await _afterStateChange(prevState, _state!);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> claimQuestReward(String rewardKey) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final prevState = _state;
      _state = await _engine.claimQuestReward(rewardKey);
      _error = null;
      await _afterStateChange(prevState, _state!);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> claimAllQuestRewards() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final prevState = _state;
      _state = await _engine.claimAllQuestRewards();
      _error = null;
      await _afterStateChange(prevState, _state!);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  ProgressionDomainRangeSummary summaryForDomainRange({
    required ProgressionDomain domain,
    required DateTime start,
    required DateTime end,
  }) {
    final rangeStart = progressionDate(start);
    final rangeEnd = progressionDate(end);

    final matchingGrants = rewardGrants.where((grant) {
      if (grant.domain != domain) return false;
      final anchor = progressionDate(grant.period.start);
      return !anchor.isBefore(rangeStart) && !anchor.isAfter(rangeEnd);
    });

    final grants = matchingGrants.toList();
    final earnedXp =
        grants.fold<int>(0, (sum, grant) => sum + grant.effectiveXpGranted);

    return ProgressionDomainRangeSummary(
      earnedXp: earnedXp,
      grantCount: grants.length,
    );
  }

  Future<void> _emitProgressionNotifications(
    Set<String> prevGrantKeys,
    Set<String> prevUnlockedIds,
  ) async {
    final state = _state;
    if (state == null) return;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('selected_language_code') ?? 'cs';
    final l10n = await AppLocalizations.delegate.load(Locale(langCode));
    final progressionL10n = ProgressionL10n(l10n);

    final newGrants = state.questRewardGrants
        .where((g) => !prevGrantKeys.contains(g.rewardKey))
        .toList();
    for (var i = 0; i < newGrants.length; i++) {
      final grant = newGrants[i];
      final quest =
          state.quests.where((q) => q.id == grant.questId).firstOrNull;
      final title = quest != null ? progressionL10n.questTitle(quest) : 'Quest';
      unawaited(NotificationService.instance
          .showQuestCompleted(title, grant.xpGranted, index: i));
    }

    final newAchievements = state.achievements
        .where((a) => a.unlocked && !prevUnlockedIds.contains(a.id))
        .toList();
    for (var i = 0; i < newAchievements.length; i++) {
      final a = newAchievements[i];
      unawaited(NotificationService.instance.showAchievementUnlocked(
        progressionL10n.achievementTitle(a),
        progressionL10n.achievementDescription(a),
        index: i,
      ));
    }
  }

  Future<void> _afterStateChange(
    ProgressionEngineState? previous,
    ProgressionEngineState current,
  ) async {
    final cosmeticDispatch = await _cosmeticUnlockDispatcher.dispatch(
      previous: previous,
      current: current,
    );
    _queueCelebrations(
      previous: previous,
      current: current,
      cosmeticDispatch: cosmeticDispatch,
    );
  }

  void _queueCelebrations({
    required ProgressionEngineState? previous,
    required ProgressionEngineState current,
    required CosmeticUnlockDispatchResult cosmeticDispatch,
  }) {
    if (previous == null) return;

    final createdAt = DateTime.now();
    final events = <ProgressionCelebrationEvent>[];
    final attachedCosmeticIds = <String>{};

    for (var level = previous.profile.level + 1;
        level <= current.profile.level;
        level++) {
      final levelCosmetics = _itemsForSource(
        cosmeticDispatch,
        sourceType: CosmeticUnlockSource.progressionLevel.name,
        sourceId: 'level_$level',
      );
      final rewardCosmetics = _mergedCosmeticIds(
        _cosmeticRewardTable.cosmeticsForLevel(level),
        levelCosmetics,
      );
      final isMilestone =
          levelHasTitleBreakpoint(level) || rewardCosmetics.isNotEmpty;
      if (!isMilestone) continue;

      attachedCosmeticIds.addAll(rewardCosmetics);
      events.add(
        ProgressionCelebrationEvent(
          id: 'level|$level|${createdAt.microsecondsSinceEpoch}',
          kind: ProgressionCelebrationKind.levelMilestone,
          createdAt: createdAt,
          level: level,
          cosmeticIds: rewardCosmetics,
        ),
      );
    }

    final previousAchievementIds =
        previous.achievements.where((a) => a.unlocked).map((a) => a.id).toSet();
    final newlyUnlockedAchievements = current.achievements
        .where((a) => a.unlocked && !previousAchievementIds.contains(a.id))
        .where((a) => levelFromAchievementId(a.id) == null);

    for (final achievement in newlyUnlockedAchievements) {
      final achievementCosmetics = _itemsForSource(
        cosmeticDispatch,
        sourceType: CosmeticUnlockSource.achievement.name,
        sourceId: achievement.id,
      );
      final rewardCosmetics = _mergedCosmeticIds(
        _cosmeticRewardTable.cosmeticsForAchievement(achievement.id),
        achievementCosmetics,
      );
      attachedCosmeticIds.addAll(rewardCosmetics);
      events.add(
        ProgressionCelebrationEvent(
          id: 'achievement|${achievement.id}|${createdAt.microsecondsSinceEpoch}',
          kind: ProgressionCelebrationKind.achievementUnlocked,
          createdAt: createdAt,
          achievement: achievement,
          cosmeticIds: rewardCosmetics,
        ),
      );
    }

    for (final item in cosmeticDispatch.items) {
      if (attachedCosmeticIds.contains(item.cosmeticId)) continue;
      events.add(
        ProgressionCelebrationEvent(
          id: 'cosmetic|${item.cosmeticId}|${createdAt.microsecondsSinceEpoch}',
          kind: ProgressionCelebrationKind.cosmeticUnlocked,
          createdAt: createdAt,
          cosmeticIds: [item.cosmeticId],
        ),
      );
    }

    if (events.isEmpty) return;
    _celebrationQueue.addAll(events);
  }

  List<String> _itemsForSource(
    CosmeticUnlockDispatchResult result, {
    required String sourceType,
    required String sourceId,
  }) {
    return result.items
        .where(
          (item) => item.sourceType == sourceType && item.sourceId == sourceId,
        )
        .map((item) => item.cosmeticId)
        .toList(growable: false);
  }

  List<String> _mergedCosmeticIds(List<String> first, List<String> second) {
    final seen = <String>{};
    return [
      for (final id in [...first, ...second])
        if (seen.add(id)) id,
    ];
  }

  Future<void> _hydrate() async {
    try {
      _state = await _engine.load();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
