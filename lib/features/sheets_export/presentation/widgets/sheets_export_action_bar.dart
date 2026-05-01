import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/sheets_export_provider.dart';

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
        '${_short.format(provider.from)} - ${_short.format(provider.to)}';
    final summary = l10n.exportSummary(provider.dayCount, fields, range);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 16,
                color: Tokens.onSurfaceMuted,
              ),
              const SizedBox(width: Tokens.spaceSm),
              Expanded(
                child: Text(
                  summary,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeSmall,
                    color: Tokens.onSurfaceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Tokens.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Tokens.accent.withValues(alpha: 0.18),
                disabledForegroundColor: const Color(0x66FFFFFF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Tokens.radiusTile),
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
                        const SizedBox(width: Tokens.spaceMd),
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
                        const SizedBox(width: Tokens.spaceSm),
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
      ),
    );
  }
}
