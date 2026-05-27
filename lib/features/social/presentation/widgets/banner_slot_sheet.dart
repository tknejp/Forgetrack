// Hide Flutter's debug-mode `Banner` widget so the cosmetic `Banner`
// sealed subclass (from cosmetic_models.dart) wins the name lookup.
import 'package:flutter/material.dart' hide Banner;
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetics_screen_internals.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import 'profile_title_banner.dart';
import 'slot_sheet_shell.dart';

/// Bottom sheet for managing the equipped title banner from the
/// profile screen. Mirrors [SkinSlotSheet] / [CompanionSlotSheet]:
/// shows the currently equipped banner's preview + rarity / unlock
/// hint, lets the owner swap to any other unlocked banner from an
/// inline list, or unequip the current one.
///
/// Banners are 4:1 landscape so the picker is a vertical list of
/// full-width previews, not the square grid the other slot sheets
/// use.
///
/// Returns a [BannerSlotPick] describing the player's choice:
///   * `null` — sheet dismissed without changes
///   * `BannerSlotPick.remove()` — unequip the current banner
///   * `BannerSlotPick.equip(id)` — equip that banner instead
class BannerSlotSheet extends StatelessWidget {
  const BannerSlotSheet({
    super.key,
    required this.current,
    required this.unlocked,
  });

  /// The currently equipped banner. `null` if the slot is empty (the
  /// sheet then collapses the manage block and shows the picker only).
  final Cosmetic? current;

  /// Every unlocked banner in the player's inventory, including the
  /// currently equipped one. The picker filters [current] out
  /// internally so the list only offers alternatives.
  final List<Cosmetic> unlocked;

  static Future<BannerSlotPick?> show(
    BuildContext context, {
    required Cosmetic? current,
    required List<Cosmetic> unlocked,
  }) {
    return showModalBottomSheet<BannerSlotPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BannerSlotSheet(current: current, unlocked: unlocked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final others = [
      for (final b in unlocked)
        if (b.id != current?.id) b,
    ];

    // Resolve player's live level + title so picker rows preview each
    // banner with the chrome the player would actually see on the
    // profile after equipping. The sheet is opened from inside the
    // app's provider tree, so the read is safe.
    final progression = context.watch<ProgressionEngineProvider>();
    final level = progression.level;
    final l10n = context.l10n;
    final display = const ProgressionDisplayResolver().levelDisplay(level);
    final title = display.title(l10n);

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
              _CurrentBannerBlock(
                banner: current!,
                level: level,
                title: title,
                onRemove: () => Navigator.of(context)
                    .pop(const BannerSlotPick.remove()),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              current == null ? 'VYBER BANNER' : 'VYMĚNIT ZA',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _BannerPickerList(
              banners: others,
              level: level,
              title: title,
              onPick: (def) => Navigator.of(context)
                  .pop(BannerSlotPick.equip(def.id)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet result returned to the caller. Same shape as
/// [SkinSlotPick] / [CompanionSlotPick] so the screen-side handler
/// pattern stays identical across slot sheets.
class BannerSlotPick {
  const BannerSlotPick.remove()
      : removed = true,
        cosmeticId = null;
  const BannerSlotPick.equip(String id)
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
          'BANNER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasCurrent ? 'Spravovat banner' : 'Vyber banner',
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

class _CurrentBannerBlock extends StatelessWidget {
  const _CurrentBannerBlock({
    required this.banner,
    required this.level,
    required this.title,
    required this.onRemove,
  });

  final Cosmetic banner;
  final int level;
  final String title;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rarityColor = cosmeticRarityColor(banner.rarity);

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
          _CurrentBannerPreview(banner: banner, level: level, title: title),
          const SizedBox(height: 12),
          Text(
            banner.name(l10n),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Tokens.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            banner.rarity.label(l10n).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: rarityColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            banner.description(l10n),
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

class _BannerPickerList extends StatelessWidget {
  const _BannerPickerList({
    required this.banners,
    required this.level,
    required this.title,
    required this.onPick,
  });

  final List<Cosmetic> banners;
  final int level;
  final String title;
  final void Function(Cosmetic def) onPick;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Žádné další bannery k vybrání. Odemkneš je postupem na vyšších úrovních.',
          style: TextStyle(
            fontSize: 13,
            color: Tokens.onSurfaceFaint,
            height: 1.4,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final def in banners) ...[
          _BannerPickerRow(
            banner: def,
            level: level,
            title: title,
            onTap: () => onPick(def),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BannerPickerRow extends StatelessWidget {
  const _BannerPickerRow({
    required this.banner,
    required this.level,
    required this.title,
    required this.onTap,
  });

  final Cosmetic banner;
  final int level;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rarityColor = cosmeticRarityColor(banner.rarity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            border: Border.all(color: rarityColor.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BannerPickerPreview(
                banner: banner,
                level: level,
                title: title,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      banner.name(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Tokens.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    banner.rarity.label(l10n).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: rarityColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picker-row preview — full banner asset with the player's live level
/// + title overlaid via [BannerChrome], so each row shows how that
/// banner would read after equipping. Falls back to a flag-icon
/// placeholder when the asset can't be resolved (catalog row without a
/// shipped png).
class _BannerPickerPreview extends StatelessWidget {
  const _BannerPickerPreview({
    required this.banner,
    required this.level,
    required this.title,
  });

  final Cosmetic banner;
  final int level;
  final String title;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        CosmeticsConfig.standard().resolveAssetPath(banner.assetKey);
    if (assetPath == null) {
      return AspectRatio(
        aspectRatio: 1024 / 256,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.05),
            child: const Center(
              child: Icon(
                Icons.flag_rounded,
                color: Tokens.onSurfaceMuted,
              ),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BannerChrome(
        assetPath: assetPath,
        level: level,
        title: title,
        paletteRarity: banner.rarity,
      ),
    );
  }
}

/// "Current banner" block preview — same live-chrome render as the
/// picker rows so the management block previews exactly what the
/// player will see on their profile after equipping (and what was
/// painted by [ProfileTitleBanner] above this sheet).
class _CurrentBannerPreview extends StatelessWidget {
  const _CurrentBannerPreview({
    required this.banner,
    required this.level,
    required this.title,
  });

  final Cosmetic banner;
  final int level;
  final String title;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        CosmeticsConfig.standard().resolveAssetPath(banner.assetKey);
    if (assetPath == null) {
      return AspectRatio(
        aspectRatio: 1024 / 256,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.05),
            child: const Center(
              child: Icon(
                Icons.flag_rounded,
                color: Tokens.onSurfaceMuted,
              ),
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BannerChrome(
        assetPath: assetPath,
        level: level,
        title: title,
        paletteRarity: banner.rarity,
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
                'Sundat banner',
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
