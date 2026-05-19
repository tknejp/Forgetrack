enum SocialFriendRequestStatus {
  pending,
  accepted,
  declined,
}

class SocialFriendRequest {
  const SocialFriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id; // lint-ignore: untyped-id — Firestore document id, persisted as raw string
  final String fromUid; // lint-ignore: untyped-id — Firebase Auth uid is a platform-boundary raw string
  final String toUid; // lint-ignore: untyped-id — Firebase Auth uid is a platform-boundary raw string
  final SocialFriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == SocialFriendRequestStatus.pending;
}
