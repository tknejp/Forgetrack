import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_lifecycle_helpers.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_state.dart';
import '../domain/cosmetic_unlock_rules.dart';
import '../domain/consumed_relics.dart';
import '../domain/inventory.dart';
import '../domain/player_cosmetic_lifecycle.dart';
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

    // Phase 19 of the domain refactor moved the lifecycle-aware
    // display filter + sort off this widget and onto
    // `CosmeticsProvider.displayCosmeticsForGrid`. The widget reads
    // the projection + the inventory it derived from; cards
    // pattern-match on lifecycle for per-card rendering only.
    final Map<String, CosmeticRevealResult> revealResults;
    final Inventory inventory;
    final List<Cosmetic> displayDefs;
    if (devTools) {
      revealResults = const {};
      inventory = Inventory.empty;
    } else {
      revealResults = cosmetics.computeRevealResults(kCosmeticUnlockRules);
      inventory = cosmetics.buildInventory(
        claimableNodeIds: progression.availableNodeIds,
      );
    }
    displayDefs = cosmetics.displayCosmeticsForGrid(
      claimableNodeIds: progression.availableNodeIds,
      devTools: devTools,
      inventory: inventory,
    );

    final equippedDefs = cosmetics.service.getEquippedDefinitions(state);
    final presentTypes = devTools
        ? CosmeticType.values.toList()
        : CosmeticType.values
            .where((type) => displayDefs.any((def) => def.type == type)) // lint-ignore: widget-no-logic — tab-presence filter over pre-built displayDefs
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
                      .where((def) => def.type == type) // lint-ignore: widget-no-logic — page-by-tab slice of pre-built displayDefs
                      .toList(growable: false);
              return _CategoryGrid(
                defs: pageDefs,
                cosmetics: cosmetics,
                state: state,
                inventory: inventory,
                devTools: devTools,
                l10n: l10n,
                consumedRelicIds: consumedIds,
                onTap: (definition) => _showDetails(
                  context,
                  cosmetics: cosmetics,
                  state: state,
                  definition: definition,
                  l10n: l10n,
                  devTools: devTools,
                  revealResult: revealResults[definition.id],
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
    Set<String> consumedRelicIdSet = const {},
  }) {
    final isLocked = !state.unlocked.containsKey(definition.id);
    final rules = devTools
        ? kCosmeticUnlockRules
            .where((r) => r.cosmeticId == definition.id) // lint-ignore: widget-no-logic — devtools-only matrix view, static catalog rules
            .toList()
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
    required this.inventory,
    required this.devTools,
    required this.l10n,
    required this.onTap,
    this.consumedRelicIds = const {},
  });

  final List<Cosmetic> defs;
  final CosmeticsProvider cosmetics;
  final UserCosmeticsState state;
  /// Phase 10 read projection. Cards pattern-match on lifecycle
  /// instead of reading `CosmeticRevealState` directly.
  final Inventory inventory;
  final bool devTools;
  final AppLocalizations l10n;
  final ValueChanged<Cosmetic> onTap;
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
                final lifecycle =
                    devTools ? null : inventory.byIdString(def.id)?.lifecycle;
                final isRelicConsumed = !devTools &&
                    def is RelicCosmetic &&
                    consumedRelicIds.contains(def.id);
                return _CosmeticCard(
                  definition: def,
                  isEquipped: state.equipped.slotId(def.type) == def.id,
                  isLocked: devTools && !isUnlocked,
                  showMissingAsset: devTools,
                  lifecycle: lifecycle,
                  l10n: l10n,
                  isRelicConsumed: isRelicConsumed,
                  onTap: () => onTap(def),
                );
              },
            ),
    );
  }
}

class _CosmeticCard extends StatefulWidget {
  const _CosmeticCard({
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
  // devTools-only: shows lock icon + dim
  final bool isLocked;
  final bool showMissingAsset;
  /// Phase 10 player-side state. Non-null in normal mode; null in
  /// devTools mode (devTools renders every catalog row regardless of
  /// player state).
  final PlayerCosmeticLifecycle? lifecycle;
  /// True for a relic that has been "consumed" by a companion claim —
  /// stays in inventory but dim + "Použito" pill.
  final bool isRelicConsumed;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  State<_CosmeticCard> createState() => _CosmeticCardState();
}

class _CosmeticCardState extends State<_CosmeticCard>
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
  void didUpdateWidget(covariant _CosmeticCard oldWidget) {
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
    // Phase 11: the card branches purely on (definition, lifecycle).
    // For Companion catalog rows, [hidesIdentity] gates the silhouette
    // + mystery name presentation; non-companion locked rows show
    // their real identity in every state except CosmeticHidden.
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

    final assetPath = isHiddenCard
        ? null
        : context
            .read<CosmeticsProvider>()
            .service
            .config
            .resolveAssetPath(definition.previewAssetKey ?? definition.assetKey);
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
      // card stands out across a 20-card grid. `pulse` is in [0, 1]
      // and is driven by `_pulseCtrl` (1400 ms reverse-repeat) when
      // `_isClaimableCompanion`; it stays 0 for every other lifecycle
      // state so the static cards keep their identical decoration
      // (no idle animation cost, no flicker on rebuild).
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
              // partial progress chip — only when the lifecycle
              // carries real progress numbers (`CosmeticTeased` with
              // `hasProgress`). For companions, the chip surfaces in
              // the partial state with snapshot numbers from the
              // evaluator, then yields to the READY pill once the
              // engine flips the companion availability node into
              // `claimable`.
              if (isPartialCard && !isClaimableCompanion && teased != null)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: _ProgressChip(
                    satisfied: teased.satisfiedConditions,
                    total: teased.totalConditions,
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

// Phase 19 of the domain refactor moved the grid filter + sort
// helpers (`_byTypeThenSortOrder`, `_sortByLifecycle`,
// `_lifecycleSortRank`, `_compareUnlockedCosmetics`) onto
// `CosmeticsProvider.displayCosmeticsForGrid`. Widget no longer
// composes domain logic.

