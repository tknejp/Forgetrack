import 'package:meta/meta.dart';

import 'ids.dart';
import 'player_cosmetic.dart';
import 'player_cosmetic_lifecycle.dart';

/// Read-only projection of every enabled [Cosmetic] catalog row + its
/// current [PlayerCosmeticLifecycle] state for the active player.
///
/// Phase 10 mirror of [PlayerQuestCatalog] / [PlayerAchievementShelf]:
/// same construction contract (factory from entries, immutable map
/// wrapped unmodifiable), same accessor vocabulary, same empty
/// sentinel. The "inventory" term matches the proposal's collection
/// noun (`docs/domain_model/proposal.md` §2.4) — the player browses
/// owned / teased cosmetics as a shelf-style inventory, not a queue.
///
/// **Construction.** Build via
/// `PlayerCosmeticLifecycleService.build(...)` in
/// `lib/features/cosmetics/application/`. The service takes primitive
/// inputs (catalog rows + unlocked map + reveal results + available
/// node ids) so the [Inventory] surface itself stays a pure-domain
/// value class — no Flutter / l10n / provider imports.
///
/// **Empty state.** [Inventory.empty] is the sentinel for the
/// pre-first-evaluation window. Returns empty iterables and null
/// lookups so widgets don't need null checks at every site.
///
/// **Iteration order.** [all] returns values in catalog insertion
/// order (Dart `Map` insertion-order guarantee); lifecycle-filtered
/// iterables preserve that order.
///
/// **UserCosmeticsState lives on.** Phase 10 keeps the legacy
/// `UserCosmeticsState.unlocked` backing storage; the Inventory
/// derives from it. Real removal is Phase 12 (per migration_plan.md
/// §Phase 10 step 5).
@immutable
class Inventory {
  /// Construct from an iterable of [PlayerCosmetic] entries.
  /// Duplicate ids keep the last occurrence — matches Dart's
  /// `Map.fromEntries` semantics and the service contract.
  factory Inventory.fromEntries(Iterable<PlayerCosmetic> entries) {
    final map = <CosmeticId, PlayerCosmetic>{};
    for (final entry in entries) {
      map[entry.id] = entry;
    }
    return Inventory._(Map.unmodifiable(map));
  }

  const Inventory._(this._entries);

  /// Sentinel for the pre-first-evaluation state. Exposed as `const`
  /// so callers default to it without allocations.
  static const Inventory empty = Inventory._(<CosmeticId, PlayerCosmetic>{});

  final Map<CosmeticId, PlayerCosmetic> _entries;

  /// Look up a single cosmetic projection by its typed id. Returns
  /// null when the id isn't in the inventory.
  PlayerCosmetic? byId(CosmeticId id) => _entries[id];

  /// String-keyed convenience lookup. The legacy `UnlockedCosmetic.cosmeticId`
  /// is a raw String today; this overload removes the `CosmeticId(...)` wrap
  /// at every call site. Returns null when the id isn't present.
  PlayerCosmetic? byIdString(String id) => _entries[CosmeticId(id)];

  /// All cosmetic projections in catalog insertion order.
  Iterable<PlayerCosmetic> get all => _entries.values;

  /// Number of catalog rows in the inventory. O(1).
  int get length => _entries.length;

  /// True when the inventory has zero entries — typically the sentinel
  /// [Inventory.empty] before the first evaluation completes.
  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  /// True iff [id] is in the inventory (regardless of lifecycle).
  bool contains(CosmeticId id) => _entries.containsKey(id);

  /// Cosmetics in the terminal [CosmeticOwned] state. Backs the
  /// inventory screen's "owned" tab + the social profile mirror.
  Iterable<PlayerCosmetic> get owned =>
      _entries.values.where((c) => c.lifecycle is CosmeticOwned);

  /// Cosmetics in [CosmeticClaimable] — the player can claim them now.
  /// Today this is only ever companion availability; future producers
  /// (premium grants, promotional codes) layer on the same state.
  Iterable<PlayerCosmetic> get claimable =>
      _entries.values.where((c) => c.lifecycle is CosmeticClaimable);

  /// Cosmetics in [CosmeticTeased] — identity revealed, locked. Mixes
  /// the no-progress "visibleLocked" flavour with the partial-progress
  /// flavour; widgets pattern-match on `hasProgress` to distinguish.
  Iterable<PlayerCosmetic> get teased =>
      _entries.values.where((c) => c.lifecycle is CosmeticTeased);

  /// Cosmetics in [CosmeticHidden] — silhouette in the grid.
  Iterable<PlayerCosmetic> get hidden =>
      _entries.values.where((c) => c.lifecycle is CosmeticHidden);

  /// Count of owned cosmetics. Reads the iterable once. Backs the
  /// hero header pill and the social profile's "X / Y unlocked" line.
  int get ownedCount => owned.length;

  /// Subset of [all] keyed by [ids] (filters out missing entries).
  /// Lets screen consumers pull a known bucket (e.g. the catalog
  /// ordering by type) and ask the inventory for the matching
  /// projection slice in one pass.
  Iterable<PlayerCosmetic> among(Iterable<CosmeticId> ids) sync* {
    for (final id in ids) {
      final entry = _entries[id];
      if (entry != null) yield entry;
    }
  }

  /// Apply [predicate] against every entry in insertion order.
  Iterable<PlayerCosmetic> where(bool Function(PlayerCosmetic) predicate) =>
      _entries.values.where(predicate);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Inventory) return false;
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
  String toString() => 'Inventory(length: $length)';
}
