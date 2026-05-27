import 'package:flutter/material.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:provider/provider.dart';

import '../../../../cosmetics/application/cosmetics_provider.dart';
import '../../../../progression_engine/application/progression_engine_provider.dart';
import '../../../../progression_engine/domain/catalog/progression_node_catalog.dart';

/// Devtools panel that force-completes an entire chapter chain
/// (opener → steps → finale) in one tap. The finale grants the
/// chapter's emblem cosmetic, so this is the canonical way to drive
/// the chapter-completion celebration + the resulting emblem unlock
/// without grinding through every step's objective.
///
/// Each row is one chapter from the catalog; the button iterates the
/// chapter's nodes in `chainOrder` and calls
/// [ProgressionEngineProvider.devToolsForceCompleteNode] sequentially
/// so each prereq is satisfied before the next node fires.
class ChapterCompleterPanel extends StatefulWidget {
  const ChapterCompleterPanel({super.key, required this.isBusy});

  final bool isBusy;

  @override
  State<ChapterCompleterPanel> createState() => _ChapterCompleterPanelState();
}

class _ChapterCompleterPanelState extends State<ChapterCompleterPanel> {
  String? _completingId;

  /// One [_ChapterRow] per chapter found in the catalog. We collect
  /// chapter nodes once during `initState` since the catalog is a
  /// const-built table (no runtime mutation).
  late final List<_ChapterRow> _rows = () {
    final nodes = const ProgressionEntryCatalog().build();
    final grouped = <ChapterId, List<Quest>>{};
    for (final node in nodes) {
      if (node is Quest && node.chapterId != null) {
        grouped.putIfAbsent(node.chapterId!, () => <Quest>[]).add(node);
      }
    }
    final out = <_ChapterRow>[];
    for (final entry in grouped.entries) {
      final chain = [...entry.value]
        ..sort((a, b) => (a.chainOrder ?? 0).compareTo(b.chainOrder ?? 0));
      out.add(_ChapterRow(
        chapterId: entry.key,
        nodes: chain,
      ));
    }
    out.sort((a, b) => a.chapterId.raw.compareTo(b.chapterId.raw));
    return out;
  }();

  Future<void> _completeChapter(_ChapterRow row) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final cosmetics = context.read<CosmeticsProvider>();
    setState(() => _completingId = row.chapterId.raw);
    try {
      // First drive the engine ledger so the chapter celebration +
      // narrative state behaves as if the player completed every step.
      // Each `devToolsForceCompleteNode` writes the node's
      // ObjectiveCompletionEvent + NodeClaimEvent and re-evaluates;
      // sequential order satisfies the chain prereqs as we go.
      for (final node in row.nodes) {
        await provider.devToolsForceCompleteNode(node.id);
      }
      // Safety net: simulateClaim drops the cosmetic reward grant
      // when the resolver still classifies the finale as not
      // available (e.g. a stricter unlock condition outside the chain
      // prereqs). Devtools should always end up with the chapter's
      // emblem unlocked regardless, so direct-grant every CosmeticReward
      // the chain carries — matches the "_devGrant always direct-unlocks"
      // policy on the cosmetic details sheet.
      for (final node in row.nodes) {
        for (final reward in node.rewards) {
          if (reward is CosmeticReward) {
            await cosmetics.debugGrantCosmetic(reward.cosmeticId);
          }
        }
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Chapter "${row.chapterId.raw}" force-completed '
            '(${row.nodes.length} nodes)',
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
            'Force-completes every node in a chapter chain '
            '(opener → steps → finale). The finale grants the chapter\'s '
            'emblem cosmetic so this is the one-tap path to test '
            'chapter-completion celebrations + emblem unlocks.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          for (final row in _rows)
            // Material wrapper so the inner ListTile's ink splashes +
            // selection chrome find their nearest Material ancestor
            // here rather than the surrounding DevToolsCollapsibleCard's
            // BoxDecoration (which Flutter flags as
            // "background may be invisible").
            Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  row.chapterId.raw,
                  style: tt.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
                subtitle: Text('${row.nodes.length} nodes'),
                trailing: TextButton(
                  onPressed: widget.isBusy || _completingId != null
                      ? null
                      : () => _completeChapter(row),
                  child: _completingId == row.chapterId.raw
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete'), // lint-ignore: l10n-literal — devtools, intentionally English
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapterRow {
  const _ChapterRow({required this.chapterId, required this.nodes});

  final ChapterId chapterId;
  final List<Quest> nodes;
}
