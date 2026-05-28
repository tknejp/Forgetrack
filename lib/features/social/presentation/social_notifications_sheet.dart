import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../application/social_provider.dart';
import '../domain/social_models.dart';
import 'widgets/social_chip.dart';
import 'widgets/social_cosmetic_avatar.dart';
import 'widgets/social_empty.dart';

/// Modal bottom sheet pushed from the bell button in `SocialScreen`'s
/// persistent top bar. Today the sheet is friend-request-only — every
/// pending incoming `SocialFriendRequest` lands here with Accept /
/// Decline affordances — but the title + empty-state copy stay
/// generic so the same surface can host other notification kinds
/// (achievement reactions, leaderboard pings, …) once those land.
///
/// Sized to ~70% of the available screen height so a player with a
/// few notifications can see them all without scrolling, while a
/// large inbox stays scrollable inside the sheet. The sheet is
/// rendered against the same surface chrome the other social sheets
/// already use (rounded top + drag handle + dim bg) so it reads as
/// part of the same primitive set as `ProfileFriendsListSheet`.
class SocialNotificationsSheet extends StatefulWidget {
  const SocialNotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const SocialNotificationsSheet(),
    );
  }

  @override
  State<SocialNotificationsSheet> createState() =>
      _SocialNotificationsSheetState();
}

class _SocialNotificationsSheetState extends State<SocialNotificationsSheet> {
  /// Cache of `fetchProfileById` futures so a brief rebuild doesn't
  /// re-trigger a network round-trip for each request row.
  final Map<String, Future<SocialUserProfile?>> _profiles = {};

  @override
  void initState() {
    super.initState();
    // Flush unread state as soon as the sheet opens. Best-effort —
    // failures here only mean the bell badge stays lit until the next
    // notifications stream tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().markNotificationsRead();
    });
  }

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
    final requests = social.incomingRequests;
    final screenH = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenH * 0.72),
      child: Container(
        decoration: const BoxDecoration(
          color: Tokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Tokens.cardBorder),
            left: BorderSide(color: Tokens.cardBorder),
            right: BorderSide(color: Tokens.cardBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Tokens.cardBorder,
                borderRadius: BorderRadius.circular(Tokens.radiusProgress),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 18, color: Tokens.onSurface),
                  const SizedBox(width: Tokens.spaceSm),
                  Text(
                    l10n.socialNotificationsTitle,
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeBody,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Tokens.cardBorder),
            Flexible(
              child: requests.isEmpty
                  ? _EmptyState(l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _RequestRow(
                        request: requests[i],
                        getProfile: _profile,
                        onAccept: () => _handleAccept(requests[i].id),
                        onDecline: () => _handleDecline(requests[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(String requestId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final sp = context.read<SocialProvider>();
    await sp.acceptFriendRequest(requestId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(sp.error == null
          ? l10n.socialFriendRequestAccepted
          : l10n.socialErrorWithMessage(sp.error!)),
    ));
  }

  Future<void> _handleDecline(String requestId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final sp = context.read<SocialProvider>();
    await sp.declineFriendRequest(requestId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(sp.error == null
          ? l10n.socialFriendRequestDeclined
          : l10n.socialErrorWithMessage(sp.error!)),
    ));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: SocialEmpty(
        icon: Icons.notifications_none_rounded,
        title: l10n.socialNotificationsEmptyTitle,
        subtitle: l10n.socialNotificationsEmptySubtitle,
      ),
    );
  }
}

/// One friend-request row inside the sheet. Same visual primitives
/// as the legacy friends-tab `_RequestsSection` so a player who knew
/// that surface recognises this one immediately.
class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.getProfile,
    required this.onAccept,
    required this.onDecline,
  });

  final SocialFriendRequest request;
  final Future<SocialUserProfile?> Function(String uid) getProfile;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  static const _accept = Color(0xFF10B981);
  static const _decline = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [Color(0x1AEF4444), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
        border: Border.all(color: _decline.withValues(alpha: 0.3)),
      ),
      child: FutureBuilder<SocialUserProfile?>(
        future: getProfile(request.fromUid),
        builder: (context, snap) {
          final l10n = context.l10n;
          final p = snap.data;
          final name = p?.displayName.isNotEmpty == true
              ? p!.displayName
              : (p?.handle.isNotEmpty == true
                  ? '@${p!.handle}'
                  : request.fromUid);
          return Row(
            children: [
              SocialCosmeticAvatar(
                name: name,
                size: 40,
                photoUrl: p?.photoUrl,
                profile: p,
                color: const Color(0xFFF97316),
              ),
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
                      p?.handle.isNotEmpty == true
                          ? '@${p!.handle}'
                          : l10n.socialWantsToBeFriend,
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeCaption,
                        color: Tokens.onSurfaceFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.spaceSm),
              SocialChip(
                label: l10n.socialAccept,
                color: _accept,
                onTap: onAccept,
              ),
              const SizedBox(width: 6),
              SocialChip(
                label: l10n.socialDecline,
                color: _decline,
                onTap: onDecline,
              ),
            ],
          );
        },
      ),
    );
  }
}
