import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_log.dart';
import '../../../l10n/l10n.dart';
import '../../celebration/application/progression_engine_celebration_adapter.dart';
import '../../celebration/presentation/widgets/fullscreen/celebration_fullscreen.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../cosmetics/domain/hero_race_catalog.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../application/onboarding_provider.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';
import 'onboarding_steps.dart';

/// First-launch welcome screen — Variant 1 (Multi-step Quest) per
/// `design/design_handoff_welcome_onboarding_v1`.
///
/// Layout:
///   1. Status-bar gap (manually applied so the gradient extends to the
///      very top of the screen rather than being clipped by SafeArea)
///   2. Header strip — progress dots + skip button
///   3. Body — `PageView` with `NeverScrollableScrollPhysics`, advanced
///      only via the CTA / back chevron / skip
///   4. Footer — back button (steps 2–4) + primary CTA
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _stepCount = 4;

  /// Starter skin catalog id granted at race-pick time. The cosmetics
  /// provider trio in [_finish] unlocks + equips this so the new
  /// player's hero card paints with their chosen race's pilgrim look
  /// from the first frame after onboarding.
  static const _starterSkinId = 'skin_pilgrim';

  /// Cosmetics granted by the `welcome_to_journey` achievement that the
  /// new player should also see equipped on the very first paint of
  /// MainShell. Pre-unlocking + equipping these inside [_finish] (instead
  /// of leaning on the engine grant alone) covers two failure modes:
  ///   * the engine's reward dispatch never lands an [equip] call, so
  ///     items would sit unequipped in inventory after the celebration,
  ///   * if cosmetics weren't loaded when the grant fired (sign-in race),
  ///     the bridge silently drops the unlock and the banner never
  ///     appears in inventory at all.
  static const List<(String, CosmeticType)> _welcomeCosmetics = [
    ('background_camp', CosmeticType.background),
    ('frame_pilgrim', CosmeticType.frame),
    ('banner_pilgrim', CosmeticType.banner),
  ];

  final PageController _pageController = PageController();
  int _step = 0;

  /// Currently-previewed [HeroRace] id. Local UI state until [_finish] —
  /// sign-in happens in Step 2, and `CosmeticsProvider` writes are
  /// uid-keyed, so we can only persist once Auth has bound a user.
  /// Initialised from the cosmetics provider on first build (carries a
  /// re-entered onboarding's prior pick), else from the first race in
  /// catalog order.
  String _draftRaceId = HeroRaceCatalog.definitions.first.id;
  bool _draftSeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draftSeeded) return;
    final persistedRace = context.read<CosmeticsProvider>().currentRaceId;
    if (persistedRace != null && HeroRaceCatalog.byId(persistedRace) != null) {
      _draftRaceId = persistedRace;
    }
    _draftSeeded = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int target) {
    setState(() => _step = target);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _go(_step + 1);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) _go(_step - 1);
  }

  void _skip() => _go(_stepCount - 1);

  void _onPickRace(String raceId) {
    if (raceId == _draftRaceId) return;
    setState(() => _draftRaceId = raceId);
  }

  Future<void> _finish() async {
    final cosmetics = context.read<CosmeticsProvider>();
    final onboarding = context.read<OnboardingProvider>();
    final progression = context.read<ProgressionEngineProvider>();

    // Commit race + starter skin once a uid is bound. If the user
    // skipped sign-in (Step 2 is opt-in via the skip button), the
    // commit is deferred — `CosmeticsProvider` would warn `no_user_bound`
    // and discard the call. The draft race id is intentionally not
    // persisted to a secondary store; cosmetic state is uid-scoped by
    // design and the unauth path is a degraded mode anyway.
    if (cosmetics.currentUid != null) {
      try {
        await cosmetics.selectRace(_draftRaceId);
        final hasStarter =
            cosmetics.state?.unlocked.containsKey(_starterSkinId) ?? false;
        if (!hasStarter) {
          await cosmetics.unlock(
            _starterSkinId,
            sourceType: CosmeticUnlockSource.defaultBaseline.name,
          );
        }
        if (cosmetics.state?.equipped.skinId != _starterSkinId) {
          await cosmetics.equip(_starterSkinId);
        }
        // Pre-unlock + auto-equip the welcome-pack cosmetics. The
        // `welcome_to_journey` achievement also grants them via the
        // engine's reward pipeline, but (a) that path only unlocks,
        // never equips, and (b) it silently drops when cosmetics isn't
        // yet uid-bound — which was leaving the banner missing from
        // inventory in the post-onboarding handoff. Doing it here makes
        // the equipped loadout deterministic on first MainShell paint
        // and writes through to Firestore via the service layer.
        for (final (id, _) in _welcomeCosmetics) {
          final already =
              cosmetics.state?.unlocked.containsKey(id) ?? false;
          if (!already) {
            await cosmetics.unlock(
              id,
              sourceType: CosmeticUnlockSource.achievement.name,
              sourceId: 'welcome_to_journey',
            );
          }
        }
        for (final (id, type) in _welcomeCosmetics) {
          if (cosmetics.state?.equipped.slotId(type) != id) {
            await cosmetics.equip(id);
          }
        }
        AppLog.app.info(
          'onboarding: race + starter skin + welcome pack committed',
          payload:
              'race=$_draftRaceId skin=$_starterSkinId uid=${cosmetics.currentUid}',
        );
      } catch (e, st) {
        // Race / unlock / equip throws are already caught + logged
        // inside the provider; this `catch` is defensive against
        // platform-level failures (Isar I/O, etc.). Onboarding
        // completion must not be blocked by a transient cosmetic
        // write — the player can re-enter through DevTools reset if
        // their state ended up half-applied.
        AppLog.app.warn(
          'onboarding: race commit threw',
          payload: 'race=$_draftRaceId error=$e stack=$st',
        );
      }
      if (!mounted) return;
    } else {
      AppLog.app.warn(
        'onboarding: finished without signed-in user — race not persisted',
        payload: 'draftRace=$_draftRaceId',
      );
    }

    // Force an engine pass so `welcome_to_journey` (no conditions, fires
    // on first evaluation) is recorded in the ledger before the routing
    // gate flips. Without this, the achievement gets evaluated later —
    // after MainShell has already mounted — and the celebration appears
    // on top of the home screen instead of in place of it.
    await progression.refresh();
    if (!mounted) return;

    // Drain whatever the engine queued (welcome achievement + any
    // catch-up celebrations from a background sync replay) as fullscreen
    // routes pushed on top of the welcome screen. The user never sees
    // MainShell until the celebration is dismissed.
    await _drainWelcomeCelebrations(progression, cosmetics);
    if (!mounted) return;

    await onboarding.markCompleted();
    // Routing in app.dart watches the provider — flipping completed
    // automatically swaps the home from WelcomeScreen to MainShell.
  }

  Future<void> _drainWelcomeCelebrations(
    ProgressionEngineProvider progression,
    CosmeticsProvider cosmetics,
  ) async {
    final adapter = ProgressionEngineCelebrationAdapter(cosmetics: cosmetics);
    while (mounted) {
      final result = progression.takePendingCelebration();
      if (result == null) return;
      final events = adapter.convert(result);
      for (final event in events) {
        if (!mounted) return;
        await openCelebrationFullscreen(
          context: context,
          event: event,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: OnboardingTheme.bg,
      ),
      child: Scaffold(
        backgroundColor: OnboardingTheme.bg,
        // Manually pad for status bar so the radial gradient covers the
        // full viewport (SafeArea would clip the top).
        body: Stack(
          children: [
            // Top purple radial wash.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: OnboardingTheme.pageGradientTop,
                ),
              ),
            ),
            // Bottom teal radial wash.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: OnboardingTheme.pageGradientBottom,
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: topInset),
                _Header(
                  step: _step,
                  totalSteps: _stepCount,
                  onSkip: _skip,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepScroll(
                        child: StepWelcome(
                          draftRaceId: _draftRaceId,
                          onPickRace: _onPickRace,
                        ),
                      ),
                      const _StepScroll(child: StepAccount()),
                      const _StepScroll(child: StepHealth()),
                      const _StepScroll(child: StepFinal()),
                    ],
                  ),
                ),
                _Footer(
                  step: _step,
                  totalSteps: _stepCount,
                  onBack: _back,
                  onNext: _next,
                  bottomInset: bottomInset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.totalSteps,
    required this.onSkip,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ProgressDots(totalSteps: totalSteps, currentStep: step),
          if (step < totalSteps - 1)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.welcomeSkip,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: OnboardingTheme.textCaption,
                ),
              ),
            )
          else
            const SizedBox(width: 0, height: 28),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    required this.bottomInset,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLast = step == totalSteps - 1;
    final label = switch (step) {
      0 => l10n.welcomeCtaStart,
      1 || 2 => l10n.welcomeCtaContinue,
      _ => l10n.welcomeCtaFinish,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottomInset),
      child: Row(
        children: [
          if (step > 0) ...[
            BackBtn(onTap: onBack),
            const SizedBox(width: 10),
          ],
          PrimaryBtn(
            label: label,
            onTap: onNext,
            showArrow: !isLast,
            showWand: isLast,
          ),
        ],
      ),
    );
  }
}
