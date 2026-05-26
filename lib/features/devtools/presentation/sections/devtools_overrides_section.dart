import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../features/settings/presentation/dialogs/settings_dialogs.dart';
import '../../application/devtools_provider.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

class DevToolsOverridesSection extends StatelessWidget {
  const DevToolsOverridesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final devTools = context.watch<DevToolsProvider>();
    final overrides = devTools.overrides;
    final cs = Theme.of(context).colorScheme;

    final hasAny = !overrides.isEmpty;

    return DevToolsSectionCard(
      title: context.l10n.devtoolsSectionOverrides,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(
            context.l10n.devtoolsOverridesHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Steps override',
          value: overrides.stepsOverride?.toString() ?? '—',
          valueColor: overrides.stepsOverride != null ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Step offset',
          value: overrides.stepOffset?.toString() ?? '—',
          valueColor: overrides.stepOffset != null ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Calories override',
          value: overrides.caloriesOverride != null
              ? '${overrides.caloriesOverride!.toStringAsFixed(0)} kcal'
              : '—',
          valueColor: overrides.caloriesOverride != null ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Weight override',
          value: overrides.weightOverride != null
              ? '${overrides.weightOverride!.toStringAsFixed(1)} kg'
              : '—',
          valueColor: overrides.weightOverride != null ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Clear all overrides',
          isDestructive: hasAny,
          isDisabled: !hasAny,
          onTap: hasAny ? () => _confirmClear(context) : null,
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: l10n.devtoolsOverridesClearTitle,
      message: l10n.devtoolsOverridesClearMessage,
      confirmLabel: l10n.devtoolsOverridesClearConfirm,
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<DevToolsProvider>().clearOverrides();
    }
  }
}
