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
import 'widgets/social_feed_card.dart';
import 'widgets/social_notification_card.dart';

/// Modal bottom sheet pushed from the bell button in `SocialScreen`'s
/// persistent top bar. Hosts two stacked sections, both optional:
///
///   1. **Friend requests** — pending incoming `SocialFriendRequest`s
///      with Accept (green) / Decline (red) chips. Kept at the top of
///      the list because acting on them changes a relationship and
///      gates everything else on the social tab.
///   2. **Reactions** — every reaction someone left on the signed-in
///      user's shared achievements, rendered through the existing
///      `SocialNotificationCard`. Tap on the row opens the share in
///      an inline detail sheet so the player can see the post in
///      context without leaving the bell surface.
///
/// Moved the reaction surface here from the dedicated `Activity` tab
/// (which is gone in the same change) so the bell becomes the single
/// inbox for everything social. Both sections feed the same bell
/// badge — `pendingCount + unreadNotifCount` — and the sheet flushes
/// the unread side via `markNotificationsRead` on open.
///
/// Sized to ~72 % of the available screen height so a small inbox is
/// readable at a glance while a large one stays scrollable inside
/// the sheet.
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

  /// Owned by the sheet so the pull-to-dismiss listener can ask
  /// "is the inbox list at scroll offset 0?" before treating a
  /// downward drag as dismiss intent.
  late final ScrollController _scrollController;

  // ── Dismiss-on-pull-down state ─────────────────────────────────
  //
  // `showModalBottomSheet`'s default `enableDrag` only fires when no
  // descendant claims the gesture. With even a single notification
  // row, the inner `ListView` wins the pointer arena and the sheet
  // stops responding to swipe-down anywhere except the top header.
  // Mirror the raw-pointer pattern from `SocialSearchSheet` /
  // `slot_sheet_shell.dart`: track downward delta while the list is
  // at offset 0, pop once we cross the threshold.
  double _dragAccumulated = 0;
  bool _tracking = false;
  static const double _dismissThreshold = 80;

  bool get _atTop =>
      !_scrollController.hasClients || _scrollController.offset <= 0;

  void _onPointerDown(PointerDownEvent event) {
    _dragAccumulated = 0;
    _tracking = _atTop;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final dy = event.delta.dy;
    if (!_tracking) {
      // Re-arm once the user has scrolled back to the top and starts
      // pulling downward again — common path on long inboxes the
      // player has browsed before deciding to dismiss.
      if (_atTop && dy > 0) {
        _tracking = true;
        _dragAccumulated = 0;
      } else {
        return;
      }
    }
    if (!_atTop) {
      _tracking = false;
      _dragAccumulated = 0;
      return;
    }
    _dragAccumulated += dy;
    if (_dragAccumulated < 0) _dragAccumulated = 0;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_dragAccumulated > _dismissThreshold) {
      Navigator.of(context).maybePop();
    }
    _dragAccumulated = 0;
    _tracking = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _dragAccumulated = 0;
    _tracking = false;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Flush unread state as soon as the sheet opens. Best-effort —
    // failures here only mean the bell badge stays lit until the next
    // notifications stream tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().markNotificationsRead();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final notifications = social.notifications;
    final screenH = MediaQuery.of(context).size.height;
    final isEmpty = requests.isEmpty && notifications.isEmpty;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ConstrainedBox(
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
              child: isEmpty
                  ? _EmptyState(l10n: l10n)
                  : ListView(
                      // Owned by the parent state so the pull-to-
                      // dismiss listener can ask the controller
                      // whether we're at scroll offset 0 before
                      // treating a downward drag as dismiss intent.
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      children: [
                        // Friend requests on top — acting on them
                        // changes a relationship, so the player should
                        // see them before scrolling through reactions.
                        if (requests.isNotEmpty) ...[
                          _SectionHeader(
                              label: l10n.socialFriendRequestsTitle),
                          for (var i = 0; i < requests.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _RequestRow(
                              request: requests[i],
                              getProfile: _profile,
                              onAccept: () => _handleAccept(requests[i].id),
                              onDecline: () => _handleDecline(requests[i].id),
                            ),
                          ],
                          if (notifications.isNotEmpty)
                            const SizedBox(height: 18),
                        ],
                        if (notifications.isNotEmpty) ...[
                          _SectionHeader(
                              label:
                                  l10n.socialNotificationsReactionsSection),
                          for (var i = 0; i < notifications.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            SocialNotificationCard(
                              notification: notifications[i],
                              onOpenShare: () =>
                                  _openShare(notifications[i].shareId),
                            ),
                          ],
                        ],
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openShare(String shareId) {
    final share = context.read<SocialProvider>().shareById(shareId);
    if (share == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareDetailSheet(share: share),
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

/// Section caption shown above each notification group inside the
/// sheet — matches the small-caps "RECENT ACTIVITY" treatment the
/// retired activity tab used so the visual hierarchy reads as the
/// same kind of inbox header.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          color: Tokens.onSurfaceFaint,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Lifted from the retired activity tab. Surfaced when the player
/// taps an "Open post" affordance on a reaction notification — shows
/// the original share inline so they can see the post in context
/// without leaving the notifications surface. Re-uses
/// `SocialFeedCard` so the visual matches what the feed tab already
/// renders for the same share.
class _ShareDetailSheet extends StatelessWidget {
  const _ShareDetailSheet({required this.share});
  final SocialAchievementShare share;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Tokens.cardBorder,
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
            ),
          ),
          const SizedBox(height: 14),
          SocialFeedCard(share: share),
          const SizedBox(height: Tokens.spaceXs),
        ],
      ),
    );
  }
}
