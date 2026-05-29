import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/sentry/sentry_bootstrap.dart';
import '../../../../l10n/l10n.dart';
import '../../../coach_log_export/application/coach_log_export_settings.dart';
import '../../../coach_log_export/presentation/bushido_export_screen.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/section_head.dart';
import '../../../sheets_export/presentation/sheets_export_screen.dart';
import '../widgets/settings_widgets.dart';

class SettingsDataSection extends StatelessWidget {
  const SettingsDataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsCard(
      children: [
        SettingsTile(
          icon: Icons.table_chart_outlined,
          label: l10n.profileExportToSheets,
          showChevron: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SheetsExportScreen()),
          ),
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.sports_score_outlined,
          label: l10n.coachLogExportTitle,
          showChevron: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BushidoExportScreen()),
          ),
        ),
        const SettingsTileDivider(),
        SettingsSwitchTile(
          icon: Icons.bolt_outlined,
          label: l10n.coachLogExportQuickButtonSetting,
          subtitle: l10n.coachLogExportQuickButtonSettingSubtitle,
          value: context
              .watch<CoachLogExportSettings>()
              .showOverviewQuickButton,
          onChanged: (value) => context
              .read<CoachLogExportSettings>()
              .setShowOverviewQuickButton(value),
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.delete_sweep_outlined,
          label: l10n.settingsClearCache,
          showChevron: true,
          onTap: () {},
        ),
      ],
    );
  }
}

/// About screen body — app identity + a short description, an FAQ list
/// covering the integrations users ask about (Health Connect, Kalorické
/// Tabulky, goals, data, progression), and the contact / legal links.
///
/// NOTE: several entries here are still placeholders pending real content
/// (privacy policy + terms targets, contact email, website, store rating).
/// Tracked on Trello for completion.
class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AboutIdentityCard(),
        const SizedBox(height: 18),
        _AboutGroupHeader(label: l10n.aboutSectionFaq, accent: Tokens.accent),
        const _AboutFaqCard(),
        const SizedBox(height: 18),
        _AboutGroupHeader(
          label: l10n.aboutSectionContact,
          accent: Tokens.accent,
        ),
        const _AboutLinksCard(),
      ],
    );
  }
}

/// App logo + wordmark + version + tagline, with the one-paragraph
/// description below.
class _AboutIdentityCard extends StatelessWidget {
  const _AboutIdentityCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            children: [
              const AppLogoIcon(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppWordmark(height: 20),
                    const SizedBox(height: 4),
                    Text(
                      l10n.aboutTagline,
                      style: tt.bodySmall?.copyWith(color: Tokens.onSurfaceMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.settingsAppVersion} ${AppConstants.appVersion}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SettingsTileDivider(indent: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Text(
            l10n.aboutDescription,
            style: tt.bodyMedium?.copyWith(
              color: Tokens.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header used between About cards.
class _AboutGroupHeader extends StatelessWidget {
  const _AboutGroupHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: Tokens.spaceSm),
      child: SectionHead(label: label, accent: accent),
    );
  }
}

/// Expandable FAQ list. Each entry is a question (tap to expand) tagged
/// with its category and revealing a short answer.
class _AboutFaqCard extends StatelessWidget {
  const _AboutFaqCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final items = <_FaqItem>[
      _FaqItem(
        icon: Icons.health_and_safety_outlined,
        category: l10n.aboutFaqCatHc,
        question: l10n.aboutFaqHcWhatQ,
        answer: l10n.aboutFaqHcWhatA,
      ),
      _FaqItem(
        icon: Icons.link_rounded,
        category: l10n.aboutFaqCatHc,
        question: l10n.aboutFaqHcConnectQ,
        answer: l10n.aboutFaqHcConnectA,
      ),
      _FaqItem(
        icon: Icons.sync_problem_outlined,
        category: l10n.aboutFaqCatHc,
        question: l10n.aboutFaqHcNoDataQ,
        answer: l10n.aboutFaqHcNoDataA,
      ),
      _FaqItem(
        icon: Icons.restaurant_outlined,
        category: l10n.aboutFaqCatKt,
        question: l10n.aboutFaqKtWhatQ,
        answer: l10n.aboutFaqKtWhatA,
      ),
      _FaqItem(
        icon: Icons.login_rounded,
        category: l10n.aboutFaqCatKt,
        question: l10n.aboutFaqKtConnectQ,
        answer: l10n.aboutFaqKtConnectA,
      ),
      _FaqItem(
        icon: Icons.flag_outlined,
        category: l10n.aboutFaqCatGoals,
        question: l10n.aboutFaqGoalsQ,
        answer: l10n.aboutFaqGoalsA,
      ),
      _FaqItem(
        icon: Icons.shield_outlined,
        category: l10n.aboutFaqCatData,
        question: l10n.aboutFaqPrivacyQ,
        answer: l10n.aboutFaqPrivacyA,
      ),
      _FaqItem(
        icon: Icons.sports_esports_outlined,
        category: l10n.aboutFaqCatGame,
        question: l10n.aboutFaqRpgQ,
        answer: l10n.aboutFaqRpgA,
      ),
    ];

    return SettingsCard(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SettingsTileDivider(indent: 0),
          _FaqTile(item: items[i]),
        ],
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.icon,
    required this.category,
    required this.question,
    required this.answer,
  });

  final IconData icon;
  final String category;
  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SettingsExpandableTile(
      icon: item.icon,
      iconColor: Tokens.accent,
      label: item.question,
      summary: item.category,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Text(
            item.answer,
            style: tt.bodySmall?.copyWith(
              color: Tokens.onSurfaceMuted,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

/// Contact, feedback and legal links. Feedback is wired to Sentry; the
/// remaining rows are placeholders (see class-level note + Trello card).
class _AboutLinksCard extends StatelessWidget {
  const _AboutLinksCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsCard(
      children: [
        SettingsTile(
          icon: Icons.feedback_outlined,
          label: l10n.settingsFeedback,
          showChevron: true,
          onTap: () {
            // SentryFeedbackWidget asserts that Sentry options are wired, so
            // we hard-skip on dev / no-DSN builds. The snackbar makes the
            // dead-end obvious instead of silently doing nothing.
            if (!SentryBootstrap.isEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsFeedbackUnavailable)),
              );
              return;
            }
            SentryFeedbackWidget.show(context);
          },
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.mail_outline_rounded,
          label: l10n.aboutContactEmail,
          showChevron: true,
          onTap: () {},
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.star_outline_rounded,
          label: l10n.aboutRateApp,
          showChevron: true,
          onTap: () {},
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.public_outlined,
          label: l10n.aboutWebsite,
          showChevron: true,
          onTap: () {},
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          label: l10n.settingsPrivacy,
          showChevron: true,
          onTap: () {},
        ),
        const SettingsTileDivider(),
        SettingsTile(
          icon: Icons.article_outlined,
          label: l10n.settingsTerms,
          showChevron: true,
          onTap: () {},
        ),
      ],
    );
  }
}

