import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/kaloricke_tabulky_provider.dart';
import '../profile/profile_screen.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<KalorickeTabulkyProvider>(
      builder: (context, kt, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.screenNutrition),
            actions: [
              if (kt.isLoggedIn)
                kt.isRefreshing
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.sync),
                        tooltip: 'Sync',
                        onPressed: () => kt.refresh(),
                      ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          ),
          body: _buildBody(context, kt),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, KalorickeTabulkyProvider kt) {
    if (kt.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!kt.isLoggedIn) {
      return _NotConnectedState(
        onGoToSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      );
    }
    if (kt.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return _NutritionDataView(kt: kt);
  }
}

// ─── Not connected ────────────────────────────────────────────────────────────

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
            Icon(Icons.restaurant_outlined, size: 72, color: cs.onSurfaceVariant),
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

// ─── Nutrition data view ──────────────────────────────────────────────────────

class _NutritionDataView extends StatelessWidget {
  final KalorickeTabulkyProvider kt;

  const _NutritionDataView({required this.kt});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),

        // ── Header + sync time ──────────────────────────────────────────────
        Row(
          children: [
            Text(
              l10n.ktNutritionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (kt.lastSyncedAt != null)
              Text(
                l10n.ktSyncedAt(
                  DateFormat('HH:mm', locale).format(kt.lastSyncedAt!),
                ),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Sync error banner ───────────────────────────────────────────────
        if (kt.syncError != null) ...[
          _ErrorBanner(
            message: l10n.ktSyncError,
            onRetry: () => kt.refresh(),
            retryLabel: l10n.ktRetry,
          ),
          const SizedBox(height: 12),
        ],

        // ── Auth error banner (session expired) ─────────────────────────────
        if (kt.authError != null) ...[
          _ErrorBanner(
            message: kt.authError!,
            onRetry: null,
            retryLabel: null,
          ),
          const SizedBox(height: 12),
        ],

        // ── No diary data yet ───────────────────────────────────────────────
        if (!kt.hasTodayData && kt.syncError == null && kt.authError == null)
          _NoDiaryDataCard()
        else ...[
          // ── Calories card ─────────────────────────────────────────────────
          _CalorieCard(calories: kt.todayCalories),
          const SizedBox(height: 12),

          // ── Macro grid ────────────────────────────────────────────────────
          _MacroGrid(
            protein: kt.todayProtein,
            fat: kt.todayFat,
            carbs: kt.todayCarbs,
            fiber: kt.todayFiber,
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Calorie summary card ─────────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  final double calories;

  const _CalorieCard({required this.calories});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: cs.primary, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${calories.round()} kcal',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                Text(
                  l10n.caloriesConsumed,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Macro 2×2 grid ───────────────────────────────────────────────────────────

class _MacroGrid extends StatelessWidget {
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  const _MacroGrid({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: l10n.macroProtein,
                value: protein,
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MacroCard(
                label: l10n.macroFat,
                value: fat,
                icon: Icons.water_drop_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: l10n.macroCarbs,
                value: carbs,
                icon: Icons.grain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MacroCard(
                label: l10n.macroFiber,
                value: fiber,
                icon: Icons.eco_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: cs.secondary, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${value.round()} g',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No diary data placeholder ────────────────────────────────────────────────

class _NoDiaryDataCard extends StatelessWidget {
  const _NoDiaryDataCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.no_meals, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              l10n.ktNoDiaryData,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
              ),
              onPressed: onRetry,
              child: Text(retryLabel ?? ''),
            ),
        ],
      ),
    );
  }
}
