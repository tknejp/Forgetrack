import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../application/cosmetics_provider.dart';
import '../../domain/cosmetic_models.dart';
import '../../domain/cosmetic_reveal_state.dart';
import '../../domain/cosmetic_unlock_rules.dart';
import '../../domain/consumed_relics.dart';
import '../../domain/inventory.dart';
import '../cosmetic_details_sheet.dart';
import 'cosmetics_screen_category_grid.dart';
import 'cosmetics_screen_chrome.dart';
import 'cosmetics_screen_segmented_tabs.dart';

/// Body of the cosmetics inventory: equipped row, per-type segmented
/// tabs, and the paginated category grid. Used by the "Inventář" tab
/// on the own-profile `SocialUserProfileScreen` and by the DevTools
/// catalog browser (which sets `devToolsMode: true`).
class CosmeticsInventoryView extends StatefulWidget {
  const CosmeticsInventoryView({
    super.key,
    this.initialFocusId,
    this.devToolsMode = false,
    this.onLeftEdgeOverscroll,
  });

  final String? initialFocusId;
  final bool devToolsMode;

  /// Fired once per drag-gesture when the user keeps dragging right
  /// at the leftmost category page (i.e. tries to overscroll past the
  /// first inner tab). Hosts that wrap this view in a parent
  /// horizontal pager — e.g. the own-profile `TabBarView` —
  /// hand off to their previous tab here, so the player can
  /// "swipe through the inventory back to Statistiky" in one
  /// continuous motion. Null when the view is used as a standalone
  /// route (push) where there's no outer pager to hand off to.
  final VoidCallback? onLeftEdgeOverscroll;

  @override
  State<CosmeticsInventoryView> createState() => _CosmeticsInventoryViewState();
}

class _CosmeticsInventoryViewState extends State<CosmeticsInventoryView> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _didInitialFocus = false;
  // Overscroll handoff bookkeeping: accumulate pixels of overscroll
  // at the leftmost category page during the current drag, fire
  // `onLeftEdgeOverscroll` once when the accumulator crosses
  // `_kHandoffThreshold`, then suppress further fires until the
  // user lifts and starts a new drag.
  double _overscrollAccumulator = 0;
  bool _handoffFired = false;
  static const double _kHandoffThreshold = 24;

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

    if (cosmetics.isLoading && cosmetics.state == null) {
      return const Center(
        child: CircularProgressIndicator(color: Tokens.accent),
      );
    }

    final state = cosmetics.state;
    if (state == null) return const CosmeticsScreenNotSignedIn();

    final devTools = widget.devToolsMode;
    final consumedIds = consumedRelicIds(state);

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

    final orderedTypes = [...CosmeticType.values]
      ..sort((a, b) => _kTabTypeRank(a).compareTo(_kTabTypeRank(b)));
    final presentTypes = devTools
        ? orderedTypes
        : orderedTypes
            .where((type) => // lint-ignore: widget-no-logic — tab-presence filter over pre-built displayDefs
                displayDefs.any((def) => def.type == type))
            .toList(growable: false);

    final tabs = <CosmeticType?>[...presentTypes, null];

    if (!_didInitialFocus && widget.initialFocusId != null) {
      _didInitialFocus = true;
      final id = widget.initialFocusId!;
      final def = cosmetics.service.catalog.byId(id);
      if (def != null) {
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

    final activeIndex =
        _currentIndex >= tabs.length ? 0 : _currentIndex;

    return Column(
      children: [
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
          child: NotificationListener<ScrollNotification>(
            // Edge handoff for the outer TabBarView. Drag-to-switch on
            // the inner category PageView stays enabled (default
            // PageScrollPhysics) so the player can swipe between
            // categories. Once they reach the leftmost page and keep
            // dragging right, the engine fires `OverscrollNotification`
            // because the position is clamped at `minScrollExtent`;
            // we accumulate the overscroll pixels there and call
            // `onLeftEdgeOverscroll` after a small threshold, letting
            // the host (own-profile `TabBarView`) hand off to its
            // previous tab in the same continuous gesture.
            onNotification: (n) {
              if (n is ScrollStartNotification) {
                _overscrollAccumulator = 0;
                _handoffFired = false;
              } else if (n is OverscrollNotification &&
                  !_handoffFired &&
                  widget.onLeftEdgeOverscroll != null) {
                final atLeftEdge =
                    n.metrics.pixels <= n.metrics.minScrollExtent + 0.5;
                if (atLeftEdge) {
                  _overscrollAccumulator += n.overscroll.abs();
                  if (_overscrollAccumulator >= _kHandoffThreshold) {
                    _handoffFired = true;
                    widget.onLeftEdgeOverscroll!();
                  }
                }
              } else if (n is ScrollEndNotification) {
                _overscrollAccumulator = 0;
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: tabs.length,
              itemBuilder: (context, pageIndex) {
              final type = tabs[pageIndex];
              final pageDefs = type == null
                  ? [...displayDefs]
                  : displayDefs
                      .where((def) => def.type == type) // lint-ignore: widget-no-logic — page-by-tab slice of pre-built displayDefs
                      .toList();
              // Pin equipped items to the front of each tab. The
              // dedicated "Vybaveno" row is gone (replaced by the
              // tabbed profile layout), so the player needs to see
              // their currently worn cosmetic at the top of the grid
              // — both for context and so re-equipping is a one-tap
              // gesture without scrolling. Stable sort: equipped
              // items keep their relative order, everything else
              // keeps the order CosmeticsProvider produced.
              pageDefs.sort((a, b) {
                final aEq = state.equipped.slotId(a.type) == a.id ? 0 : 1;
                final bEq = state.equipped.slotId(b.type) == b.id ? 0 : 1;
                return aEq.compareTo(bEq);
              });
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
