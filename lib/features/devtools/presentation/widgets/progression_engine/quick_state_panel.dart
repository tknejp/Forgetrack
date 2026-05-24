import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../progression_engine/application/progression_engine_provider.dart';

/// Top-of-page strip: profile vitals (level / XP / day offset / ledger
/// size) + the day-shift controls inline. Putting the clock buttons
/// next to the day-offset readout makes the cause/effect obvious —
/// the number you're nudging is right there.
class QuickStatePanel extends StatelessWidget {
  const QuickStatePanel({super.key, required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressionEngineProvider>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final profile = provider.profile;
    final ledger = provider.ledger;
    final ledgerSize = (ledger?.objectiveCompletions.length ?? 0) +
        (ledger?.nodeCompletions.length ?? 0) +
        (ledger?.nodeClaims.length ?? 0) +
        (ledger?.rewardGrants.length ?? 0) +
        (ledger?.nodeAnnouncements.length ?? 0);
    final dayOffset = provider.devDayOffset;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _StatChip(label: 'LVL', value: '${profile.level}'),
              _StatChip(label: 'XP', value: '${profile.totalXp}'),
              _StatChip(
                label: 'DAY',
                value: dayOffset == 0 ? 'real' : '+$dayOffset',
              ),
              _StatChip(label: 'EVENTS', value: '$ledgerSize'),
              if (provider.pendingCelebrations.isNotEmpty)
                _StatChip(
                  label: 'PENDING',
                  value: '${provider.pendingCelebrations.length}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : () => _advance(context),
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Advance day +1'), // lint-ignore: l10n-literal — devtools, intentionally English
                ),
              ),
              if (dayOffset > 0) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _resetDay(context),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Reset'), // lint-ignore: l10n-literal — devtools, intentionally English
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      busy ? null : () => _pickJoinedAt(context, provider),
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text('Joined: ${_formatDate(provider.joinedAt)}'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    busy ? null : () => _reseedJoinedAt(context, provider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reseed'), // lint-ignore: l10n-literal — devtools, intentionally English
              ),
            ],
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    await provider.devToolsAdvanceDay();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Advanced to day +${provider.devDayOffset}')),
    );
  }

  Future<void> _resetDay(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    await provider.devToolsResetDayOffset();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Day offset reset to 0')), // lint-ignore: l10n-literal — devtools, intentionally English
    );
  }

  Future<void> _pickJoinedAt(
    BuildContext context,
    ProgressionEngineProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.joinedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    await provider.devToolsSetJoinedAt(picked);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Joined date set to ${_formatDate(picked)}')),
    );
  }

  Future<void> _reseedJoinedAt(
    BuildContext context,
    ProgressionEngineProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await provider.devToolsSetJoinedAt(null);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Reseeded joined date to ${_formatDate(provider.joinedAt)}'),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.65),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
