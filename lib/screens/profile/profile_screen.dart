import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../features/auth/application/auth_provider.dart';
import '../../theme/ft_design_tokens.dart';
import '../../widgets/ft/ft_screen_header.dart';
import 'sections/profile_goals_section.dart';
import 'sections/profile_header_section.dart';
import 'sections/profile_kt_section.dart';
import 'sections/profile_preferences_section.dart';
import 'sections/profile_static_sections.dart';
import 'widgets/profile_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  ? _ProfileBackButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            ProfileHeaderCard(auth: auth),
            const SizedBox(height: 18),
            ProfileSection(
              title: l10n.sectionGoals,
              child: const ProfileGoalsSection(),
            ),
            ProfileSection(
              title: l10n.sectionPreferences,
              child: const ProfilePreferencesSection(),
            ),
            ProfileSection(
              title: l10n.ktSectionTitle,
              child: const ProfileKtSection(),
            ),
            ProfileSection(
              title: l10n.sectionData,
              child: const ProfileDataSection(),
            ),
            ProfileSection(
              title: l10n.sectionAbout,
              child: const ProfileAboutSection(),
            ),
            if (auth.isSignedIn)
              ProfileSection(
                title: l10n.sectionAccount,
                bottomSpacing: 0,
                child: const ProfileAccountSection(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileBackButton({required this.onTap});

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
