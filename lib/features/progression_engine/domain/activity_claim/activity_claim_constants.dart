/// Synthetic `nodeId` carrying every per-activity claim ledger event.
///
/// The catalog validator only checks catalog-internal references
/// (`nodes[*].objectiveId`, unlock conditions); it does NOT enforce
/// that every ledger event's `nodeId` resolves to a catalog entry.
/// That gap lets us use a single template id for an unbounded number
/// of dynamic claim instances — the activity's identity lives in the
/// event's `periodKey` instead (see `activityClaimKey`).
///
/// Profile XP totals are derived from every [RewardGrantEvent] in the
/// ledger regardless of source, so claims under this id contribute to
/// level / streaks / XP curves identically to catalog-quest claims.
library;

const String kActivityWorkoutClaimNodeId = 'daily_activity_claim_workout'; // lint-ignore: untyped-id — synthetic node id, persisted as raw string in RewardGrantEvent.nodeId
