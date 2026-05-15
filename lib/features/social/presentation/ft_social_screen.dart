import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/drag_reveal_pager.dart';
import '../../../l10n/l10n.dart';
import '../application/social_provider.dart';
import 'tabs/social_activity_tab.dart';
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
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tab.index == 1 && !_tab.indexIsChanging) {
      context.read<SocialProvider>().markNotificationsRead();
    }
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
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
              _FriendCountRow(count: social.friends.length),
            SocialTabBar(
              controller: _tab,
              pendingCount: social.incomingRequests.length,
              unreadNotifCount: social.unreadNotificationCount,
            ),
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
                    SocialActivityTab(),
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

class _FriendCountRow extends StatelessWidget {
  const _FriendCountRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              color: Tokens.active.dim,
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
              border:
                  Border.all(color: Tokens.active.color.withValues(alpha: 0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 14,
                  color: Tokens.active.color,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.socialFriendCount(count),
                  style: TextStyle(
                    color: Tokens.active.color,
                    fontSize: Tokens.fontSizeSmall,
                    fontWeight: FontWeight.w900,
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
