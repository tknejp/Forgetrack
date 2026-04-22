import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/sheets_export_provider.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_plain_card.dart';
import '../../profile/dialogs/profile_dialogs.dart';

class SheetsExportTargetCard extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportTargetCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = provider.spreadsheetId;
    final url = provider.spreadsheetUrl;

    return FtPlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.exportTargetLabel),
          const SizedBox(height: 8),
          if (id == null) ...[
            Text(
              l10n.exportTargetMissingBody,
              style: const TextStyle(
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
                  tooltip: l10n.exportTargetCopyLink,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: FtTokens.onSurfaceMuted,
                  ),
                  onPressed: url == null
                      ? null
                      : () => _copyLink(context, url, l10n),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _confirmForget(context, l10n),
                style: TextButton.styleFrom(
                  foregroundColor: FtTokens.onSurfaceMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.exportTargetForgetButton,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyLink(
    BuildContext context,
    String url,
    AppLocalizations l10n,
  ) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.exportTargetLinkCopied),
        backgroundColor: FtTokens.surface,
      ),
    );
  }

  Future<void> _confirmForget(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showProfileConfirmationDialog(
      context,
      title: l10n.exportTargetForgetConfirmTitle,
      message: l10n.exportTargetForgetConfirmMessage,
      confirmLabel: l10n.exportTargetForgetConfirmAction,
      isDestructive: true,
    );
    if (!confirmed) return;
    await provider.forgetSpreadsheet();
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
