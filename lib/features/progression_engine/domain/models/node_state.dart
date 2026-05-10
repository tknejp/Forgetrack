/// Runtime state of one progression node, derived from the current
/// objective outcome + unlock conditions + claim policy + ledger.
enum NodeState {
  /// Unlock conditions not met (or activation policy disables the node
  /// in current RPG mode). Player cannot interact.
  locked,

  /// Unlock conditions met; objective in progress (or already complete
  /// for a manual-claim node awaiting the user's tap).
  available,

  /// Objective complete and rewards granted (automatic claim) — or
  /// player tapped to claim (manual claim).
  completed,
}
