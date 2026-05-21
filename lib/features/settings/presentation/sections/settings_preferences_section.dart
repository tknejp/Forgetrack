import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../app/locale_provider.dart';
import '../../../../app/notification_preferences_provider.dart';
import '../../../../core/sentry/sentry_bootstrap.dart';
import '../../../../core/sentry/sentry_consent_provider.dart';
import '../widgets/settings_widgets.dart';

class SettingsPreferencesSection extends StatelessWidget {
  const SettingsPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final notificationPreferences =
        context.watch<NotificationPreferencesProvider>();
    final sentryConsent = context.watch<SentryConsentProvider>();
    final l10n = context.l10n;
    final sentryAvailable = SentryBootstrap.isAvailable;

    return SettingsCard(
      children: [
        SettingsDropdownTile<String?>(
          icon: Icons.language_outlined,
          label: l10n.settingsLanguage,
          value: localeProvider.locale?.languageCode,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.languageSystemDefault),
            ),
            DropdownMenuItem<String?>(
              value: 'en',
              child: Text(l10n.languageEnglish),
            ),
            DropdownMenuItem<String?>(
              value: 'cs',
              child: Text(l10n.languageCzech),
            ),
          ],
          onChanged: (code) {
            final newLocale = code == null ? null : Locale(code);
            context.read<LocaleProvider>().setLocale(newLocale);
          },
        ),
        const SettingsTileDivider(),
        SettingsSwitchTile(
          icon: Icons.notifications_active_outlined,
          label: l10n.settingsNotifications,
          subtitle: l10n.settingsNotificationsSubtitle,
          value: notificationPreferences.notificationsEnabled,
          onChanged: (value) {
            context
                .read<NotificationPreferencesProvider>()
                .setNotificationsEnabled(value);
          },
        ),
        const SettingsTileDivider(),
        SettingsSwitchTile(
          icon: Icons.bug_report_outlined,
          label: l10n.settingsCrashReporting,
          subtitle: sentryAvailable
              ? l10n.settingsCrashReportingSubtitle
              : l10n.settingsCrashReportingDevBuild,
          // On dev / no-DSN builds the toggle is effectively informational —
          // we still let the user flip the persisted pref so when they hop
          // onto a prod build it takes effect immediately, but a restart-
          // required snackbar only fires when Sentry can actually run.
          value: sentryConsent.enabled,
          onChanged: (value) async {
            await context.read<SentryConsentProvider>().setEnabled(value);
            if (!context.mounted) return;
            if (sentryAvailable) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsCrashReportingRestart),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
