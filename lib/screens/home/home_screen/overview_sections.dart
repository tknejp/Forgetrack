part of '../home_screen.dart';

class _OverviewScrollableContent extends StatelessWidget {
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider kt;
  final SelectedPeriod period;
  final ValueChanged<SelectedPeriod> onPeriodChanged;
  final _ResolvedOverviewMetrics metrics;
  final double dailyCaloriesGoal;
  final double dailyProteinGoal;
  final double dailyFatGoal;
  final double dailyCarbsGoal;

  const _OverviewScrollableContent({
    required this.fitness,
    required this.kt,
    required this.period,
    required this.onPeriodChanged,
    required this.metrics,
    required this.dailyCaloriesGoal,
    required this.dailyProteinGoal,
    required this.dailyFatGoal,
    required this.dailyCarbsGoal,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 300) {
            return;
          }

          final updated = velocity > 0 ? period.backward() : period.forward();
          if (updated != period) {
            onPeriodChanged(updated);
          }
        },
        child: RefreshIndicator(
          key: ValueKey(period),
          onRefresh: () => _refreshOverview(fitness, kt, period),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
            children: [
              const SizedBox(height: 16),
              _PeriodHeader(
                period: period,
                locale: locale,
                onPeriodChanged: onPeriodChanged,
              ),
              _OverviewStatusBanners(
                fitness: fitness,
                kt: kt,
                period: period,
              ),
              const SizedBox(height: 16),
              _OverviewSummaryCards(
                period: period,
                metrics: metrics,
                dailyCaloriesGoal: dailyCaloriesGoal,
                dailyProteinGoal: dailyProteinGoal,
                dailyFatGoal: dailyFatGoal,
                dailyCarbsGoal: dailyCarbsGoal,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewStatusBanners extends StatelessWidget {
  final FitnessProvider fitness;
  final KalorickeTabulkyProvider kt;
  final SelectedPeriod period;

  const _OverviewStatusBanners({
    required this.fitness,
    required this.kt,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (fitness.errorMessage == null && (!kt.isLoggedIn || kt.syncError == null)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (fitness.errorMessage != null) ...[
          const SizedBox(height: 10),
          _InlineErrorBanner(
            icon: Icons.error_outline,
            message: l10n.healthSyncFailed,
            onRetry: fitness.refresh,
          ),
        ],
        if (kt.isLoggedIn && kt.syncError != null) ...[
          const SizedBox(height: 10),
          _InlineErrorBanner(
            icon: Icons.restaurant_menu,
            message: kt.syncError!,
            onRetry: () => kt.refreshRange(period.start, period.end),
          ),
        ],
      ],
    );
  }
}

class _OverviewSummaryCards extends StatelessWidget {
  final SelectedPeriod period;
  final _ResolvedOverviewMetrics metrics;
  final double dailyCaloriesGoal;
  final double dailyProteinGoal;
  final double dailyFatGoal;
  final double dailyCarbsGoal;

  const _OverviewSummaryCards({
    required this.period,
    required this.metrics,
    required this.dailyCaloriesGoal,
    required this.dailyProteinGoal,
    required this.dailyFatGoal,
    required this.dailyCarbsGoal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDay = period.type == PeriodType.day;

    return Column(
      children: [
        StepsCard(
          todaySteps: metrics.stepsValue,
          goal: metrics.stepsGoal,
          history: metrics.stepsChartHistory,
          mainLabel: isDay ? l10n.stepsCurrent : l10n.stepsAverage,
        ),
        const SizedBox(height: 12),
        CalorieSummaryCard(
          consumed: metrics.consumedCalories,
          burned: metrics.caloriesBurned,
          goal: dailyCaloriesGoal,
          protein: metrics.protein ?? 0,
          fat: metrics.fat ?? 0,
          carbs: metrics.carbs ?? 0,
          fiber: metrics.fiber ?? 0,
          proteinGoal: dailyProteinGoal,
          fatGoal: dailyFatGoal,
          carbsGoal: dailyCarbsGoal,
          title: isDay ? null : l10n.caloriesAvgPerDay,
        ),
        const SizedBox(height: 12),
        WeightCard(data: metrics.weightCard),
        const SizedBox(height: 12),
        _OverviewSleepSection(metrics: metrics),
      ],
    );
  }
}

class _OverviewSleepSection extends StatelessWidget {
  final _ResolvedOverviewMetrics metrics;

  const _OverviewSleepSection({required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.sleep != null) {
      return SleepCard(sleep: metrics.sleep);
    }
    if (metrics.avgSleep != null) {
      return SleepCard(avgDuration: metrics.avgSleep);
    }
    return const _NoSleepDataCard();
  }
}
