import 'package:flutter/widgets.dart';

/// Inherited-model scope that broadcasts "which quest card is currently
/// expanded" down to every [EngineQuestCard] / [EngineChapterCard] /
/// [EngineLongTermCard] / [EngineCompletedQuestCard] without forcing all
/// cards to rebuild when the expanded id flips.
///
/// **Why an `InheritedModel` instead of an `InheritedNotifier` or a plain
/// prop drilling?** Tapping a card to expand it used to call
/// `setState(() => _expandedNodeId = …)` inside `QuestsScreenV2`. That
/// invalidated the whole quest screen build — every section, every card —
/// even though at most two cards (the previously-expanded one and the
/// newly-expanded one) actually changed their `isExpanded` state. With ten
/// or so cards on screen and ~8 ms per card build, the resulting frame
/// was ~90 ms (2026-05-22 trace).
///
/// `InheritedModel<String>` lets each card declare a dependency on its
/// own `nodeId` aspect. When the expanded id flips from `A` to `B`,
/// [updateShouldNotifyDependent] returns true only for the cards that
/// either *were* `A` or *are* `B` — the rest stay clean and skip the
/// build phase entirely.
class ExpandedQuestScope extends InheritedModel<String> {
  const ExpandedQuestScope({
    super.key,
    required this.expandedNodeId,
    required super.child,
  });

  final String? expandedNodeId;

  /// Looks up the scope above [context] and registers [nodeId] as the
  /// aspect this widget depends on. Returns `true` when [nodeId] is the
  /// currently-expanded card. Returns `false` when no scope is mounted
  /// (the cards work standalone in widget tests / previews).
  static bool isExpanded(BuildContext context, String nodeId) {
    final scope = InheritedModel.inheritFrom<ExpandedQuestScope>(
      context,
      aspect: nodeId,
    );
    return scope?.expandedNodeId == nodeId;
  }

  @override
  bool updateShouldNotify(ExpandedQuestScope oldWidget) {
    return oldWidget.expandedNodeId != expandedNodeId;
  }

  @override
  bool updateShouldNotifyDependent(
    ExpandedQuestScope oldWidget,
    Set<String> aspects,
  ) {
    final oldId = oldWidget.expandedNodeId;
    final newId = expandedNodeId;
    if (oldId == newId) return false;
    // A card only cares if its own nodeId either *was* the expanded id
    // (about to collapse) or *is* the new expanded id (about to expand).
    return (oldId != null && aspects.contains(oldId)) ||
        (newId != null && aspects.contains(newId));
  }
}
