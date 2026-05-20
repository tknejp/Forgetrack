import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/logging/app_log.dart';
import '../domain/player_goal.dart';

/// Cloud gateway for per-metric goal revision histories.
///
/// Firestore layout:
///   `users/{uid}/goal_history/{metricName}`
///   Doc: `{ revisions: [{target: double, effectiveAt: Timestamp}],
///           updatedAt: Timestamp }`
///
/// One document per metric, one doc-write per goal change. With 8
/// tracked metrics and ~1 change per week per metric this is well
/// within Firestore free-tier limits.
///
/// **Anti-cheat role.** Firestore holds the server-truth revision
/// timeline. A player who lowers their goal locally still has the
/// original history in the cloud, so any future server-side
/// validation (leaderboards, streak certification) can read the
/// authoritative target for each calendar day.
class GoalHistoryFirestoreGateway {
  GoalHistoryFirestoreGateway({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'goal_history';

  // GoalMetric.targetWeight has no history — excluded from sync.
  static const Set<GoalMetric> syncedMetrics = {
    GoalMetric.dailySteps,
    GoalMetric.dailyCalories,
    GoalMetric.dailyProtein,
    GoalMetric.dailyFat,
    GoalMetric.dailyCarbs,
    GoalMetric.dailyFiber,
    GoalMetric.sleepHours,
    GoalMetric.weeklyActivityMins,
    GoalMetric.dailyActivityMins,
  };

  // ── Push ─────────────────────────────────────────────────────────

  /// Pushes [revisions] for [metric] to Firestore. Best-effort —
  /// network errors are logged and swallowed so a Firestore outage
  /// never blocks a local goal change.
  Future<void> pushRevisions(
    String uid,
    GoalMetric metric,
    List<GoalRevision> revisions,
  ) async {
    if (uid.isEmpty || !syncedMetrics.contains(metric)) return;
    try {
      final ref = _docRef(uid, metric);
      await ref.set({
        'revisions': [for (final r in revisions) _revisionToMap(r)],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLog.sync.debug(
        'goals: synced ${revisions.length} revisions for metric=${metric.name}',
      );
    } catch (e) {
      AppLog.sync.warn(
        'goals: push failed for metric=${metric.name}',
        payload: e.toString(),
      );
    }
  }

  /// First-time migration: pushes the entire local history for every
  /// metric in a single batch. Idempotent — re-running overwrites
  /// with the same data.
  Future<void> seedAllRevisions(
    String uid,
    Map<GoalMetric, List<GoalRevision>> allRevisions,
  ) async {
    if (uid.isEmpty) return;
    final batch = _firestore.batch();
    var count = 0;
    for (final metric in syncedMetrics) {
      final revisions = allRevisions[metric];
      if (revisions == null || revisions.isEmpty) continue;
      batch.set(_docRef(uid, metric), {
        'revisions': [for (final r in revisions) _revisionToMap(r)],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      count += revisions.length;
    }
    try {
      await batch.commit();
      AppLog.sync.info(
        'goals: seeded $count revisions for uid=$uid',
      );
    } catch (e) {
      AppLog.sync.warn('goals: seed failed', payload: e.toString());
    }
  }

  // ── Pull ─────────────────────────────────────────────────────────

  /// Pulls all goal_history docs for [uid]. Returns an empty map when
  /// the user has no cloud history (new account / no prior sync).
  Future<Map<GoalMetric, List<GoalRevision>>> pullRevisions(String uid) async {
    if (uid.isEmpty) return {};
    try {
      final futures = {
        for (final m in syncedMetrics) m: _docRef(uid, m).get(),
      };
      final result = <GoalMetric, List<GoalRevision>>{};
      for (final entry in futures.entries) {
        final snap = await entry.value;
        if (!snap.exists) continue;
        final data = snap.data();
        if (data == null) continue;
        final revisions = _revisionsFromMap(data);
        if (revisions.isNotEmpty) result[entry.key] = revisions;
      }
      final total = result.values.fold(0, (s, l) => s + l.length);
      AppLog.sync.info(
        'goals: pulled $total revisions for uid=$uid',
      );
      return result;
    } catch (e) {
      AppLog.sync.warn('goals: pull failed', payload: e.toString());
      return {};
    }
  }

  // ── Merge (pure, testable) ────────────────────────────────────────

  /// Merges [local] and [cloud] revision lists. Union by
  /// `effectiveFrom` date; on same-day conflict the cloud entry wins
  /// (cloud is server truth). Returns a new sorted list.
  static List<GoalRevision> merge(
    List<GoalRevision> local,
    List<GoalRevision> cloud,
  ) {
    if (cloud.isEmpty) return List.of(local);
    if (local.isEmpty) return List.of(cloud);

    final byDate = <DateTime, GoalRevision>{};
    for (final r in local) {
      byDate[r.effectiveFrom] = r;
    }
    // Cloud overwrites local on same-date conflict.
    for (final r in cloud) {
      byDate[r.effectiveFrom] = r;
    }
    return byDate.values.toList()
      ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
  }

  // ── Helpers ───────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _docRef(
    String uid,
    GoalMetric metric,
  ) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection(_collection)
          .doc(metric.name);

  static Map<String, dynamic> _revisionToMap(GoalRevision r) => {
        'target': r.value,
        'effectiveAt': Timestamp.fromDate(r.effectiveFrom),
      };

  static List<GoalRevision> _revisionsFromMap(Map<String, dynamic> data) {
    final raw = data['revisions'];
    if (raw is! List) return [];
    final result = <GoalRevision>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final target = item['target'];
      final effectiveAt = item['effectiveAt'];
      if (target is! num) continue;
      DateTime? date;
      if (effectiveAt is Timestamp) {
        final d = effectiveAt.toDate();
        date = DateTime(d.year, d.month, d.day);
      } else if (effectiveAt is String) {
        date = DateTime.tryParse(effectiveAt);
        if (date != null) date = DateTime(date.year, date.month, date.day);
      }
      if (date == null) continue;
      result.add(GoalRevision(effectiveFrom: date, value: target.toDouble()));
    }
    result.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    return result;
  }
}
