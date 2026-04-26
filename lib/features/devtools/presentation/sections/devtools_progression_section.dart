import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression/application/progression_provider.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

String _fmt(DateTime? dt) {
  if (dt == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class DevToolsProgressionSection extends StatefulWidget {
  const DevToolsProgressionSection({super.key});

  @override
  State<DevToolsProgressionSection> createState() =>
      _DevToolsProgressionSectionState();
}

class _DevToolsProgressionSectionState
    extends State<DevToolsProgressionSection> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionProvider>();
    final cs = Theme.of(context).colorScheme;

    return DevToolsSectionCard(
      title: 'Progression / RPG', // TODO: l10n
      children: [
        DevToolsStatusTile(
          label: 'Level',
          value: '${p.profile.level}  (${p.profile.levelTitle})',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Total XP',
          value: '${p.profile.totalXp} XP',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'XP into current level',
          value: '${p.profile.xpIntoLevel} / ${p.profile.nextLevelXp}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Quests  (active / completed / total)',
          value:
              '${p.activeQuests.length} / ${p.completedQuests.length} / ${p.quests.length}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Pending rewards',
          value: '${p.pendingRewards.length}',
          valueColor:
              p.pendingRewards.isNotEmpty ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Achievements  (unlocked / total)',
          value:
              '${p.achievements.where((a) => a.unlocked).length} / ${p.achievements.length}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last evaluated',
          value: _fmt(p.lastEvaluatedAt),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Loading / refreshing',
          value: '${p.isLoading} / ${p.isRefreshing || _isRefreshing}',
        ),
        if (p.error != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Error',
            value: p.error!,
            valueColor: cs.error,
          ),
        ],
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Recalculate Progression',
          subtitle: 'Calls progression.refresh() — sync log added in Phase 3',
          isLoading: _isRefreshing || p.isRefreshing,
          onTap: (_isRefreshing || p.isRefreshing)
              ? null
              : () async {
                  setState(() => _isRefreshing = true);
                  try {
                    await context.read<ProgressionProvider>().refresh();
                  } finally {
                    if (mounted) setState(() => _isRefreshing = false);
                  }
                },
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Grant test XP',
          subtitle: 'No safe method exists yet',
          onTap: null,
          isDisabled: true,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Complete test quest',
          subtitle: 'No safe method exists yet',
          onTap: null,
          isDisabled: true,
        ),
      ],
    );
  }
}
