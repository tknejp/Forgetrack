import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/selected_period.dart';
import '../../../../core/services/connectivity_provider.dart';
import 'home_card_list.dart';
import 'offline_source_banner.dart';

/// Per-period orchestrator. Stateless, keyed by [period] so the parent
/// drag-reveal pager can swap pages by identity. Does not watch any
/// provider directly — subscriptions are owned by [_HomeOfflineBanner]
/// and [HomeCardList] (which in turn delegate the data-card watches
/// to each slot widget).
class DayContent extends StatelessWidget {
  const DayContent({
    super.key,
    required this.period,
    required this.barKey,
    required this.showCachedHcAnyway,
    required this.showCachedKtAnyway,
    required this.onShowCachedHc,
    required this.onShowCachedKt,
    required this.onHcAction,
    required this.onOpenActivities,
    required this.onOpenSteps,
    required this.onOpenNutrition,
    required this.onOpenBody,
    required this.onOpenSleep,
  });

  final SelectedPeriod period;
  final GlobalKey barKey;
  final bool showCachedHcAnyway;
  final bool showCachedKtAnyway;
  final VoidCallback onShowCachedHc;
  final VoidCallback onShowCachedKt;
  final VoidCallback onHcAction;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSteps;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenBody;
  final VoidCallback onOpenSleep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HomeOfflineBanner(),
        HomeCardList(
          period: period,
          barKey: barKey,
          showCachedHcAnyway: showCachedHcAnyway,
          showCachedKtAnyway: showCachedKtAnyway,
          onShowCachedHc: onShowCachedHc,
          onShowCachedKt: onShowCachedKt,
          onHcAction: onHcAction,
          onOpenActivities: onOpenActivities,
          onOpenSteps: onOpenSteps,
          onOpenNutrition: onOpenNutrition,
          onOpenBody: onOpenBody,
          onOpenSleep: onOpenSleep,
        ),
      ],
    );
  }
}

/// Banner above the cards when the device is offline. Scopes its
/// subscription to `ConnectivityProvider.isOnline` only so the rest of
/// the day content stays clean when the provider notifies but the bool
/// hasn't flipped.
class _HomeOfflineBanner extends StatelessWidget {
  const _HomeOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Selector<ConnectivityProvider, bool>(
      selector: (_, c) => c.isOnline,
      builder: (context, isOnline, _) {
        if (isOnline) return const SizedBox.shrink();
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OfflineSourceBanner(
            message: l10n.homeOfflineBanner,
            onTap: () {},
          ),
        );
      },
    );
  }
}
