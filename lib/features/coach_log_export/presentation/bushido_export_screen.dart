import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/bushido_export_provider.dart';

class BushidoExportScreen extends StatefulWidget {
  const BushidoExportScreen({super.key});

  @override
  State<BushidoExportScreen> createState() => _BushidoExportScreenState();
}

class _BushidoExportScreenState extends State<BushidoExportScreen> {
  static final _dateFmt = DateFormat('d MMM yyyy');

  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _from = today.subtract(const Duration(days: 6));
    _to = today;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<BushidoExportProvider>();
    final isExporting = provider.isExporting;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Tokens.bg,
      ),
      child: Scaffold(
        backgroundColor: Tokens.bg,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            14,
            MediaQuery.of(context).padding.top + 12,
            14,
            28,
          ),
          children: [
            ScreenHeader(
              greeting: context.l10n.sectionData,
              title: l10n.coachLogExportTitle,
              leading: const FtBackButton(),
            ),
            const SizedBox(height: 18),
            _HeroCard(description: l10n.coachLogExportDescription),
            const SizedBox(height: Tokens.spaceMd),
            _CurrentWeekCard(
              isExporting: isExporting,
              onExport: () => _exportCurrentWeek(context),
            ),
            const SizedBox(height: Tokens.spaceMd),
            _RangeCard(
              from: _from,
              to: _to,
              isExporting: isExporting,
              dateFmt: _dateFmt,
              onPickRange: () => _pickRange(context),
              onExport: () => _exportRange(context),
            ),
            if (provider.isExporting) ...[
              const SizedBox(height: Tokens.spaceMd),
              const _ExportingBanner(),
            ],
            if (provider.lastError != null) ...[
              const SizedBox(height: Tokens.spaceMd),
              _ErrorBanner(message: provider.lastError!),
            ],
            if (provider.lastResult != null && !provider.isExporting) ...[
              const SizedBox(height: Tokens.spaceMd),
              _SuccessCard(
                result: provider.lastResult!,
                openSheetsLabel: l10n.coachLogExportOpenSheets,
                successLabel: l10n.coachLogExportSuccessWeeks(
                  provider.lastResult!.weeksExported,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Tokens.accent,
                onPrimary: Colors.white,
                surface: Tokens.surface,
                onSurface: Tokens.onSurface,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  Future<void> _exportCurrentWeek(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<BushidoExportProvider>();
    try {
      await provider.exportCurrentWeek(l10n: l10n);
    } catch (_) {
      // error surfaced via provider.lastError
    }
  }

  Future<void> _exportRange(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<BushidoExportProvider>();
    try {
      await provider.exportRange(from: _from, to: _to, l10n: l10n);
    } catch (_) {
      // error surfaced via provider.lastError
    }
  }
}

// ─── Hero card ─────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String description;

  const _HeroCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Tokens.accent.withValues(alpha: 0.14),
            Tokens.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Tokens.accent.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Tokens.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Tokens.accent.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.table_chart_outlined,
              color: Tokens.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: Tokens.spaceMd),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.4,
                color: Tokens.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Export current week card ───────────────────────────────────────────────

class _CurrentWeekCard extends StatelessWidget {
  final bool isExporting;
  final VoidCallback onExport;

  const _CurrentWeekCard({
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekFmt = DateFormat('d MMM');
    final label = '${weekFmt.format(monday)} – ${weekFmt.format(today)}';

    return _ActionCard(
      icon: Icons.today_rounded,
      iconColor: Tokens.steps.color,
      title: l10n.coachLogExportCurrentWeekButton,
      subtitle: label,
      isExporting: isExporting,
      onExport: onExport,
    );
  }
}

// ─── Export range card ──────────────────────────────────────────────────────

class _RangeCard extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final bool isExporting;
  final DateFormat dateFmt;
  final VoidCallback onPickRange;
  final VoidCallback onExport;

  const _RangeCard({
    required this.from,
    required this.to,
    required this.isExporting,
    required this.dateFmt,
    required this.onPickRange,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rangeLabel = '${dateFmt.format(from)} – ${dateFmt.format(to)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: isExporting ? null : onPickRange,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Tokens.radiusCard),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2A35A).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                      border: Border.all(
                          color:
                              const Color(0xFFF2A35A).withValues(alpha: 0.22)),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: Color(0xFFF2A35A),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rangeLabel,
                          style: const TextStyle(
                            fontSize: Tokens.fontSizeBody,
                            fontWeight: FontWeight.w700,
                            color: Tokens.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.exportRangeLabel,
                          style: const TextStyle(
                            fontSize: Tokens.fontSizeSmall,
                            color: Tokens.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Tokens.onSurfaceMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: Tokens.divider,
            indent: 14,
            endIndent: 14,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: _ExportButton(
              label: l10n.coachLogExportRangeButton,
              isExporting: isExporting,
              onPressed: onExport,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared action card (current week + range) ──────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isExporting;
  final VoidCallback onExport;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: iconColor.withValues(alpha: 0.22)),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeBody,
                          fontWeight: FontWeight.w700,
                          color: Tokens.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeSmall,
                          color: Tokens.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Tokens.divider,
            indent: 14,
            endIndent: 14,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: _ExportButton(
              label: l10n.coachLogExportCurrentWeekButton,
              isExporting: isExporting,
              onPressed: onExport,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable export button ────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  final String label;
  final bool isExporting;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.label,
    required this.isExporting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final child = isExporting
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(l10n.coachLogExportRunning),
            ],
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isExporting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Tokens.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: Tokens.fontSizeBody,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─── Status banners ─────────────────────────────────────────────────────────

class _ExportingBanner extends StatelessWidget {
  const _ExportingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Tokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Tokens.accent,
            ),
          ),
          const SizedBox(width: Tokens.spaceMd),
          Text(
            context.l10n.coachLogExportRunning,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              color: Tokens.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Tokens.danger.withValues(alpha: 0.85),
          ),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.4,
                color: Tokens.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final BushidoExportResult result;
  final String successLabel;
  final String openSheetsLabel;

  const _SuccessCard({
    required this.result,
    required this.successLabel,
    required this.openSheetsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Tokens.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.success.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Tokens.success.withValues(alpha: 0.9),
          ),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Text(
              successLabel,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                color: Tokens.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: Tokens.spaceSm),
          GestureDetector(
            onTap: () => _copyLink(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Tokens.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Tokens.radiusButton),
                border:
                    Border.all(color: Tokens.success.withValues(alpha: 0.24)),
              ),
              child: Text(
                openSheetsLabel,
                style: TextStyle(
                  fontSize: Tokens.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                  color: Tokens.success.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: result.spreadsheetUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Tokens.surface,
        content: Text(
          context.l10n.exportTargetLinkCopied,
          style: const TextStyle(color: Tokens.onSurface),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
