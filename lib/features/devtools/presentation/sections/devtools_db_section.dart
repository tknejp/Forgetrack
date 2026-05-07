import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/health_connect/application/fitness_provider.dart';
import '../../../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../../features/progression/application/progression_provider.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

String _fmt(DateTime? dt) {
  if (dt == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _dateKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

class DevToolsDbSection extends StatefulWidget {
  const DevToolsDbSection({super.key});

  @override
  State<DevToolsDbSection> createState() => _DevToolsDbSectionState();
}

class _DevToolsDbSectionState extends State<DevToolsDbSection> {
  // Captured at build / refresh time so DateTime.now() is consistent within a render.
  DateTime _lastRefresh = DateTime.now();

  void _refresh() => setState(() => _lastRefresh = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FitnessProvider>();
    final kt = context.watch<KalorickeTabulkyProvider>();
    final p = context.watch<ProgressionProvider>();
    final cs = Theme.of(context).colorScheme;

    final now = _lastRefresh;
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final todayKey = _dateKey(today);

    // ── Health diagnostics ─────────────────────────────────────────────────
    final stepsFirst = f.debugStepsFirstDate;
    final stepsLast = f.debugStepsLastDate;
    final stepsLastKey = stepsLast != null ? _dateKey(stepsLast) : null;
    final stepsLastIsToday = stepsLastKey == todayKey;

    final todayStepsViaPosition = f.todaySteps;
    final todayStepsViaMatch = f.stepsForDate(today);
    final yesterdaySteps = f.stepsForDate(yesterday);

    final hasRecords = f.debugStepsRecordCount > 0;
    final warnStaleLastDate = hasRecords && !stepsLastIsToday;
    final warnZeroToday = hasRecords && stepsLastIsToday && todayStepsViaPosition == 0;
    final warnPositionMismatch =
        todayStepsViaPosition != todayStepsViaMatch && hasRecords;

    // ── Nutrition diagnostics ──────────────────────────────────────────────
    final ktFirstKey = kt.debugNutritionFirstDateKey;
    final ktLastKey = kt.debugNutritionLastDateKey;
    final ktLastIsToday = ktLastKey == todayKey;
    final warnKtLastNotToday =
        kt.debugNutritionCacheCount > 0 && !ktLastIsToday;

    return DevToolsSectionCard(
      title: 'Local DB / Cache', // TODO: l10n
      children: [
        // ── Health Connect ─────────────────────────────────────────────────
        _SectionHeaderRow(
          label: 'Health Connect',
          onRefresh: _refresh,
        ),
        DevToolsStatusTile(
          label: 'Steps records in memory',
          value: '${f.debugStepsRecordCount}',
          valueColor: f.debugStepsRecordCount == 0
              ? cs.error.withValues(alpha: 0.7)
              : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Steps first date',
          value: stepsFirst != null ? _dateKey(stepsFirst) : '—',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Steps last date',
          value: stepsLastKey ?? '—',
          valueColor: stepsLastKey == null
              ? null
              : stepsLastIsToday
                  ? Colors.greenAccent.shade400
                  : Colors.orangeAccent,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Device date key (local)',
          value: todayKey,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Today steps  (via .last)',
          value: '$todayStepsViaPosition',
          valueColor: todayStepsViaPosition == 0 && hasRecords
              ? cs.error.withValues(alpha: 0.7)
              : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Today steps  (via date match)',
          value: '$todayStepsViaMatch',
          valueColor: todayStepsViaMatch == 0 && hasRecords
              ? cs.error.withValues(alpha: 0.7)
              : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Yesterday steps  (date match)',
          value: '$yesterdaySteps',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Weight records',
          value: '${f.debugWeightRecordCount}  '
              '(${f.debugWeightFirstDate != null ? _dateKey(f.debugWeightFirstDate!) : "—"}'
              ' → '
              '${f.debugWeightLastDate != null ? _dateKey(f.debugWeightLastDate!) : "—"})',
          valueColor: f.debugWeightRecordCount == 0
              ? cs.error.withValues(alpha: 0.7)
              : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Weight w/ bodyFat in-record',
          value: '${f.debugWeightWithBodyFatCount} / ${f.debugWeightRecordCount}',
          valueColor: f.debugWeightWithBodyFatCount == 0 &&
                  f.debugWeightRecordCount > 0
              ? Colors.orangeAccent
              : f.debugWeightWithBodyFatCount > 0
                  ? Colors.greenAccent.shade400
                  : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Latest bodyFat (meta)',
          value: f.latestBodyFat != null
              ? '${f.latestBodyFat!.toStringAsFixed(1)} %'
              : '—',
          valueColor: f.latestBodyFat != null
              ? Colors.greenAccent.shade400
              : cs.error.withValues(alpha: 0.7),
        ),
        const DevToolsSectionDivider(),
        _WeightRecordsPreview(records: f.debugWeightRecordsPreview),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Sleep / Activities',
          value: '${f.debugSleepRecordCount} / ${f.debugActivitiesCount}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'HC last synced',
          value: _fmt(f.lastSyncedAt),
        ),
        if (warnStaleLastDate) ...[
          const DevToolsSectionDivider(),
          _WarningTile(
            '⚠  Last step date $stepsLastKey ≠ today $todayKey — cache is stale',
            color: Colors.orangeAccent,
          ),
        ],
        if (warnZeroToday) ...[
          const DevToolsSectionDivider(),
          _WarningTile(
            '⚠  Today steps = 0 despite ${f.debugStepsRecordCount} records — HC returned 0 for today',
            color: cs.error,
          ),
        ],
        if (warnPositionMismatch) ...[
          const DevToolsSectionDivider(),
          _WarningTile(
            '⚠  Position mismatch: .last=$todayStepsViaPosition  date-match=$todayStepsViaMatch',
            color: Colors.orangeAccent,
          ),
        ],
        const DevToolsSectionDivider(),

        // ── Kalorické tabulky ──────────────────────────────────────────────
        _SubHeader(label: 'Kalorické tabulky'),
        DevToolsStatusTile(
          label: 'Cached day records',
          value: '${kt.debugNutritionCacheCount}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'First / Last cached date',
          value: ktFirstKey != null
              ? '$ktFirstKey  →  ${ktLastKey ?? '—'}'
              : '—',
          valueColor: warnKtLastNotToday ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: "Today's data in cache",
          value: kt.hasTodayData
              ? '${kt.todayCalories.toStringAsFixed(0)} kcal / '
                  '${kt.todayProtein.toStringAsFixed(0)} g protein'
              : 'none',
          valueColor: kt.hasTodayData
              ? Colors.greenAccent.shade400
              : cs.error.withValues(alpha: 0.7),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'KT last synced',
          value: _fmt(kt.lastSyncedAt),
        ),
        if (warnKtLastNotToday) ...[
          const DevToolsSectionDivider(),
          _WarningTile(
            '⚠  Last KT cache date $ktLastKey ≠ today $todayKey',
            color: Colors.orangeAccent,
          ),
        ],
        const DevToolsSectionDivider(),

        // ── Progression ────────────────────────────────────────────────────
        _SubHeader(label: 'Progression'),
        DevToolsStatusTile(
          label: 'Last evaluated',
          value: _fmt(p.lastEvaluatedAt),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Level / Total XP',
          value: '${p.profile.level} / ${p.profile.totalXp} XP',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Quests / Achievements',
          value: '${p.quests.length} / ${p.achievements.length}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Pending rewards',
          value: '${p.pendingRewards.length}',
          valueColor: p.pendingRewards.isNotEmpty ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),

        // ── Cache actions ──────────────────────────────────────────────────
        _SubHeader(label: 'Cache actions'),
        DevToolsActionTile(
          label: 'Clear Health cache',
          subtitle: 'Requires HealthDatabase.clearAll() — not yet implemented',
          onTap: null,
          isDisabled: true,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Clear KT cache',
          subtitle: 'Requires KtNutritionDatabase.clearAll() — not yet implemented',
          onTap: null,
          isDisabled: true,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Clear Progression cache',
          subtitle: 'Requires ProgressionDatabase.clearAll() — not yet implemented',
          onTap: null,
          isDisabled: true,
        ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({required this.label, required this.onRefresh});

  final String label;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 2),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.8,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            onPressed: onRefresh,
            tooltip: 'Refresh diagnostics',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String label;
  const _SubHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile(this.message, {required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _WeightRecordsPreview extends StatelessWidget {
  const _WeightRecordsPreview({required this.records});

  final List<({String dateKey, double kg, double? fatPct})> records;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
        child: Text(
          'Weight records preview  —  (none)',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST ${records.length} WEIGHT RECORDS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          for (final r in records)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Text(
                    r.dateKey,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r.kg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.fatPct != null
                        ? '${r.fatPct!.toStringAsFixed(1)} % fat'
                        : 'no fat',
                    style: TextStyle(
                      fontSize: 12,
                      color: r.fatPct != null
                          ? Colors.greenAccent.shade400
                          : Colors.orangeAccent,
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
