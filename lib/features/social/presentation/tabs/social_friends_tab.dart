import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import '../widgets/social_cosmetic_avatar.dart';
import '../widgets/social_empty.dart';
import '../widgets/social_lv_badge.dart';

/// "Friends" tab inside the social screen — outgoing pending requests
/// (`Sent requests`) at the top followed by the player's confirmed
/// friend list. Two surfaces moved out of this tab on 2026-05-28:
///
///   * **Search panel** is now the fullscreen [SocialSearchOverlay]
///     pushed from the persistent top bar in `SocialScreen` — the
///     input pinned against the safe-area means the soft keyboard
///     stops eating the live result list.
///   * **Incoming requests** are now the `SocialNotificationsScreen`
///     pushed from the bell icon next to the search field — they
///     stayed visually identical (accept-green / decline-red chips)
///     but live alongside future notification kinds instead of
///     squatting at the top of the friends tab.
///
/// What remains is a small, focused tab: a "you've sent these out"
/// status block (so the player can see what's in flight) and the
/// list of people who accepted.
class SocialFriendsTab extends StatefulWidget {
  const SocialFriendsTab({super.key});

  @override
  State<SocialFriendsTab> createState() => _SocialFriendsTabState();
}

class _SocialFriendsTabState extends State<SocialFriendsTab> {
  /// Cache of `fetchProfileById` futures keyed by uid so a brief
  /// rebuild doesn't re-trigger a network round-trip for each
  /// outgoing-request row.
  final Map<String, Future<SocialUserProfile?>> _profiles = {};

  Future<SocialUserProfile?> _profile(String uid) {
    return _profiles.putIfAbsent(
      uid,
      () => context.read<SocialProvider>().fetchProfileById(uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        if (social.outgoingRequests.isNotEmpty) ...[
          _OutgoingRequestsSection(
            requests: social.outgoingRequests,
            getProfile: _profile,
          ),
          const SizedBox(height: 14),
        ],
        if (social.friends.isEmpty)
          SocialEmpty(
            icon: Icons.group_outlined,
            title: l10n.socialFriendsEmptyTitle,
            subtitle: l10n.socialFriendsEmptySubtitle,
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Tokens.accent),
                const SizedBox(width: Tokens.spaceSm),
                Text(
                  l10n.socialFriendsSectionCount(social.friends.length),
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w800,
                    color: Tokens.accent,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          ...social.friends.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FriendCard(
                friend: f,
                onTap: () => openUserProfile(
                  context,
                  uid: f.uid,
                  initialDisplayName: f.displayName,
                  initialPhotoUrl: f.photoUrl,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Friend card ───────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onTap});
  final SocialUserProfile friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = const ProgressionDisplayResolver()
        .levelDisplay(friend.stats.level)
        .title(context.l10n);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1, -1),
            end: const Alignment(1, 1),
            colors: [Tokens.accent.withValues(alpha: 0.1), Tokens.surface],
          ),
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
          border: Border.all(color: Tokens.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SocialCosmeticAvatar(
                name: friend.displayName,
                size: 42,
                photoUrl: friend.photoUrl,
                profile: friend),
            const SizedBox(width: 11),
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
                        fontWeight: FontWeight.w700,
                        color: Tokens.onSurface),
                  ),
                  const SizedBox(height: Tokens.spaceXs),
                  Row(
                    children: [
                      SocialLvBadge(level: friend.stats.level, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFBBF24),
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  socialFmtXp(friend.stats.totalXp),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onSurface),
                ),
                Text(context.l10n.socialXpLabel,
                    style: const TextStyle(
                        fontSize: Tokens.fontSizeTiny,
                        color: Tokens.onSurfaceFaint,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: Tokens.spaceXs),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Tokens.onSurfaceFaint),
          ],
        ),
      ),
    );
  }
}

// ── Outgoing requests section ─────────────────────────────────────────────────

class _OutgoingRequestsSection extends StatelessWidget {
  const _OutgoingRequestsSection({
    required this.requests,
    required this.getProfile,
  });

  final List<SocialFriendRequest> requests;
  final Future<SocialUserProfile?> Function(String uid) getProfile;

  static const _accent = Tokens.accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
        border: Border.all(color: Tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
            child: Row(
              children: [
                const Icon(Icons.send_rounded, size: 14, color: _accent),
                const SizedBox(width: Tokens.spaceSm),
                Text(
                  context.l10n.socialOutgoingRequestsCount(requests.length),
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeSmall,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < requests.length; i++) ...[
            if (i > 0) Container(height: 1, color: Tokens.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
              child: FutureBuilder<SocialUserProfile?>(
                future: getProfile(requests[i].toUid),
                builder: (context, snap) {
                  final profile = snap.data;
                  final name = profile?.displayName.isNotEmpty == true
                      ? profile!.displayName
                      : (profile?.handle.isNotEmpty == true
                          ? '@${profile!.handle}'
                          : requests[i].toUid);
                  return Row(
                    children: [
                      SocialCosmeticAvatar(
                          name: name,
                          size: 40,
                          photoUrl: profile?.photoUrl,
                          profile: profile),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Tokens.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              profile?.handle.isNotEmpty == true
                                  ? '@${profile!.handle}'
                                  : context.l10n.socialAwaitingConfirmation,
                              style: const TextStyle(
                                fontSize: Tokens.fontSizeCaption,
                                color: Tokens.onSurfaceFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: _accent.withValues(alpha: 0.24)),
                        ),
                        child: Text(
                          context.l10n.socialPending,
                          style: const TextStyle(
                              fontSize: Tokens.fontSizeSmall,
                              fontWeight: FontWeight.w700,
                              color: _accent),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
