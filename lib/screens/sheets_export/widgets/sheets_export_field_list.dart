import 'package:flutter/material.dart';

import '../../../models/sheet_export_field.dart';
import '../../../providers/sheets_export_provider.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_plain_card.dart';

class SheetsExportFieldList extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportFieldList({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return FtPlainCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FIELDS TO EXPORT',
                style: TextStyle(
                  fontSize: FtTokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                  color: FtTokens.onSurfaceMuted,
                  letterSpacing: 0.9,
                ),
              ),
              Row(
                children: [
                  _LinkButton(
                    label: 'All',
                    onTap: provider.selectAllFields,
                  ),
                  const SizedBox(width: 8),
                  _LinkButton(
                    label: 'None',
                    onTap: provider.clearAllFields,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final cat in SheetExportCategory.values)
            _CategoryGroup(
              category: cat,
              provider: provider,
            ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final SheetExportCategory category;
  final SheetsExportProvider provider;

  const _CategoryGroup({required this.category, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fields = SheetExportFields.byCategory(category);
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: Text(
            SheetExportFields.categoryLabel(category),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: FtTokens.onSurface,
              letterSpacing: -0.2,
            ),
          ),
        ),
        for (final f in fields)
          _FieldRow(
            field: f,
            checked: provider.selectedKeys.contains(f.key),
            onChanged: (v) => provider.toggleField(f.key, v),
          ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final SheetExportField field;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _FieldRow({
    required this.field,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: FtTokens.accent,
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0x55FFFFFF)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FtTokens.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        field.header,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: FtTokens.onSurfaceFaint,
                        ),
                      ),
                    ],
                  ),
                  if (field.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      field.description!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FtTokens.onSurfaceMuted,
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
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: FtTokens.accent,
        ),
      ),
    );
  }
}
