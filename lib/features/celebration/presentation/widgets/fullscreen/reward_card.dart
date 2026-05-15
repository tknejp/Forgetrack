import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/models/celebration_event.dart';
import '../../../domain/models/celebration_reward.dart';
import '../shared/reward_thumb.dart';
import '../shared/type_badge.dart';

/// Single 240×300 fanned reward card. The active card gets a stronger
/// shadow + inner radial glow; inactives fade into the background.
class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.type,
    required this.active,
  });

  static const double width = 240;
  static const double height = 300;

  final CelebrationReward reward;

  /// Celebration-level type — kept on the API for callers that may want
  /// type-specific styling later, but the card's badge now reflects the
  /// individual reward's kind, not this.
  final CelebrationType type;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final token = CelebrationRarityToken.forIndex(reward.rarity.index);
    // Opaque card body. Top is the rarity color blended into the dark
    // surface so the rarity reads through but the card never lets the
    // backdrop show through. Bottom fades into a slightly darker surface.
    const baseSurface = Color(0xFF141430);
    const bottomSurface = Color(0xFF0F1226);
    final tintedTop =
        Color.alphaBlend(token.color.withValues(alpha: 0.32), baseSurface);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tintedTop, baseSurface, bottomSurface],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: token.color.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: token.glow.withValues(alpha: 0.55),
                  blurRadius: 40,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: token.color.withValues(alpha: 0.40),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: -10,
                ),
              ],
      ),
      child: Stack(
        children: [
          if (active)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.9,
                      colors: [
                        token.glow.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: RewardKindBadgePill(
                    kind: reward.kind,
                    label: reward.kind.label(l10n).toUpperCase(),
                    color: token.color,
                  ),
                ),
                const SizedBox(height: 18),
                RewardDisc(reward: reward),
                const Spacer(),
                Text(
                  reward.rarity.label(l10n).toUpperCase(),
                  style: TextStyle(
                    color: token.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reward.name(l10n),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF5F3FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                if (reward.sub != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reward.sub!(l10n),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7C2E0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
