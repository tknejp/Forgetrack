import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';

typedef ProgressionLocalizedText = String Function(AppLocalizations l10n);

/// Visual + localized metadata for each progression domain.
///
/// Carrying this on the enum eliminates the parallel switch tables that used
/// to live in presentation-layer lookup helpers and `ProgressionDomainTheme.tokenFor`/
/// `colorFor`/`iconFor`, and `social_profile_utils.socialDomainFor`/
/// `socialIconFor`. Callers read `domain.label(l10n)`, `domain.token`,
/// `domain.color`, `domain.dim`, or `domain.icon` directly.
enum ProgressionDomain {
  steps(
    token: Tokens.steps,
    icon: Icons.directions_walk_rounded,
    label: _domainStepsLabel,
  ),
  nutrition(
    token: Tokens.calories,
    icon: Icons.restaurant_rounded,
    label: _domainNutritionLabel,
  ),
  sleep(
    token: Tokens.sleep,
    icon: Icons.nightlight_round,
    label: _domainSleepLabel,
  ),
  activity(
    token: Tokens.active,
    icon: Icons.bolt_rounded,
    label: _domainActivityLabel,
  ),
  body(
    token: Tokens.weight,
    icon: Icons.monitor_weight_outlined,
    label: _domainBodyLabel,
  );

  const ProgressionDomain({
    required this.token,
    required this.icon,
    required ProgressionLocalizedText label,
  }) : _label = label;

  /// Design-token pairing (color + dim variant) for this domain.
  final Domain token;

  /// Material icon for this domain.
  final IconData icon;

  final ProgressionLocalizedText _label;

  Color get color => token.color;
  Color get dim => token.dim;

  /// Localised display label.
  String label(AppLocalizations l10n) => _label(l10n);
}

String _domainStepsLabel(AppLocalizations l10n) => l10n.progDomainSteps;
String _domainNutritionLabel(AppLocalizations l10n) => l10n.progDomainNutrition;
String _domainSleepLabel(AppLocalizations l10n) => l10n.progDomainSleep;
String _domainActivityLabel(AppLocalizations l10n) => l10n.progDomainActivity;
String _domainBodyLabel(AppLocalizations l10n) => l10n.screenBody;

enum ProgressionMetric {
  steps,
  calories,
  proteinGrams,
  carbsGrams,
  fatGrams,
  fiberGrams,
  sleepMinutes,
  activityMinutes,
  weightKg,
}

enum ProgressionPeriodKind {
  day,
  week,
}

enum ProgressionComparator {
  atLeast,
  atMost,
  betweenInclusive,
  withinRelativeTolerance,
  atLeastRelativeTolerance,
}

enum ProgressionEvaluationStatus {
  achieved,
  missed,
}

enum ProgressionMissReason {
  belowMinimum,
  aboveMaximum,
  outsideAcceptedRange,
}

enum ProgressionRewardStatus {
  unlocked,
  claimed,
}

class ProgressionGoalSet {
  const ProgressionGoalSet({
    required this.dailySteps,
    required this.dailyCalories,
    required this.dailyProteinGrams,
    this.dailyCarbsGrams = 250,
    this.dailyFatGrams = 65,
    this.dailyFiberGrams = 30,
    required this.sleepMinutes,
    required this.weeklyActivityMinutes,
    this.targetWeightKg = 70.0,
  });

  final int dailySteps;
  final double dailyCalories;
  final double dailyProteinGrams;
  final double dailyCarbsGrams;
  final double dailyFatGrams;
  final double dailyFiberGrams;
  final int sleepMinutes;
  final int weeklyActivityMinutes;
  final double targetWeightKg;
}

class ProgressionPeriod {
  const ProgressionPeriod({
    required this.kind,
    required this.start,
    required this.end,
  });

  factory ProgressionPeriod.day(DateTime date) {
    final normalized = progressionDate(date);
    return ProgressionPeriod(
      kind: ProgressionPeriodKind.day,
      start: normalized,
      end: normalized,
    );
  }

  factory ProgressionPeriod.week(DateTime weekStart) {
    final normalized = startOfProgressionWeek(weekStart);
    return ProgressionPeriod(
      kind: ProgressionPeriodKind.week,
      start: normalized,
      end: normalized.add(const Duration(days: 6)),
    );
  }

  final ProgressionPeriodKind kind;
  final DateTime start;
  final DateTime end;

  String get anchorKey => progressionDateKey(start);
}

DateTime progressionDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime startOfProgressionWeek(DateTime value) {
  final normalized = progressionDate(value);
  return normalized
      .subtract(Duration(days: normalized.weekday - DateTime.monday));
}

String progressionDateKey(DateTime value) {
  final normalized = progressionDate(value);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
