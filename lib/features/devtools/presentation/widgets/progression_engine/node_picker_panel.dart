import 'package:flutter/material.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:provider/provider.dart';

import '../../../../progression_engine/application/progression_engine_provider.dart';
import '../../../../progression_engine/domain/catalog/progression_node_catalog.dart';

/// Searchable node picker — typeahead filter over every node id in
/// the catalog, with a "Complete" button on each row.
class NodePickerPanel extends StatefulWidget {
  const NodePickerPanel({super.key, required this.isBusy});

  final bool isBusy;

  @override
  State<NodePickerPanel> createState() => _NodePickerPanelState();
}

class _NodePickerPanelState extends State<NodePickerPanel> {
  final _filterController = TextEditingController();
  String? _completingId;

  late final List<_NodeEntry> _entries = () {
    final entries = <_NodeEntry>[
      for (final node in const ProgressionEntryCatalog().build())
        _NodeEntry(id: node.id, kind: _kindLabelFor(node)),
    ]..sort((a, b) {
        final byKind = a.kind.compareTo(b.kind);
        if (byKind != 0) return byKind;
        return a.id.compareTo(b.id);
      });
    return entries;
  }();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  String _kindLabelFor(ProgressionEntry node) => switch (node) {
        Quest(:final displayBucket) => 'quest · ${displayBucket.name}',
        Achievement() => 'achievement',
        Milestone() => 'milestone',
        LevelMilestone(:final level) => 'level $level',
        ChapterCompletion() => 'chapter completion',
        ContentUnlock() => 'content unlock',
        CompanionAvailability() => 'companion availability',
        Relic() => 'relic',
      };

  Future<void> _complete(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _completingId = id);
    try {
      await provider.devToolsForceCompleteNode(id);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('Force-completed "$id"')));
    } finally {
      if (mounted) setState(() => _completingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final filter = _filterController.text.trim().toLowerCase();
    final filtered = filter.isEmpty
        ? const <_NodeEntry>[]
        : _entries
            .where((e) => // lint-ignore: widget-no-logic — devtools node-id/kind search filter
                e.id.toLowerCase().contains(filter) ||
                e.kind.toLowerCase().contains(filter))
            .take(40)
            .toList();
    final canType = !widget.isBusy && _completingId == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _filterController,
            enabled: canType,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              labelText: 'Filter',
              hintText: 'e.g. combo, achievement, companion',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (filter.isEmpty)
            Text(
              '${_entries.length} nodes in the catalog. Type to filter.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            )
          else if (filtered.isEmpty)
            Text(
              'No nodes match "$filter".',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outline.withValues(alpha: 0.18),
                ),
                itemBuilder: (context, i) {
                  final entry = filtered[i];
                  final busy = _completingId == entry.id;
                  // Wrap in a transparent Material so the ListTile's
                  // ink splash + selection chrome find their nearest
                  // Material ancestor here, not the DevToolsCollapsibleCard's
                  // outer `Container(decoration: …)` — which Flutter
                  // flags as "ListTile background may be invisible"
                  // because the DecoratedBox would mask the ink.
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        entry.id,
                        style: tt.bodyMedium
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                      subtitle: Text(entry.kind),
                      trailing: TextButton(
                        onPressed:
                            widget.isBusy || _completingId != null
                                ? null
                                : () => _complete(entry.id),
                        child: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Complete'), // lint-ignore: l10n-literal — devtools, intentionally English
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeEntry {
  const _NodeEntry({required this.id, required this.kind});
  final String id;
  final String kind;
}
