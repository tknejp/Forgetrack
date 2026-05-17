import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';

/// Bottom sheet for inspecting / managing the emblem in a single
/// header slot.
///
/// Two modes, picked by the call site:
///
///   * **Owner** (`isOwner: true`) — shows the slot's current emblem
///     (if any) with rarity + description, then a grid of every
///     unlocked emblem the user could move into this slot. Tapping a
///     grid tile assigns it; tapping the active emblem clears the
///     slot.
///   * **Friend** (`isOwner: false`) — read-only detail of the
///     emblem currently pinned in that slot. No grid, no remove
///     button. Used when looking at someone else's profile.
///
/// Returns an [EmblemSlotPick] describing the action the user took:
///   * `null` — sheet dismissed without changes
///   * `EmblemSlotPick(slotIndex, null)` — clear the slot
///   * `EmblemSlotPick(slotIndex, id)` — assign that emblem to the slot
class EmblemSlotSheet extends StatelessWidget {
  const EmblemSlotSheet({
    super.key,
    required this.slotIndex,
    required this.currentEmblem,
    required this.unlockedEmblems,
    required this.isOwner,
  });

  final int slotIndex;
  final Cosmetic? currentEmblem;
  final List<Cosmetic> unlockedEmblems;
  final bool isOwner;

  static Future<EmblemSlotPick?> show(
    BuildContext context, {
    required int slotIndex,
    required Cosmetic? currentEmblem,
    required List<Cosmetic> unlockedEmblems,
    required bool isOwner,
  }) {
    return showModalBottomSheet<EmblemSlotPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmblemSlotSheet(
        slotIndex: slotIndex,
        currentEmblem: currentEmblem,
        unlockedEmblems: unlockedEmblems,
        isOwner: isOwner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Tokens.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Tokens.cardBorder),
          left: BorderSide(color: Tokens.cardBorder),
          right: BorderSide(color: Tokens.cardBorder),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Tokens.cardBorder,
                borderRadius:
                    BorderRadius.circular(Tokens.radiusProgress),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    slotIndex: slotIndex,
                    isOwner: isOwner,
                    currentEmblem: currentEmblem,
                  ),
                  if (currentEmblem != null) ...[
                    const SizedBox(height: 20),
                    _CurrentEmblemBlock(
                      emblem: currentEmblem!,
                      isOwner: isOwner,
                      onRemove: () => Navigator.of(context)
                          .pop(EmblemSlotPick(slotIndex, null)),
                    ),
                  ],
                  if (isOwner) ...[
                    const SizedBox(height: 24),
                    Text(
                      currentEmblem == null
                          ? 'VYBER ZNAK'
                          : 'VYMĚNIT ZA',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Tokens.onSurfaceMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _UnlockedEmblemGrid(
                      emblems: unlockedEmblems,
                      currentEmblemId: currentEmblem?.id,
                      onPick: (def) => Navigator.of(context)
                          .pop(EmblemSlotPick(slotIndex, def.id)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet result returned to the caller.
class EmblemSlotPick {
  const EmblemSlotPick(this.slotIndex, this.cosmeticId);

  final int slotIndex;

  /// `null` means "clear this slot". Non-null means "pin this emblem
  /// in the slot (and clear whichever slot used to hold it, if any)".
  final String? cosmeticId;
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.slotIndex,
    required this.isOwner,
    required this.currentEmblem,
  });

  final int slotIndex;
  final bool isOwner;
  final Cosmetic? currentEmblem;

  @override
  Widget build(BuildContext context) {
    final String title;
    if (!isOwner) {
      title = currentEmblem == null ? 'Prázdný slot' : 'Detail znaku';
    } else if (currentEmblem != null) {
      title = 'Spravovat znak';
    } else {
      title = 'Vyber znak do slotu';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SLOT ${slotIndex + 1}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
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

class _CurrentEmblemBlock extends StatelessWidget {
  const _CurrentEmblemBlock({
    required this.emblem,
    required this.isOwner,
    required this.onRemove,
  });

  final Cosmetic emblem;
  final bool isOwner;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      emblem.previewAssetKey ?? emblem.assetKey,
    );
    final rarityColor = RarityPalette.forRarity(emblem.rarity).color;

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
              _EmblemThumb(
                assetPath: assetPath,
                rarityColor: rarityColor,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emblem.name(l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Tokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emblem.rarity.label(l10n).toUpperCase(),
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
            emblem.description(l10n),
            style: const TextStyle(
              fontSize: 13,
              color: Tokens.onSurfaceMuted,
              height: 1.4,
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 14),
            _RemoveButton(onTap: onRemove),
          ],
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
                'Odebrat ze slotu',
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

class _UnlockedEmblemGrid extends StatelessWidget {
  const _UnlockedEmblemGrid({
    required this.emblems,
    required this.currentEmblemId,
    required this.onPick,
  });

  final List<Cosmetic> emblems;
  final String? currentEmblemId;
  final void Function(Cosmetic) onPick;

  @override
  Widget build(BuildContext context) {
    if (emblems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Zatím nemáš odemčený žádný znak.',
          style: TextStyle(
            fontSize: 13,
            color: Tokens.onSurfaceFaint,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final def in emblems)
          _PickerTile(
            emblem: def,
            isCurrent: def.id == currentEmblemId,
            onTap: () => onPick(def),
          ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.emblem,
    required this.isCurrent,
    required this.onTap,
  });

  final Cosmetic emblem;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = CosmeticsConfig.standard().resolveAssetPath(
      emblem.previewAssetKey ?? emblem.assetKey,
    );
    final rarityColor = RarityPalette.forRarity(emblem.rarity).color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrent ? null : onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isCurrent
                ? rarityColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(Tokens.radiusButton),
            border: Border.all(
              color: isCurrent
                  ? rarityColor.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.08),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: _EmblemThumb(
            assetPath: assetPath,
            rarityColor: rarityColor,
            size: 60,
          ),
        ),
      ),
    );
  }
}

class _EmblemThumb extends StatelessWidget {
  const _EmblemThumb({
    required this.assetPath,
    required this.rarityColor,
    required this.size,
  });

  final String? assetPath;
  final Color rarityColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    rarityColor.withValues(alpha: 0.22),
                    rarityColor.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: size,
          height: size,
          child: assetPath == null
              ? const Icon(
                  Icons.shield_moon_rounded,
                  color: Colors.white70,
                )
              : Image.asset(assetPath!, fit: BoxFit.contain),
        ),
      ],
    );
  }
}

