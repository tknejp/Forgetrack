import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigator_key.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../auth/application/auth_provider.dart';
import '../../celebration/presentation/celebration_overlay_host.dart';
import '../../cosmetics/presentation/cosmetics_screen.dart';
import '../../devtools/application/devtools_permission_service.dart';
import '../../devtools/application/devtools_provider.dart';
import '../../health_connect/presentation/activities_screen.dart';
import '../../health_connect/presentation/body_screen.dart';
import '../../health_connect/presentation/sleep_screen.dart';
import '../../health_connect/presentation/steps_screen.dart';
import '../../home/presentation/overview_screen.dart';
import '../../nutrition/presentation/nutrition_screen.dart';
import '../../progression/presentation/hero/hero_screen.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/presentation/quests_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../social/application/social_provider.dart';
import '../../social/presentation/ft_social_screen.dart';
import '../../social/presentation/widgets/hero_progression_header.dart';
import 'widgets/debug_tools_sheet.dart';
import 'widgets/main_bottom_nav.dart';
import 'widgets/shell_header.dart';

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
  void dispose() {
    pendingTabSwitch.removeListener(_onPendingTabSwitch);
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
    // The header switches with an AnimatedSwitcher (220ms) and content inside
    // it can grow taller mid-animation. We measure immediately for grow, then
    // again after the switch settles so a shorter header is allowed to shrink.
    // The epoch guards against an older delayed callback firing after a newer
    // page change has already started a fresh measure cycle.
    final measureEpoch = ++_chromeMeasureEpoch;
    _currentIndex.value = index;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTopChrome());
    Future<void>.delayed(const Duration(milliseconds: 360), () {
      if (!mounted || measureEpoch != _chromeMeasureEpoch) return;
      _measureTopChrome(allowShrink: true);
    });
  }

  void _onOpenInventory({String? focusCompanionId}) {
    // The fullscreen celebration CTA pops itself before invoking this,
    // so the push lands on top of the active tab. `focusCompanionId` is
    // forwarded so a companion-availability celebration lands directly
    // on that companion's details sheet (where the player triggers the
    // claim animation) rather than on the inventory's "Vše" tab.
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CosmeticsScreen(initialFocusId: focusCompanionId),
      ),
    );
  }

  Future<void> _openActivitiesScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ActivitiesScreen()));

  Future<void> _openStepsScreen() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const StepsScreen()));

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
        onOpenSteps: _openStepsScreen,
        onOpenNutrition: _openNutritionScreen,
        onOpenBody: _openBodyScreen,
        onOpenSleep: _openSleepScreen,
      ),
      QuestsScreenV2(
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
                          child: HeaderScrim(),
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _currentIndex,
                        builder: (context, currentIndex, _) {
                          final headerData =
                              _headerDataFor(currentIndex, l10n, firstName);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: ShellHeader(
                                  key: ValueKey(currentIndex),
                                  eyebrow: headerData.eyebrow,
                                  title: headerData.title,
                                  trailing: currentIndex == 2
                                      ? SettingsButton(
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
                                child: HeroProgressionHeader(
                                  barKey: _progressionBarKey,
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
              Positioned.fill(
                child: CelebrationOverlayHost(
                  onOpenInventory: _onOpenInventory,
                ),
              ),
              if (_showDebugLauncher(context))
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: DebugLauncherButton(
                    onTap: () => showDebugToolsSheet(context),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: RepaintBoundary(
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndex,
            builder: (context, currentIndex, _) {
              return MainBottomNav(
                index: currentIndex,
                onTap: _goToPage,
                questBadge: context
                    .watch<ProgressionEngineProvider>()
                    .pendingQuestClaimNodeIds
                    .length,
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

  HeaderData _headerDataFor(int index, dynamic l10n, String? firstName) {
    switch (index) {
      case 0:
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? l10n.headerToday : l10n.navOverview;
        return HeaderData(
          eyebrow: firstName != null ? '$greeting, $firstName' : greeting,
          title: l10n.navOverview,
        );
      case 1:
        return HeaderData(
            eyebrow: l10n.questsScreenEyebrow, title: l10n.questsScreenTitle);
      case 2:
        return HeaderData(
            eyebrow: l10n.progScreenEyebrow, title: l10n.progScreenTitle);
      default:
        return HeaderData(
            eyebrow: l10n.navSocial.toUpperCase(), title: l10n.navSocial);
    }
  }
}
