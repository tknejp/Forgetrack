/// Stable, ledger-safe identity for one activity claim.
///
/// Matches the [Health Connect dedup identity][1] **minus** volatile
/// `caloriesBurned` / `distanceKm` fields — a re-sync that recalibrates
/// a workout's kcal estimate must NOT create a "new" claimable
/// instance. Time window (1-second resolution, UTC) plus normalised
/// type string is the strongest identity the data layer guarantees.
///
/// Format: `<startSec>|<endSec>|<typeUpper>` — embedded into the
/// ledger event's `periodKey` so a single template `nodeId` can carry
/// arbitrarily many per-activity claim instances without inflating the
/// node catalog.
///
/// [1]: lib/features/health_connect/data/local/health_database.dart `_activityKey`
library;

import '../../../health_connect/domain/activity_record.dart';

String activityClaimKey(ActivityRecord activity) {
  final startSec = activity.startTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  final endSec = activity.endTime.toUtc().millisecondsSinceEpoch ~/ 1000;
  final type = activity.type.trim().toUpperCase();
  return '$startSec|$endSec|$type';
}
