import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_primitives.dart';

/// Feed of milestone events shown under the big map on `HeroJourneyMapScreen`.
/// The adapter delivers events newest-first; the parent owns the selected
/// filter so controls can stay pinned with the map.
class JourneyEventFeed extends StatelessWidget {
  const JourneyEventFeed({
    super.key,
    required this.events,
    this.selectedFilter = JourneyFeedFilter.all,
  });

  /// Pre-sorted (date desc, undated last) milestone events from
  /// `JourneyAdapter.buildFeed`.
  final List<JourneyCheckpoint> events;
  final JourneyFeedFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = events
        .where((e) => journeyFeedMatchesFilter(selectedFilter, e))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filtered.isEmpty)
          _EmptyHint(filterIsAll: selectedFilter == JourneyFeedFilter.all)
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(Tokens.radiusTile),
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
}

/// Logical filter buckets exposed in the chip row. The "Levely" bucket
/// covers BOTH minor `level` and major `titleMilestone` event types — both
/// are level/title breakpoints from the same progression system, so a
/// separate "Tituly" filter would just duplicate the same rows.
enum JourneyFeedFilter { all, levels, achievements, quests }

bool journeyFeedMatchesFilter(JourneyFeedFilter filter, JourneyCheckpoint e) {
  switch (filter) {
    case JourneyFeedFilter.all:
      return true;
    case JourneyFeedFilter.levels:
      return e.type == JourneyEventType.level ||
          e.type == JourneyEventType.titleMilestone;
    case JourneyFeedFilter.achievements:
      return e.type == JourneyEventType.achievement;
    case JourneyFeedFilter.quests:
      return e.type == JourneyEventType.quest;
  }
}

class JourneyFeedFilterPills extends StatelessWidget {
  const JourneyFeedFilterPills({
    super.key,
    required this.events,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<JourneyCheckpoint> events;
  final JourneyFeedFilter selectedFilter;
  final ValueChanged<JourneyFeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = <JourneyFeedFilter>[
      for (final f in JourneyFeedFilter.values)
        if (f == JourneyFeedFilter.all ||
            events.any((e) => journeyFeedMatchesFilter(f, e)))
          f,
    ];

    if (available.length <= 2) return const SizedBox.shrink();

    return SizedBox(
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
              selected: selectedFilter == available[i],
              onTap: () => onSelected(available[i]),
            ),
          ],
        ],
      ),
    );
  }

  String _filterLabel(AppLocalizations l10n, JourneyFeedFilter f) {
    switch (f) {
      case JourneyFeedFilter.all:
        return l10n.journeyFilterAll;
      case JourneyFeedFilter.levels:
        return l10n.journeyFilterLevels;
      case JourneyFeedFilter.achievements:
        return l10n.journeyFilterAchievements;
      case JourneyFeedFilter.quests:
        return l10n.journeyFilterQuests;
    }
  }

  Color _filterColor(JourneyFeedFilter f) {
    switch (f) {
      case JourneyFeedFilter.all:
        return Tokens.accent;
      case JourneyFeedFilter.levels:
        return journeyColor(JourneyEventType.titleMilestone);
      case JourneyFeedFilter.achievements:
        return journeyColor(JourneyEventType.achievement);
      case JourneyFeedFilter.quests:
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
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: selected ? color : Tokens.onSurfaceMuted,
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
                    ? Tokens.accent.withValues(alpha: 0.55)
                    : color.withValues(alpha: 0.30),
                width: isMajor ? 1.4 : 1.0,
              ),
              boxShadow: isMajor
                  ? [
                      BoxShadow(
                        color: Tokens.accent.withValues(alpha: 0.30),
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
                      fontSize: Tokens.fontSizeCaption,
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
                      fontSize: Tokens.fontSizeCaption,
                      height: 1.4,
                      color: Tokens.onSurfaceMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Tokens.spaceSm),
          if (relTime != null && absDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  relTime,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  absDate,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeTiny,
                    fontWeight: FontWeight.w600,
                    color: Tokens.onSurfaceFaint,
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
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        filterIsAll ? l10n.journeyEmptyFeedAll : l10n.journeyEmptyFeedFiltered,
        style: const TextStyle(
          fontSize: Tokens.fontSizeSmall,
          height: 1.4,
          color: Tokens.onSurfaceMuted,
        ),
      ),
    );
  }
}
