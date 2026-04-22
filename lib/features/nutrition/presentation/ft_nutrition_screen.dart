import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/selected_period.dart';
import '../../../providers/goals_provider.dart';
import '../../../screens/profile/profile_screen.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_date_nav.dart';
import '../../../widgets/ft/ft_macro_row.dart';
import '../../../widgets/ft/ft_plain_card.dart';
import '../../../widgets/ft/ft_screen_header.dart';
import '../../../widgets/ft/ft_stat_card.dart';
import '../../../widgets/ft/ft_tab_pill.dart';
import '../application/kaloricke_tabulky_provider.dart';

class FtNutritionScreen extends StatefulWidget {
  const FtNutritionScreen({super.key});

  @override
  State<FtNutritionScreen> createState() => _FtNutritionScreenState();
}

class _FtNutritionScreenState extends State<FtNutritionScreen> {
  SelectedPeriod _period = SelectedPeriod.today();

  // TODO: connect meals card to real nutrition entries source
  static const _meals = [
    (name: 'BREAKFAST', time: '08:14', kcal: 642, emoji: '🍳'),
    (name: 'LUNCH', time: '12:48', kcal: 1124, emoji: '🍱'),
    (name: 'SNACK', time: '15:30', kcal: 312, emoji: '🍙'),
    (name: 'DINNER', time: '19:22', kcal: 1243, emoji: '🍜'),
  ];

  String _monthShort(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

  String _tab() => _period.type == PeriodType.week
      ? 'Week'
      : _period.type == PeriodType.month
          ? 'Month'
          : 'Day';

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final goals = context.watch<GoalsProvider>();

    if (!kt.isLoggedIn) {
      return _NotConnectedState(
        onConnect: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      );
    }

    final tab = _tab();

    final double kcal;
    final double protein;
    final double fat;
    final double carbs;
    if (_period.type == PeriodType.day) {
      final day = kt.nutritionForDate(_period.start);
      kcal = day?.calories ?? kt.todayCalories;
      protein = day?.protein ?? kt.todayProtein;
      fat = day?.fat ?? kt.todayFat;
      carbs = day?.carbs ?? kt.todayCarbs;
    } else {
      kcal = kt.avgCaloriesForRange(_period.start, _period.end) ?? 0;
      protein = kt.avgProteinForRange(_period.start, _period.end) ?? 0;
      fat = kt.avgFatForRange(_period.start, _period.end) ?? 0;
      carbs = kt.avgCarbsForRange(_period.start, _period.end) ?? 0;
    }

    final kcalGoal = goals.dailyCalories;
    final kcalDiff = kcal - kcalGoal;
    final kcalProgress =
        kcalGoal > 0 ? (kcal / kcalGoal).clamp(0.0, 1.0) : 0.0;
    final kcalPct = kcalGoal > 0 ? ((kcal / kcalGoal) * 100).round() : 0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) => _onSwipe(d.primaryVelocity ?? 0),
      child: RefreshIndicator(
        onRefresh: () => kt.refresh(),
        color: FtTokens.accent,
        backgroundColor: FtTokens.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            const FtScreenHeader(greeting: 'Fuel up ✦', title: 'Nutrition'),
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
              labelOverride: _dateNavOverride(),
              showTodayButton: !_period.isCurrentPeriod,
              onTodayTap: () =>
                  setState(() => _period = _period.withType(_period.type)),
            ),
            if (kt.syncError != null) ...[
              const SizedBox(height: 10),
              _SyncErrorBanner(
                message: kt.syncError!,
                onRetry: () => kt.refreshRange(_period.start, _period.end),
              ),
            ],
            const SizedBox(height: 10),
            FtStatCard(
              icon: '🔥',
              label: tab == 'Day' ? 'Calories today' : 'Calories · avg/day',
              domain: FtTokens.calories,
              stats: [
                FtStatStat(
                  value: kcal.round().toString(),
                  label: 'Intake',
                  unit: 'kcal',
                ),
                FtStatStat(
                  value: kcalGoal.round().toString(),
                  label: 'Target',
                  unit: 'kcal',
                ),
                FtStatStat(
                  value: '${kcalDiff >= 0 ? '+' : ''}${kcalDiff.round()}',
                  label: kcalDiff >= 0 ? 'Over' : 'Under',
                  unit: 'kcal',
                ),
              ],
              progress: kcalProgress,
              badge: '$kcalPct%',
              children: [
                const SizedBox(height: 10),
                const Divider(color: Color(0x12FFFFFF), thickness: 1, height: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'MACROS',
                      style: TextStyle(
                        fontSize: FtTokens.fontSizeCaption,
                        fontWeight: FontWeight.w700,
                        color: Color(0x80FFFFFF),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'red = over goal',
                      style: TextStyle(
                        fontSize: FtTokens.fontSizeMicro,
                        color: FtTokens.onSurfaceFaint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FtMacroRow(
                  label: 'Protein',
                  value: protein,
                  goal: goals.dailyProtein,
                  unit: 'g',
                  domain: FtTokens.protein,
                ),
                FtMacroRow(
                  label: 'Fat',
                  value: fat,
                  goal: goals.dailyFat,
                  unit: 'g',
                  domain: FtTokens.fat,
                ),
                FtMacroRow(
                  label: 'Carbs',
                  value: carbs,
                  goal: goals.dailyCarbs,
                  unit: 'g',
                  domain: FtTokens.carbs,
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            FtPlainCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        "TODAY'S MEALS",
                        style: TextStyle(
                          fontSize: FtTokens.fontSizeCaption,
                          fontWeight: FontWeight.w700,
                          color: Color(0x80FFFFFF),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+ Log meal',
                        style: TextStyle(
                          fontSize: FtTokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                          color: FtTokens.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < _meals.length; i++)
                    _MealRow(
                      name: _meals[i].name,
                      time: _meals[i].time,
                      kcal: _meals[i].kcal,
                      emoji: _meals[i].emoji,
                      isLast: i == _meals.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SyncErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Retry →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF87171),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotConnectedState extends StatelessWidget {
  final VoidCallback onConnect;
  const _NotConnectedState({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FtScreenHeader(greeting: 'Fuel up ✦', title: 'Nutrition'),
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Kaloricke Tabulky not connected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect your KT account in Profile to\nsee nutrition data here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: FtTokens.onSurfaceMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onConnect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: FtTokens.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Connect in Profile →',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String name;
  final String time;
  final int kcal;
  final String emoji;
  final bool isLast;

  const _MealRow({
    required this.name,
    required this.time,
    required this.kcal,
    required this.emoji,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: FtTokens.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: FtTokens.calories.dim,
              borderRadius: BorderRadius.circular(FtTokens.radiusIcon),
              border: Border.all(
                color: FtTokens.calories.color.withValues(alpha: 0.27),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xEBFFFFFF),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: FtTokens.fontSizeMicro,
                    color: FtTokens.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text: '$kcal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: FtTokens.calories.color,
              ),
              children: [
                TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    fontSize: FtTokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: FtTokens.calories.color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
