import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../auth/application/auth_provider.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../../../shared/widgets/ft/ft_screen_header.dart';
import 'sections/settings_goals_section.dart';
import 'sections/settings_header_section.dart';
import 'sections/settings_kt_section.dart';
import 'sections/settings_preferences_section.dart';
import 'sections/settings_static_sections.dart';
import 'widgets/settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: FtTokens.bg,
      ),
      child: Scaffold(
        backgroundColor: FtTokens.bg,
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            14,
            MediaQuery.of(context).padding.top + 12,
            14,
            32,
          ),
          children: [
            FtScreenHeader(
              greeting: l10n.settingsSection,
              title: l10n.screenProfile,
              leading: canPop
                  ? _SettingsBackButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            SettingsHeaderCard(auth: auth),
            const SizedBox(height: 18),
            SettingsSection(
              title: l10n.sectionGoals,
              child: const SettingsGoalsSection(),
            ),
            SettingsSection(
              title: l10n.sectionPreferences,
              child: const SettingsPreferencesSection(),
            ),
            SettingsSection(
              title: l10n.ktSectionTitle,
              child: const SettingsKtSection(),
            ),
            SettingsSection(
              title: l10n.sectionData,
              child: const SettingsDataSection(),
            ),
            SettingsSection(
              title: l10n.sectionAbout,
              child: const SettingsAboutSection(),
            ),
            if (auth.isSignedIn)
              SettingsSection(
                title: l10n.sectionAccount,
                bottomSpacing: 0,
                child: const SettingsAccountSection(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FtTokens.cardBorder),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
