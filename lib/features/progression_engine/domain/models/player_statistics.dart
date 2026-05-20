import 'package:meta/meta.dart';

import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import '../evaluator/engine_streak_source.dart';
import 'ledger_counters.dart';

/// Single, immutable entry point for **every statistical view** of
/// the local player. Wraps the two pre-existing aggregate sources —
/// per-domain [EngineStreakSummary] (current + best + last achieved)
/// and ledger-derived [LedgerCounters] (reward counts, distinct
/// active days, rolling windows, …) — behind one API so UI surfaces
/// stop reaching into `ProgressionEngineProvider` internals to fish
/// out individual map entries.
///
/// **Why it exists.** As `Trello #99` shipped, the stat surfaces on
/// the home screen, the quest screen, the hero profile and the
/// expanded-card info block each pulled per-metric numbers from
/// scattered provider getters (`currentStreakForDomain`,
/// `streakForDomain`, `ledgerCounters.bestStreakByDomain`, …). Adding
/// a new metric meant patching three or four widget consumers. This
/// value object centralises the read path so adding total XP, level
/// history, granted-reward tallies, or any future statistic is a
/// single-field change here + a single new consumer call.
///
/// **Cache, not source of truth.** The provider rebuilds a fresh
/// instance every time `_recomputeStreaks` runs. Callers should treat
/// it as a read-only snapshot — never store, never mutate, never
/// derive cross-snapshot deltas (engine pipeline owns ordering).
///
/// **Not on the Firestore wire.** Friend profiles continue to use
/// the lean `SocialUserStats` projection. `PlayerStatistics` is a
/// device-local API; cloud sync is intentionally out of scope (the
/// upcoming `JournalProjection` phase is the right home for any
/// future cloud-side stat materialisation — see ADR
/// `player-statistics-value-object`).
@immutable
class PlayerStatistics {
  const PlayerStatistics({
    required this.streaksByDomain,
    required this.counters,
    this.totalXp = 0,
    this.level = 1,
  });

  /// Sentinel "no data" snapshot — used by the provider before the
  /// first hydration completes so widgets stay null-safe without a
  /// `?` guard at every call site.
  static const PlayerStatistics empty = PlayerStatistics(
    streaksByDomain: <ProgressionDomain, EngineStreakSummary>{},
    counters: LedgerCounters.empty,
  );

  /// Per-domain streak summary. Missing domains read as
  /// [EngineStreakSummary.empty] through [streakFor].
  final Map<ProgressionDomain, EngineStreakSummary> streaksByDomain;

  /// Full ledger-derived counter bundle. Surfaced as-is so callers
  /// reaching for `bestRollingStepsByDays` etc. don't need a second
  /// provider read.
  final LedgerCounters counters;

  /// Player's lifetime XP at the time this snapshot was built.
  /// Mirrors `EngineProfile.totalXp` so a single read covers both
  /// "where am I in the level curve" and "what's my streak record".
  final int totalXp;

  /// Player's level at the time this snapshot was built. Same source
  /// as [totalXp].
  final int level;

  /// Returns the streak summary for [domain], falling back to an
  /// empty summary when the provider hasn't computed one yet (e.g.
  /// the player has no daily-scoped objectives for that domain in
  /// the catalog). Read-only convenience so widgets never have to
  /// handle the missing-key case manually.
  EngineStreakSummary streakFor(ProgressionDomain domain) {
    return streaksByDomain[domain] ?? const EngineStreakSummary.empty();
  }

  /// Helper that mirrors the `_buildStats` shape the hero profile
  /// uses: current + best for every main domain. Callers map this
  /// into UI rows without re-implementing the lookup.
  List<DomainStreakStat> domainStreaks() {
    return [
      for (final domain in ProgressionDomain.values)
        DomainStreakStat(
          domain: domain,
          currentStreak: streakFor(domain).currentStreak,
          bestStreak: streakFor(domain).bestStreak,
          lastAchievedDate: streakFor(domain).lastAchievedDate,
        ),
    ];
  }
}

/// Flat per-domain projection of the two streak counts UI surfaces
/// consume most often. Computed lazily by
/// [PlayerStatistics.domainStreaks] so widgets don't have to merge
/// `currentStreak` + `bestStreak` themselves.
@immutable
class DomainStreakStat {
  const DomainStreakStat({
    required this.domain,
    required this.currentStreak,
    required this.bestStreak,
    this.lastAchievedDate,
  });

  final ProgressionDomain domain;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastAchievedDate;
}
