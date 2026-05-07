import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/dashboard_card_assets.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../application/fitness_provider.dart';
import '../domain/activity_record.dart';

/// Detail view for a single [ActivityRecord]: hero stats, metadata, a
/// comparison chart against recent same-type activities, and a placeholder
/// for a GPS map (the current data layer doesn't expose route points).
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final ActivityRecord activity;

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final type = activity.type;
    final emoji = _emojiFor(type);
    final typeLabel = _formatType(type);
    final dateFmt = DateFormat('EEE d MMM · HH:mm', locale);
    final timeFmt = DateFormat('HH:mm', locale);

    final duration = activity.duration;
    final kcal = activity.caloriesBurned;
    final distance = activity.distanceKm;
    final hasDistance = distance != null && distance > 0.05;
    // Pace = minutes per km. Only meaningful when we have both distance > 0
    // and a non-zero duration.
    final paceMinPerKm = hasDistance && duration.inSeconds > 0
        ? duration.inSeconds / 60 / distance
        : null;

    return Scaffold(
      backgroundColor: Tokens.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: ScreenHeader(
                  greeting: '',
                  title: l10n.activityDetailTitle,
                  leading: Navigator.of(context).canPop()
                      ? const FtBackButton()
                      : null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                child: _buildContent(
                  context,
                  fitness: fitness,
                  l10n: l10n,
                  emoji: emoji,
                  typeLabel: typeLabel,
                  dateFmt: dateFmt,
                  timeFmt: timeFmt,
                  duration: duration,
                  kcal: kcal,
                  distance: distance,
                  hasDistance: hasDistance,
                  paceMinPerKm: paceMinPerKm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required FitnessProvider fitness,
    required AppLocalizations l10n,
    required String emoji,
    required String typeLabel,
    required DateFormat dateFmt,
    required DateFormat timeFmt,
    required Duration duration,
    required int? kcal,
    required double? distance,
    required bool hasDistance,
    required double? paceMinPerKm,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Hero card — primary stats ─────────────────────────────────────
        StatCard(
          icon: emoji,
          label: '$typeLabel · ${dateFmt.format(activity.startTime)}',
          domain: Tokens.active,
          visualAssets: DashboardCardAssetResolver.forKind(
            DashboardCardKind.activity,
          ),
          initiallyExpanded: true,
          collapsible: false,
          stats: [
            StatStat(
              value: _formatDuration(duration),
              label: l10n.sleepDuration,
            ),
            StatStat(
              value: kcal != null ? '$kcal' : '--',
              label: l10n.activitiesActiveCalories,
              unit: 'kcal',
            ),
            StatStat(
              value: hasDistance ? distance!.toStringAsFixed(2) : '--',
              label: l10n.activityDetailDistance,
              unit: 'km',
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Metadata card — start, end, pace ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: Tokens.active.cardDecoration(),
          child: Column(
            children: [
              _DetailRow(
                label: l10n.activityDetailStart,
                value: timeFmt.format(activity.startTime),
              ),
              _DetailRow(
                label: l10n.activityDetailEnd,
                value: timeFmt.format(activity.endTime),
              ),
              if (paceMinPerKm != null)
                _DetailRow(
                  label: l10n.activityDetailPace,
                  value: '${_formatPace(paceMinPerKm)} /km',
                  isLast: true,
                ),
              if (paceMinPerKm == null)
                _DetailRow(
                  label: l10n.activitiesActiveCalories,
                  value: kcal != null ? '$kcal kcal' : '--',
                  isLast: true,
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Comparison chart — last 10 same-type activities ───────────────
        _ComparisonCard(
          title: l10n.activityDetailComparison,
          subtitle: typeLabel,
          current: activity,
          fitness: fitness,
        ),

        const SizedBox(height: 10),

        // ── Map placeholder (GPS data not currently exposed by data layer) ──
        // TODO: render an actual map polyline once HC GPS routes are wired.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
          decoration: Tokens.steps.cardDecoration(),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.map_rounded,
                  size: 32,
                  color: Tokens.onSurfaceMuted,
                ),
                const SizedBox(height: Tokens.spaceSm),
                Text(
                  l10n.activityDetailNoMap,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Tokens.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Formatting helpers ────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '${m}m';
    final h = d.inHours;
    final rest = m - h * 60;
    return '${h}h ${rest.toString().padLeft(2, '0')}m';
  }

  String _formatPace(double minPerKm) {
    final whole = minPerKm.floor();
    final secs = ((minPerKm - whole) * 60).round();
    return "$whole:${secs.toString().padLeft(2, '0')}";
  }

  String _formatType(String hcType) => hcType
      .split('_')
      .map(
        (w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');

  String _emojiFor(String hcType) {
    final t = hcType.toUpperCase();
    if (t.contains('WALK')) return '🚶';
    if (t.contains('RUN') || t.contains('JOG')) return '🏃';
    if (t.contains('CYCL') || t.contains('BIKE')) return '🚴';
    if (t.contains('SWIM')) return '🏊';
    if (t.contains('HIKE') || t.contains('TRAIL')) return '🥾';
    if (t.contains('YOGA') || t.contains('MEDIT')) return '🧘';
    return '⚔';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: ft.divider)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ft.onSurfaceMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ft.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini-trend that compares the current activity to the most recent N
/// activities of the same Health-Connect type. Bar value is duration in
/// minutes. The current activity is highlighted via [ChartBar.isToday].
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.fitness,
  });

  final String title;
  final String subtitle;
  final ActivityRecord current;
  final FitnessProvider fitness;

  static const _maxBars = 10;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    final sameType = fitness.activities
        .where((a) =>
            a.type.toUpperCase() == current.type.toUpperCase() &&
            !a.endTime.isAfter(current.endTime))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final slice = sameType.length > _maxBars
        ? sameType.sublist(sameType.length - _maxBars)
        : sameType;

    final bars = slice.map((a) {
      final isCurrent = a.startTime == current.startTime &&
          a.endTime == current.endTime;
      return ChartBar(
        label: DateFormat('d.M.', locale).format(a.startTime),
        value: a.duration.inMinutes.toDouble(),
        isToday: isCurrent,
      );
    }).toList();

    return TrendCard(
      domain: Tokens.active,
      icon: Icons.bar_chart_rounded,
      title: title,
      subtitle: subtitle,
      collapsible: false,
      metrics: const [],
      bars: bars,
      relativeScale: false,
      emptyLabel: '—',
      expandable: bars.length > 4,
    );
  }
}
