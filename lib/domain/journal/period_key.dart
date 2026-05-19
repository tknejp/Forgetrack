/// Time-window key used to scope objective completions, node claims
/// and quest offerings.
///
/// **UTC enforcement.** The audit identified a class of cross-device
/// sync bugs where the same calendar day produced different period
/// keys depending on the device timezone (e.g. `2026-05-10` on a
/// device in UTC+02 vs `2026-05-11` on a device crossing the date
/// line). [PeriodKey.day] and [PeriodKey.isoWeek] normalise to UTC
/// before formatting so the same wall clock day yields the same key
/// regardless of where the device is.
///
/// Construction is by factory only — the const constructor is private
/// (`PeriodKey._`) so call sites cannot smuggle in an un-normalised
/// raw string. Persistence layers serialise via [raw] and reconstruct
/// via [PeriodKey.fromRaw] at the data boundary; the application
/// layer never sees the raw form.
///
/// See:
///   - docs/domain_model/migration_plan.md Phase 2 (UTC enforcement).
///   - docs/domain_model/archive/follow_ups.md §2.12 (post-Phase 2 audit of
///     existing ledger records for legacy drift).
class PeriodKey {
  /// Private — external code must go through the named factories so
  /// every key in the system is the result of a normalising pass.
  const PeriodKey._(this._value);

  /// `yyyy-MM-dd` key for the calendar day [moment] falls on, normalised
  /// to UTC. The same UTC instant always returns the same key.
  factory PeriodKey.day(DateTime moment) {
    final utc = moment.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return PeriodKey._('$year-$month-$day');
  }

  /// `yyyy-Www` ISO week key for the week [moment] falls in, normalised
  /// to UTC. Uses ISO 8601 week numbering (week starts Monday, week 1
  /// contains the year's first Thursday).
  factory PeriodKey.isoWeek(DateTime moment) {
    final utc = moment.toUtc();
    final week = _isoWeekNumber(utc);
    final year = _isoWeekYear(utc);
    return PeriodKey._('${year.toString().padLeft(4, '0')}-W'
        '${week.toString().padLeft(2, '0')}');
  }

  /// Lifetime scope — single sentinel key for objectives that span the
  /// player's entire history (e.g. `LifetimeScope` objectives).
  static const lifetime = PeriodKey._('lifetime');

  /// Per-chapter scope. [chapterId] should be a stable catalog id; the
  /// resulting key namespaces the chapter so two chapters running in
  /// parallel don't collide.
  factory PeriodKey.chapter(String chapterId) =>
      PeriodKey._('chapter:$chapterId');

  /// Reconstruct from a previously-serialised raw string. Used at the
  /// persistence boundary (Isar / Firestore mappers). Trust-the-store
  /// semantics: no re-normalisation, because the key was already
  /// normalised when first written. If a stored value looks malformed
  /// (e.g. legacy data from before UTC enforcement landed), it survives
  /// the round-trip as-is so devtools can audit it.
  factory PeriodKey.fromRaw(String raw) => PeriodKey._(raw);

  final String _value;

  /// Stable serialisation form for persistence. Returns the underlying
  /// raw string. Used by Isar / Firestore mappers at the data boundary.
  String get raw => _value;

  @override
  bool operator ==(Object other) =>
      other is PeriodKey && other._value == _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'PeriodKey($_value)';

  // ── ISO 8601 week helpers ────────────────────────────────────────
  //
  // Pure functions; no DateTime locale or platform involvement.

  static int _isoWeekNumber(DateTime utcMoment) {
    final dayOfYear = _dayOfYear(utcMoment);
    final isoWeekday = utcMoment.weekday; // Mon=1 .. Sun=7
    final week = ((dayOfYear - isoWeekday + 10) / 7).floor();
    if (week < 1) {
      // Belongs to the last ISO week of the previous year.
      return _isoWeeksInYear(utcMoment.year - 1);
    }
    if (week > _isoWeeksInYear(utcMoment.year)) {
      // Belongs to ISO week 1 of the next year.
      return 1;
    }
    return week;
  }

  static int _isoWeekYear(DateTime utcMoment) {
    final dayOfYear = _dayOfYear(utcMoment);
    final isoWeekday = utcMoment.weekday;
    final week = ((dayOfYear - isoWeekday + 10) / 7).floor();
    if (week < 1) return utcMoment.year - 1;
    if (week > _isoWeeksInYear(utcMoment.year)) return utcMoment.year + 1;
    return utcMoment.year;
  }

  static int _dayOfYear(DateTime utcMoment) {
    final startOfYear = DateTime.utc(utcMoment.year, 1, 1);
    return utcMoment.difference(startOfYear).inDays + 1;
  }

  static int _isoWeeksInYear(int year) {
    // A year has 53 ISO weeks iff Jan 1 is Thursday, or it's a leap
    // year and Jan 1 is Wednesday. Otherwise 52.
    final jan1 = DateTime.utc(year, 1, 1).weekday;
    final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    if (jan1 == DateTime.thursday) return 53;
    if (isLeap && jan1 == DateTime.wednesday) return 53;
    return 52;
  }
}
