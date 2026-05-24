import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../domain/models/celebration_reward.dart';
import 'type_badge.dart';

/// Square reward thumbnail (topsheet rows). Renders the asset preview when
/// available, falling back to a kind-typed icon. The frame is rarity-tinted.
class RewardThumb extends StatelessWidget {
  const RewardThumb({
    super.key,
    required this.reward,
    this.size = 42,
    this.iconSize = 22,
  });

  final CelebrationReward reward;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final token = CelebrationRarityToken.forIndex(reward.rarity.index);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            token.color.withValues(alpha: 0.18),
            token.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: token.rim.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(token.color),
    );
  }

  Widget _buildContent(Color tint) {
    final assetPath = reward.assetPath;
    final icon = reward.fallbackIcon ?? iconForRewardKind(reward.kind);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(icon, size: iconSize, color: tint)),
      );
    }
    return Center(child: Icon(icon, size: iconSize, color: tint));
  }
}

/// Frameless reward presentation used at the center of a fullscreen reward
/// card. Just the asset (or fallback icon) sitting on top of a soft glow
/// halo — no disc, no border, no inner highlight. The asset is shown
/// `BoxFit.contain` so frames / cosmetics keep their natural shape.
class RewardDisc extends StatelessWidget {
  const RewardDisc({
    super.key,
    required this.reward,
    this.size = 120,
    this.iconSize = 64,
  });

  final CelebrationReward reward;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final token = CelebrationRarityToken.forIndex(reward.rarity.index);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radial glow halo behind the asset. Uses the rarity color
          // at low alpha so it lifts the asset without competing with it.
          IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    token.color.withValues(alpha: 0.45),
                    token.color.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          _buildContent(token.color),
        ],
      ),
    );
  }

  Widget _buildContent(Color tint) {
    final assetPath = reward.assetPath;
    final icon = reward.fallbackIcon ?? iconForRewardKind(reward.kind);
    if (assetPath != null) {
      final image = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(icon, size: iconSize, color: tint),
      );
      if (reward.kind == CelebrationRewardKind.companion) {
        // Companion source canvases are bottom-biased — the silhouette
        // centre sits ~60% down because of the empty foot pad. A raw
        // `BoxFit.contain` render lands the silhouette below the glow
        // halo's bright core. Reserve bottom padding proportional to
        // the disc so the silhouette lifts back into the halo.
        return Padding(
          padding: EdgeInsets.only(bottom: size * 0.12),
          child: image,
        );
      }
      return image;
    }
    return Icon(icon, size: iconSize, color: tint);
  }
}

