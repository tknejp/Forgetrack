import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/data_source_status_row.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../onboarding/widgets/kt_login_sheet.dart';

/// In-card "system tray" rendered as the always-visible footer of the
/// home calorie card. Replaces the older between-card banners
/// (`OfflineSourceBanner` + `KtSyncStatusBanner` stacked above the
/// card) with a single status row glued to the bottom of the KT card.
///
/// State priority (top-down):
///   1. `needsReauth` — silent refresh was rejected by KT (red).
///   2. `isReconnecting` — silent refresh failed on the network, live
///      countdown + "Try now".
///   3. `syncError` — refresh OK but data endpoint still fails.
///   4. `!isLoggedIn && hasCache` — viewing cached data, tap to connect.
///   5. None — footer hides (StatCard suppresses divider + slot).
///
/// The widget owns a 1 s Timer only while the countdown state is
/// active; otherwise it's idle.
class KtCardStatusFooter extends StatefulWidget {
  final KalorickeTabulkyProvider kt;
  final VoidCallback onSyncRetry;

  const KtCardStatusFooter({
    super.key,
    required this.kt,
    required this.onSyncRetry,
  });

  /// Whether the provider state currently warrants a footer at all.
  /// Used by callers to omit the slot entirely (and skip the
  /// StatCard divider) when there's nothing to show.
  static bool isActive(KalorickeTabulkyProvider kt) {
    if (kt.needsReauth) return true;
    if (kt.isReconnecting) return true;
    if (kt.isLoggedIn && kt.syncError != null) return true;
    if (!kt.isLoggedIn && kt.hasCachedNutrition) return true;
    return false;
  }

  @override
  State<KtCardStatusFooter> createState() => _KtCardStatusFooterState();
}

class _KtCardStatusFooterState extends State<KtCardStatusFooter> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _ensureTicker();
  }

  @override
  void didUpdateWidget(covariant KtCardStatusFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureTicker();
  }

  void _ensureTicker() {
    final showCountdown = widget.kt.nextReconnectAt != null;
    if (showCountdown && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!showCountdown && _tick != null) {
      _tick!.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kt = widget.kt;

    if (kt.needsReauth) {
      return DataSourceStatusRow(
        icon: Icons.error_outline,
        tone: DataSourceStatusTone.warning,
        message: l10n.ktReauthRequired,
        ctaLabel: l10n.ktReauthCta,
        onTap: () => KTLoginSheet.show(context),
      );
    }

    final nextAt = kt.nextReconnectAt;
    if (nextAt != null) {
      final remaining = nextAt.difference(DateTime.now()).inSeconds;
      final seconds = remaining > 0 ? remaining : 0;
      return DataSourceStatusRow(
        icon: Icons.sync,
        tone: DataSourceStatusTone.warning,
        spinning: true,
        message: l10n.ktReconnecting(seconds),
        ctaLabel: l10n.ktReconnectTryNow,
        onTap: kt.retryNow,
      );
    }

    if (kt.isLoggedIn && kt.syncError != null) {
      return DataSourceStatusRow(
        icon: Icons.warning_amber_rounded,
        tone: DataSourceStatusTone.warning,
        message: l10n.ktSyncError,
        ctaLabel: l10n.ktRetry,
        onTap: widget.onSyncRetry,
      );
    }

    if (!kt.isLoggedIn && kt.hasCachedNutrition) {
      return DataSourceStatusRow(
        icon: Icons.cloud_off_rounded,
        message: l10n.ktFooterOfflineHint,
        showTrailingChevron: true,
        onTap: () => KTLoginSheet.show(context),
      );
    }

    return const SizedBox.shrink();
  }
}
