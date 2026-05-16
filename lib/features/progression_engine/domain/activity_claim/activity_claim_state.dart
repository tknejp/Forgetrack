import 'package:flutter/foundation.dart';

import '../../../health_connect/domain/activity_record.dart';

/// One per-activity entry surfaced by the home expanded activity card
/// and the activities screen list. Built by the provider from the
/// ledger + HC activities + the historical claim window.
@immutable
class ActivityClaimState {
  const ActivityClaimState({
    required this.record,
    required this.claimKey,
    required this.previewXp,
    required this.isClaimed,
    required this.isWithinWindow,
  });

  final ActivityRecord record;

  /// Stable composite identity (`<startSec>|<endSec>|<typeUpper>`),
  /// embedded into the ledger event's `periodKey`. UI keys row widgets
  /// off this so claim-state changes don't churn the list order.
  final String claimKey;

  /// Level-scaled XP the player would receive if they claimed now.
  /// Display this on the pill — when [isClaimed] is true it's still
  /// the original grant amount (read back from the ledger event), so
  /// the "+N XP" stays stable after a level-up.
  final int previewXp;

  /// True when a [NodeClaimEvent] under the synthetic
  /// `daily_activity_claim_workout` nodeId with this [claimKey] in its
  /// `periodKey` already exists.
  final bool isClaimed;

  /// True when the activity's calendar day falls inside the
  /// [historicalClaimWindow]. Outside the window the pill renders as
  /// locked — the activity is too old (or, edge-case, predates the
  /// player's join).
  final bool isWithinWindow;

  /// Convenience: can the player tap the pill *right now*?
  bool get isClaimable => !isClaimed && isWithinWindow && previewXp > 0;
}
