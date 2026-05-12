import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/application/auth_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/data/local/cosmetics_database.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../health_connect/application/goals_provider.dart';
import '../../../health_connect/data/local/health_database.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../nutrition/data/local/kt_nutrition_database.dart';
import '../../../onboarding/application/onboarding_provider.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../social/application/social_provider.dart';
import '../../application/devtools_provider.dart';
import '../../application/factory_reset/factory_reset_models.dart';
import '../../application/factory_reset/factory_reset_service.dart';
import '../widgets/devtools_action_tile.dart';
import '../widgets/devtools_section_card.dart';

/// "Factory reset / new player reset" — DevTools-only.
///
/// Wipes local databases, prefs, secure storage, signs the user out of
/// Google + Firebase, optionally purges Forgetrack-owned Firestore docs,
/// and revokes Health Connect permissions. Health Connect records and
/// Google Drive files are NEVER deleted.
class DevToolsFactoryResetSection extends StatefulWidget {
  const DevToolsFactoryResetSection({super.key});

  @override
  State<DevToolsFactoryResetSection> createState() =>
      _DevToolsFactoryResetSectionState();
}

class _DevToolsFactoryResetSectionState
    extends State<DevToolsFactoryResetSection> {
  static const _confirmText = 'RESET';

  final TextEditingController _confirmCtrl = TextEditingController();

  bool _purgeFirestore = false;
  bool _openHealthConnectSettings = true;
  bool _running = false;

  /// status keyed by step. Empty when no run has occurred yet.
  final Map<FactoryResetStep, FactoryResetStepStatus> _stepStatus = {};
  final Map<FactoryResetStep, String?> _stepNote = {};
  final Map<FactoryResetStep, String?> _stepError = {};
  FactoryResetReport? _lastReport;

  bool get _confirmed => _confirmCtrl.text.trim().toUpperCase() == _confirmText;

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return DevToolsSectionCard(
      title: 'Factory reset / new player reset',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Text(
            'Clears local databases, cached auth, settings, progression, '
            'cosmetics, sync caches; logs out of Kaloricke Tabulky and '
            'Google; revokes this app\'s Health Connect access where '
            'supported.',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
          child: _SafetyNotice(
            cs: cs,
            tt: tt,
            text: 'Health Connect records will NOT be deleted — only this '
                'app\'s permissions are revoked. Google Sheets / Drive '
                'files are NEVER deleted.',
          ),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Text(
            'Options',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: const Text('Also delete my Firestore data'),
          subtitle: const Text(
            'Deletes progressionClaims, achievementUnlocks, progression/state, '
            'cosmeticEntitlements, notifications under users/{uid}. '
            'Social/cross-user docs are left intact.',
            style: TextStyle(fontSize: 11),
          ),
          value: _purgeFirestore,
          onChanged: _running
              ? null
              : (v) => setState(() => _purgeFirestore = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: const Text('Open Android app settings at the end'),
          subtitle: const Text(
            'Lets you verify or manually revoke Health Connect permissions.',
            style: TextStyle(fontSize: 11),
          ),
          value: _openHealthConnectSettings,
          onChanged: _running
              ? null
              : (v) => setState(() => _openHealthConnectSettings = v ?? true),
        ),
        const DevToolsSectionDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Text(
            'Confirm',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: TextField(
            controller: _confirmCtrl,
            enabled: !_running,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Type $_confirmText to enable the button',
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        DevToolsActionTile(
          label: 'Run factory reset',
          subtitle: _running
              ? 'Running…'
              : 'All steps will run sequentially. Failures are reported '
                  'but do not abort the rest of the flow.',
          isDestructive: true,
          isLoading: _running,
          isDisabled: !_confirmed && !_running,
          icon: Icons.delete_sweep_rounded,
          onTap: !_confirmed || _running ? null : _runReset,
        ),
        if (_stepStatus.isNotEmpty) ...[
          const DevToolsSectionDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              'Progress',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final step in FactoryResetStep.values)
            _StepRow(
              step: step,
              status: _stepStatus[step] ?? FactoryResetStepStatus.pending,
              note: _stepNote[step],
              errorMessage: _stepError[step],
            ),
        ],
        if (_lastReport != null) ...[
          const DevToolsSectionDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: _ResultSummary(report: _lastReport!, cs: cs, tt: tt),
          ),
        ],
      ],
    );
  }

  Future<void> _runReset() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _running = true;
      _stepStatus.clear();
      _stepNote.clear();
      _stepError.clear();
      _lastReport = null;
      for (final step in FactoryResetStep.values) {
        _stepStatus[step] = FactoryResetStepStatus.pending;
      }
    });

    final deps = FactoryResetDeps(
      healthDatabase: context.read<HealthDatabase>(),
      ktNutritionDatabase: context.read<KtNutritionDatabase>(),
      cosmeticsDatabase: context.read<CosmeticsDatabase>(),
      authProvider: context.read<AuthProvider>(),
      progressionEngineProvider: context.read<ProgressionEngineProvider>(),
      cosmeticsProvider: context.read<CosmeticsProvider>(),
      fitnessProvider: context.read<FitnessProvider>(),
      kalorickeTabulkyProvider: context.read<KalorickeTabulkyProvider>(),
      goalsProvider: context.read<GoalsProvider>(),
      socialProvider: context.read<SocialProvider>(),
      devToolsProvider: context.read<DevToolsProvider>(),
      onboardingProvider: context.read<OnboardingProvider>(),
    );
    final service = context.read<FactoryResetService>();

    try {
      final report = await service.run(
        options: FactoryResetOptions(
          purgeFirestoreData: _purgeFirestore,
          openHealthConnectSettings: _openHealthConnectSettings,
        ),
        deps: deps,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _stepStatus[progress.step] = progress.status;
            if (progress.note != null) _stepNote[progress.step] = progress.note;
            if (progress.errorMessage != null) {
              _stepError[progress.step] = progress.errorMessage;
            }
          });
        },
      );
      if (!mounted) return;
      setState(() => _lastReport = report);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.hasFailures
                ? 'Factory reset finished with ${report.failureCount} failure(s)'
                : 'Factory reset complete',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _confirmCtrl.clear();
        });
      }
    }
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({
    required this.cs,
    required this.tt,
    required this.text,
  });
  final ColorScheme cs;
  final TextTheme tt;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x22FBBF24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x55FBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFFBBF24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.95),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.status,
    required this.note,
    required this.errorMessage,
  });

  final FactoryResetStep step;
  final FactoryResetStepStatus status;
  final String? note;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: _statusIcon(cs),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: status == FactoryResetStepStatus.failed
                        ? cs.error
                        : cs.onSurface,
                  ),
                ),
                if (note != null && note!.isNotEmpty)
                  Text(
                    note!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.error,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(ColorScheme cs) {
    switch (status) {
      case FactoryResetStepStatus.pending:
        return Icon(
          Icons.radio_button_unchecked_rounded,
          size: 16,
          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
        );
      case FactoryResetStepStatus.running:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        );
      case FactoryResetStepStatus.succeeded:
        return Icon(Icons.check_circle_rounded,
            size: 16, color: Colors.greenAccent);
      case FactoryResetStepStatus.skipped:
        return Icon(Icons.remove_circle_outline_rounded,
            size: 16, color: cs.onSurfaceVariant);
      case FactoryResetStepStatus.failed:
        return Icon(Icons.error_rounded, size: 16, color: cs.error);
    }
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.report,
    required this.cs,
    required this.tt,
  });

  final FactoryResetReport report;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final color = report.hasFailures ? cs.error : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.hasFailures
                ? 'Completed with errors'
                : 'Completed successfully',
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ok=${report.successCount} skipped=${report.skippedCount} '
            'failed=${report.failureCount} '
            'totalMs=${report.totalElapsed.inMilliseconds}',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
