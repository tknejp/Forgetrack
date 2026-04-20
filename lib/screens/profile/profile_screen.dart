import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
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
    );
  }
}
