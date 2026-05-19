import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';

import 'progression_node_catalog.dart';

/// Returns the id of the **first** progression node that lists
/// [cosmeticId] as a `CosmeticReward` in its reward table (typically
/// an Achievement, but Quest / Milestone / LevelMilestone reward
/// tables are searched too for completeness). Returns `null` when no
/// catalog node grants this cosmetic — e.g. companion cosmetics
/// (claimed via a `CompanionAvailability` node whose reward kind is
/// `companionAvailability`, not `cosmetic`) or content that ships
/// pre-unlocked.
///
/// Used by the devtools cosmetic-details sheet to route relic grants
/// through `progression.devToolsForceCompleteNode(achievement_id)`
/// instead of the direct `cosmetics.debugGrantCosmetic(relic_id)`
/// shortcut. The engine-routed path writes the achievement's
/// `NodeCompletionEvent` + `RewardGrantEvent(cosmetic)` series the
/// bridge consumes to flip the cosmetic in inventory — keeping the
/// engine ledger and the cosmetics inventory aligned. The direct
/// shortcut leaves them divergent, which surfaces as the
/// "3/3 conditions met but no claim CTA" bug filed as Trello #76
/// sub-issue 1.
String? grantingNodeForCosmetic(
  String cosmeticId, {
  ProgressionEntryCatalog catalog = const ProgressionEntryCatalog(),
}) {
  for (final node in catalog.build()) {
    for (final reward in node.rewards) {
      if (reward is! CosmeticReward) continue;
      if (reward.cosmeticId == cosmeticId) return node.id;
    }
  }
  return null;
}
