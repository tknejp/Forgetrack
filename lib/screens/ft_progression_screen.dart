import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../features/progression/domain/progression_models.dart';
import '../features/progression/presentation/progression_l10n.dart';
import '../features/progression/presentation/progression_provider.dart';
import '../features/progression/presentation/widgets/ft_progression_domain_theme.dart';
import '../features/progression/presentation/widgets/ft_progression_primitives.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/ft_design_tokens.dart';
import '../widgets/ft/ft_progress_bar.dart';

class FtProgressionScreen extends StatelessWidget {
  const FtProgressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);
    final auth = context.watch<AuthProvider>();
    final progression = context.watch<ProgressionProvider>();

    final displayName = auth.user?.displayName?.trim();
    final firstName = displayName?.split(' ').firstOrNull ?? 'Adventurer';
    final profile = progression.profile;

    final xpSpan =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);

    final unlocked = progression.achievements
        .where((a) => a.unlocked)
        .toList(growable: false)
      ..sort((a, b) {
        final at = a.unlockedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.unlockedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final inProgress = progression.achievements
        .where((a) => !a.unlocked)
        .toList(growable: false)
      ..sort((a, b) => b.progress.compareTo(a.progress));

    final activeQuests = [...progression.activeQuests]
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final completedQuests = [...progression.completedQuests]
      ..sort((a, b) {
        final at = a.completedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.completedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });

    final rewardHistory = [...progression.rewardGrants]
      ..sort((a, b) => b.grantedAt.compareTo(a.grantedAt));

    final current = _topStreak(progression, best: false);
    final best = _topStreak(progression, best: true);

    if (progression.isLoading && progression.rewardGrants.isEmpty) {
      return _ProgressionScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            _TopBar(),
            SizedBox(height: 10),
            _LoadingBlock(height: 180),
            SizedBox(height: 12),
            _LoadingBlock(height: 140),
            SizedBox(height: 12),
            _LoadingBlock(height: 120),
          ],
        ),
      );
    }

    return _ProgressionScaffold(
      child: RefreshIndicator(
        onRefresh: progression.refresh,
        color: FtTokens.accent,
        backgroundColor: FtTokens.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            const _TopBar(),
            const SizedBox(height: 12),
            _HeroCard(
              displayName: displayName ?? firstName,
              profile: profile,
              xpSpan: xpSpan,
              currentStreakCount: current?.currentStreak ?? 0,
              currentStreakDomain:
                  current == null ? null : progL10n.domainLabel(current.domain),
              unlockedCount: unlocked.length,
              lastEvaluatedAt: progression.lastEvaluatedAt,
              l10n: l10n,
            ),
            if (progression.error != null) ...[
              const SizedBox(height: 10),
              _InlineErrorBanner(message: progression.error!),
            ],
            const SizedBox(height: 16),
            FtProgSectionHead(
              label: l10n.progSummarySectionLabel,
              accent: FtTokens.accent,
            ),
            const SizedBox(height: 8),
            _SummaryGrid(
              items: [
                _SummaryItem(
                  label: l10n.progSummaryCurrentStreak,
                  value: '${current?.currentStreak ?? 0}',
                  caption: current == null
                      ? l10n.progSummaryNoActiveChain
                      : progL10n.domainLabel(current.domain),
                  tone: FtTokens.active.color,
                  icon: Icons.local_fire_department_rounded,
                ),
                _SummaryItem(
                  label: l10n.progSummaryBestStreak,
                  value: '${best?.bestStreak ?? 0}',
                  caption: best == null
                      ? l10n.progSummaryBuildConsistency
                      : progL10n.domainLabel(best.domain),
                  tone: FtTokens.calories.color,
                  icon: Icons.bolt_rounded,
                ),
                _SummaryItem(
                  label: l10n.progSummaryCompletedQuests,
                  value: '${completedQuests.length}',
                  tone: FtTokens.steps.color,
                  icon: Icons.flag_rounded,
                ),
                _SummaryItem(
                  label: l10n.progSummaryAchievements,
                  value: '${unlocked.length}',
                  tone: FtTokens.accent,
                  icon: Icons.shield_moon_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FtProgSectionHead(
              label: l10n.progStreakSectionLabel,
              caption: l10n.progStreakSectionCaption,
              accent: FtTokens.active.color,
            ),
            const SizedBox(height: 10),
            FtProgStreakDuel(
              currentLabel: l10n.progStreakCurrentLabel,
              currentValue: current?.currentStreak ?? 0,
              currentCaption: current == null
                  ? l10n.progBadgeStreakEmpty
                  : progL10n.domainLabel(current.domain),
              currentDomain: current?.domain,
              bestLabel: l10n.progStreakBestLabel,
              bestValue: best?.bestStreak ?? 0,
              bestCaption: best == null
                  ? l10n.progBadgeStreakHint
                  : progL10n.domainLabel(best.domain),
              bestDomain: best?.domain,
              daysSuffix: l10n.progStreakDaysSuffix,
              valueSize: 30,
            ),
            const SizedBox(height: 16),
            FtProgSectionHead(
              label: l10n.progQuestsSectionLabel,
              caption: l10n.progQuestsSectionCaption,
              accent: FtTokens.steps.color,
            ),
            const SizedBox(height: 8),
            _QuestsSection(
              active: activeQuests,
              completed: completedQuests,
              l10n: l10n,
              progL10n: progL10n,
            ),
            const SizedBox(height: 16),
            FtProgSectionHead(
              label: l10n.progAchievementsSectionLabel,
              caption: l10n.progAchievementsSectionCaption,
              accent: FtTokens.accent,
            ),
            const SizedBox(height: 8),
            _AchievementsSection(
              unlocked: unlocked,
              inProgress: inProgress,
              l10n: l10n,
              progL10n: progL10n,
            ),
            const SizedBox(height: 16),
            FtProgSectionHead(
              label: l10n.progRewardsSectionLabel,
              caption: l10n.progRewardsSectionCaption,
              accent: FtTokens.calories.color,
            ),
            const SizedBox(height: 8),
            _HistoryFeed(
              grants: rewardHistory,
              l10n: l10n,
              progL10n: progL10n,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionScaffold extends StatelessWidget {
  const _ProgressionScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtTokens.bg,
      body: SafeArea(bottom: false, child: child),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canPop)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FtTokens.cardBorder),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            ),
          )
        else
          const SizedBox(width: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.progScreenEyebrow,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: FtTokens.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.progScreenTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.displayName,
    required this.profile,
    required this.xpSpan,
    required this.currentStreakCount,
    required this.currentStreakDomain,
    required this.unlockedCount,
    required this.lastEvaluatedAt,
    required this.l10n,
  });

  final String displayName;
  final ProgressionProfile profile;
  final int xpSpan;
  final int currentStreakCount;
  final String? currentStreakDomain;
  final int unlockedCount;
  final DateTime? lastEvaluatedAt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final totalXpLabel =
        NumberFormat.compact(locale: locale).format(profile.totalXp);
    final xpProgress = (profile.xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.8, -1),
          end: Alignment(1, 1),
          colors: [Color(0x287C6FFF), Color(0x0D111422)],
        ),
        borderRadius: BorderRadius.circular(FtTokens.radiusCard),
        border: Border.all(color: FtTokens.accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x387C6FFF),
              blurRadius: 28,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FtTokens.accent,
                      FtTokens.accent.withValues(alpha: 0.53),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FtTokens.accent.withValues(alpha: 0.5),
                      width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: FtTokens.accentGlow, blurRadius: 20),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${profile.level}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.levelTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.onSurfaceMuted,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoBadge(
                label: l10n.progBadgeTotalXp,
                value: totalXpLabel,
                color: FtTokens.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LEVEL ${profile.level} · ${profile.levelTitle.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.accent,
                        letterSpacing: 0.9,
                      ),
                    ),
                    Text(
                      '${profile.xpIntoLevel} / $xpSpan XP',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FtTokens.onSurfaceFaint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FtProgressBar(
                  value: xpProgress,
                  color: FtTokens.accent,
                  glow: FtTokens.accentGlow,
                  height: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  icon: Icons.local_fire_department_rounded,
                  value: '$currentStreakCount',
                  caption: currentStreakDomain ?? l10n.progBadgeStreakHint,
                  color: FtTokens.active.color,
                  dim: FtTokens.active.dim,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroPill(
                  icon: Icons.shield_moon_rounded,
                  value: '$unlockedCount',
                  caption: l10n.progBadgeAchievements,
                  color: FtTokens.accent,
                  dim: FtTokens.accent.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
          if (lastEvaluatedAt != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                l10n.progLastSynced(_formatDateTime(lastEvaluatedAt!, locale)),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: FtTokens.onSurfaceFaint,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.value,
    required this.caption,
    required this.color,
    required this.dim,
  });

  final IconData icon;
  final String value;
  final String caption;
  final Color color;
  final Color dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.62),
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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: FtTokens.onSurfaceMuted,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.items});
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 16, color: item.tone),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: FtTokens.onSurfaceMuted,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: item.tone,
                  letterSpacing: -0.8,
                ),
              ),
              if (item.caption != null)
                Text(
                  item.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: FtTokens.onSurfaceFaint,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
    this.caption,
  });
  final String label;
  final String value;
  final Color tone;
  final IconData icon;
  final String? caption;
}

class _QuestsSection extends StatefulWidget {
  const _QuestsSection({
    required this.active,
    required this.completed,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionQuest> active;
  final List<ProgressionQuest> completed;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  State<_QuestsSection> createState() => _QuestsSectionState();
}

class _QuestsSectionState extends State<_QuestsSection> {
  static const _compactLimit = 3;
  bool _showAllCompleted = false;

  @override
  Widget build(BuildContext context) {
    final completedToShow = _showAllCompleted
        ? widget.completed
        : widget.completed.take(_compactLimit).toList(growable: false);

    return Column(
      children: [
        _SubContainer(
          background: Colors.black.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                label: widget.l10n.progQuestsActiveHeader,
                color: FtTokens.active.color,
              ),
              const SizedBox(height: 10),
              if (widget.active.isEmpty)
                _EmptyLine(
                  title: widget.l10n.progQuestsEmptyActiveTitle,
                  caption: widget.l10n.progQuestsEmptyActiveCaption,
                )
              else
                for (int i = 0; i < widget.active.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ActiveQuestCard(
                    quest: widget.active[i],
                    l10n: widget.l10n,
                    progL10n: widget.progL10n,
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _SubContainer(
          background: Colors.black.withValues(alpha: 0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                label: widget.l10n.progQuestsCompletedHeader,
                color: FtTokens.onSurfaceMuted,
              ),
              const SizedBox(height: 10),
              if (widget.completed.isEmpty)
                _EmptyLine(
                  title: widget.l10n.progQuestsEmptyCompletedTitle,
                  caption: widget.l10n.progQuestsEmptyCompletedCaption,
                )
              else
                for (int i = 0; i < completedToShow.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _CompletedQuestRow(
                    quest: completedToShow[i],
                    l10n: widget.l10n,
                    progL10n: widget.progL10n,
                  ),
                ],
              if (widget.completed.length > _compactLimit && !_showAllCompleted) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showAllCompleted = true),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      widget.l10n.progShowAllCount(widget.completed.length),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveQuestCard extends StatelessWidget {
  const _ActiveQuestCard({
    required this.quest,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = FtProgressionDomainTheme.resolveForQuest(quest);
    final token = FtProgressionDomainTheme.tokenFor(domain);
    final color = token.color;
    final descriptor = progL10n.questCriterionDescriptor(quest);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: token.gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: token.glow, blurRadius: 16, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FtProgDomIco(domain: domain, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progL10n.questTitle(quest),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descriptor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FtProgTinyPill(label: l10n.progQuestStatusActive, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            progL10n.questDescription(quest),
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: FtTokens.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
          FtProgressBar(
            value: quest.progress,
            color: color,
            glow: color.withValues(alpha: 0.38),
            height: 5,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                l10n.progProgressRatio(quest.currentValue, quest.targetValue),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                l10n.progPercent((quest.progress * 100).round()),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedQuestRow extends StatelessWidget {
  const _CompletedQuestRow({
    required this.quest,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final domain = FtProgressionDomainTheme.resolveForQuest(quest);
    final color = FtProgressionDomainTheme.colorFor(domain);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          FtProgDomIco(domain: domain, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progL10n.questTitle(quest),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: FtTokens.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  quest.completedAt != null
                      ? l10n.progQuestCompletedOn(
                          _formatDateTime(quest.completedAt!, locale))
                      : progL10n.questCriterionDescriptor(quest),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FtProgTinyPill(
            label: l10n.progQuestStatusCompleted,
            color: FtTokens.onSurfaceMuted,
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({
    required this.unlocked,
    required this.inProgress,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionAchievement> unlocked;
  final List<ProgressionAchievement> inProgress;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubContainer(
          background: Colors.black.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                label: l10n.progAchievementsUnlockedHeader,
                color: FtTokens.accent,
              ),
              const SizedBox(height: 10),
              if (unlocked.isEmpty)
                _EmptyLine(
                  title: l10n.progAchievementsEmptyUnlockedTitle,
                  caption: l10n.progAchievementsEmptyUnlockedCaption,
                )
              else
                for (int i = 0; i < unlocked.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _UnlockedAchievementCard(
                    achievement: unlocked[i],
                    l10n: l10n,
                    progL10n: progL10n,
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _SubContainer(
          background: Colors.black.withValues(alpha: 0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                label: l10n.progAchievementsInProgressHeader,
                color: FtTokens.onSurfaceMuted,
              ),
              const SizedBox(height: 10),
              if (inProgress.isEmpty)
                _EmptyLine(
                  title: l10n.progAchievementsEmptyInProgressTitle,
                  caption: l10n.progAchievementsEmptyInProgressCaption,
                )
              else
                for (int i = 0; i < inProgress.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _InProgressAchievementCard(
                    achievement: inProgress[i],
                    l10n: l10n,
                    progL10n: progL10n,
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UnlockedAchievementCard extends StatelessWidget {
  const _UnlockedAchievementCard({
    required this.achievement,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = FtProgressionDomainTheme.resolveForAchievement(achievement);
    final token = FtProgressionDomainTheme.tokenFor(domain);
    final color = token.color;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: token.gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: token.glow, blurRadius: 16, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
                child: Icon(Icons.workspace_premium_rounded, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  progL10n.achievementTitle(achievement),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FtProgTinyPill(label: l10n.progAchievementStatusUnlocked, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            progL10n.achievementDescription(achievement),
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: FtTokens.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
          FtProgressBar(
            value: 1,
            color: color,
            glow: color.withValues(alpha: 0.4),
            height: 4,
          ),
        ],
      ),
    );
  }
}

class _InProgressAchievementCard extends StatelessWidget {
  const _InProgressAchievementCard({
    required this.achievement,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = FtProgressionDomainTheme.resolveForAchievement(achievement);
    final color = FtProgressionDomainTheme.colorFor(domain);
    final pct = (achievement.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FtProgDomIco(domain: domain, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  progL10n.achievementTitle(achievement),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FtTokens.onSurfaceMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            progL10n.achievementDescription(achievement),
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: FtTokens.onSurfaceFaint,
            ),
          ),
          const SizedBox(height: 10),
          FtProgressBar(
            value: achievement.progress,
            color: color,
            glow: color.withValues(alpha: 0.3),
            height: 4,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.progProgressRatio(
              achievement.currentValue,
              achievement.targetValue,
            ),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: FtTokens.onSurfaceFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFeed extends StatelessWidget {
  const _HistoryFeed({
    required this.grants,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionRewardGrant> grants;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final rows = grants.take(8).toList(growable: false);
    if (rows.isEmpty) {
      return _EmptyLine(
        title: l10n.progRewardsEmptyTitle,
        caption: l10n.progRewardsEmptyCaption,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withValues(alpha: 0.05),
              ),
            _HistoryRow(grant: rows[i], locale: locale, progL10n: progL10n),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.grant,
    required this.locale,
    required this.progL10n,
  });

  final ProgressionRewardGrant grant;
  final String locale;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = grant.domain;
    final color = FtProgressionDomainTheme.colorFor(domain);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FtProgDomIco(domain: domain, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progL10n.ruleTitle(grant.ruleId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  progL10n.domainLabel(domain),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${grant.xpGranted} XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFA89BFF),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _formatDateTime(grant.grantedAt, locale),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: FtTokens.onSurfaceFaint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubContainer extends StatelessWidget {
  const _SubContainer({required this.background, required this.child});
  final Color background;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.title, required this.caption});
  final String title;
  final String caption;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: FtTokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x22FBBF24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55FBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: FtTokens.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(FtTokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }
}

class _DomainStreak {
  const _DomainStreak({
    required this.domain,
    required this.currentStreak,
    required this.bestStreak,
  });
  final ProgressionDomain domain;
  final int currentStreak;
  final int bestStreak;
}

_DomainStreak? _topStreak(ProgressionProvider provider, {required bool best}) {
  _DomainStreak? winner;
  for (final domain in ProgressionDomain.values) {
    final streak = provider.streakForDomain(domain);
    final metric = best ? streak.bestStreak : streak.currentStreak;
    if (metric <= 0) continue;
    final candidate = _DomainStreak(
      domain: domain,
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
    );
    if (winner == null) {
      winner = candidate;
      continue;
    }
    final winning = best ? winner.bestStreak : winner.currentStreak;
    if (metric > winning) winner = candidate;
  }
  return winner;
}

String _formatDateTime(DateTime value, String locale) {
  return DateFormat('d MMM · HH:mm', locale).format(value);
}
