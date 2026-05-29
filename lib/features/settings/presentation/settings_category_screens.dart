import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'sections/settings_goals_section.dart';
import 'sections/settings_health_connect_section.dart';
import 'sections/settings_notifications_section.dart';
import 'sections/settings_preferences_section.dart';
import 'sections/settings_static_sections.dart';
import 'widgets/settings_detail_scaffold.dart';

/// Per-category settings pages reached from the settings hub. Each is a thin
/// wrapper that drops the existing section widget onto a [SettingsDetailScaffold]
/// — the section widgets themselves are unchanged.

class SettingsHealthConnectScreen extends StatelessWidget {
  const SettingsHealthConnectScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: context.l10n.settingsHealthConnectSection,
        children: const [SettingsHealthConnectSection()],
      );
}

class SettingsPreferencesScreen extends StatelessWidget {
  const SettingsPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: context.l10n.sectionPreferences,
        children: const [SettingsPreferencesSection()],
      );
}

class SettingsNotificationsScreen extends StatelessWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: context.l10n.sectionNotifications,
        children: const [SettingsNotificationsSection()],
      );
}

class SettingsGoalsScreen extends StatelessWidget {
  const SettingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: context.l10n.sectionGoals,
        children: const [SettingsGoalsSection()],
      );
}

class SettingsDataScreen extends StatelessWidget {
  const SettingsDataScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: context.l10n.sectionData,
        children: const [SettingsDataSection()],
      );
}

class SettingsAboutScreen extends StatelessWidget {
  const SettingsAboutScreen({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: context.l10n.sectionAbout,
        children: const [SettingsAboutSection()],
      );
}
