import 'package:flutter/material.dart';

class PlayerPreset {
  const PlayerPreset({
    required this.label,
    required this.level,
    required this.hint,
  });
  final String label;
  final int level;
  final String hint;
}

const playerPresets = <PlayerPreset>[
  PlayerPreset(label: 'Fresh start', level: 1, hint: 'lv 1, no XP'),
  PlayerPreset(label: 'Early game', level: 5, hint: 'lv 5'),
  PlayerPreset(label: 'Mid game', level: 30, hint: 'lv 30'),
  PlayerPreset(label: 'Late game', level: 70, hint: 'lv 70'),
  PlayerPreset(label: 'Endgame', level: 100, hint: 'lv 100'),
];

/// One-tap shortcuts to canonical player states. The pattern was: wipe
/// ledger → set level → claim some quests → advance day. Presets fold
/// that into a single button so a fresh test reaches "Late game"
/// without typing.
class PresetsPanel extends StatelessWidget {
  const PresetsPanel({super.key, required this.busy, required this.onApply});

  final bool busy;
  final Future<void> Function(BuildContext context, PlayerPreset preset)
      onApply;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player presets',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Wipes the ledger and snaps profile.totalXp to the level '
            'threshold. Day offset clears to 0.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in playerPresets)
                ActionChip(
                  label: Text(preset.label),
                  onPressed: busy ? null : () => onApply(context, preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
