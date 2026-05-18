import 'package:meta/meta.dart';

/// Discriminator for every per-Player goal the app tracks.
///
/// Mirrors the SharedPreferences key shape `goal_*` so the wire format
/// stays stable across the Phase 14 extraction (see
/// `docs/domain_model/migration_plan.md` §Phase 14).
///
/// **History tracking.** All metrics except [targetWeight] keep a
/// revision history so retroactive backfill evaluation can resolve the
/// "target effective on day D" for an arbitrary past D. Target weight
/// is a single current value — no day-anchored evaluation, so no
/// history is persisted today.
enum GoalMetric {
  dailySteps,
  targetWeight,
  dailyCalories,
  dailyProtein,
  dailyFat,
  dailyCarbs,
  dailyFiber,
  sleepHours,
  weeklyActivityMins,
}

/// One row in a [PlayerGoal]'s revision timeline.
///
/// `effectiveFrom` is always normalised to a `DateTime(year, month,
/// day)` — time-of-day is discarded so retroactive resolution at any
/// hour of the same calendar day picks the same revision.
@immutable
class GoalRevision {
  GoalRevision({required DateTime effectiveFrom, required this.value})
      : effectiveFrom = _normalize(effectiveFrom);

  final DateTime effectiveFrom;
  final double value;

  static DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Map<String, dynamic> toJson() => {
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'value': value,
      };

  factory GoalRevision.fromJson(Map<String, dynamic> json) {
    return GoalRevision(
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalRevision &&
          other.effectiveFrom == effectiveFrom &&
          other.value == value;

  @override
  int get hashCode => Object.hash(effectiveFrom, value);

  @override
  String toString() =>
      'GoalRevision(effectiveFrom: $effectiveFrom, value: $value)';
}

/// Single per-Player goal: a metric + the current target + the
/// (optional) revision history used by retroactive evaluation.
///
/// Immutable value object. Mutation is whole-object replacement via
/// [withRevision] / [ensureRevisionAt].
///
/// **Resolve semantics ([resolveForDate]).** Returns the latest
/// revision whose `effectiveFrom <= day`, or [target] when [history]
/// is empty (e.g. for [GoalMetric.targetWeight] which is not
/// time-resolved). Matches the pre-extraction `GoalsProvider` resolver
/// behaviour so the persisted `goal_*_history` JSON shape continues to
/// drive identical backfill outcomes.
@immutable
class PlayerGoal {
  const PlayerGoal({
    required this.metric,
    required this.target,
    this.history = const [],
  });

  final GoalMetric metric;
  final double target;
  final List<GoalRevision> history;

  static DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Target effective on [effectiveDay], looked up against [history].
  double resolveForDate(DateTime effectiveDay) {
    if (history.isEmpty) return target;
    final normalized = _normalize(effectiveDay);
    GoalRevision? match;
    for (final entry in history) {
      final entryDay = entry.effectiveFrom;
      if (entryDay.isAfter(normalized)) break;
      match = entry;
    }
    return match?.value ?? history.first.value;
  }

  /// Returns a new [PlayerGoal] whose current [target] is [value] and
  /// whose [history] contains a revision at [effectiveFrom] (replacing
  /// any pre-existing revision on the same calendar day).
  PlayerGoal withRevision({
    required DateTime effectiveFrom,
    required double value,
  }) {
    final normalized = _normalize(effectiveFrom);
    final next = history
        .where((entry) => entry.effectiveFrom != normalized)
        .toList()
      ..add(GoalRevision(effectiveFrom: normalized, value: value))
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    return PlayerGoal(metric: metric, target: value, history: next);
  }

  /// If [resolveForDate]([anchor]) already equals [currentValue] this
  /// is a no-op (returns `this`). Otherwise rewrites/appends a
  /// revision at [anchor] so backfill resolution returns
  /// [currentValue] for [anchor] and later days.
  ///
  /// Used by [GoalBoard.hydrate] to fix up stale future-dated history
  /// rows on app start (matches the pre-extraction `_ensureRevisionForAnchor`).
  PlayerGoal ensureRevisionAt({
    required DateTime anchor,
    required double currentValue,
  }) {
    final resolved = resolveForDate(anchor);
    if (resolved == currentValue) return this;
    return withRevision(effectiveFrom: anchor, value: currentValue);
  }

  /// Stable order-sensitive string fingerprint of [history]. Consumers
  /// (e.g. `ProgressionProvider.signature`) include this in their
  /// own signature so they invalidate caches when the user edits a
  /// goal.
  String get historySignature => history
      .map((entry) =>
          '${entry.effectiveFrom.toIso8601String()}:${entry.value}')
      .join(',');

  PlayerGoal copyWith({
    GoalMetric? metric,
    double? target,
    List<GoalRevision>? history,
  }) {
    return PlayerGoal(
      metric: metric ?? this.metric,
      target: target ?? this.target,
      history: history ?? this.history,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlayerGoal) return false;
    if (other.metric != metric || other.target != target) return false;
    if (other.history.length != history.length) return false;
    for (var i = 0; i < history.length; i++) {
      if (other.history[i] != history[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        metric,
        target,
        Object.hashAll(history),
      );

  @override
  String toString() =>
      'PlayerGoal(metric: $metric, target: $target, '
      'history: ${history.length} revisions)';
}
