import 'achievement_share.dart';

/// Denormalised per-user statistics mirrored from the Player
/// aggregate + Journal counters into Firestore for fast friend-list
/// rendering.
///
/// **Cache, not source of truth.** Phase 17 of the domain refactor
/// documents this explicitly (`docs/domain_model/proposal.md` §5):
/// every field here can be re-derived from the canonical Player
/// aggregate (`level`, `totalXp`) + the engine's ledger
/// (`unlockedAchievementCount`, `grantedRewardCount`, streaks). The
/// Firestore row exists only because friends' tabs need a single
/// document read per friend — pulling the full ledger over the
/// network on every render would be prohibitive.
///
/// **Rebuild trigger.** Any time the local Player or Journal mutates
/// (claim, level-up, streak roll), `SocialProvider.publishProfile`
/// pushes a fresh snapshot. Phase 20 (`JournalProjection`) will
/// promote this into a first-class projection so the rebuild happens
/// via a documented contract rather than ad-hoc.
class SocialUserStats {
  const SocialUserStats({
    required this.level,
    required this.totalXp,
    required this.unlockedAchievementCount,
    required this.grantedRewardCount,
    required this.bestStepsStreak,
    required this.bestNutritionStreak,
    this.updatedAt,
    this.stepsLifetime,
    this.stepsAvg30d,
    this.activeDays30d,
    this.avgSleepMinutes7d,
    this.avgBedtimeMinutes7d,
    this.avgWakeMinutes7d,
    this.avgDeepMinutes7d,
    this.avgRemMinutes7d,
    this.latestWeightKg,
    this.latestBodyFatPct,
    this.avgKcal7d,
    this.avgProteinG7d,
    this.avgFatG7d,
    this.avgCarbsG7d,
    this.cosmeticsUnlocked,
  });

  final int level;
  final int totalXp;
  final int unlockedAchievementCount;

  /// Total reward grants in the engine ledger. V2 grants rewards
  /// immediately at evaluation time, so there is no claimed/pending
  /// split — every grant is by definition granted.
  final int grantedRewardCount;
  final int bestStepsStreak;
  final int bestNutritionStreak;
  final DateTime? updatedAt;

  // ── Personal-metric cache (nullable on the wire). ───────────────
  //
  // All entries are optional. A null value means the field is
  // unknown (the owner's device hasn't published yet) and renders
  // as `—` on friend profiles. Visibility for foreign viewers is
  // still gated by `SocialUserProfile.hiddenStatKeys` —
  // [profileStatCatalog] marks the sensitive ones default-hidden.

  final int? stepsLifetime;
  final int? stepsAvg30d;
  final int? activeDays30d;

  /// Average nightly sleep duration over the last 7 days, minutes.
  final int? avgSleepMinutes7d;

  /// Average bedtime in minutes-since-midnight over the last 7 days.
  /// Bedtimes before noon are normalised to the same 0–1440 range so
  /// the value renders as a 24-hour clock; sleep that crosses midnight
  /// is recorded as the actual bedtime minute (e.g. 23:30 → 1410).
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

  /// Total unlocked cosmetics count. Sourced from
  /// [CosmeticsProvider.state.unlocked] at publish time. Null when
  /// cosmetics provider isn't bound (first-publish race after a fresh
  /// install).
  final int? cosmeticsUnlocked;
}

/// Denormalised public-profile row published to Firestore for a
/// signed-in user.
///
/// **Cache, not source of truth.** Owned by the Social feature for
/// friend-discovery + leaderboard reads; rebuilt from Player + Loadout
/// + Inventory + Journal on every `SocialProvider.publishProfile`
/// call. Renaming or restructuring fields here is a Firestore wire-
/// format change — Phase 17 explicitly does NOT touch the shape.
class SocialUserProfile {
  const SocialUserProfile({
    required this.uid,
    required this.displayName,
    required this.handle,
    required this.email,
    required this.socialEnabled,
    required this.stats,
    this.photoUrl,
    this.raceId,
    this.createdAt,
    this.updatedAt,
    this.pinnedAchievementIds = const [],
    this.statVisibilityOverrides = const <String>{},
    this.equippedCosmetics = const SocialEquippedCosmetics.empty(),
    this.onboardingCompleted = false,
  });

  final String uid; // lint-ignore: untyped-id — Firebase Auth uid is a platform-boundary raw string
  final String displayName;
  final String handle;
  final String email;
  final String? photoUrl;

  /// HeroRace id picked at onboarding / force-pick. Null until the
  /// owning device has run the force-pick gate at least once and the
  /// projection has flushed. Friend renderers fall back to silhouette
  /// when null.
  final String? raceId;
  final bool socialEnabled;
  final SocialUserStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> pinnedAchievementIds;

  /// Per-stat visibility overrides for the profile stats section.
  ///
  /// Each entry is a stat key from `profileStatCatalog`. Semantics:
  /// **membership means the user's choice differs from the catalog's
  /// `defaultHidden`** — i.e. a default-visible stat in this set is
  /// hidden from foreign viewers, and a default-hidden stat in this
  /// set is published to foreign viewers. The resolver evaluates
  /// `defaultHidden XOR statVisibilityOverrides.contains(key)` to
  /// decide foreign-profile visibility.
  ///
  /// Override (not blacklist or whitelist) so the wire payload stays
  /// minimal when the user keeps the curated defaults, regardless of
  /// whether those defaults are visible or hidden.
  final Set<String> statVisibilityOverrides;

  final SocialEquippedCosmetics equippedCosmetics;

  /// Dev-facing marker stamped on `users/{uid}` once the owning device
  /// has cleared the welcome flow (written out-of-band by
  /// `markOnboardingCompleted`, preserved across projection re-publishes
  /// by `SetOptions(merge: true)`). Read by the onboarding flow on a
  /// fresh install / new device to detect a *returning* player — one who
  /// must NOT re-run the full welcome onboarding (no race re-pick, no
  /// welcome celebration), only a quick connection setup. Defaults to
  /// false when the field is absent (genuinely new player) or
  /// unreadable (offline / disabled backend).
  final bool onboardingCompleted;
}

/// Subset of [Loadout] (cosmetics feature) that is broadcast to
/// friends through the Firestore profile mirror. Kept as a separate
/// type because the Social feature does not import the cosmetics
/// catalog — only ids cross the network boundary.
class SocialEquippedCosmetics {
  const SocialEquippedCosmetics({
    this.frameId,
    this.relicId,
    this.backgroundId,
    this.emblemId,
    this.companionId,
    this.titleFlairId,
    this.mapEffectId,
    this.skinId,
    this.bannerId,
  });

  const SocialEquippedCosmetics.empty()
      : frameId = null,
        relicId = null,
        backgroundId = null,
        emblemId = null,
        companionId = null,
        titleFlairId = null,
        mapEffectId = null,
        skinId = null,
        bannerId = null;

  final String? frameId;
  final String? relicId;
  final String? backgroundId;
  final String? emblemId;
  final String? companionId;
  final String? titleFlairId;
  final String? mapEffectId;

  /// Equipped Skin id (race-agnostic catalog key). Combined with the
  /// owning [SocialUserProfile.raceId] at render time to resolve a
  /// per-race artwork path through `SkinAssetResolver`.
  final String? skinId;

  /// Equipped title banner id — the rarity-keyed asset painted behind
  /// the player's level + class title on the social profile header.
  /// When null, the profile derives the banner from the player's title
  /// tier rarity (see `ProfileTitleBanner`).
  final String? bannerId;

  bool get hasAny =>
      frameId != null ||
      relicId != null ||
      backgroundId != null ||
      emblemId != null ||
      companionId != null ||
      titleFlairId != null ||
      mapEffectId != null ||
      skinId != null ||
      bannerId != null;
}

/// Bundle the Social repository takes when pushing a fresh profile
/// snapshot to Firestore. Carries everything the wire format needs in
/// one immutable payload so the provider doesn't have to assemble
/// arguments at every call site.
class SocialProfileSyncPayload {
  const SocialProfileSyncPayload({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.handle,
    required this.photoUrl,
    required this.raceId,
    required this.socialEnabled,
    required this.stats,
    required this.unlockedAchievements,
    required this.equippedCosmetics,
  });

  final String uid; // lint-ignore: untyped-id — Firebase Auth uid is a platform-boundary raw string
  final String displayName;
  final String email;
  final String handle;
  final String? photoUrl;
  final String? raceId;
  final bool socialEnabled;
  final SocialUserStats stats;
  final List<SocialUnlockedAchievement> unlockedAchievements;
  final SocialEquippedCosmetics equippedCosmetics;

  SocialProfileSyncPayload copyWith({
    String? displayName,
    String? email,
    String? handle,
    Object? photoUrl = _unchanged,
    Object? raceId = _unchanged,
    bool? socialEnabled,
    SocialUserStats? stats,
    List<SocialUnlockedAchievement>? unlockedAchievements,
    SocialEquippedCosmetics? equippedCosmetics,
  }) {
    return SocialProfileSyncPayload(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      handle: handle ?? this.handle,
      photoUrl:
          identical(photoUrl, _unchanged) ? this.photoUrl : photoUrl as String?,
      raceId:
          identical(raceId, _unchanged) ? this.raceId : raceId as String?,
      socialEnabled: socialEnabled ?? this.socialEnabled,
      stats: stats ?? this.stats,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      equippedCosmetics: equippedCosmetics ?? this.equippedCosmetics,
    );
  }
}

const Object _unchanged = Object();
