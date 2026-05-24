import 'package:flutter/material.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import 'package:provider/provider.dart';

import '../../../../progression_engine/application/progression_engine_provider.dart';
import '../../../../progression_engine/domain/catalog/progression_node_catalog.dart';

/// One-tap chips for each `QuestDisplayBucket.daily` node.
class DailyGoalChipsPanel extends StatefulWidget {
  const DailyGoalChipsPanel({super.key, required this.isBusy});

  final bool isBusy;

  @override
  State<DailyGoalChipsPanel> createState() => _DailyGoalChipsPanelState();
}

class _DailyGoalChipsPanelState extends State<DailyGoalChipsPanel> {
  String? _completingId;

  late final List<Quest> _dailyQuests = [
    for (final node in const ProgressionEntryCatalog().build())
      if (node is Quest && node.displayBucket == QuestDisplayBucket.daily)
        node,
  ];

  Future<void> _complete(Quest node) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _completingId = node.id);
    try {
      // `devToolsMarkObjectiveMet` writes just the objective event,
      // so the card surfaces the Vyzvednout pill instead of jumping
      // straight to claimed. `devToolsForceCompleteNode` (which used
      // to live here) auto-claimed end-to-end and skipped the manual
      // tap that the real player flow goes through.
      await provider.devToolsMarkObjectiveMet(node.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Marked "${node.id}" met for today — tap Vyzvednout on the card to claim.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _completingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark daily goal as met today',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Writes the objective-met event for today. Card surfaces the '
            'Vyzvednout pill — tap to claim like a real player would.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final node in _dailyQuests)
                ActionChip(
                  label: _completingId == node.id
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_chipLabelFor(node.id)),
                  onPressed: widget.isBusy || _completingId != null
                      ? null
                      : () => _complete(node),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _chipLabelFor(String nodeId) {
    var label = nodeId;
    if (label.startsWith('daily_')) label = label.substring(6);
    if (label.endsWith('_today')) {
      label = label.substring(0, label.length - 6);
    }
    return label;
  }
}
