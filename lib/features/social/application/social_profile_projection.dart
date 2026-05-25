import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/journal/journal_projection.dart';

import '../../../core/logging/app_log.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart'
    show Achievement;
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart'
    show ProgressionDomain;
import '../domain/social_models.dart';
import '../domain/social_presence_repository.dart';

const _log = AppLogger('SOCIAL', scope: 'profileProjection');

/// Bundle of canonical inputs the projection denormalises into a
/// [SocialProfileSyncPayload].
///
/// Carried as a value object so the projection has a single argument
/// boundary; `SocialProvider` assembles one from its bound providers
/// on each publish attempt.
class SocialProfileInputs {
  const SocialProfileInputs({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.handle,
    required this.photoUrl,
    required this.raceId,
    required this.socialEnabled,
    required this.engine,
    required this.equippedCosmetics,
    this.fitness,
    this.nutrition,
    this.cosmetics,
  });

  final String uid;
  final String displayName;
  final String email;
  final String handle;
  final String? photoUrl;
  final String? raceId;
  final bool socialEnabled;
  final ProgressionEngineProvider engine;
  final SocialEquippedCosmetics equippedCosmetics;

  /// Optional source for activity / sleep / body stats. Null until the
  /// owning [SocialProvider] is bound to a `FitnessProvider`; while
  /// null, the projection leaves those wire fields unset (rendered as
  /// `—` on friend profiles).
  final FitnessProvider? fitness;

  /// Optional source for nutrition averages.
  final KalorickeTabulkyProvider? nutrition;

  /// Optional source for the unlocked-cosmetics count.
  final CosmeticsProvider? cosmetics;
}

typedef SocialProfileInputsGetter = SocialProfileInputs? Function();

/// Phase-20 projection that rebuilds the Firestore `SocialUserProfile`
/// row from the canonical Player + Loadout + Journal state.
///
/// **Why a projection.** The Firestore profile is a denormalised cache
/// — every field can be re-derived from Player aggregate +
/// [JournalEvent]s. Promoting the build path into a
/// [JournalProjection] (per `docs/domain_model/migration_plan.md`
/// Â§Phase 20) gives this cache rebuild the same documented contract as
/// the cosmetics inventory replay.
///
/// **Wire format frozen.** Phase 17 explicitly forbade Firestore shape
/// changes; this class therefore produces the exact same
/// [SocialProfileSyncPayload] the previous inline `_buildSyncPayload`
/// in `SocialProvider` did. Tests asserting Firestore wire format
/// stay green.
///
/// **Incremental vs. rebuild paths.** Both share the same projection
/// math:
///
/// * Incremental — `SocialProvider._syncProfileIfNeeded` does
///   signature-debounced publishes after every relevant state change.
///   It calls [publishIfReady] directly.
/// * Rebuild — explicit triggers (factory reset, cloud
///   pull-and-merge, devtools "republish") call [rebuildFromJournal]
///   which delegates to the same publish path. Today the only wired
///   trigger is the incremental path (the engine pull-and-merge
///   already mutates state that the signature picks up); having the
///   `JournalProjection` hook exposed means a future explicit
///   "republish my profile from scratch" affordance lands here
///   without restructuring the provider.
class SocialProfileProjection
    implements JournalProjection<SocialProfileSyncPayload?> {
  SocialProfileProjection({
    required SocialPresenceRepository repository,
    required SocialProfileInputsGetter inputsGetter,
  })  : _repository = repository,
        _inputsGetter = inputsGetter;

  final SocialPresenceRepository _repository;
  final SocialProfileInputsGetter _inputsGetter;

  /// Build + upsert the profile row when [_inputsGetter] returns a
  /// usable bundle. Returns the published payload, or null when
  /// inputs aren't ready (no signed-in user, social disabled,
  /// providers not yet bound).
  ///
  /// Throws whatever [SocialPresenceRepository.upsertProfile] throws —
  /// the caller (`SocialProvider`) translates the error for the UI.
  Future<SocialProfileSyncPayload?> publishIfReady() async {
    final payload = buildPayload();
    if (payload == null) return null;
    await _repository.upsertProfile(payload);
    return payload;
  }

  /// Pure projection — same inputs → same output, no IO.
  SocialProfileSyncPayload? buildPayload() {
    final inputs = _inputsGetter();
    if (inputs == null) return null;

    final unlockedAchievements = _buildUnlockedAchievementsFromEngine(inputs.engine);
    final personal = _buildPersonalMetrics(inputs);

    return SocialProfileSyncPayload(
      uid: inputs.uid,
      displayName: inputs.displayName,
      email: inputs.email,
      handle: inputs.handle,
      photoUrl: inputs.photoUrl,
      raceId: inputs.raceId,
      socialEnabled: inputs.socialEnabled,
      stats: SocialUserStats(
        level: inputs.engine.profile.level,
        totalXp: inputs.engine.profile.totalXp,
        unlockedAchievementCount: unlockedAchievements.length,
        grantedRewardCount: _grantedRewardCount(inputs.engine),
        bestStepsStreak:
            inputs.engine.streakForObjective('daily_steps').bestStreak,
        bestNutritionStreak: inputs.engine
            .streakForDomain(ProgressionDomain.nutrition)
            .bestStreak,
        updatedAt: inputs.engine.lastEvaluatedAt ?? DateTime.now(),
        stepsLifetime: personal.stepsLifetime,
        stepsAvg30d: personal.stepsAvg30d,
        activeDays30d: personal.activeDays30d,
        avgSleepMinutes7d: personal.avgSleepMinutes7d,
        avgBedtimeMinutes7d: personal.avgBedtimeMinutes7d,
        avgWakeMinutes7d: personal.avgWakeMinutes7d,
        avgDeepMinutes7d: personal.avgDeepMinutes7d,
        avgRemMinutes7d: personal.avgRemMinutes7d,
        latestWeightKg: personal.latestWeightKg,
        latestBodyFatPct: personal.latestBodyFatPct,
        avgKcal7d: personal.avgKcal7d,
        avgProteinG7d: personal.avgProteinG7d,
        avgFatG7d: personal.avgFatG7d,
        avgCarbsG7d: personal.avgCarbsG7d,
        cosmeticsUnlocked: personal.cosmeticsUnlocked,
      ),
      unlockedAchievements: unlockedAchievements,
      equippedCosmetics: inputs.equippedCosmetics,
    );
  }

  /// Pulls the personal-metric snapshot from the optional fitness +
  /// nutrition providers. Every field is nullable — when a source is
  /// unbound (e.g. boot path before fitness is wired) the
  /// corresponding wire fields stay null and friend devices render
  /// `—` for those rows until the next publish carries the data.
  static _PersonalMetrics _buildPersonalMetrics(SocialProfileInputs inputs) {
    final fitness = inputs.fitness;
    final kt = inputs.nutrition;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int? stepsLifetime;
    int? stepsAvg30d;
    int? activeDays30d;
    int? avgSleepMinutes7d;
    int? avgBedtimeMinutes7d;
    int? avgWakeMinutes7d;
    int? avgDeepMinutes7d;
    int? avgRemMinutes7d;
    double? latestWeightKg;
    double? latestBodyFatPct;

    if (fitness != null) {
      final activityStart30 = today.subtract(const Duration(days: 29));
      var lifetime = 0;
      var active = 0;
      for (final r in fitness.stepsHistory) {
        lifetime += r.steps;
        if (!r.date.isBefore(activityStart30) &&
            !r.date.isAfter(today) &&
            r.steps > 0) {
          active++;
        }
      }
      stepsLifetime = lifetime;
      stepsAvg30d = fitness.stepsAvgForRange(activityStart30, today).round();
      activeDays30d = active;

      final sleepStart7 = today.subtract(const Duration(days: 6));
      avgSleepMinutes7d =
          fitness.avgSleepForRange(sleepStart7, today)?.inMinutes;

      final bedtimeMinutes = <int>[];
      final wakeMinutes = <int>[];
      var deepSum = 0;
      var remSum = 0;
      var nightsWithStage = 0;
      for (final r in fitness.sleepHistory) {
        if (r.wakeTime.isBefore(sleepStart7) || r.sleepStart.isAfter(today)) {
          continue;
        }
        // Bedtime → minutes since midnight, with bedtimes before
        // noon shifted forward 24h to keep the average meaningful
        // when nights cross midnight.
        final bedRefMin = r.sleepStart.hour * 60 + r.sleepStart.minute;
        bedtimeMinutes
            .add(bedRefMin < 12 * 60 ? bedRefMin + 24 * 60 : bedRefMin);
        wakeMinutes.add(r.wakeTime.hour * 60 + r.wakeTime.minute);
        if (r.hasStageData) {
          nightsWithStage++;
          deepSum += r.deepDuration.inMinutes;
          remSum += r.remDuration.inMinutes;
        }
      }
      if (bedtimeMinutes.isNotEmpty) {
        final avg =
            bedtimeMinutes.reduce((a, b) => a + b) ~/ bedtimeMinutes.length;
        avgBedtimeMinutes7d = avg % (24 * 60);
      }
      if (wakeMinutes.isNotEmpty) {
        avgWakeMinutes7d =
            wakeMinutes.reduce((a, b) => a + b) ~/ wakeMinutes.length;
      }
      if (nightsWithStage > 0) {
        avgDeepMinutes7d = deepSum ~/ nightsWithStage;
        avgRemMinutes7d = remSum ~/ nightsWithStage;
      }

      latestWeightKg = fitness.latestWeight;
      latestBodyFatPct = fitness.latestBodyFat;
    }

    double? avgKcal7d;
    double? avgProteinG7d;
    double? avgFatG7d;
    double? avgCarbsG7d;
    if (kt != null) {
      final nutritionStart = today.subtract(const Duration(days: 6));
      final summary = kt.nutritionSummaryForRange(nutritionStart, today);
      if (summary != null) {
        avgKcal7d = summary.calories;
        avgProteinG7d = summary.protein;
        avgFatG7d = summary.fat;
        avgCarbsG7d = summary.carbs;
      }
    }

    return _PersonalMetrics(
      stepsLifetime: stepsLifetime,
      stepsAvg30d: stepsAvg30d,
      activeDays30d: activeDays30d,
      avgSleepMinutes7d: avgSleepMinutes7d,
      avgBedtimeMinutes7d: avgBedtimeMinutes7d,
      avgWakeMinutes7d: avgWakeMinutes7d,
      avgDeepMinutes7d: avgDeepMinutes7d,
      avgRemMinutes7d: avgRemMinutes7d,
      latestWeightKg: latestWeightKg,
      latestBodyFatPct: latestBodyFatPct,
      avgKcal7d: avgKcal7d,
      avgProteinG7d: avgProteinG7d,
      avgFatG7d: avgFatG7d,
      avgCarbsG7d: avgCarbsG7d,
      cosmeticsUnlocked: inputs.cosmetics?.state?.unlocked.length,
    );
  }

  @override
  Future<SocialProfileSyncPayload?> rebuildFromJournal({
    required Iterable<JournalEvent> events,
    required RebuildFromJournalReason reason,
  }) async {
    _log.info('rebuildFromJournal', payload: 'reason=${reason.name}');
    // Inputs are sourced from the bound providers (engine, auth,
    // cosmetics) rather than re-derived from [events]. The engine's
    // own `ledger` field already mirrors the journal after the
    // pull-and-merge call site that fronts this method, so reading
    // through the engine getter gives the same answer as walking the
    // events parameter — and matches the [publishIfReady] path
    // exactly. The parameter remains part of the contract so the
    // interface stays uniform with cosmetics replay.
    return publishIfReady();
  }

  /// Builds the cloud-snapshot achievement list from the V2 ledger +
  /// catalog. The published `rarity` field is the shared [Rarity] enum
  /// (`rarity.name` on the wire); receivers with the achievement id in
  /// their local catalog still resolve display through the V2 display
  /// resolver — the cloud-side rarity is the unknown-id colour fallback.
  static List<SocialUnlockedAchievement> _buildUnlockedAchievementsFromEngine(
    ProgressionEngineProvider engine,
  ) {
    final ledger = engine.ledger;
    if (ledger == null) return const [];

    final latestByNode = <String, DateTime>{};
    final nodes = <String, Achievement>{};
    for (final e in ledger.nodeCompletions) {
      final node = engine.nodeById(e.nodeId);
      if (node is! Achievement) continue;
      nodes[e.nodeId] = node;
      final existing = latestByNode[e.nodeId];
      if (existing == null || e.timestamp.isAfter(existing)) {
        latestByNode[e.nodeId] = e.timestamp;
      }
    }
    if (latestByNode.isEmpty) return const [];

    return [
      for (final entry in latestByNode.entries)
        SocialUnlockedAchievement(
          achievementId: entry.key,
          title: entry.key,
          description: '',
          rarity: nodes[entry.key]!.rarity,
          domain: engine.domainForNodeId(entry.key).name,
          unlockedAt: entry.value,
        ),
    ];
  }

  /// Total XP grant rows in the V2 ledger. V2 grants rewards
  /// immediately at evaluation time — there is no claimed vs pending
  /// split, so this single number stands in for both legacy counters.
  static int _grantedRewardCount(ProgressionEngineProvider engine) {
    final ledger = engine.ledger;
    if (ledger == null) return 0;
    var count = 0;
    for (final g in ledger.rewardGrants) {
      if (g.rewardKind == RewardGrantKind.xp) count++;
    }
    return count;
  }
}

class _PersonalMetrics {
  const _PersonalMetrics({
    required this.stepsLifetime,
    required this.stepsAvg30d,
    required this.activeDays30d,
    required this.avgSleepMinutes7d,
    required this.avgBedtimeMinutes7d,
    required this.avgWakeMinutes7d,
    required this.avgDeepMinutes7d,
    required this.avgRemMinutes7d,
    required this.latestWeightKg,
    required this.latestBodyFatPct,
    required this.avgKcal7d,
    required this.avgProteinG7d,
    required this.avgFatG7d,
    required this.avgCarbsG7d,
    required this.cosmeticsUnlocked,
  });

  final int? stepsLifetime;
  final int? stepsAvg30d;
  final int? activeDays30d;
  final int? avgSleepMinutes7d;
  final int? avgBedtimeMinutes7d;
  final int? avgWakeMinutes7d;
  final int? avgDeepMinutes7d;
  final int? avgRemMinutes7d;
  final double? latestWeightKg;
  final double? latestBodyFatPct;
  final double? avgKcal7d;
  final double? avgProteinG7d;
  final double? avgFatG7d;
  final double? avgCarbsG7d;
  final int? cosmeticsUnlocked;
}
