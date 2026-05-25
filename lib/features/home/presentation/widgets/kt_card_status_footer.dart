import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
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
      return _FooterRow(
        icon: Icons.error_outline,
        iconColor: const Color(0xFFF87171),
        message: l10n.ktReauthRequired,
        cta: l10n.ktReauthCta,
        onTap: () => KTLoginSheet.show(context),
      );
    }

    final nextAt = kt.nextReconnectAt;
    if (nextAt != null) {
      final remaining = nextAt.difference(DateTime.now()).inSeconds;
      final seconds = remaining > 0 ? remaining : 0;
      return _FooterRow(
        icon: Icons.sync,
        iconColor: const Color(0xFFF59E0B),
        spinning: true,
        message: l10n.ktReconnecting(seconds),
        cta: l10n.ktReconnectTryNow,
        onTap: kt.retryNow,
      );
    }

    if (kt.isLoggedIn && kt.syncError != null) {
      return _FooterRow(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFF87171),
        message: l10n.ktSyncError,
        cta: l10n.ktRetry,
        onTap: widget.onSyncRetry,
      );
    }

    if (!kt.isLoggedIn && kt.hasCachedNutrition) {
      return _FooterRow(
        icon: Icons.cloud_off_rounded,
        message: l10n.ktFooterOfflineHint,
        // Whole row is the CTA — no separate label needed.
        onTap: () => KTLoginSheet.show(context),
        trailing: const Icon(Icons.chevron_right_rounded, size: 16),
      );
    }

    return const SizedBox.shrink();
  }
}

class _FooterRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final bool spinning;
  final String message;
  final String? cta;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FooterRow({
    required this.icon,
    required this.message,
    required this.onTap,
    this.iconColor,
    this.spinning = false,
    this.cta,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final resolvedIconColor = iconColor ?? ft.onSurfaceMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          spinning
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: resolvedIconColor,
                  ),
                )
              : Icon(icon, size: 14, color: resolvedIconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ft.onSurfaceMuted,
              ),
            ),
          ),
          if (cta != null) ...[
            const SizedBox(width: 6),
            Text(
              cta!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: resolvedIconColor,
              ),
            ),
          ] else if (trailing != null) ...[
            const SizedBox(width: 6),
            IconTheme(
              data: IconThemeData(color: ft.onSurfaceMuted),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
