import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../../shared/widgets/stat_components.dart';
import '../../../domain/sleep_record.dart';

class SleepSummaryCard extends StatelessWidget {
  final SleepRecord? todaySleep;
  final List<SleepRecord> sleepHistory;
  final String locale;

  const SleepSummaryCard({
    super.key,
    required this.todaySleep,
    required this.sleepHistory,
    required this.locale,
  });

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _fmtTime(DateTime dt) => DateFormat('HH:mm', locale).format(dt);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final section = context.tokens.sleep;
    final l10n = context.l10n;
    final recentHistory =
        sleepHistory.length > 7 ? sleepHistory.sublist(0, 7) : sleepHistory;

    final totalSec =
        recentHistory.fold(0, (s, r) => s + r.totalDuration.inSeconds);
    final avg7d = Duration(seconds: (totalSec / recentHistory.length).round());
    final minDur = recentHistory
        .map((r) => r.totalDuration)
        .reduce((a, b) => a < b ? a : b);
    final maxDur = recentHistory
        .map((r) => r.totalDuration)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (todaySleep != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatColumn(
                    label: l10n.sleepDuration,
                    value: _fmtDuration(todaySleep!.totalDuration),
                    color: section.accent,
                  ),
                  StatColumn(
                    label: l10n.sleepFellAsleep,
                    value: _fmtTime(todaySleep!.sleepStart),
                    color: cs.onSurface,
                  ),
                  StatColumn(
                    label: l10n.sleepWokeUp,
                    value: _fmtTime(todaySleep!.wakeTime),
                    color: cs.onSurface,
                  ),
                ],
              ),
            ] else ...[
              Text(
                l10n.sleepNoData,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: StatDetailTile(
                        label: l10n.sleepAvg7Day, value: _fmtDuration(avg7d))),
                const SizedBox(width: 8),
                Expanded(
                    child: StatDetailTile(
                        label: l10n.weightMin, value: _fmtDuration(minDur))),
                const SizedBox(width: 8),
                Expanded(
                    child: StatDetailTile(
                        label: l10n.weightMax, value: _fmtDuration(maxDur))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
