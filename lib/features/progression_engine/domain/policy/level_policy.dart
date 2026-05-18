// Backwards-compat re-export. The canonical home for the XP-curve
// policy moved to `lib/domain/player/level_curve.dart` in Phase 4 of
// the domain refactor (see `docs/domain_model/migration_plan.md`).
//
// Existing call sites (`progression_engine_provider`, evaluators,
// social profile snapshots, …) keep importing this path so the move
// stays a single-PR change. New code in `lib/domain/` should import
// the domain path directly.
export 'package:forgetrack/domain/player/level_curve.dart';
