import 'package:flutter/material.dart' show Icons;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/domain/rarity.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import 'quest_assets.dart';

/// Chapter quests 2-10, ported from the V1 monolith
/// `progression/domain/catalog/quest_catalog.dart` (the "journey
/// chapter" specs). Forest Trial lives in its own file as the pilot;
/// this aggregator covers Ruins of Discipline → Dragonrock Sovereign
/// using a single shared shape so the catalog stays scannable.
///
/// Each chapter has five nodes: an auto-claim **open** gated by
/// player level, three manual-claim **step** nodes chained by
/// [Quest.prerequisiteNodeIds] / [Quest.nextNodeIds], and a
/// manual-claim **finale** that drops the chapter's emblem cosmetic.
///
/// Step objectives use [Objective.baselineFromNodeId] so
/// progress counts only what the player does *after* the previous
/// step completed — keeps a high-level player from auto-finishing a
/// late chapter on day one just because their lifetime ledger is
/// already past the threshold. The override path supports
/// [NodeCompletionsMetric] and [RewardCountMetric] today; the few
/// [StepsMetric]-based steps (mine_descent_steps_250k,
/// icewalker_route_steps_500k) fall back to lifetime semantics — the
/// chain prereq still enforces sequential ordering.
///
/// Step criterion mapping from V1:
/// - `ruleCompletionsAtLeast(daily_X, day)` → `NodeCompletionsMetric('daily_X_today')`
/// - `ruleCompletionsAtLeast(weekly_activity, week)` → `NodeCompletionsMetric('weekly_activity')`
/// - `totalRuleValueAtLeast(daily_steps)` → `StepsMetric` lifetime (no baseline)
/// - `ruleSetCompletionsAtLeast(reqCount, related[])` →
///   `DaysWithAtLeastKAmongMetric(related, atLeast: reqCount)`. Counts
///   distinct days on which at least `reqCount` of the listed daily
///   atoms were done (goal met or claimed) since the chain step's
///   baseline. Preserves V1's "K of M rules per day" semantics —
///   "splň všechny 4 denní cíle 5krát" means 5 days with ≥4 daily
///   goals met, not 5 step-quest completions.
/// - `rewardCountAtLeast` → `RewardCountMetric()` since baseline
/// - `domainRewardCountAtLeast(domain)` → `RewardCountMetric(domain: …)` since baseline

/// The full set of daily-quest node ids that the "four pillars"
/// chapter steps gate against. Steps that ask for "all 4 daily
/// goals" check for at least 4 of these on the same day — matches
/// the `daily_challenge_balanced` pool semantic the player already
/// sees in the daily-challenge tier.
const _allDailyAtoms = <String>[
  'daily_steps_today',
  'daily_calories_today',
  'daily_protein_today',
  'daily_carbs_today',
  'daily_fat_today',
  'daily_fiber_today',
  'daily_sleep_today',
  'daily_activity_today',
];

/// Calories + protein paired-day check used by mid-chapter nutrition
/// steps ("splň cíl kalorií i bílkovin").
const _calorieAndProtein = <String>[
  'daily_calories_today',
  'daily_protein_today',
];

/// Steps + sleep paired-day check used by recovery-themed steps
/// ("splň cíl kroků i spánku ve stejný den").
const _stepsAndSleep = <String>[
  'daily_steps_today',
  'daily_sleep_today',
];

class _ChapterSpec {
  const _ChapterSpec({
    required this.id,
    required this.level,
    required this.sortOrder,
    required this.iconAsset,
    required this.openTitleKey,
    required this.openDescKey,
    required this.finaleTitleKey,
    required this.finaleDescKey,
    required this.finaleEmblemId,
    required this.rewards,
    required this.steps,
  });

  final String id;
  final int level;
  final int sortOrder;
  final String iconAsset;
  final String Function(AppLocalizations) openTitleKey;
  final String Function(AppLocalizations) openDescKey;
  final String Function(AppLocalizations) finaleTitleKey;
  final String Function(AppLocalizations) finaleDescKey;

  /// Cosmetic id awarded by the finale step.
  final String finaleEmblemId;

  /// XP rewards in chain order: [open, step1, step2, step3, finale].
  final List<int> rewards;

  final List<_StepSpec> steps;
}

class _StepSpec {
  const _StepSpec({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.metric,
    required this.targetValue,
    required this.chainStepLabel,
    this.domain,
  });

  final String id;
  final String Function(AppLocalizations) titleKey;
  final String Function(AppLocalizations) descriptionKey;
  final ObjectiveMetric metric;
  final double targetValue;
  final String chainStepLabel;
  final ProgressionDomain? domain;
}

List<_ChapterSpec> _chapters() {
  return [
    _ChapterSpec(
      id: 'ruins_discipline',
      level: 20,
      sortOrder: 320,
      iconAsset: questAssetRuinsDisciplineIcon,
      openTitleKey: (l) => l.progQuestRuinsDisciplineOpenTitle,
      openDescKey: (l) => l.progQuestRuinsDisciplineOpenDesc,
      finaleTitleKey: (l) => l.progQuestRuinsDisciplineFinaleTitle,
      finaleDescKey: (l) => l.progQuestRuinsDisciplineFinaleDesc,
      finaleEmblemId: 'emblem_ruin_sigil',
      rewards: const [180, 260, 280, 320, 450],
      steps: [
        _StepSpec(
          id: 'ruins_discipline_nutrition_7',
          titleKey: (l) => l.progQuestRuinsDisciplineNutrition7Title,
          descriptionKey: (l) => l.progQuestRuinsDisciplineNutrition7Desc,
          // "splň cíl kalorií i bílkovin 7krát" — needs both nodes
          // on the same day, 7 days total. Old single-node calories
          // check let any 7 calorie days satisfy the step regardless
          // of protein.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _calorieAndProtein,
            atLeast: 2,
          ),
          targetValue: 7,
          chainStepLabel: '7',
          domain: ProgressionDomain.nutrition,
        ),
        _StepSpec(
          id: 'ruins_discipline_weekly_2',
          titleKey: (l) => l.progQuestRuinsDisciplineWeekly2Title,
          descriptionKey: (l) => l.progQuestRuinsDisciplineWeekly2Desc,
          metric: const NodeCompletionsMetric(nodeId: 'weekly_activity'),
          targetValue: 2,
          chainStepLabel: '2',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'ruins_discipline_steps_10',
          titleKey: (l) => l.progQuestRuinsDisciplineSteps10Title,
          descriptionKey: (l) => l.progQuestRuinsDisciplineSteps10Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_steps_today'),
          targetValue: 10,
          chainStepLabel: '10',
          domain: ProgressionDomain.steps,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'mine_descent',
      level: 30,
      sortOrder: 340,
      iconAsset: questAssetMineDescentIcon,
      openTitleKey: (l) => l.progQuestMineDescentOpenTitle,
      openDescKey: (l) => l.progQuestMineDescentOpenDesc,
      finaleTitleKey: (l) => l.progQuestMineDescentFinaleTitle,
      finaleDescKey: (l) => l.progQuestMineDescentFinaleDesc,
      finaleEmblemId: 'emblem_gatekeeper_mark',
      rewards: const [240, 380, 420, 420, 600],
      steps: [
        _StepSpec(
          id: 'mine_descent_steps_250k',
          titleKey: (l) => l.progQuestMineDescentSteps250kTitle,
          descriptionKey: (l) => l.progQuestMineDescentSteps250kDesc,
          // StepsMetric lifetime — no baseline override today; chain
          // prereq still enforces ordering. Players past 250k at
          // unlock will see this satisfied immediately.
          metric: const StepsMetric(),
          targetValue: 250000,
          chainStepLabel: '250K',
          domain: ProgressionDomain.steps,
        ),
        _StepSpec(
          id: 'mine_descent_activity_rewards_12',
          titleKey: (l) => l.progQuestMineDescentActivityRewards12Title,
          descriptionKey: (l) =>
              l.progQuestMineDescentActivityRewards12Desc,
          metric: const RewardCountMetric(domain: 'activity'),
          targetValue: 12,
          chainStepLabel: '12',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'mine_descent_protein_10',
          titleKey: (l) => l.progQuestMineDescentProtein10Title,
          descriptionKey: (l) => l.progQuestMineDescentProtein10Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_protein_today'),
          targetValue: 10,
          chainStepLabel: '10',
          domain: ProgressionDomain.nutrition,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'forge_momentum',
      level: 40,
      sortOrder: 360,
      iconAsset: questAssetForgeMomentumIcon,
      openTitleKey: (l) => l.progQuestForgeMomentumOpenTitle,
      openDescKey: (l) => l.progQuestForgeMomentumOpenDesc,
      finaleTitleKey: (l) => l.progQuestForgeMomentumFinaleTitle,
      finaleDescKey: (l) => l.progQuestForgeMomentumFinaleDesc,
      finaleEmblemId: 'emblem_mine_crest',
      rewards: const [300, 480, 520, 560, 750],
      steps: [
        _StepSpec(
          id: 'forge_momentum_weekly_4',
          titleKey: (l) => l.progQuestForgeMomentumWeekly4Title,
          descriptionKey: (l) => l.progQuestForgeMomentumWeekly4Desc,
          metric: const NodeCompletionsMetric(nodeId: 'weekly_activity'),
          targetValue: 4,
          chainStepLabel: '4',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'forge_momentum_steps_20',
          titleKey: (l) => l.progQuestForgeMomentumSteps20Title,
          descriptionKey: (l) => l.progQuestForgeMomentumSteps20Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_steps_today'),
          targetValue: 20,
          chainStepLabel: '20',
          domain: ProgressionDomain.steps,
        ),
        _StepSpec(
          id: 'forge_momentum_nutrition_15',
          titleKey: (l) => l.progQuestForgeMomentumNutrition15Title,
          descriptionKey: (l) => l.progQuestForgeMomentumNutrition15Desc,
          // "splň cíl kalorií i bílkovin 15krát" — paired-day check.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _calorieAndProtein,
            atLeast: 2,
          ),
          targetValue: 15,
          chainStepLabel: '15',
          domain: ProgressionDomain.nutrition,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'underway_pact',
      level: 50,
      sortOrder: 380,
      iconAsset: questAssetUnderwayPactIcon,
      openTitleKey: (l) => l.progQuestUnderwayPactOpenTitle,
      openDescKey: (l) => l.progQuestUnderwayPactOpenDesc,
      finaleTitleKey: (l) => l.progQuestUnderwayPactFinaleTitle,
      finaleDescKey: (l) => l.progQuestUnderwayPactFinaleDesc,
      finaleEmblemId: 'emblem_underways_mark',
      rewards: const [360, 600, 620, 680, 900],
      steps: [
        _StepSpec(
          id: 'underway_pact_four_pillars_5',
          titleKey: (l) => l.progQuestUnderwayPactFourPillars5Title,
          descriptionKey: (l) => l.progQuestUnderwayPactFourPillars5Desc,
          // "splň všechny 4 denní cíle 5krát" — 5 days with ≥4 of
          // the 8 daily atoms done. Restored from the V1 four-pillars
          // intent; the previous single-node proxy gave the player
          // a free pass on every other daily goal.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _allDailyAtoms,
            atLeast: 4,
          ),
          targetValue: 5,
          chainStepLabel: '5',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'underway_pact_sleep_14',
          titleKey: (l) => l.progQuestUnderwayPactSleep14Title,
          descriptionKey: (l) => l.progQuestUnderwayPactSleep14Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_sleep_today'),
          targetValue: 14,
          chainStepLabel: '14',
          domain: ProgressionDomain.sleep,
        ),
        _StepSpec(
          id: 'underway_pact_recovery_10',
          titleKey: (l) => l.progQuestUnderwayPactRecovery10Title,
          descriptionKey: (l) => l.progQuestUnderwayPactRecovery10Desc,
          // "splň cíl kroků i spánku ve stejný den 10krát" —
          // paired-day check on steps + sleep.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _stepsAndSleep,
            atLeast: 2,
          ),
          targetValue: 10,
          chainStepLabel: '10',
          domain: ProgressionDomain.sleep,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'frostbound_oath',
      level: 60,
      sortOrder: 400,
      iconAsset: questAssetFrostboundOathIcon,
      openTitleKey: (l) => l.progQuestFrostboundOathOpenTitle,
      openDescKey: (l) => l.progQuestFrostboundOathOpenDesc,
      finaleTitleKey: (l) => l.progQuestFrostboundOathFinaleTitle,
      finaleDescKey: (l) => l.progQuestFrostboundOathFinaleDesc,
      finaleEmblemId: 'emblem_frost_sigil',
      rewards: const [420, 720, 760, 800, 1100],
      steps: [
        _StepSpec(
          id: 'frostbound_oath_steps_21',
          titleKey: (l) => l.progQuestFrostboundOathSteps21Title,
          descriptionKey: (l) => l.progQuestFrostboundOathSteps21Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_steps_today'),
          targetValue: 21,
          chainStepLabel: '21',
          domain: ProgressionDomain.steps,
        ),
        _StepSpec(
          id: 'frostbound_oath_sleep_21',
          titleKey: (l) => l.progQuestFrostboundOathSleep21Title,
          descriptionKey: (l) => l.progQuestFrostboundOathSleep21Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_sleep_today'),
          targetValue: 21,
          chainStepLabel: '21',
          domain: ProgressionDomain.sleep,
        ),
        _StepSpec(
          id: 'frostbound_oath_weekly_6',
          titleKey: (l) => l.progQuestFrostboundOathWeekly6Title,
          descriptionKey: (l) => l.progQuestFrostboundOathWeekly6Desc,
          metric: const NodeCompletionsMetric(nodeId: 'weekly_activity'),
          targetValue: 6,
          chainStepLabel: '6',
          domain: ProgressionDomain.activity,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'icewalker_route',
      level: 70,
      sortOrder: 420,
      iconAsset: questAssetIcewalkerRouteIcon,
      openTitleKey: (l) => l.progQuestIcewalkerRouteOpenTitle,
      openDescKey: (l) => l.progQuestIcewalkerRouteOpenDesc,
      finaleTitleKey: (l) => l.progQuestIcewalkerRouteFinaleTitle,
      finaleDescKey: (l) => l.progQuestIcewalkerRouteFinaleDesc,
      finaleEmblemId: 'emblem_icewalker_mark',
      rewards: const [500, 850, 900, 950, 1300],
      steps: [
        _StepSpec(
          id: 'icewalker_route_steps_500k',
          titleKey: (l) => l.progQuestIcewalkerRouteSteps500kTitle,
          descriptionKey: (l) => l.progQuestIcewalkerRouteSteps500kDesc,
          metric: const StepsMetric(),
          targetValue: 500000,
          chainStepLabel: '500K',
          domain: ProgressionDomain.steps,
        ),
        _StepSpec(
          id: 'icewalker_route_rewards_150',
          titleKey: (l) => l.progQuestIcewalkerRouteRewards150Title,
          descriptionKey: (l) => l.progQuestIcewalkerRouteRewards150Desc,
          metric: const RewardCountMetric(),
          targetValue: 150,
          chainStepLabel: '150',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'icewalker_route_protein_30',
          titleKey: (l) => l.progQuestIcewalkerRouteProtein30Title,
          descriptionKey: (l) => l.progQuestIcewalkerRouteProtein30Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_protein_today'),
          targetValue: 30,
          chainStepLabel: '30',
          domain: ProgressionDomain.nutrition,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'mountain_ascent',
      level: 80,
      sortOrder: 440,
      iconAsset: questAssetMountainAscentIcon,
      openTitleKey: (l) => l.progQuestMountainAscentOpenTitle,
      openDescKey: (l) => l.progQuestMountainAscentOpenDesc,
      finaleTitleKey: (l) => l.progQuestMountainAscentFinaleTitle,
      finaleDescKey: (l) => l.progQuestMountainAscentFinaleDesc,
      finaleEmblemId: 'emblem_mountain_crest',
      rewards: const [600, 1000, 1100, 1150, 1600],
      steps: [
        _StepSpec(
          id: 'mountain_ascent_four_pillars_15',
          titleKey: (l) => l.progQuestMountainAscentFourPillars15Title,
          descriptionKey: (l) => l.progQuestMountainAscentFourPillars15Desc,
          // "splň všechny 4 denní cíle 15krát" — four-pillars check.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _allDailyAtoms,
            atLeast: 4,
          ),
          targetValue: 15,
          chainStepLabel: '15',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'mountain_ascent_steps_30',
          titleKey: (l) => l.progQuestMountainAscentSteps30Title,
          descriptionKey: (l) => l.progQuestMountainAscentSteps30Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_steps_today'),
          targetValue: 30,
          chainStepLabel: '30',
          domain: ProgressionDomain.steps,
        ),
        _StepSpec(
          id: 'mountain_ascent_weekly_10',
          titleKey: (l) => l.progQuestMountainAscentWeekly10Title,
          descriptionKey: (l) => l.progQuestMountainAscentWeekly10Desc,
          metric: const NodeCompletionsMetric(nodeId: 'weekly_activity'),
          targetValue: 10,
          chainStepLabel: '10',
          domain: ProgressionDomain.activity,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'dragonroad',
      level: 90,
      sortOrder: 460,
      iconAsset: questAssetDragonroadIcon,
      openTitleKey: (l) => l.progQuestDragonroadOpenTitle,
      openDescKey: (l) => l.progQuestDragonroadOpenDesc,
      finaleTitleKey: (l) => l.progQuestDragonroadFinaleTitle,
      finaleDescKey: (l) => l.progQuestDragonroadFinaleDesc,
      finaleEmblemId: 'emblem_dragon_mark',
      rewards: const [750, 1250, 1350, 1400, 2000],
      steps: [
        _StepSpec(
          id: 'dragonroad_rewards_250',
          titleKey: (l) => l.progQuestDragonroadRewards250Title,
          descriptionKey: (l) => l.progQuestDragonroadRewards250Desc,
          metric: const RewardCountMetric(),
          targetValue: 250,
          chainStepLabel: '250',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'dragonroad_four_pillars_25',
          titleKey: (l) => l.progQuestDragonroadFourPillars25Title,
          descriptionKey: (l) => l.progQuestDragonroadFourPillars25Desc,
          // "splň všechny 4 denní cíle 25krát" — four-pillars check.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _allDailyAtoms,
            atLeast: 4,
          ),
          targetValue: 25,
          chainStepLabel: '25',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'dragonroad_weekly_12',
          titleKey: (l) => l.progQuestDragonroadWeekly12Title,
          descriptionKey: (l) => l.progQuestDragonroadWeekly12Desc,
          metric: const NodeCompletionsMetric(nodeId: 'weekly_activity'),
          targetValue: 12,
          chainStepLabel: '12',
          domain: ProgressionDomain.activity,
        ),
      ],
    ),
    _ChapterSpec(
      id: 'dragonrock_sovereign',
      level: 100,
      sortOrder: 480,
      iconAsset: questAssetDragonrockSovereignIcon,
      openTitleKey: (l) => l.progQuestDragonrockSovereignOpenTitle,
      openDescKey: (l) => l.progQuestDragonrockSovereignOpenDesc,
      finaleTitleKey: (l) => l.progQuestDragonrockSovereignFinaleTitle,
      finaleDescKey: (l) => l.progQuestDragonrockSovereignFinaleDesc,
      finaleEmblemId: 'emblem_dragonrock_emblem',
      rewards: const [900, 1500, 1600, 1800, 2600],
      steps: [
        _StepSpec(
          id: 'dragonrock_sovereign_four_pillars_30',
          titleKey: (l) => l.progQuestDragonrockSovereignFourPillars30Title,
          descriptionKey: (l) =>
              l.progQuestDragonrockSovereignFourPillars30Desc,
          // "splň všechny 4 denní cíle 30krát" — four-pillars check.
          metric: const DaysWithAtLeastKAmongMetric(
            nodeIds: _allDailyAtoms,
            atLeast: 4,
          ),
          targetValue: 30,
          chainStepLabel: '30',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'dragonrock_sovereign_weekly_16',
          titleKey: (l) => l.progQuestDragonrockSovereignWeekly16Title,
          descriptionKey: (l) => l.progQuestDragonrockSovereignWeekly16Desc,
          metric: const NodeCompletionsMetric(nodeId: 'weekly_activity'),
          targetValue: 16,
          chainStepLabel: '16',
          domain: ProgressionDomain.activity,
        ),
        _StepSpec(
          id: 'dragonrock_sovereign_steps_50',
          titleKey: (l) => l.progQuestDragonrockSovereignSteps50Title,
          descriptionKey: (l) => l.progQuestDragonrockSovereignSteps50Desc,
          metric: const NodeCompletionsMetric(nodeId: 'daily_steps_today'),
          targetValue: 50,
          chainStepLabel: '50',
          domain: ProgressionDomain.steps,
        ),
      ],
    ),
  ];
}

String _openObjectiveId(String chapterId) => '${chapterId}_open_objective';
String _stepObjectiveId(String stepId) => '${stepId}_objective';
String _finaleObjectiveId(String chapterId) => '${chapterId}_finale_objective';

String _openNodeId(String chapterId) => '${chapterId}_open';
String _finaleNodeId(String chapterId) => '${chapterId}_finale';

List<Objective> chapterObjectives() {
  final out = <Objective>[];
  for (final c in _chapters()) {
    // Open: level gate. The objective is satisfied automatically once
    // the player reaches the chapter's start level.
    out.add(Objective(
      id: _openObjectiveId(c.id),
      domain: ProgressionDomain.activity,
      metric: const LevelMetric(),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: c.level.toDouble(),
      debugLabel: '${c.id} open — level >= ${c.level}',
    ));
    // Steps with baselines wired so each step's progress starts at the
    // previous step's completion.
    var prevNodeId = _openNodeId(c.id);
    for (final s in c.steps) {
      out.add(Objective(
        id: _stepObjectiveId(s.id),
        domain: s.domain,
        metric: s.metric,
        scope: const LifetimeScope(),
        operator: ObjectiveOperator.atLeast,
        targetValue: s.targetValue,
        baselineFromNodeId: prevNodeId,
        debugLabel: '${c.id} ${s.id} — since $prevNodeId',
      ));
      prevNodeId = s.id;
    }
    // Finale: same level gate as open; prereqs gate the actual ordering.
    out.add(Objective(
      id: _finaleObjectiveId(c.id),
      domain: ProgressionDomain.activity,
      metric: const LevelMetric(),
      scope: const LifetimeScope(),
      operator: ObjectiveOperator.atLeast,
      targetValue: c.level.toDouble(),
      debugLabel: '${c.id} finale — level gate (prereqs gate the chain)',
    ));
  }
  return out;
}

// Cross-chapter chain: each chapter's open auto-claims only once the
// previous chapter's finale is in the ledger. Order matches the spec
// list above (Ruins → … → Dragonrock); Forest Trail still chains off
// pilgrim_path_finale (declared in its own content file).
const _chapterPrereqByOpenId = <String, String>{
  'ruins_discipline_open': 'forest_trial_finale',
  'mine_descent_open': 'ruins_discipline_finale',
  'forge_momentum_open': 'mine_descent_finale',
  'underway_pact_open': 'forge_momentum_finale',
  'frostbound_oath_open': 'underway_pact_finale',
  'icewalker_route_open': 'frostbound_oath_finale',
  'mountain_ascent_open': 'icewalker_route_finale',
  'dragonroad_open': 'mountain_ascent_finale',
  'dragonrock_sovereign_open': 'dragonroad_finale',
};

List<ProgressionEntry> chapterNodes() {
  final out = <ProgressionEntry>[];
  for (final c in _chapters()) {
    final openId = _openNodeId(c.id);
    final finaleId = _finaleNodeId(c.id);
    final firstStepId = c.steps.first.id;
    final chapterPrereq = _chapterPrereqByOpenId[openId];

    out.add(ChapterOpener(
      id: openId,
      objectiveId: _openObjectiveId(c.id),
      unlockConditions: [
        LevelAtLeast(c.level),
        if (chapterPrereq != null) NodeCompleted(chapterPrereq),
      ],
      titleKey: c.openTitleKey,
      descriptionKey: c.openDescKey,
      rewards: [XpReward(amount: c.rewards[0])],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.rare,
      assetKey: c.iconAsset,
      chapterId: c.id,
      chainId: c.id,
      nextNodeIds: [firstStepId],
      chainStepIcon: Icons.play_arrow_rounded,
      sortOrder: c.sortOrder,
    ));

    for (var i = 0; i < c.steps.length; i++) {
      final step = c.steps[i];
      final prevId = i == 0 ? openId : c.steps[i - 1].id;
      final nextId = i == c.steps.length - 1 ? finaleId : c.steps[i + 1].id;
      final stepLabel = step.chainStepLabel;
      out.add(ChapterStep(
        id: step.id,
        objectiveId: _stepObjectiveId(step.id),
        titleKey: step.titleKey,
        descriptionKey: step.descriptionKey,
        rewards: [XpReward(amount: c.rewards[i + 1])],
        contentTags: const [ContentTag.core, ContentTag.fitness],
        rarity: Rarity.rare,
        assetKey: c.iconAsset,
        chapterId: c.id,
        chainId: c.id,
        chainOrder: i + 1,
        prerequisiteNodeIds: [prevId],
        nextNodeIds: [nextId],
        chainStepLabelKey: (_) => stepLabel,
        sortOrder: c.sortOrder + i + 1,
      ));
    }

    final lastStepId = c.steps.last.id;
    out.add(ChapterFinale(
      id: finaleId,
      objectiveId: _finaleObjectiveId(c.id),
      titleKey: c.finaleTitleKey,
      descriptionKey: c.finaleDescKey,
      rewards: [
        XpReward(amount: c.rewards[4]),
        CosmeticReward(cosmeticId: c.finaleEmblemId),
      ],
      contentTags: const [ContentTag.core, ContentTag.fitness],
      rarity: Rarity.epic,
      assetKey: c.iconAsset,
      chapterId: c.id,
      chainId: c.id,
      chainOrder: c.steps.length + 1,
      prerequisiteNodeIds: [lastStepId],
      unlockConditions: [LevelAtLeast(c.level)],
      chainStepIcon: Icons.shield_rounded,
      sortOrder: c.sortOrder + c.steps.length + 1,
    ));
  }
  return out;
}
