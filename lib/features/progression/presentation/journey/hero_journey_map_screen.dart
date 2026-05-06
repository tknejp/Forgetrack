import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_back_button.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../application/progression_provider.dart';
import '../../domain/journey_models.dart';
import 'widgets/journey_adapter.dart';
import 'widgets/journey_event_feed.dart';
import 'widgets/journey_interactive_map.dart';

/// Dedicated detail screen for the Hero Journey, opened from
/// `JourneyPreviewCard` on the Hero/Profile screen.
///
/// Layout uses a [CustomScrollView] with a pinned [SliverPersistentHeader]
/// for the map: expanded the map is fully interactive (pan, tap, tooltip);
/// as the user scrolls into the milestone history below, the header
/// gracefully collapses into a static mini preview that stays visible. The
/// transition between interactive ↔ static avoids any gesture conflict
/// between [InteractiveViewer] and the surrounding scroll view.
///
/// The horizontal stat-pills row from the previous iteration has been
/// removed — Level / Title were duplicating the Hero progression header
/// and other counts didn't earn their vertical space. Map + feed only.
class HeroJourneyMapScreen extends StatefulWidget {
  const HeroJourneyMapScreen({super.key});

  @override
  State<HeroJourneyMapScreen> createState() => _HeroJourneyMapScreenState();
}

class _HeroJourneyMapScreenState extends State<HeroJourneyMapScreen> {
  /// `null` = no checkpoint selected. Tapping a node selects it; the
  /// tooltip's X clears it back to null. Selection is hidden automatically
  /// in the collapsed / static state.
  int? _selectedIndex;
  JourneyFeedFilter _selectedFeedFilter = JourneyFeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionProvider>();
    final checkpoints = JourneyAdapter.buildMilestoneMap(progression, l10n);
    final feed = JourneyAdapter.buildFeed(progression, l10n);
    final filteredFeedCount = feed
        .where((e) => journeyFeedMatchesFilter(_selectedFeedFilter, e))
        .length;

    final screenH = MediaQuery.of(context).size.height;
    final mapMaxHeight = (screenH * 0.62).clamp(500.0, 650.0);
    const mapMinHeight = 200.0;
    final collapseScrollReserve =
        filteredFeedCount < 6 ? mapMaxHeight - mapMinHeight : 0.0;

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
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                child: ScreenHeader(
                  greeting: '',
                  title: l10n.journeyTitle,
                  leading: const FtBackButton(),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: progression.refresh,
                color: Tokens.accent,
                backgroundColor: Tokens.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MapHeaderDelegate(
                        checkpoints: checkpoints,
                        feed: feed,
                        selectedIndex: _selectedIndex,
                        selectedFeedFilter: _selectedFeedFilter,
                        onSelected: (i) => setState(() => _selectedIndex = i),
                        onFeedFilterSelected: (filter) {
                          setState(() => _selectedFeedFilter = filter);
                        },
                        maxHeight: mapMaxHeight,
                        minHeight: mapMinHeight,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          JourneyEventFeed(
                            events: feed,
                            selectedFilter: _selectedFeedFilter,
                          ),
                          if (collapseScrollReserve > 0)
                            SizedBox(height: collapseScrollReserve),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver header delegate — interpolates between expanded interactive map and
// collapsed static mini preview.
// ─────────────────────────────────────────────────────────────────────────────

class _MapHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MapHeaderDelegate({
    required this.checkpoints,
    required this.feed,
    required this.selectedIndex,
    required this.selectedFeedFilter,
    required this.onSelected,
    required this.onFeedFilterSelected,
    required this.maxHeight,
    required this.minHeight,
  });

  final List<JourneyCheckpoint> checkpoints;
  final List<JourneyCheckpoint> feed;
  final int? selectedIndex;
  final JourneyFeedFilter selectedFeedFilter;
  final ValueChanged<int?> onSelected;
  final ValueChanged<JourneyFeedFilter> onFeedFilterSelected;
  final double maxHeight;
  final double minHeight;

  /// Threshold at which the header switches from interactive to static.
  /// Picked at 0.5 so the user has clear "hand-off" feedback as they scroll.
  static const double _staticThreshold = 0.5;
  static const double _controlsHeight = 88;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);
    final isCollapsed = progress >= _staticThreshold;
    final currentMapHeight =
        (maxHeight - shrinkOffset).clamp(minHeight, maxHeight);

    return Container(
      color: Tokens.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: SizedBox(
              height: currentMapHeight - 8,
              width: double.infinity,
              child: checkpoints.isEmpty
                  ? const _EmptyJourney()
                  : JourneyInteractiveMap(
                      checkpoints: checkpoints,
                      // Hide tooltip in collapsed state so the mini preview
                      // reads cleanly, regardless of what the user last tapped.
                      selectedIndex: isCollapsed ? null : selectedIndex,
                      onSelected: onSelected,
                      height: currentMapHeight - 8,
                      interactive: !isCollapsed,
                    ),
            ),
          ),
          const _DragHandle(),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _SectionLabel(label: context.l10n.journeyHistoryHeader),
          ),
          const SizedBox(height: Tokens.spaceSm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: JourneyFeedFilterPills(
              events: feed,
              selectedFilter: selectedFeedFilter,
              onSelected: onFeedFilterSelected,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight + _controlsHeight;

  @override
  double get minExtent => minHeight + _controlsHeight;

  @override
  bool shouldRebuild(covariant _MapHeaderDelegate old) {
    return checkpoints != old.checkpoints ||
        feed != old.feed ||
        selectedIndex != old.selectedIndex ||
        selectedFeedFilter != old.selectedFeedFilter ||
        maxHeight != old.maxHeight ||
        minHeight != old.minHeight;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label + empty state
// ─────────────────────────────────────────────────────────────────────────────

/// Small horizontal handle pill rendered between the map and the feed.
/// Purely decorative — its job is to make the boundary obvious so the user
/// can predict where to drag for "scroll the page" vs. "scroll the map".
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome_rounded, size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: Tokens.accent,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _EmptyJourney extends StatelessWidget {
  const _EmptyJourney();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.explore_outlined, color: Tokens.accent, size: 28),
          const SizedBox(height: 10),
          Text(
            l10n.journeyEmptyMapTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Text(
            l10n.journeyEmptyMapBody,
            style: TextStyle(
              fontSize: Tokens.fontSizeSmall,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
