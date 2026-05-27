import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../auth/application/auth_provider.dart';
import '../../devtools/application/devtools_permission_service.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import 'sections/settings_devtools_section.dart';
import 'sections/settings_goals_section.dart';
import 'sections/settings_header_section.dart';
import 'sections/settings_health_connect_section.dart';
import 'sections/settings_kt_section.dart';
import 'sections/settings_notifications_section.dart';
import 'sections/settings_preferences_section.dart';
import 'sections/settings_static_sections.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final devtoolsPermission = context.watch<DevToolsPermissionService>();
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();

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
            32,
          ),
          children: [
            ScreenHeader(
              greeting: l10n.settingsSection,
              title: l10n.screenProfile,
              leading: canPop ? const FtBackButton() : null,
            ),
            const SizedBox(height: 18),
            SettingsHeaderCard(auth: auth),
            const SizedBox(height: 18),
            SettingsSection(
              title: l10n.ktSectionTitle,
              child: const SettingsKtSection(),
            ),
            SettingsSection(
              title: l10n.settingsHealthConnectSection,
              child: const SettingsHealthConnectSection(),
            ),
            SettingsSection(
              title: l10n.sectionPreferences,
              child: const SettingsPreferencesSection(),
            ),
            SettingsSection(
              title: l10n.sectionNotifications,
              child: const SettingsNotificationsSection(),
            ),
            SettingsSection(
              title: l10n.sectionGoals,
              child: const SettingsGoalsSection(),
            ),
            SettingsSection(
              title: l10n.sectionData,
              child: const SettingsDataSection(),
            ),
            SettingsSection(
              title: l10n.sectionAbout,
              child: const SettingsAboutSection(),
            ),
            if (devtoolsPermission.hasAccess(auth.user?.firebaseUid))
              SettingsSection(
                title: l10n.settingsDeveloperTools,
                bottomSpacing: 0,
                child: const SettingsDevToolsSection(),
              ),
          ],
        ),
      ),
    );
  }
}
