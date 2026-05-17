import 'package:forgetrack/domain/progression/catalog/ids.dart';
import '../../../../../shared/domain/rarity.dart';
import '../../localized_text.dart';
import '../../models/claim_policy.dart';
import '../../models/content_tag.dart';
import '../../models/objective_definition.dart';
import '../../models/objective_metric.dart';
import '../../models/objective_operator.dart';
import '../../models/objective_scope.dart';
import '../../models/progression_node_definition.dart';
import '../../models/reward_definition.dart';
import '../../models/unlock_condition.dart';
import '../engine_catalog_context.dart';
import 'quest_assets.dart';

/// **Chapter side quests.** Narrative bonus content tied to the
/// active chapter — surfaces only while `ChapterActive(chapterId)`
/// is true (chapter's `_open` quest done, `_finale` not yet).
///
/// **Pool shape varies per chapter.** Early chapters offer simple
/// one-off side quests; mid chapters add richer targets and bonus
/// XP conditions; late chapters introduce sequential **combo
/// chains** (one step claimable per day via
/// `NodeCompletedBeforeToday`) that build toward a chapter-defining
/// finale. Not every late chapter has a chain — variety is the
/// point, the pool reads as themed content not a uniform grid.
///
/// **Chain placement** (deliberately staggered, not every chapter):
/// - `icewalker_route` — 2-step chain (chain debut).
/// - `mountain_ascent` — no chain, three standalone side quests.
/// - `dragonroad` — 2-step chain.
/// - `dragonrock_sovereign` — 4-step apex chain culminating in a
///   true perfect day (8/8 daily goals + stacked bonuses for
///   pre-18:00 finish and ≥ 7 h sleep).
///
/// **XP scaling.** Base XP grows with chapter level, then the engine
/// multiplies by `rewardMultiplierForLevel` at claim time (×62.5 at
/// lvl 50, ×150 at lvl 100). A 1500-base apex finale at lvl 100
/// awards ≈ 225 000 XP — significant but well under the ~778 000-XP
/// level boundary at that tier. Stacked bonuses on the apex push
/// the perfect-day claim toward ~375 000 XP, still under half a
/// level — a real summit, but not level-skipping.
///
/// **Retirement.** All side quests use `LifetimeScope`. When the
/// chapter finale lands, `ChapterActive` flips false and any unmet
/// steps quietly retire — the player moves on with the journey.

const _pilgrimPath = 'pilgrim_path';
const _forestTrial = 'forest_trial';
const _ruinsDiscipline = 'ruins_discipline';
const _mineDescent = 'mine_descent';
const _forgeMomentum = 'forge_momentum';
const _underwayPact = 'underway_pact';
const _frostboundOath = 'frostbound_oath';
const _icewalkerRoute = 'icewalker_route';
const _mountainAscent = 'mountain_ascent';
const _dragonroad = 'dragonroad';
const _dragonrockSovereign = 'dragonrock_sovereign';

Objective _amongObjective(
  String id,
  List<String> nodeIds,
  int target,
) {
  return Objective(
    id: ObjectiveId(id),
    metric: TodayCompletionsAmongMetric(nodeIds: nodeIds),
    scope: const LifetimeScope(),
    operator: ObjectiveOperator.atLeast,
    targetValue: target.toDouble(),
  );
}

List<Objective> chapterSideQuestObjectives(
  EngineCatalogContext context,
) {
  return [
    // ── Pilgrim Path ───────────────────────────────────────────
    _amongObjective(
      'side_pilgrim_morning_walk_obj',
      const ['daily_steps_today', 'daily_activity_today'],
      2,
    ),
    _amongObjective(
      'side_pilgrim_quiet_rest_obj',
      const ['daily_sleep_today', 'daily_protein_today'],
      2,
    ),

    // ── Forest Trial (lv 10) — 1 standalone + 2-step chain ─────
    _amongObjective(
      'side_forest_briskwalk_obj',
      const ['daily_steps_today', 'daily_activity_today'],
      2,
    ),
    _amongObjective(
      'side_forest_camp_obj',
      const [
        'daily_sleep_today',
        'daily_protein_today',
        'daily_calories_today',
      ],
      3,
    ),
    _amongObjective(
      'side_forest_clearing_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_protein_today',
      ],
      4,
    ),

    // ── Ruins of Discipline ────────────────────────────────────
    _amongObjective(
      'side_ruins_steady_dawn_obj',
      const [
        'daily_steps_today',
        'daily_sleep_today',
        'daily_protein_today',
      ],
      3,
    ),
    _amongObjective(
      'side_ruins_iron_intake_obj',
      const [
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
        'daily_fiber_today',
      ],
      3,
    ),

    // ── Mine Descent ───────────────────────────────────────────
    _amongObjective(
      'side_mine_torchbearer_obj',
      const ['daily_steps_today', 'daily_activity_today'],
      2,
    ),
    _amongObjective(
      'side_mine_long_haul_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
      ],
      3,
    ),

    // ── Mine Descent combo chain ───────────────────────────────
    _amongObjective(
      'side_mine_deep_shaft_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
      ],
      3,
    ),
    _amongObjective(
      'side_mine_forge_finale_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
      ],
      5,
    ),

    // ── Forge Momentum ─────────────────────────────────────────
    _amongObjective(
      'side_forge_morning_anvil_obj',
      const ['daily_steps_today', 'daily_activity_today'],
      2,
    ),
    _amongObjective(
      'side_forge_full_furnace_obj',
      const [
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
      ],
      4,
    ),

    // ── Underway Pact ──────────────────────────────────────────
    _amongObjective(
      'side_underway_warm_camp_obj',
      const [
        'daily_sleep_today',
        'daily_protein_today',
        'daily_calories_today',
      ],
      3,
    ),
    _amongObjective(
      'side_underway_long_watch_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
      ],
      3,
    ),

    // ── Underway Pact combo chain ──────────────────────────────
    _amongObjective(
      'side_pact_march_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
      ],
      4,
    ),
    _amongObjective(
      'side_pact_finale_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_protein_today',
        'daily_calories_today',
        'daily_carbs_today',
        'daily_fat_today',
      ],
      6,
    ),

    // ── Frostbound Oath ────────────────────────────────────────
    _amongObjective(
      'side_frostbound_first_light_obj',
      const ['daily_steps_today', 'daily_activity_today'],
      2,
    ),
    _amongObjective(
      'side_frostbound_long_oath_obj',
      const [
        'daily_steps_today',
        'daily_sleep_today',
        'daily_protein_today',
        'daily_calories_today',
      ],
      4,
    ),

    // ── Icewalker Route (1 standalone + 2-step chain) ──────────
    _amongObjective(
      'side_icewalker_dawn_march_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_calories_today',
      ],
      3,
    ),
    _amongObjective(
      'side_icewalker_provisioner_obj',
      const [
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
        'daily_fiber_today',
      ],
      5,
    ),
    _amongObjective(
      'side_icewalker_finale_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
      ],
      6,
    ),

    // ── Mountain Ascent (3 standalone, no chain — variety) ─────
    _amongObjective(
      'side_mountain_steep_morning_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
      ],
      3,
    ),
    _amongObjective(
      'side_mountain_full_ridge_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_protein_today',
        'daily_calories_today',
      ],
      5,
    ),

    // ── Dragonroad (1 standalone + 2-step chain) ───────────────
    _amongObjective(
      'side_dragonroad_warden_dawn_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_calories_today',
        'daily_protein_today',
      ],
      4,
    ),
    _amongObjective(
      'side_dragonroad_iron_appetite_obj',
      const [
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
        'daily_fiber_today',
      ],
      5,
    ),
    _amongObjective(
      'side_dragonroad_finale_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
      ],
      7,
    ),

    // ── Dragonrock Sovereign (1 standalone + 4-step apex chain) ─
    _amongObjective(
      'side_dragonrock_sovereign_dawn_obj',
      const [
        'daily_steps_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
      ],
      5,
    ),
    _amongObjective(
      'side_dragonrock_sovereign_vigil_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
      ],
      6,
    ),
    _amongObjective(
      'side_dragonrock_sovereign_throne_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
      ],
      7,
    ),
    _amongObjective(
      'side_dragonrock_sovereign_crown_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
        'daily_fiber_today',
      ],
      7,
    ),
    // Apex finale — 8/8 daily goals = a literal perfect day.
    _amongObjective(
      'side_dragonrock_sovereign_finale_obj',
      const [
        'daily_steps_today',
        'daily_activity_today',
        'daily_sleep_today',
        'daily_calories_today',
        'daily_protein_today',
        'daily_carbs_today',
        'daily_fat_today',
        'daily_fiber_today',
      ],
      8,
    ),
  ];
}

/// **Standalone side quest** — ungated by other side quests, just
/// gated by the chapter being active + an early chapter chain step
/// being done. The default everywhere except chain steps.
Quest _standalone({
  required String id,
  required String objectiveId,
  required String chapterId,
  required String chapterEntryGateNodeId,
  required LocalizedText titleKey,
  required LocalizedText descriptionKey,
  required int baseXp,
  required Rarity rarity,
  required String assetKey,
  List<RewardDefinition> bonusRewards = const [],
}) {
  return ChapterSideQuest(
    id: ProgressionEntryId(id),
    objectiveId: objectiveId,
    claimPolicy: ClaimPolicy.manual,
    // ChapterActive is the only "soft" gate — it filters by the
    // active chapter window. The "must be completed" + "must be at
    // least a day old" gates derive from the prereq + the subtype's
    // CooldownDays(1) policy.
    unlockConditions: [ChapterActive(chapterId)],
    prerequisiteNodeIds: [chapterEntryGateNodeId],
    titleKey: titleKey,
    descriptionKey: descriptionKey,
    rewards: [XpReward(amount: baseXp), ...bonusRewards],
    contentTags: const [ContentTag.core, ContentTag.fitness],
    rarity: rarity,
    assetKey: assetKey,
    chapterId: chapterId,
  );
}

/// **Chain step** — sequential side quest. First step gates on the
/// chapter entry node; subsequent steps gate on the prior step.
/// The `CooldownDays(1)` policy on [ChapterSideQuest] adds the
/// "wait until tomorrow" rule, so the catalog only declares the
/// hard dependency.
Quest _chainStep({
  required String id,
  required String objectiveId,
  required String chapterId,
  required String chainId,
  required int chainOrder,
  required String chainStepLabel,
  required String chapterEntryGateNodeId,
  required String? prerequisiteNodeId,
  required String? nextNodeId,
  required LocalizedText titleKey,
  required LocalizedText descriptionKey,
  required int baseXp,
  required Rarity rarity,
  required String assetKey,
  List<RewardDefinition> bonusRewards = const [],
}) {
  // First step gates on the chapter chain entry; subsequent steps
  // gate on the prior side-quest step. Either way the gate goes
  // into `prerequisiteNodeIds` and the subtype's CooldownDays(1)
  // policy derives both `NodeCompleted` and `NodeCompletedBeforeToday`.
  final prereqId = prerequisiteNodeId ?? chapterEntryGateNodeId;
  return ChapterSideQuest(
    id: ProgressionEntryId(id),
    objectiveId: objectiveId,
    claimPolicy: ClaimPolicy.manual,
    unlockConditions: [ChapterActive(chapterId)],
    prerequisiteNodeIds: [prereqId],
    titleKey: titleKey,
    descriptionKey: descriptionKey,
    rewards: [XpReward(amount: baseXp), ...bonusRewards],
    contentTags: const [ContentTag.core, ContentTag.fitness],
    rarity: rarity,
    assetKey: assetKey,
    chapterId: chapterId,
    chainId: chainId,
    chainOrder: chainOrder,
    chainStepLabelKey: (_) => chainStepLabel,
    nextNodeIds: nextNodeId == null ? const [] : [nextNodeId],
  );
}

List<ProgressionEntry> chapterSideQuests() {
  return [
    // ── Pilgrim Path (2 standalone) ────────────────────────────
    _standalone(
      id: const ProgressionEntryId('side_pilgrim_morning_walk'),
      objectiveId: 'side_pilgrim_morning_walk_obj',
      chapterId: _pilgrimPath,
      chapterEntryGateNodeId: 'pilgrim_path_first_steps',
      titleKey: (l) => l.progSidePilgrimMorningWalkTitle,
      descriptionKey: (l) => l.progSidePilgrimMorningWalkDesc,
      baseXp: 80,
      rarity: Rarity.uncommon,
      assetKey: questAssetPilgrimPathIcon,
    ),
    _standalone(
      id: const ProgressionEntryId('side_pilgrim_quiet_rest'),
      objectiveId: 'side_pilgrim_quiet_rest_obj',
      chapterId: _pilgrimPath,
      chapterEntryGateNodeId: 'pilgrim_path_first_reward',
      titleKey: (l) => l.progSidePilgrimQuietRestTitle,
      descriptionKey: (l) => l.progSidePilgrimQuietRestDesc,
      baseXp: 110,
      rarity: Rarity.uncommon,
      assetKey: questAssetPilgrimPathIcon,
    ),

    // ── Forest Trial (1 standalone + 2-step chain) ─────────────
    _standalone(
      id: const ProgressionEntryId('side_forest_briskwalk'),
      objectiveId: 'side_forest_briskwalk_obj',
      chapterId: _forestTrial,
      chapterEntryGateNodeId: 'forest_trial_daily_wins_5',
      titleKey: (l) => l.progSideForestBriskwalkTitle,
      descriptionKey: (l) => l.progSideForestBriskwalkDesc,
      baseXp: 100,
      rarity: Rarity.uncommon,
      assetKey: questAssetForestTrialIcon,
    ),
    _chainStep(
      id: const ProgressionEntryId('side_forest_camp'),
      objectiveId: 'side_forest_camp_obj',
      chapterId: _forestTrial,
      chainId: 'forest_trial_side',
      chainOrder: 0,
      chainStepLabel: '1',
      chapterEntryGateNodeId: 'forest_trial_steps_5',
      prerequisiteNodeId: null,
      nextNodeId: 'side_forest_clearing',
      titleKey: (l) => l.progSideForestCampTitle,
      descriptionKey: (l) => l.progSideForestCampDesc,
      baseXp: 130,
      rarity: Rarity.uncommon,
      assetKey: questAssetForestTrialIcon,
    ),
    _chainStep(
      id: const ProgressionEntryId('side_forest_clearing'),
      objectiveId: 'side_forest_clearing_obj',
      chapterId: _forestTrial,
      chainId: 'forest_trial_side',
      chainOrder: 1,
      chainStepLabel: '🛡',
      chapterEntryGateNodeId: 'forest_trial_steps_5',
      prerequisiteNodeId: 'side_forest_camp',
      nextNodeId: null,
      titleKey: (l) => l.progSideForestClearingTitle,
      descriptionKey: (l) => l.progSideForestClearingDesc,
      baseXp: 200,
      rarity: Rarity.uncommon,
      assetKey: questAssetForestTrialIcon,
      bonusRewards: const [
        BonusXpReward(amount: 60, condition: CompletedBeforeHour(18)),
      ],
    ),

    // ── Ruins of Discipline (2 standalone) ─────────────────────
    _standalone(
      id: const ProgressionEntryId('side_ruins_steady_dawn'),
      objectiveId: 'side_ruins_steady_dawn_obj',
      chapterId: _ruinsDiscipline,
      chapterEntryGateNodeId: 'ruins_discipline_nutrition_7',
      titleKey: (l) => l.progSideRuinsSteadyDawnTitle,
      descriptionKey: (l) => l.progSideRuinsSteadyDawnDesc,
      baseXp: 140,
      rarity: Rarity.uncommon,
      assetKey: questAssetRuinsDisciplineIcon,
    ),
    _standalone(
      id: const ProgressionEntryId('side_ruins_iron_intake'),
      objectiveId: 'side_ruins_iron_intake_obj',
      chapterId: _ruinsDiscipline,
      chapterEntryGateNodeId: 'ruins_discipline_weekly_2',
      titleKey: (l) => l.progSideRuinsIronIntakeTitle,
      descriptionKey: (l) => l.progSideRuinsIronIntakeDesc,
      baseXp: 200,
      rarity: Rarity.uncommon,
      assetKey: questAssetRuinsDisciplineIcon,
      bonusRewards: const [
        BonusXpReward(amount: 60, condition: CompletedBeforeHour(18)),
      ],
    ),

    // ── Mine Descent (2 standalone) ────────────────────────────
    _standalone(
      id: const ProgressionEntryId('side_mine_torchbearer'),
      objectiveId: 'side_mine_torchbearer_obj',
      chapterId: _mineDescent,
      chapterEntryGateNodeId: 'mine_descent_steps_250k',
      titleKey: (l) => l.progSideMineTorchbearerTitle,
      descriptionKey: (l) => l.progSideMineTorchbearerDesc,
      baseXp: 220,
      rarity: Rarity.uncommon,
      assetKey: questAssetMineDescentIcon,
    ),
    _standalone(
      id: const ProgressionEntryId('side_mine_long_haul'),
      objectiveId: 'side_mine_long_haul_obj',
      chapterId: _mineDescent,
      chapterEntryGateNodeId: 'mine_descent_activity_rewards_12',
      titleKey: (l) => l.progSideMineLongHaulTitle,
      descriptionKey: (l) => l.progSideMineLongHaulDesc,
      baseXp: 300,
      rarity: Rarity.uncommon,
      assetKey: questAssetMineDescentIcon,
      bonusRewards: const [
        BonusXpReward(amount: 90, condition: CompletedBeforeHour(18)),
      ],
    ),

    // ── Mine Descent combo chain (2-step, gates on chain step 3) ─
    _chainStep(
      id: const ProgressionEntryId('side_mine_deep_shaft'),
      objectiveId: 'side_mine_deep_shaft_obj',
      chapterId: _mineDescent,
      chainId: 'mine_descent_side',
      chainOrder: 0,
      chainStepLabel: '1',
      chapterEntryGateNodeId: 'mine_descent_protein_10',
      prerequisiteNodeId: null,
      nextNodeId: 'side_mine_forge_finale',
      titleKey: (l) => l.progSideMineDeepShaftTitle,
      descriptionKey: (l) => l.progSideMineDeepShaftDesc,
      baseXp: 280,
      rarity: Rarity.uncommon,
      assetKey: questAssetMineDescentIcon,
      bonusRewards: const [
        BonusXpReward(amount: 100, condition: CompletedBeforeHour(14)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_mine_forge_finale'),
      objectiveId: 'side_mine_forge_finale_obj',
      chapterId: _mineDescent,
      chainId: 'mine_descent_side',
      chainOrder: 1,
      chainStepLabel: '🛡',
      chapterEntryGateNodeId: 'mine_descent_protein_10',
      prerequisiteNodeId: 'side_mine_deep_shaft',
      nextNodeId: null,
      titleKey: (l) => l.progSideMineForgeFinaleTitle,
      descriptionKey: (l) => l.progSideMineForgeFinaleDesc,
      baseXp: 400,
      rarity: Rarity.rare,
      assetKey: questAssetMineDescentIcon,
      bonusRewards: const [
        BonusXpReward(amount: 140, condition: SleepAtLeast(minutes: 420)),
      ],
    ),

    // ── Forge Momentum (2 standalone) ──────────────────────────
    _standalone(
      id: const ProgressionEntryId('side_forge_morning_anvil'),
      objectiveId: 'side_forge_morning_anvil_obj',
      chapterId: _forgeMomentum,
      chapterEntryGateNodeId: 'forge_momentum_weekly_4',
      titleKey: (l) => l.progSideForgeMorningAnvilTitle,
      descriptionKey: (l) => l.progSideForgeMorningAnvilDesc,
      baseXp: 320,
      rarity: Rarity.uncommon,
      assetKey: questAssetForgeMomentumIcon,
      bonusRewards: const [
        BonusXpReward(amount: 120, condition: CompletedBeforeHour(12)),
      ],
    ),
    _standalone(
      id: const ProgressionEntryId('side_forge_full_furnace'),
      objectiveId: 'side_forge_full_furnace_obj',
      chapterId: _forgeMomentum,
      chapterEntryGateNodeId: 'forge_momentum_steps_20',
      titleKey: (l) => l.progSideForgeFullFurnaceTitle,
      descriptionKey: (l) => l.progSideForgeFullFurnaceDesc,
      baseXp: 420,
      rarity: Rarity.rare,
      assetKey: questAssetForgeMomentumIcon,
      bonusRewards: const [
        BonusXpReward(amount: 140, condition: CompletedBeforeHour(18)),
      ],
    ),

    // ── Underway Pact (2 standalone) ───────────────────────────
    _standalone(
      id: const ProgressionEntryId('side_underway_warm_camp'),
      objectiveId: 'side_underway_warm_camp_obj',
      chapterId: _underwayPact,
      chapterEntryGateNodeId: 'underway_pact_four_pillars_5',
      titleKey: (l) => l.progSideUnderwayWarmCampTitle,
      descriptionKey: (l) => l.progSideUnderwayWarmCampDesc,
      baseXp: 460,
      rarity: Rarity.rare,
      assetKey: questAssetUnderwayPactIcon,
      bonusRewards: const [
        BonusXpReward(amount: 150, condition: SleepAtLeast(minutes: 420)),
      ],
    ),
    _standalone(
      id: const ProgressionEntryId('side_underway_long_watch'),
      objectiveId: 'side_underway_long_watch_obj',
      chapterId: _underwayPact,
      chapterEntryGateNodeId: 'underway_pact_sleep_14',
      titleKey: (l) => l.progSideUnderwayLongWatchTitle,
      descriptionKey: (l) => l.progSideUnderwayLongWatchDesc,
      baseXp: 560,
      rarity: Rarity.rare,
      assetKey: questAssetUnderwayPactIcon,
      bonusRewards: const [
        BonusXpReward(amount: 180, condition: CompletedBeforeHour(14)),
      ],
    ),

    // ── Underway Pact combo chain (2-step, gates on chain step 3) ─
    _chainStep(
      id: const ProgressionEntryId('side_pact_march'),
      objectiveId: 'side_pact_march_obj',
      chapterId: _underwayPact,
      chainId: 'underway_pact_side',
      chainOrder: 0,
      chainStepLabel: '1',
      chapterEntryGateNodeId: 'underway_pact_recovery_10',
      prerequisiteNodeId: null,
      nextNodeId: 'side_pact_finale',
      titleKey: (l) => l.progSidePactMarchTitle,
      descriptionKey: (l) => l.progSidePactMarchDesc,
      baseXp: 600,
      rarity: Rarity.rare,
      assetKey: questAssetUnderwayPactIcon,
      bonusRewards: const [
        BonusXpReward(amount: 200, condition: CompletedBeforeHour(14)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_pact_finale'),
      objectiveId: 'side_pact_finale_obj',
      chapterId: _underwayPact,
      chainId: 'underway_pact_side',
      chainOrder: 1,
      chainStepLabel: '🛡',
      chapterEntryGateNodeId: 'underway_pact_recovery_10',
      prerequisiteNodeId: 'side_pact_march',
      nextNodeId: null,
      titleKey: (l) => l.progSidePactFinaleTitle,
      descriptionKey: (l) => l.progSidePactFinaleDesc,
      baseXp: 820,
      rarity: Rarity.rare,
      assetKey: questAssetUnderwayPactIcon,
      bonusRewards: const [
        BonusXpReward(amount: 280, condition: SleepAtLeast(minutes: 420)),
      ],
    ),

    // ── Frostbound Oath (2 standalone) ─────────────────────────
    _standalone(
      id: const ProgressionEntryId('side_frostbound_first_light'),
      objectiveId: 'side_frostbound_first_light_obj',
      chapterId: _frostboundOath,
      chapterEntryGateNodeId: 'frostbound_oath_steps_21',
      titleKey: (l) => l.progSideFrostboundFirstLightTitle,
      descriptionKey: (l) => l.progSideFrostboundFirstLightDesc,
      baseXp: 600,
      rarity: Rarity.rare,
      assetKey: questAssetFrostboundOathIcon,
      bonusRewards: const [
        BonusXpReward(amount: 200, condition: CompletedBeforeHour(12)),
      ],
    ),
    _standalone(
      id: const ProgressionEntryId('side_frostbound_long_oath'),
      objectiveId: 'side_frostbound_long_oath_obj',
      chapterId: _frostboundOath,
      chapterEntryGateNodeId: 'frostbound_oath_sleep_21',
      titleKey: (l) => l.progSideFrostboundLongOathTitle,
      descriptionKey: (l) => l.progSideFrostboundLongOathDesc,
      baseXp: 720,
      rarity: Rarity.rare,
      assetKey: questAssetFrostboundOathIcon,
      bonusRewards: const [
        BonusXpReward(amount: 240, condition: SleepAtLeast(minutes: 420)),
      ],
    ),

    // ── Icewalker Route (1 standalone + 2-step chain) ──────────
    _standalone(
      id: const ProgressionEntryId('side_icewalker_dawn_march'),
      objectiveId: 'side_icewalker_dawn_march_obj',
      chapterId: _icewalkerRoute,
      chapterEntryGateNodeId: 'icewalker_route_steps_500k',
      titleKey: (l) => l.progSideIcewalkerDawnMarchTitle,
      descriptionKey: (l) => l.progSideIcewalkerDawnMarchDesc,
      baseXp: 760,
      rarity: Rarity.rare,
      assetKey: questAssetIcewalkerRouteIcon,
      bonusRewards: const [
        BonusXpReward(amount: 260, condition: CompletedBeforeHour(12)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_icewalker_provisioner'),
      objectiveId: 'side_icewalker_provisioner_obj',
      chapterId: _icewalkerRoute,
      chainId: 'icewalker_route_side',
      chainOrder: 0,
      chainStepLabel: '1',
      chapterEntryGateNodeId: 'icewalker_route_rewards_150',
      prerequisiteNodeId: null,
      nextNodeId: 'side_icewalker_finale',
      titleKey: (l) => l.progSideIcewalkerProvisionerTitle,
      descriptionKey: (l) => l.progSideIcewalkerProvisionerDesc,
      baseXp: 700,
      rarity: Rarity.rare,
      assetKey: questAssetIcewalkerRouteIcon,
      bonusRewards: const [
        BonusXpReward(amount: 220, condition: CompletedBeforeHour(18)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_icewalker_finale'),
      objectiveId: 'side_icewalker_finale_obj',
      chapterId: _icewalkerRoute,
      chainId: 'icewalker_route_side',
      chainOrder: 1,
      chainStepLabel: '🛡',
      chapterEntryGateNodeId: 'icewalker_route_rewards_150',
      prerequisiteNodeId: 'side_icewalker_provisioner',
      nextNodeId: null,
      titleKey: (l) => l.progSideIcewalkerFinaleTitle,
      descriptionKey: (l) => l.progSideIcewalkerFinaleDesc,
      baseXp: 1000,
      rarity: Rarity.epic,
      assetKey: questAssetIcewalkerRouteIcon,
      bonusRewards: const [
        BonusXpReward(amount: 320, condition: SleepAtLeast(minutes: 420)),
      ],
    ),

    // ── Mountain Ascent (2 standalone, deliberately no chain) ──
    _standalone(
      id: const ProgressionEntryId('side_mountain_steep_morning'),
      objectiveId: 'side_mountain_steep_morning_obj',
      chapterId: _mountainAscent,
      chapterEntryGateNodeId: 'mountain_ascent_four_pillars_15',
      titleKey: (l) => l.progSideMountainSteepMorningTitle,
      descriptionKey: (l) => l.progSideMountainSteepMorningDesc,
      baseXp: 880,
      rarity: Rarity.rare,
      assetKey: questAssetMountainAscentIcon,
      bonusRewards: const [
        BonusXpReward(amount: 300, condition: CompletedBeforeHour(14)),
      ],
    ),
    _standalone(
      id: const ProgressionEntryId('side_mountain_full_ridge'),
      objectiveId: 'side_mountain_full_ridge_obj',
      chapterId: _mountainAscent,
      chapterEntryGateNodeId: 'mountain_ascent_steps_30',
      titleKey: (l) => l.progSideMountainFullRidgeTitle,
      descriptionKey: (l) => l.progSideMountainFullRidgeDesc,
      baseXp: 1000,
      rarity: Rarity.epic,
      assetKey: questAssetMountainAscentIcon,
      bonusRewards: const [
        BonusXpReward(amount: 340, condition: SleepAtLeast(minutes: 420)),
      ],
    ),

    // ── Dragonroad (1 standalone + 2-step chain) ───────────────
    _standalone(
      id: const ProgressionEntryId('side_dragonroad_warden_dawn'),
      objectiveId: 'side_dragonroad_warden_dawn_obj',
      chapterId: _dragonroad,
      chapterEntryGateNodeId: 'dragonroad_rewards_250',
      titleKey: (l) => l.progSideDragonroadWardenDawnTitle,
      descriptionKey: (l) => l.progSideDragonroadWardenDawnDesc,
      baseXp: 1100,
      rarity: Rarity.epic,
      assetKey: questAssetDragonroadIcon,
      bonusRewards: const [
        BonusXpReward(amount: 360, condition: CompletedBeforeHour(14)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_dragonroad_iron_appetite'),
      objectiveId: 'side_dragonroad_iron_appetite_obj',
      chapterId: _dragonroad,
      chainId: 'dragonroad_side',
      chainOrder: 0,
      chainStepLabel: '1',
      chapterEntryGateNodeId: 'dragonroad_four_pillars_25',
      prerequisiteNodeId: null,
      nextNodeId: 'side_dragonroad_finale',
      titleKey: (l) => l.progSideDragonroadIronAppetiteTitle,
      descriptionKey: (l) => l.progSideDragonroadIronAppetiteDesc,
      baseXp: 1000,
      rarity: Rarity.epic,
      assetKey: questAssetDragonroadIcon,
      bonusRewards: const [
        BonusXpReward(amount: 320, condition: CompletedBeforeHour(14)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_dragonroad_finale'),
      objectiveId: 'side_dragonroad_finale_obj',
      chapterId: _dragonroad,
      chainId: 'dragonroad_side',
      chainOrder: 1,
      chainStepLabel: '🛡',
      chapterEntryGateNodeId: 'dragonroad_four_pillars_25',
      prerequisiteNodeId: 'side_dragonroad_iron_appetite',
      nextNodeId: null,
      titleKey: (l) => l.progSideDragonroadFinaleTitle,
      descriptionKey: (l) => l.progSideDragonroadFinaleDesc,
      baseXp: 1300,
      rarity: Rarity.epic,
      assetKey: questAssetDragonroadIcon,
      bonusRewards: const [
        BonusXpReward(amount: 420, condition: SleepAtLeast(minutes: 420)),
      ],
    ),

    // ── Dragonrock Sovereign (1 standalone + 4-step apex) ──────
    _standalone(
      id: const ProgressionEntryId('side_dragonrock_sovereign_dawn'),
      objectiveId: 'side_dragonrock_sovereign_dawn_obj',
      chapterId: _dragonrockSovereign,
      chapterEntryGateNodeId: 'dragonrock_sovereign_four_pillars_30',
      titleKey: (l) => l.progSideDragonrockSovereignDawnTitle,
      descriptionKey: (l) => l.progSideDragonrockSovereignDawnDesc,
      baseXp: 1200,
      rarity: Rarity.epic,
      assetKey: questAssetDragonrockSovereignIcon,
      bonusRewards: const [
        BonusXpReward(amount: 400, condition: CompletedBeforeHour(18)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_dragonrock_sovereign_vigil'),
      objectiveId: 'side_dragonrock_sovereign_vigil_obj',
      chapterId: _dragonrockSovereign,
      chainId: 'dragonrock_sovereign_side',
      chainOrder: 0,
      chainStepLabel: '1',
      chapterEntryGateNodeId: 'dragonrock_sovereign_weekly_16',
      prerequisiteNodeId: null,
      nextNodeId: 'side_dragonrock_sovereign_throne',
      titleKey: (l) => l.progSideDragonrockSovereignVigilTitle,
      descriptionKey: (l) => l.progSideDragonrockSovereignVigilDesc,
      baseXp: 1100,
      rarity: Rarity.epic,
      assetKey: questAssetDragonrockSovereignIcon,
      bonusRewards: const [
        BonusXpReward(amount: 360, condition: SleepAtLeast(minutes: 420)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_dragonrock_sovereign_throne'),
      objectiveId: 'side_dragonrock_sovereign_throne_obj',
      chapterId: _dragonrockSovereign,
      chainId: 'dragonrock_sovereign_side',
      chainOrder: 1,
      chainStepLabel: '2',
      chapterEntryGateNodeId: 'dragonrock_sovereign_weekly_16',
      prerequisiteNodeId: 'side_dragonrock_sovereign_vigil',
      nextNodeId: 'side_dragonrock_sovereign_crown',
      titleKey: (l) => l.progSideDragonrockSovereignThroneTitle,
      descriptionKey: (l) => l.progSideDragonrockSovereignThroneDesc,
      baseXp: 1250,
      rarity: Rarity.epic,
      assetKey: questAssetDragonrockSovereignIcon,
      bonusRewards: const [
        BonusXpReward(amount: 420, condition: CompletedBeforeHour(14)),
      ],
    ),
    _chainStep(
      id: const ProgressionEntryId('side_dragonrock_sovereign_crown'),
      objectiveId: 'side_dragonrock_sovereign_crown_obj',
      chapterId: _dragonrockSovereign,
      chainId: 'dragonrock_sovereign_side',
      chainOrder: 2,
      chainStepLabel: '3',
      chapterEntryGateNodeId: 'dragonrock_sovereign_weekly_16',
      prerequisiteNodeId: 'side_dragonrock_sovereign_throne',
      nextNodeId: 'side_dragonrock_sovereign_finale',
      titleKey: (l) => l.progSideDragonrockSovereignCrownTitle,
      descriptionKey: (l) => l.progSideDragonrockSovereignCrownDesc,
      baseXp: 1400,
      rarity: Rarity.epic,
      assetKey: questAssetDragonrockSovereignIcon,
      bonusRewards: const [
        BonusXpReward(amount: 460, condition: SleepAtLeast(minutes: 420)),
      ],
    ),
    // **Apex finale.** A literal perfect day — every one of the 8
    // daily goals met — with two stacked bonuses (≥ 7 h sleep AND
    // finished before 18:00). Highest base XP in the catalog.
    _chainStep(
      id: const ProgressionEntryId('side_dragonrock_sovereign_finale'),
      objectiveId: 'side_dragonrock_sovereign_finale_obj',
      chapterId: _dragonrockSovereign,
      chainId: 'dragonrock_sovereign_side',
      chainOrder: 3,
      chainStepLabel: '👑',
      chapterEntryGateNodeId: 'dragonrock_sovereign_weekly_16',
      prerequisiteNodeId: 'side_dragonrock_sovereign_crown',
      nextNodeId: null,
      titleKey: (l) => l.progSideDragonrockSovereignFinaleTitle,
      descriptionKey: (l) => l.progSideDragonrockSovereignFinaleDesc,
      baseXp: 1500,
      rarity: Rarity.legendary,
      assetKey: questAssetDragonrockSovereignIcon,
      bonusRewards: const [
        BonusXpReward(amount: 500, condition: SleepAtLeast(minutes: 420)),
        BonusXpReward(amount: 500, condition: CompletedBeforeHour(18)),
      ],
    ),
  ];
}
