part of '../calories_screen.dart';

class _NutritionStateBody extends StatelessWidget {
  final KalorickeTabulkyProvider kt;

  const _NutritionStateBody({required this.kt});

  @override
  Widget build(BuildContext context) {
    if (kt.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!kt.isLoggedIn) {
      return _NotConnectedState(
        onGoToSettings: () => _openSettings(context),
      );
    }
    if (kt.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _NutritionDataView(kt: kt);
  }
}

class _NotConnectedState extends StatelessWidget {
  final VoidCallback onGoToSettings;

  const _NotConnectedState({required this.onGoToSettings});

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
              Icons.restaurant_outlined,
              size: 72,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.screenNutrition,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ktLoginPrompt,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.ktGoToSettings),
              onPressed: onGoToSettings,
            ),
          ],
        ),
      ),
    );
  }
}
