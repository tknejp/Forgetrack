import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';

/// Compact tile for an equipped cosmetic — small thumbnail + two-line label
/// (type small caps, cosmetic name on the next line). Designed to flow in
/// a `Wrap` (cosmetics debug screen) or be wrapped in `Expanded` cells of
/// a `Row` (hero "Vybraná výbava" row).
///
/// Pass an [AppLocalizations] to render translated names; without it the
/// chip falls back to the cosmetic id.
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
  final AppLocalizations? l10n;
  final CosmeticsConfig? config;
  final String? labelOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetPath = (config ?? CosmeticsConfig.standard())
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final l10n = this.l10n;
    final name =
        labelOverride ?? (l10n != null ? definition.name(l10n) : definition.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusInner),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Thumbnail(
              assetPath: assetPath,
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
                      fontSize: Tokens.fontSizeTiny,
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
                      fontSize: Tokens.fontSizeSmall,
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
    required this.type,
    required this.size,
  });

  final String? assetPath;
  final CosmeticType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: assetPath != null
          ? Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _ThumbFallback(
                type: type,
                size: size,
              ),
            )
          : _ThumbFallback(
              type: type,
              size: size,
            ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback({
    required this.type,
    required this.size,
  });

  final CosmeticType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        _iconForType(type),
        size: size * 0.5,
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
