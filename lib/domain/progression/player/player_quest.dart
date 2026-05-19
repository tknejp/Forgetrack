import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import '../catalog/progression_entry.dart';
import 'player_quest_lifecycle.dart';

/// Per-player snapshot of one Quest catalog row.
///
/// Phase 7 of the domain refactor introduces this value class as the
/// projection unit inside [PlayerQuestCatalog]. R.1 promoted the
/// previous `id: QuestId` field to a full [Quest] reference so the
/// projection matches proposal §2.4 — consumers no longer need the
/// `ProgressionEntryCatalog.definitionForId(id) as Quest` dance to
/// reach the catalog row chrome (title / reward list / display
/// bucket / chain order).
///
///   - [quest]: full [Quest] catalog row this snapshot wraps.
///   - [lifecycle]: sealed discriminator carrying the four lifecycle
///     states (Locked / Available / CompletedPendingClaim / Claimed).
///   - [evaluatedAt]: timestamp of the engine evaluation that produced
///     this snapshot.
///
/// **Id forwarding.** The legacy `id` getter is kept as a
/// [QuestId]-typed forward of `quest.id` so existing call sites
/// (`PlayerQuestCatalog.byId(QuestId)`, lifecycle tests) continue to
/// compile without a sweep. The narrower `QuestId` wrapper is rebuilt
/// from `quest.id.value` because [Quest.id] is the umbrella
/// [ProgressionEntryId] type (a Quest catalog row's id IS a quest id
/// by convention, but the static type doesn't carry that fact).
///
/// See:
///   - `docs/domain_model/proposal.md` §2.4 (PlayerQuest).
///   - `docs/domain_model/archive/follow_ups.md` §R.1 (catalog migration).
///   - ADR `player-quest-catalog-projection` in
///     `docs/site/data/decisions.json`.
@immutable
class PlayerQuest {
  const PlayerQuest({
    required this.quest,
    required this.lifecycle,
    required this.evaluatedAt,
  });

  final Quest quest;
  final PlayerQuestLifecycle lifecycle;
  final DateTime evaluatedAt;

  /// Forwarded quest id, narrowed to [QuestId] for backward compat
  /// with the Phase 7 callers that key on [PlayerQuestCatalog.byId].
  /// `quest.id` carries the same underlying String at runtime.
  QuestId get id => QuestId(quest.id.value);

  PlayerQuest copyWith({
    Quest? quest,
    PlayerQuestLifecycle? lifecycle,
    DateTime? evaluatedAt,
  }) {
    return PlayerQuest(
      quest: quest ?? this.quest,
      lifecycle: lifecycle ?? this.lifecycle,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // Catalog rows do not currently override structural equality, so
    // PlayerQuest keys on the catalog id (the projection's natural
    // identity) plus the lifecycle / evaluatedAt payload. Two
    // PlayerQuests with the same `quest.id` always describe the same
    // logical row — different catalog instances with matching ids
    // are equivalent for projection consumers (cache invalidation,
    // diff detection).
    return other is PlayerQuest &&
        other.quest.id == quest.id &&
        other.lifecycle == lifecycle &&
        other.evaluatedAt == evaluatedAt;
  }

  @override
  int get hashCode => Object.hash(quest.id, lifecycle, evaluatedAt);

  @override
  String toString() =>
      'PlayerQuest(id: ${quest.id}, lifecycle: $lifecycle, '
      'evaluatedAt: $evaluatedAt)';
}
