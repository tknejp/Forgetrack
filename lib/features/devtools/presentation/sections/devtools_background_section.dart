import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../core/services/background_sync_service.dart';
import '../../../../features/settings/presentation/dialogs/settings_dialogs.dart';
import '../../application/devtools_provider.dart';
import '../../application/devtools_sync_logger.dart';
import '../../domain/devtools_sync_event.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

String _ago(DateTime? dt) {
  if (dt == null) return 'never';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 5) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m ago';
  return '${diff.inDays}d ago';
}

String _full(DateTime? dt) {
  if (dt == null) return 'never';
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

DevToolsSyncEvent? _latest(List<DevToolsSyncEvent> events,
    {String? source, String? feature}) {
  for (final e in events) {
    if (source != null && e.source != source) continue;
    if (feature != null && e.feature != feature) continue;
    return e; // events are newest-first from DevToolsSyncLogger
  }
  return null;
}

class DevToolsBackgroundSection extends StatefulWidget {
  const DevToolsBackgroundSection({super.key});

  @override
  State<DevToolsBackgroundSection> createState() =>
      _DevToolsBackgroundSectionState();
}

class _DevToolsBackgroundSectionState
    extends State<DevToolsBackgroundSection> {
  List<DevToolsSyncEvent> _events = [];
  bool _loading = true;
  bool _reRegistering = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    final events = await DevToolsSyncLogger.instance.getEvents();
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  Future<void> _reRegister() async {
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: context.l10n.devtoolsBackgroundReregisterTitle,
      message: 'Calls BackgroundSyncService.register() with '
          'ExistingPeriodicWorkPolicy.keep — will not cancel a running task.',
      confirmLabel: 'Re-register',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    setState(() { _reRegistering = true; _statusMsg = null; });
    try {
      await BackgroundSyncService.register();
      if (mounted) {
        setState(() =>
            _statusMsg = 'Re-registered at ${_full(DateTime.now())}');
      }
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _reRegistering = false);
    }
  }

  Future<void> _clearLog() async {
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: context.l10n.devtoolsBackgroundClearLogTitle,
      message:
          'Removes all ${_events.length} events from the DevTools sync log. '
          'Does not affect real app data.',
      confirmLabel: 'Clear',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await DevToolsSyncLogger.instance.clear();
    if (mounted) setState(() { _events = []; _statusMsg = 'Log cleared'; });
  }

  @override
  Widget build(BuildContext context) {
    final devTools = context.watch<DevToolsProvider>();
    final cs = Theme.of(context).colorScheme;

    final canReRegister = devTools.isDebugModeEnabled;

    final lastBg = _latest(_events, source: 'background', feature: 'all');
    final lastHealthFg = _latest(_events, feature: 'health');
    final lastNutritionFg = _latest(_events, feature: 'nutrition');
    final lastProgressionFg = _latest(_events, feature: 'progression');

    final bgStale = lastBg != null &&
        DateTime.now().difference(lastBg.timestamp).inHours >= 1;

    return DevToolsSectionCard(
      title: context.l10n.devtoolsSectionBackground,
      children: [
        // ── Task info ────────────────────────────────────────────────────
        DevToolsStatusTile(
          label: 'Task ID',
          value: BackgroundSyncService.debugTaskId,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Task name',
          value: BackgroundSyncService.debugTaskName,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Configured interval',
          value:
              '${BackgroundSyncService.debugSyncInterval.inMinutes} min',
        ),
        const DevToolsSectionDivider(),
        _NoteRow(
          'Android/WorkManager: minimum periodic interval is 15 min. '
          'Actual execution depends on battery, Doze mode, and OEM restrictions.',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Debug Mode',
          value: devTools.isDebugModeEnabled ? 'ON' : 'OFF',
          valueColor: devTools.isDebugModeEnabled
              ? Colors.greenAccent.shade400
              : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'BG debug notifications',
          value: devTools.isBgDebugNotificationsEnabled ? 'ON' : 'OFF',
          valueColor: devTools.isBgDebugNotificationsEnabled
              ? Colors.greenAccent.shade400
              : null,
        ),
        const DevToolsSectionDivider(),

        // ── Last background sync ─────────────────────────────────────────
        DevToolsStatusTile(
          label: 'Last BG sync  (ago)',
          value: _ago(lastBg?.timestamp),
          valueColor: lastBg == null
              ? cs.error.withValues(alpha: 0.7)
              : bgStale
                  ? Colors.orangeAccent
                  : Colors.greenAccent.shade400,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last BG sync  (timestamp)',
          value: _full(lastBg?.timestamp),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last BG result',
          value: lastBg?.result ?? '—',
          valueColor: lastBg?.result == 'failure' ? cs.error : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last BG duration',
          value: lastBg?.durationMs != null
              ? '${lastBg!.durationMs}ms'
              : '—',
        ),
        if (lastBg?.errorMessage != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Last BG error',
            value: lastBg!.errorMessage!,
            valueColor: cs.error,
          ),
        ],
        const DevToolsSectionDivider(),

        // ── Foreground comparison ────────────────────────────────────────
        DevToolsStatusTile(
          label: 'Last health sync  (fg/manual)',
          value: _ago(lastHealthFg?.timestamp),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last nutrition sync  (fg/manual)',
          value: _ago(lastNutritionFg?.timestamp),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last progression eval',
          value: _ago(lastProgressionFg?.timestamp),
        ),
        const DevToolsSectionDivider(),

        // ── Warnings ─────────────────────────────────────────────────────
        if (lastBg == null) ...[
          _WarnRow(
            '⚠  No background syncs recorded yet',
            color: cs.error.withValues(alpha: 0.8),
          ),
          const DevToolsSectionDivider(),
        ] else if (bgStale) ...[
          _WarnRow(
            '⚠  Last BG sync > 1h ago — WorkManager may be deferring',
            color: Colors.orangeAccent,
          ),
          const DevToolsSectionDivider(),
        ],

        // ── Status message ───────────────────────────────────────────────
        if (_statusMsg != null) ...[
          DevToolsStatusTile(label: 'Status', value: _statusMsg!),
          const DevToolsSectionDivider(),
        ],

        // ── Actions ──────────────────────────────────────────────────────
        DevToolsActionTile(
          label: 'Refresh diagnostics',
          isLoading: _loading,
          isDisabled: _loading,
          onTap: _loading ? null : _loadEvents,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Re-register background sync',
          subtitle: canReRegister
              ? 'ExistingWorkPolicy.keep — will not cancel running task'
              : 'Enable Debug Mode to unlock',
          isDisabled: !canReRegister || _reRegistering,
          isLoading: _reRegistering,
          onTap: canReRegister && !_reRegistering ? _reRegister : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Trigger one-off background task',
          subtitle: 'WorkManager one-off trigger — not yet implemented',
          isDisabled: true,
          onTap: null,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Clear sync log',
          isDestructive: _events.isNotEmpty,
          isDisabled: _events.isEmpty,
          onTap: _events.isNotEmpty ? _clearLog : null,
        ),
      ],
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
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
