import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression/presentation/progression_l10n.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/social_provider.dart';
import '../../domain/social_models.dart';
import '../social_profile_utils.dart';
import '../widgets/social_cosmetic_avatar.dart';
import '../widgets/social_chip.dart';
import '../widgets/social_empty.dart';
import '../widgets/social_lv_badge.dart';

class SocialFriendsTab extends StatefulWidget {
  const SocialFriendsTab({super.key});

  @override
  State<SocialFriendsTab> createState() => _SocialFriendsTabState();
}

class _SocialFriendsTabState extends State<SocialFriendsTab> {
  bool _reqExpanded = true;
  final Map<String, Future<SocialUserProfile?>> _reqProfiles = {};
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<SocialUserProfile?> _reqProfile(String uid) {
    return _reqProfiles.putIfAbsent(
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
        if (social.incomingRequests.isNotEmpty) ...[
          _RequestsSection(
            requests: social.incomingRequests,
            expanded: _reqExpanded,
            onToggle: () => setState(() => _reqExpanded = !_reqExpanded),
            getProfile: _reqProfile,
            onAccept: (id) async {
              final messenger = ScaffoldMessenger.of(context);
              final sp = context.read<SocialProvider>();
              await sp.acceptFriendRequest(id);
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(
                content: Text(sp.error == null
                    ? l10n.socialFriendRequestAccepted
                    : l10n.socialErrorWithMessage(sp.error!)),
              ));
            },
            onDecline: (id) async {
              final messenger = ScaffoldMessenger.of(context);
              final sp = context.read<SocialProvider>();
              await sp.declineFriendRequest(id);
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(
                content: Text(sp.error == null
                    ? l10n.socialFriendRequestDeclined
                    : l10n.socialErrorWithMessage(sp.error!)),
              ));
            },
          ),
          const SizedBox(height: 10),
        ],
        if (social.outgoingRequests.isNotEmpty) ...[
          _OutgoingRequestsSection(
            requests: social.outgoingRequests,
            getProfile: _reqProfile,
          ),
          const SizedBox(height: 10),
        ],
        _SearchBar(
          controller: _search,
          isSearching: social.isSearching,
          results: social.searchResults,
          onSearch: () =>
              context.read<SocialProvider>().searchUsers(_search.text),
          onAdd: (uid) async {
            final messenger = ScaffoldMessenger.of(context);
            final sp = context.read<SocialProvider>();
            await sp.sendFriendRequest(uid);
            if (!mounted) return;
            _search.clear();
            sp.clearSearchResults();
            messenger.showSnackBar(SnackBar(
              content: Text(sp.error == null
                  ? l10n.socialFriendRequestSent
                  : l10n.socialErrorWithMessage(sp.error!)),
            ));
          },
          onOpenProfile: (p) => openUserProfile(
            context,
            uid: p.uid,
            initialDisplayName: p.displayName,
            initialPhotoUrl: p.photoUrl,
          ),
        ),
        const SizedBox(height: 14),
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
    final title = ProgressionL10n(context.l10n).levelTitle(friend.stats.level);
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

// ── Requests section ──────────────────────────────────────────────────────────

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.requests,
    required this.expanded,
    required this.onToggle,
    required this.getProfile,
    required this.onAccept,
    required this.onDecline,
  });

  final List<SocialFriendRequest> requests;
  final bool expanded;
  final VoidCallback onToggle;
  final Future<SocialUserProfile?> Function(String uid) getProfile;
  final Future<void> Function(String id) onAccept;
  final Future<void> Function(String id) onDecline;

  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [Color(0x1AEF4444), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded, size: 14, color: _red),
                  const SizedBox(width: Tokens.spaceSm),
                  Text(
                    context.l10n.socialFriendRequestsTitle,
                    style: const TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        fontWeight: FontWeight.w700,
                        color: _red),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius:
                          BorderRadius.circular(Tokens.radiusProgress),
                    ),
                    child: Center(
                      child: Text(
                        '${requests.length}',
                        style: const TextStyle(
                            fontSize: Tokens.fontSizeTiny,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Tokens.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            ...requests.map(
              (req) => Column(
                children: [
                  Container(height: 1, color: _red.withValues(alpha: 0.18)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
                    child: FutureBuilder<SocialUserProfile?>(
                      future: getProfile(req.fromUid),
                      builder: (context, snap) {
                        final p = snap.data;
                        final name = p?.displayName.isNotEmpty == true
                            ? p!.displayName
                            : (p?.handle.isNotEmpty == true
                                ? '@${p!.handle}'
                                : req.fromUid);
                        return Row(
                          children: [
                            SocialCosmeticAvatar(
                                name: name,
                                size: 40,
                                photoUrl: p?.photoUrl,
                                profile: p,
                                color: const Color(0xFFF97316)),
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
                                        color: Tokens.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    p?.handle.isNotEmpty == true
                                        ? '@${p!.handle}'
                                        : context.l10n.socialWantsToBeFriend,
                                    style: const TextStyle(
                                        fontSize: Tokens.fontSizeCaption,
                                        color: Tokens.onSurfaceFaint),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Tokens.spaceSm),
                            SocialChip(
                                label: context.l10n.socialAccept,
                                color: const Color(0xFF10B981),
                                onTap: () => onAccept(req.id)),
                            const SizedBox(width: 6),
                            SocialChip(
                                label: context.l10n.socialDecline,
                                color: _red,
                                onTap: () => onDecline(req.id)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
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

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.onSearch,
    required this.onAdd,
    required this.onOpenProfile,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<SocialUserProfile> results;
  final VoidCallback onSearch;
  final Future<void> Function(String uid) onAdd;
  final void Function(SocialUserProfile) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            border: Border.all(color: Tokens.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  size: 15, color: Tokens.onSurfaceFaint),
              const SizedBox(width: Tokens.spaceSm),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  style: const TextStyle(fontSize: 13, color: Tokens.onSurface),
                  decoration: InputDecoration(
                    hintText: context.l10n.socialSearchHint,
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Tokens.onSurfaceFaint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: Tokens.spaceSm),
              GestureDetector(
                onTap: isSearching ? null : onSearch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSearching
                        ? Tokens.accent.withValues(alpha: 0.4)
                        : Tokens.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSearching ? '…' : context.l10n.socialSearchButton,
                    style: const TextStyle(
                        fontSize: Tokens.fontSizeSmall,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(Tokens.radiusInner),
              border: Border.all(color: Tokens.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < results.length; i++) ...[
                  if (i > 0) Container(height: 1, color: Tokens.divider),
                  _SearchResult(
                    profile: results[i],
                    onAdd: () => onAdd(results[i].uid),
                    onOpen: () => onOpenProfile(results[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult(
      {required this.profile, required this.onAdd, required this.onOpen});
  final SocialUserProfile profile;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
        child: Row(
          children: [
            SocialCosmeticAvatar(
              name: profile.displayName,
              size: 36,
              photoUrl: profile.photoUrl,
              profile: profile,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Tokens.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.l10n
                        .socialHandleLevel(profile.handle, profile.stats.level),
                    style: const TextStyle(
                        fontSize: Tokens.fontSizeCaption,
                        color: Tokens.onSurfaceFaint),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Tokens.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Tokens.accent.withValues(alpha: 0.28)),
                ),
                child: Text(
                  context.l10n.socialAdd,
                  style: const TextStyle(
                      fontSize: Tokens.fontSizeSmall,
                      fontWeight: FontWeight.w700,
                      color: Tokens.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
