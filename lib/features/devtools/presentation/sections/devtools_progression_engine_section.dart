import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../../../../features/progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/quest_display_bucket.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_collapsible_card.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

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
///
/// "Run V2 evaluation (ambitious-player input)" was removed — that
/// tile sent a fake input through the engine, but the rest of the
/// devtools talks to the real input source. The presets cover
/// everything the synthetic input used to.
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
        _QuickStatePanel(busy: busy),
        const DevToolsSectionDivider(),
        _PresetsPanel(busy: busy, onApply: _applyPreset),
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
        _DailyGoalChipsPanel(isBusy: busy),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DevToolsCollapsibleCard(
            title: 'XP / level overrides',
            subtitle: 'Set total Â· Add delta Â· Set level',
            leadingIcon: Icons.bolt_rounded,
            children: [_XpLevelTabsPanel(isBusy: busy)],
          ),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DevToolsCollapsibleCard(
            title: 'Catalog search',
            subtitle: 'Find + force-complete any node by id',
            leadingIcon: Icons.search_rounded,
            children: [_NodePickerPanel(isBusy: busy)],
          ),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: DevToolsCollapsibleCard(
            title: 'Inspect',
            subtitle: 'Ledger counters + last-result diagnostics',
            leadingIcon: Icons.analytics_outlined,
            children: [_InspectPanel(provider: p)],
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

  Future<void> _applyPreset(BuildContext context, _PlayerPreset preset) async {
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

// ── Quick state header ────────────────────────────────────────────────

/// Top-of-page strip: profile vitals (level / XP / day offset / ledger
/// size) + the day-shift controls inline. Putting the clock buttons
/// next to the day-offset readout makes the cause/effect obvious —
/// the number you're nudging is right there.
class _QuickStatePanel extends StatelessWidget {
  const _QuickStatePanel({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressionEngineProvider>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final profile = provider.profile;
    final ledger = provider.ledger;
    final ledgerSize = (ledger?.objectiveCompletions.length ?? 0) +
        (ledger?.nodeCompletions.length ?? 0) +
        (ledger?.nodeClaims.length ?? 0) +
        (ledger?.rewardGrants.length ?? 0) +
        (ledger?.nodeAnnouncements.length ?? 0);
    final dayOffset = provider.devDayOffset;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vitals row — small caps stat block.
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _StatChip(label: 'LVL', value: '${profile.level}'),
              _StatChip(label: 'XP', value: '${profile.totalXp}'),
              _StatChip(
                label: 'DAY',
                value: dayOffset == 0 ? 'real' : '+$dayOffset',
              ),
              _StatChip(label: 'EVENTS', value: '$ledgerSize'),
              if (provider.pendingCelebrations.isNotEmpty)
                _StatChip(
                  label: 'PENDING',
                  value: '${provider.pendingCelebrations.length}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Day shift controls. `Advance day` is the daily-test
          // workhorse; reset only matters when offset != 0.
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: busy ? null : () => _advance(context),
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Advance day +1'), // lint-ignore: l10n-literal — devtools, intentionally English
                ),
              ),
              if (dayOffset > 0) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _resetDay(context),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Reset'), // lint-ignore: l10n-literal — devtools, intentionally English
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Joined-date controls. Floor for retroactive claim
          // windows; pick a date in the past to widen the window
          // beyond the real install date, or reseed to fall back to
          // `min(now, earliest ledger event)`.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      busy ? null : () => _pickJoinedAt(context, provider),
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text('Joined: ${_formatDate(provider.joinedAt)}'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    busy ? null : () => _reseedJoinedAt(context, provider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reseed'), // lint-ignore: l10n-literal — devtools, intentionally English
              ),
            ],
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _advance(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    await provider.devToolsAdvanceDay();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Advanced to day +${provider.devDayOffset}')),
    );
  }

  Future<void> _resetDay(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    await provider.devToolsResetDayOffset();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Day offset reset to 0')), // lint-ignore: l10n-literal — devtools, intentionally English
    );
  }

  Future<void> _pickJoinedAt(
    BuildContext context,
    ProgressionEngineProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.joinedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    await provider.devToolsSetJoinedAt(picked);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Joined date set to ${_formatDate(picked)}')),
    );
  }

  Future<void> _reseedJoinedAt(
    BuildContext context,
    ProgressionEngineProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await provider.devToolsSetJoinedAt(null);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Reseeded joined date to ${_formatDate(provider.joinedAt)}'),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.65),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Player presets ────────────────────────────────────────────────────

/// One-tap shortcuts to canonical player states. The pattern was: wipe
/// ledger → set level → claim some quests → advance day. Presets fold
/// that into a single button so a fresh test reaches "Late game"
/// without typing.
class _PresetsPanel extends StatelessWidget {
  const _PresetsPanel({required this.busy, required this.onApply});

  final bool busy;
  final Future<void> Function(BuildContext context, _PlayerPreset preset)
      onApply;

  static const _presets = <_PlayerPreset>[
    _PlayerPreset(label: 'Fresh start', level: 1, hint: 'lv 1, no XP'),
    _PlayerPreset(label: 'Early game', level: 5, hint: 'lv 5'),
    _PlayerPreset(label: 'Mid game', level: 30, hint: 'lv 30'),
    _PlayerPreset(label: 'Late game', level: 70, hint: 'lv 70'),
    _PlayerPreset(label: 'Endgame', level: 100, hint: 'lv 100'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Player presets',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Wipes the ledger and snaps profile.totalXp to the level '
            'threshold. Day offset clears to 0.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                ActionChip(
                  label: Text(preset.label),
                  onPressed: busy ? null : () => onApply(context, preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerPreset {
  const _PlayerPreset({
    required this.label,
    required this.level,
    required this.hint,
  });
  final String label;
  final int level;
  final String hint;
}

// ── Inspect (collapsible diagnostics) ─────────────────────────────────

class _InspectPanel extends StatelessWidget {
  const _InspectPanel({required this.provider});

  final ProgressionEngineProvider provider;

  @override
  Widget build(BuildContext context) {
    final ledger = provider.ledger;
    final last = provider.lastResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DevToolsStatusTile(
          label: 'Loading',
          value: '${provider.isLoading}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger objective completions',
          value: '${ledger?.objectiveCompletions.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger node completions',
          value: '${ledger?.nodeCompletions.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger node claims',
          value: '${ledger?.nodeClaims.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger node announcements',
          value: '${ledger?.nodeAnnouncements.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Ledger reward grants',
          value: '${ledger?.rewardGrants.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last result — completed nodes',
          value: '${last?.completedNodes.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last result — newly available nodes',
          value: '${last?.newlyAvailableNodes.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Last result — granted rewards',
          value: '${last?.grantedRewards.length ?? 0}',
        ),
      ],
    );
  }
}

// ── XP / level tabs panel ─────────────────────────────────────────────

/// Tabbed shell that replaces the three separate XP/Level panels.
/// Behaviour is unchanged per tab — the user wanted them grouped
/// because they're conceptually one knob ("override the profile").
class _XpLevelTabsPanel extends StatefulWidget {
  const _XpLevelTabsPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_XpLevelTabsPanel> createState() => _XpLevelTabsPanelState();
}

class _XpLevelTabsPanelState extends State<_XpLevelTabsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        TabBar(
          controller: _tab,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Tokens.cardBorder,
          tabs: const [
            Tab(text: 'Set total'),
            Tab(text: 'Add'),
            Tab(text: 'Set level'),
          ],
        ),
        AnimatedBuilder(
          animation: _tab,
          builder: (_, __) {
            switch (_tab.index) {
              case 0:
                return _SetTotalXpForm(isBusy: widget.isBusy);
              case 1:
                return _AddXpForm(isBusy: widget.isBusy);
              case 2:
              default:
                return _SetLevelForm(isBusy: widget.isBusy);
            }
          },
        ),
      ],
    );
  }
}

class _SetTotalXpForm extends StatefulWidget {
  const _SetTotalXpForm({required this.isBusy});
  final bool isBusy;

  @override
  State<_SetTotalXpForm> createState() => _SetTotalXpFormState();
}

class _SetTotalXpFormState extends State<_SetTotalXpForm> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    return (n == null || n < 0) ? null : n;
  }

  Future<void> _apply() async {
    final xp = _parse();
    if (xp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetTotalXp(xp);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('V2 totalXp set to $xp')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = !widget.isBusy && !_applying && _parse() != null;
    return _NumericApplyRow(
      hint: 'Wipes ledger, inserts one synthetic XP grant so '
          'profile.totalXp == value.',
      labelText: 'Total XP',
      hintText: 'e.g. 25000',
      buttonText: 'Apply',
      controller: _controller,
      isApplying: _applying,
      canApply: canApply,
      onChanged: () => setState(() {}),
      onApply: _apply,
      enabled: !widget.isBusy && !_applying,
    );
  }
}

class _AddXpForm extends StatefulWidget {
  const _AddXpForm({required this.isBusy});
  final bool isBusy;

  @override
  State<_AddXpForm> createState() => _AddXpFormState();
}

class _AddXpFormState extends State<_AddXpForm> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    return (n == null || n <= 0) ? null : n;
  }

  Future<void> _apply() async {
    final xp = _parse();
    if (xp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsAddXp(xp);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Granted +$xp XP')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = !widget.isBusy && !_applying && _parse() != null;
    return _NumericApplyRow(
      hint: 'Appends a synthetic XP grant on top of the existing '
          'ledger. Triggers a re-evaluation so level-ups fire.',
      labelText: 'XP to add',
      hintText: 'e.g. 500',
      buttonText: 'Add',
      controller: _controller,
      isApplying: _applying,
      canApply: canApply,
      onChanged: () => setState(() {}),
      onApply: _apply,
      enabled: !widget.isBusy && !_applying,
    );
  }
}

class _SetLevelForm extends StatefulWidget {
  const _SetLevelForm({required this.isBusy});
  final bool isBusy;

  @override
  State<_SetLevelForm> createState() => _SetLevelFormState();
}

class _SetLevelFormState extends State<_SetLevelForm> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    return (n == null || n < 1) ? null : n;
  }

  Future<void> _apply() async {
    final level = _parse();
    if (level == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetLevel(level);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('Set level to $level')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = !widget.isBusy && !_applying && _parse() != null;
    return _NumericApplyRow(
      hint: 'Wipes ledger, inserts a synthetic grant equal to '
          'xpRequiredForLevel(level). Lands at the level floor.',
      labelText: 'Target level',
      hintText: 'e.g. 25',
      buttonText: 'Apply',
      controller: _controller,
      isApplying: _applying,
      canApply: canApply,
      onChanged: () => setState(() {}),
      onApply: _apply,
      enabled: !widget.isBusy && !_applying,
    );
  }
}

class _NumericApplyRow extends StatelessWidget {
  const _NumericApplyRow({
    required this.hint,
    required this.labelText,
    required this.hintText,
    required this.buttonText,
    required this.controller,
    required this.isApplying,
    required this.canApply,
    required this.onChanged,
    required this.onApply,
    required this.enabled,
  });

  final String hint;
  final String labelText;
  final String hintText;
  final String buttonText;
  final TextEditingController controller;
  final bool isApplying;
  final bool canApply;
  final VoidCallback onChanged;
  final Future<void> Function() onApply;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hint,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: labelText,
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply ? onApply : null,
                child: isApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Daily goal chips ──────────────────────────────────────────────────

/// One-tap chips for each `QuestDisplayBucket.daily` node.
class _DailyGoalChipsPanel extends StatefulWidget {
  const _DailyGoalChipsPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_DailyGoalChipsPanel> createState() => _DailyGoalChipsPanelState();
}

class _DailyGoalChipsPanelState extends State<_DailyGoalChipsPanel> {
  String? _completingId;

  late final List<Quest> _dailyQuests = [
    for (final node in const ProgressionEntryCatalog().build())
      if (node is Quest && node.displayBucket == QuestDisplayBucket.daily)
        node,
  ];

  Future<void> _complete(Quest node) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _completingId = node.id);
    try {
      // `devToolsMarkObjectiveMet` writes just the objective event,
      // so the card surfaces the Vyzvednout pill instead of jumping
      // straight to claimed. `devToolsForceCompleteNode` (which used
      // to live here) auto-claimed end-to-end and skipped the manual
      // tap that the real player flow goes through.
      await provider.devToolsMarkObjectiveMet(node.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Marked "${node.id}" met for today — tap Vyzvednout on the card to claim.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _completingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark daily goal as met today',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Writes the objective-met event for today. Card surfaces the '
            'Vyzvednout pill — tap to claim like a real player would.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final node in _dailyQuests)
                ActionChip(
                  label: _completingId == node.id
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_chipLabelFor(node.id)),
                  onPressed: widget.isBusy || _completingId != null
                      ? null
                      : () => _complete(node),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _chipLabelFor(String nodeId) {
    var label = nodeId;
    if (label.startsWith('daily_')) label = label.substring(6);
    if (label.endsWith('_today')) {
      label = label.substring(0, label.length - 6);
    }
    return label;
  }
}

// ── Catalog search ────────────────────────────────────────────────────

/// Searchable node picker — typeahead filter over every node id in
/// the catalog, with a "Complete" button on each row.
class _NodePickerPanel extends StatefulWidget {
  const _NodePickerPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_NodePickerPanel> createState() => _NodePickerPanelState();
}

class _NodePickerPanelState extends State<_NodePickerPanel> {
  final _filterController = TextEditingController();
  String? _completingId;

  late final List<_NodeEntry> _entries = () {
    final entries = <_NodeEntry>[
      for (final node in const ProgressionEntryCatalog().build())
        _NodeEntry(id: node.id, kind: _kindLabelFor(node)),
    ]..sort((a, b) {
        final byKind = a.kind.compareTo(b.kind);
        if (byKind != 0) return byKind;
        return a.id.compareTo(b.id);
      });
    return entries;
  }();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  String _kindLabelFor(ProgressionEntry node) => switch (node) {
        Quest(:final displayBucket) => 'quest Â· ${displayBucket.name}',
        Achievement() => 'achievement',
        Milestone() => 'milestone',
        LevelMilestone(:final level) => 'level $level',
        ChapterCompletion() => 'chapter completion',
        ContentUnlock() => 'content unlock',
        CompanionAvailability() => 'companion availability',
        Relic() => 'relic',
      };

  Future<void> _complete(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _completingId = id);
    try {
      await provider.devToolsForceCompleteNode(id);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('Force-completed "$id"')));
    } finally {
      if (mounted) setState(() => _completingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final filter = _filterController.text.trim().toLowerCase();
    final filtered = filter.isEmpty
        ? const <_NodeEntry>[]
        : _entries
            .where((e) => // lint-ignore: widget-no-logic — devtools node-id/kind search filter
                e.id.toLowerCase().contains(filter) ||
                e.kind.toLowerCase().contains(filter))
            .take(40)
            .toList();
    final canType = !widget.isBusy && _completingId == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _filterController,
            enabled: canType,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              labelText: 'Filter',
              hintText: 'e.g. combo, achievement, companion',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (filter.isEmpty)
            Text(
              '${_entries.length} nodes in the catalog. Type to filter.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            )
          else if (filtered.isEmpty)
            Text(
              'No nodes match "$filter".',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outline.withValues(alpha: 0.18),
                ),
                itemBuilder: (context, i) {
                  final entry = filtered[i];
                  final busy = _completingId == entry.id;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.id,
                      style: tt.bodyMedium
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(entry.kind),
                    trailing: TextButton(
                      onPressed:
                          widget.isBusy || _completingId != null
                              ? null
                              : () => _complete(entry.id),
                      child: busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text('Complete'), // lint-ignore: l10n-literal — devtools, intentionally English
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeEntry {
  const _NodeEntry({required this.id, required this.kind});
  final String id;
  final String kind;
}
