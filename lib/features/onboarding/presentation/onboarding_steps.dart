import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/notification_preferences_provider.dart';
import '../../../core/logging/app_log.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../health_connect/application/goals_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../nutrition/application/nutrition_goals_source_provider.dart';
import '../widgets/integration_toggle_row.dart';
import '../widgets/kt_login_sheet.dart';
import '../widgets/onboarding_goal_row.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';
import 'race_picker_view.dart';

// ─── Step 1 — Race picker ────────────────────────────────────────────────

class StepWelcome extends StatelessWidget {
  const StepWelcome({
    super.key,
    required this.draftRaceId,
    required this.onPickRace,
  });

  /// Race id the parent (`WelcomeScreen`) currently has drafted.
  /// Pre-sign-in state — not persisted until the welcome `_finish()`
  /// commit, because `CosmeticsProvider` writes are uid-keyed and
  /// sign-in happens in Step 2.
  final String draftRaceId;

  /// Callback fired when the user taps a race tile. Updates the
  /// parent's draft only; the cosmetics provider trio (selectRace +
  /// unlock + equip) runs in `_finish()` once a uid is bound.
  final ValueChanged<String> onPickRace;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RacePickerView(
        draftRaceId: draftRaceId,
        onPickRace: onPickRace,
        title: l10n.welcomeStep1Title,
        subtitle: l10n.welcomeStep1Subtitle,
        subtitleAccent: l10n.welcomeStep1SubtitleAccent,
        levelLabel: l10n.welcomeStep1HeroPill,
      ),
    );
  }
}
// ─── Step 2 — ÃšÄet ───────────────────────────────────────────────────────

class StepAccount extends StatelessWidget {
  const StepAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifPrefs = context.watch<NotificationPreferencesProvider>();
    final l10n = context.l10n;
    final connected = auth.isSignedIn;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIcon(
            tint: OnboardingTheme.purpleAccent,
            assetPath: 'assets/ui/welcome/shield.png',
          ),
          StepHeading(
            title: l10n.welcomeStep2Title,
            subtitle: l10n.welcomeStep2Subtitle,
          ),
          const SizedBox(height: 22),
          _GoogleSignInButton(
            connected: connected,
            email: auth.user?.email,
            busy: auth.isBusy,
          ),
          const SizedBox(height: 18),
          const _AccountBenefitsCard(),
          const SizedBox(height: 14),
          IntegrationToggleRow(
            title: l10n.welcomeStep4NotifTitle,
            subtitle: l10n.welcomeStep4NotifSubtitle,
            tint: OnboardingTheme.purpleAccent,
            active: notifPrefs.notificationsEnabled,
            icon: '🔔',
            onTap: () => context
                .read<NotificationPreferencesProvider>()
                .setNotificationsEnabled(!notifPrefs.notificationsEnabled),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l10n.welcomeStep2Footnote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: OnboardingTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.connected,
    required this.email,
    required this.busy,
  });

  final bool connected;
  final String? email;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = connected
        ? (email != null
            ? l10n.welcomeStep2GoogleSignedInAs(email!)
            : l10n.welcomeStep2GoogleSignedIn)
        : l10n.welcomeStep2GoogleSignIn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: connected || busy
            ? null
            : () async {
                try {
                  await context.read<AuthProvider>().signIn();
                } catch (e, st) {
                  AppLog.app.error('onboarding: google sign-in failed',
                      err: e, stackTrace: st);
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: connected
                ? OnboardingTheme.green.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: connected
                ? Border.all(
                    color: OnboardingTheme.green.withValues(alpha: 0.45),
                  )
                : null,
            boxShadow: connected ? null : OnboardingTheme.googleButtonShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (connected)
                const Icon(Icons.check_circle_rounded,
                    color: OnboardingTheme.green, size: 20)
              else
                const _GoogleGGlyph(),
              const SizedBox(width: 12),
              Flexible(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: connected
                              ? OnboardingTheme.green
                              : const Color(0xFF1F1F1F),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGGlyph extends StatelessWidget {
  const _GoogleGGlyph();

  @override
  Widget build(BuildContext context) {
    // The asset folder already contains the official 4-color G as SVG —
    // reuse it instead of inlining the path data.
    return SvgPicture.asset(
      'assets/icons/google/google_logo.svg',
      width: 20,
      height: 20,
    );
  }
}

class _AccountBenefitsCard extends StatelessWidget {
  const _AccountBenefitsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      l10n.welcomeStep2Benefit1,
      l10n.welcomeStep2Benefit2,
      l10n.welcomeStep2Benefit3,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(167, 139, 250, 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromRGBO(167, 139, 250, 0.16),
        ),
      ),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: OnboardingTheme.green.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OnboardingTheme.green.withValues(alpha: 0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: OnboardingTheme.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            OnboardingTheme.textPrimary.withValues(alpha: 0.75),
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

// ─── Step 3 — ZdravÃ­ ─────────────────────────────────────────────────────

class StepHealth extends StatefulWidget {
  const StepHealth({super.key});

  @override
  State<StepHealth> createState() => _StepHealthState();
}

class _StepHealthState extends State<StepHealth> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final l10n = context.l10n;
    final connected = fitness.hasPermissions;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIcon(
            tint: OnboardingTheme.teal,
            assetPath: 'assets/ui/welcome/script.png',
          ),
          StepHeading(
            title: l10n.welcomeStep3Title,
            subtitle: l10n.welcomeStep3Subtitle,
          ),
          const SizedBox(height: 22),
          const _DataIconGrid(),
          const SizedBox(height: 18),
          _HealthConnectCta(
            connected: connected,
            busy: _busy,
            onTap: () async {
              setState(() => _busy = true);
              try {
                await context.read<FitnessProvider>().requestPermissions();
              } catch (e, st) {
                AppLog.app.error('onboarding: HC permission failed',
                    err: e, stackTrace: st);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
          const SizedBox(height: 18),
          const _HealthGoals(),
          const SizedBox(height: 12),
          const _HealthPrivacyHint(),
        ],
      ),
    );
  }
}

class _DataIconGrid extends StatelessWidget {
  const _DataIconGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      _DataChip(
          emoji: '👣',
          label: l10n.welcomeStep3DataSteps,
          color: OnboardingTheme.green),
      _DataChip(
          emoji: '🔥',
          label: l10n.welcomeStep3DataCalories,
          color: const Color(0xFFFBBF24)),
      _DataChip(
          emoji: '🌙',
          label: l10n.welcomeStep3DataSleep,
          color: const Color(0xFFA89BFF)),
      _DataChip(
          emoji: '⚔️',
          label: l10n.welcomeStep3DataActivity,
          color: const Color(0xFF2DD4BF)),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({
    required this.emoji,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: OnboardingTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: OnboardingTheme.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthConnectCta extends StatelessWidget {
  const _HealthConnectCta({
    required this.connected,
    required this.busy,
    required this.onTap,
  });

  final bool connected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label =
        connected ? l10n.welcomeStep3CtaConnected : l10n.welcomeStep3Cta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: connected || busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: connected ? null : OnboardingTheme.hcCtaGradient,
            color: connected
                ? OnboardingTheme.green.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: connected
                  ? OnboardingTheme.green.withValues(alpha: 0.45)
                  : const Color.fromRGBO(63, 184, 175, 0.55),
            ),
            boxShadow: connected ? null : OnboardingTheme.hcCtaShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (connected)
                const Icon(Icons.check_circle_rounded,
                    color: OnboardingTheme.green, size: 18)
              else if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (connected || busy) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: connected ? OnboardingTheme.green : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthPrivacyHint extends StatelessWidget {
  const _HealthPrivacyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(167, 139, 250, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(167, 139, 250, 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.shield_outlined,
                size: 14, color: OnboardingTheme.purpleAccent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.welcomeStep3Privacy,
              style: OnboardingTheme.footnote.copyWith(
                color: OnboardingTheme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 4 — Hotovo ─────────────────────────────────────────────────────

class StepFinal extends StatefulWidget {
  const StepFinal({super.key});

  @override
  State<StepFinal> createState() => _StepFinalState();
}

class _StepFinalState extends State<StepFinal> {
  bool _ktBusy = false;

  Future<void> _handleKtTap() async {
    final kt = context.read<KalorickeTabulkyProvider>();
    if (kt.isLoggedIn) {
      setState(() => _ktBusy = true);
      try {
        await kt.logout();
      } finally {
        if (mounted) setState(() => _ktBusy = false);
      }
      return;
    }
    await KTLoginSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final l10n = context.l10n;
    final ktConnected = kt.isLoggedIn;
    final ktSubtitle = ktConnected
        ? (kt.loggedInEmail ?? l10n.welcomeStep4KtConnected)
        : l10n.welcomeStep4KtSubtitle;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIcon(
            tint: OnboardingTheme.gold,
            assetPath: 'assets/ui/welcome/target.png',
          ),
          StepHeading(
            title: l10n.welcomeStep4Title,
            subtitle: l10n.welcomeStep4Subtitle,
          ),
          const SizedBox(height: 12),
          IntegrationToggleRow(
            title: l10n.welcomeStep4KtTitle,
            subtitle: ktSubtitle,
            tint: OnboardingTheme.ktTint,
            active: ktConnected,
            onTap: _handleKtTap,
            iconAsset: 'assets/icons/kt/kaloricke_tabulky.png',
            busy: _ktBusy || kt.isLoading,
          ),
          const SizedBox(height: 18),
          const _NutritionGoals(),
        ],
      ),
    );
  }
}

// ─── Goal-editing blocks (Step 3 health + Step 4 nutrition) ──────────────

/// Left-aligned heading above an onboarding goal group.
class _GoalsHeading extends StatelessWidget {
  const _GoalsHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: OnboardingTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Editable Health Connect goals on Step 3: steps, daily + weekly
/// activity, sleep, and target weight. Always local — HC goals never
/// come from KT.
class _HealthGoals extends StatelessWidget {
  const _HealthGoals();

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsProvider>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final intFmt = NumberFormat.decimalPattern(locale);
    final oneDecimal = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GoalsHeading(l10n.onboardingGoalsHealthHeading),
        OnboardingGoalGroup(
          rows: [
            OnboardingGoalRow(
              icon: Icons.directions_walk_rounded,
              tint: OnboardingTheme.green,
              label: l10n.goalDailySteps,
              valueText: intFmt.format(goals.dailySteps),
              unit: l10n.goalUnitSteps,
              onTap: () => _editIntGoal(
                context,
                title: l10n.goalDailySteps,
                initialValue: goals.dailySteps,
                unit: l10n.goalUnitSteps,
                onSave: (v) => context.read<GoalsProvider>().setDailySteps(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.directions_run_rounded,
              tint: OnboardingTheme.teal,
              label: l10n.goalDailyActivity,
              valueText: intFmt.format(goals.dailyActivityMins),
              unit: l10n.goalUnitMins,
              onTap: () => _editIntGoal(
                context,
                title: l10n.goalDailyActivity,
                initialValue: goals.dailyActivityMins,
                unit: l10n.goalUnitMins,
                onSave: (v) =>
                    context.read<GoalsProvider>().setDailyActivityMins(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.timer_outlined,
              tint: OnboardingTheme.teal,
              label: l10n.goalWeeklyActivity,
              valueText: intFmt.format(goals.weeklyActivityMins),
              unit: l10n.goalUnitMins,
              onTap: () => _editIntGoal(
                context,
                title: l10n.goalWeeklyActivity,
                initialValue: goals.weeklyActivityMins,
                unit: l10n.goalUnitMins,
                onSave: (v) =>
                    context.read<GoalsProvider>().setWeeklyActivityMins(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.bedtime_outlined,
              tint: OnboardingTheme.purpleAccent,
              label: l10n.goalSleepHours,
              valueText: oneDecimal.format(goals.sleepHours),
              unit: l10n.goalUnitHours,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalSleepHours,
                initialValue: goals.sleepHours,
                unit: l10n.goalUnitHours,
                fractionDigits: 1,
                onSave: (v) => context.read<GoalsProvider>().setSleepHours(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.monitor_weight_outlined,
              tint: OnboardingTheme.purpleLight,
              label: l10n.goalTargetWeight,
              valueText: oneDecimal.format(goals.targetWeight),
              unit: l10n.goalUnitKg,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalTargetWeight,
                initialValue: goals.targetWeight,
                unit: l10n.goalUnitKg,
                fractionDigits: 1,
                onSave: (v) => context.read<GoalsProvider>().setTargetWeight(v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Editable nutrition goals on Step 4: calories + macros, plus the #98
/// source toggle. The toggle appears once KT is connected; while the KT
/// source is active the local rows are read-only and display the
/// KT-sourced values `GoalsProvider` already dispatches.
class _NutritionGoals extends StatelessWidget {
  const _NutritionGoals();

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsProvider>();
    final kt = context.watch<KalorickeTabulkyProvider>();
    final sourceProvider = context.watch<NutritionGoalsSourceProvider>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final intFmt = NumberFormat.decimalPattern(locale);

    final usesKt = sourceProvider.usesKt && kt.isLoggedIn;
    final editable = !usesKt;
    String fmt(double v) => intFmt.format(v.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GoalsHeading(l10n.onboardingGoalsNutritionHeading),
        if (kt.isLoggedIn) ...[
          IntegrationToggleRow(
            title: l10n.nutritionGoalsSourceSwitchTitle,
            subtitle: l10n.nutritionGoalsSourceSwitchSubtitle,
            tint: OnboardingTheme.ktTint,
            active: sourceProvider.usesKt,
            iconAsset: 'assets/icons/kt/kaloricke_tabulky.png',
            onTap: () =>
                context.read<NutritionGoalsSourceProvider>().setSource(
                      sourceProvider.usesKt
                          ? NutritionGoalsSource.local
                          : NutritionGoalsSource.kt,
                    ),
          ),
          const SizedBox(height: 8),
          Text(
            usesKt
                ? l10n.nutritionGoalsSourceKtHint
                : l10n.nutritionGoalsSourceOffCaption,
            style: OnboardingTheme.footnote.copyWith(
              color: OnboardingTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
        ],
        OnboardingGoalGroup(
          rows: [
            OnboardingGoalRow(
              icon: Icons.local_fire_department_outlined,
              tint: OnboardingTheme.gold,
              label: l10n.goalDailyCalories,
              valueText: fmt(goals.dailyCalories),
              unit: l10n.goalUnitKcal,
              enabled: editable,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalDailyCalories,
                initialValue: goals.dailyCalories,
                unit: l10n.goalUnitKcal,
                fractionDigits: 0,
                onSave: (v) =>
                    context.read<GoalsProvider>().setDailyCalories(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.fitness_center,
              tint: OnboardingTheme.teal,
              label: l10n.goalDailyProtein,
              valueText: fmt(goals.dailyProtein),
              unit: l10n.goalUnitG,
              enabled: editable,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalDailyProtein,
                initialValue: goals.dailyProtein,
                unit: l10n.goalUnitG,
                fractionDigits: 0,
                onSave: (v) =>
                    context.read<GoalsProvider>().setDailyProtein(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.water_drop_outlined,
              tint: OnboardingTheme.gold,
              label: l10n.goalDailyFat,
              valueText: fmt(goals.dailyFat),
              unit: l10n.goalUnitG,
              enabled: editable,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalDailyFat,
                initialValue: goals.dailyFat,
                unit: l10n.goalUnitG,
                fractionDigits: 0,
                onSave: (v) => context.read<GoalsProvider>().setDailyFat(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.grain,
              tint: OnboardingTheme.purpleAccent,
              label: l10n.goalDailyCarbs,
              valueText: fmt(goals.dailyCarbs),
              unit: l10n.goalUnitG,
              enabled: editable,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalDailyCarbs,
                initialValue: goals.dailyCarbs,
                unit: l10n.goalUnitG,
                fractionDigits: 0,
                onSave: (v) => context.read<GoalsProvider>().setDailyCarbs(v),
              ),
            ),
            OnboardingGoalRow(
              icon: Icons.spa_outlined,
              tint: OnboardingTheme.green,
              label: l10n.goalDailyFiber,
              valueText: fmt(goals.dailyFiber),
              unit: l10n.goalUnitG,
              enabled: editable,
              onTap: () => _editDoubleGoal(
                context,
                title: l10n.goalDailyFiber,
                initialValue: goals.dailyFiber,
                unit: l10n.goalUnitG,
                fractionDigits: 0,
                onSave: (v) => context.read<GoalsProvider>().setDailyFiber(v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Goal edit helpers (dark onboarding value sheet) ─────────────────────

Future<void> _editIntGoal(
  BuildContext context, {
  required String title,
  required int initialValue,
  required String unit,
  required Future<void> Function(int) onSave,
}) async {
  final result = await OnboardingValueSheet.show(
    context,
    title: title,
    initialText: initialValue.toString(),
    unit: unit,
    isDecimal: false,
    saveLabel: context.l10n.goalSave,
  );
  if (result == null) return;
  final parsed = int.tryParse(result.trim());
  if (parsed != null && parsed > 0) await onSave(parsed);
}

Future<void> _editDoubleGoal(
  BuildContext context, {
  required String title,
  required double initialValue,
  required String unit,
  required int fractionDigits,
  required Future<void> Function(double) onSave,
}) async {
  final result = await OnboardingValueSheet.show(
    context,
    title: title,
    initialText: initialValue.toStringAsFixed(fractionDigits),
    unit: unit,
    isDecimal: fractionDigits > 0,
    saveLabel: context.l10n.goalSave,
  );
  if (result == null) return;
  final parsed = double.tryParse(result.replaceAll(',', '.'));
  if (parsed != null && parsed > 0) await onSave(parsed);
}
