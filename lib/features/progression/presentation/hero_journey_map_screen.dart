import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../application/progression_provider.dart';
import '../domain/journey_models.dart';
import 'progression_l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionProvider>();
    final progL10n = ProgressionL10n(l10n);
    final checkpoints =
        JourneyAdapter.buildMilestoneMap(progression, progL10n, l10n);
    final feed = JourneyAdapter.buildFeed(progression, progL10n, l10n);

    final screenH = MediaQuery.of(context).size.height;
    final mapMaxHeight = (screenH * 0.62).clamp(500.0, 650.0);
    const mapMinHeight = 200.0;

    return Scaffold(
      backgroundColor: FtTokens.bg,
      appBar: AppBar(
        backgroundColor: FtTokens.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: FtTokens.onSurface),
        title: Text(
          l10n.journeyTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: FtTokens.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: progression.refresh,
          color: FtTokens.accent,
          backgroundColor: FtTokens.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _MapHeaderDelegate(
                  checkpoints: checkpoints,
                  selectedIndex: _selectedIndex,
                  onSelected: (i) => setState(() => _selectedIndex = i),
                  maxHeight: mapMaxHeight,
                  minHeight: mapMinHeight,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Drag affordance — a small handle pill that visually
                    // separates the map from the milestone history. Drags
                    // landing here belong to the parent CustomScrollView, so
                    // they collapse the map / scroll the feed (vs. drags on
                    // the map area, which scroll the map's own canvas).
                    const _DragHandle(),
                    const SizedBox(height: 6),
                    _SectionLabel(label: l10n.journeyHistoryHeader),
                    const SizedBox(height: 8),
                    JourneyEventFeed(events: feed),
                  ]),
                ),
              ),
            ],
          ),
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
    required this.selectedIndex,
    required this.onSelected,
    required this.maxHeight,
    required this.minHeight,
  });

  final List<JourneyCheckpoint> checkpoints;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;
  final double maxHeight;
  final double minHeight;

  /// Threshold at which the header switches from interactive to static.
  /// Picked at 0.5 so the user has clear "hand-off" feedback as they scroll.
  static const double _staticThreshold = 0.5;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);
    final isCollapsed = progress >= _staticThreshold;
    final currentHeight =
        (maxHeight - shrinkOffset).clamp(minHeight, maxHeight);

    return Container(
      color: FtTokens.bg,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: SizedBox(
        height: currentHeight - 8,
        width: double.infinity,
        child: checkpoints.isEmpty
            ? const _EmptyJourney()
            : JourneyInteractiveMap(
                checkpoints: checkpoints,
                // Hide tooltip in collapsed state so the mini preview reads
                // cleanly, regardless of what the user last tapped.
                selectedIndex: isCollapsed ? null : selectedIndex,
                onSelected: onSelected,
                height: currentHeight - 8,
                interactive: !isCollapsed,
              ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _MapHeaderDelegate old) {
    return checkpoints != old.checkpoints ||
        selectedIndex != old.selectedIndex ||
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
          borderRadius: BorderRadius.circular(99),
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
        const Icon(Icons.auto_awesome_rounded,
            size: 14, color: FtTokens.accent),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: FtTokens.accent,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.explore_outlined, color: FtTokens.accent, size: 28),
          const SizedBox(height: 10),
          Text(
            l10n.journeyEmptyMapTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.journeyEmptyMapBody,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
