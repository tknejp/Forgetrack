import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';

/// Pure lookup helpers for the `CompanionAvailability` progression
/// nodes that gate companion claiming. The cosmetics side reads these
/// to drive the claim CTA and the devtools state matrix.
///
/// **Why a free function, not a class.** Phase 11 deletes
/// `CompanionsRegistry` â€” the view-model factory it used to bundle
/// (cosmetic + node + state + revealResult) is gone. The only piece of
/// `CompanionsRegistry` that survives is the catalog walk that
/// extracts `CompanionAvailability` rows from
/// `ProgressionEntryCatalog`. That walk is a pure function over the
/// const catalog and doesn't deserve a class.
///
/// **Identity invariant.** Companion id == cosmetic id == availability
/// node id (set in `companions_content.dart`). `companionAvailabilityFor(id)`
/// returns the node whose `companionId` equals [id]. Returns null when
/// no row matches â€” typically because [id] isn't a companion at all.

/// Cached list of every `CompanionAvailability` row in the engine
/// catalog (today 7 â€” see `companions_content.dart`). Built once at
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

/// Companions intentionally claimed **outside** the
/// `CompanionAvailability` / `claimNode` flow.
///
/// Track A R.7 (2026-05-19) audited the catalog and confirmed the
/// three companions listed here ship without a progression-engine
/// availability node by design — they are unlocked through
/// `CosmeticUnlockRule` (level gate + two-relic ownership) and the
/// cosmetic-unlock bridge grants them silently as soon as the
/// conditions hold. The claim sheet / devtools matrix uses this
/// whitelist + [companionAvailabilityFor] to decide which UI path a
/// companion belongs to; the forward-parity test in
/// `test/features/cosmetics/companion_availability_lookup_test.dart`
/// enforces that every catalog companion is either gated by an
/// availability node OR listed here.
///
/// Reason for the split (option c in
/// `docs/domain_model/archive/follow_ups.md` §2 R.7): the three companions
/// are mid-late rarity rewards whose gating is already fully
/// expressed by their relic prerequisites
/// (`relic_oathbound_mark` + `relic_bridge_key`, etc., see
/// `cosmetic_unlock_rules.dart`). Wrapping the same condition graph
/// in a redundant `CompanionAvailability` row would duplicate the
/// gate in two places without changing the player-facing flow — the
/// player still sees Hidden → Owned with no claim CTA either way.
///
/// New companions: add a `CompanionAvailability` node in
/// `companions_content.dart` (the preferred path — keeps everything
/// claimable through one engine API) **or** add an entry here plus
/// a matching `CosmeticUnlockRule`. The forward-parity test will
/// fail at build time if you forget to pick one.
const Set<String> companionsClaimedViaUnlockRules = <String>{
  'companion_bridge_gargoyle',
  'companion_cave_lynx',
  'companion_aurora_stag',
};
