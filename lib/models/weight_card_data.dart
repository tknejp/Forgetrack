import 'package:flutter/foundation.dart';

import 'selected_period.dart';

enum WeightChartMode { daily, weekly, monthly }

/// A single data point for the weight chart.
@immutable
class WeightChartPoint {
  final DateTime date;
  final double weight;

  const WeightChartPoint({required this.date, required this.weight});
}

/// Pre-computed data for WeightCard, assembled by the metrics layer so the
/// widget itself contains no business logic.
@immutable
class WeightCardData {
  final PeriodType periodType;

  /// Primary displayed value.
  /// - Day   → measurement for that day (null if none recorded)
  /// - Week  → average weight across the week
  /// - Month → average weight across the month
  final double? mainValue;

  /// Change vs the previous comparable period.
  /// - Day   → vs previous measurement (any day before)
  /// - Week  → avg(this week) − avg(prev week)
  /// - Month → avg(this month) − avg(prev month)
  /// null when comparison data is unavailable.
  final double? trendValue;

  final double goalWeight;

  // ── Day mode only ─────────────────────────────────────────────────────────
  final double? bodyFatPercent;

  // ── Week / Month mode only ────────────────────────────────────────────────
  final double? periodMin;
  final double? periodMax;

  // ── Chart ─────────────────────────────────────────────────────────────────
  final List<WeightChartPoint> chartPoints;
  final WeightChartMode chartMode;

  const WeightCardData({
    required this.periodType,
    required this.mainValue,
    required this.trendValue,
    required this.goalWeight,
    this.bodyFatPercent,
    this.periodMin,
    this.periodMax,
    required this.chartPoints,
    required this.chartMode,
  });

  bool get hasData => mainValue != null;
}
