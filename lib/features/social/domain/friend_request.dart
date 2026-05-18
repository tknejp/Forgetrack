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

  final String id;
  final String fromUid;
  final String toUid;
  final SocialFriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == SocialFriendRequestStatus.pending;
}
