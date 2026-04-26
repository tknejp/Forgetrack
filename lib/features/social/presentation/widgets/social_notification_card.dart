import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/social_models.dart';
import '../social_helpers.dart';
import 'social_avatar.dart';

class SocialNotificationCard extends StatelessWidget {
  const SocialNotificationCard({
    super.key,
    required this.notification,
    this.onOpenShare,
  });
  final SocialNotification notification;
  final VoidCallback? onOpenShare;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: unread
            ? FtTokens.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread
              ? FtTokens.accent.withValues(alpha: 0.22)
              : FtTokens.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openUserProfile(
              context,
              uid: notification.actorUid,
              initialDisplayName: notification.actorName,
              initialPhotoUrl: notification.actorPhoto,
            ),
            child: SocialAvatar(
              name: notification.actorName,
              photoUrl: notification.actorPhoto,
              size: 36,
              color: unread ? FtTokens.accent : FtTokens.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => openUserProfile(
                        context,
                        uid: notification.actorUid,
                        initialDisplayName: notification.actorName,
                        initialPhotoUrl: notification.actorPhoto,
                      ),
                      child: Text(
                        notification.actorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FtTokens.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const Text(
                      ' reagoval(a) ',
                      style: TextStyle(
                          fontSize: 12,
                          color: FtTokens.onSurfaceMuted,
                          height: 1.4),
                    ),
                    Text(
                      notification.emoji,
                      style:
                          const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const Text(
                      ' na tvůj achievement ',
                      style: TextStyle(
                          fontSize: 12,
                          color: FtTokens.onSurfaceMuted,
                          height: 1.4),
                    ),
                    Text(
                      notification.achievementTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.accent.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      socialRelativeTime(notification.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: FtTokens.onSurfaceFaint),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: FtTokens.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    if (onOpenShare != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onOpenShare,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Zobrazit příspěvek',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: FtTokens.accent.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: FtTokens.accent.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
