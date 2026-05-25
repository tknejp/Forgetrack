part of '../calories_screen.dart';

class _NutritionContentList extends StatelessWidget {
  final KalorickeTabulkyProvider kt;
  final _Period period;
  final _NutritionValues values;
  final double dailyCaloriesGoal;
  final double dailyProteinGoal;
  final double dailyFatGoal;
  final double dailyCarbsGoal;
  final Future<void> Function() onRefresh;
  final ValueChanged<_Period> onPeriodChanged;
  final VoidCallback onOpenGoals;

  const _NutritionContentList({
    required this.kt,
    required this.period,
    required this.values,
    required this.dailyCaloriesGoal,
    required this.dailyProteinGoal,
    required this.dailyFatGoal,
    required this.dailyCarbsGoal,
    required this.onRefresh,
    required this.onPeriodChanged,
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
        children: [
          const SizedBox(height: 16),
          _NutritionStatusBanners(kt: kt),
          _PeriodSelector(
            selected: period,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: 16),
          _NutritionMainSection(
            period: period,
            values: values,
            dailyCaloriesGoal: dailyCaloriesGoal,
            dailyProteinGoal: dailyProteinGoal,
            dailyFatGoal: dailyFatGoal,
            dailyCarbsGoal: dailyCarbsGoal,
            onOpenGoals: onOpenGoals,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NutritionStatusBanners extends StatefulWidget {
  final KalorickeTabulkyProvider kt;

  const _NutritionStatusBanners({required this.kt});

  @override
  State<_NutritionStatusBanners> createState() =>
      _NutritionStatusBannersState();
}

class _NutritionStatusBannersState extends State<_NutritionStatusBanners> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _ensureTickerForCountdown();
  }

  @override
  void didUpdateWidget(covariant _NutritionStatusBanners oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureTickerForCountdown();
  }

  void _ensureTickerForCountdown() {
    final showCountdown = widget.kt.nextReconnectAt != null;
    if (showCountdown && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!showCountdown && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kt = widget.kt;

    if (kt.needsReauth) {
      return Column(
        children: [
          _ErrorBanner(
            message: l10n.ktReauthRequired,
            onRetry: () => KTLoginSheet.show(context),
            retryLabel: l10n.ktReauthCta,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    // Logged-out viewer scrolling cached nutrition data. Soft info
    // banner (cloud_off, muted) — mirrors the home card's offline
    // footer; tap routes to the same KT login sheet.
    if (!kt.isLoggedIn && kt.hasCachedNutrition) {
      return Column(
        children: [
          _InfoBanner(
            message: l10n.ktFooterOfflineHint,
            onTap: () => KTLoginSheet.show(context),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    final nextAt = kt.nextReconnectAt;
    if (nextAt != null) {
      final remaining = nextAt.difference(DateTime.now()).inSeconds;
      final seconds = remaining > 0 ? remaining : 0;
      return Column(
        children: [
          _ErrorBanner(
            message: l10n.ktReconnecting(seconds),
            onRetry: kt.retryNow,
            retryLabel: l10n.ktReconnectTryNow,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    if (kt.syncError == null && kt.authError == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (kt.syncError != null) ...[
          _ErrorBanner(
            message: l10n.ktSyncError,
            onRetry: () => kt.refresh(),
            retryLabel: l10n.ktRetry,
          ),
          const SizedBox(height: 12),
        ],
        if (kt.authError != null) ...[
          _ErrorBanner(
            message: kt.authError!,
            onRetry: null,
            retryLabel: null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NutritionMainSection extends StatelessWidget {
  final _Period period;
  final _NutritionValues values;
  final double dailyCaloriesGoal;
  final double dailyProteinGoal;
  final double dailyFatGoal;
  final double dailyCarbsGoal;
  final VoidCallback onOpenGoals;

  const _NutritionMainSection({
    required this.period,
    required this.values,
    required this.dailyCaloriesGoal,
    required this.dailyProteinGoal,
    required this.dailyFatGoal,
    required this.dailyCarbsGoal,
    required this.onOpenGoals,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAverage = period != _Period.today;
    final hasData = values.calories != null;

    if (!hasData) {
      return period == _Period.today
          ? const _NoDiaryDataCard()
          : _NoHistoryDataCard(message: l10n.nutritionNoHistoryData);
    }

    return Column(
      children: [
        _CalorieCard(
          calories: values.calories,
          goal: dailyCaloriesGoal,
          isAverage: isAverage,
        ),
        const SizedBox(height: 12),
        _MacrosCard(
          protein: values.protein,
          proteinGoal: dailyProteinGoal,
          fat: values.fat,
          fatGoal: dailyFatGoal,
          carbs: values.carbs,
          carbsGoal: dailyCarbsGoal,
          isAverage: isAverage,
        ),
        const SizedBox(height: 12),
        _SecondaryNutrientsCard(
          fiber: values.fiber,
          sugar: values.sugar,
          salt: values.salt,
          saturatedFat: values.saturatedFat,
        ),
        const SizedBox(height: 4),
        _NutritionGoalsShortcut(onPressed: onOpenGoals),
      ],
    );
  }
}

class _NutritionGoalsShortcut extends StatelessWidget {
  final VoidCallback onPressed;

  const _NutritionGoalsShortcut({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        icon: const Icon(Icons.tune, size: 16),
        label: Text(l10n.nutritionGoalsTitle),
        onPressed: onPressed,
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SegmentedButton<_Period>(
      segments: [
        ButtonSegment(value: _Period.today, label: Text(l10n.stepsToday)),
        ButtonSegment(
          value: _Period.sevenDays,
          label: Text(l10n.nutritionPeriod7d),
        ),
        ButtonSegment(
          value: _Period.thirtyDays,
          label: Text(l10n.nutritionPeriod30d),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
    );
  }
}

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

class _NoHistoryDataCard extends StatelessWidget {
  final String message;

  const _NoHistoryDataCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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

/// Soft tap-to-act banner used for the "viewing cached data" state.
/// Visually muted (no error/warning red); mirrors the home card's
/// offline footer styling so the user reads it as an informational
/// affordance, not a failure.
class _InfoBanner extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _InfoBanner({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ft.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}
