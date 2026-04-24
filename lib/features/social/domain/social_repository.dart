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

  Future<void> replaceUnlockedAchievements({
    required String uid,
    required List<SocialUnlockedAchievement> achievements,
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

  Stream<List<SocialUnlockedAchievement>> watchUnlockedAchievements(String uid);

  Future<List<SocialUnlockedAchievement>> fetchUnlockedAchievements(String uid);

  Future<void> removeFriend({required String friendshipId});
}
