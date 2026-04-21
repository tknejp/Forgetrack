import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../providers/sheets_export_provider.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_plain_card.dart';

class SheetsExportTargetCard extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportTargetCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final id = provider.spreadsheetId;
    final url = provider.spreadsheetUrl;

    return FtPlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Target spreadsheet'),
          const SizedBox(height: 8),
          if (id == null) ...[
            const Text(
              'No spreadsheet linked yet. A new "Forgetrack Data" spreadsheet '
              'will be created in your Google Drive on the first export.',
              style: TextStyle(
                fontSize: 13,
                color: FtTokens.onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FtTokens.steps.dim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.table_chart_rounded,
                    size: 18,
                    color: FtTokens.steps.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Forgetrack Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FtTokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        url ?? id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: FtTokens.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: FtTokens.onSurfaceMuted,
                  ),
                  onPressed: url == null
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Spreadsheet link copied'),
                                backgroundColor: FtTokens.surface,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => provider.forgetSpreadsheet(),
                style: TextButton.styleFrom(
                  foregroundColor: FtTokens.onSurfaceMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forget — create a new one next export',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: FtTokens.fontSizeMicro,
        fontWeight: FontWeight.w700,
        color: FtTokens.onSurfaceMuted,
        letterSpacing: 0.9,
      ),
    );
  }
}
