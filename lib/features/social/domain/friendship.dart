class SocialFriendship {
  const SocialFriendship({
    required this.id,
    required this.memberUids,
    required this.createdAt,
    this.sourceRequestId,
  });

  final String id;
  final List<String> memberUids;
  final DateTime createdAt;
  final String? sourceRequestId;

  String counterpartFor(String uid) {
    for (final memberUid in memberUids) {
      if (memberUid != uid) return memberUid;
    }
    return uid;
  }
}
