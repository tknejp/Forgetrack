import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
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
              greeting: l10n.sectionData,
              title: l10n.exportScreenTitle,
              leading: const FtBackButton(),
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
            const SizedBox(height: Tokens.spaceMd),
            SheetsExportTargetCard(provider: exportProvider),
            const SizedBox(height: Tokens.spaceMd),
            SheetsExportDateRange(provider: exportProvider),
            const SizedBox(height: Tokens.spaceMd),
            SheetsExportFieldList(provider: exportProvider),
            const SizedBox(height: Tokens.spaceMd),
            SheetsExportStatusBanner(provider: exportProvider),
            const SizedBox(height: Tokens.spaceLg),
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
          backgroundColor: Tokens.surface,
          content: Text(
            l10n.exportSuccessDetail(
              result.rowsWritten,
              result.rowsAdded,
              result.rowsUpdated,
            ),
            style: const TextStyle(color: Tokens.onSurface),
          ),
        ),
      );
    }
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
    final color = isReady ? Tokens.steps.color : Tokens.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.16),
            Tokens.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
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
          const SizedBox(width: Tokens.spaceMd),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Tokens.onSurface,
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
        color: Tokens.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: 16,
            color: Tokens.accent.withValues(alpha: 0.88),
          ),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Text(
              context.l10n.exportAuthorizationNote,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.35,
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
          fontSize: Tokens.fontSizeSmall,
          color: Tokens.onSurfaceMuted,
          height: 1.4,
        ),
      ),
    );
  }
}
