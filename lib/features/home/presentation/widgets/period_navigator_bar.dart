import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/period_navigator.dart';
import '../../../coach_log_export/application/bushido_export_provider.dart';
import '../../../coach_log_export/application/coach_log_export_settings.dart';
import '../../../health_connect/application/fitness_provider.dart';

/// Thin wrapper around [PeriodNavigator] that scopes its
/// `FitnessProvider` subscription to just the `lastSyncedAt` field via
/// `Selector`. A steps update notify on `FitnessProvider` would
/// otherwise rebuild the whole bar even though only the synced-time
/// label depends on it.
class PeriodNavigatorBar extends StatelessWidget {
  const PeriodNavigatorBar({
    super.key,
    required this.period,
    required this.dateLabel,
    required this.onTabChange,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onDateTap,
    this.onQuickExport,
  });

  final SelectedPeriod period;
  final String dateLabel;
  final ValueChanged<String> onTabChange;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final VoidCallback? onDateTap;

  /// Triggers a one-tap coach-log export of the current week. When non-null a
  /// quick-export icon is offered in the header — but only while the user has
  /// opted into it via Settings → Coach Log Export (see [_QuickExportAction]).
  final VoidCallback? onQuickExport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tab = period.type == PeriodType.week
        ? l10n.periodWeek
        : period.type == PeriodType.month
            ? l10n.periodMonth
            : l10n.periodDay;
    return Selector<FitnessProvider, DateTime?>(
      selector: (_, fitness) => fitness.lastSyncedAt,
      builder: (context, lastSyncedAt, _) {
        final locale = Localizations.localeOf(context).toString();
        final syncedAt = lastSyncedAt != null
            ? DateFormat('HH:mm', locale).format(lastSyncedAt)
            : null;
        return PeriodNavigator(
          domain: Tokens.steps,
          tabs: [l10n.periodDay, l10n.periodWeek, l10n.periodMonth],
          activeTab: tab,
          onTabChange: onTabChange,
          dateLabel: dateLabel,
          syncedAt: syncedAt != null ? 'Synced $syncedAt' : null,
          canGoForward: period.canGoForward,
          isCurrentPeriod: period.isCurrentPeriod,
          onPrev: onPrev,
          onNext: onNext,
          onToday: onToday,
          onDateTap: onDateTap,
          action: onQuickExport == null
              ? null
              : _QuickExportAction(onExport: onQuickExport!),
        );
      },
    );
  }
}

/// Quick coach-log export icon shown in the period navigator header.
///
/// Renders nothing unless the user enabled the toggle in
/// Settings → Coach Log Export, and shows a spinner (and disables itself)
/// while an export is in flight. Both are scoped via `context.select` so a
/// step tick or an unrelated provider notify doesn't rebuild it.
class _QuickExportAction extends StatelessWidget {
  const _QuickExportAction({required this.onExport});

  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<CoachLogExportSettings, bool>(
      (s) => s.showOverviewQuickButton,
    );
    if (!enabled) return const SizedBox.shrink();

    final isExporting = context.select<BushidoExportProvider, bool>(
      (p) => p.isExporting,
    );

    return IconButton(
      onPressed: isExporting ? null : onExport,
      icon: isExporting
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Tokens.steps.color,
              ),
            )
          : const Icon(Icons.cloud_upload_outlined, size: 20),
      color: Tokens.steps.color,
      disabledColor: Tokens.steps.color,
      tooltip: context.l10n.coachLogExportCurrentWeekButton,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
