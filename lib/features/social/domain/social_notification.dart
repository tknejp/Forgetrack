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

  final String id;
  final String actorUid;
  final String actorName;
  final String? actorPhoto;
  final String shareId;
  final String achievementTitle;
  final String emoji;
  final DateTime createdAt;
  final bool read;
}
