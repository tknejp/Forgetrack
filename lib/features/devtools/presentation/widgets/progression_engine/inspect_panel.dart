import 'package:flutter/material.dart';

import '../../../../progression_engine/application/progression_engine_provider.dart';
import '../devtools_section_card.dart';
import '../devtools_status_tile.dart';

class InspectPanel extends StatelessWidget {
  const InspectPanel({super.key, required this.provider});

  final ProgressionEngineProvider provider;

  @override
  Widget build(BuildContext context) {
    final ledger = provider.ledger;
    final last = provider.lastResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DevToolsStatusTile(
          label: 'Loading',
          value: '${provider.isLoading}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger objective completions',
          value: '${ledger?.objectiveCompletions.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger node completions',
          value: '${ledger?.nodeCompletions.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger node claims',
          value: '${ledger?.nodeClaims.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger node announcements',
          value: '${ledger?.nodeAnnouncements.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger reward grants',
          value: '${ledger?.rewardGrants.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last result — completed nodes',
          value: '${last?.completedNodes.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last result — newly available nodes',
          value: '${last?.newlyAvailableNodes.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last result — granted rewards',
          value: '${last?.grantedRewards.length ?? 0}',
        ),
      ],
    );
  }
}
