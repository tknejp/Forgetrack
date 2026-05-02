import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/cosmetics_provider.dart';
import '../../../../features/cosmetics/domain/cosmetic_models.dart';
import '../../../../features/progression/application/progression_provider.dart';
import '../../../../features/progression/domain/progression_level_config.dart';
import '../../../../features/progression/domain/progression_level_policy.dart';
import '../../../../features/progression/presentation/progression_l10n.dart';
import '../../../../l10n/l10n.dart';
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
  bool _isApplyingOverride = false;
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionProvider>();
    final cosmetics = context.watch<CosmeticsProvider>();
    final cs = Theme.of(context).colorScheme;

    final progL10n = ProgressionL10n(context.l10n);
    final progressionInventoryCount = cosmetics.state?.unlocked.values
            .where((unlock) => _isProgressionCosmeticSource(unlock.sourceType))
            .length ??
        0;
    final isBusy = p.isRefreshing ||
        _isRefreshing ||
        _isApplyingOverride ||
        _isResetting;
    return DevToolsSectionCard(
      title: 'Progression / RPG', // TODO: l10n
      children: [
        DevToolsStatusTile(
          label: 'Level',
          value:
              '${p.profile.level}  (${progL10n.levelTitle(p.profile.level)})',
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
        DevToolsActionTile(
          label: 'Reset progression',
          subtitle:
              'Wipes local Isar + Firestore claims/unlocks/state for the signed-in user',
          isDestructive: true,
          isLoading: _isResetting,
          icon: Icons.delete_forever_rounded,
          onTap: isBusy ? null : _confirmAndReset,
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

  Future<void> _confirmAndReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset progression?'),
        content: const Text(
          'This wipes ALL progression data — evaluations, grants, '
          'achievement unlocks — both locally (Isar) and in Firestore '
          'for the signed-in user. Cannot be undone.',
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResetting = true);
    final provider = context.read<ProgressionProvider>();
    try {
      await provider.devToolsResetProgression();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devtools: progression reset')),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

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
