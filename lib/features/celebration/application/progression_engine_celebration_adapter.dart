import 'package:flutter/material.dart';

import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../progression_engine/domain/catalog/content/quest_assets.dart';
import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import '../../progression_engine/domain/models/progression_resolution_reason.dart';
import '../../progression_engine/domain/models/progression_resolution_result.dart';
import 'package:forgetrack/domain/progression/catalog/quest_policies.dart';
import 'package:forgetrack/domain/progression/catalog/unlock_condition.dart';
import '../domain/models/celebration_event.dart';
import '../domain/models/celebration_reward.dart';

/// Pure transformer from a [ProgressionResolutionResult] to a list of
/// [CelebrationEvent]s the celebration overlay host can render.
///
/// Grouping rules (post-Phase 9c refactor):
///
/// 1. Bulk reasons (factoryResetSeed / historicalResync) collapse into a
///    single "welcome back" summary so the player is not buried under N
///    popups.
/// 2. Level milestones always render solo â€” they are the moment.
/// 3. Chapter completions bundle the immediately-unlocked next chapter
///    (when present in the same result) into one celebration.
/// 4. Quest + achievement + milestone nodes sharing an `objectiveId` are
///    merged into a single "goal complete" celebration so the player sees
///    "10M steps Â· achievement VzestupnÃ½ Â· 1 reward" in one card stack
///    instead of three popups.
/// 5. Achievement / relic / content-unlock nodes that don't fit any
///    bucket render solo.
/// 6. Manual-claim availability nodes (companion ready) emit a tappable
///    "Summon companion" celebration.
/// 7. Any cosmetic grant that didn't piggyback on a node celebration
///    surfaces as an orphan "reward from your progress" event.
///
/// The adapter is pure â€” same input, same output, no diffing. Diff
/// already happened inside the engine; this layer is purely a view
/// mapping.
class ProgressionEngineCelebrationAdapter {
  const ProgressionEngineCelebrationAdapter({
    required this.cosmetics,
    this.nodeCatalog = const ProgressionEntryCatalog(),
  });

  final CosmeticsProvider cosmetics;
  final ProgressionEntryCatalog nodeCatalog;

  List<CelebrationEvent> convert(ProgressionResolutionResult result) {
    if (result.isEmpty) return const [];

    if (result.reason == ProgressionResolutionReason.factoryResetSeed ||
        result.reason == ProgressionResolutionReason.historicalResync) {
      return [_buildWelcomeBackEvent(result)];
    }

    final completions = <_NodeCompletionPair>[];
    for (final c in result.completedNodes) {
      final node = ProgressionEntryCatalog.definitionForId(c.nodeId);
      if (node == null) continue;
      completions.add(_NodeCompletionPair(c, node));
    }

    // â”€â”€ Fold pre-pass â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    //
    // The catalog frequently authors a relic + a companion + a level
    // milestone gated on the same `LevelAtLeast(N)`. Without folding
    // they fire as three separate overlays, two of which share a
    // placeholder title (e.g. "VÃ­tej na cestÄ›"). Fold them into the
    // level milestone celebration so the player sees one cohesive
    // moment: "Level N Â· here are the things you just unlocked."
    final levelHostByLevel = <int, _NodeCompletionPair>{};
    for (final p in completions) {
      if (p.node is LevelMilestone) {
        levelHostByLevel[(p.node as LevelMilestone).level] = p;
      }
    }
    final completionByNodeId = {
      for (final p in completions) p.node.id: p,
    };

    final extras = <String, List<CelebrationReward>>{};
    final foldedNodeIds = <String>{};
    final foldedAvailabilityIds = <String>{};
    final forceFullscreen = <String>{};

    // Fold gateless relics into their matching level milestone.
    for (final p in completions) {
      final node = p.node;
      if (node is! Relic) continue;
      final host = _hostFromLevelOnly(
        node.unlockConditions,
        levelHostByLevel,
      );
      if (host == null) continue;
      final card = _relicPreviewCard(node);
      (extras[host.node.id] ??= []).add(card);
      forceFullscreen.add(host.node.id);
      foldedNodeIds.add(node.id);
    }

    // Fold companion availability into its gating completion (preferred)
    // or matching level milestone (fallback). Reads `newlyAvailableNodes`
    // (engine delta backed by NodeAnnouncedEvent in the ledger) so
    // the fold fires the first time the companion surfaces and
    // never again â€” including across app restarts.
    for (final availability in result.newlyAvailableNodes) {
      final node = ProgressionEntryCatalog.definitionForId(availability.nodeId);
      if (node is! CompanionAvailability) continue;
      final completedHost = _findNodeCompletedHost(
        node.unlockConditions,
        completionByNodeId,
      );
      final host = completedHost ??
          _hostFromLevelOnly(node.unlockConditions, levelHostByLevel);
      if (host == null) continue;
      final card = _companionPreviewCard(node);
      (extras[host.node.id] ??= []).add(card);
      forceFullscreen.add(host.node.id);
      foldedAvailabilityIds.add(node.id);
    }

    final events = <CelebrationEvent>[];
    final consumed = <String>{};

    // 1. Level milestones â€” always solo, always first.
    for (final pair in completions) {
      if (pair.node is! LevelMilestone) continue;
      events.add(_withExtras(
        _buildLevelEvent(pair, result),
        pair.node.id,
        extras,
        forceFullscreen,
      ));
      consumed.add(pair.node.id);
    }

    // 2. Chapter completion + bundled next-chapter unlock.
    final contentUnlocks = completions
        .where((p) => p.node is ContentUnlock)
        .toList(growable: false);
    final bundledUnlockIds = <String>{};
    for (final pair in completions) {
      if (pair.node is! ChapterCompletion) continue;
      final ev = _buildChapterEvent(
        pair,
        contentUnlocks,
        result,
        bundledUnlockIds,
      );
      if (ev != null) {
        events.add(_withExtras(ev, pair.node.id, extras, forceFullscreen));
        consumed.add(pair.node.id);
      }
    }
    consumed.addAll(bundledUnlockIds);

    // 3. Goal completions â€” bundle by objectiveId.
    final byObjective = <String, List<_NodeCompletionPair>>{};
    final unbound = <_NodeCompletionPair>[];
    for (final pair in completions) {
      if (consumed.contains(pair.node.id)) continue;
      if (foldedNodeIds.contains(pair.node.id)) continue;
      final oid = _objectiveIdOf(pair.node);
      if (oid != null) {
        (byObjective[oid] ??= []).add(pair);
      } else {
        unbound.add(pair);
      }
    }
    for (final bucket in byObjective.values) {
      final ev = _buildGoalEvent(bucket, result);
      if (ev != null) {
        // Extras can land on any node in the bucket â€” usually they
        // hit the face (first by quest > achievement > milestone),
        // but be defensive and merge across all bucket members.
        var merged = ev;
        for (final p in bucket) {
          merged = _withExtras(merged, p.node.id, extras, forceFullscreen);
        }
        events.add(merged);
        for (final p in bucket) {
          consumed.add(p.node.id);
        }
      }
    }

    // 4. Unbound completions (achievement-with-no-objective, relic) and
    //    any content-unlock not consumed by a chapter event.
    for (final pair in unbound) {
      if (consumed.contains(pair.node.id)) continue;
      final ev = _buildSoloEvent(pair, result);
      if (ev != null) {
        events.add(_withExtras(ev, pair.node.id, extras, forceFullscreen));
        consumed.add(pair.node.id);
      }
    }
    for (final pair in contentUnlocks) {
      if (consumed.contains(pair.node.id)) continue;
      events.add(_withExtras(
        _buildContentUnlockEvent(pair, result),
        pair.node.id,
        extras,
        forceFullscreen,
      ));
      consumed.add(pair.node.id);
    }

    // 5. Un-folded companion availabilities â€” emit as their own
    //    fullscreen celebration with the companion as a single reward
    //    card. The fullscreen's secondary CTA ("OtevÅ™Ã­t inventÃ¡Å™ â†’")
    //    is how the player actually unlocks the companion; there is
    //    no inline claim button.
    //
    //    Like the fold pass above, this reads `newlyAvailableNodes`
    //    so the standalone overlay fires exactly once per companion
    //    over the player's lifetime, with the persisted ledger
    //    marker tracking it across app restarts.
    for (final availability in result.newlyAvailableNodes) {
      if (foldedAvailabilityIds.contains(availability.nodeId)) continue;
      final node = ProgressionEntryCatalog.definitionForId(availability.nodeId);
      if (node is! CompanionAvailability) continue;
      events.add(_buildStandaloneCompanionEvent(node));
    }

    // 6. Orphan cosmetic grants.
    final orphanIds = <String>[];
    for (final g in result.grantedRewards) {
      if (g.event.rewardKind != RewardGrantKind.cosmetic) continue;
      if (consumed.contains(g.event.nodeId)) continue;
      final id = g.event.cosmeticId;
      if (id != null) orphanIds.add(id);
    }
    if (orphanIds.isNotEmpty) {
      events.add(_buildOrphanCosmeticEvent(orphanIds));
    }

    // â”€â”€ Final pass: bundle solo achievements into a moment pack â”€â”€
    //
    // When â‰¥2 plain `CelebrationType.achievement` events remain after
    // all earlier fold passes â€” typical case: welcome flow fires
    // `welcome_to_journey` + `first_reward` together â€” fan them into
    // a single fullscreen card stack so the player sees one cohesive
    // "moment" instead of N popups in a row. Levels, chapters,
    // goal-bucket merges, and companion-folded events stay distinct.
    return _bundleSoloAchievementsIfMany(events);
  }

  /// If at least two `CelebrationType.achievement` events exist in
  /// the list and none has an explicit `variantOverride`, replace
  /// them with a single bundled "achievement pack" event. The pack
  /// gathers every reward across the bundle and inherits the max
  /// rarity, forcing the fullscreen variant.
  List<CelebrationEvent> _bundleSoloAchievementsIfMany(
    List<CelebrationEvent> input,
  ) {
    final achievements = <CelebrationEvent>[];
    final others = <CelebrationEvent>[];
    for (final ev in input) {
      if (ev.type == CelebrationType.achievement &&
          ev.variantOverride == null) {
        achievements.add(ev);
      } else {
        others.add(ev);
      }
    }
    if (achievements.length < 2) return input;

    final mergedRewards = <CelebrationReward>[
      for (final ev in achievements) ...ev.rewards,
    ];
    var headRarity = achievements.first.headRarity;
    for (final ev in achievements) {
      headRarity = Rarity.max(headRarity, ev.headRarity);
    }
    if (mergedRewards.isNotEmpty) {
      headRarity = Rarity.max(
        headRarity,
        CelebrationEvent.maxRarityFrom(mergedRewards),
      );
    }

    // Sum XP from any source achievement events that carried one
    // (rare today â€” achievements granting XP directly â€” but defensive).
    var xpTotal = 0;
    for (final ev in achievements) {
      final award = ev.xpAward;
      if (award != null) xpTotal += award.amount;
    }

    final count = achievements.length;
    final firstId = achievements.first.id;
    final pack = CelebrationEvent(
      id: 'achievement-pack|$firstId|$count',
      type: CelebrationType.achievement,
      eyebrow: (l) => l.celebrationAchievementPackEyebrow,
      title: (l) => l.celebrationAchievementPackTitle(count),
      description: (l) {
        // Chain the bundled titles into one line so the player
        // recognises which moments collapsed together.
        return achievements
            .map((ev) => ev.title(l))
            .where((s) => s.isNotEmpty)
            .join(' Â· ');
      },
      rewards: mergedRewards,
      headRarity: headRarity,
      xpAward: xpTotal > 0 ? CelebrationXpAward(xpTotal) : null,
      variantOverride: CelebrationVariant.fullscreen,
    );

    return [...others, pack];
  }

  /// Re-emit `base` with any extras-card additions merged in. Recomputes
  /// `headRarity` and force-upgrades to fullscreen so the new card lands
  /// in the stack rather than getting summarised in a topsheet strip.
  CelebrationEvent _withExtras(
    CelebrationEvent base,
    String hostNodeId,
    Map<String, List<CelebrationReward>> extras,
    Set<String> forceFullscreen,
  ) {
    final extra = extras[hostNodeId];
    if (extra == null || extra.isEmpty) return base;
    final merged = [...base.rewards, ...extra];
    final newRarity = Rarity.max(
      base.headRarity,
      CelebrationEvent.maxRarityFrom(merged),
    );
    return CelebrationEvent(
      id: base.id,
      type: base.type,
      eyebrow: base.eyebrow,
      title: base.title,
      description: base.description,
      rewards: merged,
      headRarity: newRarity,
      xpAward: base.xpAward,
      variantOverride: forceFullscreen.contains(hostNodeId)
          ? CelebrationVariant.fullscreen
          : base.variantOverride,
    );
  }

  /// Returns the [LevelMilestone] completion that gates `conds`,
  /// but only when the conditions are *exactly* one or more
  /// [LevelAtLeast] entries. Any other condition kind disqualifies the
  /// fold â€” we don't want to assume a node belongs to the level
  /// milestone if it also has a [NodeCompleted] or RPG gate.
  _NodeCompletionPair? _hostFromLevelOnly(
    List<UnlockCondition> conds,
    Map<int, _NodeCompletionPair> levelHostByLevel,
  ) {
    if (conds.isEmpty) return null;
    int? requiredLevel;
    for (final c in conds) {
      if (c is LevelAtLeast) {
        requiredLevel = c.level;
      } else {
        return null;
      }
    }
    if (requiredLevel == null) return null;
    return levelHostByLevel[requiredLevel];
  }

  _NodeCompletionPair? _findNodeCompletedHost(
    List<UnlockCondition> conds,
    Map<String, _NodeCompletionPair> completionByNodeId,
  ) {
    for (final c in conds) {
      if (c is NodeCompleted) {
        final p = completionByNodeId[c.nodeId];
        if (p != null) return p;
      }
    }
    return null;
  }

  /// Reward card for a not-yet-claimed companion. We intentionally hide
  /// the companion's real name + art on the celebration surface â€” the
  /// claim flow inside the inventory's details sheet is what actually
  /// reveals the companion (with its forging animation). Until then the
  /// card reads as a generic "mysterious companion" preview so the
  /// reveal moment lands in one place, not split between celebration
  /// and claim.
  CelebrationReward _companionPreviewCard(CompanionAvailability node) {
    return CelebrationReward(
      id: 'companion-${node.companionId}',
      name: (l) => l.cosmeticCompanionClaimableHiddenName,
      sub: (l) => node.rarity.label(l),
      rarity: node.rarity,
      kind: CelebrationRewardKind.companion,
      assetPath: null,
      fallbackIcon: Icons.lock_rounded,
    );
  }

  /// Header reward card for a chapter â€” uses `chapterIconAssetFor`
  /// from the catalog so the celebration ties visually to the chapter
  /// art the player already saw on the chapter card. Rendered as a
  /// `location` kind so the celebration UI uses the map glyph as a
  /// fallback when the asset path doesn't resolve.
  CelebrationReward _chapterIconCard({
    required String chapterId,
    required CelebrationText nameKey,
    required Rarity rarity,
  }) {
    final asset = chapterIconAssetFor(chapterId);
    return CelebrationReward(
      id: 'chapter-icon-$chapterId',
      name: nameKey,
      sub: (l) => rarity.label(l),
      rarity: rarity,
      kind: CelebrationRewardKind.location,
      assetPath: asset.isEmpty ? null : asset,
    );
  }

  CelebrationReward _relicPreviewCard(Relic node) {
    final def = cosmetics.service.catalog.byId(node.relicId);
    return CelebrationReward(
      id: 'relic-${node.relicId}',
      name: (l) => node.titleKey(l),
      sub: (l) => node.rarity.label(l),
      rarity: node.rarity,
      kind: CelebrationRewardKind.gem,
      assetPath: def == null
          ? null
          : cosmetics.service.config
              .resolveAssetPath(def.previewAssetKey ?? def.assetKey),
    );
  }

  /// Standalone fullscreen for an un-folded companion availability.
  /// The companion appears as a single reward card and the fullscreen's
  /// existing "Open inventory â†’" CTA is how the player completes the
  /// activation.
  /// Standalone fullscreen for an un-folded companion availability.
  /// Title + description are kept neutral â€” the real reveal happens in
  /// the inventory claim flow, not on this screen. Without this swap
  /// the celebration would spoil the companion's name (and the asset
  /// path on `_companionPreviewCard` would leak the artwork) before
  /// the player even reaches the forging animation.
  CelebrationEvent _buildStandaloneCompanionEvent(
    CompanionAvailability node,
  ) {
    final card = _companionPreviewCard(node);
    return CelebrationEvent(
      id: 'companion-available|${node.id}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationCompanionReadyEyebrow,
      title: (l) => l.cosmeticCompanionClaimableHiddenName,
      description: (l) => l.cosmeticCompanionCelebrationHint,
      rewards: [card],
      headRarity: node.rarity,
      variantOverride: CelebrationVariant.fullscreen,
    );
  }

  // â”€â”€ Level â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  CelebrationEvent _buildLevelEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    final node = pair.node as LevelMilestone;
    final completion = pair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final headRarity = rewards.isEmpty
        ? node.rarity
        : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards));

    final CelebrationText title;
    if (node.isTitleBreakpoint) {
      title = (l) => l.celebrationLevelTitle(node.level, node.titleKey(l));
    } else if (rewards.isNotEmpty) {
      final first = rewards.first;
      title = (l) => l.celebrationLevelDecorativeTitle(node.level, first.name(l));
    } else {
      title = (l) => l.celebrationLevelTitleNoTitle(node.level);
    }

    return CelebrationEvent(
      id: 'level|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: node.isTitleBreakpoint
          ? CelebrationType.title
          : CelebrationType.level,
      eyebrow: (l) => node.isTitleBreakpoint
          ? l.celebrationTitleEyebrow
          : l.celebrationLevelEyebrow,
      title: title,
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
    );
  }

  // â”€â”€ Chapter (with bundled next-chapter unlock) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  CelebrationEvent? _buildChapterEvent(
    _NodeCompletionPair chapterPair,
    List<_NodeCompletionPair> contentUnlocks,
    ProgressionResolutionResult result,
    Set<String> bundledUnlockIds,
  ) {
    final node = chapterPair.node as ChapterCompletion;
    final completion = chapterPair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);

    // Heuristic: if any ContentUnlock completed in the same result,
    // treat the first un-bundled one as the next-chapter unlock.
    _NodeCompletionPair? unlockPair;
    for (final p in contentUnlocks) {
      if (bundledUnlockIds.contains(p.node.id)) continue;
      unlockPair = p;
      break;
    }
    if (unlockPair != null) {
      bundledUnlockIds.add(unlockPair.node.id);
      // Pull any cosmetic grants tied to the unlock node into the same
      // card stack so the player sees them alongside the chapter loot.
      final unlockCosmeticIds =
          _cosmeticIdsForNode(unlockPair.node.id, result);
      rewards.addAll(_cosmeticsToRewards(unlockCosmeticIds));
    }

    final unlockNode = unlockPair?.node;
    final CelebrationText description = unlockNode == null
        ? (l) => node.descriptionKey(l)
        : (l) {
            final chapterDescription = node.descriptionKey(l);
            final suffix =
                l.celebrationChapterUnlockedSuffix(unlockNode.titleKey(l));
            if (chapterDescription.isEmpty) return suffix;
            return '$chapterDescription Â· $suffix';
          };

    // Prepend the chapter icon as the headliner card so the
    // celebration ties visually to the chapter art the player just
    // finished. Always force fullscreen â€” finishing a chapter is a
    // narrative beat that deserves the big-reveal treatment.
    final allRewards = <CelebrationReward>[
      _chapterIconCard(
        chapterId: node.chapterId,
        nameKey: (l) => node.titleKey(l),
        rarity: node.rarity,
      ),
      ...rewards,
    ];
    final headRarity = Rarity.max(
      node.rarity,
      CelebrationEvent.maxRarityFrom(allRewards),
    );

    return CelebrationEvent(
      id: 'chapter|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: (l) => l.celebrationChapterEyebrow,
      title: (l) => node.titleKey(l),
      description: description,
      rewards: allRewards,
      headRarity: headRarity,
      variantOverride: CelebrationVariant.fullscreen,
    );
  }

  // â”€â”€ Goal (quest + achievement + milestone sharing objectiveId) â”€

  CelebrationEvent? _buildGoalEvent(
    List<_NodeCompletionPair> bucket,
    ProgressionResolutionResult result,
  ) {
    if (bucket.isEmpty) return null;

    // Pick the canonical face: quest > achievement > milestone.
    _NodeCompletionPair? questPair;
    _NodeCompletionPair? achievementPair;
    _NodeCompletionPair? milestonePair;
    for (final p in bucket) {
      switch (p.node) {
        case Quest():
          questPair ??= p;
        case Achievement():
          achievementPair ??= p;
        case Milestone():
          milestonePair ??= p;
        default:
          break;
      }
    }
    final face = questPair ?? achievementPair ?? milestonePair ?? bucket.first;

    // Solo node short-circuit: bucket of one falls back to per-kind
    // builder so we don't reframe a lone quest as "goal complete".
    if (bucket.length == 1) {
      return _buildSoloEvent(face, result);
    }

    // Gather all cosmetic rewards across the bucket.
    final cosmeticIds = <String>[];
    var xpAmount = 0;
    for (final p in bucket) {
      cosmeticIds.addAll(_cosmeticIdsForNode(p.node.id, result));
      final xp = _xpAmountForNode(p.node.id, result);
      if (xp != null) xpAmount += xp;
    }
    final rewards = _cosmeticsToRewards(cosmeticIds);

    // Head rarity = max(node rarities, reward rarities).
    Rarity headRarity = face.node.rarity;
    for (final p in bucket) {
      headRarity = Rarity.max(headRarity, p.node.rarity);
    }
    if (rewards.isNotEmpty) {
      headRarity =
          Rarity.max(headRarity, CelebrationEvent.maxRarityFrom(rewards));
    }
    headRarity = _clampRarityIfDecorationless(
      headRarity,
      hasRewards: rewards.isNotEmpty,
      hasXp: xpAmount > 0,
      isHeadliner: false,
    );

    return CelebrationEvent(
      id: 'goal|${face.node.id}|${face.completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.quest,
      eyebrow: (l) => l.celebrationGoalEyebrow,
      title: (l) => face.node.titleKey(l),
      description: (l) => face.node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
      xpAward: xpAmount > 0 ? CelebrationXpAward(xpAmount) : null,
    );
  }

  // â”€â”€ Solo (quest / achievement / milestone / relic) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  CelebrationEvent? _buildSoloEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    return switch (pair.node) {
      Quest() => _buildQuestEvent(pair, result),
      Achievement() => _buildAchievementEvent(pair, result),
      Milestone() => _buildMilestoneEvent(pair, result),
      Relic() => _buildRelicEvent(pair, result),
      ContentUnlock() => _buildContentUnlockEvent(pair, result),
      _ => null,
    };
  }

  /// Dispatches on the QuestNode subtype's [CelebrationPolicy]. The
  /// adapter used to derive "is opener / finale / mid / suppressed"
  /// inline from displayBucket + chainOrder + nextNodeIds.isEmpty;
  /// that branching now lives intrinsic to the subtype (Phase 2)
  /// and the adapter just reads `node.celebrationPolicy`. Adding a
  /// new celebration flavour is one switch case here + one policy
  /// subclass, not a re-shape of these conditions.
  CelebrationEvent? _buildQuestEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    final node = pair.node as Quest;
    return switch (node.celebrationPolicy) {
      SilentCelebration() => null,
      ChapterOpenedCelebration() => _buildChapterEventForQuest(
          pair,
          result,
          idPrefix: 'chapter-open',
          eyebrow: (l) => l.celebrationChapterUnlockedEyebrow,
        ),
      ChapterCompletedCelebration() => _buildChapterEventForQuest(
          pair,
          result,
          idPrefix: 'chapter-finale',
          eyebrow: (l) => l.celebrationChapterEyebrow,
        ),
    };
  }

  /// Shared shape for the two chapter-flavoured QuestNode
  /// celebrations: fullscreen overlay, chapter icon as the headliner
  /// reward card, accent rarity, optional XP award. The only delta
  /// between opener and finale is the id prefix and eyebrow text.
  CelebrationEvent _buildChapterEventForQuest(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result, {
    required String idPrefix,
    required CelebrationText eyebrow,
  }) {
    final node = pair.node as Quest;
    final completion = pair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final xp = _xpAmountForNode(node.id, result);
    final iconCard = _chapterIconCard(
      chapterId: node.chapterId!,
      nameKey: (l) => node.titleKey(l),
      rarity: node.rarity,
    );
    final allRewards = [iconCard, ...rewards];
    final headRarity = Rarity.max(
      node.rarity,
      CelebrationEvent.maxRarityFrom(allRewards),
    );
    return CelebrationEvent(
      id: '$idPrefix|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: eyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: allRewards,
      headRarity: headRarity,
      xpAward: (xp != null && xp > 0) ? CelebrationXpAward(xp) : null,
      variantOverride: CelebrationVariant.fullscreen,
    );
  }

  CelebrationEvent _buildAchievementEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    final node = pair.node as Achievement;
    final completion = pair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final xp = _xpAmountForNode(node.id, result);
    final headRarity = _clampRarityIfDecorationless(
      rewards.isEmpty
          ? node.rarity
          : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards)),
      hasRewards: rewards.isNotEmpty,
      hasXp: (xp ?? 0) > 0,
      isHeadliner: false,
    );
    return CelebrationEvent(
      id: 'achievement|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.achievement,
      eyebrow: (l) => l.celebrationAchievementEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
      xpAward: (xp != null && xp > 0) ? CelebrationXpAward(xp) : null,
    );
  }

  CelebrationEvent _buildMilestoneEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    final node = pair.node as Milestone;
    final completion = pair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final xp = _xpAmountForNode(node.id, result);
    final headRarity = _clampRarityIfDecorationless(
      rewards.isEmpty
          ? node.rarity
          : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards)),
      hasRewards: rewards.isNotEmpty,
      hasXp: (xp ?? 0) > 0,
      isHeadliner: false,
    );
    return CelebrationEvent(
      id: 'milestone|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: (l) => l.celebrationMilestoneEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
      xpAward: (xp != null && xp > 0) ? CelebrationXpAward(xp) : null,
    );
  }

  CelebrationEvent _buildRelicEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    final node = pair.node as Relic;
    final completion = pair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final headRarity = rewards.isEmpty
        ? node.rarity
        : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards));
    return CelebrationEvent(
      id: 'relic|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationRelicEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
    );
  }

  CelebrationEvent _buildContentUnlockEvent(
    _NodeCompletionPair pair,
    ProgressionResolutionResult result,
  ) {
    final node = pair.node as ContentUnlock;
    final completion = pair.completion;
    final cosmeticIds = _cosmeticIdsForNode(node.id, result);
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final headRarity = rewards.isEmpty
        ? node.rarity
        : Rarity.max(node.rarity, CelebrationEvent.maxRarityFrom(rewards));
    return CelebrationEvent(
      id: 'content|${node.id}|${completion.event.timestamp.microsecondsSinceEpoch}',
      type: CelebrationType.location,
      eyebrow: (l) => l.celebrationContentUnlockEyebrow,
      title: (l) => node.titleKey(l),
      description: (l) => node.descriptionKey(l),
      rewards: rewards,
      headRarity: headRarity,
    );
  }

  // â”€â”€ Orphan cosmetic + welcome-back summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  CelebrationEvent _buildOrphanCosmeticEvent(List<String> cosmeticIds) {
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final count = rewards.isEmpty ? cosmeticIds.length : rewards.length;
    return CelebrationEvent(
      id: 'cosmetic|${cosmeticIds.join(',')}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationCosmeticUnlockedEyebrow,
      title: rewards.length == 1
          ? rewards.first.name
          : (l) => l.celebrationCosmeticUnlockedTitle(count),
      description: (l) => l.celebrationOrphanRewardHint,
      rewards: rewards,
      headRarity: rewards.isEmpty
          ? Rarity.common
          : CelebrationEvent.maxRarityFrom(rewards),
    );
  }

  CelebrationEvent _buildWelcomeBackEvent(ProgressionResolutionResult result) {
    final cosmeticIds = <String>[];
    for (final g in result.grantedRewards) {
      if (g.event.rewardKind == RewardGrantKind.cosmetic) {
        final id = g.event.cosmeticId;
        if (id != null) cosmeticIds.add(id);
      }
    }
    final rewards = _cosmeticsToRewards(cosmeticIds);
    final count = rewards.isEmpty ? 1 : rewards.length;
    return CelebrationEvent(
      id: 'summary|${result.runId}',
      type: CelebrationType.cosmetic,
      eyebrow: (l) => l.celebrationWelcomeBackEyebrow,
      title: (l) => l.celebrationWelcomeBackTitle(count),
      description: (l) => l.celebrationSummaryHint,
      rewards: rewards,
      headRarity: rewards.isEmpty
          ? Rarity.common
          : CelebrationEvent.maxRarityFrom(rewards),
      variantOverride: CelebrationVariant.fullscreen,
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Extracts the objectiveId from nodes that have one, so the goal-bucket
  /// pre-pass can group siblings tracking the same condition.
  String? _objectiveIdOf(ProgressionEntry node) => switch (node) {
        Quest(:final objectiveId) => objectiveId,
        Achievement(:final objectiveId) => objectiveId,
        Milestone(:final objectiveId) => objectiveId,
        _ => null,
      };

  /// Stops a node authored as `rare`/`epic` from glowing legendary purple
  /// when the celebration has no actual rewards to back the visual. The
  /// "headliner" carve-out (level/chapter) keeps their authored rarity
  /// because those events are intrinsically meaningful even without a
  /// dropped item.
  Rarity _clampRarityIfDecorationless(
    Rarity input, {
    required bool hasRewards,
    required bool hasXp,
    required bool isHeadliner,
  }) {
    if (isHeadliner) return input;
    if (hasRewards || hasXp) return input;
    return Rarity.common;
  }

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

  List<Cosmetic> _resolveCosmetics(List<String> ids) {
    final catalog = cosmetics.service.catalog;
    return ids
        .map(catalog.byId)
        .whereType<Cosmetic>()
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

class _NodeCompletionPair {
  const _NodeCompletionPair(this.completion, this.node);
  final NodeCompletion completion;
  final ProgressionEntry node;
}
