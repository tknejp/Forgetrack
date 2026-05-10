import '../../../../shared/domain/rarity.dart';
import '../models/progression_node_definition.dart';
import '../models/quest_display_bucket.dart';
import '../models/reward_definition.dart';

/// Catalog of progression nodes (quests, achievements, milestones,
/// chapter completions, companions, relics, level milestones, content
/// unlocks). Phase 1 ships an empty `build()` plus a sample node per
/// representative type so the validator + tests have something to
/// exercise; real content lands during Phase 3 (catalog port).
class ProgressionNodeCatalog {
  const ProgressionNodeCatalog();

  static ProgressionNode? definitionForId(String id) => _byId[id];

  static final Map<String, ProgressionNode> _byId = {
    for (final def in const ProgressionNodeCatalog().build()) def.id: def,
  };

  List<ProgressionNode> build() {
    return [
      // Sample quest referencing the matching sample objective.
      QuestNode(
        id: 'sample_quest_steps_today',
        objectiveId: 'sample_steps_today',
        displayBucket: QuestDisplayBucket.daily,
        titleKey: (l) => l.progDomainSteps,
        descriptionKey: (l) => l.progRuleDailyStepsDesc,
        rewards: const [XpReward(amount: 80)],
        rarity: Rarity.common,
      ),
      // Sample achievement sharing the same objective — proves the
      // "one objective, many nodes" design end-to-end.
      AchievementNode(
        id: 'sample_achievement_steps_today',
        objectiveId: 'sample_steps_today',
        titleKey: (l) => l.progDomainSteps,
        descriptionKey: (l) => l.progRuleDailyStepsDesc,
        rewards: const [],
        rarity: Rarity.common,
      ),
    ];
  }
}
