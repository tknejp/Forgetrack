import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../application/sheets_export_provider.dart';
import '../domain/sheet_export_field.dart';
import 'widgets/sheets_export_action_bar.dart';
import 'widgets/sheets_export_date_range.dart';
import 'widgets/sheets_export_field_list.dart';
import 'widgets/sheets_export_status_banner.dart';
import 'widgets/sheets_export_target_card.dart';

class SheetsExportScreen extends StatelessWidget {
  const SheetsExportScreen({super.key});

  static final DateFormat _shortRange = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final exportProvider = context.watch<SheetsExportProvider>();
    final range =
        '${_shortRange.format(exportProvider.from)} - ${_shortRange.format(exportProvider.to)}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: FtTokens.bg,
      ),
      child: Scaffold(
        backgroundColor: FtTokens.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            children: [
              _ExportHeader(
                eyebrow: l10n.sectionData,
                title: l10n.exportScreenTitle,
              ),
              const SizedBox(height: 18),
              _ExportCommandCard(
                summary: l10n.exportSummary(
                  exportProvider.dayCount,
                  exportProvider.selectedFields.length,
                  range,
                ),
                isReady: exportProvider.canExport,
              ),
              const SizedBox(height: 12),
              SheetsExportTargetCard(provider: exportProvider),
              const SizedBox(height: 12),
              SheetsExportDateRange(provider: exportProvider),
              const SizedBox(height: 12),
              SheetsExportFieldList(provider: exportProvider),
              const SizedBox(height: 12),
              SheetsExportStatusBanner(provider: exportProvider),
              const SizedBox(height: 16),
              const _AuthorizationNote(),
              const SizedBox(height: 10),
              SheetsExportActionBar(
                provider: exportProvider,
                onExport: () => _runExport(context, exportProvider),
              ),
              const SizedBox(height: 14),
              const _ExplainerText(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runExport(
    BuildContext context,
    SheetsExportProvider provider,
  ) async {
    final l10n = context.l10n;
    final fitness = context.read<FitnessProvider>();
    final nutrition = context.read<KalorickeTabulkyProvider>();
    final src = SheetExportDataSources(fitness: fitness, nutrition: nutrition);
    await provider.runExport(src, l10n: l10n);

    if (!context.mounted) return;
    final result = provider.lastResult;
    if (provider.status == SheetsExportStatus.success && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: FtTokens.surface,
          content: Text(
            l10n.exportSuccessDetail(
              result.rowsWritten,
              result.rowsAdded,
              result.rowsUpdated,
            ),
            style: const TextStyle(color: FtTokens.onSurface),
          ),
        ),
      );
    }
  }
}

class _ExportHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _ExportHeader({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: FtTokens.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportCommandCard extends StatelessWidget {
  final String summary;
  final bool isReady;

  const _ExportCommandCard({
    required this.summary,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final color = isReady ? FtTokens.steps.color : FtTokens.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            FtTokens.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(FtTokens.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.24)),
            ),
            child: Icon(
              isReady ? Icons.cloud_done_rounded : Icons.tune_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: FtTokens.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorizationNote extends StatelessWidget {
  const _AuthorizationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FtTokens.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtTokens.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 16,
            color: FtTokens.accent.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.exportAuthorizationNote,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: FtTokens.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainerText extends StatelessWidget {
  const _ExplainerText();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        l10n.exportExplainer(today),
        style: const TextStyle(
          fontSize: 12,
          color: FtTokens.onSurfaceMuted,
          height: 1.4,
        ),
      ),
    );
  }
}
