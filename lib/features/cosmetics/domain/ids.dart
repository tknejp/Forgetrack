/// Typed identifiers for cosmetic catalog rows.
///
/// Lives in the cosmetics feature (not lib/domain/) because cosmetics
/// are a self-contained feature with their own catalog separate from
/// the progression entry hierarchy. The id type is a distinct namespace
/// from [ProgressionEntryId] — passing a quest id where a cosmetic id
/// is expected (or vice versa) is a compile error.
///
/// Companion bug class (proposal §1, §7.3): the original "companion id
/// == cosmetic id == availability node id" convention was enforced
/// only by comments. With [CosmeticId] vs [ProgressionEntryId]
/// (lib/domain/progression/catalog/ids.dart), the compiler refuses to
/// confuse the two — `inventory.byId(node.id)` is a type error if
/// `node.id` is a progression-entry id.
///
/// See:
///   - docs/domain_model/proposal.md §2.3 (separate Cosmetic vs
///     CompanionAvailability typed namespaces).
///   - docs/domain_model/migration_plan.md Phase 3.b.
library;

/// Id for a [Cosmetic] catalog row. Wraps [String] at compile time;
/// erases to [String] at runtime — zero overhead. Persistence
/// boundary uses [raw] for Isar / Firestore I/O.
extension type const CosmeticId(String value) implements String {
  /// Stable serialisation form alias for [value]. Use [raw] at the
  /// persistence boundary for self-documenting intent; the underlying
  /// String IS-A relationship (`implements String`) means a typed id
  /// can also be passed directly wherever a String is expected, so
  /// `.raw` is mostly stylistic.
  String get raw => value;
}
