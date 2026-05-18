import '../../../shared/domain/rarity.dart';

enum SocialShareVisibility {
  friends,
}

class SocialAchievementActorSnapshot {
  const SocialAchievementActorSnapshot({
    required this.displayName,
    this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
}

class SocialAchievementSnapshot {
  const SocialAchievementSnapshot({
    required this.title,
    required this.description,
    required this.rarity,
    this.domain,
  });

  final String title;
  final String description;
  final Rarity rarity;
  final String? domain;
}

class SocialReactionSnapshot {
  const SocialReactionSnapshot({required this.displayName, this.photoUrl});
  final String displayName;
  final String? photoUrl;
}

class SocialAchievementShare {
  const SocialAchievementShare({
    required this.id,
    required this.actorUid,
    required this.achievementId,
    required this.createdAt,
    required this.visibility,
    required this.actorSnapshot,
    required this.achievementSnapshot,
    this.message,
    this.reactions = const {},
    this.reactorSnapshots = const {},
  });

  final String id;
  final String actorUid;
  final String achievementId;
  final DateTime createdAt;
  final String? message;
  final SocialShareVisibility visibility;
  final SocialAchievementActorSnapshot actorSnapshot;
  final SocialAchievementSnapshot achievementSnapshot;

  /// uid → emoji
  final Map<String, String> reactions;

  /// uid → snapshot
  final Map<String, SocialReactionSnapshot> reactorSnapshots;
}

class SocialUnlockedAchievement {
  const SocialUnlockedAchievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.rarity,
    required this.unlockedAt,
    this.domain,
  });

  final String achievementId;
  final String title;
  final String description;
  final Rarity rarity;
  final String? domain;
  final DateTime unlockedAt;
}

/// Raw row read from `users/{uid}/engineNodeCompletions/{eventKey}`.
///
/// The repo returns these untyped — `SocialProvider` filters down to
/// Achievements and resolves rarity / domain via the local
/// progression catalog when building [SocialUnlockedAchievement] for
/// the friend-profile view. Keeping the catalog lookup in the
/// application layer means the repo stays Firestore-only and doesn't
/// import progression engine domain types.
class RemoteEngineNodeCompletion {
  const RemoteEngineNodeCompletion({
    required this.nodeId,
    required this.completedAt,
    this.periodKey,
  });

  final String nodeId;
  final DateTime completedAt;
  final String? periodKey;
}
