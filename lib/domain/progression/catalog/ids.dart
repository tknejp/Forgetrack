/// Typed identifiers for progression catalog rows.
///
/// Catalog rows live in [ProgressionEntryCatalog] (Quest, Achievement,
/// Milestone, …) and reference each other by id. Before typed ids,
/// every id was a raw [String] — meaning `inventory.byCosmeticId(quest.id)`
/// compiled, despite mixing two different namespaces. Refactor typos
/// slipped through compilation and surfaced only at runtime, in
/// data-shape bugs that were hard to trace.
///
/// Each extension type below wraps a [String] at compile time and is
/// erased back to [String] at runtime. There is **zero runtime cost**:
/// the underlying value is still a plain String in memory and on the
/// wire. The compile-time discipline is what matters.
///
/// **Construction at the application/UI boundary.** Code that reads an
/// id out of a Firestore document, an Isar record, or a UI text field
/// wraps the raw string with the appropriate typed constructor:
///
///     final id = ProgressionEntryId(doc['nodeId'] as String);
///
/// **Serialisation at the persistence boundary.** Mappers in `data/`
/// unwrap via `id.raw` before writing back. The domain layer never
/// sees the raw form during normal operation.
///
/// See:
///   - docs/domain_model/proposal.md §7 anti-pattern #3.
///   - docs/domain_model/migration_plan.md Phase 3.b.
///
/// **Type hierarchy.** All progression catalog ids implement the
/// umbrella [ProgressionEntryId], so generic interfaces that operate
/// on any catalog row (e.g. `Journal.eventsForNode`) accept any of
/// them. Narrow types like [QuestId] add no new members — they exist
/// purely for compile-time discrimination at construction and consumer
/// sites that statically know the kind of id they expect.
library;

/// Umbrella id for any catalog row in [ProgressionEntryCatalog]. Use
/// this when the caller's code is generic over kind (e.g. a Journal
/// reader that doesn't care whether the node is a Quest or an
/// Achievement).
extension type const ProgressionEntryId(String value) implements String {
  /// Stable serialisation form alias for [value]. Use [raw] at the
  /// persistence boundary for self-documenting intent; the underlying
  /// String IS-A relationship (`implements String`) means a typed id
  /// can also be passed directly wherever a String is expected, so
  /// `.raw` is mostly stylistic.
  String get raw => value;
}

/// Id for a quest catalog row (`Quest` and its subtypes:
/// DailyQuest, WeeklyQuest, ChapterOpener, ChapterStep, ChapterFinale,
/// ChapterSideQuest, ComboStep, ComboFinale, DailyChallenge,
/// LongTermQuest).
extension type const QuestId(String value) implements ProgressionEntryId {}

/// Id for an [Achievement] catalog row.
extension type const AchievementId(String value)
    implements ProgressionEntryId {}

/// Id for a [Milestone] or [LevelMilestone] catalog row.
extension type const MilestoneId(String value)
    implements ProgressionEntryId {}

/// Id for the *narrative chapter* concept (currently spread across
/// chapter content files; the Chapter catalog wrapper lands in
/// Phase 13). [ChapterId] is NOT a [ProgressionEntryId] because a
/// chapter is not itself a catalog row — it's an aggregating concept
/// that ties multiple ProgressionEntry rows (opener, steps, finale,
/// side-quests, completion node) together via a shared id.
extension type const ChapterId(String value) implements String {
  String get raw => value;
}

/// Id for an [Objective] catalog row. Objectives are referenced by
/// quest / achievement / milestone nodes via `objectiveId` to signal
/// what they measure.
extension type const ObjectiveId(String value) implements String {
  String get raw => value;
}

/// Id for a *quest chain* — a linear sequence of quests that share a
/// chain id and are ordered by `chainOrder`. Used by chapter chains
/// (opener → step → step → finale) and combo chains. Like
/// [ChapterId], a chain is not itself a catalog row — it's an
/// aggregating concept tying multiple Quest rows together. R.1
/// introduces this wrapper so `Quest.chainId` cannot be confused
/// with a quest id or a chapter id at the type level.
extension type const ChainId(String value) implements String {
  String get raw => value;
}

/// Id for a *combo pool* — a shared completion pool that combo quests
/// and combo achievements ride on. ComboStep / ComboFinale / DailyChallenge
/// rows declare a `comboPoolId`; achievements with
/// [ComboPoolCompletionsMetric] reference the same pool. R.1 typed
/// wrapper to keep the namespace separate from quest / chain ids.
extension type const ComboPoolId(String value) implements String {
  String get raw => value;
}

/// Id for a *daily-tier group* — groups daily-quest variants that
/// share rotation slots so the picker can keep one quest per tier in
/// view at a time (e.g. "steps-easy / steps-medium / steps-hard"
/// rotate as one group). R.1 typed wrapper.
extension type const DailyTierGroupId(String value) implements String {
  String get raw => value;
}

/// Id for a *cosmetic* catalog row (Frame / Background / Companion /
/// Relic / Emblem / TitleFlair / MapEffect). Lives in
/// [lib/features/cosmetics/domain/] as the cosmetic catalog itself
/// stays feature-scoped per proposal §6, but the id wrapper lives
/// here so catalog rows in `lib/domain/progression/catalog/` that
/// reference cosmetics (CompanionAvailability, Relic, ContentUnlock,
/// CosmeticReward) can do so with a typed cross-reference without
/// pulling the cosmetics catalog into the domain layer.
extension type const CosmeticId(String value) implements String {
  String get raw => value;
}

/// Id for a player-facing *title* reward. Today titles live as their
/// own grant rows (`TitleReward`) and surface on hero card / journey
/// screen. R.1 typed wrapper keeps title ids namespaced separately
/// from cosmetic ids even though the storage shape overlaps.
extension type const TitleId(String value) implements String {
  String get raw => value;
}

/// Id for an *emblem* reward — small badge / icon that shows on
/// profile / feed. Wraps the storage string at the typed boundary;
/// emblem ids historically share namespace with cosmetic ids in the
/// authoring catalog but the proposal treats them as a distinct
/// grant kind.
extension type const EmblemId(String value) implements String {
  String get raw => value;
}
