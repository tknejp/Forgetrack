import '../domain/social_models.dart';
import '../domain/social_repository.dart';

class DisabledSocialRepository implements SocialRepository {
  const DisabledSocialRepository({
    required this.reason,
  });

  final String reason;

  @override
  Future<void> acceptFriendRequest({required String requestId}) {
    throw StateError(reason);
  }

  @override
  Future<void> declineFriendRequest({required String requestId}) {
    throw StateError(reason);
  }

  @override
  Future<List<SocialAchievementShare>> fetchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) async {
    return const [];
  }

  @override
  Stream<List<SocialAchievementShare>> watchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) {
    return Stream<List<SocialAchievementShare>>.value(const []);
  }

  @override
  Future<List<SocialUserProfile>> fetchProfilesByIds(
    Iterable<String> uids,
  ) async {
    return const [];
  }

  @override
  Future<void> replaceUnlockedAchievements({
    required String uid,
    required List<SocialUnlockedAchievement> achievements,
  }) {
    throw StateError(reason);
  }

  @override
  Future<List<SocialUserProfile>> searchProfilesByHandle(
    String query, {
    required String excludeUid,
    int limit = 8,
  }) async {
    return const [];
  }

  @override
  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) {
    throw StateError(reason);
  }

  @override
  Future<void> shareAchievement(SocialAchievementShare share) {
    throw StateError(reason);
  }

  @override
  Future<void> upsertProfile(SocialProfileSyncPayload payload) {
    throw StateError(reason);
  }

  @override
  Stream<List<SocialFriendRequest>> watchIncomingFriendRequests({
    required String uid,
  }) {
    return const Stream<List<SocialFriendRequest>>.empty();
  }

  @override
  Stream<List<SocialFriendship>> watchFriendships({required String uid}) {
    return const Stream<List<SocialFriendship>>.empty();
  }

  @override
  Stream<List<SocialUserProfile>> watchProfilesByIds(Iterable<String> uids) {
    return Stream<List<SocialUserProfile>>.value(const []);
  }

  @override
  Stream<List<SocialFriendRequest>> watchOutgoingFriendRequests({
    required String uid,
  }) {
    return const Stream<List<SocialFriendRequest>>.empty();
  }

  @override
  Stream<List<SocialUnlockedAchievement>> watchUnlockedAchievements(
      String uid) {
    return Stream<List<SocialUnlockedAchievement>>.value(const []);
  }

  @override
  Future<List<SocialUnlockedAchievement>> fetchUnlockedAchievements(
    String uid,
  ) async {
    return const [];
  }

  @override
  Future<void> removeFriend({required String friendshipId}) {
    throw StateError(reason);
  }

  @override
  Future<void> addReaction({
    required String shareId,
    required String actorUid,
    required String actorName,
    required String? actorPhoto,
    required String emoji,
    required String shareOwnerUid,
    required String achievementTitle,
  }) {
    throw StateError(reason);
  }

  @override
  Future<void> removeReaction({
    required String shareId,
    required String actorUid,
    required String shareOwnerUid,
  }) {
    throw StateError(reason);
  }

  @override
  Stream<List<SocialNotification>> watchNotifications(String uid) {
    return Stream<List<SocialNotification>>.value(const []);
  }

  @override
  Future<void> markNotificationsRead(String uid) async {}
}
