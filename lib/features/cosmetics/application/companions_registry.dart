import 'package:flutter/foundation.dart';

import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import '../../progression_engine/domain/models/progression_node_definition.dart';
import '../domain/companion_state.dart';
import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_state.dart';

/// Value object bundling everything a UI surface needs to render a
/// single companion: its cosmetic definition (artwork, name, rarity),
/// the progression-engine availability node (unlock conditions, ids),
/// and the resolved [CompanionState] for the current player.
///
/// The companion's truth lives in three independent stores
/// (cosmetics repo for ownership, ledger for availability, reveal
/// evaluator for partial-progress numbers), so [Companion] is **not**
/// persisted — it is rebuilt by [CompanionsRegistry.snapshot] each
/// time the inputs change. Treat it like a view model: immutable,
/// short-lived, derivable from canonical sources.
@immutable
class Companion {
  const Companion({
    required this.cosmetic,
    required this.node,
    required this.state,
    this.revealResult,
  });

  /// Visual / catalog facts (asset, localised name, description,
  /// rarity tier).
  final CosmeticDefinition cosmetic;

  /// Progression-engine node that owns the manual-claim contract.
  /// Drives [claimNode] calls when the player taps "Vyzvedni".
  final CompanionAvailabilityNode node;

  /// Resolved lifecycle state for the current player. See
  /// [CompanionState] for the four-state model.
  final CompanionState state;

  /// Partial-progress numbers + checklist rows, when the reveal
  /// evaluator produced them. Null for `hidden`; non-null for
  /// `partial` / `claimable` / `claimed` (the evaluator builds rows
  /// for all three branches now that claimable companions reuse the
  /// partial-style checklist).
  final CosmeticRevealResult? revealResult;

  /// Companion id == cosmetic id == availability-node id (see
  /// `companions_content.dart` for the construction).
  String get id => cosmetic.id;

  /// Number of unlock conditions currently satisfied (e.g. 1 of 3).
  /// Returns null when [revealResult] doesn't carry partial-progress
  /// counters.
  int? get satisfiedConditions => revealResult?.satisfiedConditions;

  /// Total number of unlock conditions on the companion's gating
  /// rule. Pairs with [satisfiedConditions] to render "1/3
  /// podmínek splněno".
  int? get totalConditions => revealResult?.totalConditions;

  /// Per-row checklist data ([met] flags + condition ids the sheet
  /// resolves to localised labels). Populated for every state where
  /// the checklist makes sense; null for `hidden`.
  List<CosmeticRevealConditionRow>? get conditionRows =>
      revealResult?.conditionRows;
}

/// Pure factory that walks the progression catalog and produces a
/// fresh [Companion] view for every authored companion. Used by the
/// inventory grid, details sheet, devtools matrix — every surface that
/// needs to render or transition a companion.
///
/// Inputs are deliberately primitives (`Set<String>`, the reveal map)
/// rather than provider instances so the class stays testable in pure
/// Dart and so a misbehaving provider can't smuggle stale state in
/// through a side channel.
class CompanionsRegistry {
  const CompanionsRegistry({
    this.cosmeticCatalog = const CosmeticCatalog(),
  });

  final CosmeticCatalog cosmeticCatalog;

  /// Cached list of every `CompanionAvailabilityNode` in the engine
  /// catalog (currently 7 — see `companions_content.dart`). Built
  /// once at first access; the catalog is `const` so a single eager
  /// pass is fine.
  static final List<CompanionAvailabilityNode> _nodes = [
    for (final node in const ProgressionNodeCatalog().build())
      if (node is CompanionAvailabilityNode) node,
  ];

  /// Read-only view of every companion-availability node in the
  /// catalog. Used by devtools surfaces that don't have a player
  /// state yet (e.g. pre-bind) and just want to know which
  /// companions exist.
  static List<CompanionAvailabilityNode> get allNodes =>
      List.unmodifiable(_nodes);

  /// Build a [Companion] for every catalog entry. Order matches the
  /// authoring order in `companions_content.dart` (chapter ladder).
  List<Companion> snapshot({
    required Set<String> unlockedCosmeticIds,
    required Set<String> availableNodeIds,
    required Map<String, CosmeticRevealResult> revealResults,
  }) {
    final out = <Companion>[];
    for (final node in _nodes) {
      final cosmetic = cosmeticCatalog.byId(node.companionId);
      if (cosmetic == null) continue; // catalog desync — drop the row
      final revealResult = revealResults[cosmetic.id];
      final state = resolveCompanionState(
        companionId: cosmetic.id,
        unlockedCosmeticIds: unlockedCosmeticIds,
        availableNodeIds: availableNodeIds,
        revealResult: revealResult,
      );
      out.add(Companion(
        cosmetic: cosmetic,
        node: node,
        state: state,
        revealResult: revealResult,
      ));
    }
    return out;
  }

  /// Resolve a single companion by its id (cosmetic id). Returns
  /// null if the id is not a companion in the catalog.
  Companion? byId(
    String companionId, {
    required Set<String> unlockedCosmeticIds,
    required Set<String> availableNodeIds,
    required Map<String, CosmeticRevealResult> revealResults,
  }) {
    for (final node in _nodes) {
      if (node.companionId != companionId) continue;
      final cosmetic = cosmeticCatalog.byId(companionId);
      if (cosmetic == null) return null;
      final revealResult = revealResults[companionId];
      final state = resolveCompanionState(
        companionId: companionId,
        unlockedCosmeticIds: unlockedCosmeticIds,
        availableNodeIds: availableNodeIds,
        revealResult: revealResult,
      );
      return Companion(
        cosmetic: cosmetic,
        node: node,
        state: state,
        revealResult: revealResult,
      );
    }
    return null;
  }
}
