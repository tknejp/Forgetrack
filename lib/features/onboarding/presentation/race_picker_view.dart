import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../cosmetics/config/skin_asset_resolver.dart';
import '../../cosmetics/domain/hero_race.dart';
import '../../cosmetics/domain/hero_race_catalog.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';

/// Reusable race-pick UI body — sparkle-haloed preview + title +
/// subtitle + 3-col grid of race tiles + selected-race tag.
///
/// Used by:
///   * `StepWelcome` inside the onboarding `PageView` (no Scaffold).
///   * `ForcePickRaceScreen` as the body of a standalone full-screen
///     surface for existing players who don't yet have a race set
///     (game state predates the race system).
///
/// Owns its own sparkle [AnimationController] so callers don't have to
/// thread one in. State is otherwise external: parent holds
/// [draftRaceId] and listens to [onPickRace].
class RacePickerView extends StatefulWidget {
  const RacePickerView({
    super.key,
    required this.draftRaceId,
    required this.onPickRace,
    required this.title,
    required this.subtitle,
    required this.subtitleAccent,
    required this.levelLabel,
  });

  /// Currently-drafted race id. Parent updates this via [onPickRace]
  /// callbacks.
  final String draftRaceId;

  /// Fired with the tapped race id on every tile interaction. Parent
  /// is responsible for persisting / committing the choice.
  final ValueChanged<String> onPickRace;

  /// Main heading rendered between the preview and the grid.
  final String title;

  /// Body subtitle. The accent phrase is highlighted inline.
  final String subtitle;

  /// Substring inside [subtitle] that gets the accent (purple) styling.
  /// Empty / absent → the whole subtitle renders plain.
  final String subtitleAccent;

  /// Bottom-right pill on the hero preview — typically "LVL 1".
  final String levelLabel;

  @override
  State<RacePickerView> createState() => _RacePickerViewState();
}

class _RacePickerViewState extends State<RacePickerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;

  static const _resolver = SkinAssetResolver();
  static const _pilgrimAssetKey = 'cosmetics.skins.pilgrim';

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedRace = HeroRaceCatalog.byId(widget.draftRaceId) ??
        HeroRaceCatalog.definitions.first;
    // Preview uses the thumbnail variant — square format with the
    // asset's own background, framed by the sparkle halo.
    final previewPath = _resolver.resolve(
      raceId: selectedRace.id,
      skinAssetKey: _pilgrimAssetKey,
      variant: SkinAssetVariant.thumbnail,
    );
    return Column(
      children: [
        _RaceHeroPreview(
          sparkleController: _sparkleController,
          assetPath: previewPath,
          raceName: selectedRace.name(l10n),
          levelLabel: widget.levelLabel,
        ),
        const SizedBox(height: 14),
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: OnboardingTheme.stepHeading,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _Step1Subtitle(
            full: widget.subtitle,
            accent: widget.subtitleAccent,
          ),
        ),
        const SizedBox(height: 16),
        _RaceGrid(
          selectedRaceId: selectedRace.id,
          onPick: widget.onPickRace,
        ),
        const SizedBox(height: 16),
        _RaceTag(race: selectedRace, l10n: l10n),
      ],
    );
  }
}

class _Step1Subtitle extends StatelessWidget {
  const _Step1Subtitle({required this.full, required this.accent});

  final String full;
  final String accent;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 14,
      height: 1.45,
      color: OnboardingTheme.textSecondary,
    );
    final accentStyle = const TextStyle(
      color: OnboardingTheme.purpleAccent,
      fontWeight: FontWeight.w600,
    );
    if (accent.isEmpty) {
      return Text(full, textAlign: TextAlign.center, style: baseStyle);
    }
    final idx = full.indexOf(accent);
    if (idx < 0) {
      return Text(full, textAlign: TextAlign.center, style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        children: [
          if (idx > 0) TextSpan(text: full.substring(0, idx)),
          TextSpan(text: accent, style: accentStyle),
          if (idx + accent.length < full.length)
            TextSpan(text: full.substring(idx + accent.length)),
        ],
      ),
      textAlign: TextAlign.center,
      style: baseStyle,
    );
  }
}

/// 168×168 hero preview — race body inside a coloured glow halo, four
/// staggered sparkles, "LVL 1" pill bottom-right.
class _RaceHeroPreview extends StatelessWidget {
  const _RaceHeroPreview({
    required this.sparkleController,
    required this.assetPath,
    required this.raceName,
    required this.levelLabel,
  });

  final AnimationController sparkleController;
  final String? assetPath;
  final String raceName;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    const size = 168.0;
    const accent = OnboardingTheme.purpleAccent;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.33),
                  Colors.transparent,
                ],
                radius: 0.55,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(anim),
                child: child,
              ),
            ),
            // Hard accent ring + soft outer glow — mirrors the
            // selected-tile chrome below so the preview reads as
            // "the picked tile, blown up" instead of a separate
            // visual treatment.
            child: Container(
              key: ValueKey(assetPath ?? raceName),
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(132 * 0.32),
                boxShadow: [
                  const BoxShadow(
                    color: accent,
                    spreadRadius: 3,
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // Inset 2 px so the ring reads as a frame around the
              // figure, matching the `_RaceTile` selected inset.
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular((132 - 4) * 0.32),
                  child: _SkinFigure(
                    assetPath: assetPath,
                    fallbackLabel: raceName,
                    size: 132 - 4,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.04,
            top: size * 0.18,
            child: AnimatedSparkle(
              animation: sparkleController,
              phaseOffset: 0.0,
              size: 14,
            ),
          ),
          Positioned(
            right: size * 0.06,
            top: size * 0.10,
            child: AnimatedSparkle(
              animation: sparkleController,
              phaseOffset: 0.25,
              size: 18,
            ),
          ),
          Positioned(
            right: size * 0.04,
            bottom: size * 0.16,
            child: AnimatedSparkle(
              animation: sparkleController,
              phaseOffset: 0.50,
              size: 12,
            ),
          ),
          Positioned(
            left: size * 0.08,
            bottom: size * 0.10,
            child: AnimatedSparkle(
              animation: sparkleController,
              phaseOffset: 0.75,
              size: 16,
            ),
          ),
          Positioned(
            right: size * 0.18 - 8,
            bottom: size * 0.18 - 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1B1B3C), Color(0xFF0F1226)],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: OnboardingTheme.gold.withValues(alpha: 0.45),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.6),
                    blurRadius: 14,
                    spreadRadius: -4,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                levelLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: OnboardingTheme.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a resolved skin asset; falls back to a silhouette
/// placeholder for any null / unloadable state.
class _SkinFigure extends StatelessWidget {
  const _SkinFigure({
    required this.assetPath,
    required this.fallbackLabel,
    required this.size,
  });

  final String? assetPath;
  final String fallbackLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return _SkinSilhouette(label: fallbackLabel, size: size);
    }
    return Image.asset(
      assetPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 512×512 pixel-art source downscales crisply with no AA blur.
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) =>
          _SkinSilhouette(label: fallbackLabel, size: size),
    );
  }
}

class _SkinSilhouette extends StatelessWidget {
  const _SkinSilhouette({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color.fromRGBO(28, 30, 56, 0.55),
        border: Border.all(
          color: OnboardingTheme.purpleAccent.withValues(alpha: 0.45),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: size * 0.4,
            color: OnboardingTheme.purpleAccent.withValues(alpha: 0.85),
          ),
          if (size >= 64) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Color.fromRGBO(167, 139, 250, 0.85),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fixed 3×3 grid of all nine [HeroRace] tiles — one row per three
/// races, no wrap reflow. Tile size is capped so the picker reads as
/// a compact portrait gallery rather than a row of giant cards.
class _RaceGrid extends StatelessWidget {
  const _RaceGrid({
    required this.selectedRaceId,
    required this.onPick,
  });

  final String selectedRaceId;
  final ValueChanged<String> onPick;

  static const _resolver = SkinAssetResolver();
  static const _pilgrimAssetKey = 'cosmetics.skins.pilgrim';
  static const _cols = 3;
  static const _gap = 12.0;
  static const _maxTileSize = 72.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final races = HeroRaceCatalog.definitions;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fittedSize =
            ((constraints.maxWidth - _gap * (_cols - 1)) / _cols)
                .floorToDouble();
        final tileSize =
            fittedSize > _maxTileSize ? _maxTileSize : fittedSize;
        // Chunk the 9-race list into 3 rows of 3 so the grid is always
        // exactly 3×3 regardless of available width (a Wrap would
        // collapse to 4+4+1 / 5+4 on wider tablets).
        final rows = <List<HeroRace>>[];
        for (var i = 0; i < races.length; i += _cols) {
          rows.add(
            races.sublist(i, (i + _cols).clamp(0, races.length)),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var ri = 0; ri < rows.length; ri++) ...[
              if (ri > 0) const SizedBox(height: _gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var ci = 0; ci < rows[ri].length; ci++) ...[
                    if (ci > 0) const SizedBox(width: _gap),
                    _RaceTile(
                      size: tileSize,
                      race: rows[ri][ci],
                      selected: rows[ri][ci].id == selectedRaceId,
                      assetPath: _resolver.resolve(
                        raceId: rows[ri][ci].id,
                        skinAssetKey: _pilgrimAssetKey,
                        variant: SkinAssetVariant.thumbnail,
                      ),
                      fallbackLabel: rows[ri][ci].name(l10n),
                      onTap: () => onPick(rows[ri][ci].id),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RaceTile extends StatelessWidget {
  const _RaceTile({
    required this.size,
    required this.race,
    required this.selected,
    required this.assetPath,
    required this.fallbackLabel,
    required this.onTap,
  });

  final double size;
  final HeroRace race;
  final bool selected;
  final String? assetPath;
  final String fallbackLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = OnboardingTheme.purpleAccent;
    final radius = BorderRadius.circular(size * 0.32);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            if (selected) ...[
              const BoxShadow(
                color: accent,
                spreadRadius: 3,
                blurRadius: 0,
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ] else
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.35),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(selected ? 2 : 0),
          child: ClipRRect(
            borderRadius: radius,
            child: _SkinFigure(
              assetPath: assetPath,
              fallbackLabel: fallbackLabel,
              size: size - (selected ? 4 : 0),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaceTag extends StatelessWidget {
  const _RaceTag({required this.race, required this.l10n});

  final HeroRace race;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const accent = OnboardingTheme.purpleAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(color: accent, blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                '${race.name(l10n)} · ${race.description(l10n)}',
                key: ValueKey(race.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: OnboardingTheme.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
