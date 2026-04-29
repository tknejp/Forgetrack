import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigator_key.dart';
import '../../auth/application/auth_provider.dart';
import '../../health_connect/presentation/ft_activities_screen.dart';
import '../../health_connect/presentation/ft_body_screen.dart';
import '../../health_connect/presentation/ft_sleep_screen.dart';
import '../../nutrition/presentation/ft_nutrition_screen.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/presentation/widgets/ft_progression_home_card.dart';
import '../../social/application/social_provider.dart';
import '../../social/presentation/ft_social_screen.dart';
import '../../social/presentation/widgets/social_profile_header.dart';
import '../../../l10n/l10n.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../home/presentation/ft_overview_screen.dart';
import '../../progression/presentation/ft_progression_screen.dart';

class FtMainShell extends StatefulWidget {
  const FtMainShell({super.key});

  @override
  State<FtMainShell> createState() => _FtMainShellState();
}

class _FtMainShellState extends State<FtMainShell> {
  late final PageController _pageController;
  final GlobalKey _progressionBarKey = GlobalKey();
  final GlobalKey _topChromeKey = GlobalKey();
  int _currentIndex = 0;
  double _topChromeHeight = 148;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    pendingTabSwitch.addListener(_onPendingTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTopChrome();
      _onPendingTabSwitch();
    });
  }

  @override
  void dispose() {
    pendingTabSwitch.removeListener(_onPendingTabSwitch);
    _pageController.dispose();
    super.dispose();
  }

  void _onPendingTabSwitch() {
    final index = pendingTabSwitch.value;
    if (index == null) return;
    pendingTabSwitch.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goToPage(index);
    });
  }

  void _measureTopChrome() {
    final box = _topChromeKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final height = box.size.height;
    if ((height - _topChromeHeight).abs() > 0.5 && mounted) {
      setState(() => _topChromeHeight = height);
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _currentIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTopChrome());
    Future<void>.delayed(const Duration(milliseconds: 340), () {
      if (mounted) _measureTopChrome();
    });
  }

  Future<void> _openActivitiesScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const FtActivitiesScreen()));

  Future<void> _openNutritionScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const FtNutritionScreen()));

  Future<void> _openBodyScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const FtBodyScreen()));

  Future<void> _openSleepScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const FtSleepScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.displayName?.split(' ').firstOrNull;

    final screens = [
      FtOverviewScreen(
        outerController: _pageController,
        barKey: _progressionBarKey,
        topContentInset: _topChromeHeight,
        onOpenActivities: _openActivitiesScreen,
        onOpenNutrition: _openNutritionScreen,
        onOpenBody: _openBodyScreen,
        onOpenSleep: _openSleepScreen,
      ),
      FtQuestsScreen(
        barKey: _progressionBarKey,
        outerController: _pageController,
        topContentInset: _topChromeHeight,
      ),
      FtProgressionScreen(
        barKey: _progressionBarKey,
        outerController: _pageController,
        topContentInset: _topChromeHeight,
      ),
      FtSocialScreen(
        outerController: _pageController,
        topContentInset: _topChromeHeight,
      ),
    ];

    final headerData = _headerDataFor(_currentIndex, l10n, firstName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: FtTokens.bg,
      ),
      child: Scaffold(
        backgroundColor: FtTokens.bg,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _handlePageChanged,
                  children: screens,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  key: _topChromeKey,
                  child: Stack(
                    children: [
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: _HeaderScrim(),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        onEnd: _measureTopChrome,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _ShellHeader(
                                key: ValueKey(_currentIndex),
                                eyebrow: headerData.eyebrow,
                                title: headerData.title,
                                trailing: _currentIndex == 0
                                    ? _AvatarButton(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SettingsScreen(),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final curved = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  );
                                  return FadeTransition(
                                    opacity: curved,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, -0.04),
                                        end: Offset.zero,
                                      ).animate(curved),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _currentIndex == 3
                                    ? const SocialProfileHeader(
                                        key: ValueKey('social-profile-header'),
                                      )
                                    : FtProgressionCard(
                                        key: const ValueKey(
                                          'progression-header-card',
                                        ),
                                        barKey: _progressionBarKey,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _FtBottomNav(
          index: _currentIndex,
          onTap: _goToPage,
          questBadge:
              context.watch<ProgressionProvider>().pendingRewards.length,
          socialBadge: context.watch<SocialProvider>().incomingRequests.length +
              context.watch<SocialProvider>().unreadNotificationCount,
        ),
      ),
    );
  }

  _HeaderData _headerDataFor(int index, dynamic l10n, String? firstName) {
    switch (index) {
      case 0:
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? l10n.headerToday : l10n.navOverview;
        return _HeaderData(
          eyebrow: firstName != null ? '$greeting, $firstName' : greeting,
          title: l10n.navOverview,
        );
      case 1:
        return _HeaderData(
            eyebrow: l10n.questsScreenEyebrow, title: l10n.questsScreenTitle);
      case 2:
        return _HeaderData(
            eyebrow: l10n.progScreenEyebrow, title: l10n.progScreenTitle);
      default:
        return _HeaderData(
            eyebrow: l10n.navSocial.toUpperCase(), title: l10n.navSocial);
    }
  }
}

class _HeaderData {
  const _HeaderData({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.accent,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _HeaderScrim extends StatelessWidget {
  const _HeaderScrim();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.55, 1],
          colors: [
            FtTokens.bg,
            FtTokens.bg.withValues(alpha: 0.94),
            FtTokens.bg.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FtTokens.accent.withValues(alpha: 0.33),
              FtTokens.accent.withValues(alpha: 0.13),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.accent.withValues(alpha: 0.27)),
          boxShadow: [BoxShadow(color: FtTokens.accentGlow, blurRadius: 16)],
        ),
        child: const Center(
          child: Text('🛠', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _FtBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final int questBadge;
  final int socialBadge;

  const _FtBottomNav({
    required this.index,
    required this.onTap,
    this.questBadge = 0,
    this.socialBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(label: context.l10n.navOverview, icon: Icons.grid_view_rounded),
      _NavItem(label: context.l10n.navQuests, icon: Icons.flag_rounded),
      _NavItem(label: context.l10n.navHero, icon: Icons.person_outline_rounded),
      _NavItem(label: context.l10n.navSocial, icon: Icons.groups_rounded),
    ];

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding:
          EdgeInsets.only(top: 10, bottom: bottomPad + 10, left: 8, right: 8),
      decoration: const BoxDecoration(
        color: Color(0xF20D0F1C),
        border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavItemTile(
                item: items[i],
                isActive: i == index,
                onTap: () => onTap(i),
                badge: i == 1
                    ? questBadge
                    : i == 3
                        ? socialBadge
                        : 0,
                badgeColor:
                    i == 1 ? const Color(0xFFFFBD2E) : const Color(0xFFEF4444),
              ),
            ),
        ],
      ),
    );
  }
}

@immutable
class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

class _NavItemTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;
  final Color badgeColor;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
    this.badgeColor = const Color(0xFFEF4444),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            FtTokens.accent.withValues(alpha: 0.20),
                            FtTokens.accent.withValues(alpha: 0.09),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? FtTokens.accent.withValues(alpha: 0.27)
                        : Colors.transparent,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: FtTokens.accentGlow, blurRadius: 10)]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: isActive ? FtTokens.accent : const Color(0x59FFFFFF),
                  ),
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: -3,
                  right: -1,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 13, minHeight: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: const Color(0xFF0D0F1C), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: FtTokens.fontSizeMicro,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? FtTokens.accent : const Color(0x59FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
