/// Per-activity claim XP reward. Tier × type multiplier with a
/// distinction between **endurance** kinds (walking, hiking, running,
/// cycling, swimming, rowing) where XP keeps accruing past 60 min, and
/// **short-form** kinds (strength, HIIT, yoga, "other") where the
/// 60+ tier is the cap because longer-than-an-hour rarely scales
/// proportionally with actual effort.
///
/// Final reward is later scaled by the engine's level policy
/// (`scaledRewardXp`) when the grant is written, so this returns the
/// **base** XP — the headline number the pill displays.
library;

/// Coarse activity family resolved from a Health Connect type string.
/// Mapping is intentionally fuzzy (`type.toUpperCase().contains(...)`)
/// so device-vendor variants like Samsung Health's "OTHER" / "WORKOUT"
/// all land in a reasonable bucket.
enum ActivityRewardKind {
  walking,
  hiking,
  running,
  cycling,
  swimming,
  rowing,
  strength,
  hiit,
  yoga,
  /// Samsung Health's "jiné cvičení" lands here — the user logs strength
  /// workouts under this kind because Samsung's kcal estimate matches
  /// best. Treated as strength-equivalent (short-form, 1.5×).
  otherWorkout,
  /// Anything we couldn't map. Conservative 1.0× / short-form cap.
  unknown,
}

ActivityRewardKind activityRewardKindFromType(String hcType) {
  final t = hcType.toUpperCase();
  // Order matters: HIIT before generic strength, hiking before walking
  // (walking is the broader substring), rowing before generic strength.
  if (t.contains('HIGH_INTENSITY') ||
      t.contains('HIIT') ||
      t.contains('INTERVAL')) {
    return ActivityRewardKind.hiit;
  }
  if (t.contains('HIKE') || t.contains('TRAIL')) {
    return ActivityRewardKind.hiking;
  }
  if (t.contains('RUN') || t.contains('JOG')) {
    return ActivityRewardKind.running;
  }
  if (t.contains('CYCL') || t.contains('BIKE') || t.contains('SPIN')) {
    return ActivityRewardKind.cycling;
  }
  if (t.contains('SWIM')) {
    return ActivityRewardKind.swimming;
  }
  if (t.contains('ROW') || t.contains('KAYAK') || t.contains('PADDLE')) {
    return ActivityRewardKind.rowing;
  }
  if (t.contains('WALK')) {
    return ActivityRewardKind.walking;
  }
  if (t.contains('STRENGTH') ||
      t.contains('WEIGHT') ||
      t.contains('RESISTANCE') ||
      t.contains('CALISTHENICS')) {
    return ActivityRewardKind.strength;
  }
  if (t.contains('YOGA') ||
      t.contains('PILATES') ||
      t.contains('STRETCH') ||
      t.contains('MOBILITY') ||
      t.contains('MEDIT')) {
    return ActivityRewardKind.yoga;
  }
  if (t.contains('OTHER') || t.contains('WORKOUT') || t.contains('EXERCISE')) {
    return ActivityRewardKind.otherWorkout;
  }
  return ActivityRewardKind.unknown;
}

bool _isEndurance(ActivityRewardKind kind) {
  switch (kind) {
    case ActivityRewardKind.walking:
    case ActivityRewardKind.hiking:
    case ActivityRewardKind.running:
    case ActivityRewardKind.cycling:
    case ActivityRewardKind.swimming:
    case ActivityRewardKind.rowing:
      return true;
    case ActivityRewardKind.strength:
    case ActivityRewardKind.hiit:
    case ActivityRewardKind.yoga:
    case ActivityRewardKind.otherWorkout:
    case ActivityRewardKind.unknown:
      return false;
  }
}

/// Tier table — keyed off minutes. Endurance keeps progressing past 60;
/// short-form caps at the 60+ band.
int _baseTier({required int minutes, required bool isEndurance}) {
  if (minutes < 10) return 5;
  if (minutes < 30) return 15;
  if (minutes < 60) return 30;
  if (!isEndurance) return 50;
  // Endurance-only extended tiers.
  if (minutes < 120) return 50;
  if (minutes < 180) return 65;
  if (minutes < 240) return 80;
  return 95;
}

double _typeMultiplier(ActivityRewardKind kind) {
  switch (kind) {
    case ActivityRewardKind.walking:
    case ActivityRewardKind.hiking:
      return 1.0;
    case ActivityRewardKind.running:
    case ActivityRewardKind.cycling:
    case ActivityRewardKind.swimming:
    case ActivityRewardKind.rowing:
      return 1.3;
    case ActivityRewardKind.strength:
    case ActivityRewardKind.otherWorkout:
      return 1.5;
    case ActivityRewardKind.hiit:
      return 1.7;
    case ActivityRewardKind.yoga:
      return 1.2;
    case ActivityRewardKind.unknown:
      return 1.0;
  }
}

/// Base XP for one claimed activity. Returns `0` for non-positive
/// durations (treat as a no-op, the pill should be hidden in that
/// case rather than offering a free 5 XP).
int activityRewardXp({required int durationMinutes, required String hcType}) {
  if (durationMinutes <= 0) return 0;
  final kind = activityRewardKindFromType(hcType);
  final tier = _baseTier(
    minutes: durationMinutes,
    isEndurance: _isEndurance(kind),
  );
  return (tier * _typeMultiplier(kind)).round();
}
