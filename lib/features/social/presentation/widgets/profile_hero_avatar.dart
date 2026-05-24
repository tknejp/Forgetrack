import 'package:flutter/material.dart';

import '../../../cosmetics/config/skin_asset_resolver.dart';
import '../../../cosmetics/domain/cosmetic_catalog.dart';

/// Full-body hero avatar — drives the asymmetric "hero on the left,
/// companion on the right" composition. No frame border applied
/// (frames live on the compact thumbnail surfaces only).
class ProfileHeroBodyAvatar extends StatelessWidget {
  const ProfileHeroBodyAvatar({
    super.key,
    required this.raceId,
    required this.skinId,
    required this.fallbackLabel,
    required this.size,
  });

  final String? raceId;
  final String? skinId;
  final String fallbackLabel;
  final double size;

  static const _resolver = SkinAssetResolver();

  @override
  Widget build(BuildContext context) {
    final skinDef = skinId == null ? null : const CosmeticCatalog().byId(skinId!);
    final assetPath = _resolver.resolve(
      raceId: raceId,
      skinAssetKey: skinDef?.assetKey,
      variant: SkinAssetVariant.fullBody,
    );
    if (assetPath == null) {
      return _HeroSilhouette(label: fallbackLabel, size: size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        // Sharp pixel art — no bilinear sampling.
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            _HeroSilhouette(label: fallbackLabel, size: size),
      ),
    );
  }
}

class _HeroSilhouette extends StatelessWidget {
  const _HeroSilhouette({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: size * 0.55,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          if (size >= 100) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
