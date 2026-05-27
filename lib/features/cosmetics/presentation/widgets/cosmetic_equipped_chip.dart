import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_screen_internals.dart';
import 'cosmetic_preview_frame.dart';
import 'cosmetic_preview_path.dart';

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
    this.raceId,
    this.labelOverride,
    this.onTap,
  });

  final Cosmetic definition;
  final AppLocalizations? l10n;
  final CosmeticsConfig? config;

  /// Player's selected race id. Skin previews need it to land on the
  /// race-specific thumbnail (`assets/cosmetics/skins/<race>/<id>_thumb.png`);
  /// non-skin types ignore it. Null is safe — skin chips fall back to
  /// the type-icon placeholder.
  final String? raceId;
  final String? labelOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetPath = resolveCosmeticPreviewPath(
      definition,
      config: config ?? CosmeticsConfig.standard(),
      raceId: raceId,
    );
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
              rarity: definition.rarity,
              size: 32,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (l10n != null) ...[
                    Text(
                      cosmeticTypeLabel(definition.type, l10n).toUpperCase(),
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
                  ],
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
    required this.rarity,
    required this.size,
  });

  final String? assetPath;
  final CosmeticType type;
  final Rarity rarity;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return SizedBox(
        width: size,
        height: size,
        child: _ThumbFallback(type: type, size: size),
      );
    }
    return CosmeticPreviewFrame(
      size: size,
      borderColor: cosmeticRarityColor(rarity),
      child: Image.asset(
        assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _ThumbFallback(type: type, size: size),
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
    case CosmeticType.skin:
      return Icons.person;
    case CosmeticType.banner:
      return Icons.flag;
  }
}

