import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'onboarding_theme.dart';

/// Header progress strip. 4 horizontal pill-shaped dots, the active dot
/// widens. Animated 300ms linear per the design spec.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalSteps; i++)
          Padding(
            padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
              height: 4,
              width: i == currentStep ? 22 : 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i <= currentStep
                    ? OnboardingTheme.purpleAccent
                    : const Color.fromRGBO(167, 139, 250, 0.18),
              ),
            ),
          ),
      ],
    );
  }
}

/// Step icon shown at the top of steps 2–4. Larger glyph on a
/// double-layered tinted glow halo — no container, no border, no fill.
/// The two stacked radial layers (a tight bright core + a wider soft
/// bloom) are what gives the asset a luminous "lit-from-within" feel.
class StepIcon extends StatelessWidget {
  const StepIcon({
    super.key,
    required this.tint,
    this.emoji,
    this.assetPath,
  }) : assert(emoji != null || assetPath != null,
            'StepIcon needs either emoji or assetPath');

  final Color tint;
  final String? emoji;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer wide bloom.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tint.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                  radius: 0.55,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            // Inner brighter core.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tint.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  radius: 0.35,
                ),
              ),
              child: const SizedBox.expand(),
            ),
            if (assetPath != null)
              Image.asset(assetPath!,
                  width: 88, height: 88, fit: BoxFit.contain)
            else
              Text(emoji!, style: const TextStyle(fontSize: 56, height: 1)),
          ],
        ),
      ),
    );
  }
}

/// Twinkling 4-pointed star used around the hero icon on Step 1.
///
/// All sparkles share a single `AnimationController` driven by the
/// caller (so we only spin one ticker for the whole cluster). Each
/// sparkle takes a `phaseOffset` in [0, 1) which staggers when its
/// peak hits within the 2.4s loop — matching the `wm-spark` keyframes
/// from the design (opacity 0 → 1 → 0, scale 0.4 → 1 → 0.4).
class AnimatedSparkle extends StatelessWidget {
  const AnimatedSparkle({
    super.key,
    required this.animation,
    required this.phaseOffset,
    required this.size,
    this.color = const Color(0xFFF4C152),
  });

  final Animation<double> animation;
  final double phaseOffset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final phase = (animation.value + phaseOffset) % 1.0;
        // sin(π·phase) → 0 at the edges, 1 at phase=0.5, smooth ease.
        final envelope = math.sin(math.pi * phase).clamp(0.0, 1.0);
        final opacity = envelope;
        final scale = 0.4 + 0.6 * envelope;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: size,
                color: color,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Centered title + subtitle pair used by steps 2–4.
class StepHeading extends StatelessWidget {
  const StepHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: OnboardingTheme.stepHeading,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: OnboardingTheme.stepSubtitle.copyWith(
                color: OnboardingTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 56×52 footer back chevron. Hidden on step 0 by the caller.
class BackBtn extends StatelessWidget {
  const BackBtn({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 52,
        decoration: BoxDecoration(
          color: OnboardingTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OnboardingTheme.borderMid),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.chevron_left_rounded,
          size: 22,
          color: Color(0xFFC7C2E0),
        ),
      ),
    );
  }
}

/// Footer primary CTA. Purple gradient with an optional leading wand
/// (✦) on the final step and a trailing chevron on intermediate steps.
class PrimaryBtn extends StatelessWidget {
  const PrimaryBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.showArrow = false,
    this.showWand = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showArrow;
  final bool showWand;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: OnboardingTheme.primaryCtaGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: OnboardingTheme.primaryCtaShadow,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showWand) ...[
                const Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: OnboardingTheme.ctaLabel.copyWith(color: Colors.white),
              ),
              if (showArrow) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny labelled section header used in Step 1 hero card and Step 4
/// quests preview ("✦ TVŮJ START", "✦ PRVNÍ QUESTY").
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '✦ $text',
      style: OnboardingTheme.sectionLabel.copyWith(color: color),
    );
  }
}
