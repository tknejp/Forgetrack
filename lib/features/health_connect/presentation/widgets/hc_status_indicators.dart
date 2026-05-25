import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/data_source_status_row.dart';
import '../../application/fitness_provider.dart';
import '../../application/health_connect_settings_launcher.dart';

/// Whether a Health Connect status indicator should render right now.
///
/// HC has a much simpler state machine than KT: the only surfaced
/// status is "permissions are revoked / HC unavailable but we're
/// rendering cached data anyway". Once `FitnessAccessState.ready` we
/// stay quiet. `checking` is also quiet so transient init states
/// don't flash a banner.
bool _hcStatusActive(FitnessProvider fitness) {
  switch (fitness.accessState) {
    case FitnessAccessState.ready:
    case FitnessAccessState.checking:
      return false;
    case FitnessAccessState.permissionRequired:
    case FitnessAccessState.unavailable:
      return true;
  }
}


/// In-card "system tray" rendered as the always-visible footer of any
/// Health Connect–driven home card (steps / weight / activity / sleep).
/// Sibling to [KtCardStatusFooter] — uses the same shared
/// [DataSourceStatusRow] primitive so the visual vocabulary matches
/// across data sources.
///
/// HC drives several cards from the same permission state, so the
/// same footer instance ends up on each HC card. That's intentional
/// even though the message repeats: home cards are user-reorderable,
/// so we can't rely on a single "first HC card" to anchor the status.
class HcCardStatusFooter extends StatelessWidget {
  const HcCardStatusFooter({super.key, required this.fitness});

  final FitnessProvider fitness;

  /// Mirrors [KtCardStatusFooter.isActive] — callers omit the
  /// [StatCard.footer] slot entirely when this returns false so the
  /// card avoids the divider+padding overhead in the steady state.
  static bool isActive(FitnessProvider fitness) => _hcStatusActive(fitness);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DataSourceStatusRow(
      icon: Icons.cloud_off_rounded,
      message: l10n.healthFooterOfflineHint,
      showTrailingChevron: true,
      onTap: () => runHcAccessFlow(fitness),
    );
  }
}

/// Standalone banner counterpart to [HcCardStatusFooter] for use on
/// detail screens (steps / body / activities / sleep) where there is
/// no enclosing card to hang a footer off. Matches the styling of
/// [KtSyncStatusBanner] so detail screens across data sources read
/// the same when the underlying source is in an offline state.
class HcStatusBanner extends StatelessWidget {
  const HcStatusBanner({super.key, required this.fitness});

  final FitnessProvider fitness;

  /// Whether the banner should render at all. Callers can skip
  /// surrounding spacing when this is false to avoid an empty gap.
  static bool isActive(FitnessProvider fitness) => _hcStatusActive(fitness);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DataSourceStatusBanner(
      icon: Icons.cloud_off_rounded,
      message: l10n.healthFooterOfflineHint,
      showTrailingChevron: true,
      onTap: () => runHcAccessFlow(fitness),
    );
  }
}
