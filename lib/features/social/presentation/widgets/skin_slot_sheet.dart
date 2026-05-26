import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/skin_asset_resolver.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetics_screen_internals.dart';
import 'slot_sheet_shell.dart';

/// Bottom sheet for managing the equipped skin from the profile hero
/// header. Mirrors [CompanionSlotSheet]: shows the current skin's
/// rarity / description, lets the owner swap to any other owned skin
/// from an inline picker grid, or unequip the current one. Skin
/// previews resolve via [SkinAssetResolver] against the player's
/// selected race — without [raceId] the sheet still renders, but
/// tiles fall back to the type-icon placeholder.
///
/// Returns a [SkinSlotPick] describing the player's choice:
///   * `null` — sheet dismissed without changes
///   * `SkinSlotPick.remove()` — unequip the current skin
///   * `SkinSlotPick.equip(id)` — equip that skin instead
class SkinSlotSheet extends StatelessWidget {
  const SkinSlotSheet({
    super.key,
    required this.current,
    required this.unlocked,
    required this.raceId,
  });

  /// The currently equipped skin. `null` if the slot is empty (the
  /// sheet then collapses the manage block and shows the picker
  /// only).
  final Cosmetic? current;

  /// Every unlocked skin in the player's inventory, including the
  /// currently equipped one. The picker filters [current] out
  /// internally so the grid only offers alternatives.
  final List<Cosmetic> unlocked;

  /// Player's selected race id. Drives the per-race file resolution
  /// for both the current-skin preview and every picker tile.
  final String? raceId;

  static const _resolver = SkinAssetResolver();

  static Future<SkinSlotPick?> show(
    BuildContext context, {
    required Cosmetic? current,
    required List<Cosmetic> unlocked,
    required String? raceId,
  }) {
    return showModalBottomSheet<SkinSlotPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkinSlotSheet(
        current: current,
        unlocked: unlocked,
        raceId: raceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final others = [
      for (final s in unlocked)
        if (s.id != current?.id) s,
    ];

    return SlotSheetShell(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(hasCurrent: current != null),
            if (current != null) ...[
              const SizedBox(height: 20),
              _CurrentSkinBlock(
                skin: current!,
                raceId: raceId,
                onRemove: () => Navigator.of(context)
                    .pop(const SkinSlotPick.remove()),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              current == null ? 'VYBER VZHLED' : 'VYMĚNIT ZA',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _SkinPickerGrid(
              skins: others,
              raceId: raceId,
              onPick: (def) =>
                  Navigator.of(context).pop(SkinSlotPick.equip(def.id)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet result returned to the caller. Sealed-ish via private ctors
/// so the caller pattern-matches on [removed] vs [cosmeticId].
class SkinSlotPick {
  const SkinSlotPick.remove()
      : removed = true,
        cosmeticId = null;
  const SkinSlotPick.equip(String id)
      : removed = false,
        cosmeticId = id;

  final bool removed;
  final String? cosmeticId;
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.hasCurrent});

  final bool hasCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VZHLED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasCurrent ? 'Spravovat vzhled' : 'Vyber vzhled',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Tokens.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _CurrentSkinBlock extends StatelessWidget {
  const _CurrentSkinBlock({
    required this.skin,
    required this.raceId,
    required this.onRemove,
  });

  final Cosmetic skin;
  final String? raceId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rarityColor = cosmeticRarityColor(skin.rarity);
    final assetPath = SkinSlotSheet._resolver.resolve(
      raceId: raceId,
      skinAssetKey: skin.assetKey,
      // Full body in the manage block so the player previews the
      // same composition they see on the profile hero card.
      variant: SkinAssetVariant.fullBody,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: rarityColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkinPreview(
                assetPath: assetPath,
                color: rarityColor,
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skin.name(l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Tokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skin.rarity.label(l10n).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: rarityColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            skin.description(l10n),
            style: const TextStyle(
              fontSize: 13,
              color: Tokens.onSurfaceMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _RemoveButton(onTap: onRemove),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(Tokens.radiusButton),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Tokens.onSurfaceMuted,
              ),
              SizedBox(width: 8),
              Text(
                'Sundat vzhled',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Tokens.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinPickerGrid extends StatelessWidget {
  const _SkinPickerGrid({
    required this.skins,
    required this.raceId,
    required this.onPick,
  });

  final List<Cosmetic> skins;
  final String? raceId;
  final void Function(Cosmetic) onPick;

  @override
  Widget build(BuildContext context) {
    if (skins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Žádný další odemčený vzhled.',
          style: TextStyle(
            fontSize: 13,
            color: Tokens.onSurfaceFaint,
          ),
        ),
      );
    }

    // Same 3-column shape as the companion picker so the two
    // surfaces feel like one family.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: skins.length,
      itemBuilder: (_, index) => _PickerTile(
        skin: skins[index],
        raceId: raceId,
        onTap: () => onPick(skins[index]),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.skin,
    required this.raceId,
    required this.onTap,
  });

  final Cosmetic skin;
  final String? raceId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = cosmeticRarityColor(skin.rarity);
    final assetPath = SkinSlotSheet._resolver.resolve(
      raceId: raceId,
      skinAssetKey: skin.previewAssetKey ?? skin.assetKey,
      variant: SkinAssetVariant.thumbnail,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.13),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: color.withValues(alpha: 0.27)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CosmeticBadge(
                definition: skin,
                assetPath: assetPath,
                color: color,
                size: 48,
                framed: false,
              ),
              const SizedBox(height: Tokens.spaceSm),
              Text(
                skin.name(l10n),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: Tokens.fontSizeTiny,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinPreview extends StatelessWidget {
  const _SkinPreview({
    required this.assetPath,
    required this.color,
    required this.size,
  });

  final String? assetPath;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final child = assetPath == null
        ? Icon(
            Icons.person_rounded,
            size: size * 0.56,
            color: color.withValues(alpha: 0.85),
          )
        : Image.asset(
            assetPath!,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, __, ___) => Icon(
              Icons.person_rounded,
              size: size * 0.56,
              color: color.withValues(alpha: 0.85),
            ),
          );

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    );
  }
}
