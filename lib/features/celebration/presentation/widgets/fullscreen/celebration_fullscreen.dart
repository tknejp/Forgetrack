import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/models/celebration_event.dart';
import '../../../domain/models/celebration_reward.dart';
import '../shared/aura_layer.dart';
import '../shared/particles_layer.dart';
import '../shared/rays_layer.dart';
import '../shared/xp_award_pill.dart';
import 'pagination_dots.dart';
import 'reward_card_stack.dart';

/// Variant C — fullscreen multi-reward celebration with a fanned card stack.
/// Pushed via [openCelebrationFullscreen] which wraps the standard
/// PageRoute machinery. The widget itself is intentionally agnostic about
/// how it was pushed; it only knows how to dismiss itself via [onDismiss].
class CelebrationFullscreen extends StatefulWidget {
  const CelebrationFullscreen({
    super.key,
    required this.event,
    required this.onDismiss,
    required this.onOpenInventory,
  });

  final CelebrationEvent event;
  final VoidCallback onDismiss;

  /// Optional. When non-null *and* the event has at least one wearable
  /// reward, the secondary CTA "Otevřít inventář →" is shown. The callback
  /// is responsible for navigating after the fullscreen has dismissed.
  /// The optional `focusCompanionId` is set when the event's headline
  /// reward is a companion availability — the inventory screen uses it
  /// to land directly on that companion's details sheet.
  final void Function({String? focusCompanionId})? onOpenInventory;

  @override
  State<CelebrationFullscreen> createState() => _CelebrationFullscreenState();
}

class _CelebrationFullscreenState extends State<CelebrationFullscreen>
    with SingleTickerProviderStateMixin {
  late final RewardStackController _stack = RewardStackController(
    rewardCount: widget.event.rewards.isEmpty ? 1 : widget.event.rewards.length,
  );

  // Drives the staged entry: backdrop / FX → header → cards → CTA. The
  // route already does a quick presence fade (≈250 ms); this controller
  // continues the reveal so the heavier compositing layers (BackdropFilter,
  // particles) get a frame to warm up before the cards appear.
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Animation<double> _stagedOpacity(Interval interval) =>
      CurvedAnimation(parent: _entry, curve: interval);

  @override
  void initState() {
    super.initState();
    _stack.addListener(_onStackChanged);
    _entry.forward();
  }

  @override
  void dispose() {
    _stack.removeListener(_onStackChanged);
    _stack.dispose();
    _entry.dispose();
    super.dispose();
  }

  void _onStackChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasWearable => widget.event.rewards.any(_isWearable);
  bool get _hasCompanion =>
      widget.event.rewards.any((r) => r.kind == CelebrationRewardKind.companion);

  /// Pulls the companion id off the first companion reward in the event
  /// (typically the only one) so the inventory CTA can land directly on
  /// that companion's details sheet. Reward ids are namespaced
  /// `companion-<id>` (see `_companionPreviewCard` in the adapter) or
  /// `cosmetic-<id>` (for orphan cosmetic grants of type companion).
  String? get _focusCompanionId {
    for (final r in widget.event.rewards) {
      if (r.kind != CelebrationRewardKind.companion) continue;
      final id = r.id;
      const prefixes = ['companion-', 'cosmetic-'];
      for (final p in prefixes) {
        if (id.startsWith(p)) return id.substring(p.length);
      }
      return id;
    }
    return null;
  }

  static bool _isWearable(CelebrationReward r) =>
      r.kind == CelebrationRewardKind.frame ||
      r.kind == CelebrationRewardKind.background ||
      r.kind == CelebrationRewardKind.companion;

  void _dismiss() => widget.onDismiss();

  void _handlePrimary() {
    if (_stack.atLast || widget.event.rewards.isEmpty) {
      _dismiss();
    } else {
      _stack.advance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ft = context.ft;
    final event = widget.event;
    final token = CelebrationRarityToken.forIndex(event.headRarity.index);

    // Stage intervals: each section reveals in its own band so the
    // backdrop and FX have time to settle before the cards arrive.
    final backdropFade =
        _stagedOpacity(const Interval(0.0, 0.45, curve: Curves.easeOut));
    final fxFade =
        _stagedOpacity(const Interval(0.10, 0.65, curve: Curves.easeOut));
    final headerFade =
        _stagedOpacity(const Interval(0.25, 0.65, curve: Curves.easeOut));
    final cardsFade = _stagedOpacity(
        const Interval(0.45, 1.0, curve: Cubic(0.16, 1.0, 0.30, 1.0)));
    final ctaFade =
        _stagedOpacity(const Interval(0.55, 1.0, curve: Curves.easeOut));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: backdropFade,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 1.0,
                    colors: [
                      token.color.withValues(alpha: 0.18),
                      const Color(0xCC0B0F1E),
                      const Color(0xF202030B),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: fxFade,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AuraLayer(
                      rarity: event.headRarity,
                      intensity: 0.7,
                      alignment: const Alignment(0, -0.5),
                    ),
                    RaysLayer(rarity: event.headRarity, intensity: 0.5),
                    ParticlesLayer(
                      rarity: event.headRarity,
                      count: 14,
                      intensity: 0.7,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: FadeTransition(
                      opacity: headerFade,
                      child: _CloseButton(onTap: _dismiss),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: headerFade,
                    child: Text(
                      event.eyebrow(l10n).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: token.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                        shadows: [
                          Shadow(
                            color: token.glow.withValues(alpha: 0.55),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: headerFade,
                    child: Text(
                      event.title(l10n),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF5F3FF),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: headerFade,
                      child: Text(
                        event.description!(l10n),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ft.onSurfaceMuted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  if (event.xpAward != null) ...[
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: headerFade,
                      child: CelebrationXpAwardPill(
                        amount: event.xpAward!.amount,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (event.rewards.isNotEmpty)
                    AnimatedBuilder(
                      animation: cardsFade,
                      builder: (context, child) {
                        final t = cardsFade.value;
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 24),
                            child: Transform.scale(
                              scale: 0.92 + 0.08 * t,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: RewardCardStack(
                        event: event,
                        controller: _stack,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: cardsFade,
                    child: PaginationDots(
                      count: event.rewards.length,
                      activeIndex: _stack.activeIndex,
                      headRarity: event.headRarity,
                      onTap: _stack.setActive,
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: ctaFade,
                    child: _PrimaryCta(
                      label: l10n.celebrationContinue,
                      color: token.color,
                      glow: token.glow,
                      onTap: _handlePrimary,
                    ),
                  ),
                  if (widget.onOpenInventory != null && _hasWearable) ...[
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: ctaFade,
                      child: TextButton(
                        onPressed: () {
                          final companionId = _focusCompanionId;
                          _dismiss();
                          widget.onOpenInventory!(
                            focusCompanionId: companionId,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC7C2E0),
                        ),
                        child: Text(
                          _hasCompanion
                              ? l10n.celebrationClaimCompanion
                              : l10n.celebrationOpenInventory,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.color,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF0B0F1E),
          elevation: 0,
          shadowColor: glow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.celebrationCloseSemantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xCC0B0F1E),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Color(0xFFC7C2E0),
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Pushes the fullscreen celebration as a non-opaque PageRoute. Returns when
/// the user dismisses (or when [event] is exhausted).
Future<void> openCelebrationFullscreen({
  required BuildContext context,
  required CelebrationEvent event,
  void Function({String? focusCompanionId})? onOpenInventory,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      // Short presence fade for the route itself; the staged reveal
      // (backdrop → FX → header → cards → CTA) is driven by the
      // CelebrationFullscreen's internal controller so the heavier
      // compositing layers settle before the cards appear.
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondary) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: CelebrationFullscreen(
            event: event,
            onDismiss: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            },
            onOpenInventory: onOpenInventory,
          ),
        );
      },
    ),
  );
}
