import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../screens/profile/dialogs/profile_dialogs.dart';
import '../../../../theme/ft_design_tokens.dart';
import '../../../../widgets/ft/ft_plain_card.dart';
import '../../application/sheets_export_provider.dart';

class SheetsExportTargetCard extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportTargetCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = provider.spreadsheetId;
    final url = provider.spreadsheetUrl;

    return FtPlainCard(
      domain: id == null ? null : FtTokens.steps,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.table_chart_rounded,
            text: l10n.exportTargetLabel,
            color: id == null ? FtTokens.accent : FtTokens.steps.color,
          ),
          const SizedBox(height: 12),
          if (id == null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TargetIcon(
                  icon: Icons.add_to_drive_rounded,
                  color: FtTokens.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.exportTargetMissingBody,
                    style: const TextStyle(
                      fontSize: 13,
                      color: FtTokens.onSurfaceMuted,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                _TargetIcon(
                  icon: Icons.table_chart_rounded,
                  color: FtTokens.steps.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Forgetrack Data',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: FtTokens.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        url ?? id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
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
                  onPressed:
                      url == null ? null : () => _copyLink(context, url, l10n),
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
  final IconData icon;
  final String text;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: FtTokens.fontSizeMicro,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _TargetIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TargetIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}
