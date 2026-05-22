import 'package:flutter/material.dart';

import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'social_cosmetic_avatar.dart';

/// Modal bottom-sheet content that lists a user's friends. Surfaced from
/// the small "Přátelé · N" chip rendered under the @handle in the profile
/// hero card — replaces the inline expandable banner that used to sit
/// under the header.
class ProfileFriendsListSheet extends StatelessWidget {
  const ProfileFriendsListSheet({super.key, required this.stream});

  final Stream<List<SocialUserProfile>> stream;

  static Future<void> show(
    BuildContext context, {
    required Stream<List<SocialUserProfile>> stream,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileFriendsListSheet(stream: stream),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Tokens.cardBorder),
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Tokens.cardBorder,
                  borderRadius: BorderRadius.circular(Tokens.radiusProgress),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceLg),
            StreamBuilder<List<SocialUserProfile>>(
              stream: stream,
              builder: (context, snap) {
                final loading = snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData;
                final friends = snap.data ?? const <SocialUserProfile>[];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Tokens.active.dim,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: Tokens.active.color.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: Tokens.active.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.socialProfileFriendsTitle,
                            style: const TextStyle(
                              fontSize: Tokens.fontSizeMicro,
                              fontWeight: FontWeight.w800,
                              color: Tokens.onSurfaceFaint,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        if (loading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Tokens.accent,
                            ),
                          )
                        else
                          Text(
                            '${friends.length}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Tokens.active.color,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: Tokens.spaceMd),
                    if (friends.isEmpty && !loading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.l10n.socialProfileNoFriends,
                          style: const TextStyle(
                            fontSize: Tokens.fontSizeSmall,
                            color: Tokens.onSurfaceFaint,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final friend in friends)
                                _ProfileFriendRow(friend: friend),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFriendRow extends StatelessWidget {
  const _ProfileFriendRow({required this.friend});

  final SocialUserProfile friend;

  @override
  Widget build(BuildContext context) {
    final title = const ProgressionDisplayResolver()
        .levelDisplay(friend.stats.level)
        .title(context.l10n);
    final subtitle = friend.handle.isEmpty
        ? context.l10n.socialFriendLevelSubtitle(friend.stats.level, title)
        : context.l10n.socialFriendHandleLevelSubtitle(
            friend.handle,
            friend.stats.level,
            title,
          );

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        openUserProfile(
          context,
          uid: friend.uid,
          initialDisplayName: friend.displayName,
          initialPhotoUrl: friend.photoUrl,
        );
      },
      borderRadius: BorderRadius.circular(Tokens.radiusInner),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Row(
          children: [
            SocialCosmeticAvatar(
              name: friend.displayName,
              size: 36,
              photoUrl: friend.photoUrl,
              profile: friend,
              radius: 11,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      fontWeight: FontWeight.w600,
                      color: Tokens.onSurfaceFaint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Tokens.onSurfaceFaint,
            ),
          ],
        ),
      ),
    );
  }
}
