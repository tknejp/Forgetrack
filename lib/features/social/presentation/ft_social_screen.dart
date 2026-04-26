import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../../shared/widgets/ft/ft_drag_reveal_pager.dart';
import '../application/social_provider.dart';
import 'tabs/social_activity_tab.dart';
import 'tabs/social_feed_tab.dart';
import 'tabs/social_friends_tab.dart';
import 'tabs/social_leaderboard_tab.dart';
import 'widgets/social_status_banner.dart';
import 'widgets/social_tab_bar.dart';

class FtSocialScreen extends StatefulWidget {
  const FtSocialScreen({
    super.key,
    required this.outerController,
    this.topContentInset = 0,
  });
  final PageController outerController;
  final double topContentInset;

  @override
  State<FtSocialScreen> createState() => _FtSocialScreenState();
}

class _FtSocialScreenState extends State<FtSocialScreen>
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
      backgroundColor: FtTokens.bg,
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
            SocialTabBar(
              controller: _tab,
              pendingCount: social.incomingRequests.length,
              unreadNotifCount: social.unreadNotificationCount,
            ),
            Expanded(
              child: FtEdgePageHandoff(
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
