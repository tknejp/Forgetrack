import 'package:flutter/material.dart';

import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import 'social_cosmetic_avatar.dart';

// ── Friends section ───────────────────────────────────────────────────────────

class ProfileFriendsSection extends StatefulWidget {
  const ProfileFriendsSection({super.key, required this.stream});

  final Stream<List<SocialUserProfile>> stream;

  @override
  State<ProfileFriendsSection> createState() => _ProfileFriendsSectionState();
}

class _ProfileFriendsSectionState extends State<ProfileFriendsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SocialUserProfile>>(
      stream: widget.stream,
      builder: (context, snap) {
        final loading =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;
        final friends = snap.data ?? const <SocialUserProfile>[];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(Tokens.radiusTile),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: friends.isEmpty
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(Tokens.radiusTile),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(
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
                      const SizedBox(width: Tokens.spaceSm),
                      ExpandChevron(
                        expanded: _expanded,
                        color: Tokens.onSurfaceFaint,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _ProfileFriendList(friends: friends),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileFriendList extends StatelessWidget {
  const _ProfileFriendList({required this.friends});

  final List<SocialUserProfile> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Text(
          context.l10n.socialProfileNoFriends,
          style: const TextStyle(
            fontSize: Tokens.fontSizeSmall,
            color: Tokens.onSurfaceFaint,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        children: [
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 6),
          for (final friend in friends) _ProfileFriendRow(friend: friend),
        ],
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
      onTap: () => openUserProfile(
        context,
        uid: friend.uid,
        initialDisplayName: friend.displayName,
        initialPhotoUrl: friend.photoUrl,
      ),
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
