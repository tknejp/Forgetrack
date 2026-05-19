import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import 'player_quest.dart';
import 'player_quest_lifecycle.dart';

/// Read-only projection of every Quest catalog row + its current
/// [PlayerQuestLifecycle] state for the active player.
///
/// Phase 7 of the domain refactor introduces this aggregate so quest
/// screens no longer reach into raw `EngineQuestProgress` lists to
/// derive state. The catalog is the authoritative lifecycle source —
/// produced once per engine evaluation, replaced wholesale on each
/// refresh, queried by widgets that need a single quest's state or
/// any of the lifecycle-filtered iterables below.
///
/// **Construction.** [PlayerQuestCatalog] is immutable; the entries
/// map is wrapped in an unmodifiable view so a caller can't mutate
/// the catalog after construction. Build the catalog via
/// `PlayerQuestCatalogService` (in `lib/features/progression_engine/
/// application/`) — that's the application-layer adapter that maps
/// the engine's per-evaluation `EngineQuestProgress` instances into
/// [PlayerQuest] values.
///
/// **Iteration order.** [all] returns values in insertion order
/// (Dart `Map` insertion-order guarantee); the lifecycle-filtered
/// iterables ([locked], [available], [pendingClaim], [claimed])
/// preserve that order. The service is responsible for handing
/// quests in whatever order downstream widgets want; this collection
/// is order-preserving but not order-imposing.
///
/// **Empty state.** [PlayerQuestCatalog.empty] is the sentinel the
/// provider returns before the first evaluation completes. It has
/// `.all` empty, every lifecycle filter empty, [byId] always null.
///
/// See:
///   - `docs/domain_model/proposal.md` §2.4 (PlayerQuestCatalog).
///   - `docs/domain_model/migration_plan.md` §Phase 7.
///   - ADR `player-quest-catalog-projection`.
@immutable
class PlayerQuestCatalog {
  /// Construct from an iterable of [PlayerQuest] entries. Duplicate
  /// ids in [entries] keep the last occurrence — matches Dart's
  /// `Map.fromEntries` semantics. The service guarantees uniqueness
  /// by id; this fallback is defensive and observable in tests.
  factory PlayerQuestCatalog.fromEntries(Iterable<PlayerQuest> entries) {
    final map = <QuestId, PlayerQuest>{};
    for (final entry in entries) {
      map[entry.id] = entry;
    }
    return PlayerQuestCatalog._(Map.unmodifiable(map));
  }

  const PlayerQuestCatalog._(this._entries);

  /// Sentinel for the pre-first-evaluation state. Reading from it
  /// returns empty iterables and null lookups so screen consumers
  /// don't need null checks at every site.
  static const PlayerQuestCatalog empty =
      PlayerQuestCatalog._(<QuestId, PlayerQuest>{});

  final Map<QuestId, PlayerQuest> _entries;

  /// Look up a single quest by its typed id. Returns null when the
  /// id isn't in the catalog (e.g. the catalog hasn't loaded yet,
  /// or the requested quest is RPG-gated off in the current mode).
  PlayerQuest? byId(QuestId id) => _entries[id];

  /// All quests in insertion order.
  Iterable<PlayerQuest> get all => _entries.values;

  /// Number of catalog rows. O(1).
  int get length => _entries.length;

  /// True when the catalog has zero entries — typically the sentinel
  /// [PlayerQuestCatalog.empty] before the first evaluation completes.
  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  /// True iff [id] is present in the catalog (regardless of lifecycle).
  bool contains(QuestId id) => _entries.containsKey(id);

  /// Quests currently in the [QuestLocked] state. Backs the
  /// ZAMČENÉ QUESTY section.
  Iterable<PlayerQuest> get locked =>
      _entries.values.where((q) => q.lifecycle is QuestLocked);

  /// Quests currently in the [QuestAvailable] state (eligible,
  /// objective in progress). Backs the "active" rows that the
  /// daily / weekly sections show with their progress bars.
  Iterable<PlayerQuest> get available =>
      _entries.values.where((q) => q.lifecycle is QuestAvailable);

  /// Quests where the objective is satisfied and a manual claim is
  /// pending. Backs the gold "Vyzvednout" pills and the
  /// `dailyClaimable` / `weeklyClaimable` screen rollups.
  Iterable<PlayerQuest> get pendingClaim =>
      _entries.values.where((q) => q.lifecycle is QuestCompletedPendingClaim);

  /// Quests with the completion event in the ledger. Backs the
  /// DOKONČENÉ QUESTY section and the `dailyUnclaimed`-complementary
  /// filter on the daily-section sticky-slot logic.
  Iterable<PlayerQuest> get claimed =>
      _entries.values.where((q) => q.lifecycle is QuestClaimed);

  /// Subset of [all] keyed by [ids] (filters out missing entries).
  /// Lets screen consumers pull a known bucket (e.g. the engine's
  /// `currentDailyQuests` ordering) and ask the catalog for the
  /// matching projection slice in O(n) lookups.
  Iterable<PlayerQuest> among(Iterable<QuestId> ids) sync* {
    for (final id in ids) {
      final entry = _entries[id];
      if (entry != null) yield entry;
    }
  }

  /// Apply [predicate] against every entry in insertion order. Use
  /// this for ad-hoc filters that don't match one of the named
  /// lifecycle accessors (e.g. "pending claim AND in the chapter
  /// pool"). Returning Iterable, not List, so consumers pay only for
  /// the entries they actually iterate.
  Iterable<PlayerQuest> where(bool Function(PlayerQuest) predicate) =>
      _entries.values.where(predicate);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayerQuestCatalog) return false;
    if (other._entries.length != _entries.length) return false;
    for (final entry in _entries.entries) {
      if (other._entries[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(_entries.entries
      .map((e) => Object.hash(e.key, e.value)));

  @override
  String toString() => 'PlayerQuestCatalog(length: $length)';
}
