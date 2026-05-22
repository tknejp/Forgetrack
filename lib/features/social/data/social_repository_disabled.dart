import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../domain/social_models.dart';
import '../domain/social_presence_repository.dart';

/// Drop-in [SocialPresenceRepository] used when the social Firebase
/// backend is unavailable (firebase init failed, social backend
/// disabled in build config, anonymous session). Read methods return
/// empty Success payloads so the UI renders an empty state; mutating
/// methods return `Failure(PermissionError(scope: 'social.disabled'))`
/// so consumers can pattern-match on the typed reason via
/// `SocialProvider.lastError` without falling through to a stringly
/// "unknown error" banner.
class DisabledSocialRepository implements SocialPresenceRepository {
  const DisabledSocialRepository({
    required this.reason,
  });

  final String reason;

  Failure<T, AppError> _disabled<T>(String scope) => Failure(
        PermissionError(
          scope: 'social.$scope',
          originalError: StateError(reason),
        ),
      );

  @override
  Future<Result<void, AppError>> acceptFriendRequest({
    required String requestId,
  }) async =>
      _disabled<void>('acceptFriendRequest');

  @override
  Future<Result<void, AppError>> declineFriendRequest({
    required String requestId,
  }) async =>
      _disabled<void>('declineFriendRequest');

  @override
  Future<Result<List<SocialAchievementShare>, AppError>>
      fetchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) async =>
          const Success<List<SocialAchievementShare>, AppError>(
              <SocialAchievementShare>[]);

  @override
  Stream<List<SocialAchievementShare>> watchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  }) {
    return Stream<List<SocialAchievementShare>>.value(const []);
  }

  @override
  Future<Result<List<SocialUserProfile>, AppError>> fetchProfilesByIds(
    Iterable<String> uids,
  ) async =>
      const Success<List<SocialUserProfile>, AppError>(<SocialUserProfile>[]);

  @override
  Future<Result<List<SocialUserProfile>, AppError>> searchProfilesByHandle(
    String query, {
    required String excludeUid,
    int limit = 8,
  }) async =>
      const Success<List<SocialUserProfile>, AppError>(<SocialUserProfile>[]);

  @override
  Future<Result<void, AppError>> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async =>
      _disabled<void>('sendFriendRequest');

  @override
  Future<Result<void, AppError>> shareAchievement(
    SocialAchievementShare share,
  ) async =>
      _disabled<void>('shareAchievement');

  @override
  Future<Result<void, AppError>> deleteAchievementShare({
    required String shareId,
  }) async =>
      _disabled<void>('deleteAchievementShare');

  @override
  Future<Result<void, AppError>> upsertProfile(
    SocialProfileSyncPayload payload,
  ) async =>
      _disabled<void>('upsertProfile');

  @override
  Future<Result<String, AppError>> updateProfileHandle({
    required String uid,
    required String desiredHandle,
  }) async =>
      _disabled<String>('updateProfileHandle');

  @override
  Future<Result<void, AppError>> updateProfilePhotoUrl({
    required String uid,
    required String? photoUrl,
  }) async =>
      _disabled<void>('updateProfilePhotoUrl');

  @override
  Future<Result<void, AppError>> updatePinnedAchievement({
    required String uid,
    required String achievementId,
    required bool pinned,
  }) async =>
      _disabled<void>('updatePinnedAchievement');

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
  Stream<List<RemoteEngineNodeCompletion>> watchEngineNodeCompletions(
    String uid,
  ) {
    return Stream<List<RemoteEngineNodeCompletion>>.value(const []);
  }

  @override
  Future<Result<List<RemoteEngineNodeCompletion>, AppError>>
      fetchEngineNodeCompletions(String uid) async =>
          const Success<List<RemoteEngineNodeCompletion>, AppError>(
              <RemoteEngineNodeCompletion>[]);

  @override
  Future<Result<void, AppError>> removeFriend({
    required String friendshipId,
  }) async =>
      _disabled<void>('removeFriend');

  @override
  Future<Result<void, AppError>> addReaction({
    required String shareId,
    required String actorUid,
    required String actorName,
    required String? actorPhoto,
    required String emoji,
    required String shareOwnerUid,
    required String achievementTitle,
  }) async =>
      _disabled<void>('addReaction');

  @override
  Future<Result<void, AppError>> removeReaction({
    required String shareId,
    required String actorUid,
    required String shareOwnerUid,
  }) async =>
      _disabled<void>('removeReaction');

  @override
  Stream<List<SocialNotification>> watchNotifications(String uid) {
    return Stream<List<SocialNotification>>.value(const []);
  }

  @override
  Future<Result<void, AppError>> markNotificationsRead(String uid) async =>
      const Success<void, AppError>(null);
}
