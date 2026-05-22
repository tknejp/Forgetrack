import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../domain/cosmetic_models.dart';

class DebugDetailsSection extends StatelessWidget {
  const DebugDetailsSection({
    super.key,
    required this.definition,
    required this.unlock,
    required this.color,
  });

  final Cosmetic definition;
  final UnlockedCosmetic? unlock;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Icon(Icons.bug_report_outlined,
                  size: 13, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).debugDetailsHeader,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          children: [
            _DebugRow(AppLocalizations.of(context).debugRowId, definition.id, copyable: true),
            _DebugRow(AppLocalizations.of(context).debugRowType, definition.type.name),
            _DebugRow(AppLocalizations.of(context).debugRowRarity, definition.rarity.name),
            _DebugRow(AppLocalizations.of(context).debugRowRegion, definition.region.name),
            _DebugRow(
              AppLocalizations.of(context).debugRowAssetKey,
              definition.assetKey ?? AppLocalizations.of(context).debugMissing,
              warn: definition.assetKey == null,
              copyable: definition.assetKey != null,
            ),
            if (definition.previewAssetKey != null &&
                definition.previewAssetKey != definition.assetKey)
              _DebugRow(AppLocalizations.of(context).debugRowPreviewAssetKey, definition.previewAssetKey!, copyable: true),
            _DebugRow(AppLocalizations.of(context).debugRowSortOrder, '${definition.sortOrder}'),
            _DebugRow(
              AppLocalizations.of(context).debugRowIsPremium,
              '${definition.isPremium}',
              warn: definition.isPremium,
            ),
            _DebugRow(
              AppLocalizations.of(context).debugRowIsEnabled,
              '${definition.isEnabled}',
              warn: !definition.isEnabled,
            ),
            if (definition.metadata.isNotEmpty)
              _DebugRow(AppLocalizations.of(context).debugRowMetadata, _fmtMap(definition.metadata)),
            if (unlock != null) ...[
              const Divider(height: 14, thickness: 1),
              _DebugRow(
                AppLocalizations.of(context).debugRowUnlockedAt,
                unlock!.unlockedAt.toIso8601String(),
              ),
              if (unlock!.sourceType != null)
                _DebugRow(AppLocalizations.of(context).debugRowSourceType, unlock!.sourceType!),
              if (unlock!.sourceId != null)
                _DebugRow(AppLocalizations.of(context).debugRowSourceId, unlock!.sourceId!),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtMap(Map<String, Object?> map) {
    if (map.isEmpty) return '{}';
    final entries =
        map.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '{ $entries }';
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow(
    this.label,
    this.value, {
    this.warn = false,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool warn;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueColor = warn
        ? Colors.orange.withValues(alpha: 0.9)
        : cs.onSurfaceVariant.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
              child: GestureDetector(
              onLongPress: copyable
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context).copiedToClipboard(value)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).copiedToClipboard(value)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
