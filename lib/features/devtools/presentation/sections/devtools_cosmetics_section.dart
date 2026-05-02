import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/cosmetics_provider.dart';
import '../../../../features/cosmetics/domain/cosmetic_catalog.dart';
import '../../../../features/cosmetics/domain/cosmetic_models.dart';
import '../../../../features/cosmetics/presentation/cosmetics_screen.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

class DevToolsCosmeticsSection extends StatefulWidget {
  const DevToolsCosmeticsSection({super.key});

  @override
  State<DevToolsCosmeticsSection> createState() =>
      _DevToolsCosmmeticsSectionState();
}

class _DevToolsCosmmeticsSectionState
    extends State<DevToolsCosmeticsSection> {
  bool _isClearing = false;
  bool _isGrantingAll = false;

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final state = cosmetics.state;
    final cs = Theme.of(context).colorScheme;

    final totalCount = CosmeticCatalog.definitions.length;
    final unlockedCount = state?.unlocked.length ?? 0;
    final equippedSlots = CosmeticType.values
        .where((t) => state?.equipped.slotId(t) != null)
        .length;
    final isBusy = _isClearing || _isGrantingAll || cosmetics.isLoading;

    return DevToolsSectionCard(
      title: 'Cosmetics',
      children: [
        DevToolsStatusTile(
          label: 'Unlocked / total',
          value: '$unlockedCount / $totalCount',
          valueColor: unlockedCount > 0 ? Colors.greenAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Equipped slots',
          value: '$equippedSlots / ${CosmeticType.values.length}',
        ),
        if (cosmetics.errorMessage != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Error',
            value: cosmetics.errorMessage!,
            valueColor: cs.error,
          ),
        ],
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Open inventory',
          subtitle: 'All catalog items — locked, assets, grant/revoke, conditions',
          icon: Icons.inventory_2_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CosmeticsScreen(devToolsMode: true),
            ),
          ),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Unlock all cosmetics',
          subtitle: 'Grants every catalog item to the signed-in user',
          icon: Icons.lock_open_rounded,
          isLoading: isBusy,
          onTap: isBusy ? null : _grantAll,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Clear all cosmetics',
          subtitle:
              'Wipes every unlock and clears all equipped slots for the signed-in user',
          isDestructive: true,
          isLoading: isBusy,
          icon: Icons.delete_sweep_rounded,
          onTap: isBusy ? null : _confirmAndClearAll,
        ),
      ],
    );
  }

  Future<void> _grantAll() async {
    setState(() => _isGrantingAll = true);
    try {
      final granted =
          await context.read<CosmeticsProvider>().devToolsGrantAllCosmetics();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DevTools: granted $granted cosmetics')),
      );
    } finally {
      if (mounted) setState(() => _isGrantingAll = false);
    }
  }

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all cosmetics?'),
        content: const Text(
          'Removes every unlock and clears all equipped slots for the '
          'signed-in user. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    try {
      final removed =
          await context.read<CosmeticsProvider>().devToolsClearAllUnlocks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DevTools: cleared $removed cosmetic unlocks')),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }
}
