import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity_record.dart';
import '../../providers/fitness_provider.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivity')),
      body: Builder(builder: (context) {
        if (fitness.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (fitness.activities.isEmpty) {
          return const Center(
            child: Text('Za posledních 7 dní nebyly nalezeny žádné aktivity.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: fitness.activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ActivityDetailCard(fitness.activities[i]),
        );
      }),
    );
  }
}

class _ActivityDetailCard extends StatelessWidget {
  final ActivityRecord activity;

  const _ActivityDetailCard(this.activity);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d. M. yyyy, HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(activity.type,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Chip(
                  label: Text('${activity.duration.inMinutes} min'),
                  backgroundColor: cs.primaryContainer,
                  labelStyle: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateFmt.format(activity.startTime),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                if (activity.caloriesBurned != null)
                  _Metric(
                    icon: Icons.local_fire_department,
                    value: '${activity.caloriesBurned} kcal',
                    // Spálené kalorie = energetická data = brand orange
                    color: cs.primary,
                  ),
                if (activity.distanceKm != null)
                  _Metric(
                    icon: Icons.straighten,
                    value: '${activity.distanceKm!.toStringAsFixed(2)} km',
                    // Vzdálenost = komplementární tertiary barva ze seedu
                    color: cs.tertiary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _Metric({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
