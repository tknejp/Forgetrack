import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../domain/activity_record.dart';

class WorkoutPermissionCard extends StatelessWidget {
  final VoidCallback onGrant;
  const WorkoutPermissionCard({super.key, required this.onGrant});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.fitness_center_outlined, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              l10n.activitiesWorkoutPermissionTitle,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.activitiesWorkoutPermissionBody,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: Text(l10n.healthGrantAccess),
              onPressed: onGrant,
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutList extends StatelessWidget {
  final List<ActivityRecord> activities;
  final String locale;

  const WorkoutList({super.key, required this.activities, required this.locale});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.fitness_center, size: 40, color: cs.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                context.l10n.activitiesNoWorkouts,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < activities.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            _WorkoutTile(activity: activities[i], locale: locale),
          ],
        ],
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final ActivityRecord activity;
  final String locale;

  const _WorkoutTile({required this.activity, required this.locale});

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return Icons.directions_run;
    if (t.contains('walk')) return Icons.directions_walk;
    if (t.contains('bike') || t.contains('cycling')) return Icons.directions_bike;
    if (t.contains('swim')) return Icons.pool;
    if (t.contains('yoga')) return Icons.self_improvement;
    if (t.contains('strength') || t.contains('weight')) return Icons.fitness_center;
    return Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final section = context.tokens.steps;

    final mins = activity.duration.inMinutes;
    final dateStr = DateFormat('d. M.', locale).format(activity.startTime);
    final timeStr = DateFormat('HH:mm', locale).format(activity.startTime);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: section.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_iconForType(activity.type), color: section.accent, size: 18),
      ),
      title: Text(
        activity.type.replaceAll('_', ' '),
        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$dateStr · $timeStr',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$mins min', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (activity.caloriesBurned != null)
            Text(
              '${activity.caloriesBurned} kcal',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
