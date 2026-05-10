import '../../../../shared/domain/rarity.dart';
import '../models/content_tag.dart';
import '../models/progression_node_definition.dart';
import '../models/quest_display_bucket.dart';
import '../models/reward_definition.dart';
import '../models/unlock_condition.dart';
import 'engine_catalog_context.dart';

/// Catalog of progression nodes (quests, achievements, milestones,
/// chapter completions, companions, relics, level milestones,
/// content unlocks).
///
/// Phase 3 (pilot): a representative slice — daily quests using
/// shared objectives, an achievement that piggybacks on a daily
/// objective, a lifetime mastery achievement, the welcome
/// achievement, and one level milestone with cosmetic rewards.
/// Real ARB strings reused from the legacy catalog so titles look
/// right end-to-end. The full port lands incrementally.
class ProgressionNodeCatalog {
  const ProgressionNodeCatalog();

  static ProgressionNode? definitionForId(String id) => _byId[id];

  static final Map<String, ProgressionNode> _byId = {
    for (final def in const ProgressionNodeCatalog().build()) def.id: def,
  };

  List<ProgressionNode> build([
    EngineCatalogContext context = const EngineCatalogContext(),
  ]) {
    return [
      // ── Daily quests ─────────────────────────────────────────────
      QuestNode(
        id: 'daily_steps_today',
        objectiveId: 'daily_steps_today',
        displayBucket: QuestDisplayBucket.daily,
        titleKey: (l) => l.progRuleDailySteps,
        descriptionKey: (l) => l.progRuleDailyStepsDesc,
        rewards: const [XpReward(amount: 80)],
        contentTags: const [ContentTag.core, ContentTag.fitness],
        rarity: Rarity.common,
      ),
      QuestNode(
        id: 'daily_protein_today',
        objectiveId: 'daily_protein_today',
        displayBucket: QuestDisplayBucket.daily,
        titleKey: (l) => l.progRuleDailyProtein,
        descriptionKey: (l) => l.progRuleDailyProteinDesc,
        rewards: const [XpReward(amount: 60)],
        contentTags: const [ContentTag.core, ContentTag.fitness],
        rarity: Rarity.common,
      ),

      // ── Achievements ─────────────────────────────────────────────
      AchievementNode(
        id: 'welcome_to_journey',
        objectiveId: 'welcome_xp',
        titleKey: (l) => l.progAchievementWelcomeToJourneyTitle,
        descriptionKey: (l) => l.progAchievementWelcomeToJourneyDesc,
        rewards: const [
          CosmeticReward(cosmeticId: 'background_camp'),
          CosmeticReward(cosmeticId: 'emblem_pilgrim_mark'),
        ],
        contentTags: const [ContentTag.core, ContentTag.cosmetics],
        rarity: Rarity.common,
      ),
      AchievementNode(
        id: 'lifetime_steps_100k',
        objectiveId: 'lifetime_steps_100k',
        titleKey: (l) => l.progDomainSteps,
        descriptionKey: (l) => l.progRewardsSectionLabel,
        rewards: const [
          CosmeticReward(cosmeticId: 'background_forest_trail'),
        ],
        contentTags: const [ContentTag.core, ContentTag.fitness],
        rarity: Rarity.uncommon,
      ),

      // ── Level milestone ──────────────────────────────────────────
      LevelMilestoneNode(
        id: 'level_5',
        level: 5,
        emoji: '\u{1F97E}', // 🥾 hiking boot — matches legacy tier
        titleKey: (l) => l.progDomainSteps,
        descriptionKey: (l) => l.progLevelAchievementDesc(5),
        rewards: const [
          CosmeticReward(cosmeticId: 'background_forest_trail'),
        ],
        unlockConditions: const [LevelAtLeast(5)],
        isTitleBreakpoint: true,
        contentTags: const [ContentTag.core, ContentTag.journey],
        rarity: Rarity.common,
      ),
    ];
  }
}
