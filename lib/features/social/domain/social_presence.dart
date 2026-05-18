import 'package:meta/meta.dart';

import 'achievement_share.dart';
import 'friend_request.dart';
import 'friendship.dart';
import 'social_notification.dart';
import 'social_user_profile.dart';

/// Per-Player social aggregate facade.
///
/// Phase 17 of the domain refactor (`docs/domain_model/migration_plan.md`
/// §Phase 17) bundles the previously scattered Social state surfaces
/// (own profile, handle, incoming / outgoing friend requests,
/// confirmed friendships, friend profile snapshots, recent achievement
/// shares, notifications) into a single immutable read aggregate.
///
/// Owned by `SocialProvider` — read it via
/// `socialProvider.presence`. The aggregate is *read-only*; every
/// mutation still flows through the provider's existing imperative
/// methods (`sendFriendRequest`, `acceptFriendRequest`,
/// `publishProfile`, etc.), which write through the
/// `SocialPresenceRepository` and refresh the provider's internal
/// fields. The aggregate is then re-fabricated and exposed.
///
/// **Cache, not source of truth.** Friends / friendships / shares /
/// notifications all live in Firestore subcollections that mirror
/// canonical state (own profile derives from Player + Loadout +
/// Journal; shares + reactions are append-only). See
/// [SocialUserProfile] / [SocialUserStats] docstrings for the
/// per-field rebuild path. Phase 20 will promote the rebuild to a
/// first-class `JournalProjection`.
///
/// **Phase 17 scope.** Phase 17 deliberately ships the facade
/// **without rewiring imperative call sites**. Existing widgets that
/// call `socialProvider.friendships` continue to work because the
/// provider still exposes those getters; the new `presence` getter
/// is the *forward-compatible* read shape that future widget sweeps
/// can migrate to incrementally (Phase 19+).
@immutable
class SocialPresence {
  const SocialPresence({
    required this.uid,
    required this.ownProfile,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.friendships,
    required this.friends,
    required this.recentShares,
    required this.notifications,
  });

  /// Sentinel "no signed-in user" instance. UI code can read
  /// `presence.friends` without a null guard before the social
  /// session has settled.
  static const SocialPresence anonymous = SocialPresence(
    uid: '',
    ownProfile: null,
    incomingRequests: [],
    outgoingRequests: [],
    friendships: [],
    friends: [],
    recentShares: [],
    notifications: [],
  );

  /// Active social user id. Empty string when no one is signed in.
  final String uid;

  /// Own published profile snapshot mirrored from Firestore. Null
  /// before the first profile pull lands (cold start) or when the
  /// signed-in user has disabled social.
  final SocialUserProfile? ownProfile;

  /// Pending friend requests addressed to [uid].
  final List<SocialFriendRequest> incomingRequests;

  /// Pending friend requests sent by [uid] awaiting a response.
  final List<SocialFriendRequest> outgoingRequests;

  /// Confirmed friendships — the persistent edges that survive across
  /// `friend_request → friendship` lifecycle transitions.
  final List<SocialFriendship> friendships;

  /// Per-friend profile snapshots indexed in the same order as
  /// [friendships]'s counterpart uids. Backed by the same Firestore
  /// reads as [ownProfile].
  final List<SocialUserProfile> friends;

  /// Latest visible achievement shares (own + friends), sorted
  /// newest-first by `createdAt`. Capped by the repository's
  /// `recentShares` query.
  final List<SocialAchievementShare> recentShares;

  /// Notifications for the signed-in user (achievement reactions on
  /// own shares + friend request events).
  final List<SocialNotification> notifications;

  /// Count of [notifications] whose `read` flag is false. Surfaced
  /// on the Social tab's badge.
  int get unreadNotificationCount =>
      notifications.where((n) => !n.read).length;

  /// True when there is at least one [SocialFriendRequest] in
  /// [incomingRequests] still in `pending` state.
  bool get hasPendingIncomingRequests =>
      incomingRequests.any((r) => r.isPending);

  SocialPresence copyWith({
    String? uid,
    Object? ownProfile = _unchanged,
    List<SocialFriendRequest>? incomingRequests,
    List<SocialFriendRequest>? outgoingRequests,
    List<SocialFriendship>? friendships,
    List<SocialUserProfile>? friends,
    List<SocialAchievementShare>? recentShares,
    List<SocialNotification>? notifications,
  }) {
    return SocialPresence(
      uid: uid ?? this.uid,
      ownProfile: identical(ownProfile, _unchanged)
          ? this.ownProfile
          : ownProfile as SocialUserProfile?,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      friendships: friendships ?? this.friendships,
      friends: friends ?? this.friends,
      recentShares: recentShares ?? this.recentShares,
      notifications: notifications ?? this.notifications,
    );
  }
}

const Object _unchanged = Object();
