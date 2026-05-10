import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/models/celebration_event.dart';
import '../shared/aura_layer.dart';
import '../shared/particles_layer.dart';
import '../shared/type_badge.dart';
import 'claim_button.dart';
import 'topsheet_reward_row.dart';

/// Variant D — top-anchored small-win celebration. Renders a stack of:
///   * Backdrop blur + dark gradient
///   * Soft aura + light particle field (rarity-tinted)
///   * Header (icon-square + eyebrow + title + close)
///   * Optional rewards strip
///   * Optional claim button (gold pill)
///
/// Entry animation: 700ms slide-down + fade. The header icon-square plays its
/// own pop after a 100ms delay (owned by [TypeIconSquare]).
class CelebrationTopsheet extends StatefulWidget {
  const CelebrationTopsheet({
    super.key,
    required this.event,
    required this.onDismiss,
    required this.onClaimAttempt,
  });

  final CelebrationEvent event;
  final VoidCallback onDismiss;

  /// Invoked once the user taps the claim button — receives the
  /// rewardKey and is responsible for the idempotent provider call. Returns
  /// when the upstream operation completes (button stays in `claimed`
  /// state regardless of outcome since the visual flip is one-way).
  final Future<void> Function(String rewardKey) onClaimAttempt;

  @override
  State<CelebrationTopsheet> createState() => _CelebrationTopsheetState();
}

class _CelebrationTopsheetState extends State<CelebrationTopsheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _curve = CurvedAnimation(
      parent: _entry,
      curve: const Cubic(0.16, 1.0, 0.30, 1.0),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    // Outer border + glow now follow the head rarity (matches the inner
    // icon-square and the rarity-driven aura behind the content), so the
    // whole topsheet reads as one rarity-coherent surface.
    final accent =
        CelebrationRarityToken.forIndex(event.headRarity.index).color;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, child) {
            final t = _curve.value;
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * -30),
                child: child,
              ),
            );
          },
          child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xEB0F1226),
                          Color(0xF20B0F1E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.34),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.40),
                          blurRadius: 40,
                          offset: const Offset(0, 14),
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: IgnorePointer(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AuraLayer(
                                      rarity: event.headRarity,
                                      intensity: 0.5,
                                      alignment: const Alignment(0, -1.0),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: ParticlesLayer(
                                      rarity: event.headRarity,
                                      count: 8,
                                      intensity: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(
                                event: event,
                                onDismiss: widget.onDismiss,
                              ),
                              if (event.rewards.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _RewardsStrip(
                                  event: event,
                                  parentAnimation: _curve,
                                ),
                              ],
                              if (event.claim != null) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ClaimButton(
                                    xpAmount: event.claim!.xpAmount,
                                    onClaim: () => widget.onClaimAttempt(
                                      event.claim!.rewardKey,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.onDismiss});

  final CelebrationEvent event;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    // Tie the kicker label and icon-square to the head rarity rather than
    // the celebration's type accent. The type accent for `level` is xp
    // gold, which collided visually with legendary rarity gold and made
    // a Level 35 celebration with a rare reward look like a legendary
    // moment.
    final rarityToken =
        CelebrationRarityToken.forIndex(event.headRarity.index);
    final accent = rarityToken.color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TypeIconSquare(type: event.type, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.eyebrow(l10n).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.title(l10n),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ft.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              if (event.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  event.description!(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ft.onSurfaceMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CloseButton(onTap: onDismiss),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(
            Icons.close_rounded,
            color: ft.onSurfaceMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _RewardsStrip extends StatelessWidget {
  const _RewardsStrip({required this.event, required this.parentAnimation});

  final CelebrationEvent event;
  final Animation<double> parentAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent =
        CelebrationRarityToken.forIndex(event.headRarity.index).color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.progQuestDetailRewards.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < event.rewards.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == event.rewards.length - 1 ? 0 : 8),
            child: _StaggeredFadeIn(
              parent: parentAnimation,
              startAt: 0.25 + i * 0.10,
              child: TopsheetRewardRow(reward: event.rewards[i]),
            ),
          ),
      ],
    );
  }
}

/// Drives a child's opacity + slight slide-up using a portion of the parent
/// curve. Used for the staggered reward-row entry.
class _StaggeredFadeIn extends StatelessWidget {
  const _StaggeredFadeIn({
    required this.parent,
    required this.startAt,
    required this.child,
  });

  final Animation<double> parent;
  final double startAt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clamped = startAt.clamp(0.0, 0.9);
    return AnimatedBuilder(
      animation: parent,
      builder: (context, child) {
        final raw = (parent.value - clamped) / (1 - clamped);
        final t = raw.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
