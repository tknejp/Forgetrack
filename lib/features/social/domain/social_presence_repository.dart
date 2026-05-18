import 'achievement_share.dart';
import 'friend_request.dart';
import 'friendship.dart';
import 'social_notification.dart';
import 'social_user_profile.dart';

/// Persistence contract for the [SocialPresence] aggregate.
///
/// Phase 17 of the domain refactor renamed `SocialRepository` →
/// `SocialPresenceRepository` to align with the per-aggregate naming
/// convention the proposal §2 ratified (`PlayerRepository`,
/// `InventoryRepository`, `JournalRepository`,
/// `SocialPresenceRepository`).
///
/// **Boundary contract.** Implementations read/write Firestore
/// subcollections (own profile, friend requests, friendships, shares,
/// reactions, notifications, engine node completions). The repo does
/// not interpret what it stores — it shuttles typed VOs across the
/// wire. Reaction / share / profile rebuilds are the provider's job.
///
/// **Firestore wire format is frozen.** Phase 17 explicitly does NOT
/// touch persistence semantics — every existing collection / document
/// / field stays as-is so cross-version clients keep reading the same
/// payloads. Rename is lexical at the Dart layer only.
abstract class SocialPresenceRepository {
  Stream<List<SocialFriendRequest>> watchIncomingFriendRequests({
    required String uid,
  });

  Stream<List<SocialFriendRequest>> watchOutgoingFriendRequests({
    required String uid,
  });

  Stream<List<SocialFriendship>> watchFriendships({
    required String uid,
  });

  Stream<List<SocialUserProfile>> watchProfilesByIds(Iterable<String> uids);

  Future<List<SocialUserProfile>> fetchProfilesByIds(Iterable<String> uids);

  Future<List<SocialUserProfile>> searchProfilesByHandle(
    String query, {
    required String excludeUid,
    int limit = 8,
  });

  Future<List<SocialAchievementShare>> fetchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  });

  Stream<List<SocialAchievementShare>> watchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  });

  Future<void> upsertProfile(SocialProfileSyncPayload payload);

  Future<String> updateProfileHandle({
    required String uid,
    required String desiredHandle,
  });

  Future<void> updateProfilePhotoUrl({
    required String uid,
    required String? photoUrl,
  });

  Future<void> updatePinnedAchievement({
    required String uid,
    required String achievementId,
    required bool pinned,
  });

  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  });

  Future<void> acceptFriendRequest({
    required String requestId,
  });

  Future<void> declineFriendRequest({
    required String requestId,
  });

  Future<void> shareAchievement(SocialAchievementShare share);

  /// Streams every node completion event in the user's V2 engine ledger.
  ///
  /// Used by `SocialProvider.watchFriendAchievements` which filters down
  /// to [Achievement] ids via the local progression catalog and
  /// builds [SocialUnlockedAchievement]s. Completion of non-achievement
  /// nodes (quests, milestones) is included in the stream — callers
  /// must filter.
  Stream<List<RemoteEngineNodeCompletion>> watchEngineNodeCompletions(
    String uid,
  );

  Future<List<RemoteEngineNodeCompletion>> fetchEngineNodeCompletions(
    String uid,
  );

  Future<void> removeFriend({required String friendshipId});

  Future<void> addReaction({
    required String shareId,
    required String actorUid,
    required String actorName,
    required String? actorPhoto,
    required String emoji,
    required String shareOwnerUid,
    required String achievementTitle,
  });

  Future<void> removeReaction({
    required String shareId,
    required String actorUid,
    required String shareOwnerUid,
  });

  Stream<List<SocialNotification>> watchNotifications(String uid);

  Future<void> markNotificationsRead(String uid);
}
