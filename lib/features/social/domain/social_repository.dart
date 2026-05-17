import 'social_models.dart';

abstract class SocialRepository {
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
