import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/stat_card.dart';

/// "You need to set up X" card used by Health Connect and Kalorické
/// Tabulky on the home overview. Mirrors the visual chrome of a normal
/// [StatCard] (domain card decoration, hero icon + background asset,
/// title row) so prompt slots blend with the rest of the dashboard
/// instead of looking like a foreign popover.
///
/// The data-source logo (KT, HC, …) is shown on the primary CTA button
/// only — keeping the card header consistent with the connected state.
class DataSourcePromptCard extends StatelessWidget {
  const DataSourcePromptCard({
    super.key,
    required this.domain,
    required this.heroIcon,
    required this.title,
    required this.body,
    required this.ctaLogoAsset,
    required this.ctaLabel,
    required this.providerAccent,
    required this.onAction,
    required this.onShowCached,
    this.visualAssets,
  });

  /// Drives the card decoration / hero glow, matching the StatCard that
  /// occupies this slot once the source is set up. Independent from
  /// [providerAccent] — the *card* speaks the slot's data domain (e.g.
  /// calories), the *CTA* speaks the data provider's brand identity.
  final Domain domain;

  /// Emoji used inside the hero icon when no asset is supplied (matches
  /// [StatCard.icon] fallback).
  final String heroIcon;

  final String title;
  final String body;

  /// Source logo (KT/HC PNG) rendered as a prefix on the CTA button.
  final String ctaLogoAsset;

  final String ctaLabel;

  /// Brand colour of the data provider (KT green, HC blue, future
  /// integrations get their own hue). Used as the outline + label tint
  /// on the primary CTA so each provider stays visually distinct from
  /// the card's data domain.
  final Color providerAccent;

  final VoidCallback onAction;

  /// Dashboard hero icon + background asset bundle. Same value passed
  /// to the matching connected-state StatCard so the visual continuity
  /// across "needs setup → has data" transitions is preserved.
  final StatCardVisualAssets? visualAssets;

  /// When non-null, renders the secondary "Show saved data" pill that
  /// lets the user view previously cached data without setting up the
  /// source. Null when there's no cache to show — in that case the
  /// prompt offers login only, since there's nothing to fall back to.
  final VoidCallback? onShowCached;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;

    return RepaintBoundary(
      child: Container(
        decoration: domain.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _buildBackgroundImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: ft.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceMd),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ft.onSurfaceMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceLg),
                  _buildPrimaryCta(),
                  if (onShowCached != null) ...[
                    const SizedBox(height: Tokens.spaceSm),
                    _buildShowCachedCta(context, ft, l10n),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final assets = visualAssets;
    if (assets == null || !assets.hasBackgroundAsset) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(assets.backgroundAssetPath!),
              fit: BoxFit.cover,
              alignment: assets.backgroundAlignment,
              opacity: assets.backgroundOpacity.clamp(0.0, 1.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIcon() {
    final assets = visualAssets;
    final hasAsset = assets != null && assets.hasIconAsset;
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: domain.glow.withValues(alpha: 0.18),
                  blurRadius: Tokens.glowSm,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          if (hasAsset)
            Image.asset(
              assets.iconAssetPath!,
              width: 74,
              height: 74,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(heroIcon, style: const TextStyle(fontSize: 30));
              },
            )
          else
            Text(heroIcon, style: const TextStyle(fontSize: 30)),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: providerAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: providerAccent.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              ctaLogoAsset,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.login_rounded,
                size: 18,
                color: providerAccent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              ctaLabel,
              style: TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w800,
                color: providerAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowCachedCta(
    BuildContext context,
    ThemeTokens ft,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onShowCached,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Text(
          l10n.healthShowCachedData,
          style: TextStyle(
            fontSize: Tokens.fontSizeSmall,
            fontWeight: FontWeight.w700,
            color: ft.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
