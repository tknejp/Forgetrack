import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/widgets/trend_chart.dart';
import '../../../application/fitness_provider.dart';
import '../../../domain/weight_record.dart';
import 'body_period.dart';

BodyPeriod bodyPeriodForDate(BodyRange range, DateTime date) {
  return BodyPeriod(
    range: range,
    referenceDate: DateTime(date.year, date.month, date.day),
  );
}

String bodyBarLabel(String locale, BodyPeriod period) {
  return switch (period.range) {
    BodyRange.day => DateFormat('d.M.', locale).format(period.start),
    BodyRange.week => DateFormat('d.M.', locale).format(period.start),
    BodyRange.month => DateFormat.MMM(locale).format(period.start),
  };
}

double? averageWeightForPeriod(FitnessProvider fitness, BodyPeriod period) {
  final records = fitness.weightHistoryForRange(period.start, period.end);
  if (records.isEmpty) return null;
  return records.fold<double>(0, (sum, r) => sum + r.weight) / records.length;
}

double? averageBodyFatForPeriod(FitnessProvider fitness, BodyPeriod period) {
  final records = fitness
      .weightHistoryForRange(period.start, period.end)
      .where((r) => r.bodyFat != null)
      .toList();
  if (records.isEmpty) return null;
  return records.fold<double>(0, (s, r) => s + r.bodyFat!) / records.length;
}

double? averageLeanMassForPeriod(FitnessProvider fitness, BodyPeriod period) {
  final records = fitness
      .weightHistoryForRange(period.start, period.end)
      .where((r) => r.bodyFat != null)
      .toList();
  if (records.isEmpty) return null;
  return records.fold<double>(
        0,
        (s, r) => s + r.weight * (1 - r.bodyFat! / 100),
      ) /
      records.length;
}

double? averageBodyWaterForPeriod(FitnessProvider fitness, BodyPeriod period) {
  final records = fitness
      .weightHistoryForRange(period.start, period.end)
      .where((r) => r.bodyWater != null)
      .toList();
  if (records.isEmpty) return null;
  return records.fold<double>(0, (s, r) => s + r.bodyWater!) / records.length;
}

List<WeightPeriodBar> buildWeightBars(
  BuildContext context,
  FitnessProvider fitness,
  BodyPeriod selected,
) {
  final locale = Localizations.localeOf(context).toString();
  // Group weights by period start in a single O(n) pass — no per-record
  // calls to weightHistoryForRange which would make this O(n²).
  final groups = <DateTime, List<double>>{};
  final periodForKey = <DateTime, BodyPeriod>{};
  for (final record in fitness.weightHistory) {
    final period = bodyPeriodForDate(selected.range, record.date);
    groups.putIfAbsent(period.start, () => []).add(record.weight);
    periodForKey[period.start] = period;
  }
  return groups.entries.map((entry) {
    final period = periodForKey[entry.key]!;
    final weights = entry.value;
    final value = selected.range == BodyRange.day
        ? weights.last
        : weights.fold<double>(0, (s, v) => s + v) / weights.length;
    return WeightPeriodBar(
      period: period,
      bar: ChartBar(
        label: bodyBarLabel(locale, period),
        value: value,
        isToday: period == selected,
      ),
    );
  }).toList()
    ..sort((a, b) => a.period.start.compareTo(b.period.start));
}

List<WeightPeriodBar> _buildGroupedBars(
  BuildContext context,
  FitnessProvider fitness,
  BodyPeriod selected,
  double? Function(WeightRecord record) extract,
) {
  final locale = Localizations.localeOf(context).toString();
  final grouped = <DateTime, List<double>>{};
  for (final record in fitness.weightHistory) {
    final value = extract(record);
    if (value == null) continue;
    final period = bodyPeriodForDate(selected.range, record.date);
    grouped.putIfAbsent(period.start, () => []).add(value);
  }
  return grouped.entries.map((entry) {
    final period =
        BodyPeriod(range: selected.range, referenceDate: entry.key);
    final average =
        entry.value.fold<double>(0, (sum, v) => sum + v) / entry.value.length;
    return WeightPeriodBar(
      period: period,
      bar: ChartBar(
        label: bodyBarLabel(locale, period),
        value: average,
        isToday: period == selected,
      ),
    );
  }).toList()
    ..sort((a, b) => a.period.start.compareTo(b.period.start));
}

List<WeightPeriodBar> buildBodyFatBars(
  BuildContext context,
  FitnessProvider fitness,
  BodyPeriod selected,
) =>
    _buildGroupedBars(context, fitness, selected, (r) => r.bodyFat);

List<WeightPeriodBar> buildLeanMassBars(
  BuildContext context,
  FitnessProvider fitness,
  BodyPeriod selected,
) =>
    _buildGroupedBars(context, fitness, selected, (r) {
      final bf = r.bodyFat;
      if (bf == null) return null;
      return r.weight * (1 - bf / 100);
    });

List<WeightPeriodBar> buildBodyWaterBars(
  BuildContext context,
  FitnessProvider fitness,
  BodyPeriod selected,
) =>
    _buildGroupedBars(context, fitness, selected, (r) => r.bodyWater);
