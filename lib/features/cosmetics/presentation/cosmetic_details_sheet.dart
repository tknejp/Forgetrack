import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_log.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/domain/catalog/granting_achievement_lookup.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_catalog.dart';
import '../domain/cosmetic_lifecycle_helpers.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_state.dart';
import '../domain/cosmetic_unlock_rule.dart';
import '../domain/cosmetic_unlock_rules.dart';
import '../domain/consumed_relics.dart';
import '../domain/player_cosmetic_lifecycle.dart';
import 'cosmetics_screen_internals.dart';
import 'widgets/companion_claim_reveal.dart';
import 'widgets/companion_fake_idle_preview.dart';

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

  /// Normal-mode reveal result. Null in devTools mode. Phase 11 keeps
  /// this only as a fallback when the inventory's lifecycle hasn't
  /// surfaced rows yet (cold first build); the body re-derives the
  /// lifecycle from the provider on every build.
  final CosmeticRevealResult? revealResult;

  /// True for a relic that has already been consumed by a companion
  /// claim. Adds a "Použito" pill + replaces the unlock-source hint
  /// with the consumed flavor line.
  final bool isRelicConsumed;

  @override
  State<CosmeticDetailsSheet> createState() => _CosmeticDetailsSheetState();
}

class _CosmeticDetailsSheetState extends State<CosmeticDetailsSheet> {
  bool _equipBusy = false;
  bool _devBusy = false;

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
    final cosmeticId = widget.definition.id;
    final grantingNodeId = grantingNodeForCosmetic(cosmeticId);
    _log.info('devGrant start',
        payload: 'id=$cosmeticId grantingNode=${grantingNodeId ?? "<none>"}');
    if (grantingNodeId != null) {
      // Route through the engine so the granting node's
      // NodeCompletionEvent + RewardGrantEvent(cosmetic) series lands
      // in the ledger; the cosmetic-unlock bridge then flips the
      // cosmetic in inventory via the production path. This keeps
      // the engine ledger + cosmetics inventory in lockstep — without
      // it, devtools-granting a relic leaves the corresponding
      // CompanionAvailability node permanently un-claimable because
      // its `OwnsCosmetic(relic)` gate holds while its parent
      // achievement's NodeCompletion is absent from the journal
      // (Trello #76 sub-issue 1).
      await context
          .read<ProgressionEngineProvider>()
          .devToolsForceCompleteNode(grantingNodeId);
      _log.info('devGrant via engine completed',
          payload: 'id=$cosmeticId grantingNode=$grantingNodeId');
    } else {
      // Cosmetic with no catalog-side granting node (e.g. premium
      // unlocks, content that ships pre-unlocked, dev-only items).
      // Falls back to the direct cosmetics-inventory grant.
      await context
          .read<CosmeticsProvider>()
          .debugGrantCosmetic(cosmeticId);
      _log.info('devGrant via cosmetics debugGrant completed',
          payload: 'id=$cosmeticId');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _devRevoke() async {
    if (_devBusy || _equipBusy) return;
    setState(() => _devBusy = true);
    await context
        .read<CosmeticsProvider>()
        .debugRevokeCosmetic(widget.definition.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;
    final l10n = widget.l10n;
    final color = cosmeticRarityColor(definition.rarity);
    // Watch the cosmetics provider so a successful claim from the
    // embedded [CompanionClaimReveal] flips this sheet from the
    // claim-flow layout into the normal unlocked layout without
    // requiring the player to re-open the sheet. Watching progression
    // alongside catches the case where the engine finished the manual
    // claim before the cosmetics-side notify arrives (the order is
    // not contractually guaranteed by `claimNode`).
    final cosmeticsProvider = context.watch<CosmeticsProvider>();
    final cosmeticsState = cosmeticsProvider.state ?? widget.state;
    final progression = context.watch<ProgressionEngineProvider>();
    final isEquipped =
        cosmeticsState.equipped.slotId(definition.type) == definition.id;
    final assetPath = context
        .read<CosmeticsProvider>()
        .service
        .config
        .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final description = definition.description(l10n);
    final unlock = cosmeticsState.unlocked[definition.id];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isLocked = widget.isLocked;
    final devTools = widget.devToolsMode;
    final rules = widget.devToolsUnlockRules;
    final anyBusy = _equipBusy || _devBusy;

    // Recompute the reveal result from the **current** cosmetics
    // state instead of using the stale `widget.revealResult` snapshot
    // captured at the moment `_showDetails` was called. Without this
    // the sheet keeps showing ZAMČENO + "1/3 podmínek splněno" after
    // the player claims the companion mid-sheet, because the parent's
    // reveal map was frozen at "partial".
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
    final effectiveLocked = devTools ? isLocked : (isVisibleLocked || isPartial || isHidden);

    // Hidden cards show a mystery header instead of the real cosmetic.
    final displayName = isHidden ? l10n.cosmeticUnknownReward : definition.name(l10n);
    final hiddenColor = isHidden
        ? Tokens.onSurfaceMuted
        : color;

    // Companion identity-hide rule (proposal §4.3): when [hidesIdentity]
    // says we must conceal the companion (i.e. it's a Companion catalog
    // row and the lifecycle is anything except Owned), the sheet shows
    // one of two alternate bodies in place of the regular layout:
    //   * Claimable → forging animation + "Vyzvedni" CTA
    //   * Hidden / Teased → mystery body with optional checklist
    // Non-companion cosmetics never hit this branch.
    if (!devTools && hidesIdentity(definition, lifecycle!)) {
      if (lifecycle is CosmeticClaimable) {
        return _ClaimableCompanionBody(
          definition: definition,
          l10n: l10n,
          color: color,
          bottomPad: bottomPad,
        );
      }
      return _LockedCompanionBody(
        definition: definition,
        teased: teased,
        l10n: l10n,
        bottomPad: bottomPad,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius:
                        BorderRadius.circular(Tokens.radiusProgress),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // header: badge + name + pills
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isHidden)
                    _HiddenBadgeLarge(color: hiddenColor)
                  else if (definition is Companion)
                    CompanionFakeIdlePreview(
                      width: 128,
                      height: 128,
                      glowColor: color,
                      enableGlow: false,
                      floatDistance: 2.5,
                      minScale: 0.995,
                      maxScale: 1.008,
                      child: CosmeticBadge(
                        definition: definition,
                        assetPath: assetPath,
                        color: color,
                        size: 128,
                        framed: false,
                        glow: true,
                        fit: BoxFit.contain,
                        contentScale: 1.25,
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
                            color: isHidden
                                ? Tokens.onSurfaceMuted
                                : Tokens.onSurface,
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
                              _TinyPill(
                                label: cosmeticTypeLabel(definition.type),
                                color: color,
                              ),
                              _TinyPill(
                                label: definition.rarity.label(l10n),
                                color: color,
                              ),
                            ],
                            if (isEquipped)
                              _TinyPill(
                                label: l10n.cosmeticEquippedBadge,
                                color: color,
                              ),
                            if (effectiveLocked && !isHidden)
                              _TinyPill(
                                label: l10n.journeyBadgeLocked,
                                color: isLocked
                                    ? Theme.of(context).colorScheme.error
                                    : hiddenColor.withValues(alpha: 0.85),
                              ),
                            if (devTools && definition.assetKey == null)
                              _TinyPill(
                                label: l10n.cosmeticNoAsset,
                                color: Colors.orange,
                              ),
                            if (isRelicConsumed)
                              _TinyPill(
                                label: l10n.cosmeticRelicConsumedBadge,
                                color: Tokens.onSurfaceMuted,
                              ),
                          ],
                        ),
                        // partial progress indicator
                        if (isPartial) ...[
                          const SizedBox(height: 8),
                          _PartialProgressRow(
                            satisfied: teased.satisfiedConditions,
                            total: teased.totalConditions,
                            l10n: l10n,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // description
              if (!isHidden && description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  description,
                  style: const TextStyle(
                    color: Tokens.onSurfaceMuted,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // companion requirements checklist — shown for every
              // companion reveal state where we have rows (partial /
              // visibleLocked teaser / unlocked). The evaluator now
              // populates rows for `unlocked` too, with every entry
              // marked met, so the player sees the same checklist
              // they used while progressing — just fully ticked.
              if (!devTools &&
                  !isHidden &&
                  definition is Companion &&
                  revealResult?.conditionRows != null) ...[
                const SizedBox(height: 18),
                _CompanionChecklist(
                  conditionRows: revealResult!.conditionRows!,
                  color: color,
                  l10n: l10n,
                ),
              ],

              // unlock info (unlocked items)
              if (unlock != null) ...[
                const SizedBox(height: 14),
                Text(
                  l10n.cosmeticUnlockedAt(
                    MaterialLocalizations.of(context).formatMediumDate(unlock.unlockedAt),
                  ),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.78),
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],

              // hidden mystery hint
              if (isHidden) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.help_outline_rounded,
                        size: 13,
                        color: Tokens.onSurfaceFaint.withValues(alpha: 0.6)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.cosmeticHiddenUnlockCondition,
                        style: TextStyle(
                          color: Tokens.onSurfaceFaint.withValues(alpha: 0.6),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // visible-locked unlock hint
              if ((isVisibleLocked || isPartial) &&
                  definition.unlockHint != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHint!(l10n),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // consumed relic flavor line
              if (isRelicConsumed) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: Tokens.onSurfaceMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.cosmeticRelicConsumedHint,
                        style: const TextStyle(
                          color: Tokens.onSurfaceMuted,
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // unlocked items: show how this was earned
              if (!isHidden && !effectiveLocked && !devTools &&
                  definition.unlockHint != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star_border_rounded,
                        size: 13, color: color.withValues(alpha: 0.55)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHint!(l10n),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.55),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // devTools: always show the player-facing unlock hint when one
              // exists, even if raw rule details are shown below.
              if (devTools && definition.unlockHint != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        definition.unlockHint!(l10n),
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // unlock conditions (devtools)
              if (rules != null && rules.isNotEmpty) ...[
                const SizedBox(height: 18),
                _UnlockConditionsSection(rules: rules, color: color),
              ],

              // debug details section
              if (devTools) ...[
                const SizedBox(height: 18),
                _DebugDetailsSection(
                  definition: definition,
                  unlock: unlock,
                  color: color,
                ),
              ],

              const SizedBox(height: 20),

              // action buttons
              if (devTools) ...[
                if (isLocked)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: anyBusy
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: _outlineStyle(color),
                          child: Text(l10n.dialogClose),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DevButton(
                          label: l10n.devGrant,
                          icon: Icons.lock_open_rounded,
                          color: Colors.greenAccent,
                          busy: _devBusy,
                          onTap: anyBusy ? null : _devGrant,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _ActionButton(
                        label: isEquipped ? l10n.cosmeticUnequip : l10n.cosmeticEquip,
                        icon: isEquipped
                            ? Icons.remove_circle_outline_rounded
                            : Icons.check_circle_rounded,
                        color: color,
                        busy: _equipBusy,
                        onTap: anyBusy ? null : _toggleEquipped,
                      ),
                      const SizedBox(height: 8),
                      _DevButton(
                        label: l10n.devRevoke,
                        icon: Icons.lock_rounded,
                        color: Theme.of(context).colorScheme.error,
                        busy: _devBusy,
                        onTap: anyBusy ? null : _devRevoke,
                      ),
                    ],
                  ),
              ] else if (effectiveLocked)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: _outlineStyle(isHidden ? Tokens.onSurfaceMuted : color),
                    child: Text(l10n.dialogClose),
                  ),
                )
              else
                _ActionButton(
                  label: isEquipped ? l10n.cosmeticUnequip : l10n.cosmeticEquip,
                  icon: isEquipped
                      ? Icons.remove_circle_outline_rounded
                      : Icons.check_circle_rounded,
                  color: color,
                  busy: _equipBusy,
                  onTap: anyBusy ? null : _toggleEquipped,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static ButtonStyle _outlineStyle(Color color) => OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.34)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hidden badge (94px placeholder for the details sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _HiddenBadgeLarge extends StatelessWidget {
  const _HiddenBadgeLarge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: 36,
          color: color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Partial progress row
// ─────────────────────────────────────────────────────────────────────────────

class _PartialProgressRow extends StatelessWidget {
  const _PartialProgressRow({
    required this.satisfied,
    required this.total,
    required this.l10n,
    required this.color,
  });

  final int satisfied;
  final int total;
  final AppLocalizations l10n;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.incomplete_circle_rounded,
            size: 13, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 5),
        Text(
          l10n.cosmeticPartialProgress(satisfied, total),
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Companion requirements checklist
// ─────────────────────────────────────────────────────────────────────────────

class _CompanionChecklist extends StatelessWidget {
  const _CompanionChecklist({
    required this.conditionRows,
    required this.color,
    required this.l10n,
  });

  final List<CosmeticRevealConditionRow> conditionRows;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checklist_rounded,
                size: 13, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
            Text(
              l10n.cosmeticRequirementsHeader,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final row in conditionRows)
          _ChecklistRow(row: row, color: color, l10n: l10n),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.row,
    required this.color,
    required this.l10n,
  });

  final CosmeticRevealConditionRow row;
  final Color color;
  final AppLocalizations l10n;

  static const _catalog = CosmeticCatalog();
  static const _levelPrefix = 'level_at_least_';
  static const _ownsPrefix = 'owns_';

  String _label() {
    final id = row.conditionId;
    if (id.startsWith(_levelPrefix)) {
      final level = int.tryParse(id.substring(_levelPrefix.length));
      if (level != null) return l10n.cosmeticCompanionLevelGate(level);
    }
    if (id.startsWith(_ownsPrefix)) {
      final cosmeticId = id.substring(_ownsPrefix.length);
      final name = _catalog.byId(cosmeticId)?.name(l10n);
      if (name != null) return name;
    }
    return id.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final metColor = row.met ? color : Tokens.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            row.met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: metColor.withValues(alpha: row.met ? 0.9 : 0.45),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _label(),
              style: TextStyle(
                color: metColor.withValues(alpha: row.met ? 0.9 : 0.6),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debug details
// ─────────────────────────────────────────────────────────────────────────────

class _DebugDetailsSection extends StatelessWidget {
  const _DebugDetailsSection({
    required this.definition,
    required this.unlock,
    required this.color,
  });

  final Cosmetic definition;
  final UnlockedCosmetic? unlock;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Icon(Icons.bug_report_outlined,
                  size: 13, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).debugDetailsHeader,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          children: [
            _DebugRow(AppLocalizations.of(context).debugRowId, definition.id, copyable: true),
            _DebugRow(AppLocalizations.of(context).debugRowType, definition.type.name),
            _DebugRow(AppLocalizations.of(context).debugRowRarity, definition.rarity.name),
            _DebugRow(AppLocalizations.of(context).debugRowRegion, definition.region.name),
            _DebugRow(
              AppLocalizations.of(context).debugRowAssetKey,
              definition.assetKey ?? AppLocalizations.of(context).debugMissing,
              warn: definition.assetKey == null,
              copyable: definition.assetKey != null,
            ),
            if (definition.previewAssetKey != null &&
                definition.previewAssetKey != definition.assetKey)
              _DebugRow(AppLocalizations.of(context).debugRowPreviewAssetKey, definition.previewAssetKey!, copyable: true),
            _DebugRow(AppLocalizations.of(context).debugRowSortOrder, '${definition.sortOrder}'),
            _DebugRow(
              AppLocalizations.of(context).debugRowIsPremium,
              '${definition.isPremium}',
              warn: definition.isPremium,
            ),
            _DebugRow(
              AppLocalizations.of(context).debugRowIsEnabled,
              '${definition.isEnabled}',
              warn: !definition.isEnabled,
            ),
            if (definition.metadata.isNotEmpty)
              _DebugRow(AppLocalizations.of(context).debugRowMetadata, _fmtMap(definition.metadata)),
            if (unlock != null) ...[
              const Divider(height: 14, thickness: 1),
              _DebugRow(
                AppLocalizations.of(context).debugRowUnlockedAt,
                unlock!.unlockedAt.toIso8601String(),
              ),
              if (unlock!.sourceType != null)
                _DebugRow(AppLocalizations.of(context).debugRowSourceType, unlock!.sourceType!),
              if (unlock!.sourceId != null)
                _DebugRow(AppLocalizations.of(context).debugRowSourceId, unlock!.sourceId!),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtMap(Map<String, Object?> map) {
    if (map.isEmpty) return '{}';
    final entries =
        map.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '{ $entries }';
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow(
    this.label,
    this.value, {
    this.warn = false,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool warn;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueColor = warn
        ? Colors.orange.withValues(alpha: 0.9)
        : cs.onSurfaceVariant.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
              child: GestureDetector(
              onLongPress: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context).copiedToClipboard(value)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).copiedToClipboard(value)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unlock conditions
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockConditionsSection extends StatelessWidget {
  const _UnlockConditionsSection({
    required this.rules,
    required this.color,
  });

  final List<CosmeticUnlockRule> rules;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_open_rounded,
                size: 13, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
            Text(
              l10n.cosmeticUnlockConditionsHeader,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: Tokens.fontSizeCaption,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < rules.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.listOrSeparator,
                style: tt.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.4),
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _RuleBlock(rule: rules[i], color: color),
        ],
      ],
    );
  }
}

class _RuleBlock extends StatelessWidget {
  const _RuleBlock({required this.rule, required this.color});

  final CosmeticUnlockRule rule;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).ruleSource(rule.sourceType, rule.sourceId),
            style: tt.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          for (final cond in rule.conditions)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_box_outline_blank_rounded,
                      size: 11,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      cond.id
                          .replaceAll('_at_least_', ' ≥ ')
                          .replaceAll('_', ' '),
                      style: tt.bodySmall?.copyWith(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared button widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DevButton extends StatelessWidget {
  const _DevButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: busy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Tokens.bg,
          disabledBackgroundColor: color.withValues(alpha: 0.34),
          disabledForegroundColor: Tokens.onSurfaceMuted,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: Tokens.fontSizeMicro,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Claim-flow body shown in place of the regular details layout when a
/// companion's `CompanionAvailability` is in `available` state. The
/// player taps "Vyzvedni společníka" inside the [CompanionClaimReveal]
/// stage — that triggers the relic-fusing animation and, on completion,
/// calls `progression.claimNode` which grants the cosmetic. The
/// surrounding [CosmeticDetailsSheet] watches `CosmeticsProvider`, so
/// once the cosmetic lands in the unlocked set the parent rebuilds and
/// replaces this body with the standard companion details.
class _ClaimableCompanionBody extends StatelessWidget {
  const _ClaimableCompanionBody({
    required this.definition,
    required this.l10n,
    required this.color,
    required this.bottomPad,
  });

  final Cosmetic definition;
  final AppLocalizations l10n;
  final Color color;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final relicIds = companionRelicGateIds(definition.id);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius:
                        BorderRadius.circular(Tokens.radiusProgress),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.cosmeticCompanionClaimableBadge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Tokens.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cosmeticCompanionClaimableHiddenName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Tokens.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cosmeticCompanionClaimableHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Tokens.onSurfaceMuted,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              CompanionClaimReveal(
                companion: definition,
                relicIds: relicIds,
                color: color,
                onClaim: () => _runClaim(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Calls `progression.claimNode` for the matching
  /// `CompanionAvailability` (id == cosmetic id, see
  /// `companions_content.dart`). Logged so resets / sync flows can
  /// be correlated to the moment the player tapped Vyzvedni.
  Future<void> _runClaim(BuildContext context) async {
    final progression = context.read<ProgressionEngineProvider>();
    _log.info('claim companion', payload: 'id=${definition.id}');
    await progression.claimNode(nodeId: definition.id);
  }
}

/// Body shown for `hidden` or `partial` companions. Identity stays
/// concealed (silhouette + mystery name) per the four-state spec —
/// the player meets the actual companion only after they reach the
/// claim flow. The body still surfaces:
///
///   * a progress chip when [Companion.revealResult] carries
///     satisfied/total counters (i.e. `partial` only — `hidden`
///     returns no counters),
///   * the requirements checklist with live `met` flags so the
///     player can see what to work toward (or, in the rare
///     teaser-floor case, a generic placeholder when the checklist
///     is empty).
///
/// No action buttons are rendered here — the only way out of these
/// states is engine progress (granted gating-relic achievements),
/// which is observed automatically when the providers notify and
/// the parent sheet rebuilds.
class _LockedCompanionBody extends StatelessWidget {
  const _LockedCompanionBody({
    required this.definition,
    required this.teased,
    required this.l10n,
    required this.bottomPad,
  });

  /// The companion catalog row. Carries rarity / name / asset; the
  /// body intentionally renders the silhouette + mystery name in this
  /// state, so [definition] feeds rarity-coloured chrome only.
  final Cosmetic definition;

  /// The Teased payload (`satisfied / total / rows`) when the
  /// lifecycle is `CosmeticTeased`. Null when the lifecycle is
  /// `CosmeticHidden` — in which case no progress chip or checklist
  /// renders (the mystery body collapses to a single hint).
  final CosmeticTeased? teased;

  final AppLocalizations l10n;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final color = cosmeticRarityColor(definition.rarity);
    final hiddenColor = Tokens.onSurfaceMuted;
    final satisfied = teased?.hasProgress == true
        ? teased!.satisfiedConditions
        : null;
    final total =
        teased?.hasProgress == true ? teased!.totalConditions : null;
    final rows = teased?.conditionRows;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius:
                        BorderRadius.circular(Tokens.radiusProgress),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HiddenBadgeLarge(color: hiddenColor),
                  const SizedBox(width: Tokens.spaceLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cosmeticCompanionClaimableHiddenName,
                          style: const TextStyle(
                            color: Tokens.onSurfaceMuted,
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
                            _TinyPill(
                              label: l10n.journeyBadgeLocked,
                              color: hiddenColor.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                        if (satisfied != null && total != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.incomplete_circle_rounded,
                                size: 13,
                                color: color.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.cosmeticPartialProgress(satisfied, total),
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.8),
                                  fontSize: Tokens.fontSizeCaption,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (rows != null && rows.isNotEmpty) ...[
                const SizedBox(height: 18),
                _CompanionChecklist(
                  conditionRows: rows,
                  color: color,
                  l10n: l10n,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 13,
                    color: Tokens.onSurfaceFaint.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      l10n.cosmeticHiddenUnlockCondition,
                      style: TextStyle(
                        color: Tokens.onSurfaceFaint.withValues(alpha: 0.7),
                        fontSize: Tokens.fontSizeCaption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hiddenColor,
                    side: BorderSide(
                      color: hiddenColor.withValues(alpha: 0.34),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Tokens.radiusInner),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  child: Text(l10n.dialogClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
