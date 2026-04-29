import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../devtools/application/devtools_sync_logger.dart';
import '../../devtools/domain/devtools_sync_event.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/notification_service.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../../features/health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../application/progression_engine.dart';
import '../data/provider_progression_source.dart';
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

class ProgressionProvider extends ChangeNotifier {
  ProgressionProvider({
    required ProgressionEngine engine,
  }) : _engine = engine {
    unawaited(_hydrate());
  }

  final ProgressionEngine _engine;

  ProgressionEngineState? _state;
  ProviderProgressionSource? _source;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _refreshQueued = false;
  String? _error;
  String? _lastRequestedSignature;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  DateTime? get lastEvaluatedAt => _state?.lastEvaluatedAt;

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

  void bind({
    required GoalsProvider goalsProvider,
    required FitnessProvider fitnessProvider,
    required KalorickeTabulkyProvider nutritionProvider,
  }) {
    _source = ProviderProgressionSource(
      goalsProvider: goalsProvider,
      fitnessProvider: fitnessProvider,
      nutritionProvider: nutritionProvider,
    );

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
    final hadState = _state != null;

    String? syncError;
    try {
      _state = await _engine.sync(source);
      _error = null;
      if (hadState)
        unawaited(
            _emitProgressionNotifications(prevGrantKeys, prevUnlockedIds));
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
      _state = await _engine.claimReward(rewardKey);
      _error = null;
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
      _state = await _engine.claimAllRewards();
      _error = null;
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
      _state = await _engine.claimQuestReward(rewardKey);
      _error = null;
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
      _state = await _engine.claimAllQuestRewards();
      _error = null;
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
