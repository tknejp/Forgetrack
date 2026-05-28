import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'social_cosmetic_avatar.dart';

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
    final l10n = context.l10n;
    final unread = !notification.read;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: unread
            ? Tokens.accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(
          color: unread
              ? Tokens.accent.withValues(alpha: 0.22)
              : Tokens.cardBorder,
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
            child: _LiveNotificationAvatar(
              notification: notification,
              color: unread ? Tokens.accent : Tokens.onSurfaceMuted,
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
                          fontSize: Tokens.fontSizeSmall,
                          fontWeight: FontWeight.w700,
                          color: Tokens.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Text(
                      l10n.socialNotificationReactedPrefix,
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        color: Tokens.onSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      notification.emoji,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    Text(
                      l10n.socialNotificationReactedSuffix,
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        color: Tokens.onSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                    Text(
                      notification.achievementTitle,
                      style: TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        fontWeight: FontWeight.w700,
                        color: Tokens.accent.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      socialRelativeTime(notification.createdAt, l10n),
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeMicro,
                        color: Tokens.onSurfaceFaint,
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Tokens.accent,
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
                              l10n.socialNotificationOpenPost,
                              style: TextStyle(
                                fontSize: Tokens.fontSizeMicro,
                                fontWeight: FontWeight.w700,
                                color: Tokens.accent.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: Tokens.accent.withValues(alpha: 0.85),
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

class _LiveNotificationAvatar extends StatelessWidget {
  const _LiveNotificationAvatar({
    required this.notification,
    required this.color,
  });

  final SocialNotification notification;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final social = context.read<SocialProvider>();
    return StreamBuilder<SocialUserProfile?>(
      stream: social.watchProfileById(notification.actorUid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.displayName.trim().isNotEmpty == true
            ? profile!.displayName.trim()
            : notification.actorName;
        final photoUrl = profile?.photoUrl?.trim().isNotEmpty == true
            ? profile!.photoUrl
            : notification.actorPhoto;
        return SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SocialCosmeticAvatar(
                name: name,
                photoUrl: photoUrl,
                profile: profile,
                size: 44,
                color: color,
              ),
            ],
          ),
        );
      },
    );
  }
}
