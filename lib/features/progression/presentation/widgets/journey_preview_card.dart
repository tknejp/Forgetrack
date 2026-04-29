import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../application/progression_provider.dart';
import '../../domain/journey_models.dart';
import '../hero_journey_map_screen.dart';
import '../progression_l10n.dart';
import 'journey_adapter.dart';
import 'journey_shared.dart';

/// Compact teaser shown directly on the Hero/Profile screen.
///
/// - Mini horizontal path with 3–5 checkpoints (oldest left → newest right).
/// - Summary text: last milestone, current title, next goal.
/// - Whole card is tappable; opens `HeroJourneyMapScreen`.
///
/// Height stays around ~200 px so the Hero screen stays scrollable and the
/// preview reads as an entry-point, not the main content.
class JourneyPreviewCard extends StatelessWidget {
  const JourneyPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionProvider>();
    final progL10n = ProgressionL10n(l10n);
    final preview = JourneyAdapter.buildPreview(progression, progL10n, l10n);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HeroJourneyMapScreen()),
        ),
        splashColor: FtTokens.accent.withValues(alpha: 0.18),
        highlightColor: FtTokens.accent.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1838), Color(0xFF0F1226)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: FtTokens.accent.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: FtTokens.accent.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Header(),
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: _MiniMap(checkpoints: preview),
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                preview: preview,
                profileTitle: progL10n.levelTitle(progression.profile.level),
                profileLevel: progression.profile.level,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        const Icon(Icons.auto_awesome_rounded,
            size: 14, color: FtTokens.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.journeyPreviewKicker,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: FtTokens.accent,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: FtTokens.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: FtTokens.accent.withValues(alpha: 0.36),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.journeyOpenMap,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: FtTokens.accent.withValues(alpha: 0.95),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_rounded,
                  size: 12, color: FtTokens.accent),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal mini path. Newest (current) is rendered on the right;
/// oldest on the left, matching the design HTML's horizontal mini-map.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.checkpoints});
  final List<JourneyCheckpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) {
      return const _MiniMapEmpty();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Adapter returns newest first → reverse for left-to-right time flow.
        final ordered = checkpoints.reversed.toList(growable: false);
        final n = ordered.length;
        final positions = List<Offset>.generate(n, (i) {
          final t = n == 1 ? 0.5 : i / (n - 1);
          final x = 14 + t * (w - 28);
          final y = h * 0.5 + math.sin(i * 1.4) * h * 0.22;
          return Offset(x, y);
        });

        return Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: JourneyPathPainter(
                nodePositions: positions,
                pathColor: FtTokens.accent,
              ),
            ),
            for (int i = 0; i < n; i++)
              Positioned(
                left: positions[i].dx - _halfNode(ordered[i]),
                top: positions[i].dy - _halfNode(ordered[i]),
                child: IgnorePointer(
                  // Whole card already handles taps — nodes are decorative.
                  child: JourneyCheckpointNode(
                    checkpoint: ordered[i],
                    isSelected: false,
                    onTap: () {},
                    baseSize: _baseSize(ordered[i]),
                    compact: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static double _baseSize(JourneyCheckpoint cp) {
    if (cp.isCurrent) return 24;
    if (cp.isMajorMilestone) return 22;
    if (cp.type == JourneyEventType.achievement) return 18;
    return 16;
  }

  static double _halfNode(JourneyCheckpoint cp) {
    return (_baseSize(cp) + 14) / 2;
  }
}

class _MiniMapEmpty extends StatelessWidget {
  const _MiniMapEmpty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.journeyMiniMapEmpty,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.preview,
    required this.profileTitle,
    required this.profileLevel,
  });

  final List<JourneyCheckpoint> preview;
  final String profileTitle;
  final int profileLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final lastMilestone = preview.firstWhere(
      (c) => !c.isCurrent && c.isUnlocked,
      orElse: () => const JourneyCheckpoint(
        id: '_none',
        type: JourneyEventType.level,
        label: '—',
        isUnlocked: false,
      ),
    );
    final nextLocked = preview.firstWhere(
      (c) => !c.isUnlocked,
      orElse: () => const JourneyCheckpoint(
        id: '_none',
        type: JourneyEventType.level,
        label: '—',
        isUnlocked: false,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryItem(
            icon: Icons.history_rounded,
            label: l10n.journeyLastMilestone,
            value: lastMilestone.id == '_none' ? '—' : lastMilestone.label,
            color: FtTokens.active.color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            icon: Icons.workspace_premium_rounded,
            label: '${l10n.journeyTitleLabel} · L $profileLevel',
            value: profileTitle,
            color: FtTokens.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            icon: Icons.flag_outlined,
            label: l10n.journeyNextGoal,
            value: nextLocked.id == '_none' ? '—' : nextLocked.label,
            color: FtTokens.calories.color,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.85),
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}
