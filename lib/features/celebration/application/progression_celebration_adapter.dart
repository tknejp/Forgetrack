import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/domain/policy/level_config.dart';
import '../domain/models/celebration_event.dart';
import '../domain/models/celebration_reward.dart';

/// Pure transformer from a [ProgressionCelebrationEvent] into a
/// [CelebrationEvent].
///
/// **Single source of truth.** Rarity, cosmetic ids, and pairing are read
/// directly off the catalog runtime objects (`tier.rarity`,
/// `quest.rarity`, `quest.cosmeticRewards`, `achievement.rarity`,
/// `achievement.cosmeticRewards`). The adapter does *no* derivation —
/// adding a new quest with a cosmetic drop or a new achievement with a
/// custom rarity is one catalog edit. The celebration UI follows.
class ProgressionCelebrationAdapter {
  const ProgressionCelebrationAdapter({
    required this.cosmetics,
    required this.claim,
  });

  final CosmeticsProvider cosmetics;

  /// Idempotent claim callback wired to
  /// `ProgressionProvider.claimQuestReward`.
  final Future<void> Function(String rewardKey) claim;

  CelebrationEvent convert(ProgressionCelebrationEvent event) {
    switch (event.kind) {
      case ProgressionCelebrationKind.levelMilestone:
        return _convertLevelMilestone(event);
      case ProgressionCelebrationKind.achievementUnlocked:
        // An achievement event that also carries a quest grant means the
        // queueing layer detected a paired quest+achievement (shared
        // criterion, e.g. "1M steps" both as quest and achievement). One
        // celebration replaces the cascade of two.
        if (event.questGrant != null) {
          return _convertCombinedAchievementQuest(event);
        }
        return _convertAchievementUnlocked(event);
      case ProgressionCelebrationKind.cosmeticUnlocked:
        return _convertCosmeticUnlocked(event);
      case ProgressionCelebrationKind.questCompleted:
        return _convertQuestCompleted(event);
    }
  }

  CelebrationEvent _convertLevelMilestone(ProgressionCelebrationEvent event) {
    final level = event.level ?? 1;
    final tier = tierForLevel(level);
    final hasTitle = levelHasTitleBreakpoint(level);
    final cosmeticRewards = _cosmeticsToRewards(event.cosmeticIds);

    final rewards = <CelebrationReward>[];
    if (hasTitle) {
      // The unlocked title itself is a "showcase" reward — synthesise a
      // CelebrationReward of kind `title` so the fullscreen card stack has
      // something tangible to display alongside the cosmetic frame.
      rewards.add(CelebrationReward(
        id: 'level-title-$level',
        name: tier.title,
        sub: (l) => l.celebrationLevelRewardName(level),
        rarity: tier.rarity,
        kind: CelebrationRewardKind.title,
      ));
    }
    rewards.addAll(cosmeticRewards);

    final headRarity = rewards.isEmpty
        ? tier.rarity
        : CelebrationEvent.maxRarityFrom(rewards);

    return CelebrationEvent(
      id: event.id,
      type: hasTitle ? CelebrationType.title : CelebrationType.level,
      eyebrow: (l) =>
          hasTitle ? l.celebrationTitleEyebrow : l.celebrationLevelEyebrow,
      title: (l) =>
          hasTitle ? l.celebrationLevelTitle(level, tier.title(l))
                   : l.celebrationLevelTitleNoTitle(level),
      rewards: rewards,
      headRarity: headRarity,
    );
  }

  CelebrationEvent _convertAchievementUnlocked(
      ProgressionCelebrationEvent event) {
    final achievement = event.achievement;
    final cosmeticRewards = _cosmeticsToRewards(event.cosmeticIds);

    // Head rarity is the max of the achievement's own rarity and the
    // attached cosmetics — so a Common achievement with a Legendary frame
    // attached still tints the celebration legendary.
    final achievementRarity = achievement?.rarity ?? Rarity.common;
    final headRarity = cosmeticRewards.isEmpty
        ? achievementRarity
        : Rarity.max(
            CelebrationEvent.maxRarityFrom(cosmeticRewards),
            achievementRarity,
          );

    return CelebrationEvent(
      id: event.id,
      type: CelebrationType.achievement,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) =>
          achievement?.title(l) ?? l.celebrationAchievementEyebrow,
      description:
          achievement == null ? null : (l) => achievement.description(l),
      rewards: cosmeticRewards,
      headRarity: headRarity,
    );
  }

  /// Combined celebration for a quest grant whose `quest.achievementId`
  /// points at a freshly unlocked achievement.
  CelebrationEvent _convertCombinedAchievementQuest(
      ProgressionCelebrationEvent event) {
    final achievement = event.achievement;
    final grant = event.questGrant!;
    final quest = event.quest;
    final cosmeticRewards = _cosmeticsToRewards(event.cosmeticIds);

    final pairRarity = Rarity.max(
      achievement?.rarity ?? Rarity.common,
      quest?.rarity ?? Rarity.common,
    );
    final headRarity = cosmeticRewards.isEmpty
        ? pairRarity
        : Rarity.max(
            CelebrationEvent.maxRarityFrom(cosmeticRewards),
            pairRarity,
          );

    return CelebrationEvent(
      id: event.id,
      type: CelebrationType.achievement,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) =>
          achievement?.title(l) ?? quest?.title(l) ??
              l.celebrationAchievementEyebrow,
      description: achievement != null
          ? (l) => achievement.description(l)
          : (quest != null ? (l) => quest.description(l) : null),
      rewards: cosmeticRewards,
      headRarity: headRarity,
      claim: CelebrationClaim(
        rewardKey: grant.rewardKey,
        xpAmount: grant.xpGranted,
        onClaim: claim,
      ),
    );
  }

  CelebrationEvent _convertCosmeticUnlocked(
      ProgressionCelebrationEvent event) {
    final cosmeticDefs = _resolveCosmetics(event.cosmeticIds);
    final cosmeticRewards = _cosmeticsToRewards(event.cosmeticIds);
    final headRarity = cosmeticRewards.isEmpty
        ? Rarity.common
        : CelebrationEvent.maxRarityFrom(cosmeticRewards);
    final firstName =
        cosmeticDefs.isEmpty ? null : cosmeticDefs.first.name;

    return CelebrationEvent(
      id: event.id,
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationCosmeticUnlockedEyebrow,
      title: firstName ?? ((l) => l.celebrationCosmeticUnlockedEyebrow),
      rewards: cosmeticRewards,
      headRarity: headRarity,
    );
  }

  CelebrationEvent _convertQuestCompleted(
      ProgressionCelebrationEvent event) {
    final grant = event.questGrant!;
    final quest = event.quest;

    // Quest XP is the *claim*, not a visual reward — keeping it out of the
    // rewards list lets the variant router send a daily-quest topsheet to
    // the right surface (small claim pill, not a fullscreen card stack).
    return CelebrationEvent(
      id: event.id,
      type: CelebrationType.quest,
      eyebrow: (l) => l.celebrationQuestEyebrow,
      title: (l) => quest?.title(l) ?? l.celebrationQuestEyebrow,
      description: quest == null ? null : (l) => quest.description(l),
      rewards: const [],
      headRarity: quest?.rarity ?? Rarity.common,
      claim: CelebrationClaim(
        rewardKey: grant.rewardKey,
        xpAmount: grant.xpGranted,
        onClaim: claim,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  List<CosmeticDefinition> _resolveCosmetics(List<String> ids) {
    final catalog = cosmetics.service.catalog;
    return ids
        .map(catalog.byId)
        .whereType<CosmeticDefinition>()
        .toList(growable: false);
  }

  List<CelebrationReward> _cosmeticsToRewards(List<String> ids) {
    final defs = _resolveCosmetics(ids);
    return [
      for (final def in defs)
        CelebrationReward(
          id: 'cosmetic-${def.id}',
          name: def.name,
          sub: (l) => def.rarity.label(l),
          rarity: def.rarity,
          kind: _kindForCosmeticType(def.type),
          assetPath: cosmetics.service.config.resolveAssetPath(
            def.previewAssetKey ?? def.assetKey,
          ),
        ),
    ];
  }

  CelebrationRewardKind _kindForCosmeticType(CosmeticType type) {
    switch (type) {
      case CosmeticType.frame:
        return CelebrationRewardKind.frame;
      case CosmeticType.background:
        return CelebrationRewardKind.background;
      case CosmeticType.companion:
        return CelebrationRewardKind.companion;
      case CosmeticType.titleFlair:
        return CelebrationRewardKind.title;
      case CosmeticType.emblem:
        return CelebrationRewardKind.badge;
      case CosmeticType.relic:
        return CelebrationRewardKind.gem;
      case CosmeticType.mapEffect:
        return CelebrationRewardKind.location;
    }
  }
}
