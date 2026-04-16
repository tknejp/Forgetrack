import 'package:flutter/material.dart';
import '../../../models/activity_record.dart';

class ActivityCard extends StatelessWidget {
  final List<ActivityRecord> activities;

  const ActivityCard({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Aktivity (7 dní)',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (activities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Žádné aktivity za posledních 7 dní.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...activities.take(3).map((a) => _ActivityTile(activity: a)),
            if (activities.length > 3)
              Text(
                '+ ${activities.length - 3} dalších',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityRecord activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: Icon(_iconForType(activity.type),
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(activity.type),
      subtitle: Text('${activity.duration.inMinutes} min'
          '${activity.distanceKm != null ? ' · ${activity.distanceKm!.toStringAsFixed(1)} km' : ''}'
          '${activity.caloriesBurned != null ? ' · ${activity.caloriesBurned} kcal' : ''}'),
      dense: true,
    );
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return Icons.directions_run;
    if (t.contains('walk')) return Icons.directions_walk;
    if (t.contains('cycl') || t.contains('bike')) return Icons.directions_bike;
    if (t.contains('swim')) return Icons.pool;
    return Icons.sports;
  }
}
