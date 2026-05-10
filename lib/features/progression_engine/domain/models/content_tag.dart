/// Declarative classification of progression content.
///
/// Drives display filtering and (combined with [ActivationPolicy])
/// engine evaluation when the player toggles RPG mode. A single node
/// or reward may carry multiple tags — e.g. `[core, fitness]` for a
/// daily steps quest, `[rpg, companions]` for a companion node.
enum ContentTag {
  /// Always shown, regardless of RPG mode. Steps / nutrition / sleep /
  /// activity tracking lives here.
  core,

  /// RPG-flavored content (chapters, fantasy titles, journey prose).
  rpg,

  /// Fitness-focused — daily activity, steps, weekly volume.
  fitness,

  /// Journey map / chapter content.
  journey,

  /// Cosmetic-tagged content. Useful when filtering "what does
  /// completing this node give me cosmetically".
  cosmetics,

  /// Relic rewards (passive RPG items).
  relics,

  /// Companion rewards (manual-claim RPG partners).
  companions,

  /// Social-feed-relevant content (anything friends might see).
  social,
}
