import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';

/// Pure lookup helpers for the `CompanionAvailability` progression
/// nodes that gate companion claiming. The cosmetics side reads these
/// to drive the claim CTA and the devtools state matrix.
///
/// **Why a free function, not a class.** Phase 11 deletes
/// `CompanionsRegistry` — the view-model factory it used to bundle
/// (cosmetic + node + state + revealResult) is gone. The only piece of
/// `CompanionsRegistry` that survives is the catalog walk that
/// extracts `CompanionAvailability` rows from
/// `ProgressionEntryCatalog`. That walk is a pure function over the
/// const catalog and doesn't deserve a class.
///
/// **Identity invariant.** Companion id == cosmetic id == availability
/// node id (set in `companions_content.dart`). `companionAvailabilityFor(id)`
/// returns the node whose `companionId` equals [id]. Returns null when
/// no row matches — typically because [id] isn't a companion at all.

/// Cached list of every `CompanionAvailability` row in the engine
/// catalog (today 7 — see `companions_content.dart`). Built once at
/// first access; the catalog is `const` so a single eager pass is
/// fine and the result never changes within an app run.
final List<CompanionAvailability> _allCompanionAvailabilities = [
  for (final node in const ProgressionEntryCatalog().build())
    if (node is CompanionAvailability) node,
];

/// Read-only view of every companion-availability node in the catalog.
/// Used by devtools surfaces that don't have a player state yet (e.g.
/// pre-bind) and just want to enumerate companions.
List<CompanionAvailability> get allCompanionAvailabilities =>
    List.unmodifiable(_allCompanionAvailabilities);

/// Look up the gating `CompanionAvailability` node for a given
/// cosmetic id. Returns null when [cosmeticId] isn't a companion.
CompanionAvailability? companionAvailabilityFor(String cosmeticId) {
  for (final node in _allCompanionAvailabilities) {
    if (node.companionId == cosmeticId) return node;
  }
  return null;
}

