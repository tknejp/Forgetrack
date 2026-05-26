import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetics_screen_internals.dart';
import '../../../cosmetics/presentation/widgets/companion_buff_chip.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import 'hero_progression_header.dart';
import 'slot_sheet_shell.dart';

/// Bottom sheet for managing the equipped companion from the profile
/// hero header. Replaces the read-only cosmetic-details flow with a
/// loadout-management surface: the player sees the current companion's
/// rarity / description / buff, can swap to any other owned companion
/// from an inline picker grid, or unequip the current one.
///
/// Returns a [CompanionSlotPick] describing the player's choice:
///   * `null` — sheet dismissed without changes
///   * `CompanionSlotPick.remove()` — unequip the current companion
///   * `CompanionSlotPick.equip(id)` — equip that companion instead
class CompanionSlotSheet extends StatelessWidget {
  const CompanionSlotSheet({
    super.key,
    required this.current,
    required this.unlocked,
  });

  /// The currently equipped companion. `null` if the slot is empty
  /// (the sheet then collapses the manage block and shows the picker
  /// only). The profile entry point only opens this sheet when a
  /// companion is equipped, but the empty-state path is supported so
  /// the sheet can be reused from other surfaces later.
  final Cosmetic? current;

  /// Every unlocked companion in the player's inventory, including
  /// the currently equipped one. The picker filters [current] out
  /// internally so the grid only offers alternatives.
  final List<Cosmetic> unlocked;

  static Future<CompanionSlotPick?> show(
    BuildContext context, {
    required Cosmetic? current,
    required List<Cosmetic> unlocked,
  }) {
    return showModalBottomSheet<CompanionSlotPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanionSlotSheet(
        current: current,
        unlocked: unlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final others = [
      for (final c in unlocked)
        if (c.id != current?.id) c,
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
              _CurrentCompanionBlock(
                companion: current!,
                onRemove: () => Navigator.of(context)
                    .pop(const CompanionSlotPick.remove()),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              current == null ? 'VYBER SPOLEČNÍKA' : 'VYMĚNIT ZA',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _CompanionPickerGrid(
              companions: others,
              onPick: (def) => Navigator.of(context)
                  .pop(CompanionSlotPick.equip(def.id)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet result returned to the caller. Sealed-ish via private ctors
/// so the caller pattern-matches on [removed] vs [cosmeticId].
class CompanionSlotPick {
  const CompanionSlotPick.remove()
      : removed = true,
        cosmeticId = null;
  const CompanionSlotPick.equip(String id)
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
          'SPOLEČNÍK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasCurrent ? 'Spravovat společníka' : 'Vyber společníka',
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

class _CurrentCompanionBlock extends StatelessWidget {
  const _CurrentCompanionBlock({
    required this.companion,
    required this.onRemove,
  });

  final Cosmetic companion;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rarityColor = cosmeticRarityColor(companion.rarity);
    final buff = companion is Companion ? (companion as Companion).buff : null;

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
              CompanionAsset(definition: companion, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      companion.name(l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Tokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companion.rarity.label(l10n).toUpperCase(),
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
            companion.description(l10n),
            style: const TextStyle(
              fontSize: 13,
              color: Tokens.onSurfaceMuted,
              height: 1.4,
            ),
          ),
          if (buff != null) ...[
            const SizedBox(height: 12),
            CompanionBuffBanner(
              buff: buff,
              // `read` (not `watch`): the chain position is a snapshot
              // for the sheet's lifetime. `watch` here caused the sheet
              // to rebuild on every progression notification, which
              // reset the modal-sheet drag gesture mid-swipe and broke
              // drag-to-dismiss.
              currentChapterChainPosition: buff is ChapterDepthCompanionBuff
                  ? context
                      .read<ProgressionEngineProvider>()
                      .currentChapterChainPosition
                  : null,
            ),
          ],
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
                'Sundat společníka',
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

class _CompanionPickerGrid extends StatelessWidget {
  const _CompanionPickerGrid({
    required this.companions,
    required this.onPick,
  });

  final List<Cosmetic> companions;
  final void Function(Cosmetic) onPick;

  @override
  Widget build(BuildContext context) {
    if (companions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Žádný další odemčený společník.',
          style: TextStyle(
            fontSize: 13,
            color: Tokens.onSurfaceFaint,
          ),
        ),
      );
    }

    // 3-column grid matching the inventory layout
    // (`cosmetics_screen.dart`: crossAxisCount 3, spacing 10,
    // childAspectRatio 0.88) so the picker tiles read as the same
    // surface the player already knows from the cosmetics screen.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: companions.length,
      itemBuilder: (_, index) => _PickerTile(
        companion: companions[index],
        onTap: () => onPick(companions[index]),
      ),
    );
  }
}

/// Inventory-shaped tile: rarity-tinted gradient background + glow,
/// centered [CosmeticBadge], rarity-colored name, and the companion's
/// XP-buff label in amber underneath. Mirrors `_CosmeticCard` in
/// `cosmetics_screen.dart` so the picker reads as the same surface
/// the player already knows from the cosmetics inventory.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.companion,
    required this.onTap,
  });

  final Cosmetic companion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = cosmeticRarityColor(companion.rarity);
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      companion.previewAssetKey ?? companion.assetKey,
    );
    final buff = companion is Companion ? (companion as Companion).buff : null;
    final buffLabel = buff == null ? null : formatCompanionBuff(l10n, buff);

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
                definition: companion,
                assetPath: assetPath,
                color: color,
                size: 48,
                framed: false,
              ),
              const SizedBox(height: Tokens.spaceSm),
              Text(
                companion.name(l10n),
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
              if (buffLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    buffLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Tokens.xp.withValues(alpha: 0.85),
                      fontSize: Tokens.fontSizeTiny - 1,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
