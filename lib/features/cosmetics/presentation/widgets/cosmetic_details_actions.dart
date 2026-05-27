import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_models.dart';
import 'details_sheet_buttons.dart';

/// Footer action buttons for the cosmetic details standard body.
/// Branches across devTools / locked / equippable cases — matches the
/// original inline tree exactly.
class CosmeticDetailsActions extends StatelessWidget {
  const CosmeticDetailsActions({
    super.key,
    required this.definition,
    required this.l10n,
    required this.color,
    required this.isHidden,
    required this.isLocked,
    required this.devTools,
    required this.isEquipped,
    required this.canEquipEmblem,
    required this.effectiveLocked,
    required this.anyBusy,
    required this.equipBusy,
    required this.devBusy,
    required this.onToggleEquipped,
    required this.onDevGrant,
    required this.onDevRevoke,
  });

  final Cosmetic definition;
  final AppLocalizations l10n;
  final Color color;
  final bool isHidden;
  final bool isLocked;
  final bool devTools;
  final bool isEquipped;
  /// Emblem-only: false when the board has no free unlocked slot and
  /// the emblem isn't already pinned anywhere, so the Vybavit CTA
  /// renders disabled with a helper line. True in every other
  /// emblem state (already pinned → unpin / free slot available →
  /// pin). Ignored for non-emblem cosmetics.
  final bool canEquipEmblem;
  final bool effectiveLocked;
  final bool anyBusy;
  final bool equipBusy;
  final bool devBusy;
  final VoidCallback onToggleEquipped;
  final VoidCallback onDevGrant;
  final VoidCallback onDevRevoke;

  @override
  Widget build(BuildContext context) {
    if (devTools) {
      if (isLocked) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    anyBusy ? null : () => Navigator.of(context).pop(),
                style: detailsSheetOutlineStyle(color),
                child: Text(l10n.dialogClose),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DevButton(
                label: l10n.devGrant,
                icon: Icons.lock_open_rounded,
                color: Colors.greenAccent,
                busy: devBusy,
                onTap: anyBusy ? null : onDevGrant,
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          ActionButton(
            label:
                isEquipped ? l10n.cosmeticUnequip : l10n.cosmeticEquip,
            icon: isEquipped
                ? Icons.remove_circle_outline_rounded
                : Icons.check_circle_rounded,
            color: color,
            busy: equipBusy,
            onTap: anyBusy ? null : onToggleEquipped,
          ),
          const SizedBox(height: 8),
          DevButton(
            label: l10n.devRevoke,
            icon: Icons.lock_rounded,
            color: Theme.of(context).colorScheme.error,
            busy: devBusy,
            onTap: anyBusy ? null : onDevRevoke,
          ),
        ],
      );
    }

    if (effectiveLocked || definition is RelicCosmetic) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: detailsSheetOutlineStyle(
              isHidden ? Tokens.onSurfaceMuted : color),
          child: Text(l10n.dialogClose),
        ),
      );
    }

    // Emblems route through the EmblemBoard (per-user 6-slot
    // showcase) rather than the global loadout. When the player
    // has no free unlocked slot and this emblem isn't already
    // pinned, the CTA is disabled and a helper line below explains
    // why so the player isn't left wondering why the tap does
    // nothing.
    if (definition is Emblem) {
      final emblemBlocked = !isEquipped && !canEquipEmblem;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionButton(
            label: isEquipped ? l10n.cosmeticUnequip : l10n.cosmeticEquip,
            icon: isEquipped
                ? Icons.remove_circle_outline_rounded
                : Icons.check_circle_rounded,
            color: color,
            busy: equipBusy,
            onTap: anyBusy || emblemBlocked ? null : onToggleEquipped,
          ),
          if (emblemBlocked) ...[
            const SizedBox(height: 10),
            Text(
              l10n.cosmeticEmblemNoFreeSlot,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Tokens.onSurfaceMuted,
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      );
    }

    return ActionButton(
      label: isEquipped ? l10n.cosmeticUnequip : l10n.cosmeticEquip,
      icon: isEquipped
          ? Icons.remove_circle_outline_rounded
          : Icons.check_circle_rounded,
      color: color,
      busy: equipBusy,
      onTap: anyBusy ? null : onToggleEquipped,
    );
  }
}
