import '../domain/progression_achievement_catalog.dart';
import '../domain/progression_achievement_evaluator.dart';
import '../domain/progression_evaluator.dart';
import '../domain/progression_level_policy.dart';
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
    required this.achievements,
    required this.quests,
    required this.streaksByRuleId,
    required this.streaksByDomain,
    this.lastEvaluatedAt,
  });

  final ProgressionProfile profile;
  final List<ProgressionEvaluation> evaluations;
  final List<ProgressionRewardGrant> rewardGrants;
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
    final ledger = await _repository.loadLedger();
    return _toState(ledger, evaluationDate: _clock());
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
    var state = _toState(ledger, evaluationDate: now);
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
    final ledger = await _repository.claimReward(
      rewardKey: rewardKey,
      claimedAt: now,
    );
    return _toState(ledger, evaluationDate: now);
  }

  Future<ProgressionEngineState> claimAllRewards() async {
    final now = _clock();
    final ledger = await _repository.claimAllRewards(claimedAt: now);
    return _toState(ledger, evaluationDate: now);
  }

  ProgressionEngineState _toState(
    ProgressionLedgerSnapshot ledger, {
    required DateTime evaluationDate,
  }) {
    final totalXp = ledger.rewardGrants.fold<int>(
      0,
      (sum, grant) => sum + grant.effectiveXpGranted,
    );

    final evaluations = [...ledger.evaluations]
      ..sort((a, b) => b.period.start.compareTo(a.period.start));
    final rewardGrants = [...ledger.rewardGrants]
      ..sort((a, b) => b.period.start.compareTo(a.period.start));
    final profile = _levelPolicy.resolve(totalXp);
    final streaksByRuleId = _streakPolicy.summarizeByRule(evaluations);
    final streaksByDomain = _streakPolicy.summarizeByDomain(evaluations);
    final achievements = _achievementEvaluator.evaluate(
      definitions: _achievementCatalog.build(),
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
    );

    final questResult = _questEvaluator.evaluate(
      definitions: _questCatalog.build(),
      previousActiveQuestIds: ledger.activeQuestIds,
      evaluationDate: evaluationDate,
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      achievements: achievements,
      streaksByRuleId: streaksByRuleId,
      streaksByDomain: streaksByDomain,
    );

    return ProgressionEngineState(
      profile: profile,
      evaluations: evaluations,
      rewardGrants: rewardGrants,
      achievements: achievements,
      quests: questResult.quests,
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
      (sum, grant) => sum + grant.xpGranted,
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
}
