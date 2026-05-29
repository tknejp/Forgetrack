import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/constants.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_provider.dart';
import '../../devtools/application/devtools_permission_service.dart';
import '../../devtools/presentation/devtools_screen.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/ft_back_button.dart';
import '../../../shared/widgets/screen_header.dart';
import 'sections/settings_header_section.dart';
import 'sections/settings_kt_section.dart';
import 'settings_category_screens.dart';
import 'widgets/settings_widgets.dart';

/// Settings hub. Shows the account card plus a compact menu of categories;
/// each row drills into its own page (see [settings_category_screens.dart]).
/// Heavy sections (KT, Goals) used to render inline here and made the screen
/// scroll for a long time — drilling down keeps the entry point scannable.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final devtoolsPermission = context.watch<DevToolsPermissionService>();
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();

    void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );

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
            const SizedBox(height: 12),
            const SettingsKtSection(),
            const SizedBox(height: 18),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.favorite_border,
                  iconColor: Tokens.danger,
                  label: l10n.settingsHealthConnectSection,
                  subtitle: l10n.settingsHubHealthConnectSubtitle,
                  showChevron: true,
                  onTap: () => open(const SettingsHealthConnectScreen()),
                ),
                const SettingsTileDivider(),
                SettingsTile(
                  icon: Icons.track_changes_outlined,
                  iconColor: Tokens.success,
                  label: l10n.sectionGoals,
                  subtitle: l10n.settingsHubGoalsSubtitle,
                  showChevron: true,
                  onTap: () => open(const SettingsGoalsScreen()),
                ),
                const SettingsTileDivider(),
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  iconColor: Tokens.difficultyMedium,
                  label: l10n.sectionNotifications,
                  subtitle: l10n.settingsHubNotificationsSubtitle,
                  showChevron: true,
                  onTap: () => open(const SettingsNotificationsScreen()),
                ),
                const SettingsTileDivider(),
                SettingsTile(
                  icon: Icons.tune,
                  iconColor: Tokens.accent,
                  label: l10n.sectionPreferences,
                  subtitle: l10n.settingsHubPreferencesSubtitle,
                  showChevron: true,
                  onTap: () => open(const SettingsPreferencesScreen()),
                ),
                const SettingsTileDivider(),
                SettingsTile(
                  icon: Icons.import_export,
                  iconColor: Tokens.difficultyHard,
                  label: l10n.sectionData,
                  subtitle: l10n.settingsHubDataSubtitle,
                  showChevron: true,
                  onTap: () => open(const SettingsDataScreen()),
                ),
                const SettingsTileDivider(),
                SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: Tokens.onSurfaceMuted,
                  label: l10n.sectionAbout,
                  subtitle: l10n.settingsHubAboutSubtitle,
                  trailingLabel: AppConstants.appVersion,
                  showChevron: true,
                  onTap: () => open(const SettingsAboutScreen()),
                ),
              ],
            ),
            if (devtoolsPermission.hasAccess(auth.user?.firebaseUid)) ...[
              const SizedBox(height: 16),
              SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.developer_mode,
                    label: l10n.settingsDeveloperTools,
                    showChevron: true,
                    onTap: () => open(const DevToolsScreen()),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
