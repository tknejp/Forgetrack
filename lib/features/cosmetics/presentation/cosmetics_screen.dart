import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../application/cosmetics_provider.dart';
import '../domain/cosmetic_models.dart';
import '../domain/cosmetic_reveal_state.dart';
import '../domain/cosmetic_unlock_rules.dart';
import '../domain/consumed_relics.dart';
import '../domain/inventory.dart';
import 'cosmetic_details_sheet.dart';
import 'widgets/cosmetics_screen_category_grid.dart';
import 'widgets/cosmetics_screen_chrome.dart';
import 'widgets/cosmetics_screen_equipped_section.dart';
import 'widgets/cosmetics_screen_segmented_tabs.dart';

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
                title: 'Inventář',
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
    if (state == null) return const CosmeticsScreenNotSignedIn();

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

    // The "Vybaveno" row shows the three slots that define how the
    // hero reads at a glance: skin (the body / identity), background
    // (the scene behind), companion (the buddy beside). Frame chrome
    // appears on every compact avatar surface already, so it's
    // omitted here to give skin the lead slot — the same skin asset
    // drives the profile + hero header full-body composition.
    // Emblems live on the profile-screen emblem grid; relics are
    // consumed by companion claims, not worn. The explicit order
    // (instead of relying on `CosmeticType.values`) pins skin to
    // first place regardless of future enum reshuffles.
    const equippedSlotOrder = <CosmeticType>[
      CosmeticType.skin,
      CosmeticType.companion,
      CosmeticType.background,
    ];
    final equippedById = {
      for (final def in cosmetics.service.getEquippedDefinitions(state))
        def.type: def,
    };
    final equippedDefs = <Cosmetic>[
      for (final type in equippedSlotOrder)
        if (equippedById[type] != null) equippedById[type]!,
    ];
    // Player-facing tab order: skin (identity) → companion (buddy)
    // → background (scene) → frame → emblem → relic → anything else
    // → "Vše". Skin sits first so the inventory opens on what the
    // player most often customises, mirroring the inventory section
    // order on the profile screen.
    //
    // `_kTabTypeOrder` keys this ranking; types missing from the
    // ranking (titleFlair, mapEffect, …) keep their natural enum
    // order at the tail. In normal mode types with zero displayable
    // items are dropped via `displayDefs.any`; devtools mode keeps
    // every type so empty categories are still inspectable.
    final orderedTypes = [...CosmeticType.values]
      ..sort((a, b) => _kTabTypeRank(a).compareTo(_kTabTypeRank(b)));
    final presentTypes = devTools
        ? orderedTypes
        : orderedTypes
            .where((type) => displayDefs.any((def) => def.type == type)) // lint-ignore: widget-no-logic — tab-presence filter over pre-built displayDefs
            .toList(growable: false);

    // Tab layout: per-type tabs first (skin leads), "Vše" pinned at
    // the end so the catch-all browse mode is one swipe away without
    // pushing the most-used tab off the screen edge.
    final tabs = <CosmeticType?>[...presentTypes, null];

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
          child: CosmeticsScreenEquippedSection(
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
          CosmeticsScreenSegmentedTabs(
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
              return CosmeticsScreenCategoryGrid(
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

/// Player-facing tab priority for the cosmetics inventory.
///
/// Lower rank = earlier in the strip. Types missing from the table
/// fall to a stable high rank (after the explicit list, before
/// "Vše") and keep their natural enum order within that band.
const Map<CosmeticType, int> _kTabPriority = <CosmeticType, int>{
  CosmeticType.skin: 0,
  CosmeticType.companion: 1,
  CosmeticType.background: 2,
  CosmeticType.frame: 3,
  CosmeticType.emblem: 4,
  CosmeticType.relic: 5,
};

int _kTabTypeRank(CosmeticType type) =>
    _kTabPriority[type] ?? (100 + type.index);
