import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/notification_preferences_provider.dart';
import '../../../core/logging/app_log.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import '../widgets/integration_toggle_row.dart';
import '../widgets/kt_login_sheet.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';
import 'race_picker_view.dart';

// ─── Step 1 — Race picker ────────────────────────────────────────────────

class StepWelcome extends StatelessWidget {
  const StepWelcome({
    super.key,
    required this.draftRaceId,
    required this.onPickRace,
  });

  /// Race id the parent (`WelcomeScreen`) currently has drafted.
  /// Pre-sign-in state — not persisted until the welcome `_finish()`
  /// commit, because `CosmeticsProvider` writes are uid-keyed and
  /// sign-in happens in Step 2.
  final String draftRaceId;

  /// Callback fired when the user taps a race tile. Updates the
  /// parent's draft only; the cosmetics provider trio (selectRace +
  /// unlock + equip) runs in `_finish()` once a uid is bound.
  final ValueChanged<String> onPickRace;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RacePickerView(
        draftRaceId: draftRaceId,
        onPickRace: onPickRace,
        title: l10n.welcomeStep1Title,
        subtitle: l10n.welcomeStep1Subtitle,
        subtitleAccent: l10n.welcomeStep1SubtitleAccent,
        levelLabel: l10n.welcomeStep1HeroPill,
      ),
    );
  }
}
// ─── Step 2 — ÃšÄet ───────────────────────────────────────────────────────

class StepAccount extends StatelessWidget {
  const StepAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final connected = auth.isSignedIn;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIcon(
            tint: OnboardingTheme.purpleAccent,
            assetPath: 'assets/ui/welcome/shield.png',
          ),
          StepHeading(
            title: l10n.welcomeStep2Title,
            subtitle: l10n.welcomeStep2Subtitle,
          ),
          const SizedBox(height: 22),
          _GoogleSignInButton(
            connected: connected,
            email: auth.user?.email,
            busy: auth.isBusy,
          ),
          const SizedBox(height: 18),
          const _AccountBenefitsCard(),
          const SizedBox(height: 14),
          Center(
            child: Text(
              l10n.welcomeStep2Footnote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: OnboardingTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.connected,
    required this.email,
    required this.busy,
  });

  final bool connected;
  final String? email;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = connected
        ? (email != null
            ? l10n.welcomeStep2GoogleSignedInAs(email!)
            : l10n.welcomeStep2GoogleSignedIn)
        : l10n.welcomeStep2GoogleSignIn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: connected || busy
            ? null
            : () async {
                try {
                  await context.read<AuthProvider>().signIn();
                } catch (e, st) {
                  AppLog.app.error('onboarding: google sign-in failed',
                      err: e, stackTrace: st);
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: connected
                ? OnboardingTheme.green.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: connected
                ? Border.all(
                    color: OnboardingTheme.green.withValues(alpha: 0.45),
                  )
                : null,
            boxShadow: connected ? null : OnboardingTheme.googleButtonShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (connected)
                const Icon(Icons.check_circle_rounded,
                    color: OnboardingTheme.green, size: 20)
              else
                const _GoogleGGlyph(),
              const SizedBox(width: 12),
              Flexible(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: connected
                              ? OnboardingTheme.green
                              : const Color(0xFF1F1F1F),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGGlyph extends StatelessWidget {
  const _GoogleGGlyph();

  @override
  Widget build(BuildContext context) {
    // The asset folder already contains the official 4-color G as SVG —
    // reuse it instead of inlining the path data.
    return SvgPicture.asset(
      'assets/icons/google/google_logo.svg',
      width: 20,
      height: 20,
    );
  }
}

class _AccountBenefitsCard extends StatelessWidget {
  const _AccountBenefitsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      l10n.welcomeStep2Benefit1,
      l10n.welcomeStep2Benefit2,
      l10n.welcomeStep2Benefit3,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(167, 139, 250, 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromRGBO(167, 139, 250, 0.16),
        ),
      ),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: OnboardingTheme.green.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: OnboardingTheme.green.withValues(alpha: 0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: OnboardingTheme.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            OnboardingTheme.textPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Step 3 — ZdravÃ­ ─────────────────────────────────────────────────────

class StepHealth extends StatefulWidget {
  const StepHealth({super.key});

  @override
  State<StepHealth> createState() => _StepHealthState();
}

class _StepHealthState extends State<StepHealth> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final fitness = context.watch<FitnessProvider>();
    final l10n = context.l10n;
    final connected = fitness.hasPermissions;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIcon(
            tint: OnboardingTheme.teal,
            assetPath: 'assets/ui/welcome/script.png',
          ),
          StepHeading(
            title: l10n.welcomeStep3Title,
            subtitle: l10n.welcomeStep3Subtitle,
          ),
          const SizedBox(height: 22),
          const _DataIconGrid(),
          const SizedBox(height: 18),
          _HealthConnectCta(
            connected: connected,
            busy: _busy,
            onTap: () async {
              setState(() => _busy = true);
              try {
                await context.read<FitnessProvider>().requestPermissions();
              } catch (e, st) {
                AppLog.app.error('onboarding: HC permission failed',
                    err: e, stackTrace: st);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
          const SizedBox(height: 12),
          const _HealthPrivacyHint(),
        ],
      ),
    );
  }
}

class _DataIconGrid extends StatelessWidget {
  const _DataIconGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      _DataChip(
          emoji: '👣',
          label: l10n.welcomeStep3DataSteps,
          color: OnboardingTheme.green),
      _DataChip(
          emoji: '🔥',
          label: l10n.welcomeStep3DataCalories,
          color: const Color(0xFFFBBF24)),
      _DataChip(
          emoji: '🌙',
          label: l10n.welcomeStep3DataSleep,
          color: const Color(0xFFA89BFF)),
      _DataChip(
          emoji: '⚔️',
          label: l10n.welcomeStep3DataActivity,
          color: const Color(0xFF2DD4BF)),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({
    required this.emoji,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: OnboardingTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: OnboardingTheme.textPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthConnectCta extends StatelessWidget {
  const _HealthConnectCta({
    required this.connected,
    required this.busy,
    required this.onTap,
  });

  final bool connected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label =
        connected ? l10n.welcomeStep3CtaConnected : l10n.welcomeStep3Cta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: connected || busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: connected ? null : OnboardingTheme.hcCtaGradient,
            color: connected
                ? OnboardingTheme.green.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: connected
                  ? OnboardingTheme.green.withValues(alpha: 0.45)
                  : const Color.fromRGBO(63, 184, 175, 0.55),
            ),
            boxShadow: connected ? null : OnboardingTheme.hcCtaShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (connected)
                const Icon(Icons.check_circle_rounded,
                    color: OnboardingTheme.green, size: 18)
              else if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (connected || busy) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: connected ? OnboardingTheme.green : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthPrivacyHint extends StatelessWidget {
  const _HealthPrivacyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(167, 139, 250, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(167, 139, 250, 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.shield_outlined,
                size: 14, color: OnboardingTheme.purpleAccent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.welcomeStep3Privacy,
              style: OnboardingTheme.footnote.copyWith(
                color: OnboardingTheme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 4 — Hotovo ─────────────────────────────────────────────────────

class StepFinal extends StatefulWidget {
  const StepFinal({super.key});

  @override
  State<StepFinal> createState() => _StepFinalState();
}

class _StepFinalState extends State<StepFinal> {
  bool _ktBusy = false;

  Future<void> _handleKtTap() async {
    final kt = context.read<KalorickeTabulkyProvider>();
    if (kt.isLoggedIn) {
      setState(() => _ktBusy = true);
      try {
        await kt.logout();
      } finally {
        if (mounted) setState(() => _ktBusy = false);
      }
      return;
    }
    await KTLoginSheet.show(context);
  }

  Future<void> _handleNotifTap() async {
    final prefs = context.read<NotificationPreferencesProvider>();
    await prefs.setNotificationsEnabled(!prefs.notificationsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.watch<KalorickeTabulkyProvider>();
    final notifPrefs = context.watch<NotificationPreferencesProvider>();
    final l10n = context.l10n;
    final ktConnected = kt.isLoggedIn;
    final ktSubtitle = ktConnected
        ? (kt.loggedInEmail ?? l10n.welcomeStep4KtConnected)
        : l10n.welcomeStep4KtSubtitle;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepIcon(
            tint: OnboardingTheme.gold,
            assetPath: 'assets/ui/welcome/target.png',
          ),
          StepHeading(
            title: l10n.welcomeStep4Title,
            subtitle: l10n.welcomeStep4Subtitle,
          ),
          const SizedBox(height: 12),
          IntegrationToggleRow(
            title: l10n.welcomeStep4KtTitle,
            subtitle: ktSubtitle,
            tint: OnboardingTheme.ktTint,
            active: ktConnected,
            onTap: _handleKtTap,
            iconAsset: 'assets/icons/kt/kaloricke_tabulky.png',
            busy: _ktBusy || kt.isLoading,
          ),
          const SizedBox(height: 12),
          IntegrationToggleRow(
            title: l10n.welcomeStep4NotifTitle,
            subtitle: l10n.welcomeStep4NotifSubtitle,
            tint: OnboardingTheme.purpleAccent,
            active: notifPrefs.notificationsEnabled,
            onTap: _handleNotifTap,
            icon: '🔔',
          ),
          const SizedBox(height: 18),
          const _FirstQuestsCard(),
        ],
      ),
    );
  }
}

class _FirstQuestsCard extends StatelessWidget {
  const _FirstQuestsCard();

  /// Curated quest ids surfaced on the welcome screen's "first quests"
  /// preview. V2 mirrors V1's starter set (daily_steps_today +
  /// daily_sleep_today + earn-first-reward), substituting V2 node ids
  /// where the catalog renamed the entry. Edit this list to change the
  /// curated set rather than the widget body.
  static const List<String> _starterQuestNodeIds = [
    'daily_steps_today',
    'daily_sleep_today',
    'long_term_earn_first_reward',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <_QuestRow>[];
    for (final id in _starterQuestNodeIds) {
      final node = ProgressionEntryCatalog.definitionForId(id);
      if (node is! Quest) continue;
      var rewardXp = 0;
      for (final reward in node.rewards) {
        if (reward is XpReward) rewardXp += reward.amount;
      }
      rows.add(_QuestRow(
        text: node.titleKey(l10n),
        xp: '+$rewardXp XP',
      ));
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: OnboardingTheme.questsCardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OnboardingTheme.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            text: l10n.welcomeStep4QuestsLabel,
            color: OnboardingTheme.gold,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: Border(
                  bottom: i < rows.length - 1
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                        )
                      : BorderSide.none,
                ),
              ),
              child: rows[i],
            ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.text, required this.xp});

  final String text;
  final String xp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: OnboardingTheme.gold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: OnboardingTheme.gold.withValues(alpha: 0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: OnboardingTheme.textPrimary.withValues(alpha: 0.85),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: OnboardingTheme.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: OnboardingTheme.gold.withValues(alpha: 0.30),
            ),
          ),
          child: Text(
            xp,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: OnboardingTheme.gold,
            ),
          ),
        ),
      ],
    );
  }
}
