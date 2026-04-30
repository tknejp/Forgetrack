import 'package:flutter/material.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_l10n.dart';

/// Grid tile for a cosmetic in a collection screen. Renders unlocked/locked
/// states and an optional "equipped" badge. Designed to be safe when the
/// asset is missing — never throws on a missing image.
class CosmeticCollectionTile extends StatelessWidget {
  const CosmeticCollectionTile({
    super.key,
    required this.definition,
    required this.isUnlocked,
    this.isEquipped = false,
    this.config,
    this.l10n,
    this.onTap,
  });

  final CosmeticDefinition definition;
  final bool isUnlocked;
  final bool isEquipped;
  final CosmeticsConfig? config;
  final CosmeticsL10n? l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = (config ?? CosmeticsConfig.standard())
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final rarityColor = _rarityColor(definition.rarity);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: FtTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rarityColor.withValues(alpha: isUnlocked ? 0.7 : 0.25),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: assetPath != null
                  ? Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _Placeholder(rarityColor: rarityColor),
                    )
                  : _Placeholder(rarityColor: rarityColor),
            ),
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.60),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 28,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Text(
                  l10n?.name(definition) ?? definition.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            if (isEquipped)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: FtTokens.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n?.equippedBadge ?? 'EQUIPPED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _rarityColor(CosmeticRarity rarity) {
    switch (rarity) {
      case CosmeticRarity.common:
        return const Color(0xFF8E8E8E);
      case CosmeticRarity.rare:
        return const Color(0xFF58A6FF);
      case CosmeticRarity.epic:
        return const Color(0xFFB388FF);
      case CosmeticRarity.legendary:
        return const Color(0xFFFFD54F);
    }
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.rarityColor});

  final Color rarityColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withValues(alpha: 0.35),
            rarityColor.withValues(alpha: 0.10),
          ],
        ),
      ),
    );
  }
}
