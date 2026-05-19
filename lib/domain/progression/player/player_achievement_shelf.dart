import 'package:meta/meta.dart';

import '../catalog/ids.dart';
import 'player_achievement.dart';
import 'player_achievement_lifecycle.dart';

/// Read-only projection of every Achievement catalog row + its current
/// [PlayerAchievementLifecycle] state for the active player.
///
/// Phase 8 mirror of [PlayerQuestCatalog]: same shape, same accessor
/// vocabulary, named for the proposal's `Shelf` term (`docs/domain_model
/// /proposal.md` §2.4). The "shelf" metaphor matches the UI surface —
/// achievements live in a grid the player browses, not a queue of
/// active work.
///
/// **Construction.** [PlayerAchievementShelf] is immutable; the entries
/// map is wrapped in an unmodifiable view so a caller can't mutate
/// the shelf after construction. Build via
/// `PlayerAchievementShelfService` in
/// `lib/features/progression_engine/application/` — the application-
/// layer adapter that maps the engine's per-evaluation
/// `EngineAchievementView` instances into [PlayerAchievement] values.
///
/// **Empty state.** [PlayerAchievementShelf.empty] is the sentinel the
/// provider returns before the first evaluation completes. Reading
/// from it returns empty iterables and null lookups, so screen
/// consumers don't need null checks at every site.
///
/// **Iteration order.** [all] returns values in insertion order (Dart
/// `Map` insertion-order guarantee); lifecycle-filtered iterables
/// preserve that order.
@immutable
class PlayerAchievementShelf {
  /// Construct from an iterable of [PlayerAchievement] entries.
  /// Duplicate ids keep the last occurrence — matches Dart's
  /// `Map.fromEntries` semantics and the service contract.
  factory PlayerAchievementShelf.fromEntries(
    Iterable<PlayerAchievement> entries,
  ) {
    final map = <AchievementId, PlayerAchievement>{};
    for (final entry in entries) {
      map[entry.id] = entry;
    }
    return PlayerAchievementShelf._(Map.unmodifiable(map));
  }

  const PlayerAchievementShelf._(this._entries);

  /// Sentinel for the pre-first-evaluation state. Exposed as `const`
  /// so call sites can default to it without allocations.
  static const PlayerAchievementShelf empty =
      PlayerAchievementShelf._(<AchievementId, PlayerAchievement>{});

  final Map<AchievementId, PlayerAchievement> _entries;

  /// Look up a single achievement by its typed id. Returns null when
  /// the id isn't in the shelf.
  PlayerAchievement? byId(AchievementId id) => _entries[id];

  /// All achievements in insertion order.
  Iterable<PlayerAchievement> get all => _entries.values;

  /// Number of catalog rows. O(1).
  int get length => _entries.length;

  /// True when the shelf has zero entries — typically the sentinel
  /// [PlayerAchievementShelf.empty] before the first evaluation
  /// completes.
  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  /// True iff [id] is present in the shelf (regardless of lifecycle).
  bool contains(AchievementId id) => _entries.containsKey(id);

  /// Achievements currently in the [AchievementLocked] state.
  /// Hero/Journey surfaces usually hide these rows.
  Iterable<PlayerAchievement> get locked =>
      _entries.values.where((a) => a.lifecycle is AchievementLocked);

  /// Achievements currently in the [AchievementInProgress] state.
  /// Hero "in progress" carousel rolls these up; detail sheet surfaces
  /// per-row progress.
  Iterable<PlayerAchievement> get inProgress =>
      _entries.values.where((a) => a.lifecycle is AchievementInProgress);

  /// Achievements in the terminal [AchievementUnlocked] state.
  /// Backs the hero "unlocked" grid and the journey "you earned X"
  /// timeline events.
  Iterable<PlayerAchievement> get unlocked =>
      _entries.values.where((a) => a.lifecycle is AchievementUnlocked);

  /// Count of unlocked achievements. Reads the unlocked iterable
  /// once. Backs the hero header pill.
  int get unlockedCount => unlocked.length;

  /// Subset of [all] keyed by [ids] (filters out missing entries).
  /// Lets screen consumers pull a known bucket (e.g. the catalog's
  /// ordering) and ask the shelf for the matching projection slice.
  Iterable<PlayerAchievement> among(Iterable<AchievementId> ids) sync* {
    for (final id in ids) {
      final entry = _entries[id];
      if (entry != null) yield entry;
    }
  }

  /// Apply [predicate] against every entry in insertion order. Use for
  /// ad-hoc filters that don't match one of the named lifecycle
  /// accessors.
  Iterable<PlayerAchievement> where(
    bool Function(PlayerAchievement) predicate,
  ) =>
      _entries.values.where(predicate);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayerAchievementShelf) return false;
    if (other._entries.length != _entries.length) return false;
    for (final entry in _entries.entries) {
      if (other._entries[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
        _entries.entries.map((e) => Object.hash(e.key, e.value)),
      );

  @override
  String toString() => 'PlayerAchievementShelf(length: $length)';
}
