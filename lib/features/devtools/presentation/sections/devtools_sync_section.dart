import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/health_connect/application/fitness_provider.dart';
import '../../../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../../application/devtools_sync_logger.dart';
import '../../domain/devtools_sync_event.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_log_list.dart';
import '../widgets/devtools_section_card.dart';

class DevToolsSyncSection extends StatefulWidget {
  const DevToolsSyncSection({super.key});

  @override
  State<DevToolsSyncSection> createState() => _DevToolsSyncSectionState();
}

class _DevToolsSyncSectionState extends State<DevToolsSyncSection> {
  List<DevToolsSyncEvent> _events = [];
  bool _loadingEvents = true;

  bool _syncingHealth = false;
  bool _syncingNutrition = false;
  bool _syncingProgression = false;
  bool _syncingAll = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await DevToolsSyncLogger.instance.getEvents();
    if (mounted) setState(() { _events = events; _loadingEvents = false; });
  }

  Future<void> _clearLog() async {
    await DevToolsSyncLogger.instance.clear();
    if (mounted) setState(() => _events = []);
  }

  Future<void> _syncHealth() async {
    setState(() => _syncingHealth = true);
    try {
      await context.read<FitnessProvider>().refresh();
    } finally {
      if (mounted) {
        setState(() => _syncingHealth = false);
        await _loadEvents();
      }
    }
  }

  Future<void> _syncNutrition() async {
    setState(() => _syncingNutrition = true);
    try {
      await context.read<KalorickeTabulkyProvider>().refresh();
    } finally {
      if (mounted) {
        setState(() => _syncingNutrition = false);
        await _loadEvents();
      }
    }
  }

  Future<void> _syncProgression() async {
    setState(() => _syncingProgression = true);
    try {
      await context.read<ProgressionEngineProvider>().refresh();
    } finally {
      if (mounted) {
        setState(() => _syncingProgression = false);
        await _loadEvents();
      }
    }
  }

  Future<void> _syncAll() async {
    final fitness = context.read<FitnessProvider>();
    final kt = context.read<KalorickeTabulkyProvider>();
    final progression = context.read<ProgressionEngineProvider>();
    setState(() => _syncingAll = true);
    try {
      await fitness.refresh();
      await kt.refresh();
      await progression.refresh();
    } finally {
      if (mounted) {
        setState(() => _syncingAll = false);
        await _loadEvents();
      }
    }
  }

  bool get _anyRunning =>
      _syncingHealth || _syncingNutrition || _syncingProgression || _syncingAll;

  @override
  Widget build(BuildContext context) {
    return DevToolsSectionCard(
      title: 'Sync Diagnostics', // TODO: l10n
      children: [
        DevToolsActionTile(
          label: 'Run Health Sync',
          subtitle: 'FitnessProvider.refresh() — logs stepsBefore/After',
          isLoading: _syncingHealth || _syncingAll,
          isDisabled: _anyRunning,
          onTap: _anyRunning ? null : _syncHealth,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Run Nutrition Sync',
          subtitle: 'KalorickeTabulkyProvider.refresh()',
          isLoading: _syncingNutrition || _syncingAll,
          isDisabled: _anyRunning,
          onTap: _anyRunning ? null : _syncNutrition,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Run Progression Recalc',
          subtitle: 'ProgressionEngineProvider.refresh()',
          isLoading: _syncingProgression || _syncingAll,
          isDisabled: _anyRunning,
          onTap: _anyRunning ? null : _syncProgression,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Run Full Sync',
          subtitle: 'Health → Nutrition → Progression in sequence',
          isLoading: _syncingAll,
          isDisabled: _anyRunning,
          onTap: _anyRunning ? null : _syncAll,
        ),
        const DevToolsSectionDivider(),
        _SyncLogHeader(
          loading: _loadingEvents,
          eventCount: _events.length,
          onRefresh: _loadEvents,
          onClear: _events.isEmpty ? null : _clearLog,
        ),
        const DevToolsSectionDivider(),
        if (_loadingEvents)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          DevToolsLogList(events: _events),
      ],
    );
  }
}

class _SyncLogHeader extends StatelessWidget {
  const _SyncLogHeader({
    required this.loading,
    required this.eventCount,
    required this.onRefresh,
    required this.onClear,
  });

  final bool loading;
  final int eventCount;
  final VoidCallback onRefresh;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
      child: Row(
        children: [
          Text(
            'Sync Log  ($eventCount / 20)', // TODO: l10n
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: loading ? null : onRefresh,
            tooltip: 'Reload log',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: onClear,
              tooltip: 'Clear log',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}
