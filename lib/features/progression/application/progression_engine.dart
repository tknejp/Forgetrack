import '../domain/progression_achievement_catalog.dart';
import '../domain/progression_achievement_evaluator.dart';
import '../domain/progression_evaluator.dart';
import '../domain/progression_level_policy.dart';
import '../domain/progression_local_repository.dart';
import '../domain/progression_models.dart';
import '../domain/progression_quest_catalog.dart';
import '../domain/progression_quest_evaluator.dart';
import '../domain/progression_repository.dart';
import '../domain/progression_rule_catalog.dart';
import '../domain/progression_streak_policy.dart';
import 'progression_source.dart';

class ProgressionEngineState {
  const ProgressionEngineState({
    required this.profile,
    required this.evaluations,
    required this.rewardGrants,
    required this.questRewardGrants,
    required this.achievements,
    required this.quests,
    required this.streaksByRuleId,
    required this.streaksByDomain,
    this.lastEvaluatedAt,
  });

  final ProgressionProfile profile;
  final List<ProgressionEvaluation> evaluations;
  final List<ProgressionRewardGrant> rewardGrants;
  final List<ProgressionQuestRewardGrant> questRewardGrants;
  final List<ProgressionAchievement> achievements;
  final List<ProgressionQuest> quests;
  final Map<String, ProgressionStreakSummary> streaksByRuleId;
  final Map<ProgressionDomain, ProgressionStreakSummary> streaksByDomain;
  final DateTime? lastEvaluatedAt;
}

class ProgressionEngine {
  ProgressionEngine({
    required ProgressionRepository repository,
    ProgressionAchievementCatalog achievementCatalog =
        const ProgressionAchievementCatalog(),
    ProgressionAchievementEvaluator achievementEvaluator =
        const ProgressionAchievementEvaluator(),
    ProgressionQuestCatalog questCatalog = const ProgressionQuestCatalog(),
    ProgressionQuestEvaluator questEvaluator =
        const ProgressionQuestEvaluator(),
    ProgressionEvaluator evaluator = const ProgressionEvaluator(),
    ProgressionRuleCatalog ruleCatalog = const ProgressionRuleCatalog(),
    ProgressionLevelPolicy levelPolicy = const ProgressionLevelPolicy(),
    ProgressionStreakPolicy streakPolicy = const ProgressionStreakPolicy(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _achievementCatalog = achievementCatalog,
        _achievementEvaluator = achievementEvaluator,
        _questCatalog = questCatalog,
        _questEvaluator = questEvaluator,
        _evaluator = evaluator,
        _ruleCatalog = ruleCatalog,
        _levelPolicy = levelPolicy,
        _streakPolicy = streakPolicy,
        _clock = clock ?? DateTime.now;

  final ProgressionRepository _repository;
  final ProgressionAchievementCatalog _achievementCatalog;
  final ProgressionAchievementEvaluator _achievementEvaluator;
  final ProgressionQuestCatalog _questCatalog;
  final ProgressionQuestEvaluator _questEvaluator;
  final ProgressionEvaluator _evaluator;
  final ProgressionRuleCatalog _ruleCatalog;
  final ProgressionLevelPolicy _levelPolicy;
  final ProgressionStreakPolicy _streakPolicy;
  final DateTime Function() _clock;

  Future<ProgressionEngineState> load() async {
    final now = _clock();
    final ledger = await _repository.loadLedger();
    return _stateWithPersistedAchievementUnlocks(
      ledger,
      evaluationDate: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Devtools — never call from production code paths.
  // ---------------------------------------------------------------------------

  /// Wipes the entire progression ledger (evaluations, grants, quest grants,
  /// active quests, achievement unlocks) and returns the empty post-wipe
  /// state. Profile becomes level 1 / 0 XP.
  Future<ProgressionEngineState> devToolsResetLedger() async {
    final local = _requireLocalRepository();
    await local.wipeAllProgressionData();
    return load();
  }

  /// Wipes the ledger and inserts a single synthetic claimed rule grant whose
  /// final XP equals [xp]. Resulting profile total XP is exactly [xp]; level
  /// is derived through the regular [ProgressionLevelPolicy].
  ///
  /// Note: any subsequent `sync()` will additively re-evaluate live source
  /// data and may grant further XP on top — for an exact level/XP test, do
  /// not trigger a refresh after this call.
  Future<ProgressionEngineState> devToolsSetTotalXp(int xp) async {
    final clamped = xp < 0 ? 0 : xp;
    final local = _requireLocalRepository();
    await local.wipeAllProgressionData();

    if (clamped > 0) {
      final now = _clock();
      final period = ProgressionPeriod(
        kind: ProgressionPeriodKind.day,
        start: now,
        end: now,
      );
      await local.insertRestoredRuleGrant(
        ProgressionRewardGrant(
          rewardKey: 'devtools_xp_override',
          ruleId: 'devtools_synthetic',
          ruleVersion: 'v1',
          domain: ProgressionDomain.steps,
          period: period,
          xpGranted: clamped,
          baseXp: clamped,
          targetValue: 0,
          actualValue: 0,
          toleranceRatio: 0,
          rewardStatus: ProgressionRewardStatus.claimed,
          unlockedAt: now,
          claimedAt: now,
          finalXp: clamped,
          levelAtClaim: 1,
          multiplierAtClaim: 1.0,
        ),
      );
    }

    return load();
  }

  ProgressionLocalRepository _requireLocalRepository() {
    final repo = _repository;
    if (repo is! ProgressionLocalRepository) {
      throw StateError(
        'Devtools methods require a ProgressionLocalRepository '
        '(got ${repo.runtimeType}).',
      );
    }
    return repo;
  }

  Future<ProgressionEngineState> sync(ProgressionSource source) async {
    final now = _clock();
    final existingLedger = await _repository.loadLedger();
    final evaluations = _evaluateAll(
      source,
      existingLedger: existingLedger,
    );

    var ledger = await _repository.persistEvaluations(
      evaluations: evaluations,
      evaluatedAt: now,
    );
    var state = await _stateWithPersistedAchievementUnlocks(
      ledger,
      evaluationDate: now,
    );
    ledger = await _repository.loadLedger();

    final newQuestRewardGrants = _newQuestRewardGrants(
      state.quests,
      existingGrants: ledger.questRewardGrants,
      unlockedAt: now,
    );

    if (newQuestRewardGrants.isNotEmpty) {
      ledger = await _repository.persistQuestRewardGrants(
        grants: newQuestRewardGrants,
      );
      state = _toState(ledger, evaluationDate: now);
    }

    final nextActiveQuestIds = state.quests
        .where((quest) => quest.status == ProgressionQuestStatus.active)
        .map((quest) => quest.id)
        .toSet();

    if (!_sameQuestSet(nextActiveQuestIds, ledger.activeQuestIds)) {
      ledger = await _repository.persistActiveQuestSet(
        activeQuestIds: nextActiveQuestIds,
      );
      state = _toState(ledger, evaluationDate: now);
    }

    return state;
  }

  Future<ProgressionEngineState> claimReward(String rewardKey) async {
    final now = _clock();
    var ledger = await _repository.loadLedger();
    final grant =
        ledger.rewardGrants.where((g) => g.rewardKey == rewardKey).firstOrNull;
    if (grant == null || grant.isClaimed) {
      return _toState(ledger, evaluationDate: now);
    }
    final claimedXp = _totalClaimedXp(ledger);
    final level = _levelPolicy.levelForXp(claimedXp);
    final baseXpValue = grant.baseXp ?? grant.xpGranted;
    ledger = await _repository.claimReward(
      rewardKey: rewardKey,
      claimedAt: now,
      finalXp: _levelPolicy.scaledRewardXp(baseXp: baseXpValue, level: level),
      levelAtClaim: level,
      multiplierAtClaim: _levelPolicy.rewardMultiplierForLevel(level),
    );
    return _stateWithPersistedAchievementUnlocks(
      ledger,
      evaluationDate: now,
    );
  }

  Future<ProgressionEngineState> claimAllRewards() async {
    final now = _clock();
    var ledger = await _repository.loadLedger();
    var runningClaimedXp = _totalClaimedXp(ledger);

    final unclaimedGrants = ledger.rewardGrants
        .where((g) => g.isUnlocked)
        .toList()
      ..sort((a, b) => a.period.start.compareTo(b.period.start));

    for (final grant in unclaimedGrants) {
      final level = _levelPolicy.levelForXp(runningClaimedXp);
      final baseXpValue = grant.baseXp ?? grant.xpGranted;
      final finalXp =
          _levelPolicy.scaledRewardXp(baseXp: baseXpValue, level: level);
      ledger = await _repository.claimReward(
        rewardKey: grant.rewardKey,
        claimedAt: now,
        finalXp: finalXp,
        levelAtClaim: level,
        multiplierAtClaim: _levelPolicy.rewardMultiplierForLevel(level),
      );
      runningClaimedXp += finalXp;
    }

    return _stateWithPersistedAchievementUnlocks(
      ledger,
      evaluationDate: now,
    );
  }

  Future<ProgressionEngineState> claimQuestReward(String rewardKey) async {
    final now = _clock();
    var ledger = await _repository.loadLedger();
    final grant = ledger.questRewardGrants
        .where((g) => g.rewardKey == rewardKey)
        .firstOrNull;
    if (grant == null || grant.isClaimed) {
      return _toState(ledger, evaluationDate: now);
    }
    final claimedXp = _totalClaimedXp(ledger);
    final level = _levelPolicy.levelForXp(claimedXp);
    final baseXpValue = grant.baseXp ?? grant.xpGranted;
    ledger = await _repository.claimQuestReward(
      rewardKey: rewardKey,
      claimedAt: now,
      finalXp: _levelPolicy.scaledRewardXp(baseXp: baseXpValue, level: level),
      levelAtClaim: level,
      multiplierAtClaim: _levelPolicy.rewardMultiplierForLevel(level),
    );
    return _stateWithPersistedAchievementUnlocks(
      ledger,
      evaluationDate: now,
    );
  }

  Future<ProgressionEngineState> claimAllQuestRewards() async {
    final now = _clock();
    var ledger = await _repository.loadLedger();
    var runningClaimedXp = _totalClaimedXp(ledger);

    final unclaimedGrants = ledger.questRewardGrants
        .where((g) => g.isUnlocked)
        .toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    for (final grant in unclaimedGrants) {
      final level = _levelPolicy.levelForXp(runningClaimedXp);
      final baseXpValue = grant.baseXp ?? grant.xpGranted;
      final finalXp =
          _levelPolicy.scaledRewardXp(baseXp: baseXpValue, level: level);
      ledger = await _repository.claimQuestReward(
        rewardKey: grant.rewardKey,
        claimedAt: now,
        finalXp: finalXp,
        levelAtClaim: level,
        multiplierAtClaim: _levelPolicy.rewardMultiplierForLevel(level),
      );
      runningClaimedXp += finalXp;
    }

    return _stateWithPersistedAchievementUnlocks(
      ledger,
      evaluationDate: now,
    );
  }

  Future<ProgressionEngineState> _stateWithPersistedAchievementUnlocks(
    ProgressionLedgerSnapshot ledger, {
    required DateTime evaluationDate,
  }) async {
    var state = _toState(ledger, evaluationDate: evaluationDate);
    final newUnlocks = _newAchievementUnlocks(
      state.achievements,
      existingUnlocks: ledger.achievementUnlocks,
    );
    if (newUnlocks.isEmpty) return state;

    final updatedLedger =
        await _repository.persistAchievementUnlocks(unlocks: newUnlocks);
    return _toState(updatedLedger, evaluationDate: evaluationDate);
  }

  int _totalClaimedXp(ProgressionLedgerSnapshot ledger) {
    return ledger.rewardGrants.fold<int>(
          0,
          (sum, g) => sum + g.effectiveXpGranted,
        ) +
        ledger.questRewardGrants.fold<int>(
          0,
          (sum, g) => sum + g.effectiveXpGranted,
        );
  }

  ProgressionEngineState _toState(
    ProgressionLedgerSnapshot ledger, {
    required DateTime evaluationDate,
  }) {
    final totalXp = ledger.rewardGrants.fold<int>(
          0,
          (sum, grant) => sum + grant.effectiveXpGranted,
        ) +
        ledger.questRewardGrants.fold<int>(
          0,
          (sum, grant) => sum + grant.effectiveXpGranted,
        );

    final evaluations = [...ledger.evaluations]
      ..sort((a, b) => b.period.start.compareTo(a.period.start));
    final rewardGrants = [...ledger.rewardGrants]
      ..sort((a, b) => b.period.start.compareTo(a.period.start));
    final questRewardGrants = [...ledger.questRewardGrants]
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final profile = _levelPolicy.resolve(totalXp);
    final streaksByRuleId = _streakPolicy.summarizeByRule(evaluations);
    final streaksByDomain = _streakPolicy.summarizeByDomain(evaluations);
    final questDefinitions = _questCatalog.build();
    final existingUnlocks = {
      for (final u in ledger.achievementUnlocks) u.achievementId: u.unlockedAt,
    };
    final achievements = _achievementEvaluator.evaluate(
      definitions: _achievementCatalog.build(),
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
      existingUnlocks: existingUnlocks,
    );

    final questResult = _questEvaluator.evaluate(
      definitions: questDefinitions,
      previousActiveQuestIds: ledger.activeQuestIds,
      evaluationDate: evaluationDate,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      achievements: achievements,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
    );
    final quests = _decorateQuestRewards(
      quests: questResult.quests,
      definitions: questDefinitions,
      grants: questRewardGrants,
      profile: profile,
    );

    return ProgressionEngineState(
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      questRewardGrants: questRewardGrants,
      achievements: achievements,
      quests: quests,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
      lastEvaluatedAt: ledger.lastEvaluatedAt,
    );
  }

  List<ProgressionEvaluation> _evaluateAll(
    ProgressionSource source, {
    required ProgressionLedgerSnapshot existingLedger,
  }) {
    final snapshots = [
      ...source.buildDailySnapshots(),
      ...source.buildWeeklySnapshots(),
    ]..sort((a, b) {
        final byEnd = a.period.end.compareTo(b.period.end);
        if (byEnd != 0) return byEnd;
        final byKind = a.period.kind.index.compareTo(b.period.kind.index);
        if (byKind != 0) return byKind;
        return a.period.start.compareTo(b.period.start);
      });

    final evaluations = _evaluateSnapshots(
      source: source,
      snapshots: snapshots,
      existingLedger: existingLedger,
    ).toList(growable: false);

    evaluations.sort((a, b) => a.evaluationKey.compareTo(b.evaluationKey));
    return evaluations;
  }

  Iterable<ProgressionEvaluation> _evaluateSnapshots({
    required ProgressionSource source,
    required List<ProgressionSnapshot> snapshots,
    required ProgressionLedgerSnapshot existingLedger,
  }) sync* {
    final existingRewardByKey = {
      for (final grant in existingLedger.rewardGrants) grant.rewardKey: grant,
    };
    var runningXp = existingLedger.rewardGrants.fold<int>(
          0,
          (sum, grant) => sum + grant.effectiveXpGranted,
        ) +
        existingLedger.questRewardGrants.fold<int>(
          0,
          (sum, grant) => sum + grant.effectiveXpGranted,
        );

    for (final snapshot in snapshots) {
      final rules = _sortedRulesForPeriod(
        _ruleCatalog.build(source.goalsForPeriod(snapshot.period)),
      ).where((rule) => rule.periodKind == snapshot.period.kind);
      final levelAtSnapshot = _levelPolicy.levelForXp(runningXp);
      var earnedThisSnapshot = 0;
      for (final rule in rules) {
        final rewardKey = rule.rewardKeyFor(snapshot.period);
        final existingReward = existingRewardByKey[rewardKey];
        final rewardXp = existingReward?.xpGranted ??
            _levelPolicy.scaledRewardXp(
              baseXp: rule.rewardXp,
              level: levelAtSnapshot,
            );
        final evaluation = _evaluator.evaluate(
          rule: rule,
          snapshot: snapshot,
          rewardXp: rewardXp,
        );
        if (evaluation.achieved && existingReward == null) {
          earnedThisSnapshot += rewardXp;
        }
        yield evaluation;
      }
      runningXp += earnedThisSnapshot;
    }
  }

  List<ProgressionRuleDefinition> _sortedRulesForPeriod(
    List<ProgressionRuleDefinition> rules,
  ) {
    final sortedRules = [...rules]..sort((a, b) {
        final byPeriod = a.periodKind.index.compareTo(b.periodKind.index);
        if (byPeriod != 0) return byPeriod;
        final byId = a.id.compareTo(b.id);
        if (byId != 0) return byId;
        return a.version.compareTo(b.version);
      });
    return sortedRules;
  }

  bool _sameQuestSet(Set<String> left, Set<String> right) {
    if (left.length != right.length) return false;
    for (final item in left) {
      if (!right.contains(item)) return false;
    }
    return true;
  }

  List<ProgressionAchievementUnlockEvent> _newAchievementUnlocks(
    List<ProgressionAchievement> achievements, {
    required List<ProgressionAchievementUnlockEvent> existingUnlocks,
  }) {
    final existingIds = {
      for (final u in existingUnlocks) u.achievementId,
    };
    return [
      for (final achievement in achievements)
        if (achievement.unlocked && !existingIds.contains(achievement.id))
          ProgressionAchievementUnlockEvent(
            unlockKey: 'achievement|${achievement.id}',
            achievementId: achievement.id,
            // Prefer the evaluator's estimated timestamp; fall back to now.
            unlockedAt: achievement.unlockedAt ?? _clock(),
          ),
    ];
  }

  List<ProgressionQuestRewardGrant> _newQuestRewardGrants(
    List<ProgressionQuest> quests, {
    required List<ProgressionQuestRewardGrant> existingGrants,
    required DateTime unlockedAt,
  }) {
    final existingKeys = {
      for (final grant in existingGrants) grant.rewardKey,
    };

    return [
      for (final quest in quests)
        if (quest.isCompleted &&
            quest.rewardKey != null &&
            quest.rewardXp > 0 &&
            !existingKeys.contains(quest.rewardKey))
          ProgressionQuestRewardGrant(
            rewardKey: quest.rewardKey!,
            questId: quest.id,
            xpGranted: quest.rewardXp,
            rewardStatus: ProgressionRewardStatus.unlocked,
            unlockedAt: unlockedAt,
            completedAt: quest.completedAt!,
          ),
    ];
  }

  List<ProgressionQuest> _decorateQuestRewards({
    required List<ProgressionQuest> quests,
    required List<ProgressionQuestDefinition> definitions,
    required List<ProgressionQuestRewardGrant> grants,
    required ProgressionProfile profile,
  }) {
    final definitionsById = {
      for (final definition in definitions) definition.id: definition,
    };
    final grantsByRewardKey = {
      for (final grant in grants) grant.rewardKey: grant,
    };

    return [
      for (final quest in quests)
        _withQuestRewardState(
          quest,
          definition: definitionsById[quest.id],
          grantsByRewardKey: grantsByRewardKey,
          profile: profile,
        ),
    ];
  }

  ProgressionQuest _withQuestRewardState(
    ProgressionQuest quest, {
    required ProgressionQuestDefinition? definition,
    required Map<String, ProgressionQuestRewardGrant> grantsByRewardKey,
    required ProgressionProfile profile,
  }) {
    if (definition == null) return quest;

    final rewardKey = quest.completedAt == null
        ? null
        : definition.rewardKeyFor(quest.completedAt!);
    final rewardGrant = rewardKey == null ? null : grantsByRewardKey[rewardKey];
    final displayXp = rewardGrant?.isClaimed == true
        ? rewardGrant!.effectiveXpGranted
        : _levelPolicy.scaledRewardXp(
            baseXp: definition.rewardXp,
            level: profile.level,
          );

    return ProgressionQuest(
      id: quest.id,
      title: quest.title,
      description: quest.description,
      type: quest.type,
      category: quest.category,
      criterionType: quest.criterionType,
      status: quest.status,
      targetValue: quest.targetValue,
      currentValue: quest.currentValue,
      progress: quest.progress,
      prerequisiteQuestIds: quest.prerequisiteQuestIds,
      sortOrder: quest.sortOrder,
      priority: quest.priority,
      isHighlighted: quest.isHighlighted,
      rewardXp: displayXp,
      rewardKey: rewardKey,
      rewardStatus: rewardGrant?.rewardStatus,
      rewardUnlockedAt: rewardGrant?.unlockedAt,
      rewardClaimedAt: rewardGrant?.claimedAt,
      completedAt: quest.completedAt,
      ruleId: quest.ruleId,
      domain: quest.domain,
      periodKind: quest.periodKind,
      achievementId: quest.achievementId,
      relatedRuleIds: quest.relatedRuleIds,
      minimumLevel: quest.minimumLevel,
      minimumTrackedDays: quest.minimumTrackedDays,
    );
  }
}
