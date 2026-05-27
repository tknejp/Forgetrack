import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_log.dart';
import '../../../l10n/app_localizations.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/domain/catalog/granting_achievement_lookup.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_lifecycle_helpers.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_state.dart';
import '../domain/cosmetic_unlock_rule.dart';
import '../domain/cosmetic_unlock_rules.dart';
import '../domain/player_cosmetic_lifecycle.dart';
import '../config/skin_asset_resolver.dart';
import 'cosmetics_screen_internals.dart';
import 'widgets/claimable_companion_body.dart';
import 'widgets/companion_claim_flow.dart';
import 'widgets/cosmetic_details_standard_body.dart';
import 'widgets/cosmetic_preview_path.dart';
import 'widgets/locked_companion_body.dart';

const _log = AppLogger('COSMETICS', scope: 'details_sheet');

class CosmeticDetailsSheet extends StatefulWidget {
  const CosmeticDetailsSheet({
    super.key,
    required this.definition,
    required this.state,
    required this.l10n,
    this.isLocked = false,
    this.devToolsUnlockRules,
    this.devToolsMode = false,
    this.revealResult,
    this.isRelicConsumed = false,
  });

  final Cosmetic definition;
  final UserCosmeticsState state;
  final AppLocalizations l10n;

  /// DevTools-only: whether to show locked-state UI (ZAMČENO pill, Grant btn).
  final bool isLocked;
  final List<CosmeticUnlockRule>? devToolsUnlockRules;
  final bool devToolsMode;

  /// Normal-mode reveal result. Null in devTools mode.
  final CosmeticRevealResult? revealResult;

  /// True for a relic that has already been consumed by a companion
  /// claim.
  final bool isRelicConsumed;

  @override
  State<CosmeticDetailsSheet> createState() => _CosmeticDetailsSheetState();
}

class _CosmeticDetailsSheetState extends State<CosmeticDetailsSheet> {
  bool _equipBusy = false;
  bool _devBusy = false;

  /// Attached to the unlocked-layout companion avatar; the morph
  /// layer reads its absolute position to land the sprite exactly
  /// over the slot. Lives on this state — the sheet widget is the
  /// same instance across the Claimable → Owned rebuild, so the key
  /// keeps pointing at the avatar from one frame to the next.
  final GlobalKey _companionSlotKey = GlobalKey();

  /// Notifier the avatar slot watches — true during the morph
  /// handoff. The forging overlay flips it true at the reveal
  /// frame so the rebuild triggered by the engine grant doesn't
  /// flash a second sprite, and the morph layer flips it back to
  /// false once it reaches the destination.
  final ValueNotifier<bool> _hideCompanion = ValueNotifier(false);

  /// Cross-state owner for the ritual's fullscreen [OverlayEntry].
  final ClaimOverlayHandle _claimOverlay = ClaimOverlayHandle();

  @override
  void dispose() {
    _hideCompanion.dispose();
    _claimOverlay.removeIfActive();
    super.dispose();
  }

  Future<void> _toggleEquipped() async {
    if (_equipBusy || _devBusy) return;
    setState(() => _equipBusy = true);
    final provider = context.read<CosmeticsProvider>();
    final definition = widget.definition;
    final isEquipped =
        widget.state.equipped.slotId(definition.type) == definition.id;
    if (isEquipped) {
      await provider.unequip(definition.type);
    } else {
      await provider.equip(definition.id);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _devGrant() async {
    if (_devBusy || _equipBusy) return;
    setState(() => _devBusy = true);
    final navigator = Navigator.of(context);
    final sheetRoute = ModalRoute.of(context);
    final cosmeticId = widget.definition.id;
    final grantingNodeId = grantingNodeForCosmetic(cosmeticId);
    _log.info('devGrant start',
        payload: 'id=$cosmeticId grantingNode=${grantingNodeId ?? "<none>"}');
    try {
      if (grantingNodeId != null) {
        await context
            .read<ProgressionEngineProvider>()
            .devToolsForceCompleteNode(grantingNodeId);
        _log.info('devGrant via engine completed',
            payload: 'id=$cosmeticId grantingNode=$grantingNodeId');
      } else {
        await context
            .read<CosmeticsProvider>()
            .debugGrantCosmetic(cosmeticId);
        _log.info('devGrant via cosmetics debugGrant completed',
            payload: 'id=$cosmeticId');
      }
    } finally {
      if (mounted) {
        setState(() => _devBusy = false);
      }
    }
    if (!mounted) return;
    _closeSheet(navigator, sheetRoute);
  }

  Future<void> _devRevoke() async {
    if (_devBusy || _equipBusy) return;
    setState(() => _devBusy = true);
    final navigator = Navigator.of(context);
    final sheetRoute = ModalRoute.of(context);
    try {
      await context
          .read<CosmeticsProvider>()
          .debugRevokeCosmetic(widget.definition.id);
    } finally {
      if (mounted) {
        setState(() => _devBusy = false);
      }
    }
    if (!mounted) return;
    _closeSheet(navigator, sheetRoute);
  }

  /// Removes the sheet's specific route from the Navigator stack.
  /// Using `removeRoute` (rather than `pop`) protects against an
  /// overlay route (celebration, dialog) being pushed mid-await and
  /// stealing the pop, which would leave the sheet stuck open.
  void _closeSheet(NavigatorState navigator, ModalRoute<Object?>? sheetRoute) {
    if (sheetRoute != null && sheetRoute.isActive) {
      navigator.removeRoute(sheetRoute);
    } else {
      navigator.maybePop();
    }
  }

  /// Opens the given relic's own [CosmeticDetailsSheet] on top of the
  /// current modal. Passed down to the companion checklist so each
  /// gating relic is tappable.
  void _openRelicDetails(BuildContext context, Cosmetic relic) {
    final cosmetics = context.read<CosmeticsProvider>();
    final state = cosmetics.state;
    if (state == null) return;
    final revealResults =
        cosmetics.computeRevealResults(kCosmeticUnlockRules);
    final revealResult = revealResults[relic.id];
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CosmeticDetailsSheet(
        definition: relic,
        state: state,
        l10n: widget.l10n,
        revealResult: revealResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final l10n = widget.l10n;
    final color = cosmeticRarityColor(definition.rarity);
    // Watch the cosmetics provider so a successful claim from the
    // embedded [CompanionClaimFlow] flips this sheet from the
    // claim-flow layout into the normal unlocked layout without
    // requiring the player to re-open the sheet.
    final cosmeticsProvider = context.watch<CosmeticsProvider>();
    final cosmeticsState = cosmeticsProvider.state ?? widget.state;
    final progression = context.watch<ProgressionEngineProvider>();
    final canEquipType = definition is Frame ||
        definition is Background ||
        definition is Companion;
    final isEquipped = canEquipType &&
        cosmeticsState.equipped.slotId(definition.type) == definition.id;
    final assetPath = resolveCosmeticPreviewPath(
      definition,
      config: cosmeticsProvider.service.config,
      raceId: cosmeticsProvider.currentRaceId,
      // The details header on the standard body renders skins as a
      // full-body composition (no frame border around the figure),
      // matching the profile / hero hero header treatment.
      skinVariant: SkinAssetVariant.fullBody,
      // Companions render in a 170² header slot via
      // CompanionFakeIdlePreview — that uses the full 512² painted
      // asset so the silhouette + rarity glow fill the slot. The
      // inventory-tile preview thumb would shrink down to ~half size
      // and lose presence at this scale. Banner / background /
      // skin / frame / relic / emblem all read fine off the preview.
      usePreviewKey: definition is! Companion,
    );
    final description = definition.description(l10n);
    final unlock = cosmeticsState.unlocked[definition.id];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isLocked = widget.isLocked;
    final devTools = widget.devToolsMode;
    final rules = widget.devToolsUnlockRules;
    final anyBusy = _equipBusy || _devBusy;

    // Recompute the reveal result from the **current** cosmetics
    // state instead of using the stale `widget.revealResult` snapshot.
    final revealResults = devTools
        ? const <String, CosmeticRevealResult>{}
        : cosmeticsProvider.computeRevealResults(kCosmeticUnlockRules);
    final revealResult = devTools
        ? null
        : (revealResults[definition.id] ?? widget.revealResult);

    final isRelicConsumed = widget.isRelicConsumed;

    // Phase 10: pattern-match on PlayerCosmeticLifecycle instead of
    // CosmeticRevealState directly. The inventory carries the same
    // mapping the reveal evaluator computes, plus the
    // [CosmeticClaimable] surface for companion availability gates.
    final lifecycle = devTools
        ? null
        : cosmeticsProvider
                .buildInventory(claimableNodeIds: progression.availableNodeIds)
                .byIdString(definition.id)
                ?.lifecycle ??
            const CosmeticHidden();
    final teased = lifecycle is CosmeticTeased ? lifecycle : null;
    final isHidden = lifecycle is CosmeticHidden;
    final isPartial = teased != null && teased.hasProgress;
    final isVisibleLocked = teased != null && !teased.hasProgress;
    final effectiveLocked =
        devTools ? isLocked : (isVisibleLocked || isPartial || isHidden);

    // Hidden cards show a mystery header instead of the real cosmetic.
    final displayName =
        isHidden ? l10n.cosmeticUnknownReward : definition.name(l10n);
    final hiddenColor =
        isHidden ? cosmeticRarityColor(definition.rarity) : color;
    // Hidden state forces muted color even on the rarity-tinted side.
    final resolvedHiddenColor = isHidden ? hiddenColor : color;

    // Companion identity-hide rule (proposal §4.3): when [hidesIdentity]
    // says we must conceal the companion, the sheet shows one of two
    // alternate bodies in place of the regular layout.
    if (!devTools && hidesIdentity(definition, lifecycle!)) {
      if (lifecycle is CosmeticClaimable) {
        return ClaimableCompanionBody(
          definition: definition,
          l10n: l10n,
          color: color,
          bottomPad: bottomPad,
          destSlotKey: _companionSlotKey,
          hideCompanion: _hideCompanion,
          overlayHandle: _claimOverlay,
        );
      }
      return LockedCompanionBody(
        definition: definition,
        teased: teased,
        l10n: l10n,
        bottomPad: bottomPad,
        onOpenRelic: _openRelicDetails,
      );
    }

    return CosmeticDetailsStandardBody(
      definition: definition,
      l10n: l10n,
      color: color,
      assetPath: assetPath,
      description: description,
      unlock: unlock,
      bottomPad: bottomPad,
      isLocked: isLocked,
      devTools: devTools,
      devToolsUnlockRules: rules,
      isRelicConsumed: isRelicConsumed,
      revealResult: revealResult,
      teased: teased,
      isHidden: isHidden,
      isPartial: isPartial,
      isVisibleLocked: isVisibleLocked,
      effectiveLocked: effectiveLocked,
      isEquipped: isEquipped,
      displayName: displayName,
      hiddenColor: resolvedHiddenColor,
      companionSlotKey: _companionSlotKey,
      hideCompanion: _hideCompanion,
      equipBusy: _equipBusy,
      devBusy: _devBusy,
      anyBusy: anyBusy,
      onToggleEquipped: _toggleEquipped,
      onDevGrant: _devGrant,
      onDevRevoke: _devRevoke,
      onOpenRelic: _openRelicDetails,
    );
  }
}
