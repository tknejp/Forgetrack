import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_logo.dart';
import '../dialogs/profile_dialogs.dart';
import '../widgets/profile_settings_widgets.dart';

class ProfileDataSection extends StatelessWidget {
  const ProfileDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ProfileSettingsCard(
      children: [
        ProfileSettingsTile(
          icon: Icons.table_chart_outlined,
          label: l10n.profileExportToSheets,
          showChevron: true,
          onTap: () {},
        ),
        const ProfileTileDivider(),
        ProfileSettingsTile(
          icon: Icons.delete_sweep_outlined,
          label: l10n.settingsClearCache,
          showChevron: true,
          onTap: () {},
        ),
      ],
    );
  }
}

class ProfileAboutSection extends StatelessWidget {
  const ProfileAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return ProfileSettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            children: [
              const AppBrandLockup(
                iconSize: 72,
                wordmarkHeight: 28,
                gap: 14,
              ),
              const SizedBox(height: 14),
              Text(
                '${l10n.settingsAppVersion} ${AppConstants.appVersion}',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        ProfileSettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: l10n.settingsPrivacy,
          showChevron: true,
          onTap: () {},
        ),
        const ProfileTileDivider(),
        ProfileSettingsTile(
          icon: Icons.article_outlined,
          label: l10n.settingsTerms,
          showChevron: true,
          onTap: () {},
        ),
        const ProfileTileDivider(),
        ProfileSettingsTile(
          icon: Icons.feedback_outlined,
          label: l10n.settingsFeedback,
          showChevron: true,
          onTap: () {},
        ),
      ],
    );
  }
}

class ProfileAccountSection extends StatelessWidget {
  const ProfileAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ProfileSettingsCard(
      children: [
        ProfileSettingsTile(
          icon: Icons.logout,
          iconColor: cs.error,
          label: l10n.profileSignOut,
          labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w500,
              ),
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showProfileConfirmationDialog(
      context,
      title: l10n.profileSignOutConfirmTitle,
      message: l10n.profileSignOutConfirmMessage,
      confirmLabel: l10n.profileSignOut,
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().signOut();
  }
}
