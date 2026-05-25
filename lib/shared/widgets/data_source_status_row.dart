import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Visual tone of a data-source status indicator. Drives icon + label
/// colour while keeping the row layout identical, so the same row can
/// represent informational ("showing saved data") and warning
/// ("reconnect in 12s") states without diverging widget trees.
enum DataSourceStatusTone {
  /// Muted neutral — used for the "viewing cached data" affordance.
  /// Icon and accent take [ThemeTokens.onSurfaceMuted].
  info,

  /// Red attention — used for hard failures (needs reauth, sync error,
  /// reconnect countdown). Icon and accent take the shared warning red.
  warning,
}

/// One-line status indicator with optional trailing CTA or chevron.
///
/// Shared layout primitive used by:
/// - per-card footers via [StatCard.footer] (no own container — sits on
///   top of the card's divider line);
/// - standalone in-screen banners via [DataSourceStatusBanner] (rounded
///   muted container above scrollable content on detail screens).
///
/// Both KT and Health Connect status indicators consume this widget so
/// every data source surfaces offline / reauth / failure states with
/// the same vocabulary.
class DataSourceStatusRow extends StatelessWidget {
  const DataSourceStatusRow({
    super.key,
    required this.icon,
    required this.message,
    required this.onTap,
    this.tone = DataSourceStatusTone.info,
    this.spinning = false,
    this.ctaLabel,
    this.showTrailingChevron = false,
  });

  /// Lead icon; ignored when [spinning] is true (a spinner takes its
  /// place to indicate an active reconnect attempt).
  final IconData icon;

  /// Body text, typically a single line. Truncated by [Expanded] if it
  /// runs past the available width.
  final String message;

  /// Whole-row tap target. Mirrored to the CTA chip when provided.
  final VoidCallback onTap;

  final DataSourceStatusTone tone;

  /// When true a small [CircularProgressIndicator] replaces the leading
  /// icon. Used for "reconnecting in Xs" states.
  final bool spinning;

  /// Optional trailing action label (e.g. "Try again", "Sign in").
  /// When omitted callers may instead set [showTrailingChevron] to
  /// indicate the whole row is tappable.
  final String? ctaLabel;

  /// Renders a `>` chevron at the end of the row. Use when there is no
  /// explicit CTA label but the row is still tappable.
  final bool showTrailingChevron;

  Color _accentColor(ThemeTokens ft) {
    return switch (tone) {
      DataSourceStatusTone.info => ft.onSurfaceMuted,
      DataSourceStatusTone.warning => const Color(0xFFF87171),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final accent = _accentColor(ft);
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
                    color: accent,
                  ),
                )
              : Icon(icon, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: ft.onSurfaceMuted,
              ),
            ),
          ),
          if (ctaLabel != null) ...[
            const SizedBox(width: 6),
            Text(
              ctaLabel!,
              style: TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ] else if (showTrailingChevron) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: ft.onSurfaceMuted,
            ),
          ],
        ],
      ),
    );
  }
}

/// Standalone banner variant of [DataSourceStatusRow]. Wraps the row in
/// a rounded muted container with the card-border ring and is meant to
/// sit above scrollable content on detail screens (Nutrition / Steps /
/// Body / Sleep / Activity) where there is no enclosing card divider
/// to lean on.
class DataSourceStatusBanner extends StatelessWidget {
  const DataSourceStatusBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.onTap,
    this.tone = DataSourceStatusTone.info,
    this.spinning = false,
    this.ctaLabel,
    this.showTrailingChevron = false,
  });

  final IconData icon;
  final String message;
  final VoidCallback onTap;
  final DataSourceStatusTone tone;
  final bool spinning;
  final String? ctaLabel;
  final bool showTrailingChevron;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final isWarning = tone == DataSourceStatusTone.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFF87171).withValues(alpha: 0.12)
            : ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFF87171).withValues(alpha: 0.3)
              : ft.cardBorder,
        ),
      ),
      child: DataSourceStatusRow(
        icon: icon,
        message: message,
        onTap: onTap,
        tone: tone,
        spinning: spinning,
        ctaLabel: ctaLabel,
        showTrailingChevron: showTrailingChevron,
      ),
    );
  }
}
