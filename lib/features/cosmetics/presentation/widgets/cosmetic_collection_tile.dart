import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusInner),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface.withValues(alpha: isUnlocked ? 0.52 : 0.28),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            _Placeholder(type: definition.type),
                      )
                    : _Placeholder(type: definition.type),
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
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
                    fontSize: Tokens.fontSizeCaption,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.54),
                    borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    l10n?.equippedBadge ?? 'EQUIPPED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: Tokens.fontSizeTiny,
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
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.type});

  final CosmeticType type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        _iconForType(type),
        size: 32,
        color: Tokens.onSurfaceFaint,
      ),
    );
  }
}

IconData _iconForType(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return Icons.crop_square;
    case CosmeticType.relic:
      return Icons.auto_awesome;
    case CosmeticType.background:
      return Icons.landscape;
    case CosmeticType.emblem:
      return Icons.shield;
    case CosmeticType.companion:
      return Icons.pets;
    case CosmeticType.titleFlair:
      return Icons.title;
    case CosmeticType.mapEffect:
      return Icons.map;
  }
}
