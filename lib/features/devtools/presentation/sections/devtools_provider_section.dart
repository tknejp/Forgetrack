import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/health_connect/application/fitness_provider.dart';
import '../../../../features/health_connect/application/goals_provider.dart';
import '../../../../features/nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../../features/progression/application/progression_provider.dart';
import '../../../progression/domain/policy/level_config.dart';
import '../../../../features/social/application/social_provider.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

String _fmt(DateTime? dt) {
  if (dt == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 5) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class DevToolsProviderSection extends StatelessWidget {
  const DevToolsProviderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FitnessCard(),
        SizedBox(height: 10),
        _KtCard(),
        SizedBox(height: 10),
        _ProgressionCard(),
        SizedBox(height: 10),
        _SocialCard(),
        SizedBox(height: 10),
        _GoalsCard(),
      ],
    );
  }
}

class _FitnessCard extends StatelessWidget {
  const _FitnessCard();

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FitnessProvider>();
    final cs = Theme.of(context).colorScheme;

    final accessLabel = f.accessState.name;
    final accessColor = f.accessState == FitnessAccessState.ready
        ? Colors.greenAccent.shade400
        : f.accessState == FitnessAccessState.unavailable
            ? cs.error
            : null;

    return DevToolsSectionCard(
      title: 'Health Connect', // TODO: l10n
      children: [
        DevToolsStatusTile(
            label: 'Access state', value: accessLabel, valueColor: accessColor),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'HC available',
            value: f.isHealthConnectAvailable ? 'yes' : 'no'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Permissions', value: f.hasPermissions ? 'granted' : 'no'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Initialized', value: f.hasInitialized ? 'yes' : 'no'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Loading / refreshing',
            value: '${f.isLoading} / ${f.isRefreshing}'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(label: 'Last synced', value: _fmt(f.lastSyncedAt)),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Today steps',
            value: '${f.todaySteps}',
            valueColor:
                f.todaySteps == 0 ? cs.error.withValues(alpha: 0.7) : null),
        if (f.errorMessage != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
              label: 'Error', value: f.errorMessage!, valueColor: cs.error),
        ],
      ],
    );
  }
}

class _KtCard extends StatelessWidget {
  const _KtCard();

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final cs = Theme.of(context).colorScheme;

    return DevToolsSectionCard(
      title: 'Kalorické tabulky', // TODO: l10n
      children: [
        DevToolsStatusTile(
          label: 'Logged in',
          value: kt.isLoggedIn ? (kt.loggedInEmail ?? 'yes') : 'no',
          valueColor: kt.isLoggedIn
              ? Colors.greenAccent.shade400
              : cs.error.withValues(alpha: 0.7),
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Initializing / loading / refreshing',
            value:
                '${kt.isInitializing} / ${kt.isLoading} / ${kt.isRefreshing}'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(label: 'Last synced', value: _fmt(kt.lastSyncedAt)),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Has today data',
            value: kt.hasTodayData ? 'yes' : 'no',
            valueColor: kt.hasTodayData
                ? Colors.greenAccent.shade400
                : cs.error.withValues(alpha: 0.7)),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Today kcal / protein',
            value:
                '${kt.todayCalories.toStringAsFixed(0)} kcal / ${kt.todayProtein.toStringAsFixed(0)} g'),
        if (kt.authError != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
              label: 'Auth error', value: kt.authError!, valueColor: cs.error),
        ],
        if (kt.syncError != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
              label: 'Sync error', value: kt.syncError!, valueColor: cs.error),
        ],
      ],
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionProvider>();
    final cs = Theme.of(context).colorScheme;

    return DevToolsSectionCard(
      title: 'Progression', // TODO: l10n
      children: [
        DevToolsStatusTile(
            label: 'Loading / refreshing',
            value: '${p.isLoading} / ${p.isRefreshing}'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Last evaluated', value: _fmt(p.lastEvaluatedAt)),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Level / total XP',
            value: '${p.profile.level} / ${p.profile.totalXp} XP'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Level title',
            value: tierForLevel(p.profile.level).title(context.l10n)),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Quests (total / completed)',
            value: '${p.quests.length} / ${p.completedQuests.length}'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Pending rewards',
            value: '${p.pendingRewards.length}',
            valueColor:
                p.pendingRewards.isNotEmpty ? Colors.orangeAccent : null),
        if (p.error != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
              label: 'Error', value: p.error!, valueColor: cs.error),
        ],
      ],
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SocialProvider>();
    final cs = Theme.of(context).colorScheme;

    return DevToolsSectionCard(
      title: 'Social', // TODO: l10n
      children: [
        DevToolsStatusTile(
            label: 'Ready',
            value: s.isReady ? 'yes' : 'no',
            valueColor: s.isReady ? Colors.greenAccent.shade400 : null),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Backend ready', value: s.backendReady ? 'yes' : 'no'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Unread notifications',
            value: '${s.unreadNotificationCount}'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(label: 'Friends', value: '${s.friends.length}'),
        if (s.backendMessage.isNotEmpty) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
              label: 'Backend message',
              value: s.backendMessage,
              valueColor: cs.onSurfaceVariant),
        ],
        if (s.error != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
              label: 'Error', value: s.error!, valueColor: cs.error),
        ],
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard();

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GoalsProvider>();

    return DevToolsSectionCard(
      title: 'Goals', // TODO: l10n
      children: [
        DevToolsStatusTile(label: 'Daily steps', value: '${g.dailySteps}'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Daily calories', value: '${g.dailyCalories} kcal'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Daily protein', value: '${g.dailyProtein} g'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Target weight', value: '${g.targetWeight} kg'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(label: 'Sleep goal', value: '${g.sleepHours} h'),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
            label: 'Weekly activity', value: '${g.weeklyActivityMins} min'),
      ],
    );
  }
}
