import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../theme/ft_design_tokens.dart';
import '../../../../widgets/ft/ft_progress_bar.dart';
import '../../domain/progression_models.dart';
import '../progression_l10n.dart';
import '../progression_provider.dart';
import 'ft_progression_domain_theme.dart';
import 'ft_progression_primitives.dart';

/// Redesigned progression card for the Overview / Dashboard screen.
///
/// Compact state: level orb + XP bar + streak & achievement pills.
/// Expanded state: 4-column mini stat grid + streak duel + active quest
/// preview + "open profile" CTA.
class FtProgressionCard extends StatefulWidget {
  const FtProgressionCard({
    super.key,
    required this.onOpen,
    this.initiallyExpanded = false,
  });

  final VoidCallback onOpen;
  final bool initiallyExpanded;

  @override
  State<FtProgressionCard> createState() => _FtProgressionCardState();
}

class _FtProgressionCardState extends State<FtProgressionCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);
    final progression = context.watch<ProgressionProvider>();
    final profile = progression.profile;

    final xpSpan =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);
    final xpProgress = (profile.xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    final current = _topStreak(progression, best: false);
    final best = _topStreak(progression, best: true);
    final unlockedCount = progression.achievements
        .where((achievement) => achievement.unlocked)
        .length;

    final activeQuests = [...progression.activeQuests]
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final previewQuests = activeQuests.take(3).toList(growable: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.8, -1),
            end: Alignment(1, 1),
            colors: [Color(0x247C6FFF), Color(0x0A7C6FFF)],
          ),
          borderRadius: BorderRadius.circular(FtTokens.radiusCard),
          border: Border.all(color: FtTokens.accent.withValues(alpha: 0.28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E7C6FFF),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompactHeader(
              level: profile.level,
              levelTitle: profile.levelTitle,
              xpInto: profile.xpIntoLevel,
              xpMax: xpSpan,
              xpProgress: xpProgress,
              expanded: _expanded,
              onToggle: _toggle,
            ),
            if (!_expanded) ...[
              const SizedBox(height: 12),
              _HighlightPills(
                currentStreak: current,
                unlockedCount: unlockedCount,
                progL10n: progL10n,
                achievementsLabel: l10n.progBadgeAchievements,
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0x12FFFFFF), height: 1),
              const SizedBox(height: 12),
              _MiniStatGrid(
                totalXp: profile.totalXp,
                toNext: profile.xpToNextLevel < 0 ? 0 : profile.xpToNextLevel,
                achievements: unlockedCount,
                questsDone: progression.completedQuests.length,
                l10n: l10n,
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
              ),
              if (previewQuests.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ActiveQuestsPreview(
                  quests: previewQuests,
                  label: l10n.progActiveQuestsLabel,
                  progL10n: progL10n,
                ),
              ],
              const SizedBox(height: 12),
              _OpenCta(
                label: l10n.progOpenCta,
                onTap: widget.onOpen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.level,
    required this.levelTitle,
    required this.xpInto,
    required this.xpMax,
    required this.xpProgress,
    required this.expanded,
    required this.onToggle,
  });

  final int level;
  final String levelTitle;
  final int xpInto;
  final int xpMax;
  final double xpProgress;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FtTokens.accent,
                FtTokens.accent.withValues(alpha: 0.53),
              ],
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: FtTokens.accent.withValues(alpha: 0.4), width: 1.5),
            boxShadow: const [
              BoxShadow(color: FtTokens.accentGlow, blurRadius: 14),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'LEVEL $level · ${levelTitle.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: FtTokens.accent,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$xpInto / $xpMax XP',
                    style: const TextStyle(
                      fontSize: 10,
                      color: FtTokens.onSurfaceFaint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FtProgressBar(
                value: xpProgress,
                color: FtTokens.accent,
                glow: FtTokens.accentGlow,
                height: 5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ChevronButton(expanded: expanded, onTap: onToggle),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: expanded ? 0.5 : 0,
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HighlightPills extends StatelessWidget {
  const _HighlightPills({
    required this.currentStreak,
    required this.unlockedCount,
    required this.progL10n,
    required this.achievementsLabel,
  });

  final _DomainStreak? currentStreak;
  final int unlockedCount;
  final ProgressionL10n progL10n;
  final String achievementsLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HighlightPill(
            icon: Icons.local_fire_department_rounded,
            value: '${currentStreak?.currentStreak ?? 0}',
            caption: currentStreak == null
                ? context.l10n.progBadgeStreakHint
                : progL10n.domainLabel(currentStreak!.domain),
            color: FtTokens.active.color,
            dim: FtTokens.active.dim,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _HighlightPill(
            icon: Icons.shield_moon_rounded,
            value: '$unlockedCount',
            caption: achievementsLabel,
            color: FtTokens.accent,
            dim: FtTokens.accent.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({
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
      padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
      decoration: BoxDecoration(
        color: dim,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: caption,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatGrid extends StatelessWidget {
  const _MiniStatGrid({
    required this.totalXp,
    required this.toNext,
    required this.achievements,
    required this.questsDone,
    required this.l10n,
  });

  final int totalXp;
  final int toNext;
  final int achievements;
  final int questsDone;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final compact = NumberFormat.compact(locale: locale).format(totalXp);
    return Row(
      children: [
        Expanded(
          child: _MiniStatCell(
            icon: Icons.stars_rounded,
            value: compact,
            label: l10n.progMiniStatTotalXp,
            color: FtTokens.accent,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCell(
            icon: Icons.trending_up_rounded,
            value: '$toNext',
            label: l10n.progMiniStatToNext,
            color: FtTokens.sleep.color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCell(
            icon: Icons.shield_moon_rounded,
            value: '$achievements',
            label: l10n.progMiniStatAchievements,
            color: FtTokens.accent,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _MiniStatCell(
            icon: Icons.flag_rounded,
            value: '$questsDone',
            label: l10n.progMiniStatQuests,
            color: FtTokens.steps.color,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCell extends StatelessWidget {
  const _MiniStatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurfaceFaint,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveQuestsPreview extends StatelessWidget {
  const _ActiveQuestsPreview({
    required this.quests,
    required this.label,
    required this.progL10n,
  });

  final List<ProgressionQuest> quests;
  final String label;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: FtTokens.onSurfaceFaint,
              letterSpacing: 0.9,
            ),
          ),
          for (int i = 0; i < quests.length; i++) ...[
            if (i > 0)
              Container(height: 1, color: Colors.white.withValues(alpha: 0.04)),
            _MiniQuestRow(quest: quests[i], progL10n: progL10n),
          ],
        ],
      ),
    );
  }
}

class _MiniQuestRow extends StatelessWidget {
  const _MiniQuestRow({required this.quest, required this.progL10n});
  final ProgressionQuest quest;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = FtProgressionDomainTheme.resolveForQuest(quest);
    final color = FtProgressionDomainTheme.colorFor(domain);
    final pct = (quest.progress * 100).clamp(0, 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                FtProgressBar(
                  value: quest.progress,
                  color: color,
                  glow: color.withValues(alpha: 0.28),
                  height: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenCta extends StatelessWidget {
  const _OpenCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FtTokens.accent.withValues(alpha: 0.85),
              FtTokens.accent.withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: FtTokens.accentGlow, blurRadius: 18, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
          ],
        ),
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
