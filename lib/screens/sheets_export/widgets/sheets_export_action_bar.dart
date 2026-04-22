import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/sheets_export_provider.dart';
import '../../../theme/ft_design_tokens.dart';

class SheetsExportActionBar extends StatelessWidget {
  final SheetsExportProvider provider;
  final VoidCallback onExport;

  const SheetsExportActionBar({
    super.key,
    required this.provider,
    required this.onExport,
  });

  static final DateFormat _short = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fields = provider.selectedFields.length;
    final range =
        '${_short.format(provider.from)} – ${_short.format(provider.to)}';
    final summary = l10n.exportSummary(provider.dayCount, fields, range);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            summary,
            style: const TextStyle(
              fontSize: 12,
              color: FtTokens.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FtTokens.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  FtTokens.accent.withValues(alpha: 0.18),
              disabledForegroundColor: const Color(0x66FFFFFF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: Colors.transparent,
            ),
            onPressed: provider.canExport ? onExport : null,
            child: provider.isExporting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.exportButtonRunning,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.exportButton,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
