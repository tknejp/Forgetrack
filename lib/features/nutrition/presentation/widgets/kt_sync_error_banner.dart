import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/data_source_status_row.dart';
import '../../../onboarding/widgets/kt_login_sheet.dart';
import '../../application/kaloricke_tabulky_provider.dart';

/// Multi-state KT sync banner driven by [KalorickeTabulkyProvider]:
///
/// 1. **needsReauth** — silent session refresh was rejected by KT, the
///    stored hash is no longer valid. Shows the reauth CTA which opens
///    [KTLoginSheet] over the current screen.
/// 2. **isReconnecting** — silent refresh just failed on the network;
///    next attempt is scheduled. Shows a live countdown plus a
///    "Try now" button that bypasses the throttle.
/// 3. **syncError** — refresh succeeded but the data endpoint still
///    fails. Shows the legacy "retry" CTA which calls [onRetry].
/// 4. **offlineCache** — user is viewing cached data while logged out.
///    Soft info banner (muted, cloud_off icon) that opens the KT login
///    sheet on tap.
///
/// When none of the above is active, the banner shrinks to nothing so
/// it's safe to embed unconditionally inside list/column layouts.
class KtSyncStatusBanner extends StatefulWidget {
  final KalorickeTabulkyProvider kt;
  final VoidCallback onRetry;

  const KtSyncStatusBanner({
    super.key,
    required this.kt,
    required this.onRetry,
  });

  /// Whether the provider state currently warrants showing a banner.
  /// Mirrors [KtCardStatusFooter.isActive] for the home footer; callers
  /// can use this to skip surrounding spacing when the banner would
  /// render as an empty box.
  static bool isActive(KalorickeTabulkyProvider kt) {
    if (kt.needsReauth) return true;
    if (kt.isReconnecting) return true;
    if (kt.syncError != null) return true;
    if (!kt.isLoggedIn && kt.hasCachedNutrition) return true;
    return false;
  }

  @override
  State<KtSyncStatusBanner> createState() => _KtSyncStatusBannerState();
}

class _KtSyncStatusBannerState extends State<KtSyncStatusBanner> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _ensureTickerForCountdown();
  }

  @override
  void didUpdateWidget(covariant KtSyncStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureTickerForCountdown();
  }

  void _ensureTickerForCountdown() {
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
      return DataSourceStatusBanner(
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
      return DataSourceStatusBanner(
        icon: Icons.sync,
        tone: DataSourceStatusTone.warning,
        spinning: true,
        message: l10n.ktReconnecting(seconds),
        ctaLabel: l10n.ktReconnectTryNow,
        onTap: kt.retryNow,
      );
    }

    if (kt.syncError != null) {
      return DataSourceStatusBanner(
        icon: Icons.warning_amber_rounded,
        tone: DataSourceStatusTone.warning,
        message: l10n.ktSyncError,
        ctaLabel: l10n.ktRetry,
        onTap: widget.onRetry,
      );
    }

    if (!kt.isLoggedIn && kt.hasCachedNutrition) {
      return DataSourceStatusBanner(
        icon: Icons.cloud_off_rounded,
        message: l10n.ktFooterOfflineHint,
        showTrailingChevron: true,
        onTap: () => KTLoginSheet.show(context),
      );
    }

    return const SizedBox.shrink();
  }
}
