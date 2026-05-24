import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/cosmetics_provider.dart';
import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_screen.dart';

/// "Inventář" section — a row of three featured cosmetic tiles (frame,
/// companion, background) that reads the signed-in user's
/// [CosmeticsProvider] state and routes taps to the full
/// [CosmeticsScreen] filtered by type.
///
/// Shared between the Hero tab and the profile screen so both surfaces
/// expose the same inventory overview + entry point.
class CosmeticsInventorySection extends StatelessWidget {
  const CosmeticsInventorySection({super.key});

  static const _featuredTypes = <CosmeticType>[
    CosmeticType.frame,
    CosmeticType.companion,
    CosmeticType.background,
  ];

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final state = cosmetics.state;
    final l10n = AppLocalizations.of(context);
    final config = CosmeticsConfig.standard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InventorySectionHead(
          onShowAll: state == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CosmeticsScreen(),
                    ),
                  ),
        ),
        const SizedBox(height: 10),
        if (state == null)
          _InventoryHint(
            text: cosmetics.isLoading
                ? 'Načítám inventář…'
                : 'Inventář bude dostupný po přihlášení.',
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _featuredTypes.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _FeaturedCosmeticTile(
                    type: _featuredTypes[i],
                    item: _featuredForType(
                      cosmetics,
                      state,
                      _featuredTypes[i],
                    ),
                    l10n: l10n,
                    config: config,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CosmeticsScreen(
                          initialType: _featuredTypes[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  _FeaturedCosmetic? _featuredForType(
    CosmeticsProvider cosmetics,
    UserCosmeticsState state,
    CosmeticType type,
  ) {
    final catalog = cosmetics.service.catalog;
    final equippedId = state.equipped.slotId(type);
    if (equippedId != null && state.unlocked.containsKey(equippedId)) {
      final equipped = catalog.byId(equippedId);
      if (equipped != null && equipped.isEnabled) {
        return _FeaturedCosmetic(definition: equipped, isEquipped: true);
      }
    }

    final unlocked = catalog
        .byType(type)
        .where((def) => def.isEnabled && state.unlocked.containsKey(def.id)) // lint-ignore: widget-no-logic — inventory display-slice over pre-built catalog
        .toList()
      ..sort((a, b) {
        final aAt = state.unlocked[a.id]!.unlockedAt;
        final bAt = state.unlocked[b.id]!.unlockedAt;
        return bAt.compareTo(aAt);
      });
    if (unlocked.isEmpty) return null;
    return _FeaturedCosmetic(definition: unlocked.first, isEquipped: false);
  }
}

class _InventorySectionHead extends StatelessWidget {
  const _InventorySectionHead({required this.onShowAll});

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome,
            size: 14, color: Tokens.accent.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'INVENTÁŘ',
            style: TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w900,
              color: Tokens.accent,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (onShowAll != null)
          InkWell(
            onTap: onShowAll,
            borderRadius: BorderRadius.circular(Tokens.radiusIcon),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Zobrazit vše',
                    style: TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onSurfaceMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 14, color: Tokens.onSurfaceMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InventoryHint extends StatelessWidget {
  const _InventoryHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: Tokens.fontSizeSmall,
          fontWeight: FontWeight.w600,
          color: Tokens.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _FeaturedCosmetic {
  const _FeaturedCosmetic({
    required this.definition,
    required this.isEquipped,
  });

  final Cosmetic definition;
  final bool isEquipped;
}

class _FeaturedCosmeticTile extends StatelessWidget {
  const _FeaturedCosmeticTile({
    required this.type,
    required this.item,
    required this.l10n,
    required this.config,
    required this.onTap,
  });

  final CosmeticType type;
  final _FeaturedCosmetic? item;
  final AppLocalizations l10n;
  final CosmeticsConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final definition = item?.definition;
    final assetPath = config.resolveAssetPath(
      definition?.previewAssetKey ?? definition?.assetKey,
    );
    final hasItem = definition != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusButton),
      child: Container(
        height: 128,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: hasItem ? 0.045 : 0.025),
          borderRadius: BorderRadius.circular(Tokens.radiusButton),
          border: Border.all(
            color: Colors.white.withValues(alpha: hasItem ? 0.08 : 0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: assetPath != null
                    ? _FeaturedAssetImage(
                        assetPath: assetPath,
                        type: type,
                        definition: definition,
                        hasItem: hasItem,
                      )
                    : _PreviewFallback(type: type, dim: !hasItem),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _labelForType(type).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              definition == null ? 'Žádné' : definition.name(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w900,
                color: hasItem ? Tokens.onSurface : Tokens.onSurfaceFaint,
              ),
            ),
            if (item != null) ...[
              const SizedBox(height: 2),
              Text(
                item!.isEquipped ? 'VYBAVENO' : 'POSLEDNÍ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w900,
                  color:
                      item!.isEquipped ? Tokens.accent : Tokens.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _labelForType(CosmeticType type) {
    switch (type) {
      case CosmeticType.frame:
        return 'Rámečky';
      case CosmeticType.relic:
        return 'Relikvie';
      case CosmeticType.background:
        return 'Pozadí';
      case CosmeticType.emblem:
        return 'Znaky';
      case CosmeticType.companion:
        return 'Společníci';
      case CosmeticType.titleFlair:
        return 'Tituly';
      case CosmeticType.mapEffect:
        return 'Efekty mapy';
      case CosmeticType.skin:
        return 'Vzhledy';
    }
  }
}

/// Featured-tile asset image with type-aware vertical anchoring. Companion
/// source assets carry ~48 px of empty pad below the feet inside their
/// 512² canvas, so the raw `BoxFit.contain` render sits visibly low in
/// the tile — the silhouette body ends up below the visual centre while
/// the foot pad acts as dead space at the bottom. Reserve bottom padding
/// for companions so the contained image is forced upward, the foot pad
/// disappears into the tile floor, and the silhouette reads as
/// vertically balanced against the type label below.
class _FeaturedAssetImage extends StatelessWidget {
  const _FeaturedAssetImage({
    required this.assetPath,
    required this.type,
    required this.definition,
    required this.hasItem,
  });

  final String assetPath;
  final CosmeticType type;
  final Cosmetic? definition;
  final bool hasItem;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          _PreviewFallback(type: type, dim: !hasItem),
    );
    return image;
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({
    required this.type,
    required this.dim,
  });

  final CosmeticType type;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        _iconForType(type),
        size: 28,
        color:
            dim ? Tokens.onSurfaceFaint : Colors.white.withValues(alpha: 0.88),
      ),
    );
  }

  static IconData _iconForType(CosmeticType type) {
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
    }
  }
}
