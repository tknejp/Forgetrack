import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_shared.dart';

/// Filterable feed of milestone events shown under the big map on
/// `HeroJourneyMapScreen`. The adapter delivers events newest-first; this
/// widget only owns the filter UI.
class JourneyEventFeed extends StatefulWidget {
  const JourneyEventFeed({super.key, required this.events});

  /// Pre-sorted (date desc, undated last) milestone events from
  /// `JourneyAdapter.buildFeed`.
  final List<JourneyCheckpoint> events;

  @override
  State<JourneyEventFeed> createState() => _JourneyEventFeedState();
}

/// Logical filter buckets exposed in the chip row. The "Levely" bucket
/// covers BOTH minor `level` and major `titleMilestone` event types — both
/// are level/title breakpoints from the same progression system, so a
/// separate "Tituly" filter would just duplicate the same rows.
enum _FeedFilter { all, levels, achievements, quests }

class _JourneyEventFeedState extends State<JourneyEventFeed> {
  _FeedFilter _filter = _FeedFilter.all;

  bool _matches(_FeedFilter filter, JourneyCheckpoint e) {
    switch (filter) {
      case _FeedFilter.all:
        return true;
      case _FeedFilter.levels:
        return e.type == JourneyEventType.level ||
            e.type == JourneyEventType.titleMilestone;
      case _FeedFilter.achievements:
        return e.type == JourneyEventType.achievement;
      case _FeedFilter.quests:
        return e.type == JourneyEventType.quest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Only surface chips for buckets that actually have at least one event.
    final available = <_FeedFilter>[
      for (final f in _FeedFilter.values)
        if (f == _FeedFilter.all || widget.events.any((e) => _matches(f, e))) f,
    ];

    final filtered = widget.events
        .where((e) => _matches(_filter, e))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (available.length > 2) ...[
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < available.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _Chip(
                    label: _filterLabel(l10n, available[i]),
                    color: _filterColor(available[i]),
                    selected: _filter == available[i],
                    onTap: () => setState(() => _filter = available[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (filtered.isEmpty)
          _EmptyHint(filterIsAll: _filter == _FeedFilter.all)
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  _FeedRow(event: filtered[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _filterLabel(AppLocalizations l10n, _FeedFilter f) {
    switch (f) {
      case _FeedFilter.all:
        return l10n.journeyFilterAll;
      case _FeedFilter.levels:
        return l10n.journeyFilterLevels;
      case _FeedFilter.achievements:
        return l10n.journeyFilterAchievements;
      case _FeedFilter.quests:
        return l10n.journeyFilterQuests;
    }
  }

  Color _filterColor(_FeedFilter f) {
    switch (f) {
      case _FeedFilter.all:
        return FtTokens.accent;
      case _FeedFilter.levels:
        // Title-breakpoint milestones dominate this bucket — use the
        // major (gold) tone so the chip matches the prominent rows.
        return journeyColor(JourneyEventType.titleMilestone);
      case _FeedFilter.achievements:
        return journeyColor(JourneyEventType.achievement);
      case _FeedFilter.quests:
        return journeyColor(JourneyEventType.quest);
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? color : FtTokens.onSurfaceMuted,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.event});
  final JourneyCheckpoint event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = journeyCheckpointColor(event);
    final locale = Localizations.localeOf(context).toString();
    final relTime =
        event.unlockedAt != null ? _relative(l10n, event.unlockedAt!) : null;
    final absDate = event.unlockedAt != null
        ? DateFormat('d. M. yyyy', locale).format(event.unlockedAt!)
        : null;
    final isMajor = event.isMajorMilestone;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMajor ? 36 : 32,
            height: isMajor ? 36 : 32,
            decoration: BoxDecoration(
              gradient: isMajor
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD980), Color(0xFFE5A833)],
                    )
                  : null,
              color: isMajor ? null : color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isMajor
                    ? FtTokens.accent.withValues(alpha: 0.55)
                    : color.withValues(alpha: 0.30),
                width: isMajor ? 1.4 : 1.0,
              ),
              boxShadow: isMajor
                  ? [
                      BoxShadow(
                        color: FtTokens.accent.withValues(alpha: 0.30),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: _emojiOrIcon(event, color, isMajor ? 20 : 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _typeLabel(l10n, event.type),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMajor ? 14 : 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.sublabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.78),
                    ),
                  ),
                ],
                if (event.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: FtTokens.onSurfaceMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (relTime != null && absDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  relTime,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  absDate,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: FtTokens.onSurfaceFaint,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _emojiOrIcon(JourneyCheckpoint cp, Color color, double size) {
    if (cp.emoji != null) {
      return Text(cp.emoji!, style: TextStyle(fontSize: size, height: 1));
    }
    return Icon(journeyIcon(cp.type), size: size, color: color);
  }

  String _typeLabel(AppLocalizations l10n, JourneyEventType type) {
    switch (type) {
      // titleMilestone shows as "LEVEL" too — see comment in
      // journey_interactive_map.dart for rationale.
      case JourneyEventType.titleMilestone:
      case JourneyEventType.level:
        return l10n.journeyTypeLevel;
      case JourneyEventType.achievement:
        return l10n.journeyTypeAchievement;
      case JourneyEventType.quest:
        return l10n.journeyTypeQuest;
      case JourneyEventType.streak:
      case JourneyEventType.xpMilestone:
        return l10n.journeyTypeLevel;
    }
  }
}

String _relative(AppLocalizations l10n, DateTime at) {
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inSeconds < 60) return l10n.journeyRelativeNow;
  if (diff.inMinutes < 60) return l10n.journeyRelativeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.journeyRelativeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.journeyRelativeDays(diff.inDays);
  if (diff.inDays < 30) {
    return l10n.journeyRelativeWeeks((diff.inDays / 7).floor());
  }
  if (diff.inDays < 365) {
    return l10n.journeyRelativeMonths((diff.inDays / 30).floor());
  }
  return l10n.journeyRelativeYears((diff.inDays / 365).floor());
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.filterIsAll});
  final bool filterIsAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        filterIsAll ? l10n.journeyEmptyFeedAll : l10n.journeyEmptyFeedFiltered,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: FtTokens.onSurfaceMuted,
        ),
      ),
    );
  }
}
