part of '../home_screen.dart';

class _HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _HomeNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(
                alpha: isDark ? 0.8 : 0.74,
              ),
              border: Border.all(
                color: cs.outlineVariant.withValues(
                  alpha: isDark ? 0.42 : 0.62,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.tokens.subtleShadow.withValues(
                    alpha: isDark ? 0.16 : 0.05,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.navOverview,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.directions_run_outlined),
                  selectedIcon: const Icon(Icons.directions_run),
                  label: l10n.navActivities,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.restaurant_outlined),
                  selectedIcon: const Icon(Icons.restaurant),
                  label: l10n.navNutrition,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.monitor_weight_outlined),
                  selectedIcon: const Icon(Icons.monitor_weight),
                  label: l10n.navBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
