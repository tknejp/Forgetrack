import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../providers/fitness_provider.dart';

class HcUnavailableState extends StatelessWidget {
  final FitnessProvider fitness;
  const HcUnavailableState({super.key, required this.fitness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(l10n.healthNotAvailable,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.healthNotAvailableBody,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.healthInstall),
              onPressed: () => fitness.installHealthConnect(),
            ),
          ],
        ),
      ),
    );
  }
}

class HcNoPermissionsState extends StatelessWidget {
  final FitnessProvider fitness;
  const HcNoPermissionsState({super.key, required this.fitness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(l10n.healthPermissionRequired,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.healthPermissionBody,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.shield_outlined),
              label: Text(l10n.healthGrantAccess),
              onPressed: () => fitness.requestPermissions(),
            ),
          ],
        ),
      ),
    );
  }
}
