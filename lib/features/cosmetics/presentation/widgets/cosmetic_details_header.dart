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
            width: 130,
            height: 130,
            child: ValueListenableBuilder<bool>(
              valueListenable: hideCompanion,
              builder: (context, hidden, child) {
                return Opacity(
                  opacity: hidden ? 0.0 : 1.0,
                  child: child,
                );
              },
              child: CompanionFakeIdlePreview(
                width: 130,
                height: 130,
                glowColor: color,
                enableGlow: false,
                floatDistance: 2.5,
                minScale: 0.995,
                maxScale: 1.008,
                child: CosmeticBadge(
                  definition: definition,
                  assetPath: assetPath,
                  color: color,
                  size: 130,
                  framed: false,
                  glow: true,
                  fit: BoxFit.contain,
                  contentScale: 1.25,
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
