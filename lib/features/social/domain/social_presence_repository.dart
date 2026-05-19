import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
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
///
/// **R.4 (2026-05-19) — Result-typed Future methods.** Every Future-
/// returning method returns `Future<Result<T, AppError>>` so the
/// `SocialProvider` pattern-matches on failure severity instead of
/// catching `Object` and stringifying. Stream methods stay raw and
/// surface errors via `onError` — converting them would require a
/// `Stream<Result<T, AppError>>` shape that doesn't pay for itself
/// (stream subscriptions already debounce errors and re-subscribe is
/// the only meaningful recovery). The per-method `// R.4:` comments
/// on the implementation classes record the rationale where worth
/// noting.
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

  Future<Result<List<SocialUserProfile>, AppError>> fetchProfilesByIds(
    Iterable<String> uids,
  );

  Future<Result<List<SocialUserProfile>, AppError>> searchProfilesByHandle(
    String query, {
    required String excludeUid,
    int limit = 8,
  });

  Future<Result<List<SocialAchievementShare>, AppError>>
      fetchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  });

  Stream<List<SocialAchievementShare>> watchRecentAchievementShares({
    required Iterable<String> actorUids,
    int limit = 20,
  });

  Future<Result<void, AppError>> upsertProfile(
    SocialProfileSyncPayload payload,
  );

  Future<Result<String, AppError>> updateProfileHandle({
    required String uid,
    required String desiredHandle,
  });

  Future<Result<void, AppError>> updateProfilePhotoUrl({
    required String uid,
    required String? photoUrl,
  });

  Future<Result<void, AppError>> updatePinnedAchievement({
    required String uid,
    required String achievementId,
    required bool pinned,
  });

  Future<Result<void, AppError>> sendFriendRequest({
    required String fromUid,
    required String toUid,
  });

  Future<Result<void, AppError>> acceptFriendRequest({
    required String requestId,
  });

  Future<Result<void, AppError>> declineFriendRequest({
    required String requestId,
  });

  Future<Result<void, AppError>> shareAchievement(
    SocialAchievementShare share,
  );

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

  Future<Result<List<RemoteEngineNodeCompletion>, AppError>>
      fetchEngineNodeCompletions(String uid);

  Future<Result<void, AppError>> removeFriend({required String friendshipId});

  Future<Result<void, AppError>> addReaction({
    required String shareId,
    required String actorUid,
    required String actorName,
    required String? actorPhoto,
    required String emoji,
    required String shareOwnerUid,
    required String achievementTitle,
  });

  Future<Result<void, AppError>> removeReaction({
    required String shareId,
    required String actorUid,
    required String shareOwnerUid,
  });

  Stream<List<SocialNotification>> watchNotifications(String uid);

  Future<Result<void, AppError>> markNotificationsRead(String uid);
}
