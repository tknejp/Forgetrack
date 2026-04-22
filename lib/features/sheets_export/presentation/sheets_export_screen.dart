import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../theme/ft_design_tokens.dart';
import '../../../widgets/ft/ft_plain_card.dart';
import '../../auth/application/auth_provider.dart';
import '../application/sheets_export_provider.dart';
import '../domain/sheet_export_field.dart';
import 'widgets/sheets_export_action_bar.dart';
import 'widgets/sheets_export_date_range.dart';
import 'widgets/sheets_export_field_list.dart';
import 'widgets/sheets_export_status_banner.dart';
import 'widgets/sheets_export_target_card.dart';

class SheetsExportScreen extends StatelessWidget {
  const SheetsExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final exportProvider = context.watch<SheetsExportProvider>();

    return Scaffold(
      backgroundColor: FtTokens.bg,
      appBar: AppBar(
        backgroundColor: FtTokens.bg,
        elevation: 0,
        title: Text(
          l10n.exportScreenTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: FtTokens.onSurface),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            if (!auth.isSignedIn)
              const _SignInRequiredCard()
            else ...[
              SheetsExportTargetCard(provider: exportProvider),
              const SizedBox(height: 12),
              SheetsExportDateRange(provider: exportProvider),
              const SizedBox(height: 12),
              SheetsExportFieldList(provider: exportProvider),
              const SizedBox(height: 12),
              SheetsExportStatusBanner(provider: exportProvider),
              const SizedBox(height: 16),
              SheetsExportActionBar(
                provider: exportProvider,
                onExport: () => _runExport(context, exportProvider),
              ),
              const SizedBox(height: 14),
              const _ExplainerText(),
            ],
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

// ── Sign-in gate ─────────────────────────────────────────────────────────────

class _SignInRequiredCard extends StatelessWidget {
  const _SignInRequiredCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    return FtPlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.exportSignInTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: FtTokens.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.exportSignInBody,
            style: const TextStyle(
              fontSize: 13,
              color: FtTokens.onSurfaceMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FtTokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: auth.isLoading ? null : () => auth.signIn(),
              child: Text(
                auth.isLoading ? l10n.exportSignInLoading : l10n.exportSignInButton,
              ),
            ),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 10),
            Text(
              auth.error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFF87171)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Footer note ──────────────────────────────────────────────────────────────

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
