// Hide Flutter's debug-mode `Banner` widget so the cosmetic `Banner`
// sealed subclass (from cosmetic_models.dart) wins the name lookup.
import 'package:flutter/material.dart' hide Banner;

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../social/presentation/widgets/profile_title_banner.dart';
import '../../config/cosmetics_config.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_screen_internals.dart';

/// Full-width banner card for the inventory's banner-only category.
/// Same compact card shape as the banner slot-sheet picker rows
/// ([_BannerPickerRow]) so the player sees one consistent banner-row
/// look across inventory + equip flow:
///   * banner chrome (full asset + live level/title overlay)
///   * banner name on the left, rarity label on the right
///   * small check-circle icon in the top-right corner when equipped
///   * dimmed lock overlay when the banner is still locked
class BannerInventoryTile extends StatelessWidget {
  const BannerInventoryTile({
    super.key,
    required this.definition,
    required this.isUnlocked,
    required this.isEquipped,
    required this.level,
    required this.title,
    required this.l10n,
    required this.onTap,
  });

  final Banner definition;
  final bool isUnlocked;
  final bool isEquipped;
  final AppLocalizations l10n;

  /// Player's current level — overlaid as the banner's level badge so
  /// every row previews the live chrome.
  final int level;

  /// Player's current title — overlaid as the banner's title plate.
  final String title;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = cosmeticRarityColor(definition.rarity);
    final assetPath =
        CosmeticsConfig.standard().resolveAssetPath(definition.assetKey);

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
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: assetPath == null
                        ? AspectRatio(
                            aspectRatio: 1024 / 256,
                            child: ColoredBox(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Center(
                                child: Icon(
                                  Icons.flag_rounded,
                                  color: Tokens.onSurfaceMuted,
                                ),
                              ),
                            ),
                          )
                        : BannerChrome(
                            assetPath: assetPath,
                            level: level,
                            title: title,
                            paletteRarity: definition.rarity,
                          ),
                  ),
                  if (!isUnlocked)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.lock_outline,
                            color: Colors.white.withValues(alpha: 0.55),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  if (isEquipped)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: rarityColor,
                        size: 17,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      definition.name(l10n),
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
                    definition.rarity.label(l10n).toUpperCase(),
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
