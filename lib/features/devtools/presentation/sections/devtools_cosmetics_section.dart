import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../features/cosmetics/application/cosmetics_provider.dart';
import '../../../../features/cosmetics/domain/cosmetic_catalog.dart';
import '../../../../features/cosmetics/domain/cosmetic_models.dart';
import '../../../../features/cosmetics/domain/hero_race_catalog.dart';
import '../../../../features/cosmetics/domain/player_cosmetic_lifecycle.dart';
import '../../../../features/cosmetics/presentation/widgets/cosmetics_inventory_view.dart';
import '../../../../features/onboarding/presentation/race_picker_view.dart';
import '../../../../features/onboarding/widgets/onboarding_theme.dart';
import '../../../../features/progression_engine/application/progression_engine_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_back_button.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../application/companion_dev_controller.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';
import '../widgets/devtools_status_tile.dart';

class DevToolsCosmeticsSection extends StatefulWidget {
  const DevToolsCosmeticsSection({super.key});

  @override
  State<DevToolsCosmeticsSection> createState() =>
      _DevToolsCosmmeticsSectionState();
}

class _DevToolsCosmmeticsSectionState
    extends State<DevToolsCosmeticsSection> {
  bool _isClearing = false;
  bool _isGrantingAll = false;
  // Per-companion busy flag so concurrent taps on the matrix can't race
  // through the orchestration steps (level → force-complete → grant).
  // Keyed by companion id; cleared in a finally block.
  final Set<String> _busyCompanionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final progression = context.watch<ProgressionEngineProvider>();
    final state = cosmetics.state;
    final cs = Theme.of(context).colorScheme;

    final totalCount = CosmeticCatalog.definitions.length;
    final unlockedCount = state?.unlocked.length ?? 0;
    final equippedSlots = CosmeticType.values
        .where((t) => state?.equipped.slotId(t) != null) // lint-ignore: widget-no-logic — devtools equipped-slot count
        .length;
    final isBusy = _isClearing ||
        _isGrantingAll ||
        cosmetics.isLoading ||
        _busyCompanionIds.isNotEmpty;

    return DevToolsSectionCard(
      title: 'Cosmetics',
      children: [
        DevToolsStatusTile(
          label: 'Unlocked / total',
          value: '$unlockedCount / $totalCount',
          valueColor: unlockedCount > 0 ? Colors.greenAccent : null,
        ),
        const DevToolsSectionDivider(),
        DevToolsStatusTile(
          label: 'Equipped slots',
          value: '$equippedSlots / ${CosmeticType.values.length}',
        ),
        if (cosmetics.errorMessage != null) ...[
          const DevToolsSectionDivider(),
          DevToolsStatusTile(
            label: 'Error',
            value: cosmetics.errorMessage!,
            valueColor: cs.error,
          ),
        ],
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Open inventory',
          subtitle: 'All catalog items — locked, assets, grant/revoke, conditions',
          icon: Icons.inventory_2_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const _DevToolsCosmeticsCatalogScreen(),
            ),
          ),
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Change race',
          subtitle: cosmetics.currentRaceId == null
              ? 'No race set — pick one'
              : 'Current: ${cosmetics.currentRaceId}',
          icon: Icons.face_retouching_natural_rounded,
          isLoading: isBusy,
          onTap: isBusy ? null : _changeRace,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Unlock all cosmetics',
          subtitle: 'Grants every catalog item to the signed-in user',
          icon: Icons.lock_open_rounded,
          isLoading: isBusy,
          onTap: isBusy ? null : _grantAll,
        ),
        const DevToolsSectionDivider(),
        DevToolsActionTile(
          label: 'Clear all cosmetics',
          subtitle:
              'Wipes every unlock and clears all equipped slots for the signed-in user',
          isDestructive: true,
          isLoading: isBusy,
          icon: Icons.delete_sweep_rounded,
          onTap: isBusy ? null : _confirmAndClearAll,
        ),
        const DevToolsSectionDivider(),
        _CompanionStateMatrix(
          controller: CompanionDevController(
            cosmetics: cosmetics,
            progression: progression,
          ),
          busyIds: _busyCompanionIds,
          isAnyOuterBusy: _isClearing || _isGrantingAll || cosmetics.isLoading,
          onApply: _applyCompanionState,
        ),
      ],
    );
  }

  /// Orchestrates a state transition with a per-companion busy guard.
  /// The controller's `applyState` chains several engine + cosmetics
  /// writes; the guard prevents the matrix from kicking off another
  /// transition while one is in flight (would race on the same uid /
  /// ledger).
  Future<void> _applyCompanionState(
    CompanionDevController controller,
    String companionId,
    Future<void> Function() apply,
  ) async {
    if (_busyCompanionIds.contains(companionId)) return;
    setState(() => _busyCompanionIds.add(companionId));
    try {
      await apply();
    } finally {
      if (mounted) {
        setState(() => _busyCompanionIds.remove(companionId));
      }
    }
  }

  Future<void> _changeRace() async {
    final cosmetics = context.read<CosmeticsProvider>();
    final initial = cosmetics.currentRaceId ??
        HeroRaceCatalog.definitions.first.id;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DevToolsRacePickerSheet(initialRaceId: initial),
    );
    if (picked == null || !mounted) return;
    if (picked == cosmetics.currentRaceId) return;

    await cosmetics.selectRace(picked);
    if (!mounted) return;
    final err = cosmetics.errorMessage;
    final ok = cosmetics.currentRaceId == picked;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'DevTools: race changed to $picked'
              : 'DevTools: race change failed${err == null ? '' : ' ($err)'}',
        ),
      ),
    );
  }

  Future<void> _grantAll() async {
    setState(() => _isGrantingAll = true);
    try {
      final granted =
          await context.read<CosmeticsProvider>().devToolsGrantAllCosmetics();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DevTools: granted $granted cosmetics')),
      );
    } finally {
      if (mounted) setState(() => _isGrantingAll = false);
    }
  }

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all cosmetics?'), // lint-ignore: l10n-literal — devtools, intentionally English
        content: const Text(
          'Removes every unlock and clears all equipped slots for the '
          'signed-in user. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'), // lint-ignore: l10n-literal — devtools, intentionally English
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear all'), // lint-ignore: l10n-literal — devtools, intentionally English
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    try {
      final removed =
          await context.read<CosmeticsProvider>().devToolsClearAllUnlocks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DevTools: cleared $removed cosmetic unlocks')),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }
}

/// Per-companion state matrix. Each row lists the companion + its
/// current `CompanionDevState` + a button row for each target state
/// (Hidden / VisibleLocked / Partial / Claimable / Unlocked). Tapping
/// a state runs [CompanionDevController.applyState] for that companion.
///
/// Buttons inactive when the same companion is mid-transition or when
/// the outer cosmetics section is busy (grant-all / clear-all).
class _CompanionStateMatrix extends StatelessWidget {
  const _CompanionStateMatrix({
    required this.controller,
    required this.busyIds,
    required this.isAnyOuterBusy,
    required this.onApply,
  });

  final CompanionDevController controller;
  final Set<String> busyIds;
  final bool isAnyOuterBusy;
  final Future<void> Function(
    CompanionDevController controller,
    String companionId,
    Future<void> Function() apply,
  ) onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final companions = CompanionDevController.allCompanions();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.pets_rounded,
                size: 14,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Companion state matrix',
                style: tt.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Per-companion: pick a target state. Engine level + gating '
            'achievements are forced as needed; Hidden requires gate − 10.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          for (final node in companions)
            _CompanionRow(
              node: node,
              current: controller.detect(node),
              isBusy: busyIds.contains(node.id) || isAnyOuterBusy,
              isRowBusy: busyIds.contains(node.id),
              onSelect: (target) => onApply(
                controller,
                node.id,
                () => controller.applyState(node, target),
              ),
              l10n: l10n,
            ),
        ],
      ),
    );
  }
}

class _CompanionRow extends StatelessWidget {
  const _CompanionRow({
    required this.node,
    required this.current,
    required this.isBusy,
    required this.isRowBusy,
    required this.onSelect,
    required this.l10n,
  });

  // Imported via the controller's catalog snapshot — using the
  // progression-engine type directly avoids re-exporting it from
  // application/.
  final dynamic node; // CompanionAvailability (dynamic to avoid extra import)
  final PlayerCosmeticLifecycle current;
  final bool isBusy;
  final bool isRowBusy;
  final ValueChanged<CompanionDevTarget> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final gate = CompanionDevController.gateLevelFor(node) ?? 1;
    final currentTarget = _lifecycleToTarget(current);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.titleKey(l10n) as String,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                'L$gate',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              _StateChip(lifecycle: current),
              if (isRowBusy) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: cs.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in CompanionDevTarget.values)
                _StateButton(
                  label: _targetLabel(t),
                  isCurrent: t == currentTarget,
                  isDisabled: isBusy,
                  onTap: () => onSelect(t),
                ),
            ],
          ),
          // Mechanics hint — visible buff + hidden food trigger from
          // the cosmetics catalog. Player-facing details sheet stays
          // intentionally narrow (buff chip + flavor copy); the
          // devtools row spells out the numbers so QA can spot a
          // mis-wired keyword / cap / source kind without diffing
          // the catalog file.
          ..._buildMechanicsHint(context),
        ],
      ),
    );
  }

  List<Widget> _buildMechanicsHint(BuildContext context) {
    final companion = const CosmeticCatalog().byId(node.id as String);
    if (companion is! Companion) return const [];
    final buff = companion.buff;
    final trigger = companion.foodTrigger;
    if (buff == null && trigger == null) return const [];

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lines = <_HintLine>[];

    if (buff != null) {
      lines.add(_HintLine(
        icon: Icons.flash_on_rounded,
        label: 'Buff',
        value: _buffSummary(buff),
        accent: cs.primary,
      ));
    }
    if (trigger != null) {
      lines.add(_HintLine(
        icon: Icons.restaurant_rounded,
        label: 'Food',
        value: _triggerSummary(trigger),
        accent: const Color(0xFFFFBD2E), // mirrors Tokens.xp
      ));
    }

    return [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(lines[i].icon, size: 12, color: lines[i].accent),
                  const SizedBox(width: 6),
                  Text(
                    '${lines[i].label}: ',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lines[i].value,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }

  String _buffSummary(CompanionBuff buff) {
    return switch (buff) {
      FlatCompanionBuff(:final kind, :final percent) =>
        '+$percent% ${kind.name}',
      StreakLengthCompanionBuff(:final tier1Percent, :final tier4Percent) =>
        '+$tier1Percent–$tier4Percent% per-streak',
      StreakThresholdFlatCompanionBuff(:final percent, :final minStreak) =>
        '+$percent% above ${minStreak}d streak',
      WeeklyEmphasisCompanionBuff(:final dailyPercent, :final weeklyPercent) =>
        '+$dailyPercent% daily / +$weeklyPercent% weekly quest',
      ChapterDepthCompanionBuff(:final openerPercent, :final deepPercent) =>
        '+$openerPercent–$deepPercent% chapter chain',
    };
  }

  String _triggerSummary(FoodTriggerReward trigger) {
    return switch (trigger) {
      FoodKeywordTrigger(
        :final keywords,
        :final perEntryXp,
        :final perDayMaxXp,
      ) =>
        '[${keywords.join(", ")}] · $perEntryXp XP/entry · cap $perDayMaxXp/day (hidden)',
    };
  }

  /// Map the canonical lifecycle to the closest matrix target for
  /// the "is current" highlight. `CosmeticTeased` with no progress
  /// (the old visibleLocked flavour) maps to `hidden` because the
  /// matrix's "Hidden" button is the recipe that lands there at
  /// high level (gate − 10 fallback).
  static CompanionDevTarget _lifecycleToTarget(
      PlayerCosmeticLifecycle l) {
    return switch (l) {
      CosmeticOwned() => CompanionDevTarget.claimed,
      CosmeticClaimable() => CompanionDevTarget.claimable,
      CosmeticTeased(:final totalConditions) when totalConditions > 0 =>
        CompanionDevTarget.partial,
      CosmeticTeased() || CosmeticHidden() => CompanionDevTarget.hidden,
    };
  }

  static String _targetLabel(CompanionDevTarget t) {
    return switch (t) {
      CompanionDevTarget.hidden => 'Hidden',
      CompanionDevTarget.partial => 'Partial',
      CompanionDevTarget.claimable => 'Claimable',
      CompanionDevTarget.claimed => 'Claimed',
    };
  }
}

/// One mechanics row inside the devtools companion hint (visible
/// buff or hidden food trigger). Pure data — the layout is owned by
/// `_CompanionRow._buildMechanicsHint`.
class _HintLine {
  const _HintLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.lifecycle});

  final PlayerCosmeticLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, label) = switch (lifecycle) {
      CosmeticHidden() =>
        (cs.onSurfaceVariant.withValues(alpha: 0.6), 'HIDDEN'),
      CosmeticTeased(:final totalConditions) when totalConditions > 0 =>
        (cs.secondary, 'PARTIAL'),
      CosmeticTeased() =>
        (cs.onSurfaceVariant.withValues(alpha: 0.6), 'TEASED'),
      CosmeticClaimable() => (Colors.greenAccent, 'CLAIMABLE'),
      CosmeticOwned() => (cs.primary, 'CLAIMED'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({
    required this.label,
    required this.isCurrent,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return OutlinedButton(
      onPressed: isDisabled ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isCurrent ? cs.primary.withValues(alpha: 0.16) : Colors.transparent,
        foregroundColor: isCurrent ? cs.primary : cs.onSurface,
        side: BorderSide(
          color: isCurrent
              ? cs.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: tt.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: isCurrent ? cs.primary : cs.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// DevTools-only race re-pick sheet. Wraps the onboarding [RacePickerView]
/// so QA can flip races without going through factory reset. Pops the
/// chosen race id (or null when dismissed) — the caller commits via
/// [CosmeticsProvider.selectRace].
class _DevToolsRacePickerSheet extends StatefulWidget {
  const _DevToolsRacePickerSheet({required this.initialRaceId});

  final String initialRaceId;

  @override
  State<_DevToolsRacePickerSheet> createState() =>
      _DevToolsRacePickerSheetState();
}

class _DevToolsRacePickerSheetState extends State<_DevToolsRacePickerSheet> {
  late String _draftRaceId = widget.initialRaceId;

  @override
  Widget build(BuildContext context) {
    final mediaBottom = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: OnboardingTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'DevTools — change race',
                      style: TextStyle(
                        color: OnboardingTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: OnboardingTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: RacePickerView(
                  draftRaceId: _draftRaceId,
                  onPickRace: (id) => setState(() => _draftRaceId = id),
                  title: 'Pick a race',
                  subtitle: 'Devtools override — persists immediately via '
                      'CosmeticsProvider.selectRace.',
                  subtitleAccent: '',
                  levelLabel: 'DEV',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + mediaBottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: OnboardingTheme.purplePrimary,
                    foregroundColor: OnboardingTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(_draftRaceId),
                  child: Text(
                    _draftRaceId == widget.initialRaceId
                        ? 'Confirm (no change)'
                        : 'Switch to $_draftRaceId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DevTools-only catalog browser. The player-facing cosmetics route is
/// the Inventář tab on `SocialUserProfileScreen`; this thin screen
/// stays because QA still needs the `devToolsMode: true` view
/// (all catalog items including locked + asset-missing indicators +
/// unlock-rule matrix). Lives next to the section that pushes it so
/// it never gets reused as a regular user surface.
class _DevToolsCosmeticsCatalogScreen extends StatelessWidget {
  const _DevToolsCosmeticsCatalogScreen();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                MediaQuery.of(context).padding.top + 12,
                14,
                0,
              ),
              child: const ScreenHeader(
                greeting: '',
                title: 'Cosmetics catalog (dev)',
                leading: FtBackButton(),
              ),
            ),
            const SizedBox(height: 14),
            const Expanded(
              child: CosmeticsInventoryView(devToolsMode: true),
            ),
          ],
        ),
      ),
    );
  }
}
