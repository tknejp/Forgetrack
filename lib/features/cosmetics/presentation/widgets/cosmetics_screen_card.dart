import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/cosmetics_provider.dart';
import '../../domain/cosmetic_lifecycle_helpers.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/player_cosmetic_lifecycle.dart';
import '../cosmetics_screen_internals.dart';
import '../emblem_buff_label.dart';
import 'companion_buff_chip.dart';
import 'cosmetic_preview_path.dart';
import 'cosmetics_screen_card_overlays.dart';

class CosmeticsScreenCard extends StatefulWidget {
  const CosmeticsScreenCard({
    super.key,
    required this.definition,
    required this.isEquipped,
    required this.l10n,
    required this.onTap,
    this.isLocked = false,
    this.showMissingAsset = false,
    this.lifecycle,
    this.isRelicConsumed = false,
  });

  final Cosmetic definition;
  final bool isEquipped;
  final bool isLocked;
  final bool showMissingAsset;
  final PlayerCosmeticLifecycle? lifecycle;
  final bool isRelicConsumed;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  State<CosmeticsScreenCard> createState() => _CosmeticsScreenCardState();
}

class _CosmeticsScreenCardState extends State<CosmeticsScreenCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;

  bool get _isClaimableCompanion =>
      widget.definition is Companion &&
      widget.lifecycle is CosmeticClaimable;

  @override
  void initState() {
    super.initState();
    if (_isClaimableCompanion) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(covariant CosmeticsScreenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isClaimableCompanion && _pulseCtrl == null) {
      _startPulse();
    } else if (!_isClaimableCompanion && _pulseCtrl != null) {
      _pulseCtrl?.dispose();
      _pulseCtrl = null;
    }
  }

  void _startPulse() {
    // Synced with `_ReadyPill` (1400 ms reverse-repeat) so the card
    // border / glow pulse + the corner pill pulse in lockstep — the
    // player sees one cohesive "PŘIPRAVEN" beat rather than two
    // out-of-phase animations.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final lifecycle = widget.lifecycle;
    final isEquipped = widget.isEquipped;
    final isLocked = widget.isLocked;
    final showMissingAsset = widget.showMissingAsset;
    final isRelicConsumed = widget.isRelicConsumed;
    final l10n = widget.l10n;
    final onTap = widget.onTap;
    final teased = lifecycle is CosmeticTeased ? lifecycle : null;
    final hidesCompanion =
        lifecycle != null && hidesIdentity(definition, lifecycle);
    final isHiddenCard = hidesCompanion || lifecycle is CosmeticHidden;
    final isClaimableCompanion = definition is Companion &&
        lifecycle is CosmeticClaimable;
    final isPartialCard = teased != null && teased.hasProgress;
    final isVisibleLocked = teased != null && !teased.hasProgress;
    final isNormalLocked = isLocked || isVisibleLocked;

    final color = isHiddenCard
        ? Tokens.onSurfaceFaint
        : cosmeticRarityColor(definition.rarity);

    final cosmeticsProvider = context.read<CosmeticsProvider>();
    final assetPath = isHiddenCard
        ? null
        : resolveCosmeticPreviewPath(
            definition,
            config: cosmeticsProvider.service.config,
            raceId: cosmeticsProvider.currentRaceId,
          );
    final hasAsset = definition.assetKey != null;

    final displayName = hidesCompanion
        ? l10n.cosmeticCompanionClaimableHiddenName
        : isHiddenCard
            ? l10n.cosmeticHiddenName
            : definition.name(l10n);
    final cardOpacity = isRelicConsumed
        ? 0.55
        : (isLocked || isVisibleLocked)
            ? 0.55
            : isClaimableCompanion
                ? 0.95
                : isHiddenCard
                    ? 0.35
                    : 1.0;

    BoxDecoration decorationFor(double pulse) {
      // Sub-issue 2 of Trello #76: the whole claimable companion card
      // breathes in lockstep with `_ReadyPill` so a single claimable
      // card stands out across a 20-card grid.
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.13),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(
          color: color.withValues(alpha: 0.27 + 0.10 * pulse),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16 + 0.10 * pulse),
            blurRadius: 12 + 4 * pulse,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    final pulseCtrl = _pulseCtrl;
    Widget buildCardBody(double pulse) => Container(
          decoration: decorationFor(pulse),
          child: _cardStack(
            color: color,
            assetPath: assetPath,
            hasAsset: hasAsset,
            displayName: displayName,
            isHiddenCard: isHiddenCard,
            isEquipped: isEquipped,
            isLocked: isLocked,
            isNormalLocked: isNormalLocked,
            isPartialCard: isPartialCard,
            isClaimableCompanion: isClaimableCompanion,
            isRelicConsumed: isRelicConsumed,
            showMissingAsset: showMissingAsset,
            teased: teased,
            l10n: l10n,
            definition: definition,
          ),
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: cardOpacity,
        child: pulseCtrl != null
            ? AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => buildCardBody(pulseCtrl.value),
              )
            : buildCardBody(0),
      ),
    );
  }

  Widget _cardStack({
    required Color color,
    required String? assetPath,
    required bool hasAsset,
    required String displayName,
    required bool isHiddenCard,
    required bool isEquipped,
    required bool isLocked,
    required bool isNormalLocked,
    required bool isPartialCard,
    required bool isClaimableCompanion,
    required bool isRelicConsumed,
    required bool showMissingAsset,
    required CosmeticTeased? teased,
    required AppLocalizations l10n,
    required Cosmetic definition,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isHiddenCard)
                  CardHiddenBadge(
                    color: color,
                    size: _cardBadgeSize(definition.type),
                  )
                else
                  CosmeticBadge(
                    definition: definition,
                    assetPath: assetPath,
                    color: color,
                    size: _cardBadgeSize(definition.type),
                    framed: false,
                  ),
                const SizedBox(height: Tokens.spaceSm),
                Text(
                  displayName,
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
                if (!isHiddenCard) ...[
                  Builder(builder: (context) {
                    final String? label;
                    if (definition is Emblem &&
                        definition.buff != null) {
                      label = emblemBuffLabel(definition.buff!, l10n);
                    } else if (definition is Companion &&
                        definition.buff != null) {
                      label = formatCompanionBuff(l10n, definition.buff!);
                    } else {
                      label = null;
                    }
                    if (label == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        label,
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
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        if (isEquipped)
          Positioned(
            top: 7,
            right: 7,
            child: Icon(
              Icons.check_circle_rounded,
              color: color,
              size: 17,
            ),
          ),
        if (isLocked)
          Positioned(
            top: 5,
            left: 5,
            child: Icon(
              Icons.lock_rounded,
              size: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        if (!isLocked && (isNormalLocked || isPartialCard))
          Positioned(
            top: 5,
            left: 5,
            child: Icon(
              Icons.lock_rounded,
              size: 13,
              color: color.withValues(alpha: 0.55),
            ),
          ),
        if (isPartialCard && !isClaimableCompanion && teased != null)
          Positioned(
            bottom: 5,
            right: 5,
            child: CardProgressChip(
              satisfied: teased.satisfiedConditions,
              total: teased.totalConditions,
              color: color,
            ),
          ),
        if (isClaimableCompanion)
          Positioned(
            bottom: 5,
            right: 5,
            child: CardReadyPill(
              label: l10n.cosmeticCompanionClaimableBadge,
              color: color,
            ),
          ),
        if (isRelicConsumed)
          Positioned(
            bottom: 5,
            right: 5,
            child: CardConsumedPill(label: l10n.cosmeticRelicConsumedBadge),
          ),
        if (showMissingAsset && !hasAsset)
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'NO ASSET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

double _cardBadgeSize(CosmeticType type) {
  switch (type) {
    case CosmeticType.frame:
      return 66;
    case CosmeticType.relic:
    case CosmeticType.background:
    case CosmeticType.emblem:
    case CosmeticType.companion:
    case CosmeticType.titleFlair:
    case CosmeticType.mapEffect:
    case CosmeticType.skin:
    case CosmeticType.banner:
      return 48;
  }
}
