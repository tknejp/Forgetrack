import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
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
  final PageController _pageController = PageController();
  int _step = 0;

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

  Future<void> _finish() async {
    await context.read<OnboardingProvider>().markCompleted();
    // Routing in app.dart watches the provider — flipping completed
    // automatically swaps the home from WelcomeScreen to MainShell.
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
                    children: const [
                      _StepScroll(child: StepWelcome()),
                      _StepScroll(child: StepAccount()),
                      _StepScroll(child: StepHealth()),
                      _StepScroll(child: StepFinal()),
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
