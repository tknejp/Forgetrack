part of '../home_screen.dart';

class _HealthUnavailableState extends StatelessWidget {
  final FitnessProvider fitness;

  const _HealthUnavailableState({required this.fitness});

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
            Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.healthNotAvailable,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.healthNotAvailableBody,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.download_outlined),
              label: Text(l10n.healthInstall),
              onPressed: fitness.installHealthConnect,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: fitness.initialize,
              child: Text(l10n.healthRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRequiredState extends StatelessWidget {
  final FitnessProvider fitness;

  const _PermissionRequiredState({required this.fitness});

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
            Icon(
              Icons.lock_outline,
              size: 72,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.healthPermissionRequired,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.healthPermissionBody,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.healthGrantAccess),
              onPressed: fitness.requestPermissions,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorBanner({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: cs.onErrorContainer,
            ),
            onPressed: onRetry,
            child: Text(l10n.healthRetry),
          ),
        ],
      ),
    );
  }
}

class _NoSleepDataCard extends StatelessWidget {
  const _NoSleepDataCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.tokens.sleep.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.bedtime_outlined,
                color: context.tokens.sleep.accent,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sleepTitle,
                  style: tt.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.sleepNoData,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
