import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/period_navigator.dart';
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
  });

  final SelectedPeriod period;
  final String dateLabel;
  final ValueChanged<String> onTabChange;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final VoidCallback? onDateTap;

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
        );
      },
    );
  }
}
