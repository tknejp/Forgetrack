import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../../../../features/progression_engine/domain/models/engine_evaluation_input.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

/// Devtools surface for the new engine. Lets the user trigger one
/// evaluation pass with a synthetic ambitious-player input, inspect
/// the persisted ledger size, and wipe the ledger. Independent of
/// the legacy ProgressionDevTools section.
class DevToolsProgressionEngineSection extends StatefulWidget {
  const DevToolsProgressionEngineSection({super.key});

  @override
  State<DevToolsProgressionEngineSection> createState() =>
      _DevToolsProgressionEngineSectionState();
}

class _DevToolsProgressionEngineSectionState
    extends State<DevToolsProgressionEngineSection> {
  bool _isEvaluating = false;
  bool _isWiping = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionEngineProvider>();
    final ledger = p.ledger;
    final last = p.lastResult;

    return DevToolsSectionCard(
      title: 'Progression Engine V2',
      children: [
        DevToolsStatusTile(
          label: 'Loading',
          value: '${p.isLoading}',
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
          label: 'Last result — granted rewards',
          value: '${last?.grantedRewards.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Pending celebrations',
          value: '${p.pendingCelebrations.length}',
        ),
        if (p.error != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Error',
            value: p.error!,
            valueColor: Theme.of(context).colorScheme.error,
          ),
        ],
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Run V2 evaluation (ambitious-player input)',
          subtitle:
              'Synthetic input: 10500 steps, 165g protein, 120k lifetime, level 5, 5000 XP',
          icon: Icons.play_arrow_rounded,
          isLoading: _isEvaluating || p.isEvaluating,
          isDisabled: _isWiping,
          onTap: _isEvaluating
              ? null
              : () async {
                  setState(() => _isEvaluating = true);
                  try {
                    await context
                        .read<ProgressionEngineProvider>()
                        .evaluateWith(input: _ambitiousInput());
                  } finally {
                    if (mounted) setState(() => _isEvaluating = false);
                  }
                },
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Wipe V2 ledger',
          subtitle:
              'Clears every V2 Isar collection. Legacy progression untouched.',
          isDestructive: true,
          icon: Icons.delete_sweep_rounded,
          isLoading: _isWiping,
          isDisabled: _isEvaluating,
          onTap: _isWiping ? null : () => _confirmAndWipe(context),
        ),
      ],
    );
  }

  Future<void> _confirmAndWipe(BuildContext context) async {
    // Capture all BuildContext-derived dependencies before any
    // async gap so the analyzer is happy and we never reach into a
    // disposed tree.
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe V2 ledger?'),
        content: const Text(
          'Clears every progression_engine Isar collection. '
          'Legacy progression is untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWiping = true);
    try {
      await provider.devToolsWipeLedger();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('V2 ledger wiped')),
      );
    } finally {
      if (mounted) setState(() => _isWiping = false);
    }
  }

  EngineEvaluationInput _ambitiousInput() => EngineEvaluationInput(
        evaluatedAt: DateTime.now(),
        stepsToday: 10500,
        proteinGramsToday: 165,
        stepsLifetime: 120000,
        level: 5,
        totalXp: 5000,
      );
}
