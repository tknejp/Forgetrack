import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/food_trigger_provider.dart';
import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_collapsible_card.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/progression_engine/daily_goal_chips_panel.dart';
import '../widgets/progression_engine/inspect_panel.dart';
import '../widgets/progression_engine/node_picker_panel.dart';
import '../widgets/progression_engine/presets_panel.dart';
import '../widgets/progression_engine/quick_state_panel.dart';
import '../widgets/progression_engine/xp_level_tabs_panel.dart';

/// Devtools surface for the V2 progression engine.
///
/// **Information architecture.** The page leads with the actions a
/// human actually uses every test session and tucks the rare ones
/// into collapsibles:
///
/// 1. *Quick state* — single status strip (level, XP, day offset,
///    ledger size) + inline day-shift controls. The day knob lands
///    in the most-clicked corner, no scrolling required.
/// 2. *Player presets* — one-tap jumps to canonical save states
///    (Fresh / Early / Mid / Late / Endgame). Replaces what used to
///    be a multi-step "wipe → set level → run evaluation" dance.
/// 3. *Quick claim* — the three claim shortcuts a tester reaches for
///    when running through the daily / chapter flow.
/// 4. *Daily goals* — one chip per daily node, tap-to-satisfy.
/// 5. *XP / level overrides* (collapsible) — set total, add delta,
///    set level. Was three separate panels; now a tabbed panel.
/// 6. *Catalog search* (collapsible) — force-complete any node by id.
/// 7. *Inspect* (collapsible) — ledger counters + last-result
///    diagnostics. Rarely needed mid-test, off by default.
/// 8. *Danger zone* — wipe ledger.
class DevToolsProgressionEngineSection extends StatefulWidget {
  const DevToolsProgressionEngineSection({super.key});

  @override
  State<DevToolsProgressionEngineSection> createState() =>
      _DevToolsProgressionEngineSectionState();
}

class _DevToolsProgressionEngineSectionState
    extends State<DevToolsProgressionEngineSection> {
  bool _isWiping = false;
  bool _isClaiming = false;
  bool _isCompletingDailies = false;
  bool _isCompletingChapter = false;
  bool _isApplyingPreset = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionEngineProvider>();
    final busy = _isWiping ||
        _isClaiming ||
        _isCompletingDailies ||
        _isCompletingChapter ||
        _isApplyingPreset ||
        p.isEvaluating;

    return DevToolsSectionCard(
      title: 'Progression Engine V2',
      children: [
        QuickStatePanel(busy: busy),
        const DevToolsSectionDivider(),
        SwitchListTile(
          value: p.devSuppressCelebrations,
          onChanged: (v) => p.devSuppressCelebrations = v,
          title: const Text('Suppress celebrations'), // lint-ignore: l10n-literal — devtools, intentionally English
          subtitle: const Text(
            'Drops new celebration overlays before they queue. '
            'Use when applying presets / set-level so you don\'t have '
            'to click through every milestone again.',
          ),
          secondary: const Icon(Icons.notifications_off_rounded),
          dense: true,
        ),
        const DevToolsSectionDivider(),
        PresetsPanel(busy: busy, onApply: _applyPreset),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Claim today\'s visible daily quests',
          subtitle:
              'Force-completes the two daily quests currently in the '
              'daily section pool (surprise / active combo / rotation '
              'pick). Other catalog daily atoms untouched.',
          icon: Icons.checklist_rounded,
          isLoading: _isCompletingDailies,
          isDisabled: busy && !_isCompletingDailies,
          onTap: _isCompletingDailies
              ? null
              : () => _completeVisibleDailies(context),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Claim all available quests',
          subtitle:
              'Iterates `pendingClaimNodeIds` and calls engine.claim on '
              'each — XP for every Vyzvednout pill lands at once.',
          icon: Icons.redeem_rounded,
          isLoading: _isClaiming,
          isDisabled: (busy && !_isClaiming) ||
              p.pendingClaimNodeIds.isEmpty,
          onTap: _isClaiming ? null : () => _claimAll(context),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Mark active chapter step as met',
          subtitle:
              'Writes only the chapter step\'s ObjectiveCompletionEvent so '
              'the chapter card surfaces the normal Vyzvednout pill — '
              'tap the pill to fire the real claim flow + celebration.',
          icon: Icons.flag_rounded,
          isLoading: _isCompletingChapter,
          isDisabled: busy && !_isCompletingChapter,
          onTap: _isCompletingChapter
              ? null
              : () => _completeActiveChapterSteps(context),
        ),
        const DevToolsSectionDivider(),
        DailyGoalChipsPanel(isBusy: busy),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DevToolsCollapsibleCard(
            title: 'XP / level overrides',
            subtitle: 'Set total · Add delta · Set level',
            leadingIcon: Icons.bolt_rounded,
            children: [XpLevelTabsPanel(isBusy: busy)],
          ),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DevToolsCollapsibleCard(
            title: 'Catalog search',
            subtitle: 'Find + force-complete any node by id',
            leadingIcon: Icons.search_rounded,
            children: [NodePickerPanel(isBusy: busy)],
          ),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DevToolsCollapsibleCard(
            title: 'Inspect',
            subtitle: 'Ledger counters + last-result diagnostics',
            leadingIcon: Icons.analytics_outlined,
            children: [InspectPanel(provider: p)],
          ),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Wipe V2 ledger',
          subtitle:
              'Clears every progression_engine Isar collection '
              '(including the NodeAnnouncedEvent markers Phase 5 '
              'added). Legacy progression untouched.',
          isDestructive: true,
          icon: Icons.delete_sweep_rounded,
          isLoading: _isWiping,
          isDisabled: busy && !_isWiping,
          onTap: _isWiping ? null : () => _confirmAndWipe(context),
        ),
      ],
    );
  }

  // ── Action handlers ────────────────────────────────────────────────

  Future<void> _confirmAndWipe(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final foodTrigger = context.read<FoodTriggerProvider>();
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe V2 ledger?'), // lint-ignore: l10n-literal — devtools, intentionally English
        content: const Text(
          'Clears every progression_engine Isar collection. '
          'Legacy progression is untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'), // lint-ignore: l10n-literal — devtools, intentionally English
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wipe'), // lint-ignore: l10n-literal — devtools, intentionally English
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWiping = true);
    try {
      await provider.devToolsWipeLedger();
      // The engine ledger holds the *granted* XP; the food-trigger
      // per-day claim totals live in SharedPreferences. Without
      // dropping them here, the pill stays stuck in its claimed
      // state for the rest of the day and the same Monster entry
      // can't be re-tested. Factory reset already wipes prefs
      // wholesale, so this hook is only for the devtools partial
      // wipe path.
      await foodTrigger.devToolsResetClaims();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('V2 ledger wiped')), // lint-ignore: l10n-literal — devtools, intentionally English
      );
    } finally {
      if (mounted) setState(() => _isWiping = false);
    }
  }

  Future<void> _claimAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final pending = provider.pendingClaimNodeIds.toList();
    if (pending.isEmpty) return;

    setState(() => _isClaiming = true);
    var claimed = 0;
    try {
      for (final nodeId in pending) {
        await provider.claimNode(nodeId: nodeId);
        claimed += 1;
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Claimed $claimed quests')),
      );
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Future<void> _completeActiveChapterSteps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final chapters = provider.currentChapterQuests;
    if (chapters.isEmpty) return;

    setState(() => _isCompletingChapter = true);
    var marked = 0;
    try {
      for (final q in chapters) {
        if (q.isCompleted || q.isAvailableForClaim) continue;
        await provider.devToolsMarkObjectiveMet(q.nodeId);
        marked += 1;
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Marked objective met for $marked chapter step(s) — '
            'tap the Vyzvednout pill on the chapter card to claim.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCompletingChapter = false);
    }
  }

  Future<void> _applyPreset(BuildContext context, PlayerPreset preset) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _isApplyingPreset = true);
    try {
      // `setLevel` wipes existing grants and seeds the XP floor for the
      // requested level. We also reset the day offset so presets land
      // on a clean wall-clock today.
      await provider.devToolsResetDayOffset();
      await provider.devToolsSetLevel(preset.level);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Applied preset: ${preset.label}')),
      );
    } finally {
      if (mounted) setState(() => _isApplyingPreset = false);
    }
  }

  Future<void> _completeVisibleDailies(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final visible = provider.currentDailyQuests;
    if (visible.isEmpty) return;

    setState(() => _isCompletingDailies = true);
    var done = 0;
    try {
      for (final q in visible) {
        if (q.isCompleted) continue;
        await provider.devToolsForceCompleteNode(q.nodeId);
        done += 1;
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Force-completed $done visible daily quests')),
      );
    } finally {
      if (mounted) setState(() => _isCompletingDailies = false);
    }
  }
}
