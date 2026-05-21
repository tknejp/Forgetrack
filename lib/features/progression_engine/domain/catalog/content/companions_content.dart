import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';

/// Companion availability nodes — chapter-themed companion unlock chains.
/// Each companion is gated on a player level + ownership of the themed
/// relics from its catalog row.
///
/// Unlock condition shape: `[LevelAtLeast(levelGate), OwnsCosmetic(item) …]`
/// where `levelGate` and the item list come from the catalog [Companion]
/// row. Relics themselves are `CosmeticReward`s on achievement nodes; the
/// engine reads the cosmetics inventory's `unlocked` map (via
/// `EngineEvaluationContext.ownedCosmeticIds`) so the gate evaluates the
/// same way the reveal evaluator does. The previous condition shape used
/// `NodeCompleted(<granting_achievement>)` which is equivalent in normal
/// production flow but diverged whenever the cosmetics inventory got
/// mutated through a side channel (devtools `debugGrantCosmetic`,
/// "Unlock all cosmetics", a partial cloud-pull merge) — see ADR
/// `companion-availability-owns-cosmetic`.
///
/// All nodes use `ClaimPolicy.manual` (inherited from
/// CompanionAvailability). The celebration adapter folds the reveal into
/// the achievement event that granted the final relic via the
/// companion-availability fold pass. When un-folded (e.g. the player
/// crosses the level threshold long after both relics completed), the
/// companion gets a standalone fullscreen reveal pointing to the
/// inventory.
///
/// Derived directly from [CosmeticCatalog] — the catalog is the single
/// source of truth for which companions exist, their level + item gate,
/// rarity, and display text. This file contributes only the engine-side
/// shape (`CompanionAvailability` constructor with `lockedHintKey` derived
/// from the level gate). The `titleKey` / `descriptionKey` closures are
/// the same ones the catalog row exposes — engine UI and inventory UI
/// resolve to the same generated `AppLocalizations` getters by
/// construction. Dev-only companions (those with `levelGate == null`,
/// today only Monster Energy) are skipped by the filter — they are not
/// surfaced through the progression pipeline.
List<ProgressionEntry> companionNodes() {
  return CosmeticCatalog()
      .companions
      .where((c) => c.levelGate != null)
      .map(_toCompanionAvailabilityNode)
      .toList(growable: false);
}

CompanionAvailability _toCompanionAvailabilityNode(Companion companion) {
  final levelGate = companion.levelGate!;
  return CompanionAvailability(
    id: ProgressionEntryId(companion.id.value),
    companionId: companion.id,
    titleKey: companion.name,
    descriptionKey: companion.description,
    rewards: [
      CompanionAvailabilityReward(companionId: companion.id),
    ],
    unlockConditions: [
      LevelAtLeast(levelGate),
      for (final item in companion.requiredItems) OwnsCosmetic(item),
    ],
    lockedHintKey: (l) => l.cosmeticCompanionLevelGate(levelGate),
    rarity: companion.rarity,
  );
}
