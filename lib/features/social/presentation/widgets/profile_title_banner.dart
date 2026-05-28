// Hide Flutter's debug-mode `Banner` widget so our cosmetic `Banner`
// sealed subclass (from cosmetic_models.dart) wins the name lookup.
import 'package:flutter/material.dart' hide Banner;
import 'package:google_fonts/google_fonts.dart';

import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';

/// Status-row banner showing the player's level and class title,
/// painted on top of a rarity-specific 1024×256 banner asset.
///
/// The asset itself carries all chrome (frame, gem socket, decorative
/// silhouette); this widget overlays two pieces of normal Flutter
/// text — level badge on the left, title on the right — in slots
/// expressed as fractions of the asset's canvas, so the layout is
/// resolution-independent.
///
/// Asset selection:
///   * If [equippedBanner] is a [Banner] cosmetic, its asset key + own
///     rarity drive both the visible image and the text palette. This
///     handles cases where the player has multiple banners unlocked
///     in the same rarity tier (e.g. Forest + Ruins, both uncommon).
///   * Otherwise the widget falls back to the tier-default banner for
///     [rarity] (used for friend profiles where we only know the title
///     tier, and for own profiles where nothing is equipped yet).
///
/// Designed to sit between the hero header's identity row (display
/// name in the app bar + `@handle · Přátelé N` row just below it)
/// and the cinematic profile hero card.
class ProfileTitleBanner extends StatelessWidget {
  const ProfileTitleBanner({
    super.key,
    required this.level,
    required this.title,
    required this.rarity,
    this.equippedBanner,
  });

  final int level;
  final String title;

  /// Title-tier rarity. Used as the fallback when no banner is
  /// equipped, so friend profiles + the brand-new own profile both
  /// render the tier-default chrome.
  final Rarity rarity;

  /// The banner the player has actively equipped, if any. When
  /// present, its `assetKey` paints the chrome and its own `rarity`
  /// drives the text palette — independent of the title tier above.
  /// Catalog lookup happens caller-side via `socialCosmeticById`.
  final Cosmetic? equippedBanner;

  // Tier-default banner asset key. Each rarity maps to the first
  // banner unlocked in that tier — used when the player has nothing
  // equipped in `Loadout.bannerId`, or when rendering a friend's
  // profile that doesn't expose the equipped banner.
  static const Map<Rarity, String> _defaultAssetByRarity = {
    Rarity.common: 'assets/cosmetics/banners/pilgrim.png',
    Rarity.uncommon: 'assets/cosmetics/banners/forest.png',
    Rarity.rare: 'assets/cosmetics/banners/mine.png',
    Rarity.epic: 'assets/cosmetics/banners/frost.png',
    Rarity.legendary: 'assets/cosmetics/banners/mountain.png',
    Rarity.mythic: 'assets/cosmetics/banners/dragonrock.png',
  };

  @override
  Widget build(BuildContext context) {
    final equipped = equippedBanner;
    final isBanner = equipped is Banner;
    final paletteRarity = isBanner ? equipped.rarity : rarity;
    final assetPath = isBanner
        ? (CosmeticsConfig.standard().resolveAssetPath(equipped.assetKey) ??
            _defaultAssetByRarity[paletteRarity]!)
        : _defaultAssetByRarity[rarity]!;

    return BannerChrome(
      assetPath: assetPath,
      level: level,
      title: title,
      paletteRarity: paletteRarity,
    );
  }
}

/// Renders a banner asset at its native 4:1 aspect ratio with the
/// player's level + title overlaid in rarity-tinted Cinzel text.
///
/// The layout fractions, font sizes, and per-rarity text palette are
/// shared with [ProfileTitleBanner] and the inventory banner tile so
/// every surface that previews a banner looks visually identical to
/// what the player would see equipped on their profile.
///
/// Asset selection + tier fallback is the caller's responsibility —
/// this widget takes a fully-resolved [assetPath] and does not consult
/// the cosmetics config.
class BannerChrome extends StatelessWidget {
  const BannerChrome({
    super.key,
    required this.assetPath,
    required this.level,
    required this.title,
    required this.paletteRarity,
  });

  final String assetPath;
  final int level;
  final String title;
  final Rarity paletteRarity;

  // ── Asset coordinate system ──────────────────────────────────────────
  // Source canvas: 1024×256 (aspect 4:1).
  // Frame caps reach ~15 px into each edge → text/badge content lives
  // safely inside ~x∈[80, 760] of the source.
  static const double _aspect = 1024 / 256;

  // Level badge gem (~140 px wide, x=90..230 of the source).
  static const double _levelBoxLeftFrac = 90 / 1024;
  static const double _levelBoxRightFrac = 235 / 1024;

  // Title plate (x=240..750 of the source; past 750 the asset starts
  // to include decorative silhouette + corner gem, so the title is
  // held back to that line and may ellipsise / scale down on long
  // Czech titles).
  static const double _titleBoxLeftFrac = 240 / 1024;
  static const double _titleBoxRightFrac = 750 / 1024;

  // Vertical safe band (~45 px padding top/bottom on the source).
  static const double _textBoxTopFrac = 45 / 256;
  static const double _textBoxBottomFrac = 211 / 256;

  // Locked absolute font sizes — text stays the same visual size
  // regardless of how wide / tall the rendered banner ends up. The
  // banner asset can grow (less screen-side padding, different device
  // widths) without dragging the text along. Calibrated to read well
  // on a 360-px-wide screen with ~8-px screen gutter.
  static const double _levelFontSize = 18;
  static const double _titleFontSize = 16;

  @override
  Widget build(BuildContext context) {
    final palette = BannerPalette.forRarity(paletteRarity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w / _aspect;
        final textBandH = h * (_textBoxBottomFrac - _textBoxTopFrac);

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned(
                left: w * _levelBoxLeftFrac,
                top: h * _textBoxTopFrac,
                width: w * (_levelBoxRightFrac - _levelBoxLeftFrac),
                height: textBandH,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$level',
                      style: GoogleFonts.cinzel(
                        color: palette.levelColor,
                        fontSize: _levelFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                        letterSpacing: 0.4,
                        shadows: palette.levelShadows,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * _titleBoxLeftFrac,
                top: h * _textBoxTopFrac,
                width: w * (_titleBoxRightFrac - _titleBoxLeftFrac),
                height: textBandH,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cinzel(
                        color: palette.titleColor,
                        fontSize: _titleFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        height: 1.5,
                        shadows: palette.titleShadows,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Per-rarity text palette for banner chrome. Tuned to the specific
/// banner art per tier — the contrast targets and glow colours don't
/// generalise to other surfaces.
///
/// TODO: move per-banner chrome colours (level / title text, glow
/// shadows) onto [Banner.metadata] so individual banners can override
/// the tier default. Today every banner in the same rarity inherits
/// one palette, which forces art to fit the palette instead of the
/// other way around — e.g. a rare-tier banner with a bright snow
/// background can't drop the cream title colour for a darker readable
/// one without re-tuning every other rare banner.
class BannerPalette {
  const BannerPalette({
    required this.levelColor,
    required this.titleColor,
    required this.titleShadows,
    required this.levelShadows,
  });

  final Color levelColor;
  final Color titleColor;
  final List<Shadow> titleShadows;
  final List<Shadow> levelShadows;

  static const Shadow _baseDrop = Shadow(
    color: Color(0xCC000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  factory BannerPalette.forRarity(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return const BannerPalette(
          levelColor: Color(0xFFE5E7EB),
          titleColor: Color(0xFFE6E1D6),
          levelShadows: [_baseDrop],
          titleShadows: [_baseDrop],
        );
      case Rarity.uncommon:
        return const BannerPalette(
          levelColor: Color(0xFFD7F5C5),
          titleColor: Color(0xFFD9E8C5),
          levelShadows: [
            _baseDrop,
            Shadow(color: Color(0x5546D964), blurRadius: 6),
          ],
          titleShadows: [
            _baseDrop,
            Shadow(color: Color(0x3346D964), blurRadius: 8),
          ],
        );
      case Rarity.rare:
        return const BannerPalette(
          levelColor: Color(0xFFFFD08A),
          titleColor: Color(0xFFF1D8A8),
          levelShadows: [
            _baseDrop,
            Shadow(color: Color(0x66F0A040), blurRadius: 6),
          ],
          titleShadows: [
            _baseDrop,
            Shadow(color: Color(0x33F0A040), blurRadius: 8),
          ],
        );
      case Rarity.epic:
        return const BannerPalette(
          levelColor: Color(0xFFD9C3FF),
          titleColor: Color(0xFFBFDFFF),
          levelShadows: [
            _baseDrop,
            Shadow(color: Color(0x668AB4FF), blurRadius: 8),
          ],
          titleShadows: [
            _baseDrop,
            Shadow(color: Color(0x408AB4FF), blurRadius: 10),
          ],
        );
      case Rarity.legendary:
        return const BannerPalette(
          levelColor: Color(0xFFFFD36A),
          titleColor: Color(0xFFFFD98A),
          levelShadows: [
            _baseDrop,
            Shadow(color: Color(0x80FFB938), blurRadius: 8),
          ],
          titleShadows: [
            _baseDrop,
            Shadow(color: Color(0x4DFFB938), blurRadius: 10),
          ],
        );
      case Rarity.mythic:
        return const BannerPalette(
          levelColor: Color(0xFFFFB1A1),
          titleColor: Color(0xFFFFD59A),
          levelShadows: [
            _baseDrop,
            Shadow(color: Color(0x80E25A38), blurRadius: 8),
          ],
          titleShadows: [
            _baseDrop,
            Shadow(color: Color(0x40E25A38), blurRadius: 12),
          ],
        );
    }
  }
}
