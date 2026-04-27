import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../application/progression_provider.dart';
import '../domain/journey_models.dart';
import '../domain/progression_models.dart';
import 'progression_l10n.dart';
import 'widgets/journey_adapter.dart';
import 'widgets/journey_event_feed.dart';
import 'widgets/journey_interactive_map.dart';
import 'widgets/journey_shared.dart';

/// Dedicated detail screen for the Hero Journey, reached by tapping the
/// `JourneyPreviewCard` on the Hero/Profile screen.
///
/// Layout is map-dominant:
///   - AppBar (back + title)
///   - Big interactive [JourneyInteractiveMap] — fixed to ~62 % of viewport
///     height (clamped 500–650 px). Has its own gesture context so pan
///     doesn't fight with the feed scroll.
///   - Compact horizontal stat chips (no large stat grid).
///   - Filterable [JourneyEventFeed] below.
class HeroJourneyMapScreen extends StatefulWidget {
  const HeroJourneyMapScreen({super.key});

  @override
  State<HeroJourneyMapScreen> createState() => _HeroJourneyMapScreenState();
}

class _HeroJourneyMapScreenState extends State<HeroJourneyMapScreen> {
  /// `null` = no checkpoint selected. The screen opens with no overlay so
  /// the user sees the bare map; tapping a node selects it, the tooltip's
  /// X clears it.
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionProvider>();
    final progL10n = ProgressionL10n(context.l10n);
    final checkpoints = JourneyAdapter.buildFull(progression, progL10n);
    final feed = JourneyAdapter.buildFeed(progression, progL10n);

    final screenH = MediaQuery.of(context).size.height;
    final mapHeight = (screenH * 0.62).clamp(500.0, 650.0);

    return Scaffold(
      backgroundColor: FtTokens.bg,
      appBar: AppBar(
        backgroundColor: FtTokens.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: FtTokens.onSurface),
        title: const Text(
          'Cesta hrdiny',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: FtTokens.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Map area: fixed height, owns its gestures ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: SizedBox(
                height: mapHeight,
                width: double.infinity,
                child: checkpoints.isEmpty
                    ? const _EmptyJourney()
                    : JourneyInteractiveMap(
                        checkpoints: checkpoints,
                        selectedIndex: _selectedIndex,
                        onSelected: (i) =>
                            setState(() => _selectedIndex = i),
                        height: mapHeight,
                      ),
              ),
            ),

            // ── Below-the-map content scrolls independently ──────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: progression.refresh,
                color: FtTokens.accent,
                backgroundColor: FtTokens.surface,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                  children: [
                    _CompactStatChips(
                      provider: progression,
                      checkpoints: checkpoints,
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel(label: 'Historie milníků'),
                    const SizedBox(height: 8),
                    JourneyEventFeed(events: feed),
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
// Compact horizontal stat chips — replaces the previous large stat grid.
// Lives directly below the map. Horizontal-scroll on small screens.
// ─────────────────────────────────────────────────────────────────────────────

class _CompactStatChips extends StatelessWidget {
  const _CompactStatChips({
    required this.provider,
    required this.checkpoints,
  });

  final ProgressionProvider provider;
  final List<JourneyCheckpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    final achCount = provider.achievements.where((a) => a.unlocked).length;
    final questCount = provider.completedQuests.length;
    final streakCount = ProgressionDomain.values
        .where((d) => provider.streakForDomain(d).bestStreak >= 7)
        .length;
    final nextLocked = checkpoints.firstWhere(
      (c) => !c.isUnlocked,
      orElse: () => const JourneyCheckpoint(
        id: '_none',
        type: JourneyEventType.level,
        label: '',
        isUnlocked: false,
      ),
    );

    final chips = <Widget>[
      _StatChip(
        type: JourneyEventType.achievement,
        value: '$achCount',
        label: achCount == 1 ? 'úspěch' : 'úspěchů',
      ),
      _StatChip(
        type: JourneyEventType.quest,
        value: '$questCount',
        label: questCount == 1 ? 'quest' : 'questů',
      ),
      _StatChip(
        type: JourneyEventType.streak,
        value: '$streakCount',
        label: streakCount == 1 ? 'série' : 'sérií',
      ),
      if (nextLocked.id != '_none')
        _StatChip(
          type: JourneyEventType.level,
          value: 'Další',
          label: nextLocked.label,
        ),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.type,
    required this.value,
    required this.label,
  });

  final JourneyEventType type;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = journeyColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(journeyIcon(type), size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label + empty state
// ─────────────────────────────────────────────────────────────────────────────

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
          const Text(
            'Tvá cesta právě začíná',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Splň první quest, odemkni úspěch nebo zaznamenej aktivitu — '
            'milníky se začnou objevovat na mapě.',
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
