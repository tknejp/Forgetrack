import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../l10n/l10n.dart';
import '../../celebration/application/progression_engine_celebration_adapter.dart';
import '../../celebration/presentation/widgets/fullscreen/celebration_fullscreen.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../cosmetics/domain/hero_race_catalog.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../social/application/social_provider.dart';
import '../application/onboarding_provider.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';
import 'onboarding_steps.dart';

/// Onboarding mode, resolved once a uid binds after the Step 2 sign-in
/// (or immediately, if onboarding is re-entered while already signed in).
///
///   * [undetermined] — pre-sign-in / still resolving. Renders the
///     full new-player layout so a brand-new player sees the race pick
///     hook first; the race-commit guard ([_canCommitRace]) blocks any
///     write until the mode is known + the cloud is reachable.
///   * [newPlayer] — no cloud `onboardingCompleted` flag and no
///     cloud-restored race. Full onboarding (race pick + welcome
///     celebration).
///   * [returning] — same account, fresh install / new device. The
///     player already cleared onboarding elsewhere, so the race pick is
///     dropped (race is a permanent choice, restored from the cloud) and
///     the welcome celebration is suppressed; only a quick connection
///     setup (Google / Health Connect / Kalorické tabulky) remains.
enum _OnboardingMode { undetermined, newPlayer, returning }

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
///
/// New players see the full 4-step flow (race pick + account + health +
/// final); returning players see a 3-step quick setup (account + health
/// + final, no race pick). See [_OnboardingMode].
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Number of steps in the current flow. Returning players drop the
  /// leading race-pick step (4 → 3). Drives the progress dots + the
  /// `_next`/`_skip` bounds.
  int get _stepCount => _mode == _OnboardingMode.returning ? 3 : 4;

  /// Resolved onboarding mode — see [_OnboardingMode]. Starts
  /// [_OnboardingMode.undetermined] and flips once a uid binds and the
  /// cloud signals settle (via [_resolveMode]).
  _OnboardingMode _mode = _OnboardingMode.undetermined;

  /// Guards [_resolveMode] against overlapping runs while its async
  /// cloud read is in flight.
  bool _resolvingMode = false;

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

  /// Currently-previewed [HeroRace] id. Local UI state until the race is
  /// committed — sign-in happens in Step 2, and `CosmeticsProvider`
  /// writes are uid-keyed, so we can only persist once Auth has bound a
  /// user. Initialised from the cosmetics provider on first build
  /// (carries a re-entered onboarding's prior pick), else from the first
  /// race in catalog order.
  String _draftRaceId = HeroRaceCatalog.definitions.first.id;
  bool _draftSeeded = false;

  /// Cosmetics provider we hold a listener on so mode resolution +
  /// [_commitRaceAndStarterSkin] can fire the moment a uid binds and the
  /// cloud state settles after the Step 2 sign-in — see
  /// [_onCosmeticsChanged]. Captured in [didChangeDependencies] so the
  /// listener is detached cleanly in [dispose].
  CosmeticsProvider? _cosmetics;

  /// Captured in [didChangeDependencies] so [_resolveMode]'s async cloud
  /// read doesn't reach through `context` after an await. Social is the
  /// `onboardingCompleted`-flag reader; connectivity gates the race
  /// commit so a still-unsynced returning player's race is never
  /// clobbered offline.
  SocialProvider? _social;
  ConnectivityProvider? _connectivity;

  /// Guards [_commitRaceAndStarterSkin] to a single early publish. The
  /// [_finish] commit re-runs unconditionally (idempotent) to absorb a
  /// race change made by stepping back to Step 1 after sign-in.
  bool _starterCommitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _social = context.read<SocialProvider>();
    _connectivity = context.read<ConnectivityProvider>();

    final cosmetics = context.read<CosmeticsProvider>();
    if (!identical(cosmetics, _cosmetics)) {
      _cosmetics?.removeListener(_onCosmeticsChanged);
      _cosmetics = cosmetics;
      _cosmetics!.addListener(_onCosmeticsChanged);
    }

    if (!_draftSeeded) {
      final persistedRace = cosmetics.currentRaceId;
      if (persistedRace != null &&
          HeroRaceCatalog.byId(persistedRace) != null) {
        _draftRaceId = persistedRace;
      }
      _draftSeeded = true;
    }

    // Covers the re-entered / already-signed-in-at-boot case where the
    // uid + cosmetics state are already bound before the first listener
    // fire: resolve the mode (new vs returning) and, for a new player,
    // publish the race early. Deferred to post-frame because the
    // returning-via-cloud-race branch flips [_mode] synchronously via
    // setState, which must not run inside this build pass.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_resolveModeThenMaybeCommit());
    });
  }

  @override
  void dispose() {
    _cosmetics?.removeListener(_onCosmeticsChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// `CosmeticsProvider` listener: every cosmetics notification after
  /// sign-in (uid bind, cloud pull-and-merge landing) is a chance to
  /// resolve the onboarding mode and — for a new player — publish the
  /// drafted race early so the social search thumbnail isn't the Google
  /// photo while onboarding finishes.
  void _onCosmeticsChanged() => unawaited(_resolveModeThenMaybeCommit());

  Future<void> _resolveModeThenMaybeCommit() async {
    await _resolveMode();
    _maybeCommitStarterAfterLogin();
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
    final social = context.read<SocialProvider>();

    final isReturning = _mode == _OnboardingMode.returning;

    // New player only: commit the drafted race + starter skin + welcome
    // pack. A returning player keeps the permanent race the cosmetics
    // pull-and-merge already restored from the cloud (committing the
    // default draft would clobber it), and gets the welcome pack back via
    // the cloud ledger replay — so we touch nothing for them here.
    if (!isReturning) {
      if (_canCommitRace(cosmetics)) {
        // Idempotent re-commit: the race + starter skin were usually
        // already published right after the Step 2 sign-in via
        // [_maybeCommitStarterAfterLogin]; running it again covers the
        // sign-in-late path. The guards inside also block any overwrite.
        await _commitRaceAndStarterSkin(cosmetics);
        if (!mounted) return;
      } else if (cosmetics.currentUid == null) {
        // Skipped sign-in (Step 2 is opt-in): cosmetic state is uid-scoped
        // so the race can't be persisted — the unauth path is a degraded
        // mode by design.
        AppLog.app.warn(
          'onboarding: finished without signed-in user — race not persisted',
          payload: 'draftRace=$_draftRaceId',
        );
      }

      if (cosmetics.currentUid != null) {
        try {
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
        } catch (e, st) {
          // Unlock / equip throws are already caught + logged inside the
          // provider; this `catch` is defensive against platform-level
          // failures (Isar I/O, etc.). Onboarding completion must not be
          // blocked by a transient cosmetic write — the player can
          // re-enter through DevTools reset if state ended up half-applied.
          AppLog.app.warn(
            'onboarding: welcome pack commit threw',
            payload: 'error=$e stack=$st',
          );
        }
        if (!mounted) return;
      }
    }

    // Settle the cloud ledger, open the engine evaluation gate, and run
    // the first pass. For a new player this mints `welcome_to_journey`
    // (no conditions) and queues its celebration before the routing gate
    // flips. For a returning player the awaited cloud pull has already
    // merged their prior welcome completion, so the engine resolves it as
    // already-done and queues nothing — fixing the duplicate celebration
    // on every reinstall.
    await progression.activateAfterOnboarding();
    if (!mounted) return;

    // Drain the queued celebration as fullscreen routes on top of the
    // welcome screen, so the player never sees MainShell until it's
    // dismissed. New players only — a returning player has nothing queued.
    if (!isReturning) {
      await _drainWelcomeCelebrations(progression, cosmetics);
      if (!mounted) return;
    }

    await onboarding.markCompleted();
    // Stamp the cloud `onboardingCompleted` flag — the load-bearing
    // "returning player" signal read on the next install / new device.
    // Fire-and-forget: completion must never be blocked by (or fail on) a
    // transient profile write. No-op when sign-in was skipped (no uid).
    unawaited(social.markOnboardingCompleted());
    // Routing in app.dart watches the provider — flipping completed
    // automatically swaps the home from WelcomeScreen to MainShell.
  }

  /// Whether it's safe to commit the drafted race. Guards:
  ///   * signed in + cosmetics state loaded,
  ///   * **no existing race** — never overwrite a returning player's
  ///     permanent cloud race (restored by the cosmetics pull-and-merge),
  ///   * **online** — so we don't write a default race that a returning
  ///     player whose cloud race hasn't pulled yet (offline / misdetected
  ///     as new) would push over their real race on reconnect. An offline
  ///     new player falls back to `ForcePickRaceScreen` once online.
  bool _canCommitRace(CosmeticsProvider cosmetics) {
    if (cosmetics.currentUid == null) return false;
    if (cosmetics.state == null) return false;
    if (cosmetics.currentRaceId != null) return false;
    if (!(_connectivity?.isOnline ?? true)) return false;
    return true;
  }

  /// Persists the drafted race + the starter `skin_pilgrim` for the
  /// bound user so the cosmetics state — and, through the social profile
  /// projection, the Firestore `users/{uid}` doc — carries `raceId` +
  /// `skinId` from the first publish. Without this, a friend who searches
  /// the user mid-onboarding (signed in at Step 2 but not yet finished)
  /// sees the Google account photo instead of the race-skin thumbnail.
  ///
  /// Best-effort: the skin unlock/equip are guarded and any platform-level
  /// throw is swallowed. Defends the never-overwrite invariant itself so
  /// it's safe regardless of caller — a returning player's existing race
  /// is never clobbered.
  Future<void> _commitRaceAndStarterSkin(CosmeticsProvider cosmetics) async {
    if (cosmetics.currentUid == null) return;
    // Never overwrite an existing race (defense-in-depth alongside
    // [_canCommitRace] at the call sites).
    if (cosmetics.currentRaceId != null) return;
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
      AppLog.app.info(
        'onboarding: race + starter skin committed',
        payload:
            'race=$_draftRaceId skin=$_starterSkinId uid=${cosmetics.currentUid}',
      );
    } catch (e, st) {
      AppLog.app.warn(
        'onboarding: race + starter skin commit threw',
        payload: 'race=$_draftRaceId error=$e stack=$st',
      );
    }
  }

  /// Resolves [_mode] once a uid is bound and the cosmetics cloud state
  /// has settled (so `currentRaceId` reflects the cloud, not a transient
  /// null). A cloud-restored race is the strongest "returning" signal;
  /// the explicit `onboardingCompleted` flag is the fallback. Resolves to
  /// new on no cloud race + flag false/unreadable — the race-commit guard
  /// ([_canCommitRace]) independently prevents clobbering when that
  /// "new" is actually an offline-misdetected returning player. Runs once.
  Future<void> _resolveMode() async {
    if (_mode != _OnboardingMode.undetermined || _resolvingMode) return;
    final cosmetics = _cosmetics;
    if (cosmetics == null ||
        cosmetics.currentUid == null ||
        cosmetics.state == null) {
      return;
    }
    _resolvingMode = true;
    try {
      var returning = cosmetics.currentRaceId != null;
      if (!returning) {
        returning = await _social?.fetchOnboardingCompleted() ?? false;
      }
      if (!mounted) return;
      setState(() {
        _mode = returning
            ? _OnboardingMode.returning
            : _OnboardingMode.newPlayer;
        // The returning flow drops the leading race step; snap the page
        // index to the account step (now index 0) the player just used
        // to sign in.
        if (_mode == _OnboardingMode.returning) _step = 0;
      });
      if (_mode == _OnboardingMode.returning) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
      AppLog.app.info('onboarding: mode resolved', payload: 'mode=$_mode');
    } finally {
      _resolvingMode = false;
    }
  }

  /// Fires [_commitRaceAndStarterSkin] exactly once, as soon as the
  /// cosmetics provider has a loaded, uid-bound state and the player is a
  /// (new, online) candidate for a race commit — i.e. right after the
  /// Step 2 Google sign-in (or immediately, if onboarding was re-entered
  /// while already signed in). Wired through the `CosmeticsProvider`
  /// listener in [didChangeDependencies] (via [_resolveModeThenMaybeCommit]).
  void _maybeCommitStarterAfterLogin() {
    if (_starterCommitted) return;
    final cosmetics = _cosmetics;
    if (cosmetics == null) return;
    // Returning players keep their cloud race — never publish a draft.
    if (_mode == _OnboardingMode.returning) return;
    if (!_canCommitRace(cosmetics)) return;
    _starterCommitted = true;
    unawaited(_commitRaceAndStarterSkin(cosmetics));
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

  /// Step pages for the current [_mode]. New / undetermined players get
  /// the full 4-step flow (race pick first); returning players drop the
  /// leading race step (3-step quick setup). Index 0 differs between the
  /// two lists — [_resolveMode] snaps `_step` to 0 (account) on the flip
  /// so the page controller stays in range.
  List<Widget> _stepPages() {
    if (_mode == _OnboardingMode.returning) {
      return const [
        _StepScroll(child: StepAccount()),
        _StepScroll(child: StepHealth()),
        _StepScroll(child: StepFinal()),
      ];
    }
    return [
      _StepScroll(
        child: StepWelcome(
          draftRaceId: _draftRaceId,
          onPickRace: _onPickRace,
        ),
      ),
      const _StepScroll(child: StepAccount()),
      const _StepScroll(child: StepHealth()),
      const _StepScroll(child: StepFinal()),
    ];
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
                    children: _stepPages(),
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
