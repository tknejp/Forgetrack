import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../models/sleep_record.dart';

// ─── Public card ──────────────────────────────────────────────────────────────

class SleepCard extends StatefulWidget {
  final SleepRecord sleep;

  const SleepCard({super.key, required this.sleep});

  @override
  State<SleepCard> createState() => _SleepCardState();
}

class _SleepCardState extends State<SleepCard> {
  bool _expanded = false;

  /// Formats a [Duration] as "Xh Ym" (e.g. "7h 42m").
  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Formats a [DateTime] as "HH:mm" using the current locale.
  String _fmtTime(DateTime dt, String locale) =>
      DateFormat('HH:mm', locale).format(dt);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final duration = widget.sleep.totalDuration;
    // Progress toward an 8-hour sleep goal (clamped 0–1).
    const goalDuration = Duration(hours: 8);
    final progress =
        (duration.inSeconds / goalDuration.inSeconds).clamp(0.0, 1.0);
    final goalReached = duration >= goalDuration;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.bedtime_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(l10n.sleepTitle, style: tt.titleMedium),
                  const Spacer(),
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

              // ── Collapsed stats ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: l10n.sleepDuration,
                    value: _fmtDuration(duration),
                    color: cs.primary,
                  ),
                  _StatColumn(
                    label: l10n.sleepFellAsleep,
                    value: _fmtTime(widget.sleep.sleepStart, locale),
                    color: cs.onSurface,
                  ),
                  _StatColumn(
                    label: l10n.sleepWokeUp,
                    value: _fmtTime(widget.sleep.wakeTime, locale),
                    color: cs.onSurface,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Progress bar ─────────────────────────────────────────────
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: goalReached ? cs.tertiary : cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),

              // ── Expanded detail ──────────────────────────────────────────
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
                              value: _fmtTime(
                                widget.sleep.sleepStart,
                                locale,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DetailTile(
                              label: l10n.sleepWokeUp,
                              value: _fmtTime(
                                widget.sleep.wakeTime,
                                locale,
                              ),
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
    );
  }
}

// ─── Shared sub-widgets (mirrors steps_card.dart pattern) ─────────────────────

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
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
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
