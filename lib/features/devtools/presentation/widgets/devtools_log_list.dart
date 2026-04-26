import 'package:flutter/material.dart';

import '../../domain/devtools_sync_event.dart';

class DevToolsLogList extends StatelessWidget {
  const DevToolsLogList({super.key, required this.events});

  final List<DevToolsSyncEvent> events;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Text(
          'No events recorded yet.',
          style: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: events.map((e) => _EventRow(event: e)).toList(),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final DevToolsSyncEvent event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resultColor = switch (event.result) {
      'success' => Colors.greenAccent.shade400,
      'failure' => cs.error,
      'started' => Colors.orangeAccent,
      _ => cs.onSurfaceVariant,
    };

    final extra = event.extra;
    String? extraText;
    if (extra != null && extra.isNotEmpty) {
      extraText = extra.entries.map((e) => '${e.key}=${e.value}').join('  ');
    }

    final dt = event.timestamp;
    final timeLabel =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    final durationLabel =
        event.durationMs != null ? ' ${event.durationMs}ms' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                timeLabel,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                event.feature,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '[${event.source}]',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${event.result}$durationLabel',
                style: TextStyle(
                  color: resultColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (event.errorMessage != null) ...[
            const SizedBox(height: 2),
            Text(
              event.errorMessage!,
              style: TextStyle(
                color: cs.error,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (extraText != null) ...[
            const SizedBox(height: 2),
            Text(
              extraText,
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
