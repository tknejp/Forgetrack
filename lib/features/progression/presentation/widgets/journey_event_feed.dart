import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_shared.dart';

/// Filterable feed of milestone events shown under the big map on
/// [HeroJourneyMapScreen]. Events are sorted newest-first by the adapter;
/// this widget only handles type-filter UI.
class JourneyEventFeed extends StatefulWidget {
  const JourneyEventFeed({super.key, required this.events});

  /// Pre-sorted (date desc) milestone events. Each entry must have a non-null
  /// `unlockedAt` — the adapter's `buildFeed` already enforces this.
  final List<JourneyCheckpoint> events;

  @override
  State<JourneyEventFeed> createState() => _JourneyEventFeedState();
}

class _JourneyEventFeedState extends State<JourneyEventFeed> {
  JourneyEventType? _selectedType; // null = all

  @override
  Widget build(BuildContext context) {
    // Build the chip list from event types actually present in the feed,
    // so empty-by-construction filters don't clutter the UI.
    final available = <JourneyEventType>{
      for (final e in widget.events) e.type,
    }.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final filtered = _selectedType == null
        ? widget.events
        : widget.events
            .where((e) => e.type == _selectedType)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (available.length > 1) ...[
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _Chip(
                  label: 'Vše',
                  color: FtTokens.accent,
                  selected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
                for (final type in available) ...[
                  const SizedBox(width: 6),
                  _Chip(
                    label: journeyTypeLabel(type),
                    color: journeyColor(type),
                    selected: _selectedType == type,
                    onTap: () => setState(() => _selectedType = type),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (filtered.isEmpty)
          _EmptyHint(filterType: _selectedType)
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
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: selected ? color : FtTokens.onSurfaceMuted,
            letterSpacing: 0.7,
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
    final color = journeyColor(event.type);
    final locale = Localizations.localeOf(context).toString();
    final relTime = _relativeCs(event.unlockedAt!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Center(child: _icon(event, color)),
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
                        journeyTypeLabel(event.type),
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
                        style: const TextStyle(
                          fontSize: 13,
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
                DateFormat('d. M. yyyy', locale).format(event.unlockedAt!),
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

  Widget _icon(JourneyCheckpoint cp, Color color) {
    if (cp.type == JourneyEventType.level && cp.levelNumber != null) {
      return Text(
        '${cp.levelNumber}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: journeyFgColor(cp.type),
          height: 1,
        ),
      );
    }
    return Icon(
      journeyIcon(cp.type),
      size: 16,
      color: color,
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({this.filterType});
  final JourneyEventType? filterType;

  @override
  Widget build(BuildContext context) {
    final msg = filterType == null
        ? 'Zatím tu žádné události nejsou. Splň první quest nebo odemkni úspěch.'
        : 'V této kategorii zatím žádné události nejsou.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        msg,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: FtTokens.onSurfaceMuted,
        ),
      ),
    );
  }
}

String _relativeCs(DateTime at) {
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inSeconds < 60) return 'právě teď';
  if (diff.inMinutes < 60) return 'před ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'před ${diff.inHours} h';
  if (diff.inDays < 7) return 'před ${diff.inDays} dny';
  if (diff.inDays < 30) return 'před ${(diff.inDays / 7).floor()} týdny';
  if (diff.inDays < 365) return 'před ${(diff.inDays / 30).floor()} měsíci';
  return 'před ${(diff.inDays / 365).floor()} lety';
}
