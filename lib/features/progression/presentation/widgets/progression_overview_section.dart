import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/ft_expand_chevron.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../domain/progression_models.dart' show ProgressionDomain;
import 'progression_domain_theme.dart';

/// Compact, expandable progression overview rendered on the Hero tab.
///
/// Collapsed:
///   * 3 inline stat chips (total XP, achievements, current top streak)
///   * chevron to expand
///
/// Expanded:
///   * 2x2 grid (total XP, XP to next, achievements, quests done)
///   * current + best domain streak pills
///
/// Active daily quests no longer live here — they moved to the expanded
/// state of `HeroProgressionHeader`.
class ProgressionOverviewSection extends StatefulWidget {
  const ProgressionOverviewSection({super.key});

  @override
  State<ProgressionOverviewSection> createState() =>
      _ProgressionOverviewSectionState();
}

class _ProgressionOverviewSectionState
    extends State<ProgressionOverviewSection> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progression = context.watch<ProgressionEngineProvider>();
    final profile = progression.profile;

    final current = _topStreak(progression, best: false);
    final best = _topStreak(progression, best: true);
    final unlockedCount = progression.unlockedAchievementCount;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(Tokens.radiusCard),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CompactStatRow(
                totalXp: profile.totalXp,
                achievements: unlockedCount,
                topStreak: current?.currentStreak ?? 0,
                expanded: _expanded,
                onToggle: _toggle,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
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
                child: _expanded
                    ? Padding(
                        key: const ValueKey('overview-expanded'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            _MiniStatGrid(
                              totalXp: profile.totalXp,
                              toNext: profile.xpToNextLevel < 0
                                  ? 0
                                  : profile.xpToNextLevel,
                              achievements: unlockedCount,
                              questsDone: progression.completedQuestCount,
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
                          ],
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('overview-collapsed'),
                        width: double.infinity,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStatRow extends StatelessWidget {
  const _CompactStatRow({
    required this.totalXp,
    required this.achievements,
    required this.topStreak,
    required this.expanded,
    required this.onToggle,
  });

  final int totalXp;
  final int achievements;
  final int topStreak;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final compactXp = NumberFormat.compact(locale: locale).format(totalXp);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _CompactChip(
            icon: Icons.stars_rounded,
            value: compactXp,
            label: l10n.progMiniStatTotalXp,
            color: Tokens.accent,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _CompactChip(
            icon: Icons.shield_moon_rounded,
            value: '$achievements',
            label: l10n.progMiniStatAchievements,
            color: Tokens.accent,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: _CompactChip(
            icon: Icons.local_fire_department_rounded,
            value: '$topStreak',
            label: l10n.progStreakCurrentLabel,
            color: Tokens.active.color,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ExpandChevron(
              expanded: expanded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
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
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextSpan(
                    text: '  ${label.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.72),
                      letterSpacing: 0.5,
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

// ── Mini stats grid ───────────────────────────────────────────────────────────

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
  final AppLocalizations l10n;

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

// ── Domain streak summary ─────────────────────────────────────────────────────

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

// ── Helpers ───────────────────────────────────────────────────────────────────

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
