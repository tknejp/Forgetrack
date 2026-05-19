class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.shareId,
    required this.achievementTitle,
    required this.emoji,
    required this.createdAt,
    required this.read,
    this.actorPhoto,
  });

  final String id; // lint-ignore: untyped-id — notification dedupe token, persisted as raw string
  final String actorUid; // lint-ignore: untyped-id — Firebase Auth uid is a platform-boundary raw string
  final String actorName;
  final String? actorPhoto;
  final String shareId; // lint-ignore: untyped-id — share document id reference, persisted as raw string
  final String achievementTitle;
  final String emoji;
  final DateTime createdAt;
  final bool read;
}
