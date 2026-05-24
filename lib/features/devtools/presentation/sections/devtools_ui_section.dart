import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/health_connect/application/fitness_provider.dart';
import '../../../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../../features/onboarding/presentation/welcome_screen.dart';
import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';
import '../widgets/devtools_action_tile.dart';

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

class DevToolsUiSection extends StatelessWidget {
  const DevToolsUiSection({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FitnessProvider>();
    final kt = context.watch<KalorickeTabulkyProvider>();
    final p = context.watch<ProgressionEngineProvider>();
    final cs = Theme.of(context).colorScheme;

    final today = DateTime.now();

    // Compare provider state vs what we know about today
    final stepsToday = f.todaySteps;
    final ktToday = kt.hasTodayData;
    final progEvaluated = p.lastEvaluatedAt;

    final progStale = progEvaluated != null &&
        DateTime.now().difference(progEvaluated).inHours > 2;

    return DevToolsSectionCard(
      title: 'UI / Provider Propagation', // TODO: l10n
      children: [
        DevToolsStatusTile(
          label: 'Today (device)',
          value:
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: "Steps for today (provider)",
          value: '$stepsToday',
          valueColor: stepsToday == 0 ? cs.error.withValues(alpha: 0.7) : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: "KT data for today (provider)",
          value: ktToday
              ? '${kt.todayCalories.toStringAsFixed(0)} kcal'
              : 'not loaded',
          valueColor:
              ktToday ? null : cs.error.withValues(alpha: 0.7),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Progression last evaluated',
          value: _fmt(progEvaluated),
          valueColor: progStale ? Colors.orangeAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'HC initialized',
          value: f.hasInitialized ? 'yes' : 'no',
          valueColor:
              f.hasInitialized ? null : cs.error.withValues(alpha: 0.7),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'HC access state',
          value: f.accessState.name,
        ),
        const DevToolsSectionDivider(),
        // kt.loadFromCache() is safe (pure DB read) but does NOT call
        // notifyListeners(), so UI would not update. Use kt.refresh() in Phase 3.
        DevToolsActionTile(
          label: 'Reload KT from local cache',
          subtitle: 'No notifyListeners() — UI update deferred to Phase 3 refresh',
          onTap: null,
          isDisabled: true,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Force Progression refresh',
          subtitle: 'Calls progression.refresh() — no sync log until Phase 3',
          onTap: () => context.read<ProgressionEngineProvider>().refresh(),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Preview onboarding screen',
          subtitle: 'Pushes WelcomeScreen on top — back to dismiss. No state reset.',
          icon: Icons.slideshow_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const WelcomeScreen(),
              fullscreenDialog: true,
            ),
          ),
        ),
      ],
    );
  }
}
