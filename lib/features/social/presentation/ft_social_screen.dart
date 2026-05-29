import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../../l10n/l10n.dart';
import '../application/social_provider.dart';
import 'social_notifications_sheet.dart';
import 'social_search_sheet.dart';
import 'tabs/social_feed_tab.dart';
import 'tabs/social_friends_tab.dart';
import 'tabs/social_leaderboard_tab.dart';
import 'widgets/social_status_banner.dart';
import 'widgets/social_tab_bar.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({
    super.key,
    required this.outerController,
    this.topContentInset = 0,
  });
  final PageController outerController;
  final double topContentInset;

  @override
  State<SocialScreen> createState() => _FtSocialScreenState();
}

class _FtSocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    // 3 tabs since the dedicated Activity tab was retired — reactions
    // now live alongside friend requests inside the notifications
    // bottom sheet pushed from the bell in `_SocialTopBar`, so the
    // tab strip stays focused on browse-style surfaces (feed,
    // leaderboard, friend list). `markNotificationsRead` used to fire
    // when the player switched to the Activity tab; that flush now
    // happens inside `SocialNotificationsSheet` when the sheet opens.
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();

    final showBanner = !social.backendReady ||
        !social.isReady ||
        !auth.isSignedIn ||
        social.error != null;

    // Bell badge combines both notification kinds the sheet hosts:
    // pending incoming friend requests + unread reaction notifications.
    // Friend-list pending count alone used to drive the badge, but
    // now that reactions land in the same sheet they need to register
    // on the same indicator.
    final bellBadgeCount =
        social.incomingRequests.length + social.unreadNotificationCount;

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: Padding(
        padding: EdgeInsets.only(top: widget.topContentInset),
        child: Column(
          children: [
            if (showBanner)
              SocialStatusBanner(
                backendReady: social.backendReady,
                sessionReady: social.isReady,
                signedIn: auth.isSignedIn,
                isSigningIn: auth.isBusy,
                error: social.error ?? social.backendMessage,
                onSignIn: auth.isBusy
                    ? null
                    : () => context.read<AuthProvider>().signIn(),
              ),
            if (auth.isSignedIn && social.backendReady && social.isReady)
              _SocialTopBar(
                pendingCount: bellBadgeCount,
                onTapSearch: () => SocialSearchSheet.show(context),
                onTapBell: () => SocialNotificationsSheet.show(context),
              ),
            SocialTabBar(controller: _tab),
            Expanded(
              child: EdgePageHandoff(
                controller: widget.outerController,
                currentPage: 3,
                targetPage: 2,
                isEnabled: () => _tab.index == 0 && !_tab.indexIsChanging,
                child: TabBarView(
                  controller: _tab,
                  children: const [
                    SocialFeedTab(),
                    SocialLeaderboardTab(),
                    SocialFriendsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent action strip sitting between the shell header and the
/// 4-way social tab bar. Holds a read-only search field that opens
/// the fullscreen [SocialSearchOverlay] on tap (input lands flush
/// against the safe area there so the soft keyboard doesn't eat the
/// live list) and a bell button that opens [SocialNotificationsScreen]
/// — the inbox currently surfaces only incoming friend requests but
/// the bell + route are sized to host other notification types later.
class _SocialTopBar extends StatelessWidget {
  const _SocialTopBar({
    required this.pendingCount,
    required this.onTapSearch,
    required this.onTapBell,
  });

  final int pendingCount;
  final VoidCallback onTapSearch;
  final VoidCallback onTapBell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(Tokens.radiusInner),
                  border: Border.all(color: Tokens.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 16, color: Tokens.onSurfaceFaint),
                    const SizedBox(width: Tokens.spaceSm),
                    Text(
                      l10n.socialSearchHint,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Tokens.onSurfaceFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _BellButton(
            unreadCount: pendingCount,
            onTap: onTapBell,
          ),
        ],
      ),
    );
  }
}

/// Bell button used inside [_SocialTopBar]. Renders an unread count
/// badge in the top-right corner when there's at least one pending
/// incoming friend request — matches the visual treatment of the
/// existing tab-bar badges so the bell reads as the same primitive
/// surfaced on a different surface.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

  static const Color _badge = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.socialNotificationsTitle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            border: Border.all(color: Tokens.cardBorder),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 20, color: Tokens.onSurface),
              if (unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _badge,
                      borderRadius:
                          BorderRadius.circular(Tokens.radiusProgress),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeTiny,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
