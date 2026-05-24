import 'package:forgetrack/domain/journal/journal_event.dart';
import 'package:forgetrack/domain/journal/journal_projection.dart';

import '../../../core/logging/app_log.dart';
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
      ),
      unlockedAchievements: unlockedAchievements,
      equippedCosmetics: inputs.equippedCosmetics,
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
