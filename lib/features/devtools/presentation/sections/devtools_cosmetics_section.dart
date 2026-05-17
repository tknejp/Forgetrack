import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/cosmetics_provider.dart';
import '../../../../features/cosmetics/domain/companion_state.dart';
import '../../../../features/cosmetics/domain/cosmetic_catalog.dart';
import '../../../../features/cosmetics/domain/cosmetic_models.dart';
import '../../../../features/cosmetics/presentation/cosmetics_screen.dart';
import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/companion_dev_controller.dart';
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
  // Per-companion busy flag so concurrent taps on the matrix can't race
  // through the orchestration steps (level → force-complete → grant).
  // Keyed by companion id; cleared in a finally block.
  final Set<String> _busyCompanionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();
    final state = cosmetics.state;
    final cs = Theme.of(context).colorScheme;

    final totalCount = CosmeticCatalog.definitions.length;
    final unlockedCount = state?.unlocked.length ?? 0;
    final equippedSlots = CosmeticType.values
        .where((t) => state?.equipped.slotId(t) != null)
        .length;
    final isBusy = _isClearing ||
        _isGrantingAll ||
        cosmetics.isLoading ||
        _busyCompanionIds.isNotEmpty;

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
        const DevToolsSectionDivider(),
        _CompanionStateMatrix(
          controller: CompanionDevController(
            cosmetics: cosmetics,
            progression: progression,
          ),
          busyIds: _busyCompanionIds,
          isAnyOuterBusy: _isClearing || _isGrantingAll || cosmetics.isLoading,
          onApply: _applyCompanionState,
        ),
      ],
    );
  }

  /// Orchestrates a state transition with a per-companion busy guard.
  /// The controller's `applyState` chains several engine + cosmetics
  /// writes; the guard prevents the matrix from kicking off another
  /// transition while one is in flight (would race on the same uid /
  /// ledger).
  Future<void> _applyCompanionState(
    CompanionDevController controller,
    String companionId,
    Future<void> Function() apply,
  ) async {
    if (_busyCompanionIds.contains(companionId)) return;
    setState(() => _busyCompanionIds.add(companionId));
    try {
      await apply();
    } finally {
      if (mounted) {
        setState(() => _busyCompanionIds.remove(companionId));
      }
    }
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

/// Per-companion state matrix. Each row lists the companion + its
/// current `CompanionDevState` + a button row for each target state
/// (Hidden / VisibleLocked / Partial / Claimable / Unlocked). Tapping
/// a state runs [CompanionDevController.applyState] for that companion.
///
/// Buttons inactive when the same companion is mid-transition or when
/// the outer cosmetics section is busy (grant-all / clear-all).
class _CompanionStateMatrix extends StatelessWidget {
  const _CompanionStateMatrix({
    required this.controller,
    required this.busyIds,
    required this.isAnyOuterBusy,
    required this.onApply,
  });

  final CompanionDevController controller;
  final Set<String> busyIds;
  final bool isAnyOuterBusy;
  final Future<void> Function(
    CompanionDevController controller,
    String companionId,
    Future<void> Function() apply,
  ) onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final companions = CompanionDevController.allCompanions();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.pets_rounded,
                size: 14,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Companion state matrix',
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Per-companion: pick a target state. Engine level + gating '
            'achievements are forced as needed; Hidden requires gate − 10.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          for (final node in companions)
            _CompanionRow(
              node: node,
              current: controller.detect(node),
              isBusy: busyIds.contains(node.id) || isAnyOuterBusy,
              isRowBusy: busyIds.contains(node.id),
              onSelect: (target) => onApply(
                controller,
                node.id,
                () => controller.applyState(node, target),
              ),
              l10n: l10n,
            ),
        ],
      ),
    );
  }
}

class _CompanionRow extends StatelessWidget {
  const _CompanionRow({
    required this.node,
    required this.current,
    required this.isBusy,
    required this.isRowBusy,
    required this.onSelect,
    required this.l10n,
  });

  // Imported via the controller's catalog snapshot — using the
  // progression-engine type directly avoids re-exporting it from
  // application/.
  final dynamic node; // CompanionAvailabilityNode (dynamic to avoid extra import)
  final CompanionState current;
  final bool isBusy;
  final bool isRowBusy;
  final ValueChanged<CompanionState> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final gate = CompanionDevController.gateLevelFor(node) ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.titleKey(l10n) as String,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                'L$gate',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              _StateChip(state: current),
              if (isRowBusy) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: cs.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in CompanionState.values)
                _StateButton(
                  label: _stateLabel(s),
                  isCurrent: s == current,
                  isDisabled: isBusy,
                  onTap: () => onSelect(s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _stateLabel(CompanionState s) {
    switch (s) {
      case CompanionState.hidden:
        return 'Hidden';
      case CompanionState.partial:
        return 'Partial';
      case CompanionState.claimable:
        return 'Claimable';
      case CompanionState.claimed:
        return 'Claimed';
    }
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final CompanionState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, label) = switch (state) {
      CompanionState.hidden =>
        (cs.onSurfaceVariant.withValues(alpha: 0.6), 'HIDDEN'),
      CompanionState.partial => (cs.secondary, 'PARTIAL'),
      CompanionState.claimable => (Colors.greenAccent, 'CLAIMABLE'),
      CompanionState.claimed => (cs.primary, 'CLAIMED'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({
    required this.label,
    required this.isCurrent,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: isDisabled ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isCurrent ? cs.primary.withValues(alpha: 0.16) : Colors.transparent,
        foregroundColor: isCurrent ? cs.primary : cs.onSurface,
        side: BorderSide(
          color: isCurrent
              ? cs.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: tt.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: isCurrent ? cs.primary : cs.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
