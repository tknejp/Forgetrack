import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../features/progression/domain/progression_models.dart';
import '../features/progression/presentation/progression_provider.dart';
import '../features/progression/presentation/widgets/ft_progression_home_card.dart';
import '../models/selected_period.dart';
import '../providers/auth_provider.dart';
import '../providers/fitness_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/kaloricke_tabulky_provider.dart';
import '../screens/ft_progression_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../theme/ft_design_tokens.dart';
import '../widgets/ft/ft_date_nav.dart';
import '../widgets/ft/ft_macro_row.dart';
import '../widgets/ft/ft_screen_header.dart';
import '../widgets/ft/ft_stat_card.dart';
import '../widgets/ft/ft_tab_pill.dart';

class FtOverviewScreen extends StatefulWidget {
  const FtOverviewScreen({super.key});

  @override
  State<FtOverviewScreen> createState() => _FtOverviewScreenState();
}

class _FtOverviewScreenState extends State<FtOverviewScreen>
    with WidgetsBindingObserver {
  SelectedPeriod _period = SelectedPeriod.today();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FitnessProvider>().initialize(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FitnessProvider>().initialize();
    }
  }

  Future<void> _refresh() async {
    final fitness = context.read<FitnessProvider>();
    final kt = context.read<KalorickeTabulkyProvider>();
    final futures = <Future>[fitness.refresh()];
    if (kt.isLoggedIn) {
      futures.add(kt.refreshRange(_period.start, _period.end));
    }
    await Future.wait(futures);
    if (mounted) {
      await context.read<ProgressionProvider>().refresh();
    }
  }

  Future<void> _openDatePicker() async {
    if (_period.type != PeriodType.day) return;
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _period.referenceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: FtTokens.accent,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _period = SelectedPeriod.forDay(picked));
    }
  }

  String _greeting(String? firstName) {
    final h = DateTime.now().hour;
    final base = h < 12
        ? 'Good morning'
        : h < 18
            ? 'Good afternoon'
            : 'Good evening';
    return '$base${firstName != null ? ', $firstName' : ''} ✦';
  }

  String _monthShort(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];

  String? _dateNavOverride() {
    switch (_period.type) {
      case PeriodType.day:
        return null;
      case PeriodType.week:
        final s = _period.start;
        final e = _period.end;
        return '${s.day} ${_monthShort(s.month)} – ${e.day} ${_monthShort(e.month)}';
      case PeriodType.month:
        return '${_monthShort(_period.referenceDate.month)} ${_period.referenceDate.year}';
      case PeriodType.custom:
        return null;
    }
  }

  void _changeTab(String tab) {
    final type = tab == 'Day'
        ? PeriodType.day
        : tab == 'Week'
            ? PeriodType.week
            : PeriodType.month;
    setState(() => _period = _period.withType(type));
  }

  void _onSwipe(double velocity) {
    if (velocity.abs() < 300) return;
    setState(() {
      if (velocity > 0) {
        _period = _period.backward();
      } else if (_period.canGoForward) {
        _period = _period.forward();
      }
    });
  }

  String _fmtSleep(Duration? d) {
    if (d == null) return '--';
    final h = d.inHours;
    final m = d.inMinutes - h * 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String? _xpLabel(int earnedXp) {
    if (earnedXp <= 0) return null;
    return '+$earnedXp XP';
  }

  double? _weightForSelectedPeriod(FitnessProvider fitness) {
    switch (_period.type) {
      case PeriodType.day:
        return fitness.weightForDate(_period.start)?.weight;
      case PeriodType.week:
        return fitness.weekAvgWeight(_period.start);
      case PeriodType.month:
        return fitness.monthAvgWeight(_period.referenceDate);
      case PeriodType.custom:
        return fitness.monthAvgWeight(_period.referenceDate);
    }
  }

  double? _previousWeightForSelectedPeriod(FitnessProvider fitness) {
    switch (_period.type) {
      case PeriodType.day:
        return fitness.previousWeightBefore(_period.start);
      case PeriodType.week:
        return fitness.weekAvgWeight(
          _period.start.subtract(const Duration(days: 7)),
        );
      case PeriodType.month:
        final ref = _period.referenceDate;
        return fitness.monthAvgWeight(DateTime(ref.year, ref.month - 1, 1));
      case PeriodType.custom:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();
    final auth = context.watch<AuthProvider>();
    final progression = context.watch<ProgressionProvider>();

    final firstName = auth.user?.displayName?.split(' ').firstOrNull;
    final tab = _period.type == PeriodType.week
        ? 'Week'
        : _period.type == PeriodType.month
            ? 'Month'
            : 'Day';
    final stepsXp = progression.summaryForDomainRange(
      domain: ProgressionDomain.steps,
      start: _period.start,
      end: _period.end,
    );
    final nutritionXp = progression.summaryForDomainRange(
      domain: ProgressionDomain.nutrition,
      start: _period.start,
      end: _period.end,
    );
    final sleepXp = progression.summaryForDomainRange(
      domain: ProgressionDomain.sleep,
      start: _period.start,
      end: _period.end,
    );

    // ── Steps ─────────────────────────────────────────────────────────────────
    final steps = _period.type == PeriodType.day
        ? fitness.stepsForDate(_period.start)
        : fitness.stepsAvgForRange(_period.start, _period.end);
    final stepsGoal = goals.dailySteps;
    final stepsProgress =
        stepsGoal > 0 ? (steps / stepsGoal).clamp(0.0, 1.0) : 0.0;
    final stepsLeft = (stepsGoal - steps).clamp(0, stepsGoal);

    // ── Calories ──────────────────────────────────────────────────────────────
    final dayNutrition = kt.nutritionForDate(_period.start);
    final isCurrentDay =
        _period.type == PeriodType.day && _period.isCurrentPeriod;
    final double kcal = _period.type == PeriodType.day
        ? (dayNutrition?.calories ?? (isCurrentDay ? kt.todayCalories : 0.0))
        : (kt.avgCaloriesForRange(_period.start, _period.end) ?? 0.0);
    final kcalGoal = goals.dailyCalories;
    final kcalProgress = kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final kcalDiff = kcal - kcalGoal;
    final kcalPct = kcalGoal > 0 ? ((kcal / kcalGoal) * 100).round() : 0;
    final protein = _period.type == PeriodType.day
        ? (dayNutrition?.protein ?? (isCurrentDay ? kt.todayProtein : 0.0))
        : (kt.avgProteinForRange(_period.start, _period.end) ?? 0.0);
    final fat = _period.type == PeriodType.day
        ? (dayNutrition?.fat ?? (isCurrentDay ? kt.todayFat : 0.0))
        : (kt.avgFatForRange(_period.start, _period.end) ?? 0.0);
    final carbs = _period.type == PeriodType.day
        ? (dayNutrition?.carbs ?? (isCurrentDay ? kt.todayCarbs : 0.0))
        : (kt.avgCarbsForRange(_period.start, _period.end) ?? 0.0);
    final fiber = _period.type == PeriodType.day
        ? (dayNutrition?.fiber ?? (isCurrentDay ? kt.todayFiber : 0.0))
        : (kt.avgFiberForRange(_period.start, _period.end) ?? 0.0);
    final nutritionHasDetails =
        kcal > 0 || protein > 0 || fat > 0 || carbs > 0 || fiber > 0;
    final remainingToTarget = kcalGoal - kcal;

    // ── Weight ────────────────────────────────────────────────────────────────
    final currentWeight = _weightForSelectedPeriod(fitness);
    final prevWeight = _previousWeightForSelectedPeriod(fitness);
    final weightChange = (currentWeight != null && prevWeight != null)
        ? currentWeight - prevWeight
        : null;
    final targetWeight = goals.targetWeight;
    final wHistory = fitness.weightHistory;
    final wMax = wHistory.isNotEmpty
        ? wHistory.map((w) => w.weight).reduce((a, b) => a > b ? a : b)
        : null;
    final wProgress =
        (currentWeight != null && wMax != null && wMax > targetWeight)
            ? ((wMax - currentWeight) / (wMax - targetWeight)).clamp(0.0, 1.0)
            : 0.0;
    final weightPrimaryLabel =
        _period.type == PeriodType.day ? 'Current' : 'Average';
    final weightTrendLabel = _period.type == PeriodType.day
        ? 'Change'
        : _period.type == PeriodType.week
            ? 'Vs prev week'
            : 'Vs prev month';

    // ── Sleep ─────────────────────────────────────────────────────────────────
    final sleep = _period.type == PeriodType.day
        ? fitness.sleepForDate(_period.start)
        : null;
    final avgSleep = _period.type != PeriodType.day
        ? fitness.avgSleepForRange(_period.start, _period.end)
        : null;
    final sleepDuration = sleep?.totalDuration ?? avgSleep;
    final sleepGoalMins = goals.sleepHours * 60;
    final sleepProgress = sleepDuration != null
        ? (sleepDuration.inMinutes / sleepGoalMins).clamp(0.0, 1.0)
        : 0.0;

    final fmt = NumberFormat('#,##0', 'en_US');
    final syncedAt = fitness.lastSyncedAt != null
        ? DateFormat('HH:mm').format(fitness.lastSyncedAt!)
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) => _onSwipe(d.primaryVelocity ?? 0),
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: FtTokens.accent,
        backgroundColor: FtTokens.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            FtScreenHeader(
              greeting: _greeting(firstName),
              title: 'Dashboard',
              onAvatarTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            const SizedBox(height: 10),
            FtTabPill(
              tabs: const ['Day', 'Week', 'Month'],
              active: tab,
              onChange: _changeTab,
            ),
            const SizedBox(height: 10),
            FtDateNav(
              date: _period.referenceDate,
              onPrev: () => setState(() => _period = _period.backward()),
              onNext: _period.canGoForward
                  ? () => setState(() => _period = _period.forward())
                  : null,
              syncedAt: syncedAt,
              labelOverride: _dateNavOverride(),
              onDateTap:
                  _period.type == PeriodType.day ? _openDatePicker : null,
              showTodayButton: !_period.isCurrentPeriod,
              onTodayTap: () =>
                  setState(() => _period = _period.withType(_period.type)),
            ),
            if (fitness.accessState ==
                FitnessAccessState.permissionRequired) ...[
              const SizedBox(height: 10),
              _PermissionBanner(onTap: () => fitness.requestPermissions()),
            ],
            const SizedBox(height: 10),
            FtProgressionCard(
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FtProgressionScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FtStatCard(
              icon: '🥾',
              label: tab == 'Day' ? 'Steps today' : 'Steps · avg/day',
              domain: FtTokens.steps,
              stats: [
                FtStatStat(value: fmt.format(steps), label: 'Steps'),
                FtStatStat(value: fmt.format(stepsGoal), label: 'Goal'),
                FtStatStat(
                  value: tab == 'Day' ? fmt.format(stepsLeft) : '--',
                  label: tab == 'Day' ? 'Left' : '',
                ),
              ],
              progress: stepsProgress,
              badge: '${(stepsProgress * 100).round()}%',
              xp: _xpLabel(stepsXp.earnedXp),
            ),
            const SizedBox(height: 10),
            FtStatCard(
              icon: '🔥',
              label: tab == 'Day' ? 'Calories today' : 'Calories · avg/day',
              domain: FtTokens.calories,
              stats: [
                FtStatStat(
                  value: fmt.format(kcal.round()),
                  label: 'Intake',
                  unit: 'kcal',
                ),
                FtStatStat(
                  value: fmt.format(kcalGoal.round()),
                  label: 'Target',
                  unit: 'kcal',
                ),
                FtStatStat(
                  value:
                      '${kcalDiff >= 0 ? '+' : ''}${fmt.format(kcalDiff.round())}',
                  label: kcalDiff >= 0 ? 'Over' : 'Under',
                  unit: 'kcal',
                ),
              ],
              progress: kcalProgress,
              badge: '$kcalPct%',
              xp: _xpLabel(nutritionXp.earnedXp),
              children: [
                const SizedBox(height: 12),
                if (nutritionHasDetails) ...[
                  FtMacroRow(
                    label: 'Protein',
                    value: protein,
                    goal: goals.dailyProtein,
                    unit: 'g',
                    domain: FtTokens.protein,
                  ),
                  FtMacroRow(
                    label: 'Carbs',
                    value: carbs,
                    goal: goals.dailyCarbs,
                    unit: 'g',
                    domain: FtTokens.carbs,
                  ),
                  FtMacroRow(
                    label: 'Fats',
                    value: fat,
                    goal: goals.dailyFat,
                    unit: 'g',
                    domain: FtTokens.fat,
                    isLast: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NutritionDetailTile(
                          label: 'Fiber',
                          value: '${fiber.toStringAsFixed(0)} g',
                          color: FtTokens.calories.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NutritionDetailTile(
                          label: remainingToTarget >= 0
                              ? 'Remaining'
                              : 'Over target',
                          value: '${remainingToTarget.abs().round()} kcal',
                          color: remainingToTarget >= 0
                              ? FtTokens.calories.color
                              : const Color(0xFFF87171),
                        ),
                      ),
                    ],
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'No nutrition details available for this period yet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: FtTokens.onSurfaceMuted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FtStatCard(
              icon: '⚖️',
              label: 'Weight',
              domain: FtTokens.weight,
              stats: [
                FtStatStat(
                  value: currentWeight?.toStringAsFixed(1) ?? '--',
                  label: weightPrimaryLabel,
                  unit: 'kg',
                ),
                FtStatStat(
                  value: weightChange != null
                      ? '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}'
                      : '--',
                  label: weightTrendLabel,
                  unit: 'kg',
                ),
                FtStatStat(
                  value: targetWeight.toStringAsFixed(1),
                  label: 'Goal',
                  unit: 'kg',
                ),
              ],
              progress: wProgress,
              trophy: true,
            ),
            const SizedBox(height: 10),
            FtStatCard(
              icon: '🌙',
              label: tab == 'Day' ? 'Sleep · last night' : 'Sleep · avg/night',
              domain: FtTokens.sleep,
              stats: [
                FtStatStat(value: _fmtSleep(sleepDuration), label: 'Duration'),
                FtStatStat(
                  value: sleep?.sleepStart != null
                      ? DateFormat('HH:mm').format(sleep!.sleepStart)
                      : '--',
                  label: 'Bedtime',
                ),
                FtStatStat(
                  value: sleep?.wakeTime != null
                      ? DateFormat('HH:mm').format(sleep!.wakeTime)
                      : '--',
                  label: 'Wake',
                ),
              ],
              progress: sleepProgress,
              badge: sleepDuration != null
                  ? '${(sleepProgress * 100).round()}%'
                  : null,
              xp: _xpLabel(sleepXp.earnedXp),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionDetailTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionDetailTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: FtTokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: FtTokens.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FtTokens.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🔗', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Connect Health Connect to sync your activity data',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
            const Text(
              'Allow →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FtTokens.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
