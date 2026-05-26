import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/plain_card.dart';
import '../../application/sheet_export_field.dart';
import '../../application/sheets_export_provider.dart';

class SheetsExportFieldList extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportFieldList({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PlainCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.view_column_outlined,
                    size: 14,
                    color: Tokens.accent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    l10n.exportFieldsLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeMicro,
                      fontWeight: FontWeight.w800,
                      color: Tokens.accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceSm),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Tokens.accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(Tokens.radiusProgress),
                      border: Border.all(
                        color: Tokens.accent.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      '${provider.selectedFields.length}/${SheetExportFields.all.length}',
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeMicro,
                        fontWeight: FontWeight.w800,
                        color: Tokens.accent,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _LinkButton(
                    label: l10n.exportFieldsSelectAll,
                    onTap: provider.selectAllFields,
                  ),
                  const SizedBox(width: Tokens.spaceSm),
                  _LinkButton(
                    label: l10n.exportFieldsSelectNone,
                    onTap: provider.clearAllFields,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceXs),
          for (final cat in SheetExportCategory.values)
            _CategoryGroup(
              category: cat,
              provider: provider,
              l10n: l10n,
            ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final SheetExportCategory category;
  final SheetsExportProvider provider;
  final AppLocalizations l10n;

  const _CategoryGroup({
    required this.category,
    required this.provider,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fields = SheetExportFields.byCategory(category);
    if (fields.isEmpty) return const SizedBox.shrink();
    final color = _categoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: Text(
            SheetExportFields.categoryLabel(category, l10n),
            style: TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final f in fields)
          _FieldRow(
            field: f,
            color: color,
            l10n: l10n,
            checked: provider.selectedKeys.contains(f.key),
            onChanged: (v) => provider.toggleField(f.key, v),
          ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final SheetExportField field;
  final Color color;
  final AppLocalizations l10n;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _FieldRow({
    required this.field,
    required this.color,
    required this.l10n,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final desc = field.description?.call(l10n);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: color,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: BorderSide(color: color.withValues(alpha: 0.48)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label(l10n),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: checked
                          ? Tokens.onSurface
                          : Tokens.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  if (desc != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeCaption,
                        color: Tokens.onSurfaceMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w800,
              color: Tokens.accent,
            ),
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(SheetExportCategory category) {
  switch (category) {
    case SheetExportCategory.activity:
      return Tokens.steps.color;
    case SheetExportCategory.body:
      return Tokens.weight.color;
    case SheetExportCategory.sleep:
      return Tokens.sleep.color;
    case SheetExportCategory.nutrition:
      return Tokens.calories.color;
  }
}
