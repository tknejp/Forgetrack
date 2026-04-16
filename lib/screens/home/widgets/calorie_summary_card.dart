import 'package:flutter/material.dart';

class CalorieSummaryCard extends StatelessWidget {
  final double consumed;
  final double? burned;
  final double goal;

  const CalorieSummaryCard({
    super.key,
    required this.consumed,
    this.burned,
    this.goal = 2000,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final remaining = goal - consumed + (burned ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Kalorická ikona = energie = brand orange, ne error červená
                Icon(Icons.local_fire_department, color: cs.primary),
                const SizedBox(width: 8),
                Text('Kalorie dnes',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                    label: 'Přijato',
                    value: '${consumed.round()} kcal',
                    // Přijaté kalorie = energetická data = orange
                    color: cs.primary),
                if (burned != null)
                  _StatColumn(
                      label: 'Spáleno',
                      value: '${burned!.round()} kcal',
                      color: cs.primary),
                _StatColumn(
                    label: 'Zbývá',
                    value: '${remaining.round()} kcal',
                    color: remaining >= 0 ? cs.primary : cs.error),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (consumed / goal).clamp(0.0, 1.0),
              minHeight: 6,
              color: consumed > goal ? cs.error : cs.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
