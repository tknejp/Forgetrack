import 'package:flutter/material.dart';

import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_l10n.dart';

/// Compact tile for an equipped cosmetic — small thumbnail + two-line label
/// (type small caps, cosmetic name on the next line). Designed to flow in
/// a `Wrap` (cosmetics debug screen) or be wrapped in `Expanded` cells of
/// a `Row` (hero "Vybraná výbava" row).
///
/// Pass a [CosmeticsL10n] to render translated names; without it the chip
/// falls back to the cosmetic id.
class CosmeticEquippedChip extends StatelessWidget {
  const CosmeticEquippedChip({
    super.key,
    required this.definition,
    this.l10n,
    this.config,
    this.labelOverride,
    this.onTap,
  });

  final CosmeticDefinition definition;
  final CosmeticsL10n? l10n;
  final CosmeticsConfig? config;
  final String? labelOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetPath = (config ?? CosmeticsConfig.standard())
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final name = labelOverride ?? l10n?.name(definition) ?? definition.id;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Thumbnail(
              assetPath: assetPath,
              rarity: definition.rarity,
              type: definition.type,
              size: 32,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _typeLabel(definition.type).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.assetPath,
    required this.rarity,
    required this.type,
    required this.size,
  });

  final String? assetPath;
  final CosmeticRarity rarity;
  final CosmeticType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(rarity);
    final radius = BorderRadius.circular(size * 0.28);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: rarityColor.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath != null
          ? Image.asset(
              assetPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ThumbFallback(
                rarityColor: rarityColor,
                type: type,
                size: size,
              ),
            )
          : _ThumbFallback(
              rarityColor: rarityColor,
              type: type,
              size: size,
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

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback({
    required this.rarityColor,
    required this.type,
    required this.size,
  });

  final Color rarityColor;
  final CosmeticType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withValues(alpha: 0.45),
            rarityColor.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _iconForType(type),
          size: size * 0.5,
          color: Colors.white.withValues(alpha: 0.85),
        ),
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

// Hardcoded Czech labels — debug-quality. Promote to l10n once the
// collection screen ships.
String _typeLabel(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return 'Rámeček';
    case CosmeticType.relic:
      return 'Relikvie';
    case CosmeticType.background:
      return 'Pozadí';
    case CosmeticType.emblem:
      return 'Znak';
    case CosmeticType.companion:
      return 'Společník';
    case CosmeticType.titleFlair:
      return 'Titul';
    case CosmeticType.mapEffect:
      return 'Efekt mapy';
  }
}
