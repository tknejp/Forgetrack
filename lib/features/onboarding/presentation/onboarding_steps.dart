import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/notification_preferences_provider.dart';
import '../../../core/logging/app_log.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/auth_provider.dart';
import '../../health_connect/application/fitness_provider.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../../progression_engine/domain/catalog/level_milestone_specs.dart';
import '../../progression_engine/domain/catalog/progression_node_catalog.dart';
import '../../progression_engine/domain/models/progression_node_definition.dart';
import '../../progression_engine/domain/models/reward_definition.dart';
import '../widgets/integration_toggle_row.dart';
import '../widgets/kt_login_sheet.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/onboarding_theme.dart';

// ─── Step 1 — Vítej ──────────────────────────────────────────────────────

class StepWelcome extends StatelessWidget {
  const StepWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final progression = context.watch<ProgressionEngineProvider>();
    final l10n = context.l10n;
    // V2 [EngineProfile] is always resolved through [ProgressionLevelPolicy]
    // (see [ProgressionEngineProvider.profile]) — the pre-hydration zero
    // profile and a populated ledger both go through the same policy, so
    // reading the provider directly is now safe.
    final profile = progression.profile;
    final tier = levelMilestoneAtOrBelow(profile.level);
    // Gap inside the current level so it matches the in-app hero card.
    final levelGap =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          const _SigilCluster(),
          const SizedBox(height: 18),
          Text(
            l10n.welcomeStep1Title,
            textAlign: TextAlign.center,
            style: OnboardingTheme.displayTitle,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _Step1Subtitle(
              full: l10n.welcomeStep1Subtitle,
              accent: l10n.welcomeStep1SubtitleAccent,
            ),
          ),
          const SizedBox(height: 22),
          _HeroPreviewCard(
            level: profile.level,
            xpInto: profile.xpIntoLevel,
            xpToNext: levelGap,
            tierTitle: tier.titleKey(l10n),
          ),
        ],
      ),
    );
  }
}

/// Renders the step 1 subtitle, splitting the localised string on its
/// accent phrase so the inner span can be coloured/bolded without
/// fragmenting the translation across multiple keys.
class _Step1Subtitle extends StatelessWidget {
  const _Step1Subtitle({required this.full, required this.accent});

  final String full;
  final String accent;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 15,
      height: 1.45,
      color: OnboardingTheme.textSecondary,
    );
    final accentStyle = const TextStyle(
      color: OnboardingTheme.purpleAccent,
      fontWeight: FontWeight.w600,
    );
    final idx = full.indexOf(accent);
    if (idx < 0) {
      // Translator dropped the accent phrase — render plain.
      return Text(full, textAlign: TextAlign.center, style: baseStyle);
    }
    return Text.rich(
      TextSpan(
        children: [
          if (idx > 0) TextSpan(text: full.substring(0, idx)),
          TextSpan(text: accent, style: accentStyle),
          if (idx + accent.length < full.length)
            TextSpan(text: full.substring(idx + accent.length)),
        ],
      ),
      textAlign: TextAlign.center,
      style: baseStyle,
    );
  }
}

/// Step 1 hero illustration — the Forgetrack app icon floating on a
/// double-layered purple glow with four staggered twinkling sparkles
/// around the periphery. No outer frame, no border, no inner disc —
/// just logo + glow + sparks.
class _SigilCluster extends StatefulWidget {
  const _SigilCluster();

  @override
  State<_SigilCluster> createState() => _SigilClusterState();
}

class _SigilClusterState extends State<_SigilCluster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 2.4s full cycle — matches the `wm-spark` keyframe period from the
    // design. One ticker drives all four sparkles.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 168.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer wide purple bloom.
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.fromRGBO(139, 92, 246, 0.42),
                  Colors.transparent,
                ],
                radius: 0.55,
              ),
            ),
            child: SizedBox.expand(),
          ),
          // Inner brighter core.
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.fromRGBO(167, 139, 250, 0.55),
                  Colors.transparent,
                ],
                radius: 0.32,
              ),
            ),
            child: SizedBox.expand(),
          ),
          // App icon foreground.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/branding/app-icon-foreground.png',
              fit: BoxFit.contain,
            ),
          ),
          // Four staggered sparkles. Positions match the design
          // (top-left, top-right, bottom-right, bottom-left) and the
          // phase offsets keep the four pulses out of phase so the
          // ring feels alive rather than blinking in unison.
          Positioned(
            left: size * 0.04,
            top: size * 0.18,
            child: AnimatedSparkle(
              animation: _controller,
              phaseOffset: 0.0,
              size: 14,
            ),
          ),
          Positioned(
            right: size * 0.06,
            top: size * 0.10,
            child: AnimatedSparkle(
              animation: _controller,
              phaseOffset: 0.25,
              size: 18,
            ),
          ),
          Positioned(
            right: size * 0.04,
            bottom: size * 0.16,
            child: AnimatedSparkle(
              animation: _controller,
              phaseOffset: 0.50,
              size: 12,
            ),
          ),
          Positioned(
            left: size * 0.08,
            bottom: size * 0.10,
            child: AnimatedSparkle(
              animation: _controller,
              phaseOffset: 0.75,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPreviewCard extends StatelessWidget {
  const _HeroPreviewCard({
    required this.level,
    required this.xpInto,
    required this.xpToNext,
    required this.tierTitle,
  });

  final int level;
  final int xpInto;
  final int xpToNext;
  final String tierTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: OnboardingTheme.heroCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OnboardingTheme.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            text: l10n.welcomeStep1HeroLabel,
            color: OnboardingTheme.purpleAccent,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Level badge.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: OnboardingTheme.levelBadgeGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: OnboardingTheme.levelBadgeShadow,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tierTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.66, // 0.06em
                        color: OnboardingTheme.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.welcomeStep1HeroXpProgress(xpInto, xpToNext),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            OnboardingTheme.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: OnboardingTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: OnboardingTheme.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  l10n.welcomeStep1HeroPill,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: OnboardingTheme.gold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Step 2 — Účet ───────────────────────────────────────────────────────

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

// ─── Step 3 — Zdraví ─────────────────────────────────────────────────────

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
          emoji: '😴',
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
      final node = ProgressionNodeCatalog.definitionForId(id);
      if (node is! QuestNode) continue;
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
