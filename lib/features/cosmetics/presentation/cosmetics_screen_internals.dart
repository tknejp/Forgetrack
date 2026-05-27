import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../domain/cosmetic_models.dart';

// ── Shared badge widget ───────────────────────────────────────────────────────

class CosmeticBadge extends StatelessWidget {
  const CosmeticBadge({
    super.key,
    required this.definition,
    required this.assetPath,
    required this.color,
    this.size = 42,
    this.framed = true,
    this.glow = false,
    this.fit,
    this.contentScale = 1.0,
    this.applyDisplayScale = true,
  });

  final Cosmetic definition;
  final String? assetPath;
  final Color color;
  final double size;

  /// Draws the old badge container/border.
  ///
  /// Keep true for grid/list cards.
  /// Use false in detail sheet when the raw asset should be shown.
  final bool framed;

  /// Draws a soft rarity-colored glow behind the asset.
  ///
  /// Intended mainly for detail sheet previews.
  final bool glow;

  /// Optional override for image fit.
  ///
  /// Detail sheet should usually use BoxFit.contain.
  final BoxFit? fit;

  /// Scale factor for the content within the badge.
  final double contentScale;

  /// Whether to fold a `Companion.displayScale` boost into the rendered
  /// scale. The catalog's per-companion `displayScale` was calibrated
  /// against the *full* painted asset (silhouette with natural margin
  /// inside the 512² canvas), so applying it on top of the compact
  /// preview thumb — which is already painted edge-to-edge — visibly
  /// crops the artwork inside the tile. Surfaces that render the
  /// preview thumb (inventory card, slot picker) pass `false`;
  /// scene-size surfaces stay on `true` for the full asset.
  final bool applyDisplayScale;

  @override
  Widget build(BuildContext context) {
    final isFrame = definition is Frame;
    final isCompanion = definition is Companion;
    final effectiveFit = fit ?? (isFrame ? BoxFit.contain : BoxFit.cover);
    // Companion silhouettes vary wildly inside the 512² canvas — some
    // are tiny and low-biased (ember sprite), others span almost the
    // full canvas (mountain gryphon). Fold the catalog row's per-asset
    // `displayScale` into the per-call `contentScale` so each
    // companion reads at a comparable visual size on every preview
    // surface; non-companion types are unaffected.
    final effectiveContentScale = isCompanion && applyDisplayScale
        ? contentScale * (definition as Companion).displayScale
        : contentScale;

    final content = assetPath == null
        ? CosmeticBadgeFallback(
            type: definition.type,
            color: color,
            size: size,
            framed: framed,
          )
        : Image.asset(
            assetPath!,
            fit: effectiveFit,
            errorBuilder: (_, __, ___) => CosmeticBadgeFallback(
              type: definition.type,
              color: color,
              size: size,
              framed: framed,
            ),
          );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow)
            IgnorePointer(
              child: Container(
                width: size * 0.68,
                height: size * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.32),
                      blurRadius: size * 0.30,
                      spreadRadius: size * 0.045,
                    ),
                  ],
                ),
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: framed
                ? BoxDecoration(
                    color: color.withValues(alpha: isFrame ? 0.10 : 0.18),
                    borderRadius: BorderRadius.circular(size * 0.28),
                    border: Border.all(
                      color: color.withValues(alpha: isFrame ? 0.52 : 0.32),
                      width: isFrame ? 1.8 : 1,
                    ),
                  )
                : null,
            clipBehavior: framed && !isFrame ? Clip.antiAlias : Clip.none,
            // Companions are bottom-biased inside the 512² canvas (silhouette
            // centre sits below the geometric centre across most assets).
            // Default centre-anchored scaling drops the silhouette toward the
            // tile floor; anchor the zoom below centre so the body lifts
            // upward and any empty top/bottom padding bleeds off the
            // long axis instead. Matches the morph / forging / details
            // header anchors so a companion that appears in two surfaces
            // side-by-side reads at the same vertical position.
            child: Transform.scale(
              scale: effectiveContentScale,
              alignment:
                  isCompanion ? const Alignment(0, 0.5) : Alignment.center,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class CosmeticBadgeFallback extends StatelessWidget {
  const CosmeticBadgeFallback({
    super.key,
    required this.type,
    required this.color,
    required this.size,
    this.framed = true,
  });

  final CosmeticType type;
  final Color color;
  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      cosmeticIconForType(type),
      color: framed
          ? Colors.white.withValues(alpha: 0.9)
          : color.withValues(alpha: 0.9),
      size: size * 0.52,
    );

    if (!framed) {
      return Center(child: icon);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(child: icon),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

IconData cosmeticIconForType(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return Icons.crop_square_rounded;
    case CosmeticType.relic:
      return Icons.auto_awesome_rounded;
    case CosmeticType.background:
      return Icons.landscape_rounded;
    case CosmeticType.emblem:
      return Icons.shield_rounded;
    case CosmeticType.companion:
      return Icons.pets_rounded;
    case CosmeticType.titleFlair:
      return Icons.title_rounded;
    case CosmeticType.mapEffect:
      return Icons.map_rounded;
    case CosmeticType.skin:
      return Icons.person_rounded;
    case CosmeticType.banner:
      return Icons.flag_rounded;
  }
}

String cosmeticTypeLabel(CosmeticType type, AppLocalizations l10n) {
  switch (type) {
    case CosmeticType.frame:
      return l10n.cosmeticTypeFrame;
    case CosmeticType.relic:
      return l10n.cosmeticTypeRelic;
    case CosmeticType.background:
      return l10n.cosmeticTypeBackground;
    case CosmeticType.emblem:
      return l10n.cosmeticTypeEmblem;
    case CosmeticType.companion:
      return l10n.cosmeticTypeCompanion;
    case CosmeticType.titleFlair:
      return l10n.cosmeticTypeTitleFlair;
    case CosmeticType.mapEffect:
      return l10n.cosmeticTypeMapEffect;
    case CosmeticType.skin:
      return l10n.cosmeticTypeSkin;
    case CosmeticType.banner:
      return l10n.cosmeticTypeBanner;
  }
}

Color cosmeticRarityColor(Rarity rarity) =>
    RarityPalette.forRarity(rarity).color;