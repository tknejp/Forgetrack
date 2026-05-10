/// What happens when a node's objective + unlock conditions are met.
enum ClaimPolicy {
  /// Node completes immediately, rewards granted in the same evaluation
  /// pass. Default for quests, achievements, milestones.
  automatic,

  /// Node enters an "available" state; rewards are not granted until
  /// the player explicitly claims. Default for companion availability
  /// nodes (player picks which companion to commit to) and any
  /// inventory unlock that should not be a surprise.
  manual,
}
