import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../features/health_connect/application/fitness_provider.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

// ─── Formatting helpers ────────────────────────────────────────────────────────

String _dateKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

String _full(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

String _ago(DateTime? dt) {
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 5) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m ago';
  return '${diff.inDays}d ago';
}

// ─── Section ──────────────────────────────────────────────────────────────────

class DevToolsHealthPipelineSection extends StatefulWidget {
  const DevToolsHealthPipelineSection({super.key});

  @override
  State<DevToolsHealthPipelineSection> createState() =>
      _DevToolsHealthPipelineSectionState();
}

class _DevToolsHealthPipelineSectionState
    extends State<DevToolsHealthPipelineSection> {
  bool _running = false;
  String? _statusMsg;
  // Captured post-sync for immediate comparison before next notifyListeners.
  int? _postSyncTodaySteps;
  int? _postSyncDateMatch;
  DateTime? _postSyncAt;

  Future<void> _runAndInspect() async {
    final fitness = context.read<FitnessProvider>();
    setState(() {
      _running = true;
      _statusMsg = null;
      _postSyncTodaySteps = null;
      _postSyncDateMatch = null;
      _postSyncAt = null;
    });
    try {
      await fitness.refresh();
      if (!mounted) return;
      final now = DateTime.now();
      final after = fitness.todaySteps;
      final match = fitness.debugTodayStepsDateMatch;
      setState(() {
        _postSyncTodaySteps = after;
        _postSyncDateMatch = match;
        _postSyncAt = now;
        _statusMsg = 'Sync done: .last=$after  date-match=$match';
      });
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FitnessProvider>();
    final cs = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final todayStepsPos = f.todaySteps;
    final todayStepsMatch = f.debugTodayStepsDateMatch;
    final stepsLastDate = f.debugStepsLastDate;
    final stepsLastKey = stepsLastDate != null ? _dateKey(stepsLastDate) : null;

    // ── Mismatch / anomaly detection ─────────────────────────────────────────
    final hasRecords = f.debugStepsRecordCount > 0;
    final lastDateIsToday = stepsLastKey == todayKey;
    final posMatchMismatch = hasRecords && todayStepsPos != todayStepsMatch;
    final zeroAfterNonZeroFetch = hasRecords &&
        todayStepsPos == 0 &&
        f.debugLastFetchedTodaySteps != null &&
        f.debugLastFetchedTodaySteps! > 0;
    final fetchedNonZeroButAfterZero = f.debugLastFetchedTodaySteps != null &&
        f.debugTodayStepsAfterRefresh != null &&
        f.debugLastFetchedTodaySteps! > 0 &&
        f.debugTodayStepsAfterRefresh! == 0;
    final watcherResultedInZero = f.debugDbWatcherTodaySteps != null &&
        f.debugDbWatcherTodaySteps! == 0 &&
        f.debugLastFetchedTodaySteps != null &&
        f.debugLastFetchedTodaySteps! > 0;
    final watcherBeforeAfterMismatch = f.debugLastDbWatcherFiredAt != null &&
        f.debugDbWatcherTodaySteps != null &&
        f.debugTodayStepsAfterRefresh != null &&
        f.debugDbWatcherTodaySteps! != f.debugTodayStepsAfterRefresh!;
    final postSyncPosMismatch = _postSyncTodaySteps != null &&
        _postSyncDateMatch != null &&
        _postSyncTodaySteps! != _postSyncDateMatch!;

    final preview = f.debugStepRecordsPreview;
    final previewTodayRecords = preview.where((r) => r.dateKey == todayKey).toList(); // lint-ignore: widget-no-logic — devtools today-slice over debug preview
    final duplicateTodayInPreview = previewTodayRecords.length > 1;
    final zeroAndNonZeroToday = previewTodayRecords.isNotEmpty &&
        previewTodayRecords.any((r) => r.steps == 0) &&
        previewTodayRecords.any((r) => r.steps > 0);

    return DevToolsSectionCard(
      title: context.l10n.devtoolsSectionHealthPipeline,
      children: [
        // ── Device clock ─────────────────────────────────────────────────────
        _SubHeader('Device clock'),
        DevToolsStatusTile(
          label: 'Local date key',
          value: todayKey,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Local time',
          value: _full(now),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'TZ offset',
          value: now.timeZoneOffset.isNegative
              ? '-${now.timeZoneOffset.abs().inHours.toString().padLeft(2, "0")}:${(now.timeZoneOffset.abs().inMinutes % 60).toString().padLeft(2, "0")}'
              : '+${now.timeZoneOffset.inHours.toString().padLeft(2, "0")}:${(now.timeZoneOffset.inMinutes % 60).toString().padLeft(2, "0")}',
        ),
        const DevToolsSectionDivider(),

        // ── Current provider state ────────────────────────────────────────────
        _SubHeader('Current provider state'),
        DevToolsStatusTile(
          label: 'todaySteps (.last)',
          value: '$todayStepsPos',
          valueColor: todayStepsPos == 0 && hasRecords
              ? cs.error.withValues(alpha: 0.8)
              : todayStepsPos > 0
                  ? Colors.greenAccent.shade400
                  : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'todaySteps (date-match)',
          value: '$todayStepsMatch',
          valueColor: todayStepsMatch == 0 && hasRecords
              ? cs.error.withValues(alpha: 0.8)
              : todayStepsMatch > 0
                  ? Colors.greenAccent.shade400
                  : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Steps record count',
          value: '${f.debugStepsRecordCount}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last record date',
          value: stepsLastKey ?? '—',
          valueColor: stepsLastKey == null
              ? null
              : lastDateIsToday
                  ? Colors.greenAccent.shade400
                  : Colors.orangeAccent,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'HC last synced',
          value: _ago(f.lastSyncedAt),
        ),
        const DevToolsSectionDivider(),

        // ── Last refresh pipeline ─────────────────────────────────────────────
        _SubHeader('Last refresh pipeline'),
        DevToolsStatusTile(
          label: 'Source',
          value: f.debugLastRefreshSource ?? '—',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Started',
          value: _full(f.debugLastRefreshStartedAt),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Completed',
          value: _full(f.debugLastRefreshCompletedAt),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Duration',
          value: f.debugLastRefreshDurationMs != null
              ? '${f.debugLastRefreshDurationMs}ms'
              : '—',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Query days',
          value: f.debugLastQueryDays != null ? '${f.debugLastQueryDays}' : '—',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Error',
          value: f.debugLastRefreshError ?? 'none',
          valueColor: f.debugLastRefreshError != null ? cs.error : null,
        ),
        const DevToolsSectionDivider(),

        // ── Before / after snapshot ───────────────────────────────────────────
        _SubHeader('Before / after snapshot'),
        DevToolsStatusTile(
          label: 'stepsBefore (.last)',
          value: f.debugTodayStepsBeforeRefresh != null
              ? '${f.debugTodayStepsBeforeRefresh}'
              : '—',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'last record before',
          value: f.debugLastRecordDateBefore != null
              ? '${_dateKey(f.debugLastRecordDateBefore!)}  '
                '${f.debugLastRecordStepsBefore ?? "—"} steps'
              : '—',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'HC fetched today steps',
          value: f.debugLastFetchedTodaySteps != null
              ? '${f.debugLastFetchedTodaySteps}'
              : '—',
          valueColor: f.debugLastFetchedTodaySteps == 0 ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'stepsAfter (.last)',
          value: f.debugTodayStepsAfterRefresh != null
              ? '${f.debugTodayStepsAfterRefresh}'
              : '—',
          valueColor: fetchedNonZeroButAfterZero ? cs.error : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'last record after',
          value: f.debugLastRecordDateAfter != null
              ? '${_dateKey(f.debugLastRecordDateAfter!)}  '
                '${f.debugLastRecordStepsAfter ?? "—"} steps'
              : '—',
        ),
        const DevToolsSectionDivider(),

        // ── DB watcher ────────────────────────────────────────────────────────
        _SubHeader('DB watcher (cross-isolate)'),
        DevToolsStatusTile(
          label: 'Last watcher fired',
          value: _ago(f.debugLastDbWatcherFiredAt),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'todaySteps after watcher',
          value: f.debugDbWatcherTodaySteps != null
              ? '${f.debugDbWatcherTodaySteps}'
              : '—',
          valueColor: watcherResultedInZero ? cs.error : null,
        ),
        const DevToolsSectionDivider(),

        // ── Last 5 records ────────────────────────────────────────────────────
        _SubHeader('Last 5 step records (oldest→newest)'),
        if (preview.isEmpty)
          _NoteRow('No step records in memory.')
        else
          for (final r in preview) ...[
            DevToolsStatusTile(
              label: r.dateKey,
              value: '${r.steps} steps',
              valueColor: r.dateKey == todayKey && r.steps == 0
                  ? cs.error.withValues(alpha: 0.8)
                  : r.dateKey == todayKey && r.steps > 0
                      ? Colors.greenAccent.shade400
                      : null,
            ),
            if (r != preview.last) const DevToolsSectionDivider(),
          ],
        const DevToolsSectionDivider(),

        // ── Post-sync inspect result ──────────────────────────────────────────
        if (_postSyncAt != null) ...[
          _SubHeader('Run + Inspect result  (${_full(_postSyncAt)})'),
          DevToolsStatusTile(
            label: 'todaySteps (.last)',
            value: '${_postSyncTodaySteps ?? "—"}',
            valueColor: _postSyncTodaySteps == 0 ? cs.error : Colors.greenAccent.shade400,
          ),
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'todaySteps (date-match)',
            value: '${_postSyncDateMatch ?? "—"}',
            valueColor: _postSyncDateMatch == 0 ? cs.error : Colors.greenAccent.shade400,
          ),
          const DevToolsSectionDivider(),
          if (postSyncPosMismatch) ...[
            _WarnRow(
              '⚠  Post-sync mismatch: .last=$_postSyncTodaySteps  '
              'date-match=$_postSyncDateMatch',
              color: cs.error,
            ),
            const DevToolsSectionDivider(),
          ],
        ],

        // ── Warnings ──────────────────────────────────────────────────────────
        if (posMatchMismatch) ...[
          _WarnRow(
            '⚠  Position mismatch: .last=$todayStepsPos  '
            'date-match=$todayStepsMatch — last record may not be today',
            color: Colors.orangeAccent,
          ),
          const DevToolsSectionDivider(),
        ],
        if (zeroAfterNonZeroFetch) ...[
          _WarnRow(
            '⚠  HC fetched ${f.debugLastFetchedTodaySteps} for today but '
            'todaySteps = 0 — data may have been overwritten after refresh',
            color: cs.error,
          ),
          const DevToolsSectionDivider(),
        ],
        if (fetchedNonZeroButAfterZero) ...[
          _WarnRow(
            '⚠  HC fetch returned ${f.debugLastFetchedTodaySteps} but '
            'stepsAfter = ${f.debugTodayStepsAfterRefresh} — '
            'step data was zero immediately after _fetchFromHC()',
            color: cs.error,
          ),
          const DevToolsSectionDivider(),
        ],
        if (watcherResultedInZero) ...[
          _WarnRow(
            '⚠  DB watcher fired → todaySteps became 0, but HC had '
            '${f.debugLastFetchedTodaySteps} — '
            'in-memory DB cache is stale after cross-isolate write',
            color: cs.error,
          ),
          const DevToolsSectionDivider(),
        ],
        if (watcherBeforeAfterMismatch) ...[
          _WarnRow(
            '⚠  DB watcher result (${f.debugDbWatcherTodaySteps}) ≠ '
            'stepsAfterRefresh (${f.debugTodayStepsAfterRefresh}) — '
            'DB watcher overrode refresh result',
            color: Colors.orangeAccent,
          ),
          const DevToolsSectionDivider(),
        ],
        if (duplicateTodayInPreview) ...[
          _WarnRow(
            '⚠  Multiple records for $todayKey in last-5 preview',
            color: cs.error,
          ),
          const DevToolsSectionDivider(),
        ],
        if (zeroAndNonZeroToday) ...[
          _WarnRow(
            '⚠  Today ($todayKey) has both 0 and non-zero records in preview',
            color: cs.error,
          ),
          const DevToolsSectionDivider(),
        ],

        // ── Status ────────────────────────────────────────────────────────────
        if (_statusMsg != null) ...[
          DevToolsStatusTile(label: 'Status', value: _statusMsg!),
          const DevToolsSectionDivider(),
        ],

        // ── Action ────────────────────────────────────────────────────────────
        DevToolsActionTile(
          label: 'Run Health Sync + Inspect',
          subtitle: _running
              ? 'Running…'
              : 'Runs refresh() and captures before/after diagnostics',
          isLoading: _running,
          isDisabled: _running || f.isRefreshing,
          onTap: (!_running && !f.isRefreshing) ? _runAndInspect : null,
        ),
      ],
    );
  }
}

// ─── Local helpers ────────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.label);
  final String label;

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

class _NoteRow extends StatelessWidget {
  const _NoteRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _WarnRow extends StatelessWidget {
  const _WarnRow(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
