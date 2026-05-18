import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../application/companions_registry.dart';
import '../application/cosmetics_provider.dart';
import '../domain/companion_state.dart';
import '../domain/cosmetic_models.dart' hide Companion;
// Disambiguate: `Companion` is both the new sealed cosmetic subtype
// (cosmetic_models) and the legacy view-model bundle (companions_registry).
// The view-model wins the unprefixed name until Phase 11 deletes it; the
// sealed subtype is accessed via the `cm.` prefix for `is` checks.
import '../domain/cosmetic_models.dart' as cm show Companion;
import '../domain/cosmetic_reveal_state.dart';
import '../domain/cosmetic_unlock_rules.dart';
import '../domain/consumed_relics.dart';
import 'cosmetic_details_sheet.dart';
import 'cosmetics_screen_internals.dart';

class CosmeticsScreen extends StatefulWidget {
  const CosmeticsScreen({
    super.key,
    this.initialType,
    this.initialFocusId,
    this.devToolsMode = false,
  });

  final CosmeticType? initialType;

  /// Cosmetic id to land on. When set, the screen auto-jumps to the
  /// matching tab and pops the details sheet on first build. Used by
  /// the celebration "Vyzvedni společníka →" CTA so a companion-
  /// availability celebration goes straight to its claim sheet rather
  /// than dropping the player on a generic inventory grid.
  final String? initialFocusId;

  /// When true: shows every catalog item (locked + unlocked), asset-missing
  /// indicators, and passes unlock conditions to the details sheet.
  final bool devToolsMode;

  @override
  State<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends State<CosmeticsScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _didInitialJump = false;
  bool _didInitialFocus = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    // Watch progression so the grid + details sheet react when a
    // companion claim turns the cosmetic from claimable to unlocked.
    final progression = context.watch<ProgressionEngineProvider>();
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                MediaQuery.of(context).padding.top + 12,
                14,
                0,
              ),
              child: ScreenHeader(
                greeting: '',
                title: 'Kosmetika',
                leading: const FtBackButton(),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _buildBody(context, cosmetics, progression, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CosmeticsProvider cosmetics,
    ProgressionEngineProvider progression,
    AppLocalizations l10n,
  ) {
    if (cosmetics.isLoading && cosmetics.state == null) {
      return const Center(
        child: CircularProgressIndicator(color: Tokens.accent),
      );
    }

    final state = cosmetics.state;
    if (state == null) return const _NotSignedIn();

    final devTools = widget.devToolsMode;
    final consumedIds = consumedRelicIds(state);

    final List<Cosmetic> displayDefs;
    final Map<String, CosmeticRevealResult> revealResults;
    // Map of companion id → resolved [Companion] view object. Built
    // once per build from canonical sources (cosmetics state +
    // progression availability + reveal evaluator) by
    // [CompanionsRegistry] and threaded down to cards / details
    // sheet so every surface renders from the same snapshot.
    Map<String, Companion> companions = const {};

    if (devTools) {
      displayDefs = cosmetics.service.catalog.all.toList()
        ..sort(_byTypeThenSortOrder);
      revealResults = const {};
    } else {
      revealResults = cosmetics.computeRevealResults(kCosmeticUnlockRules);
      final list = const CompanionsRegistry().snapshot(
        unlockedCosmeticIds: state.unlocked.keys.toSet(),
        availableNodeIds: progression.availableNodeIds,
        revealResults: revealResults,
      );
      companions = {for (final c in list) c.id: c};
      // Display policy: unlocked items always show. Companions
      // additionally surface for `partial` and `claimable` states so
      // the player sees what's brewing and can claim it. `hidden`
      // companions stay off the grid — once the player meets the
      // first prerequisite the card materialises in `partial`.
      // Frames, relics, backgrounds and emblems stay out of the
      // inventory until owned — they're Tier-1 rewards where a
      // locked preview would just be clutter.
      displayDefs = cosmetics.service.catalog.enabled
          .where((def) {
            final r = revealResults[def.id];
            if (r == null) return false;
            if (r.state == CosmeticRevealState.unlocked) return true;
            if (def is cm.Companion) {
              final c = companions[def.id];
              return c != null && c.state != CompanionState.hidden;
            }
            return false;
          })
          .toList()
        ..sort((a, b) => _sortRevealDefs(a, b, state, revealResults));
    }

    final equippedDefs = cosmetics.service.getEquippedDefinitions(state);
    final presentTypes = devTools
        ? CosmeticType.values.toList()
        : CosmeticType.values
            .where((type) => displayDefs.any((def) => def.type == type))
            .toList(growable: false);

    // Tab layout: index 0 = "Vše" (null type, shows every displayDef),
    // followed by one tab per present type. PageView pages stay in lockstep
    // with the segmented selector via the shared PageController.
    final tabs = <CosmeticType?>[null, ...presentTypes];

    // One-shot initial jump from widget.initialType. We can't pass an initial
    // page to the controller in initState because `tabs` is derived from the
    // current cosmetics state, which isn't available until first build.
    if (!_didInitialJump && widget.initialType != null) {
      final idx = tabs.indexOf(widget.initialType);
      if (idx > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(idx);
            setState(() => _currentIndex = idx);
          }
        });
      }
      _didInitialJump = true;
    }

    // One-shot auto-open of the details sheet for `widget.initialFocusId`.
    // Triggered after the post-frame so the PageController has had a
    // chance to settle on the initial tab (or the focus-driven jump
    // below has landed). We resolve against displayDefs first so a
    // claimable companion that lives in `partial` reveal state still
    // counts as a valid focus target.
    if (!_didInitialFocus && widget.initialFocusId != null) {
      _didInitialFocus = true;
      final id = widget.initialFocusId!;
      final def = cosmetics.service.catalog.byId(id);
      if (def != null) {
        // If we know the cosmetic type, also jump to the matching tab
        // so when the player dismisses the sheet they land in context.
        final typeIdx = tabs.indexOf(def.type);
        if (typeIdx > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pageController.hasClients) return;
            _pageController.jumpToPage(typeIdx);
            setState(() => _currentIndex = typeIdx);
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showDetails(
            context,
            cosmetics: cosmetics,
            state: state,
            definition: def,
            l10n: l10n,
            devTools: devTools,
            revealResult: revealResults[def.id],
            companions: companions,
            consumedRelicIdSet: consumedIds,
          );
        });
      }
    }

    // Clamp _currentIndex in case the tab list shrank (e.g. last item in a
    // category was unequipped/removed).
    final activeIndex =
        _currentIndex >= tabs.length ? 0 : _currentIndex;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: _EquippedSection(
            definitions: equippedDefs,
            state: state,
            l10n: l10n,
            onTap: (definition) => _showDetails(
              context,
              cosmetics: cosmetics,
              state: state,
              definition: definition,
              l10n: l10n,
              devTools: devTools,
              revealResult: revealResults[definition.id],
              companions: companions,
              consumedRelicIdSet: consumedIds,
            ),
          ),
        ),
        if (tabs.length > 1)
          _SegmentedTabs(
            tabs: tabs,
            currentIndex: activeIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: tabs.length,
            itemBuilder: (context, pageIndex) {
              final type = tabs[pageIndex];
              final pageDefs = type == null
                  ? displayDefs
                  : displayDefs
                      .where((def) => def.type == type)
                      .toList(growable: false);
              return _CategoryGrid(
                defs: pageDefs,
                cosmetics: cosmetics,
                state: state,
                revealResults: revealResults,
                devTools: devTools,
                l10n: l10n,
                companions: companions,
                consumedRelicIds: consumedIds,
                onTap: (definition) => _showDetails(
                  context,
                  cosmetics: cosmetics,
                  state: state,
                  definition: definition,
                  l10n: l10n,
                  devTools: devTools,
                  revealResult: revealResults[definition.id],
                  companions: companions,
                  consumedRelicIdSet: consumedIds,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetails(
    BuildContext context, {
    required CosmeticsProvider cosmetics,
    required UserCosmeticsState state,
    required Cosmetic definition,
    required AppLocalizations l10n,
    bool devTools = false,
    CosmeticRevealResult? revealResult,
    Map<String, Companion> companions = const {},
    Set<String> consumedRelicIdSet = const {},
  }) {
    final isLocked = !state.unlocked.containsKey(definition.id);
    final rules = devTools
        ? kCosmeticUnlockRules
            .where((r) => r.cosmeticId == definition.id)
            .toList()
        : null;
    // For companion cosmetics we hand the entire [Companion] view
    // object to the sheet — state, reveal-result rows and the
    // availability node travel together so the sheet has no need to
    // do its own engine introspection.
    final companion = !devTools && definition is cm.Companion
        ? companions[definition.id]
        : null;
    final isRelicConsumed = !devTools &&
        definition is RelicCosmetic &&
        consumedRelicIdSet.contains(definition.id);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CosmeticDetailsSheet(
        definition: definition,
        state: state,
        l10n: l10n,
        isLocked: devTools && isLocked,
        devToolsUnlockRules: rules,
        devToolsMode: devTools,
        revealResult: devTools ? null : revealResult,
        companion: companion,
        isRelicConsumed: isRelicConsumed,
      ),
    );
  }
}

class _EquippedSection extends StatelessWidget {
  const _EquippedSection({
    required this.definitions,
    required this.state,
    required this.l10n,
    required this.onTap,
  });

  final List<Cosmetic> definitions;
  final UserCosmeticsState state;
  final AppLocalizations l10n;
  final ValueChanged<Cosmetic> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHead(
          label: 'Vybaveno',
          caption: 'Aktuální vzhled profilu a cesty',
        ),
        const SizedBox(height: 10),
        if (definitions.isEmpty)
          const _EmptyLine(
            title: 'Zatím nic není vybavené.',
            caption: 'Klepni na odemčenou kosmetiku níže a vyber Vybavit.',
          )
        else
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final definition = definitions[index];
                return SizedBox(
                  width: 116,
                  child: _CosmeticCard(
                    definition: definition,
                    isEquipped: true,
                    l10n: l10n,
                    onTap: () => onTap(definition),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: definitions.length,
            ),
          ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  /// Index 0 is always the "Vše" tab (null type). Remaining entries are the
  /// types currently present in the inventory, in catalog order.
  final List<CosmeticType?> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHead(label: 'Inventář'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(Tokens.radiusProgress),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _SegmentButton(
                      label: tabs[i] == null
                          ? 'Vše'
                          : cosmeticTypeLabel(tabs[i]!),
                      icon: tabs[i] == null
                          ? Icons.apps_rounded
                          : cosmeticIconForType(tabs[i]!),
                      isSelected: currentIndex == i,
                      onTap: () => onTap(i),
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

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Tokens.accent : Tokens.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusProgress - 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Tokens.accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Tokens.radiusProgress - 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: Tokens.fontSizeTiny,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.defs,
    required this.cosmetics,
    required this.state,
    required this.revealResults,
    required this.devTools,
    required this.l10n,
    required this.onTap,
    this.companions = const {},
    this.consumedRelicIds = const {},
  });

  final List<Cosmetic> defs;
  final CosmeticsProvider cosmetics;
  final UserCosmeticsState state;
  final Map<String, CosmeticRevealResult> revealResults;
  final bool devTools;
  final AppLocalizations l10n;
  final ValueChanged<Cosmetic> onTap;
  final Map<String, Companion> companions;
  final Set<String> consumedRelicIds;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: cosmetics.refresh,
      color: Tokens.accent,
      backgroundColor: Tokens.surface,
      child: defs.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 30, 14, 36),
                  child: _EmptyInventory(),
                ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemCount: defs.length,
              itemBuilder: (context, index) {
                final def = defs[index];
                final isUnlocked = state.unlocked.containsKey(def.id);
                final revealResult = revealResults[def.id];
                final companion = !devTools && def is cm.Companion
                    ? companions[def.id]
                    : null;
                final isRelicConsumed = !devTools &&
                    def is RelicCosmetic &&
                    consumedRelicIds.contains(def.id);
                return _CosmeticCard(
                  definition: def,
                  isEquipped: state.equipped.slotId(def.type) == def.id,
                  isLocked: devTools && !isUnlocked,
                  showMissingAsset: devTools,
                  revealResult: devTools ? null : revealResult,
                  l10n: l10n,
                  companion: companion,
                  isRelicConsumed: isRelicConsumed,
                  onTap: () => onTap(def),
                );
              },
            ),
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({
    required this.definition,
    required this.isEquipped,
    required this.l10n,
    required this.onTap,
    this.isLocked = false,
    this.showMissingAsset = false,
    this.revealResult,
    this.companion,
    this.isRelicConsumed = false,
  });

  final Cosmetic definition;
  final bool isEquipped;
  // devTools-only: shows lock icon + dim
  final bool isLocked;
  final bool showMissingAsset;
  /// Non-null in normal (non-devTools) mode; null in devTools mode.
  final CosmeticRevealResult? revealResult;
  /// Resolved [Companion] view when [definition.type] == companion
  /// and the card is rendered outside devTools mode. Null for every
  /// other cosmetic type (frames / relics / backgrounds / emblems …)
  /// and inside devTools mode — those paths fall back to the
  /// reveal-evaluator output.
  final Companion? companion;
  /// True for a relic that has been "consumed" by a companion claim —
  /// stays in inventory but dim + "Použito" pill.
  final bool isRelicConsumed;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final revealState = revealResult?.state;
    // Companion cards branch on the strict four-state lifecycle —
    // identity (asset + name) stays hidden for every non-`claimed`
    // state. The reveal evaluator's `partial` / `visibleLocked`
    // signals only feed the badge (progress chip vs READY pill);
    // they no longer leak the companion's artwork.
    final cState = companion?.state;
    final isCompanionLocked = cState != null && !cState.isClaimed;
    final isHiddenCard = isCompanionLocked ||
        (cState == null && revealState == CosmeticRevealState.hidden);
    final isPartialCard = cState == CompanionState.partial ||
        (cState == null &&
            revealState == CosmeticRevealState.partial);
    final isClaimableCompanion = cState == CompanionState.claimable;
    final isVisibleLocked = revealState == CosmeticRevealState.visibleLocked;
    final isNormalLocked = isLocked || isVisibleLocked;

    final color = isHiddenCard
        ? Tokens.onSurfaceFaint
        : cosmeticRarityColor(definition.rarity);

    final assetPath = isHiddenCard
        ? null
        : context
            .read<CosmeticsProvider>()
            .service
            .config
            .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
    final hasAsset = definition.assetKey != null;

    final displayName = isCompanionLocked
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: cardOpacity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.13),
                color.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            border: Border.all(color: color.withValues(alpha: 0.27)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isHiddenCard)
                        _HiddenBadge(
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
              // devTools lock icon
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
              // normal-mode lock icon for visibleLocked + partial
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
              // partial progress chip — only when there's a real
              // partial reveal result attached. For companions, the
              // chip surfaces in `partial` state with the snapshot
              // numbers from the evaluator, then yields to the READY
              // pill once the engine flips the companion availability
              // node into `claimable`.
              if (isPartialCard &&
                  !isClaimableCompanion &&
                  revealResult != null)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: _ProgressChip(
                    satisfied: revealResult!.satisfiedConditions,
                    total: revealResult!.totalConditions,
                    color: color,
                  ),
                ),
              // claimable companion: pulsing READY pill — replaces the
              // partial progress chip so the player understands this
              // card is actionable, not still in progress.
              if (isClaimableCompanion)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: _ReadyPill(
                    label: l10n.cosmeticCompanionClaimableBadge,
                  ),
                ),
              // consumed relic: "Použito" pill in the bottom-right
              // corner so the player can see at a glance which relics
              // have already fed a companion claim.
              if (isRelicConsumed)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: _ConsumedPill(label: l10n.cosmeticRelicConsumedBadge),
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
          ),
        ),
      ),
    );
  }
}

/// Lock-icon placeholder badge used for hidden (???) cosmetics.
class _HiddenBadge extends StatelessWidget {
  const _HiddenBadge({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          size: size * 0.5,
          color: color.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

/// Small "{satisfied}/{total}" chip overlaid on partial cards.
class _ProgressChip extends StatelessWidget {
  const _ProgressChip({
    required this.satisfied,
    required this.total,
    required this.color,
  });

  final int satisfied;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$satisfied/$total',
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Pulsing "PŘIPRAVEN" pill for a claimable companion card. Uses the
/// brand accent so it pops against the muted hidden-state palette.
class _ReadyPill extends StatefulWidget {
  const _ReadyPill({required this.label});

  final String label;

  @override
  State<_ReadyPill> createState() => _ReadyPillState();
}

class _ReadyPillState extends State<_ReadyPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Tokens.accent.withValues(alpha: 0.18 + 0.18 * t),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Tokens.accent.withValues(alpha: 0.5 + 0.3 * t),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: Tokens.accent,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: Tokens.accent.withValues(alpha: 0.4 * t),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConsumedPill extends StatelessWidget {
  const _ConsumedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Tokens.onSurfaceMuted,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.label, this.caption});

  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Tokens.accent,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: const TextStyle(
                    color: Tokens.onSurfaceFaint,
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 6),
      child: _EmptyLine(
        title: 'Zatím žádná odemčená kosmetika.',
        caption: 'Nové kousky se objeví po splnění úspěchů a milníků.',
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Tokens.onSurface,
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              color: Tokens.onSurfaceMuted,
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotSignedIn extends StatelessWidget {
  const _NotSignedIn();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: _EmptyLine(
          title: 'Inventář není dostupný.',
          caption: 'Přihlas se pro přístup ke kosmetice.',
        ),
      ),
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
      return 48;
  }
}

int _byTypeThenSortOrder(Cosmetic a, Cosmetic b) {
  final typeRank = CosmeticType.values.indexOf(a.type)
      .compareTo(CosmeticType.values.indexOf(b.type));
  if (typeRank != 0) return typeRank;
  return a.sortOrder.compareTo(b.sortOrder);
}

/// Sort order for normal (non-devTools) mode:
/// 1. Unlocked items (existing sort: rarity desc → unlockedAt desc → sortOrder)
/// 2. Partial items (by sortOrder — discovered rewards the player is progressing toward)
/// 3. VisibleLocked items (by sortOrder)
int _sortRevealDefs(
  Cosmetic a,
  Cosmetic b,
  UserCosmeticsState state,
  Map<String, CosmeticRevealResult> revealResults,
) {
  final stateA = revealResults[a.id]?.state ?? CosmeticRevealState.visibleLocked;
  final stateB = revealResults[b.id]?.state ?? CosmeticRevealState.visibleLocked;

  final rankA = _revealSortRank(stateA);
  final rankB = _revealSortRank(stateB);
  if (rankA != rankB) return rankA.compareTo(rankB);

  if (stateA == CosmeticRevealState.unlocked) {
    return _compareUnlockedCosmetics(a, b, state);
  }
  return a.sortOrder.compareTo(b.sortOrder);
}

int _revealSortRank(CosmeticRevealState state) {
  switch (state) {
    case CosmeticRevealState.unlocked:
      return 0;
    case CosmeticRevealState.partial:
      return 1;
    case CosmeticRevealState.visibleLocked:
      return 2;
    case CosmeticRevealState.hidden:
      return 3;
  }
}

int _compareUnlockedCosmetics(
  Cosmetic a,
  Cosmetic b,
  UserCosmeticsState state,
) {
  final rarity = b.rarity.index.compareTo(a.rarity.index);
  if (rarity != 0) return rarity;
  final unlockedAtA = state.unlocked[a.id]?.unlockedAt;
  final unlockedAtB = state.unlocked[b.id]?.unlockedAt;
  if (unlockedAtA != null && unlockedAtB != null) {
    final unlockedAt = unlockedAtB.compareTo(unlockedAtA);
    if (unlockedAt != 0) return unlockedAt;
  }
  final sortOrder = a.sortOrder.compareTo(b.sortOrder);
  if (sortOrder != 0) return sortOrder;
  return a.id.compareTo(b.id);
}

