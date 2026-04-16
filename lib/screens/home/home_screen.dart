import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calorie_provider.dart';
import '../../providers/fitness_provider.dart';
import '../activities/activities_screen.dart';
import '../calories/calories_screen.dart';
import '../sync/sync_screen.dart';
import 'widgets/activity_card.dart';
import 'widgets/calorie_summary_card.dart';
import 'widgets/steps_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    _DashboardTab(),
    ActivitiesScreen(),
    CaloriesScreen(),
    SyncScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Načti fitness data po startu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FitnessProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Přehled'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center),
              label: 'Aktivity'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'Kalorie'),
          NavigationDestination(
              icon: Icon(Icons.sync_outlined),
              selectedIcon: Icon(Icons.sync),
              label: 'Sync'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final calories = context.watch<CalorieProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgetrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FitnessProvider>().refresh(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (fitness.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (fitness.error != null && !fitness.hasPermission) {
          return _PermissionPrompt(
            message: fitness.error!,
            onRetry: () => context.read<FitnessProvider>().init(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<FitnessProvider>().refresh(),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              StepsCard(
                todaySteps: fitness.todaySteps,
                history: fitness.stepsHistory,
              ),
              const SizedBox(height: 12),
              CalorieSummaryCard(
                consumed: calories.todayKcal,
                burned: fitness.activities.isNotEmpty
                    ? fitness.activities
                        .where((a) => a.caloriesBurned != null)
                        .fold<double>(
                            0, (sum, a) => sum + (a.caloriesBurned ?? 0))
                    : null,
              ),
              const SizedBox(height: 12),
              ActivityCard(activities: fitness.activities),
            ],
          ),
        );
      }),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PermissionPrompt({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety_outlined, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.security),
              label: const Text('Udělit oprávnění'),
            ),
          ],
        ),
      ),
    );
  }
}
