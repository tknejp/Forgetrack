import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/player_cosmetic_lifecycle.dart';
import '../cosmetics_screen_internals.dart';
import 'companion_fake_idle_preview.dart';
import 'hidden_badge_large.dart';
import 'partial_progress_row.dart';
import 'tiny_pill.dart';

/// Slot width/height for the companion preview inside the cosmetic
/// details header. Bumped from the original 130 to 170 so the natural
/// size hierarchy across companions is preserved (wide / canvas-filling
/// companions stay visibly larger than tiny low-biased ones) without
/// needing per-asset normalisation — the raw asset renders at its
/// natural BoxFit.contain size and the bigger slot just gives every
/// companion more room to breathe.
const double kCompanionDetailsSlotSize = 170;

/// Vertical lift applied to the preview content (glow + image) inside
/// the slot. Both render in the upper portion of the slot so the
/// bottom-biased silhouettes most companion canvases use (foot pad
/// below the feet, compositional weight in the lower half) shift
/// closer to the slot's optical centre.
const double _kCompanionDetailsLift = 22;

/// Companion preview rendered inside the cosmetic details header — a
/// raw 512² asset over a soft rarity-tinted glow that covers the
/// whole render area, both shifted toward the top of the slot. Raw
/// render preserves natural size hierarchy (Mountain Gryphon stays
/// bigger than Ember Sprite); the slot is sized + lifted instead of
/// per-asset scaling so the glow always covers wherever the silhouette
/// actually lands.
class _CompanionDetailsPreview extends StatelessWidget {
  const _CompanionDetailsPreview({
    required this.assetPath,
    required this.glowColor,
  });

  final String? assetPath;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    // Padding wraps both the glow and the image so the two stay
    // locked together — shifting the image up via the bottom padding
    // also shifts the glow, which prevents the "silhouette low, glow
    // high" misalignment seen when only the image moved.
    return Padding(
      padding: const EdgeInsets.only(bottom: _kCompanionDetailsLift),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft full-area rarity glow. Sizing it to fill the padded
          // content rather than a tight halo means the silhouette
          // sits inside the glow regardless of how the asset balances
          // its content inside the 512² canvas — tiny low-biased
          // sprites are still kissed by colour even though they sit
          // lower than the glow's geometric peak.
          IgnorePointer(
            child: SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.38),
                      glowColor.withValues(alpha: 0.12),
                      glowColor.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          if (assetPath == null)
            Icon(Icons.pets_rounded, size: 56, color: glowColor)
          else
            Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.pets_rounded, size: 56, color: glowColor),
            ),
        ],
      ),
    );
  }
}

/// Header row of the cosmetic details standard body: badge / companion
/// preview on the left, name + pills + optional partial-progress row on
/// the right.
class CosmeticDetailsHeader extends StatelessWidget {
  const CosmeticDetailsHeader({
    super.key,
    required this.definition,
    required this.l10n,
    required this.color,
    required this.hiddenColor,
    required this.displayName,
    required this.assetPath,
    required this.isHidden,
    required this.isEquipped,
    required this.effectiveLocked,
    required this.isLocked,
    required this.devTools,
    required this.isRelicConsumed,
    required this.isPartial,
    required this.teased,
    required this.companionSlotKey,
    required this.hideCompanion,
  });

  final Cosmetic definition;
  final AppLocalizations l10n;
  final Color color;
  final Color hiddenColor;
  final String displayName;
  final String? assetPath;
  final bool isHidden;
  final bool isEquipped;
  final bool effectiveLocked;
  final bool isLocked;
  final bool devTools;
  final bool isRelicConsumed;
  final bool isPartial;
  final CosmeticTeased? teased;
  final GlobalKey companionSlotKey;
  final ValueNotifier<bool> hideCompanion;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isHidden)
          HiddenBadgeLarge(color: hiddenColor)
        else if (definition is Companion)
          SizedBox(
            key: companionSlotKey,
            width: kCompanionDetailsSlotSize,
            height: kCompanionDetailsSlotSize,
            child: ValueListenableBuilder<bool>(
              valueListenable: hideCompanion,
              builder: (context, hidden, child) {
                return Opacity(
                  opacity: hidden ? 0.0 : 1.0,
                  child: child,
                );
              },
              child: CompanionFakeIdlePreview(
                width: kCompanionDetailsSlotSize,
                height: kCompanionDetailsSlotSize,
                glowColor: color,
                enableGlow: false,
                floatDistance: 2.5,
                minScale: 0.995,
                maxScale: 1.008,
                // Raw BoxFit.contain render inside a bigger slot —
                // preserves the natural size hierarchy across
                // companions (wide canvases stay larger than tiny
                // low-biased ones) instead of normalising via the
                // per-asset `displayScale`. The slot itself is
                // enlarged + the content shifts up so the silhouette
                // lands at the optical centre regardless of how the
                // asset balances its content in the 512² canvas.
                child: _CompanionDetailsPreview(
                  assetPath: assetPath,
                  glowColor: color,
                ),
              ),
            ),
          )
        else
          CosmeticBadge(
            definition: definition,
            assetPath: assetPath,
            color: color,
            size: 94,
            framed: false,
            glow: true,
            fit: BoxFit.contain,
          ),
        const SizedBox(width: Tokens.spaceLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  color: isHidden ? Tokens.onSurfaceMuted : Tokens.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (!isHidden) ...[
                    TinyPill(
                      label: cosmeticTypeLabel(definition.type),
                      color: color,
                    ),
                    TinyPill(
                      label: definition.rarity.label(l10n),
                      color: color,
                    ),
                  ],
                  if (isEquipped)
                    TinyPill(
                      label: l10n.cosmeticEquippedBadge,
                      color: color,
                    ),
                  if (effectiveLocked && !isHidden)
                    TinyPill(
                      label: l10n.journeyBadgeLocked,
                      color: isLocked
                          ? Theme.of(context).colorScheme.error
                          : hiddenColor.withValues(alpha: 0.85),
                    ),
                  if (devTools && definition.assetKey == null)
                    TinyPill(
                      label: l10n.cosmeticNoAsset,
                      color: Colors.orange,
                    ),
                  if (isRelicConsumed)
                    TinyPill(
                      label: l10n.cosmeticRelicConsumedBadge,
                      color: Tokens.onSurfaceMuted,
                    ),
                ],
              ),
              if (isPartial) ...[
                const SizedBox(height: 8),
                PartialProgressRow(
                  satisfied: teased!.satisfiedConditions,
                  total: teased!.totalConditions,
                  l10n: l10n,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
