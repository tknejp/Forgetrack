import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
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
      return _BannerShell(
        message: l10n.ktReauthRequired,
        ctaLabel: l10n.ktReauthCta,
        onCta: () => KTLoginSheet.show(context),
      );
    }

    final nextAt = kt.nextReconnectAt;
    if (nextAt != null) {
      final remaining = nextAt.difference(DateTime.now()).inSeconds;
      final seconds = remaining > 0 ? remaining : 0;
      return _BannerShell(
        message: l10n.ktReconnecting(seconds),
        ctaLabel: l10n.ktReconnectTryNow,
        onCta: kt.retryNow,
      );
    }

    if (kt.syncError != null) {
      return _BannerShell(
        message: l10n.ktSyncError,
        ctaLabel: l10n.ktRetry,
        onCta: widget.onRetry,
      );
    }

    if (!kt.isLoggedIn && kt.hasCachedNutrition) {
      return _InfoBannerShell(
        message: l10n.ktFooterOfflineHint,
        onTap: () => KTLoginSheet.show(context),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Muted info variant of [_BannerShell] for the offline-cache state.
/// Distinct from the red error/warning styling so users read it as
/// informational, not as a failure.
class _InfoBannerShell extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _InfoBannerShell({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ft.surfaceSubtle,
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: Tokens.fontSizeSmall,
                  color: ft.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  const _BannerShell({
    required this.message,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border:
            Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFFF87171),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                color: Color(0xCCFFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCta,
            child: Text(
              ctaLabel,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF87171),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
