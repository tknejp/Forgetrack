import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hc_state_widgets.dart';
import '../../widgets/stat_display.dart';
import '../../widgets/top_level_app_bar.dart';
import 'widgets/body_cards.dart';
import 'widgets/sleep_section.dart';

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FitnessProvider>(
      builder: (context, fitness, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: TopLevelAppBar(
            title: context.l10n.screenBody,
            subtitle: buildTopLevelHeaderSubtitle(
              context,
              syncCopy: AppHeaderSyncCopy.health,
              syncedAt: fitness.lastSyncedAt,
            ),
          ),
          body: _buildBody(context, fitness),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FitnessProvider fitness) {
    switch (fitness.accessState) {
      case FitnessAccessState.checking:
        return const Center(child: CircularProgressIndicator());
      case FitnessAccessState.unavailable:
        return HcUnavailableState(fitness: fitness);
      case FitnessAccessState.permissionRequired:
        return HcNoPermissionsState(fitness: fitness);
      case FitnessAccessState.ready:
        break;
    }
    if (fitness.weightHistory.isEmpty && fitness.sleepHistory.isEmpty) {
      return _NoDataState(fitness: fitness);
    }
    return RefreshIndicator(
      onRefresh: () => fitness.refresh(),
      child: _BodyContent(fitness: fitness),
    );
  }
}

// ─── No data state ────────────────────────────────────────────────────────────

class _NoDataState extends StatelessWidget {
  final FitnessProvider fitness;
  const _NoDataState({required this.fitness});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: () => fitness.refresh(),
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_weight_outlined,
                    size: 64, color: cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(l10n.bodyNoData,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main content (composition layer) ────────────────────────────────────────

class _BodyContent extends StatelessWidget {
  final FitnessProvider fitness;
  const _BodyContent({required this.fitness});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, goals, _) {
        final locale = Localizations.localeOf(context).toString();
        final tokens = context.tokens;
        final l10n = context.l10n;

        final currentWeight = fitness.latestWeight;
        final bodyFat = fitness.latestBodyFat;

        final today = DateTime.now();
        final change30d = fitness
            .weightMetricsForRange(
              DateTime(today.year, today.month, today.day)
                  .subtract(const Duration(days: 29)),
              today,
            )
            .trend;

        final chartPoints = fitness.dailyWeightChart(30);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            // ── Weight summary ─────────────────────────────────────────────
            if (currentWeight != null) ...[
              SectionHeader(l10n.weightTitle,
                  icon: Icons.monitor_weight_outlined,
                  color: tokens.body.accent),
              const SizedBox(height: 8),
              WeightSummaryCard(
                currentWeight: currentWeight,
                change30d: change30d,
                targetWeight: goals.targetWeight,
              ),
            ],

            // ── Body composition ───────────────────────────────────────────
            if (bodyFat != null && currentWeight != null) ...[
              const SizedBox(height: 16),
              SectionHeader(l10n.bodyComposition,
                  icon: Icons.pie_chart_outline, color: tokens.body.accent),
              const SizedBox(height: 8),
              BodyCompositionCard(weight: currentWeight, bodyFat: bodyFat),
            ],

            // ── Weight trend chart ─────────────────────────────────────────
            if (chartPoints.length >= 2) ...[
              const SizedBox(height: 16),
              SectionHeader(l10n.bodyWeightTrend,
                  icon: Icons.show_chart, color: tokens.body.accent),
              const SizedBox(height: 8),
              WeightTrendCard(points: chartPoints, locale: locale),
            ],

            // ── Sleep summary ──────────────────────────────────────────────
            if (fitness.sleepHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionHeader(l10n.sleepTitle,
                  icon: Icons.bedtime_outlined, color: tokens.sleep.accent),
              const SizedBox(height: 8),
              SleepSummaryCard(
                todaySleep: fitness.todaySleep,
                sleepHistory: fitness.sleepHistory,
                locale: locale,
              ),
            ],
          ],
        );
      },
    );
  }
}
