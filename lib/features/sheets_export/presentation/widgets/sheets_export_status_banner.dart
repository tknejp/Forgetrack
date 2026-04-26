import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/ft_design_tokens.dart';
import '../../application/sheets_export_provider.dart';

class SheetsExportStatusBanner extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportStatusBanner({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    switch (provider.status) {
      case SheetsExportStatus.idle:
      case SheetsExportStatus.exporting:
        return const SizedBox.shrink();
      case SheetsExportStatus.success:
        final r = provider.lastResult;
        return _Banner(
          color: const Color(0xFF34D399),
          icon: Icons.check_circle_rounded,
          title: l10n.exportSuccessTitle,
          message: r == null
              ? l10n.exportSuccessTitle
              : l10n.exportSuccessDetail(
                  r.rowsWritten,
                  r.rowsAdded,
                  r.rowsUpdated,
                ),
        );
      case SheetsExportStatus.error:
        return _Banner(
          color: const Color(0xFFF87171),
          icon: Icons.error_outline_rounded,
          title: l10n.exportErrorTitle,
          message: provider.errorMessage ?? l10n.exportErrorGeneric,
          onDismiss: provider.resetMessage,
        );
    }
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FtTokens.onSurface,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: FtTokens.onSurfaceMuted,
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
        ],
      ),
    );
  }
}
