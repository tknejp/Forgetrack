import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/progression/presentation/progression_provider.dart';
import '../../l10n/l10n.dart';
import '../../features/auth/application/auth_provider.dart';
import '../ft_progression_screen.dart';
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
          const SizedBox(height: 14),
          const _ProgressionProfileEntryCard(),
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

class _ProgressionProfileEntryCard extends StatelessWidget {
  const _ProgressionProfileEntryCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progression = context.watch<ProgressionProvider>();
    final profile = progression.profile;
    final unlocked =
        progression.achievements.where((a) => a.unlocked).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FtProgressionScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${profile.level}',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.progScreenEntryTitle,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.progScreenEntrySubtitle(
                        profile.levelTitle,
                        profile.totalXp,
                        unlocked,
                      ),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
