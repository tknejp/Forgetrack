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
        _SetXpPanel(isBusy: _isEvaluating || _isWiping || p.isEvaluating),
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

/// Inline panel for seeding the ledger with a synthetic XP grant.
/// Equivalent to V1's `_DevToolsXpOverridePanel` — wipes the V2
/// ledger and inserts one synthetic grant so `profile.totalXp`
/// becomes exactly the requested value. Use to test high-level
/// flows (level milestones, XP-threshold achievements) without
/// completing dozens of real quests.
class _SetXpPanel extends StatefulWidget {
  const _SetXpPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_SetXpPanel> createState() => _SetXpPanelState();
}

class _SetXpPanelState extends State<_SetXpPanel> {
  late final TextEditingController _controller;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final canApply =
        !widget.isBusy && !_applying && _resolveXp() != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set total XP',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Wipes the V2 ledger and inserts a synthetic XP grant so '
            "profile.totalXp becomes exactly the chosen value.",
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isBusy && !_applying,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Total XP',
                    hintText: 'e.g. 25000',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply ? _apply : null,
                child: _applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _resolveXp() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  Future<void> _apply() async {
    final xp = _resolveXp();
    if (xp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetTotalXp(xp);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('V2 totalXp set to $xp')),
      );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}
