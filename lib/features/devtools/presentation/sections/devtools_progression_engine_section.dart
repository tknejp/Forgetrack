import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../../../../features/progression_engine/domain/catalog/progression_node_catalog.dart';
import '../../../../features/progression_engine/domain/models/engine_evaluation_input.dart';
import '../../../../features/progression_engine/domain/models/progression_node_definition.dart';
import '../../../../features/progression_engine/domain/models/quest_display_bucket.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

/// Devtools surface for the new engine. Lets the user trigger one
/// evaluation pass with a synthetic ambitious-player input, inspect
/// the persisted ledger size, and wipe the ledger. Independent of
/// the legacy ProgressionDevTools section.
class DevToolsProgressionEngineSection extends StatefulWidget {
  const DevToolsProgressionEngineSection({super.key});

  @override
  State<DevToolsProgressionEngineSection> createState() =>
      _DevToolsProgressionEngineSectionState();
}

class _DevToolsProgressionEngineSectionState
    extends State<DevToolsProgressionEngineSection> {
  bool _isEvaluating = false;
  bool _isWiping = false;
  bool _isClaiming = false;
  bool _isCompletingDailies = false;
  bool _isCompletingChapter = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressionEngineProvider>();
    final ledger = p.ledger;
    final last = p.lastResult;

    return DevToolsSectionCard(
      title: 'Progression Engine V2',
      children: [
        DevToolsStatusTile(
          label: 'Loading',
          value: '${p.isLoading}',
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
          label: 'Last result — granted rewards',
          value: '${last?.grantedRewards.length ?? 0}',
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Pending celebrations',
          value: '${p.pendingCelebrations.length}',
        ),
        if (p.error != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Error',
            value: p.error!,
            valueColor: Theme.of(context).colorScheme.error,
          ),
        ],
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Run V2 evaluation (ambitious-player input)',
          subtitle:
              'Synthetic input: 10500 steps, 165g protein, 120k lifetime, level 5, 5000 XP',
          icon: Icons.play_arrow_rounded,
          isLoading: _isEvaluating || p.isEvaluating,
          isDisabled: _isWiping,
          onTap: _isEvaluating
              ? null
              : () async {
                  setState(() => _isEvaluating = true);
                  try {
                    await context
                        .read<ProgressionEngineProvider>()
                        .evaluateWith(input: _ambitiousInput());
                  } finally {
                    if (mounted) setState(() => _isEvaluating = false);
                  }
                },
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Claim all available quests',
          subtitle:
              'Iterates pendingClaimNodeIds and calls engine.claim on each. '
              'XP for every available quest lands in the ledger immediately.',
          icon: Icons.redeem_rounded,
          isLoading: _isClaiming,
          isDisabled: _isEvaluating ||
              _isWiping ||
              p.pendingClaimNodeIds.isEmpty,
          onTap: () => _claimAll(context),
        ),
        const DevToolsSectionDivider(),
        _SetXpPanel(isBusy: _isEvaluating || _isWiping || p.isEvaluating),
        const DevToolsSectionDivider(),
        _AddXpPanel(isBusy: _isEvaluating || _isWiping || p.isEvaluating),
        const DevToolsSectionDivider(),
        _SetLevelPanel(isBusy: _isEvaluating || _isWiping || p.isEvaluating),
        const DevToolsSectionDivider(),
        _DailyGoalChipsPanel(
          isBusy: _isEvaluating || _isWiping || p.isEvaluating,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Mark active chapter step as met',
          subtitle:
              'Writes the chapter step\'s ObjectiveCompletionEvent so '
              'the chapter card surfaces the normal Vyzvednout pill. '
              'Tap the pill afterwards to trigger the real claim '
              'flow (XP grant + fullscreen celebration). Auto-claim '
              'devtools was silently finalising the step and '
              'swallowing the celebration.',
          icon: Icons.flag_rounded,
          isLoading: _isCompletingChapter,
          isDisabled: _isEvaluating || _isWiping || _isCompletingDailies,
          onTap: _isCompletingChapter
              ? null
              : () => _completeActiveChapterSteps(context),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Claim today\'s visible daily quests',
          subtitle:
              'Force-completes only the two daily quests currently in '
              'the daily section (surprise / active combo / rotation '
              'pick). Quests not in today\'s rotation are not touched.',
          icon: Icons.checklist_rounded,
          isLoading: _isCompletingDailies,
          isDisabled: _isEvaluating || _isWiping,
          onTap: _isCompletingDailies
              ? null
              : () => _completeVisibleDailies(context),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Advance day (devtools clock +1)',
          subtitle:
              'Shifts the engine\'s "today" forward by 1 day. Daily '
              'rotation hash rolls, combo NodeCompletedBeforeToday '
              'gates open, claimed dailies retire from the completed-'
              'today set. Current offset: +${p.devDayOffset} day(s).',
          icon: Icons.skip_next_rounded,
          isDisabled: _isEvaluating || _isWiping || _isCompletingDailies,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final provider = context.read<ProgressionEngineProvider>();
            await provider.devToolsAdvanceDay();
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('Advanced to day +${provider.devDayOffset}'),
              ),
            );
          },
        ),
        if (p.devDayOffset > 0) ...[
          const DevToolsSectionDivider(),
          DevToolsActionTile(
            label: 'Reset day offset to 0',
            subtitle:
                'Snaps the devtools clock back to wall-clock today.',
            icon: Icons.replay_rounded,
            isDisabled: _isEvaluating || _isWiping || _isCompletingDailies,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final provider = context.read<ProgressionEngineProvider>();
              await provider.devToolsResetDayOffset();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Day offset reset to 0')),
              );
            },
          ),
        ],
        const DevToolsSectionDivider(),
        _NodePickerPanel(
          isBusy: _isEvaluating || _isWiping || p.isEvaluating,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Wipe V2 ledger',
          subtitle:
              'Clears every V2 Isar collection. Legacy progression untouched.',
          isDestructive: true,
          icon: Icons.delete_sweep_rounded,
          isLoading: _isWiping,
          isDisabled: _isEvaluating,
          onTap: _isWiping ? null : () => _confirmAndWipe(context),
        ),
      ],
    );
  }

  Future<void> _confirmAndWipe(BuildContext context) async {
    // Capture all BuildContext-derived dependencies before any
    // async gap so the analyzer is happy and we never reach into a
    // disposed tree.
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe V2 ledger?'),
        content: const Text(
          'Clears every progression_engine Isar collection. '
          'Legacy progression is untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wipe'),
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
        const SnackBar(content: Text('V2 ledger wiped')),
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
        await provider.claimNode(
          nodeId: nodeId,
          input: _ambitiousInput(),
        );
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

  /// Marks the bound objective of every active chapter step as met
  /// — **without** auto-claiming. The chapter card then surfaces the
  /// "Vyzvednout XP" pill so the player can tap through the real
  /// claim flow (XP grant + fullscreen celebration). The earlier
  /// shortcut wrote `NodeClaimEvent` directly, which silently
  /// finalised the step and skipped both the visible claim pill and
  /// the celebration — exactly the symptom the user reported as
  /// "chapter quest doesn't offer claim XP".
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
        SnackBar(content: Text(
          'Marked objective met for $marked chapter step(s) — '
          'tap the Vyzvednout pill on the chapter card to claim.',
        )),
      );
    } finally {
      if (mounted) setState(() => _isCompletingChapter = false);
    }
  }

  /// Force-completes only the daily quests currently surfaced in the
  /// daily section slots ([ProgressionEngineProvider.currentDailyQuests]).
  /// Quests outside today's rotation (level-gated, not picked by the
  /// hash, retired side quests, etc.) stay untouched — the user wants
  /// a tool that mirrors "claim what the player sees", not "complete
  /// the entire catalog".
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

  EngineEvaluationInput _ambitiousInput() => EngineEvaluationInput(
        evaluatedAt: DateTime.now(),
        stepsToday: 10500,
        proteinGramsToday: 165,
        stepsLifetime: 120000,
        level: 5,
        totalXp: 5000,
      );
}

/// Inline panel for seeding the ledger with a synthetic XP grant.
/// Equivalent to V1's `_DevToolsXpOverridePanel` — wipes the V2
/// ledger and inserts one synthetic grant so `profile.totalXp`
/// becomes exactly the requested value. Use to test high-level
/// flows (level milestones, XP-threshold achievements) without
/// completing dozens of real quests.
class _SetXpPanel extends StatefulWidget {
  const _SetXpPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_SetXpPanel> createState() => _SetXpPanelState();
}

class _SetXpPanelState extends State<_SetXpPanel> {
  late final TextEditingController _controller;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final canApply =
        !widget.isBusy && !_applying && _resolveXp() != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set total XP',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Wipes the V2 ledger and inserts a synthetic XP grant so '
            "profile.totalXp becomes exactly the chosen value.",
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isBusy && !_applying,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Total XP',
                    hintText: 'e.g. 25000',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply ? _apply : null,
                child: _applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _resolveXp() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  Future<void> _apply() async {
    final xp = _resolveXp();
    if (xp == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetTotalXp(xp);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('V2 totalXp set to $xp')),
      );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

/// Inline panel that **adds** XP on top of existing ledger state
/// (non-destructive, unlike [_SetXpPanel]). Triggers a downstream
/// evaluation so any level-up celebration fires.
class _AddXpPanel extends StatefulWidget {
  const _AddXpPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_AddXpPanel> createState() => _AddXpPanelState();
}

class _AddXpPanelState extends State<_AddXpPanel> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _resolve() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> _apply() async {
    final xp = _resolve();
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final canApply = !widget.isBusy && !_applying && _resolve() != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add XP',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Appends a synthetic XP grant on top of the current ledger '
            '(additive). Triggers a re-evaluation so level milestones fire.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isBusy && !_applying,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'XP to add',
                    hintText: 'e.g. 500',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply ? _apply : null,
                child: _applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline panel that sets the player's level by deriving the target
/// XP total from [ProgressionLevelPolicy]. Wipes existing grants
/// like [_SetXpPanel].
class _SetLevelPanel extends StatefulWidget {
  const _SetLevelPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_SetLevelPanel> createState() => _SetLevelPanelState();
}

class _SetLevelPanelState extends State<_SetLevelPanel> {
  final _controller = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _resolve() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1) return null;
    return parsed;
  }

  Future<void> _apply() async {
    final level = _resolve();
    if (level == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _applying = true);
    try {
      await provider.devToolsSetLevel(level);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Set level to $level')));
      _controller.clear();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final canApply = !widget.isBusy && !_applying && _resolve() != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set level',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Wipes existing grants and inserts a synthetic XP grant equal '
            'to ProgressionLevelPolicy.xpRequiredForLevel(level).',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isBusy && !_applying,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Target level',
                    hintText: 'e.g. 25',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canApply ? _apply : null,
                child: _applying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One-tap chips for each `QuestDisplayBucket.daily` node. Picks up
/// daily quests from the catalog at build time so any new daily atom
/// (carbs/fat/fiber port, etc.) shows up automatically without
/// touching this widget.
class _DailyGoalChipsPanel extends StatefulWidget {
  const _DailyGoalChipsPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_DailyGoalChipsPanel> createState() => _DailyGoalChipsPanelState();
}

class _DailyGoalChipsPanelState extends State<_DailyGoalChipsPanel> {
  String? _completingId;

  late final List<QuestNode> _dailyQuests = [
    for (final node in const ProgressionNodeCatalog().build())
      if (node is QuestNode && node.displayBucket == QuestDisplayBucket.daily)
        node,
  ];

  Future<void> _complete(QuestNode node) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _completingId = node.id);
    try {
      await provider.devToolsForceCompleteNode(node.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Marked "${node.id}" met for today')),
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
          Text('Mark daily goal as met today',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Force-completes the named daily quest with today\'s periodKey. '
            'The quest jumps to claimed state, XP lands, and the celebration '
            'fires on the next evaluation pass.',
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

  /// Strip the redundant `daily_*_today` suffix so chips read as
  /// "steps", "calories", "protein" — fits much better in the wrap.
  String _chipLabelFor(String nodeId) {
    var label = nodeId;
    if (label.startsWith('daily_')) label = label.substring(6);
    if (label.endsWith('_today')) {
      label = label.substring(0, label.length - 6);
    }
    return label;
  }
}

/// Searchable node picker — typeahead filter over every node id in
/// the catalog, with a "Complete" button on each row. Replaces the
/// free-text "Force complete node" input the user found cumbersome.
class _NodePickerPanel extends StatefulWidget {
  const _NodePickerPanel({required this.isBusy});

  final bool isBusy;

  @override
  State<_NodePickerPanel> createState() => _NodePickerPanelState();
}

class _NodePickerPanelState extends State<_NodePickerPanel> {
  final _filterController = TextEditingController();
  String? _completingId;

  // Build the catalog index once. Sorted so the list reads in a
  // predictable order (chapters → combo → achievements → …).
  late final List<_NodeEntry> _entries = () {
    final entries = <_NodeEntry>[
      for (final node in const ProgressionNodeCatalog().build())
        _NodeEntry(
          id: node.id,
          kind: _kindLabelFor(node),
        ),
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

  String _kindLabelFor(ProgressionNode node) => switch (node) {
        QuestNode(:final displayBucket) => 'quest · ${displayBucket.name}',
        AchievementNode() => 'achievement',
        MilestoneNode() => 'milestone',
        LevelMilestoneNode(:final level) => 'level $level',
        ChapterCompletionNode() => 'chapter completion',
        ContentUnlockNode() => 'content unlock',
        CompanionAvailabilityNode() => 'companion availability',
        RelicNode() => 'relic',
      };

  Future<void> _complete(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProgressionEngineProvider>();
    setState(() => _completingId = id);
    try {
      await provider.devToolsForceCompleteNode(id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Force-completed "$id"')),
      );
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
            .where((e) =>
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
          Text('Search & force-complete any node',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Type a partial node id or kind (e.g. "combo_balanced", '
            '"achievement", "companion"). Tap a result\'s button to '
            'inject the right completion events for that node — daily '
            'quests use today\'s periodKey, manual claims cascade through '
            'the engine so the celebration fires.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
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
                      style: tt.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    subtitle: Text(entry.kind),
                    trailing: TextButton(
                      onPressed: widget.isBusy ||
                              _completingId != null
                          ? null
                          : () => _complete(entry.id),
                      child: busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text('Complete'),
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
