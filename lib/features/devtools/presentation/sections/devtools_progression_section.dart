import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/cosmetics_provider.dart';
import '../../../../features/cosmetics/domain/cosmetic_models.dart';
import '../../../../features/progression/application/progression_provider.dart';
import '../../../progression/domain/policy/level_config.dart';
import '../../../progression/domain/policy/level_policy.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

enum _ResetKind { progression, cosmetics, everything }

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
  bool _isApplyingOverride = false;
  bool _isResetting = false;

  _ResetKind? _activeReset;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionProvider>();
    final cosmetics = context.watch<CosmeticsProvider>();
    final cs = Theme.of(context).colorScheme;

    final progressionInventoryCount = cosmetics.state?.unlocked.values
            .where((unlock) => _isProgressionCosmeticSource(unlock.sourceType))
            .length ??
        0;
    final isBusy =
        p.isRefreshing || _isRefreshing || _isApplyingOverride || _isResetting;
    final progressionInventoryHasItems = progressionInventoryCount > 0;
    final hasProgressionData = p.profile.totalXp > 0 ||
        p.achievements.any((a) => a.unlocked) ||
        p.completedQuests.isNotEmpty ||
        p.questRewardGrants.isNotEmpty;
    return DevToolsSectionCard(
      title: 'Progression / RPG', // TODO: l10n
      children: [
        DevToolsStatusTile(
          label: 'Level',
          value:
              '${p.profile.level}  (${tierForLevel(p.profile.level).title(context.l10n)})',
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
          valueColor: p.pendingRewards.isNotEmpty ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Achievements  (unlocked / total)',
          value:
              '${p.achievements.where((a) => a.unlocked).length} / ${p.achievements.length}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Progression inventory unlocks',
          value: '$progressionInventoryCount',
          valueColor:
              progressionInventoryCount > 0 ? Colors.orangeAccent : null,
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
          onTap: isBusy
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
        _DevToolsXpOverridePanel(
          isBusy: isBusy,
          isApplying: _isApplyingOverride,
          onApply: (xp) => _applyXpOverride(xp),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Text(
            'Resets',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        DevToolsActionTile(
          label: 'Reset progression',
          subtitle:
              'Wipes XP, achievement unlocks, quests, chapter starts. Cosmetics inventory untouched.',
          isDestructive: true,
          isLoading: _activeReset == _ResetKind.progression,
          isDisabled: (isBusy && _activeReset != _ResetKind.progression) ||
              !hasProgressionData,
          icon: Icons.history_toggle_off_rounded,
          onTap: isBusy ? null : () => _confirmAndReset(_ResetKind.progression),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Reset cosmetics inventory',
          subtitle:
              'Wipes progression-sourced cosmetics. Owed cosmetics are silently re-granted from the current state.',
          isDestructive: true,
          isLoading: _activeReset == _ResetKind.cosmetics,
          isDisabled: (isBusy && _activeReset != _ResetKind.cosmetics) ||
              !progressionInventoryHasItems,
          icon: Icons.checkroom_rounded,
          onTap: isBusy ? null : () => _confirmAndReset(_ResetKind.cosmetics),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Reset everything (fresh start)',
          subtitle:
              'Wipes progression AND cosmetics inventory. Welcome reward screen reappears.',
          isDestructive: true,
          isLoading: _activeReset == _ResetKind.everything,
          isDisabled: (isBusy && _activeReset != _ResetKind.everything) ||
              (!hasProgressionData && !progressionInventoryHasItems),
          icon: Icons.restart_alt_rounded,
          onTap: isBusy ? null : () => _confirmAndReset(_ResetKind.everything),
        ),
      ],
    );
  }

  Future<void> _applyXpOverride(int xp) async {
    setState(() => _isApplyingOverride = true);
    try {
      await context.read<ProgressionProvider>().devToolsSetTotalXp(xp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Devtools: total XP set to $xp')),
      );
    } finally {
      if (mounted) setState(() => _isApplyingOverride = false);
    }
  }

  Future<void> _confirmAndReset(_ResetKind kind) async {
    final copy = _resetCopy(kind);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(copy.dialogTitle),
        content: Text(copy.dialogBody),
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isResetting = true;
      _activeReset = kind;
    });
    final progression = context.read<ProgressionProvider>();
    final cosmetics = context.read<CosmeticsProvider>();
    try {
      switch (kind) {
        case _ResetKind.progression:
          await progression.devToolsResetProgression();
          break;
        case _ResetKind.cosmetics:
          await progression.devToolsResetCosmetics(
            resetCosmeticsInventory: cosmetics.devToolsResetProgressionUnlocks,
          );
          break;
        case _ResetKind.everything:
          await progression.devToolsResetEverything(
            resetCosmeticsInventory: cosmetics.devToolsResetProgressionUnlocks,
          );
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.toast)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
          _activeReset = null;
        });
      }
    }
  }

  _ResetCopy _resetCopy(_ResetKind kind) {
    switch (kind) {
      case _ResetKind.progression:
        return const _ResetCopy(
          dialogTitle: 'Reset progression?',
          dialogBody: 'Wipes XP, achievement unlocks, quest reward grants and '
              'chapter starts — locally (Isar) and in Firestore for the '
              'signed-in user. Cosmetics inventory is preserved. '
              'Cannot be undone.',
          toast: 'Devtools: progression reset',
        );
      case _ResetKind.cosmetics:
        return const _ResetCopy(
          dialogTitle: 'Reset cosmetics inventory?',
          dialogBody:
              'Wipes the progression-sourced cosmetics inventory for the '
              'signed-in user. Owed cosmetics are silently re-granted from '
              'the current progression state — no welcome celebration. '
              'Cannot be undone.',
          toast: 'Devtools: cosmetics inventory reset',
        );
      case _ResetKind.everything:
        return const _ResetCopy(
          dialogTitle: 'Reset everything?',
          dialogBody: 'Wipes ALL progression data AND the progression-sourced '
              'cosmetics inventory, locally and in Firestore for the '
              'signed-in user. The welcome reward screen will re-appear. '
              'Cannot be undone.',
          toast: 'Devtools: full reset complete',
        );
    }
  }
}

class _ResetCopy {
  const _ResetCopy({
    required this.dialogTitle,
    required this.dialogBody,
    required this.toast,
  });

  final String dialogTitle;
  final String dialogBody;
  final String toast;
}

bool _isProgressionCosmeticSource(String? sourceType) {
  return sourceType == CosmeticUnlockSource.progressionLevel.name ||
      sourceType == CosmeticUnlockSource.achievement.name ||
      sourceType == CosmeticUnlockSource.quest.name;
}

class _DevToolsXpOverridePanel extends StatefulWidget {
  const _DevToolsXpOverridePanel({
    required this.isBusy,
    required this.isApplying,
    required this.onApply,
  });

  final bool isBusy;
  final bool isApplying;
  final Future<void> Function(int xp) onApply;

  @override
  State<_DevToolsXpOverridePanel> createState() =>
      _DevToolsXpOverridePanelState();
}

class _DevToolsXpOverridePanelState extends State<_DevToolsXpOverridePanel> {
  static const _levelPolicy = ProgressionLevelPolicy();

  late final TextEditingController _xpController;
  int? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _xpController = TextEditingController();
  }

  @override
  void dispose() {
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final canApply = !widget.isBusy && _resolveXp() != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set total XP / level',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Wipes the ledger and inserts a synthetic claimed grant. Profile '
            'becomes exactly the chosen XP. Recalculate Progression after to '
            'evaluate live source data on top.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _xpController,
                  enabled: !widget.isBusy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Total XP',
                    hintText: 'e.g. 25000',
                    border: const OutlineInputBorder(),
                    suffixIcon: _xpController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _xpController.clear();
                                _selectedLevel = null;
                              });
                            },
                          ),
                  ),
                  onChanged: (_) => setState(() {
                    _selectedLevel = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply
                    ? () async {
                        final xp = _resolveXp();
                        if (xp == null) return;
                        await widget.onApply(xp);
                        if (!mounted) return;
                        setState(() {
                          _xpController.clear();
                          _selectedLevel = null;
                        });
                      }
                    : null,
                child: widget.isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Quick set to level',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tier in kProgressionLevelTiers)
                ChoiceChip(
                  label: Text('L${tier.level}'),
                  selected: _selectedLevel == tier.level,
                  onSelected: widget.isBusy
                      ? null
                      : (selected) {
                          if (!selected) return;
                          final xp =
                              _levelPolicy.xpRequiredForLevel(tier.level);
                          setState(() {
                            _selectedLevel = tier.level;
                            _xpController.text = xp.toString();
                          });
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }

  int? _resolveXp() {
    final raw = _xpController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }
}
