/// Why the engine ran. Carried on every [ProgressionResolutionResult]
/// so downstream consumers (celebration adapter, social publisher,
/// devtools logger) can adjust their behaviour — e.g. compress dozens
/// of grants into one summary during a historical resync, or skip
/// celebration popups for a background run.
enum ProgressionResolutionReason {
  /// User did a thing, the engine recomputed.
  liveUpdate,

  /// Player tapped "refresh" / pulled to refresh.
  manualRefresh,

  /// Background sync (app not foregrounded). Celebrations queue but
  /// do not pop until the player returns.
  backgroundSync,

  /// Bulk import / re-evaluation of historical periods. The
  /// celebration adapter compresses these into a single summary
  /// instead of N popups.
  historicalResync,

  /// Devtools-triggered run (XP override, manual achievement grant,
  /// etc.). Useful to filter from analytics.
  devTool,

  /// First post-factory-reset run that re-seeds the welcome flow.
  /// Adapter hand-crafts a single welcome celebration sequence.
  factoryResetSeed,

  /// Result returned from a manual claim action on a manual-claim
  /// node (companion, opt-in inventory unlock).
  claim,
}
