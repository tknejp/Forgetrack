/// Catalog of profile-stat keys persisted in
/// [SocialUserProfile.hiddenStatKeys].
///
/// Each [ProfileStatDescriptor] documents the user-facing identity of
/// one stat row on the profile screen: which card it belongs to, what
/// the default visibility is when the user has never toggled it, and
/// whether the wire format carries the data for foreign profiles.
///
/// Keys are stable strings — renaming one is a breaking change for
/// every user who has it in their saved blacklist. New stats land here
/// with `defaultHidden: true` if they could leak sensitive information
/// (weight, kcal, body fat), so they are opt-in to publish.
library;

/// Logical grouping → card.
enum ProfileStatCategory {
  /// Level, total XP, achievements, rewards, cosmetics, days on app.
  hero,

  /// Per-domain current + best streak records. Card-level visibility
  /// via the single `streaks.allRecords` key.
  streaks,

  /// Lifetime steps + averages + active days.
  activity,

  /// Avg sleep duration, bedtime, wake, stage breakdown.
  sleep,

  /// Sensitive — weight, body fat.
  body,

  /// Sensitive — avg kcal + macros.
  nutrition,

  /// Friend count, shared posts, join date.
  social,
}

/// Single entry in [profileStatCatalog].
class ProfileStatDescriptor {
  const ProfileStatDescriptor({
    required this.key,
    required this.category,
    this.defaultHidden = false,
    this.ownerOnly = false,
  });

  /// Stable identifier. Stored on the wire in `hiddenStatKeys`. Never
  /// rename without a migration.
  final String key;

  final ProfileStatCategory category;

  /// When the user has not explicitly chosen visibility, foreign-
  /// profile viewers see this stat only if `defaultHidden == false`.
  /// Sensitive metrics (weight, kcal, body fat) set this to true so
  /// they are opt-in to publish.
  final bool defaultHidden;

  /// V1 escape hatch: when true, the stat row never renders on a
  /// foreign profile regardless of [defaultHidden] / blacklist state
  /// because the wire format does not carry the underlying data.
  /// Lift this flag once the wire schema grows the corresponding
  /// fields.
  final bool ownerOnly;
}

/// All profile stat keys the UI knows about.
///
/// Order is irrelevant for visibility logic but matters for the
/// rendering pass — sections iterate the catalog and skip rows that
/// fall outside their category. The per-card row order is decided by
/// the [ProfileStatsSection] widget, not by this list.
const List<ProfileStatDescriptor> profileStatCatalog = [
  // ── Hero card ─────────────────────────────────────────────────────
  ProfileStatDescriptor(
    key: 'hero.level',
    category: ProfileStatCategory.hero,
  ),
  ProfileStatDescriptor(
    key: 'hero.totalXp',
    category: ProfileStatCategory.hero,
  ),
  ProfileStatDescriptor(
    key: 'hero.unlockedAchievements',
    category: ProfileStatCategory.hero,
  ),
  ProfileStatDescriptor(
    key: 'hero.grantedRewards',
    category: ProfileStatCategory.hero,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'hero.cosmeticsUnlocked',
    category: ProfileStatCategory.hero,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'hero.daysOnApp',
    category: ProfileStatCategory.hero,
  ),

  // ── Streak records (single-key card-level visibility) ─────────────
  //
  // The streak records card is per-domain dense (current + best for 5
  // domains) and per-row toggling would clutter it for no gain — the
  // streaks tell a single coherent story. One key gates the whole
  // card on foreign profiles.
  ProfileStatDescriptor(
    key: 'streaks.allRecords',
    category: ProfileStatCategory.streaks,
  ),

  // ── Activity card ─────────────────────────────────────────────────
  ProfileStatDescriptor(
    key: 'activity.stepsLifetime',
    category: ProfileStatCategory.activity,
  ),
  ProfileStatDescriptor(
    key: 'activity.stepsAvg30d',
    category: ProfileStatCategory.activity,
  ),
  ProfileStatDescriptor(
    key: 'activity.activeDays30d',
    category: ProfileStatCategory.activity,
  ),

  // ── Sleep card (own-profile only V1, default-hidden) ─────────────
  ProfileStatDescriptor(
    key: 'sleep.avgDuration7d',
    category: ProfileStatCategory.sleep,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'sleep.avgBedtime7d',
    category: ProfileStatCategory.sleep,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'sleep.avgWakeTime7d',
    category: ProfileStatCategory.sleep,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'sleep.avgDeep7d',
    category: ProfileStatCategory.sleep,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'sleep.avgRem7d',
    category: ProfileStatCategory.sleep,
    defaultHidden: true,
  ),

  // ── Body card (sensitive, own-profile only V1) ───────────────────
  ProfileStatDescriptor(
    key: 'body.latestWeight',
    category: ProfileStatCategory.body,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'body.latestBodyFat',
    category: ProfileStatCategory.body,
    defaultHidden: true,
  ),

  // ── Nutrition card (sensitive, own-profile only V1) ──────────────
  ProfileStatDescriptor(
    key: 'nutrition.avgKcal7d',
    category: ProfileStatCategory.nutrition,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'nutrition.avgProtein7d',
    category: ProfileStatCategory.nutrition,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'nutrition.avgFat7d',
    category: ProfileStatCategory.nutrition,
    defaultHidden: true,
  ),
  ProfileStatDescriptor(
    key: 'nutrition.avgCarbs7d',
    category: ProfileStatCategory.nutrition,
    defaultHidden: true,
  ),

  // ── Social card ──────────────────────────────────────────────────
  ProfileStatDescriptor(
    key: 'social.friendsCount',
    category: ProfileStatCategory.social,
  ),
  ProfileStatDescriptor(
    key: 'social.sharedPostsCount',
    category: ProfileStatCategory.social,
  ),
  ProfileStatDescriptor(
    key: 'social.joinedAt',
    category: ProfileStatCategory.social,
  ),
];

ProfileStatDescriptor? profileStatDescriptorByKey(String key) {
  for (final entry in profileStatCatalog) {
    if (entry.key == key) return entry;
  }
  return null;
}

/// Whether a foreign-profile viewer should see the row for [key].
///
/// Owner profiles always see every row — this resolver is the only
/// gate for foreign viewers. The owner's edit-mode UI shows
/// foreign-hidden rows with a muted lock badge, never filters them
/// out for the owner themselves.
///
/// Override semantics (XOR): membership in [statVisibilityOverrides]
/// means the user has chosen the OPPOSITE of the catalog default.
/// So a default-visible stat in the set is hidden from foreigners,
/// and a default-hidden stat in the set is published to foreigners.
bool isStatVisibleForViewer({
  required String key,
  required Set<String> statVisibilityOverrides,
  required bool isOwner,
}) {
  if (isOwner) return true;

  final descriptor = profileStatDescriptorByKey(key);
  if (descriptor == null) return false;

  // Owner-only stats are not in the wire format yet — never render on
  // foreign profiles regardless of the override set.
  if (descriptor.ownerOnly) return false;

  final defaultVisible = !descriptor.defaultHidden;
  final overridden = statVisibilityOverrides.contains(key);
  // XOR: visible iff default differs from override flag.
  return defaultVisible != overridden;
}
