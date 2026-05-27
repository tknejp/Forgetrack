import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/notification_preferences_provider.dart';
import '../../../../core/services/notification_preferences.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/settings_widgets.dart';

class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<NotificationPreferencesProvider>();
    final l10n = context.l10n;
    final master = prefs.notificationsEnabled;

    return SettingsCard(
      children: [
        SettingsSwitchTile(
          icon: Icons.notifications_active_outlined,
          label: l10n.settingsNotifications,
          subtitle: l10n.settingsNotifMasterSubtitle,
          value: master,
          onChanged: (value) {
            context
                .read<NotificationPreferencesProvider>()
                .setNotificationsEnabled(value);
          },
        ),
        const SettingsTileDivider(),
        _CategoryTile(
          icon: Icons.emoji_events_outlined,
          label: l10n.settingsNotifProgressionLabel,
          subtitle: l10n.settingsNotifProgressionSubtitle,
          category: NotificationCategory.progression,
          masterEnabled: master,
        ),
        const SettingsTileDivider(),
        _CategoryTile(
          icon: Icons.group_outlined,
          label: l10n.settingsNotifSocialLabel,
          subtitle: l10n.settingsNotifSocialSubtitle,
          category: NotificationCategory.social,
          masterEnabled: master,
        ),
        const SettingsTileDivider(),
        _CategoryTile(
          icon: Icons.alarm_outlined,
          label: l10n.settingsNotifRemindersLabel,
          subtitle: l10n.settingsNotifRemindersSubtitle,
          category: NotificationCategory.reminders,
          masterEnabled: master,
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.category,
    required this.masterEnabled,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final NotificationCategory category;
  final bool masterEnabled;

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<NotificationPreferencesProvider>();
    return SettingsSwitchTile(
      icon: icon,
      label: label,
      subtitle: subtitle,
      value: prefs.categoryEnabled(category),
      enabled: masterEnabled,
      onChanged: (value) {
        context
            .read<NotificationPreferencesProvider>()
            .setCategoryEnabled(category, value);
      },
    );
  }
}
