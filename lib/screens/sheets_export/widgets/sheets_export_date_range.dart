import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../providers/sheets_export_provider.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_plain_card.dart';

class SheetsExportDateRange extends StatelessWidget {
  final SheetsExportProvider provider;
  const SheetsExportDateRange({super.key, required this.provider});

  static final DateFormat _fmt = DateFormat('EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return FtPlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DATE RANGE',
                style: TextStyle(
                  fontSize: FtTokens.fontSizeMicro,
                  fontWeight: FontWeight.w700,
                  color: FtTokens.onSurfaceMuted,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                '${provider.dayCount} day(s)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FtTokens.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  date: provider.from,
                  onPick: (d) => provider.setFrom(d),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: 'To',
                  date: provider.to,
                  onPick: (d) => provider.setTo(d),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Preset(
                label: 'Last 7d',
                onTap: () => _applyLastNDays(7),
              ),
              _Preset(
                label: 'Last 30d',
                onTap: () => _applyLastNDays(30),
              ),
              _Preset(
                label: 'This month',
                onTap: _applyThisMonth,
              ),
              _Preset(
                label: 'Last month',
                onTap: _applyLastMonth,
              ),
            ],
          ),
          if (!provider.hasValidRange) ...[
            const SizedBox(height: 8),
            const Text(
              '"To" must be on or after "From".',
              style: TextStyle(fontSize: 11, color: Color(0xFFF87171)),
            ),
          ],
        ],
      ),
    );
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate,
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
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: FtTokens.fontSizeMicro,
                fontWeight: FontWeight.w700,
                color: FtTokens.onSurfaceMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              SheetsExportDateRange._fmt.format(date),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FtTokens.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Preset({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            fontWeight: FontWeight.w700,
            color: FtTokens.accent,
          ),
        ),
      ),
    );
  }
}
