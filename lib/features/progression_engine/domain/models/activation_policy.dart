/// Whether a node's evaluation runs and rewards are granted in the
/// current RPG mode setting.
///
/// Display filtering (do we render this node? hide it?) is a separate
/// axis driven by [ContentTag] in the display layer. Activation is
/// what the engine itself does about the node.
enum ActivationPolicy {
  /// Always evaluated and granted. Core fitness progression sits here.
  always,

  /// Evaluated only when RPG mode is on. If the player turned RPG off
  /// while the node was already completed, the ledger keeps it; if RPG
  /// is re-enabled later, the engine catches up retroactively.
  onlyWhenRpgEnabled,

  /// Evaluated only when RPG mode is on, and missed-while-off stays
  /// missed. Use for time-limited / "ironman" style content.
  onlyWhenRpgEnabledNoBackfill,
}
