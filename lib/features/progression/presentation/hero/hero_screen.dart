import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:forgetrack/shared/presentation/achievement_badge_specs.dart';

import '../../domain/progression_models.dart';
import '../../domain/catalog/rule_catalog.dart';
import '../../application/progression_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../cosmetics/config/cosmetics_config.dart';
import '../../../cosmetics/domain/cosmetic_models.dart';
import '../../../cosmetics/presentation/cosmetics_screen.dart';
import '../../../social/application/social_provider.dart';
import '../../../social/domain/social_models.dart';
import '../widgets/progression_primitives.dart';
import '../journey/widgets/journey_preview_card.dart';
import '../widgets/progression_internals.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../../shared/widgets/tiny_pill.dart';

class HeroScreen extends StatefulWidget {
  const HeroScreen({
    super.key,
    required this.barKey,
    required this.outerController,
    this.topContentInset = 0,
  });
  final GlobalKey barKey;
  final PageController outerController;
  final double topContentInset;

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionProvider>();
    final viewData = ProgressionViewData.from(progression);

    if (progression.isLoading && progression.rewardGrants.isEmpty) {
      return ProgressionScaffold(
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const ProgressionLoadingBlock(height: 180),
            const SizedBox(height: Tokens.spaceMd),
            const ProgressionLoadingBlock(height: 140),
            const SizedBox(height: Tokens.spaceMd),
            const ProgressionLoadingBlock(height: 120),
          ],
        ),
      );
    }

    return ProgressionScaffold(
      child: RefreshIndicator(
        onRefresh: progression.refresh,
        color: Tokens.accent,
        backgroundColor: Tokens.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (progression.error != null)
              SliverPadding(
                padding:
                    EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 0),
                sliver: SliverToBoxAdapter(
                  child: ProgressionErrorBanner(message: progression.error!),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                14,
                progression.error != null ? 16 : widget.topContentInset + 16,
                14,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ARCHIVED 2026-04-29: "Přehled postupu" + "Série" sections
                  // moved to archived_sections.dart. Replaced by inventory.
                  const _CosmeticsInventorySection(),
                  const SizedBox(height: Tokens.spaceLg),
                  const JourneyPreviewCard(),
                  const SizedBox(height: Tokens.spaceLg),
                  ProgSectionHead(
                    label: l10n.progAchievementsSectionLabel,
                    caption: l10n.progAchievementsSectionCaption,
                    accent: Tokens.accent,
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                ]),
              ),
            ),
            _AchievementsSliverSection(
              unlocked: viewData.unlocked,
              inProgress: viewData.inProgress,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievements ──────────────────────────────────────────────────────────────

class _AchievementsSliverSection extends StatelessWidget {
  const _AchievementsSliverSection({
    required this.unlocked,
    required this.inProgress,
    required this.l10n,
  });

  final List<ProgressionAchievement> unlocked;
  final List<ProgressionAchievement> inProgress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final achievements = [...unlocked, ...inProgress];
    if (achievements.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
        sliver: SliverToBoxAdapter(
          child: ProgressionEmptyLine(
            title: l10n.progAchievementsEmptyUnlockedTitle,
            caption: l10n.progAchievementsEmptyUnlockedCaption,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      sliver: _AchievementBadgeSliverGrid(
        achievements: achievements,
        l10n: l10n,
      ),
    );
  }
}

class _AchievementBadgeSliverGrid extends StatelessWidget {
  const _AchievementBadgeSliverGrid({
    required this.achievements,
    required this.l10n,
  });

  final List<ProgressionAchievement> achievements;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final crossAxisCount = width >= 620 ? 4 : 3;
        final aspectRatio = width >= 620 ? 0.98 : 0.9;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _AchievementTile(
              achievement: achievements[index],
              l10n: l10n,
            ),
            childCount: achievements.length,
          ),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.l10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final achievement = this.achievement;
    final badge = achievementBadgeSpec(achievement);
    final color = badge.color;
    final unlocked = achievement.unlocked;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAchievementDetailsSheet(
        context,
        achievement: achievement,
        l10n: l10n,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.13),
                    color.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: unlocked ? null : const Color(0x08FFFFFF),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: unlocked
                ? color.withValues(alpha: 0.27)
                : const Color(0x0FFFFFFF),
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: TextStyle(
                fontSize: 22,
                color: unlocked ? null : const Color(0x66FFFFFF),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _achievementDisplayLabel(achievement, context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Tokens.fontSizeTiny,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? color : const Color(0x66FFFFFF),
                  letterSpacing: 0.5,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementEmojiBadge extends StatelessWidget {
  const _AchievementEmojiBadge({
    required this.emoji,
    required this.color,
    required this.unlocked,
  });

  final String emoji;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: unlocked
            ? color.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: Tokens.fontSizeTitle),
        ),
      ),
    );
  }
}

class _AchievementDetailsSheet extends StatefulWidget {
  const _AchievementDetailsSheet({
    required this.achievement,
    required this.l10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;

  @override
  State<_AchievementDetailsSheet> createState() =>
      _AchievementDetailsSheetState();
}

class _AchievementDetailsSheetState extends State<_AchievementDetailsSheet> {
  bool _sharing = false;
  bool _shared = false;
  bool _pinning = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    final social = context.read<SocialProvider>();
    await social.shareAchievement(
      widget.achievement.id,
      resolvedTitle: widget.achievement.title(widget.l10n),
      resolvedDescription: widget.achievement.description(widget.l10n),
    );
    if (!mounted) return;
    setState(() {
      _sharing = false;
      _shared = social.error == null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Tokens.surface,
        content: Text(
          social.error == null
              ? 'Achievement sdílen do feedu přátel.'
              : 'Chyba: ${social.error}',
          style: const TextStyle(color: Tokens.onSurface),
        ),
      ),
    );
  }

  Future<void> _setPinned(bool pinned) async {
    setState(() => _pinning = true);
    final social = context.read<SocialProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await social.setCurrentAchievementPinned(
      achievementId: widget.achievement.id,
      pinned: pinned,
    );
    if (!mounted) return;
    setState(() => _pinning = false);
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Tokens.surface,
        content: Text(
          social.error == null
              ? (pinned
                  ? 'Achievement pripnut na profil.'
                  : 'Achievement odebran z profilu.')
              : 'Chyba: ${social.error}',
          style: const TextStyle(color: Tokens.onSurface),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final l10n = widget.l10n;
    final badge = achievementBadgeSpec(achievement);
    final color = badge.color;
    final locale = Localizations.localeOf(context).toString();
    final unlocked = achievement.unlocked;
    final progressLabel = l10n.progProgressRatio(
      achievement.currentValue,
      achievement.targetValue,
    );
    final summary = _achievementCompactSummary(
      achievement,
      l10n,
      locale,
    );
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Tokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: EdgeInsets.fromLTRB(18, 12, 18, bottomPad + 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: Tokens.spaceLg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AchievementEmojiBadge(
                  emoji: badge.emoji,
                  color: color,
                  unlocked: unlocked,
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title(l10n),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: Tokens.spaceXs),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                TinyPill(
                  label: unlocked
                      ? l10n.progAchievementStatusUnlocked
                      : l10n.progAchievementStatusInProgress,
                  color: unlocked ? color : Tokens.onSurfaceMuted,
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceLg),
            Text(
              achievement.description(l10n),
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.45,
                color: Tokens.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TinyPill(
                  label: _achievementDifficultyLabel(achievement, l10n),
                  color: color,
                ),
                TinyPill(
                  label: progressLabel,
                  color: color,
                ),
                if (achievement.ruleId != null)
                  TinyPill(
                    label: ProgressionRuleCatalog.titleForId(
                      achievement.ruleId!,
                      l10n,
                    ),
                    color: color.withValues(alpha: 0.88),
                  )
                else if (achievement.domain != null)
                  TinyPill(
                    label: achievement.domain!.label(l10n),
                    color: color.withValues(alpha: 0.88),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(Tokens.radiusTile),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressBar(
                    value: unlocked ? 1 : achievement.progress,
                    color: color,
                    glow: color.withValues(alpha: 0.35),
                    height: 4,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progressLabel,
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeSmall,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (unlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: Tokens.spaceXs),
                    Text(
                      l10n.progQuestCompletedOn(
                        progressionFormatDateTime(
                            achievement.unlockedAt!, locale),
                      ),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unlocked) ...[
              const SizedBox(height: 14),
              _PinnedAchievementAction(
                achievementId: achievement.id,
                color: color,
                busy: _pinning,
                onToggle: _setPinned,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: (_sharing || _shared) ? null : _share,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: _shared
                          ? null
                          : LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.28),
                                color.withValues(alpha: 0.14),
                              ],
                            ),
                      color:
                          _shared ? Colors.white.withValues(alpha: 0.05) : null,
                      borderRadius: BorderRadius.circular(Tokens.radiusTile),
                      border: Border.all(
                        color: _shared
                            ? Colors.white.withValues(alpha: 0.10)
                            : color.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_sharing)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        else
                          Icon(
                            _shared ? Icons.check_rounded : Icons.share_rounded,
                            size: 16,
                            color: _shared ? Tokens.onSurfaceMuted : color,
                          ),
                        const SizedBox(width: Tokens.spaceSm),
                        Text(
                          _shared
                              ? 'Sdíleno'
                              : _sharing
                                  ? 'Sdílení...'
                                  : 'Sdílet do feedu přátel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _shared ? Tokens.onSurfaceMuted : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinnedAchievementAction extends StatelessWidget {
  const _PinnedAchievementAction({
    required this.achievementId,
    required this.color,
    required this.busy,
    required this.onToggle,
  });

  final String achievementId;
  final Color color;
  final bool busy;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, social, _) {
        final uid = social.currentUid;
        if (uid == null || !social.backendReady || !social.isReady) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<SocialUserProfile?>(
          stream: social.watchProfileById(uid),
          builder: (context, snap) {
            final pinned =
                snap.data?.pinnedAchievementIds.contains(achievementId) ??
                    false;
            return GestureDetector(
              onTap: busy ? null : () => onToggle(!pinned),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: pinned
                      ? color.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(Tokens.radiusTile),
                  border: Border.all(
                    color: pinned
                        ? color.withValues(alpha: 0.38)
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (busy)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    else
                      Icon(
                        pinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        size: 16,
                        color: pinned ? color : Tokens.onSurfaceMuted,
                      ),
                    const SizedBox(width: Tokens.spaceSm),
                    Text(
                      pinned ? 'Pripnuto na profilu' : 'Pripnout na profil',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pinned ? color : Tokens.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void _showAchievementDetailsSheet(
  BuildContext context, {
  required ProgressionAchievement achievement,
  required AppLocalizations l10n,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _AchievementDetailsSheet(
      achievement: achievement,
      l10n: l10n,
    ),
  );
}

// ── Achievement display helpers ───────────────────────────────────────────────

String _achievementDisplayLabel(
  ProgressionAchievement achievement,
  BuildContext context,
) {
  final levelTarget = achievementLevelTarget(achievement);
  if (levelTarget != null) return 'LEVEL $levelTarget';
  return achievement.title(context.l10n).toUpperCase();
}

String _achievementDifficultyLabel(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
) =>
    achievement.difficulty.label(l10n);

String _achievementCompactSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  String locale,
) {
  switch (achievement.criterionType) {
    case ProgressionAchievementCriterionType.totalXpAtLeast:
      final levelTarget = achievementLevelTarget(achievement);
      if (levelTarget != null) {
        return 'LEVEL $levelTarget';
      }
      return '${_formatCompactInt(achievement.targetValue, locale)} XP';
    case ProgressionAchievementCriterionType.rewardCountAtLeast:
      if (achievement.ruleId != null) {
        return '${achievement.targetValue}x ${ProgressionRuleCatalog.titleForId(achievement.ruleId!, l10n)}';
      }
      if (achievement.domain != null) {
        return '${achievement.targetValue}x ${achievement.domain!.label(l10n)}';
      }
      return '${achievement.targetValue} ${l10n.progRewardsSectionLabel}';
    case ProgressionAchievementCriterionType.bestStreakAtLeast:
      return '${achievement.targetValue} ${l10n.progStreakDaysSuffix}';
    case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
    case ProgressionAchievementCriterionType.bestRollingWindowRuleValueAtLeast:
      return _achievementTargetSummary(achievement, l10n, locale);
    case ProgressionAchievementCriterionType.dailyQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryDailyQuests}';
    case ProgressionAchievementCriterionType.weeklyQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryWeeklyQuests}';
    case ProgressionAchievementCriterionType.totalQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryTotalQuests}';
    case ProgressionAchievementCriterionType.activeDaysAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryActiveDays}';
    case ProgressionAchievementCriterionType.perfectDaysAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryPerfectDays}';
    case ProgressionAchievementCriterionType.perfectWeeksAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryPerfectWeeks}';
    case ProgressionAchievementCriterionType.comboQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryComboQuests}';
    case ProgressionAchievementCriterionType.tripleComboQuestsCompletedAtLeast:
      return '${achievement.targetValue} ${l10n.progAchievementSummaryTripleComboQuests}';
    case ProgressionAchievementCriterionType.compositeAllOf:
      return l10n.progAchievementSummaryComposite;
  }
}

String _achievementTargetSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  String locale,
) {
  if (achievement.ruleId == 'daily_sleep') {
    final hours = (achievement.targetValue / 60).round();
    return '$hours ${l10n.goalUnitHours}';
  }
  final unit = ProgressionRuleCatalog.unitForId(achievement.ruleId, l10n);
  return '${_formatCompactInt(achievement.targetValue, locale)} $unit';
}

String _formatCompactInt(int value, String locale) {
  return NumberFormat.compact(locale: locale).format(value);
}

// ──────────────────────────────────────────────────────────────────────────────
// Cosmetics inventory section
// ──────────────────────────────────────────────────────────────────────────────

class _CosmeticsInventorySection extends StatelessWidget {
  const _CosmeticsInventorySection();

  static const _featuredTypes = <CosmeticType>[
    CosmeticType.frame,
    CosmeticType.companion,
    CosmeticType.background,
  ];

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watch<CosmeticsProvider>();
    final state = cosmetics.state;
    final l10n = AppLocalizations.of(context);
    final config = CosmeticsConfig.standard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InventorySectionHead(
          onShowAll: state == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CosmeticsScreen(),
                    ),
                  ),
        ),
        const SizedBox(height: 10),
        if (state == null)
          _InventoryHint(
            text: cosmetics.isLoading
                ? 'Načítám inventář…'
                : 'Inventář bude dostupný po přihlášení.',
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _featuredTypes.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _FeaturedCosmeticTile(
                    type: _featuredTypes[i],
                    item: _featuredForType(
                      cosmetics,
                      state,
                      _featuredTypes[i],
                    ),
                    l10n: l10n,
                    config: config,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CosmeticsScreen(
                          initialType: _featuredTypes[i],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  _FeaturedCosmetic? _featuredForType(
    CosmeticsProvider cosmetics,
    UserCosmeticsState state,
    CosmeticType type,
  ) {
    final catalog = cosmetics.service.catalog;
    final equippedId = state.equipped.slotId(type);
    if (equippedId != null && state.unlocked.containsKey(equippedId)) {
      final equipped = catalog.byId(equippedId);
      if (equipped != null && equipped.isEnabled) {
        return _FeaturedCosmetic(definition: equipped, isEquipped: true);
      }
    }

    final unlocked = catalog
        .byType(type)
        .where((def) => def.isEnabled && state.unlocked.containsKey(def.id))
        .toList()
      ..sort((a, b) {
        final aAt = state.unlocked[a.id]!.unlockedAt;
        final bAt = state.unlocked[b.id]!.unlockedAt;
        return bAt.compareTo(aAt);
      });
    if (unlocked.isEmpty) return null;
    return _FeaturedCosmetic(definition: unlocked.first, isEquipped: false);
  }
}

class _InventorySectionHead extends StatelessWidget {
  const _InventorySectionHead({required this.onShowAll});

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.auto_awesome,
            size: 14, color: Tokens.accent.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'KOSMETIKA',
            style: TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w900,
              color: Tokens.accent,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (onShowAll != null)
          InkWell(
            onTap: onShowAll,
            borderRadius: BorderRadius.circular(Tokens.radiusIcon),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Zobrazit vše',
                    style: TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      fontWeight: FontWeight.w800,
                      color: Tokens.onSurfaceMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 14, color: Tokens.onSurfaceMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InventoryHint extends StatelessWidget {
  const _InventoryHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: Tokens.fontSizeSmall,
          fontWeight: FontWeight.w600,
          color: Tokens.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _FeaturedCosmetic {
  const _FeaturedCosmetic({
    required this.definition,
    required this.isEquipped,
  });

  final CosmeticDefinition definition;
  final bool isEquipped;
}

class _FeaturedCosmeticTile extends StatelessWidget {
  const _FeaturedCosmeticTile({
    required this.type,
    required this.item,
    required this.l10n,
    required this.config,
    required this.onTap,
  });

  final CosmeticType type;
  final _FeaturedCosmetic? item;
  final AppLocalizations l10n;
  final CosmeticsConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final definition = item?.definition;
    final assetPath = config.resolveAssetPath(
      definition?.previewAssetKey ?? definition?.assetKey,
    );
    final hasItem = definition != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusButton),
      child: Container(
        height: 128,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: hasItem ? 0.045 : 0.025),
          borderRadius: BorderRadius.circular(Tokens.radiusButton),
          border: Border.all(
            color: Colors.white.withValues(alpha: hasItem ? 0.08 : 0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: assetPath != null
                    ? Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _PreviewFallback(
                          type: type,
                          dim: !hasItem,
                        ),
                      )
                    : _PreviewFallback(type: type, dim: !hasItem),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _labelForType(type).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w900,
                color: Tokens.onSurfaceMuted,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              definition == null ? 'Žádné' : definition.name(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontSizeSmall,
                fontWeight: FontWeight.w900,
                color: hasItem ? Tokens.onSurface : Tokens.onSurfaceFaint,
              ),
            ),
            if (item != null) ...[
              const SizedBox(height: 2),
              Text(
                item!.isEquipped ? 'VYBAVENO' : 'POSLEDNÍ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w900,
                  color:
                      item!.isEquipped ? Tokens.accent : Tokens.onSurfaceMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _labelForType(CosmeticType type) {
    switch (type) {
      case CosmeticType.frame:
        return 'Rámečky';
      case CosmeticType.relic:
        return 'Relikvie';
      case CosmeticType.background:
        return 'Pozadí';
      case CosmeticType.emblem:
        return 'Znaky';
      case CosmeticType.companion:
        return 'Společníci';
      case CosmeticType.titleFlair:
        return 'Tituly';
      case CosmeticType.mapEffect:
        return 'Efekty mapy';
    }
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({
    required this.type,
    required this.dim,
  });

  final CosmeticType type;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        _iconForType(type),
        size: 28,
        color:
            dim ? Tokens.onSurfaceFaint : Colors.white.withValues(alpha: 0.88),
      ),
    );
  }

  static IconData _iconForType(CosmeticType type) {
    switch (type) {
      case CosmeticType.frame:
        return Icons.crop_square;
      case CosmeticType.relic:
        return Icons.auto_awesome;
      case CosmeticType.background:
        return Icons.landscape;
      case CosmeticType.emblem:
        return Icons.shield;
      case CosmeticType.companion:
        return Icons.pets;
      case CosmeticType.titleFlair:
        return Icons.title;
      case CosmeticType.mapEffect:
        return Icons.map;
    }
  }
}
