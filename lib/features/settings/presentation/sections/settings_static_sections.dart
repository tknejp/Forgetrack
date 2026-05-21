import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/sentry/sentry_bootstrap.dart';
import '../../../../l10n/l10n.dart';
import '../../../coach_log_export/presentation/bushido_export_screen.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../sheets_export/presentation/sheets_export_screen.dart';
import '../widgets/settings_widgets.dart';

class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsCard(
      children: [
        SettingsTile(
          icon: Icons.table_chart_outlined,
          label: l10n.profileExportToSheets,
          showChevron: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SheetsExportScreen()),
          ),
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.sports_score_outlined,
          label: l10n.coachLogExportTitle,
          showChevron: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BushidoExportScreen()),
          ),
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.delete_sweep_outlined,
          label: l10n.settingsClearCache,
          showChevron: true,
          onTap: () {},
        ),
      ],
    );
  }
}

class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            children: [
              const AppLogoIcon(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppWordmark(height: 18),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.settingsAppVersion} ${AppConstants.appVersion}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SettingsTileDivider(indent: 0),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: l10n.settingsPrivacy,
          showChevron: true,
          onTap: () {},
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.article_outlined,
          label: l10n.settingsTerms,
          showChevron: true,
          onTap: () {},
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.feedback_outlined,
          label: l10n.settingsFeedback,
          showChevron: true,
          onTap: () {
            // SentryFeedbackWidget asserts that Sentry options are wired, so
            // we hard-skip on dev / no-DSN builds. The snackbar makes the
            // dead-end obvious instead of silently doing nothing.
            if (!SentryBootstrap.isEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsFeedbackUnavailable),
                ),
              );
              return;
            }
            SentryFeedbackWidget.show(context);
          },
        ),
      ],
    );
  }
}

