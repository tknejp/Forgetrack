import 'package:flutter/material.dart';
import 'package:forgetrack/shared/theme/design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/domain/display/progression_display_resolver.dart';
import '../../../progression_engine/presentation/widgets/level_badge.dart';
import '../../domain/progression_models.dart' show ProgressionDomain;
import 'progression_domain_theme.dart';
import 'progression_primitives.dart';

/// Progression card for the Overview / Dashboard screen.
///
/// Compact state:
/// - level orb
/// - XP bar
/// - current streak + achievements pills
///
/// Expanded state:
/// - 2x2 readable stat grid
/// - domain highlights
/// - active quest preview
/// - optional "open profile" CTA
class ProgressionCard extends StatefulWidget {
  const ProgressionCard({
    super.key,
    this.onOpen,
    this.initiallyExpanded = false,
    this.barKey,
    this.forceExpanded,
  });

  final VoidCallback? onOpen;
  final bool initiallyExpanded;
  final GlobalKey? barKey;

  /// When non-null, overrides the tap-to-toggle behaviour.
  final bool? forceExpanded;

  @override
  State<ProgressionCard> createState() => _ProgressionCardState();
}

class _ProgressionCardState extends State<ProgressionCard> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _isExpanded => widget.forceExpanded ?? _expanded;

  void _toggle() {
    if (widget.forceExpanded != null) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionEngineProvider>();
    final profile = progression.profile;
    final isExpanded = _isExpanded;
    final levelDisplay =
        const ProgressionDisplayResolver().levelDisplay(profile.level);

    final xpSpan =
        (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30);
    final xpProgress = (profile.xpIntoLevel / xpSpan).clamp(0.0, 1.0);

    final current = _topStreak(progression, best: false);
    final best = isExpanded ? _topStreak(progression, best: true) : null;

    final pendingRewardCount = progression.pendingClaimNodeIds.length;
    final unlockedCount = progression.unlockedAchievementCount;

    // V2 doesn't have V1's selectDailyGoalQuestsForDate picker yet —
    // show all current daily quests, capped to keep the compact card
    // readable. Three is what V1 typically surfaced.
    final previewQuests = isExpanded
        ? progression.currentDailyQuests.take(3).toList()
        : const <EngineQuestProgress>[];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Tokens.bg,
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
          boxShadow: const [
            BoxShadow(
              color: Color(0x267C6FFF),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.9, -1),
              end: Alignment(1, 1),
              colors: [
                Color(0x267C6FFF),
                Color(0x0B31E6D2),
                Color(0x087C6FFF),
              ],
            ),
            borderRadius: BorderRadius.circular(Tokens.radiusCard),
            border: Border.all(
              color: Tokens.accent.withValues(alpha: 0.30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompactHeader(
                  level: profile.level,
                  levelTitle: levelDisplay.title(l10n),
                  levelAccent: levelDisplay.accentColor,
                  xpInto: profile.xpIntoLevel,
                  xpMax: xpSpan,
                  xpProgress: xpProgress,
                  expanded: isExpanded,
                  pendingRewardBadge: pendingRewardCount > 0
                      ? l10n.progBadgePendingClaims(pendingRewardCount)
                      : null,
                  onToggle: _toggle,
                  barKey: widget.barKey,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child: isExpanded
                      ? _ExpandedProgressionBody(
                          key: const ValueKey('expanded-progression-card'),
                          totalXp: profile.totalXp,
                          toNext: profile.xpToNextLevel < 0
                              ? 0
                              : profile.xpToNextLevel,
                          achievements: unlockedCount,
                          questsDone: progression.completedQuestCount,
                          current: current,
                          best: best,
                          previewQuests: previewQuests,
                          l10n: l10n,
                          onOpen: widget.onOpen,
                        )
                      : Padding(
                          key: const ValueKey('compact-progression-card'),
                          padding: const EdgeInsets.only(top: 12),
                          child: _HighlightPills(
                            currentStreak: current,
                            unlockedCount: unlockedCount,
                            achievementsLabel: l10n.progBadgeAchievements,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedProgressionBody extends StatelessWidget {
  const _ExpandedProgressionBody({
    super.key,
    required this.totalXp,
    required this.toNext,
    required this.achievements,
    required this.questsDone,
    required this.current,
    required this.best,
    required this.previewQuests,
    required this.l10n,
    required this.onOpen,
  });

  final int totalXp;
  final int toNext;
  final int achievements;
  final int questsDone;
  final _DomainStreak? current;
  final _DomainStreak? best;
  final List<EngineQuestProgress> previewQuests;
  final dynamic l10n;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        const Divider(color: Color(0x14FFFFFF), height: 1),
        const SizedBox(height: 14),
        _MiniStatGrid(
          totalXp: totalXp,
          toNext: toNext,
          achievements: achievements,
          questsDone: questsDone,
          l10n: l10n,
        ),
        const SizedBox(height: Tokens.spaceMd),
        _DomainSummary(
          current: current,
          best: best,
          currentLabel: l10n.progStreakCurrentLabel,
          bestLabel: l10n.progStreakBestLabel,
          daysSuffix: l10n.progStreakDaysSuffix,
        ),
        if (previewQuests.isNotEmpty) ...[
          const SizedBox(height: Tokens.spaceMd),
          _ActiveQuestsPreview(
            quests: previewQuests,
            label: l10n.progQuestsDailyGoalsHeader,
          ),
        ],
        if (onOpen != null) ...[
          const SizedBox(height: Tokens.spaceMd),
          _OpenCta(
            label: l10n.progOpenCta,
            onTap: onOpen!,
          ),
        ],
      ],
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.level,
    required this.levelTitle,
    required this.levelAccent,
    required this.xpInto,
    required this.xpMax,
    required this.xpProgress,
    required this.expanded,
    required this.pendingRewardBadge,
    required this.onToggle,
    this.barKey,
  });

  final int level;
  final String levelTitle;
  final Color levelAccent;
  final int xpInto;
  final int xpMax;
  final double xpProgress;
  final bool expanded;
  final String? pendingRewardBadge;
  final VoidCallback onToggle;
  final GlobalKey? barKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LevelBadge(level: level, accentColor: levelAccent, size: 44),
        const SizedBox(width: Tokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL $level · ${levelTitle.toUpperCase()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  color: levelAccent,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                key: barKey,
                child: ProgressBar(
                  value: xpProgress,
                  color: Tokens.xp,
                  glow: Tokens.xpGlow,
                  height: 6,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$xpInto / $xpMax XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: Tokens.fontSizeCaption,
                        color: Color(0xA8FFFFFF),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (pendingRewardBadge != null) ...[
                    const SizedBox(width: Tokens.spaceSm),
                    _PendingRewardBadge(label: pendingRewardBadge!),
                  ],
                ],
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

class _PendingRewardBadge extends StatelessWidget {
  const _PendingRewardBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Tokens.xp.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(
          color: Tokens.xp.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: Tokens.fontSizeTiny,
          fontWeight: FontWeight.w900,
          color: Tokens.xp,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.065),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: ExpandChevron(
          expanded: expanded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _HighlightPills extends StatelessWidget {
  const _HighlightPills({
    required this.currentStreak,
    required this.unlockedCount,
    required this.achievementsLabel,
  });

  final _DomainStreak? currentStreak;
  final int unlockedCount;
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
                : currentStreak!.domain.label(context.l10n),
            color: Tokens.active.color,
            dim: Tokens.active.dim,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _HighlightPill(
            icon: Icons.shield_moon_rounded,
            value: '$unlockedCount',
            caption: achievementsLabel,
            color: Tokens.accent,
            dim: Tokens.accent.withValues(alpha: 0.18),
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
      height: 42,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: dim,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Tokens.spaceSm),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: caption,
                    style: TextStyle(
                      fontSize: Tokens.fontSizeCaption,
                      color: color.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w800,
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
    final compactTotalXp = NumberFormat.compact(locale: locale).format(totalXp);
    final compactToNext = NumberFormat.compact(locale: locale).format(toNext);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStatCell(
                icon: Icons.stars_rounded,
                value: compactTotalXp,
                label: l10n.progMiniStatTotalXp,
                color: Tokens.accent,
              ),
            ),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(
              child: _MiniStatCell(
                icon: Icons.trending_up_rounded,
                value: compactToNext,
                label: l10n.progMiniStatToNext,
                color: Tokens.sleep.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.spaceSm),
        Row(
          children: [
            Expanded(
              child: _MiniStatCell(
                icon: Icons.shield_moon_rounded,
                value: '$achievements',
                label: l10n.progMiniStatAchievements,
                color: Tokens.accent,
              ),
            ),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(
              child: _MiniStatCell(
                icon: Icons.flag_rounded,
                value: '$questsDone',
                label: l10n.progMiniStatQuests,
                color: Tokens.steps.color,
              ),
            ),
          ],
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
      height: 78,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
        border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Tokens.radiusIcon),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.7,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeTiny,
                    fontWeight: FontWeight.w800,
                    color: Tokens.onSurfaceFaint,
                    letterSpacing: 0.75,
                    height: 1,
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

class _DomainSummary extends StatelessWidget {
  const _DomainSummary({
    required this.current,
    required this.best,
    required this.currentLabel,
    required this.bestLabel,
    required this.daysSuffix,
  });

  final _DomainStreak? current;
  final _DomainStreak? best;
  final String currentLabel;
  final String bestLabel;
  final String daysSuffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DomainSummaryPill(
            icon: Icons.local_fire_department_rounded,
            label: currentLabel,
            value: current == null
                ? '0 $daysSuffix'
                : '${current!.currentStreak} $daysSuffix',
            caption: current == null
                ? context.l10n.progBadgeStreakEmpty
                : current!.domain.label(context.l10n),
            domain: current?.domain,
            fallbackColor: Tokens.active.color,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _DomainSummaryPill(
            icon: Icons.emoji_events_rounded,
            label: bestLabel,
            value: best == null
                ? '0 $daysSuffix'
                : '${best!.bestStreak} $daysSuffix',
            caption: best == null
                ? context.l10n.progBadgeStreakHint
                : best!.domain.label(context.l10n),
            domain: best?.domain,
            fallbackColor: Tokens.calories.color,
          ),
        ),
      ],
    );
  }
}

class _DomainSummaryPill extends StatelessWidget {
  const _DomainSummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.domain,
    required this.fallbackColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final ProgressionDomain? domain;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final color = domain == null
        ? fallbackColor
        : ProgressionDomainTheme.colorFor(domain!);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeTiny,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.spaceSm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.6,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            caption.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Tokens.fontSizeTiny,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.72),
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
  });

  final List<EngineQuestProgress> quests;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Tokens.radiusButton),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Tokens.onSurfaceFaint,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 2),
          for (int i = 0; i < quests.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.045),
              ),
            _MiniQuestRow(quest: quests[i]),
          ],
        ],
      ),
    );
  }
}

class _MiniQuestRow extends StatelessWidget {
  const _MiniQuestRow({
    required this.quest,
  });

  final EngineQuestProgress quest;

  @override
  Widget build(BuildContext context) {
    final domain = quest.domain ?? ProgressionDomain.activity;
    final color = ProgressionDomainTheme.colorFor(domain);
    final rawPct = quest.progress * 100;
    final pct =
        (rawPct.isNaN || rawPct.isInfinite) ? 0 : rawPct.clamp(0, 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgDomIco(domain: domain, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.node.titleKey(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  value: quest.progress,
                  color: color,
                  glow: color.withValues(alpha: 0.28),
                  height: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            quest.isAvailableForClaim ? '✓' : '$pct%',
            style: TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenCta extends StatelessWidget {
  const _OpenCta({
    required this.label,
    required this.onTap,
  });

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
              Tokens.accent.withValues(alpha: 0.86),
              Tokens.accent.withValues(alpha: 0.58),
            ],
          ),
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
          boxShadow: const [
            BoxShadow(
              color: Tokens.accentGlow,
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Colors.white,
            ),
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

_DomainStreak? _topStreak(
  ProgressionEngineProvider provider, {
  required bool best,
}) {
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
