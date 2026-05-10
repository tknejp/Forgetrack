import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import '../../progression_engine/domain/models/ledger_event.dart';
import '../../progression_engine/domain/models/progression_node_definition.dart';
import '../../progression_engine/domain/models/progression_resolution_reason.dart';
import '../../progression_engine/domain/models/progression_resolution_result.dart';
import '../domain/models/celebration_event.dart';
import '../domain/models/celebration_reward.dart';

/// Pure transformer from a [ProgressionResolutionResult] to a list of
/// [CelebrationEvent]s the celebration overlay host can render.
///
/// Replaces (eventually) the legacy [ProgressionCelebrationAdapter]
/// which converted one `ProgressionCelebrationEvent` at a time. The
/// V2 adapter is batched: it sees the whole resolution result and
/// can decide to compress dozens of grants into a single welcome
/// sequence when `reason == factoryResetSeed`/`historicalResync`.
///
/// The adapter is pure — same input, same output, no diffing. Diff
/// already happened inside the engine; this layer is purely a view
/// mapping.
class ProgressionEngineCelebrationAdapter {
  const ProgressionEngineCelebrationAdapter({
    required this.cosmetics,
    required this.claim,
    this.nodeCatalog = const ProgressionNodeCatalog(),
  });

  final CosmeticsProvider cosmetics;
  final ProgressionNodeCatalog nodeCatalog;

  /// Idempotent claim callback wired to the V2 engine's `claim`
  /// entry point. Called when the player taps "Vyzvednout" on a
  /// manual-claim node tile.
  final Future<void> Function(String nodeId) claim;

  /// Convert one resolution result into a list of celebrations.
  /// Order matches the spec in the plan (level → milestone → chapter
  /// → quest → achievement → reward → companion).
  List<CelebrationEvent> convert(ProgressionResolutionResult result) {
    if (result.isEmpty) return const [];

    // Bulk reasons collapse into a single summary so the player is
    // not buried under N popups after a factory reset or historical
    // resync. Phase 5 ships a stub summary; real per-reason copy
    // can be polished post-Phase 6.
    if (result.reason == ProgressionResolutionReason.factoryResetSeed ||
        result.reason == ProgressionResolutionReason.historicalResync) {
      return [_buildSummaryEvent(result)];
    }

    final events = <CelebrationEvent>[];
    final consumedNodeIds = <String>{};

    // Resolve each completed node to its catalog entry once so the
    // sort can read kind / rarity directly off the node.
    final completionsWithNode = <_NodeCompletionPair>[];
    for (final c in result.completedNodes) {
      final node = ProgressionNodeCatalog.definitionForId(c.nodeId);
      if (node == null) continue;
      completionsWithNode.add(_NodeCompletionPair(c, node));
    }

    // Stable display order — see plan §8.3.
    completionsWithNode.sort(_sortByCelebrationPriority);

    for (final pair in completionsWithNode) {
      final event = _convertCompletion(pair.completion, pair.node, result);
      if (event != null) {
        events.add(event);
        consumedNodeIds.add(pair.node.id);
      }
    }

    // Manual-claim availability — surface as a quest-style claim
    // celebration so the player notices the new "Vyzvednout" pill.
    for (final availability in result.availableNodes) {
      final node = ProgressionNodeCatalog.definitionForId(availability.nodeId);
      if (node == null) continue;
      final event = _convertAvailability(node);
      if (event != null) events.add(event);
    }

    // Orphan cosmetic grants — reward events for nodes that did
    // not produce their own celebration (e.g. cosmetic side-grants
    // from compound chains). Today this is rare; kept for safety.
    final orphanCosmeticIds = <String>[];
    for (final grant in result.grantedRewards) {
      if (grant.event.rewardKind != RewardGrantKind.cosmetic) continue;
      if (consumedNodeIds.contains(grant.event.nodeId)) continue;
      final id = grant.event.cosmeticId;
      if (id != null) orphanCosmeticIds.add(id);
    }
    if (orphanCosmeticIds.isNotEmpty) {
      events.add(_buildOrphanCosmeticEvent(orphanCosmeticIds));
    }

    return events;
  }

  // ── Per-node conversion ────────────────────────────────────────

  CelebrationEvent? _convertCompletion(
    NodeCompletion completion,
    ProgressionNode node,
    ProgressionResolutionResult result,
  ) {
    return switch (node) {
      LevelMilestoneNode() =>
        _buildLevelEvent(completion, node, result),
      AchievementNode() =>
        _buildAchievementEvent(completion, node, result),
      MilestoneNode() =>
        _buildMilestoneEvent(completion, node, result),
      ChapterCompletionNode() =>
        _buildChapterCompletionEvent(completion, node, result),
      QuestNode() => _buildQuestEvent(completion, node, result),
      RelicNode() => _buildRelicEvent(completion, node, result),
      ContentUnlockNode() => _buildContentUnlockEvent(completion, node),
      CompanionAvailabilityNode() => null, // surfaces via availability path
    };
  }

  CelebrationEvent _buildLevelEvent(
    NodeCompletion completion,
    LevelMilestoneNode node,
    ProgressionResolutionResult result,
  ) {
    final cosmeticIds = _cosmeticIdsForNode(completion.nodeId, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final headRarity = rewards.isEmpty
        ? node.rarity
        : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards));
    return CelebrationEvent(
      id: 'level|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: node.isTitleBreakpoint
          ? CelebrationType.title
          : CelebrationType.level,
      eyebrow: (l) => node.isTitleBreakpoint
          ? l.celebrationTitleEyebrow
          : l.celebrationLevelEyebrow,
      title: node.isTitleBreakpoint
          ? (l) => l.celebrationLevelTitle(node.level, node.titleKey(l))
          : (l) => l.celebrationLevelTitleNoTitle(node.level),
      rewards: rewards,
      headRarity: headRarity,
    );
  }

  CelebrationEvent _buildAchievementEvent(
    NodeCompletion completion,
    AchievementNode node,
    ProgressionResolutionResult result,
  ) {
    final cosmeticIds = _cosmeticIdsForNode(completion.nodeId, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final headRarity = rewards.isEmpty
        ? node.rarity
        : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards));
    return CelebrationEvent(
      id: 'achievement|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.achievement,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
    );
  }

  CelebrationEvent _buildMilestoneEvent(
    NodeCompletion completion,
    MilestoneNode node,
    ProgressionResolutionResult result,
  ) {
    final cosmeticIds = _cosmeticIdsForNode(completion.nodeId, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    return CelebrationEvent(
      id: 'milestone|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: rewards.isEmpty
          ? node.rarity
          : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards)),
    );
  }

  CelebrationEvent _buildChapterCompletionEvent(
    NodeCompletion completion,
    ChapterCompletionNode node,
    ProgressionResolutionResult result,
  ) {
    final cosmeticIds = _cosmeticIdsForNode(completion.nodeId, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    return CelebrationEvent(
      id: 'chapter|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: rewards.isEmpty
          ? node.rarity
          : CelebrationEvent.maxRarityFrom(rewards),
    );
  }

  CelebrationEvent _buildQuestEvent(
    NodeCompletion completion,
    QuestNode node,
    ProgressionResolutionResult result,
  ) {
    final xpAmount = _xpAmountForNode(node.id, result);
    return CelebrationEvent(
      id: 'quest|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.quest,
      eyebrow: (l) => l.celebrationQuestEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: const [],
      headRarity: node.rarity,
      claim: xpAmount == null
          ? null
          : CelebrationClaim(
              rewardKey: node.id,
              xpAmount: xpAmount,
              onClaim: (_) async {
                // Quest rewards in V2 are auto-granted by the engine
                // — the celebration claim is a UX hook for the
                // animation only. The XP is already in the ledger.
              },
            ),
    );
  }

  CelebrationEvent _buildRelicEvent(
    NodeCompletion completion,
    RelicNode node,
    ProgressionResolutionResult result,
  ) {
    return CelebrationEvent(
      id: 'relic|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationCosmeticUnlockedEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: const [],
      headRarity: node.rarity,
    );
  }

  CelebrationEvent _buildContentUnlockEvent(
    NodeCompletion completion,
    ContentUnlockNode node,
  ) {
    return CelebrationEvent(
      id: 'content|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: const [],
      headRarity: node.rarity,
    );
  }

  // ── Manual-claim availability ─────────────────────────────────

  CelebrationEvent? _convertAvailability(ProgressionNode node) {
    if (node is CompanionAvailabilityNode) {
      return CelebrationEvent(
        id: 'companion-available|${node.id}',
        type: CelebrationType.cosmetic,
        eyebrow: (l) => l.celebrationCosmeticUnlockedEyebrow,
        title: (l) => node.titleKey(l),
        description: (l) => node.descriptionKey(l),
        rewards: const [],
        headRarity: node.rarity,
        claim: CelebrationClaim(
          rewardKey: node.id,
          xpAmount: 0,
          onClaim: claim,
        ),
      );
    }
    return null;
  }

  // ── Orphan cosmetics + bulk summary ───────────────────────────

  CelebrationEvent _buildOrphanCosmeticEvent(List<String> cosmeticIds) {
    final rewards = _cosmeticsToRewards(cosmeticIds);
    return CelebrationEvent(
      id: 'cosmetic|${cosmeticIds.join(',')}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationCosmeticUnlockedEyebrow,
      title: rewards.isNotEmpty ? rewards.first.name : ((l) => l.celebrationCosmeticUnlockedEyebrow),
      rewards: rewards,
      headRarity: rewards.isEmpty
          ? Rarity.common
          : CelebrationEvent.maxRarityFrom(rewards),
    );
  }

  CelebrationEvent _buildSummaryEvent(ProgressionResolutionResult result) {
    // Collect every cosmetic id from grant events for the summary
    // card stack, plus the highest rarity for the head accent.
    final cosmeticIds = <String>[];
    for (final g in result.grantedRewards) {
      if (g.event.rewardKind == RewardGrantKind.cosmetic) {
        final id = g.event.cosmeticId;
        if (id != null) cosmeticIds.add(id);
      }
    }
    final rewards = _cosmeticsToRewards(cosmeticIds);
    return CelebrationEvent(
      id: 'summary|${result.runId}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationCosmeticUnlockedEyebrow,
      title: (l) => l.celebrationAchievementEyebrow,
      rewards: rewards,
      headRarity: rewards.isEmpty
          ? Rarity.common
          : CelebrationEvent.maxRarityFrom(rewards),
      variantOverride: CelebrationVariant.fullscreen,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  List<String> _cosmeticIdsForNode(
    String nodeId,
    ProgressionResolutionResult result,
  ) {
    final out = <String>[];
    for (final g in result.grantedRewards) {
      if (g.event.nodeId != nodeId) continue;
      if (g.event.rewardKind != RewardGrantKind.cosmetic) continue;
      final id = g.event.cosmeticId;
      if (id != null) out.add(id);
    }
    return out;
  }

  int? _xpAmountForNode(String nodeId, ProgressionResolutionResult result) {
    for (final g in result.grantedRewards) {
      if (g.event.nodeId != nodeId) continue;
      if (g.event.rewardKind != RewardGrantKind.xp) continue;
      return g.event.xpAmount;
    }
    return null;
  }

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

  // Sort: level → milestone → chapter → quest → achievement →
  // relic → content unlock. Matches plan §8.3 ordering.
  int _sortByCelebrationPriority(_NodeCompletionPair a, _NodeCompletionPair b) {
    return _priority(a.node).compareTo(_priority(b.node));
  }

  int _priority(ProgressionNode node) {
    return switch (node) {
      LevelMilestoneNode() => 0,
      MilestoneNode() => 1,
      ChapterCompletionNode() => 2,
      QuestNode() => 3,
      AchievementNode() => 4,
      RelicNode() => 5,
      CompanionAvailabilityNode() => 6,
      ContentUnlockNode() => 7,
    };
  }
}

class _NodeCompletionPair {
  const _NodeCompletionPair(this.completion, this.node);
  final NodeCompletion completion;
  final ProgressionNode node;
}
