import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DevToolsStatusTile extends StatelessWidget {
  const DevToolsStatusTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onCopy,
    this.mono = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onCopy;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: tt.bodySmall?.copyWith(
                      color: valueColor ?? cs.onSurface,
                      fontFamily: mono ? 'monospace' : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onCopy,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Copies [text] to the clipboard and shows a [SnackBar].
void copyToClipboard(BuildContext context, String text, {String? label}) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(label != null ? '$label copied' : 'Copied'), // TODO: l10n
      duration: const Duration(seconds: 2),
    ),
  );
}
