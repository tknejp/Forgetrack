import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/theme_provider.dart'
    show AppThemeMode, ThemeProvider;
import '../../../providers/time_theme_provider.dart';
import '../widgets/profile_settings_widgets.dart';

class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final timeThemeProvider = context.watch<TimeThemeProvider>();
    final l10n = context.l10n;

    return ProfileSettingsCard(
      children: [
        ProfileDropdownTile<String?>(
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
        const ProfileTileDivider(),
        ProfileDropdownTile<AppThemeMode>(
          icon: Icons.brightness_6_outlined,
          label: l10n.settingsTheme,
          value: themeProvider.choice,
          items: [
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.system,
              child: Text(l10n.themeSystem),
            ),
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.light,
              child: Text(l10n.themeLight),
            ),
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.dark,
              child: Text(l10n.themeDark),
            ),
            DropdownMenuItem<AppThemeMode>(
              value: AppThemeMode.dynamic,
              child: Text(l10n.themeDynamic),
            ),
          ],
          onChanged: (choice) {
            if (choice != null) {
              context.read<ThemeProvider>().setChoice(choice);
            }
          },
        ),
        const ProfileTileDivider(),
        ProfileSwitchTile(
          icon: Icons.wb_twilight_outlined,
          label: l10n.settingsTimeTheme,
          subtitle: l10n.settingsTimeThemeDesc,
          value: timeThemeProvider.enabled,
          onChanged: (v) => context.read<TimeThemeProvider>().setEnabled(v),
        ),
      ],
    );
  }
}
