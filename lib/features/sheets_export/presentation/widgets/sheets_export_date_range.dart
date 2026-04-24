import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../../../theme/ft_design_tokens.dart';
import '../../../../widgets/ft/ft_plain_card.dart';
import '../../application/sheets_export_provider.dart';

class SheetsExportDateRange extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportDateRange({super.key, required this.provider});

  static final DateFormat _fmt = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rangeLabel =
        '${_fmt.format(provider.from)} - ${_fmt.format(provider.to)}';

    return FtPlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: FtTokens.accent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    l10n.exportRangeLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: FtTokens.fontSizeMicro,
                      fontWeight: FontWeight.w800,
                      color: FtTokens.accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: FtTokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: FtTokens.accent.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  l10n.exportRangeDayCount(provider.dayCount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _pickRange(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      size: 18,
                      color: FtTokens.onSurfaceMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: FtTokens.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      l10n.exportRangePickButton,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: FtTokens.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Preset(
                label: l10n.exportRangePresetLast7,
                onTap: () => _applyLastNDays(7),
              ),
              _Preset(
                label: l10n.exportRangePresetLast30,
                onTap: () => _applyLastNDays(30),
              ),
              _Preset(
                label: l10n.exportRangePresetThisMonth,
                onTap: _applyThisMonth,
              ),
              _Preset(
                label: l10n.exportRangePresetLastMonth,
                onTap: _applyLastMonth,
              ),
            ],
          ),
          if (!provider.hasValidRange) ...[
            const SizedBox(height: 8),
            Text(
              l10n.exportRangeInvalid,
              style: const TextStyle(fontSize: 11, color: Color(0xFFF87171)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final today = DateTime.now();
    final lastDate = DateTime(today.year, today.month, today.day);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: provider.from, end: provider.to),
      firstDate: DateTime(2020),
      lastDate: lastDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: FtTokens.accent,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      provider.setRange(picked.start, picked.end);
    }
  }

  void _applyLastNDays(int n) {
    final today = DateTime.now();
    final to = DateTime(today.year, today.month, today.day);
    final from = to.subtract(Duration(days: n - 1));
    provider.setRange(from, to);
  }

  void _applyThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day);
    provider.setRange(start, end);
  }

  void _applyLastMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0);
    provider.setRange(start, end);
  }
}

class _Preset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Preset({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: FtTokens.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: FtTokens.accent.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: FtTokens.accent,
            ),
          ),
        ),
      ),
    );
  }
}
