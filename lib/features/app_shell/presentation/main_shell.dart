import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigator_key.dart';
import '../../auth/application/auth_provider.dart';
import '../../devtools/application/devtools_permission_service.dart';
import '../../devtools/application/devtools_provider.dart';
import '../../devtools/presentation/devtools_screen.dart';
import '../../devtools/presentation/sections/devtools_cosmetics_section.dart';
import '../../devtools/presentation/sections/devtools_progression_section.dart';
import '../../devtools/presentation/sections/devtools_unlock_inventory_section.dart';
import '../../health_connect/presentation/activities_screen.dart';
import '../../health_connect/presentation/body_screen.dart';
import '../../health_connect/presentation/sleep_screen.dart';
import '../../nutrition/presentation/nutrition_screen.dart';
import '../../progression/application/progression_provider.dart';
import '../../progression/presentation/widgets/progression_home_card.dart';
import '../../social/application/social_provider.dart';
import '../../social/presentation/ft_social_screen.dart';
import '../../social/presentation/widgets/social_profile_header.dart';
import 'widgets/progression_celebration_overlay.dart';
import '../../../l10n/l10n.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../home/presentation/overview_screen.dart';
import '../../progression/presentation/hero/hero_screen.dart';
import '../../progression/presentation/quests/quests_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _FtMainShellState();
}

class _FtMainShellState extends State<MainShell> {
  late final PageController _pageController;
  final GlobalKey _progressionBarKey = GlobalKey();
  final GlobalKey _topChromeKey = GlobalKey();
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);
  ProgressionProvider? _progressionProvider;
  ProgressionCelebrationEvent? _celebrationEvent;
  int _chromeMeasureEpoch = 0;
  double _topChromeHeight = 148;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    pendingTabSwitch.addListener(_onPendingTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTopChrome(allowShrink: true);
      _onPendingTabSwitch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final progression = context.read<ProgressionProvider>();
    if (_progressionProvider == progression) return;
    _progressionProvider?.removeListener(_onProgressionChanged);
    _progressionProvider = progression..addListener(_onProgressionChanged);
    _drainCelebrationQueue();
  }

  @override
  void dispose() {
    pendingTabSwitch.removeListener(_onPendingTabSwitch);
    _progressionProvider?.removeListener(_onProgressionChanged);
    _currentIndex.dispose();
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

  void _measureTopChrome({bool allowShrink = false}) {
    final box = _topChromeKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final height = box.size.height;
    final shouldUpdate = allowShrink
        ? (height - _topChromeHeight).abs() > 0.5
        : height > _topChromeHeight + 0.5;
    if (shouldUpdate && mounted) {
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
    final measureEpoch = ++_chromeMeasureEpoch;
    _currentIndex.value = index;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTopChrome());
    Future<void>.delayed(const Duration(milliseconds: 360), () {
      if (!mounted || measureEpoch != _chromeMeasureEpoch) return;
      _measureTopChrome(allowShrink: true);
    });
  }

  void _onProgressionChanged() {
    _drainCelebrationQueue();
  }

  void _drainCelebrationQueue() {
    if (_celebrationEvent != null) return;
    final next = _progressionProvider?.takeNextCelebration();
    if (next == null || !mounted) return;
    setState(() => _celebrationEvent = next);
  }

  void _dismissCelebration() {
    if (_celebrationEvent == null) return;
    setState(() => _celebrationEvent = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drainCelebrationQueue();
    });
  }

  Future<void> _openActivitiesScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ActivitiesScreen()));

  Future<void> _openNutritionScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const NutritionScreen()));

  Future<void> _openBodyScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const BodyScreen()));

  Future<void> _openSleepScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const SleepScreen()));

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final firstName = auth.user?.displayName?.split(' ').firstOrNull;

    final screens = [
      OverviewScreen(
        outerController: _pageController,
        barKey: _progressionBarKey,
        topContentInset: _topChromeHeight,
        onOpenActivities: _openActivitiesScreen,
        onOpenNutrition: _openNutritionScreen,
        onOpenBody: _openBodyScreen,
        onOpenSleep: _openSleepScreen,
      ),
      QuestsScreen(
        barKey: _progressionBarKey,
        outerController: _pageController,
        topContentInset: _topChromeHeight,
      ),
      HeroScreen(
        barKey: _progressionBarKey,
        outerController: _pageController,
        topContentInset: _topChromeHeight,
      ),
      SocialScreen(
        outerController: _pageController,
        topContentInset: _topChromeHeight,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: ft.bg,
      ),
      child: Scaffold(
        backgroundColor: ft.bg,
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
                      ValueListenableBuilder<int>(
                        valueListenable: _currentIndex,
                        builder: (context, currentIndex, _) {
                          final headerData =
                              _headerDataFor(currentIndex, l10n, firstName);
                          final usesProfileHeader =
                              currentIndex == 2 || currentIndex == 3;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _ShellHeader(
                                  key: ValueKey(currentIndex),
                                  eyebrow: headerData.eyebrow,
                                  title: headerData.title,
                                  trailing: currentIndex == 2
                                      ? _SettingsButton(
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
                                padding:
                                    const EdgeInsets.fromLTRB(14, 8, 14, 0),
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
                                  child: usesProfileHeader
                                      ? RepaintBoundary(
                                          key: const ValueKey(
                                            'profile-header',
                                          ),
                                          child: SocialProfileHeader(
                                            showFriendsPill: currentIndex == 3,
                                          ),
                                        )
                                      : RepaintBoundary(
                                          key: const ValueKey(
                                            'progression-header-card',
                                          ),
                                          child: ProgressionCard(
                                            barKey: _progressionBarKey,
                                          ),
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
              ),
              if (_celebrationEvent != null)
                ProgressionCelebrationOverlay(
                  key: ValueKey(_celebrationEvent!.id),
                  event: _celebrationEvent!,
                  onDismiss: _dismissCelebration,
                ),
              if (_showDebugLauncher(context))
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: _DebugLauncherButton(
                    onTap: () => _showDebugSheet(context),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: RepaintBoundary(
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndex,
            builder: (context, currentIndex, _) {
              return _FtBottomNav(
                index: currentIndex,
                onTap: _goToPage,
                questBadge:
                    context.watch<ProgressionProvider>().pendingRewards.length,
                socialBadge:
                    context.watch<SocialProvider>().incomingRequests.length +
                        context.watch<SocialProvider>().unreadNotificationCount,
              );
            },
          ),
        ),
      ),
    );
  }

  bool _showDebugLauncher(BuildContext context) {
    final debugEnabled = context.watch<DevToolsProvider>().isDebugModeEnabled;
    final uid = context.watch<AuthProvider>().user?.firebaseUid;
    return debugEnabled && DevToolsPermissionService.hasAccess(uid);
  }

  Future<void> _showDebugSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DebugToolsSheet(),
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
    final ft = context.ft;

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
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w800,
                    color: ft.accent,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeTitle,
                    fontWeight: FontWeight.w900,
                    color: ft.onSurface,
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
    final ft = context.ft;

    return Container(
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.55, 1],
          colors: [
            ft.bg,
            ft.bg.withValues(alpha: 0.94),
            ft.bg.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ft.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Icon(
          Icons.settings_rounded,
          size: 18,
          color: ft.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _DebugLauncherButton extends StatelessWidget {
  const _DebugLauncherButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ft.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.bug_report_rounded,
          color: ft.accent,
          size: 20,
        ),
      ),
    );
  }
}

enum _DebugSheetTab {
  progression,
  unlocks,
  cosmetics,
}

class _DebugToolsSheet extends StatefulWidget {
  const _DebugToolsSheet();

  @override
  State<_DebugToolsSheet> createState() => _DebugToolsSheetState();
}

class _DebugToolsSheetState extends State<_DebugToolsSheet> {
  _DebugSheetTab _tab = _DebugSheetTab.progression;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.36,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: ft.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: ft.cardBorder),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ft.onSurfaceMuted.withValues(alpha: 0.28),
                        borderRadius:
                            BorderRadius.circular(Tokens.radiusProgress),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.bug_report_rounded,
                            size: 18, color: ft.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Debug tools',
                            style: TextStyle(
                              color: ft.onSurface,
                              fontSize: Tokens.fontSizeBody,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open full DevTools',
                          icon: Icon(Icons.open_in_full_rounded,
                              color: ft.onSurfaceMuted, size: 18),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DevToolsScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(Icons.close_rounded,
                              color: ft.onSurfaceMuted, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DebugSheetChip(
                            label: 'Progression',
                            icon: Icons.military_tech_rounded,
                            selected: _tab == _DebugSheetTab.progression,
                            onTap: () =>
                                setState(() => _tab = _DebugSheetTab.progression),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _DebugSheetChip(
                            label: 'Unlocks',
                            icon: Icons.fact_check_rounded,
                            selected: _tab == _DebugSheetTab.unlocks,
                            onTap: () =>
                                setState(() => _tab = _DebugSheetTab.unlocks),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _DebugSheetChip(
                            label: 'Cosmetics',
                            icon: Icons.auto_awesome_rounded,
                            selected: _tab == _DebugSheetTab.cosmetics,
                            onTap: () =>
                                setState(() => _tab = _DebugSheetTab.cosmetics),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPad + 16),
                  child: _DebugSheetContent(tab: _tab),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DebugSheetChip extends StatelessWidget {
  const _DebugSheetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final color = selected ? ft.accent : ft.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusProgress),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? ft.accent.withValues(alpha: 0.14)
              : ft.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(
            color: selected
                ? ft.accent.withValues(alpha: 0.28)
                : ft.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugSheetContent extends StatelessWidget {
  const _DebugSheetContent({required this.tab});

  final _DebugSheetTab tab;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _DebugSheetTab.progression:
        return const DevToolsProgressionSection();
      case _DebugSheetTab.unlocks:
        return const DevToolsUnlockInventorySection();
      case _DebugSheetTab.cosmetics:
        return const DevToolsCosmeticsSection();
    }
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
    final ft = context.ft;
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
      decoration: BoxDecoration(
        color: ft.bg.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: ft.divider)),
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
                badgeColor: i == 1 ? ft.xp : ft.danger,
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
    final ft = context.ft;

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
                            ft.accent.withValues(alpha: 0.20),
                            ft.accent.withValues(alpha: 0.09),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                  border: Border.all(
                    color: isActive
                        ? ft.accent.withValues(alpha: 0.27)
                        : Colors.transparent,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: ft.accentGlow, blurRadius: 10)]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: isActive ? ft.accent : ft.onSurfaceFaint,
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
                      borderRadius:
                          BorderRadius.circular(Tokens.radiusProgress),
                      border: Border.all(color: ft.bg, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: ft.onSurface,
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
              fontSize: Tokens.fontSizeMicro,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? ft.accent : ft.onSurfaceFaint,
            ),
          ),
        ],
      ),
    );
  }
}
