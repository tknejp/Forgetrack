import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetics_screen_internals.dart';
import 'profile_hero_layout.dart';
import 'slot_sheet_shell.dart';

/// Bottom sheet for managing the equipped hero-scene background from
/// the profile screen. Mirrors [BannerSlotSheet] / [SkinSlotSheet] /
/// [CompanionSlotSheet]: shows the currently equipped background's
/// preview + rarity / unlock hint, lets the owner swap to any other
/// unlocked background, or unequip the current one (which falls back
/// to the default `background_camp` scene via
/// `socialBackgroundDefinition`).
///
/// Backgrounds are 9:16 portrait so the picker uses a 2-column grid
/// of portrait previews — wide enough for the player to recognise
/// the painted scene at a glance, compact enough to scan several at
/// once without an unreasonable scroll.
class BackgroundSlotSheet extends StatelessWidget {
  const BackgroundSlotSheet({
    super.key,
    required this.current,
    required this.unlocked,
  });

  /// The currently equipped background. `null` if the slot is empty
  /// (sheet collapses the manage block and shows the picker only).
  final Cosmetic? current;

  /// Every unlocked background in the player's inventory, including
  /// the currently equipped one. The picker filters [current] out
  /// internally so the list only offers alternatives.
  final List<Cosmetic> unlocked;

  static Future<BackgroundSlotPick?> show(
    BuildContext context, {
    required Cosmetic? current,
    required List<Cosmetic> unlocked,
  }) {
    return showModalBottomSheet<BackgroundSlotPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BackgroundSlotSheet(current: current, unlocked: unlocked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final others = [
      for (final b in unlocked)
        if (b.id != current?.id) b,
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
              _CurrentBackgroundBlock(
                background: current!,
                onRemove: () => Navigator.of(context)
                    .pop(const BackgroundSlotPick.remove()),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              current == null ? 'VYBER POZADÍ' : 'VYMĚNIT ZA',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _BackgroundPickerGrid(
              backgrounds: others,
              onPick: (def) => Navigator.of(context)
                  .pop(BackgroundSlotPick.equip(def.id)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet result returned to the caller. Same shape as
/// [BannerSlotPick] / [SkinSlotPick] / [CompanionSlotPick] so the
/// screen-side handler pattern stays identical across slot sheets.
class BackgroundSlotPick {
  const BackgroundSlotPick.remove()
      : removed = true,
        cosmeticId = null;
  const BackgroundSlotPick.equip(String id)
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
          'POZADÍ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasCurrent ? 'Spravovat pozadí' : 'Vyber pozadí',
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

class _CurrentBackgroundBlock extends StatelessWidget {
  const _CurrentBackgroundBlock({
    required this.background,
    required this.onRemove,
  });

  final Cosmetic background;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rarityColor = cosmeticRarityColor(background.rarity);

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
          // Constrain the current-block preview to a sensible height —
          // a full-width 9:16 portrait on a ~360-px screen would push
          // ~570 px tall and dwarf everything else in the sheet.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: _BackgroundPreview(background: background),
          ),
          const SizedBox(height: 12),
          Text(
            background.name(l10n),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Tokens.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            background.rarity.label(l10n).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: rarityColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            background.description(l10n),
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

class _BackgroundPickerGrid extends StatelessWidget {
  const _BackgroundPickerGrid({
    required this.backgrounds,
    required this.onPick,
  });

  final List<Cosmetic> backgrounds;
  final void Function(Cosmetic def) onPick;

  @override
  Widget build(BuildContext context) {
    if (backgrounds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Žádné další pozadí k vybrání. Odemkneš je postupem na vyšších úrovních.',
          style: TextStyle(
            fontSize: 13,
            color: Tokens.onSurfaceFaint,
            height: 1.4,
          ),
        ),
      );
    }
    // 2-column grid of 9:16 portrait previews. `shrinkWrap` +
    // `NeverScrollableScrollPhysics` so the grid lives inside the
    // sheet's outer scroll view instead of nesting its own scroll.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // 9:16 preview + ~46-px label band below. childAspectRatio
        // = width / height, so for a 9:16 image the bare image tile
        // would be 9/16 ≈ 0.56; adding the label band drops the
        // effective ratio to ~0.52.
        childAspectRatio: 0.52,
      ),
      itemCount: backgrounds.length,
      itemBuilder: (_, index) => _BackgroundPickerTile(
        background: backgrounds[index],
        onTap: () => onPick(backgrounds[index]),
      ),
    );
  }
}

class _BackgroundPickerTile extends StatelessWidget {
  const _BackgroundPickerTile({required this.background, required this.onTap});

  final Cosmetic background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rarityColor = cosmeticRarityColor(background.rarity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            border: Border.all(color: rarityColor.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _BackgroundPreview(background: background)),
              const SizedBox(height: 6),
              Text(
                background.name(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Tokens.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                background.rarity.label(l10n).toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: rarityColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the background asset as a 9:16 portrait preview. Falls back
/// to a landscape-icon placeholder when the asset can't be resolved
/// (catalog row without a shipped png).
class _BackgroundPreview extends StatelessWidget {
  const _BackgroundPreview({required this.background});

  final Cosmetic background;

  @override
  Widget build(BuildContext context) {
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      background.previewAssetKey ?? background.assetKey,
    );
    return AspectRatio(
      aspectRatio: 1 / ProfileHeroLayout.backgroundAspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: assetPath == null
            ? ColoredBox(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: Icon(
                    Icons.landscape_rounded,
                    color: Tokens.onSurfaceMuted,
                  ),
                ),
              )
            : Image.asset(
                assetPath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
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
                'Sundat pozadí',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
