import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../features/health_connect/domain/sleep_record.dart';
import '../../../theme/app_theme.dart';

class SleepCard extends StatefulWidget {
  /// Exact sleep record for day mode.
  final SleepRecord? sleep;

  /// Average sleep duration for week/month mode. Used when [sleep] is null.
  final Duration? avgDuration;

  const SleepCard({super.key, this.sleep, this.avgDuration})
      : assert(sleep != null || avgDuration != null,
            'Provide either sleep or avgDuration');

  @override
  State<SleepCard> createState() => _SleepCardState();
}

class _SleepCardState extends State<SleepCard> {
  bool _expanded = false;

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _fmtTime(DateTime dt, String locale) =>
      DateFormat('HH:mm', locale).format(dt);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final section = tokens.sleep;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final sleep = widget.sleep;
    final duration = sleep?.totalDuration ?? widget.avgDuration!;
    final isAvgMode = sleep == null;

    const goalDuration = Duration(hours: 8);
    final progress =
        (duration.inSeconds / goalDuration.inSeconds).clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          boxShadow: [
            BoxShadow(
              color: tokens.subtleShadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.05,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: isAvgMode ? null : () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: section.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(tokens.tileRadius),
                      ),
                      child: Icon(
                        Icons.bedtime_outlined,
                        color: section.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.sleepTitle,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (!isAvgMode)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: isAvgMode
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: isAvgMode ? l10n.sleepAverage : l10n.sleepDuration,
                      value: _fmtDuration(duration),
                      color: section.accent,
                    ),
                    if (!isAvgMode) ...[
                      _StatColumn(
                        label: l10n.sleepFellAsleep,
                        value: _fmtTime(sleep.sleepStart, locale),
                        color: cs.onSurface,
                      ),
                      _StatColumn(
                        label: l10n.sleepWokeUp,
                        value: _fmtTime(sleep.wakeTime, locale),
                        color: cs.onSurface,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(999),
                  color: section.accent,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                if (!isAvgMode)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailTile(
                                  label: l10n.sleepFellAsleep,
                                  value: _fmtTime(sleep.sleepStart, locale),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DetailTile(
                                  label: l10n.sleepWokeUp,
                                  value: _fmtTime(sleep.wakeTime, locale),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.tileRadius),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
