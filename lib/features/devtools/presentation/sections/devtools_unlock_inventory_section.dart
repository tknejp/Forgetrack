import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/cosmetics_provider.dart';
import '../../../../features/cosmetics/domain/cosmetic_unlock_snapshot.dart';
import '../../../../features/progression/application/progression_provider.dart';
import '../../../../features/progression/domain/cosmetic_reward_table.dart';
import '../widgets/devtools_section_card.dart';

class DevToolsUnlockInventorySection extends StatefulWidget {
  const DevToolsUnlockInventorySection({super.key});

  @override
  State<DevToolsUnlockInventorySection> createState() =>
      _DevToolsUnlockInventorySectionState();
}

class _DevToolsUnlockInventorySectionState
    extends State<DevToolsUnlockInventorySection> {
  bool _isBusy = false;

  // Snapshot override controllers
  late final TextEditingController _dailyQuestsCtrl;
  late final TextEditingController _weeklyQuestsCtrl;
  late final TextEditingController _totalQuestsCtrl;
  late final TextEditingController _activeDaysCtrl;
  late final TextEditingController _perfectDaysCtrl;
  late final TextEditingController _perfectWeeksCtrl;
  bool _firstDaily = false;
  bool _firstWeekly = false;

  @override
  void initState() {
    super.initState();
    _dailyQuestsCtrl = TextEditingController();
    _weeklyQuestsCtrl = TextEditingController();
    _totalQuestsCtrl = TextEditingController();
    _activeDaysCtrl = TextEditingController();
    _perfectDaysCtrl = TextEditingController();
    _perfectWeeksCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _dailyQuestsCtrl.dispose();
    _weeklyQuestsCtrl.dispose();
    _totalQuestsCtrl.dispose();
    _activeDaysCtrl.dispose();
    _perfectDaysCtrl.dispose();
    _perfectWeeksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionProvider>();
    final cosmetics = context.watch<CosmeticsProvider>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final achievements = p.achievements;
    final cosmeticAchievements = CosmeticRewardTable.achievementToCosmetics;

    return DevToolsSectionCard(
      title: 'Unlock Inventory',
      children: [
        // ── Achievement toggles ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Text(
            'Achievements (cosmetic-relevant)',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        for (final entry in cosmeticAchievements.entries) ...[
          _AchievementToggleTile(
            achievementId: entry.key,
            cosmeticIds: entry.value,
            isUnlocked: achievements
                .any((a) => a.id == entry.key && a.unlocked),
            isBusy: _isBusy,
            onGrant: () => _grantAchievement(entry.key),
          ),
        ],

        const DevToolsSectionDivider(),

        // ── Snapshot override panel ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Snapshot override',
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Injects a fake snapshot into the reveal evaluator without '
                'modifying real progression data. Level is taken from the '
                'current progression state.',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              _SnapshotGrid(
                dailyQuestsCtrl: _dailyQuestsCtrl,
                weeklyQuestsCtrl: _weeklyQuestsCtrl,
                totalQuestsCtrl: _totalQuestsCtrl,
                activeDaysCtrl: _activeDaysCtrl,
                perfectDaysCtrl: _perfectDaysCtrl,
                perfectWeeksCtrl: _perfectWeeksCtrl,
                firstDaily: _firstDaily,
                firstWeekly: _firstWeekly,
                isBusy: _isBusy,
                onFirstDailyChanged: (v) => setState(() => _firstDaily = v),
                onFirstWeeklyChanged: (v) => setState(() => _firstWeekly = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : _clearSnapshot,
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isBusy ? null : () => _applySnapshot(p, cosmetics),
                      child: const Text('Apply snapshot'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _grantAchievement(String achievementId) async {
    setState(() => _isBusy = true);
    try {
      await context
          .read<ProgressionProvider>()
          .devToolsGrantAchievement(achievementId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Granted achievement: $achievementId')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _applySnapshot(
      ProgressionProvider p, CosmeticsProvider cosmetics) {
    final snapshot = CosmeticUnlockSnapshot(
      level: p.profile.level,
      activeDaysCount: int.tryParse(_activeDaysCtrl.text) ?? 0,
      completedDailyQuests: int.tryParse(_dailyQuestsCtrl.text) ?? 0,
      completedWeeklyQuests: int.tryParse(_weeklyQuestsCtrl.text) ?? 0,
      totalCompletedQuests: int.tryParse(_totalQuestsCtrl.text) ?? 0,
      firstDailyQuestEver: _firstDaily,
      firstWeeklyQuestEver: _firstWeekly,
      perfectDaysCount: int.tryParse(_perfectDaysCtrl.text) ?? 0,
      perfectWeeksCount: int.tryParse(_perfectWeeksCtrl.text) ?? 0,
      ownedCosmeticIds:
          cosmetics.state?.unlocked.keys.toSet() ?? const {},
    );
    cosmetics.cacheSnapshot(snapshot);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snapshot applied to reveal evaluator')),
    );
  }

  void _clearSnapshot() {
    _dailyQuestsCtrl.clear();
    _weeklyQuestsCtrl.clear();
    _totalQuestsCtrl.clear();
    _activeDaysCtrl.clear();
    _perfectDaysCtrl.clear();
    _perfectWeeksCtrl.clear();
    setState(() {
      _firstDaily = false;
      _firstWeekly = false;
    });
    context.read<CosmeticsProvider>().cacheSnapshot(
          CosmeticUnlockSnapshot(
            level: 0,
            activeDaysCount: 0,
            completedDailyQuests: 0,
            completedWeeklyQuests: 0,
            totalCompletedQuests: 0,
            firstDailyQuestEver: false,
            firstWeeklyQuestEver: false,
            perfectDaysCount: 0,
            perfectWeeksCount: 0,
            ownedCosmeticIds: const {},
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snapshot cleared')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AchievementToggleTile extends StatelessWidget {
  const _AchievementToggleTile({
    required this.achievementId,
    required this.cosmeticIds,
    required this.isUnlocked,
    required this.isBusy,
    required this.onGrant,
  });

  final String achievementId;
  final List<String> cosmeticIds;
  final bool isUnlocked;
  final bool isBusy;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievementId,
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? Colors.greenAccent
                        : cs.onSurface,
                  ),
                ),
                Text(
                  cosmeticIds.join(', '),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.check_circle_rounded,
                  size: 18, color: Colors.greenAccent),
            )
          else
            TextButton(
              onPressed: isBusy ? null : onGrant,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Grant', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({
    required this.dailyQuestsCtrl,
    required this.weeklyQuestsCtrl,
    required this.totalQuestsCtrl,
    required this.activeDaysCtrl,
    required this.perfectDaysCtrl,
    required this.perfectWeeksCtrl,
    required this.firstDaily,
    required this.firstWeekly,
    required this.isBusy,
    required this.onFirstDailyChanged,
    required this.onFirstWeeklyChanged,
  });

  final TextEditingController dailyQuestsCtrl;
  final TextEditingController weeklyQuestsCtrl;
  final TextEditingController totalQuestsCtrl;
  final TextEditingController activeDaysCtrl;
  final TextEditingController perfectDaysCtrl;
  final TextEditingController perfectWeeksCtrl;
  final bool firstDaily;
  final bool firstWeekly;
  final bool isBusy;
  final ValueChanged<bool> onFirstDailyChanged;
  final ValueChanged<bool> onFirstWeeklyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumField(
                  ctrl: dailyQuestsCtrl,
                  label: 'Daily quests',
                  enabled: !isBusy),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(
                  ctrl: weeklyQuestsCtrl,
                  label: 'Weekly quests',
                  enabled: !isBusy),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumField(
                  ctrl: totalQuestsCtrl,
                  label: 'Total quests',
                  enabled: !isBusy),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(
                  ctrl: activeDaysCtrl,
                  label: 'Active days',
                  enabled: !isBusy),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumField(
                  ctrl: perfectDaysCtrl,
                  label: 'Perfect days',
                  enabled: !isBusy),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(
                  ctrl: perfectWeeksCtrl,
                  label: 'Perfect weeks',
                  enabled: !isBusy),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('First daily ever',
                    style: TextStyle(fontSize: 12)),
                value: firstDaily,
                onChanged: isBusy ? null : (v) => onFirstDailyChanged(v ?? false),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('First weekly ever',
                    style: TextStyle(fontSize: 12)),
                value: firstWeekly,
                onChanged:
                    isBusy ? null : (v) => onFirstWeeklyChanged(v ?? false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.ctrl,
    required this.label,
    required this.enabled,
  });

  final TextEditingController ctrl;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
