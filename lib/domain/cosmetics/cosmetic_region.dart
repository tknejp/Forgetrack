/// Journey region a cosmetic is themed around. Used for grouping in the
/// inventory and matching cosmetics to the chapter/environment palette
/// they belong to. `neutral` is reserved for cosmetics that are
/// region-agnostic (dev-only items, cross-chapter gear).
///
/// Lives in `lib/domain/cosmetics/` so the cross-feature
/// [CompanionSpec] (consumed by both `cosmetics` and `progression_engine`
/// features) can name it without forcing either feature to import the
/// other's domain layer.
enum CosmeticRegion {
  forestTrail,
  ruinedPass,
  dwarvenMines,
  frostlands,
  dragonMountains,
  dragonrockFortress,
  neutral,
}
