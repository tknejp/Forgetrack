import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../features/auth/application/auth_provider.dart';
import '../../../../features/health_connect/application/goals_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/section_head.dart';
import '../../../../shared/widgets/top_level_app_bar.dart';
import '../../application/fitness_provider.dart';
import '../hc_state_widgets.dart';
import 'widgets/body_cards.dart';
import 'widgets/sleep_section.dart';

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
            isSignedIn: auth.isSignedIn,
            displayName: auth.user?.displayName,
            email: auth.user?.email,
            sessionStateKey: auth.sessionState.name,
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
              SectionHead(label: l10n.weightTitle, accent: tokens.body.accent),
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
              SectionHead(label: l10n.bodyComposition, accent: tokens.body.accent),
              const SizedBox(height: 8),
              BodyCompositionCard(weight: currentWeight, bodyFat: bodyFat),
            ],

            // ── Weight trend chart ─────────────────────────────────────────
            if (chartPoints.length >= 2) ...[
              const SizedBox(height: 16),
              SectionHead(label: l10n.bodyWeightTrend, accent: tokens.body.accent),
              const SizedBox(height: 8),
              WeightTrendCard(points: chartPoints, locale: locale),
            ],

            // ── Sleep summary ──────────────────────────────────────────────
            if (fitness.sleepHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionHead(label: l10n.sleepTitle, accent: tokens.sleep.accent),
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
