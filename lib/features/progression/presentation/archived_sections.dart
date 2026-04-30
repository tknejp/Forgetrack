// ARCHIVED 2026-04-29
//
// Original "Přehled postupu" (overview summary) and "Série" (streak duel)
// sections from `ft_progression_screen.dart`, plus the supporting
// `_SummaryGrid` / `_SummaryItem` helpers.
//
// They were replaced by a cosmetics-inventory section in the progression
// home. Code is preserved here verbatim (modulo making private types public
// so the file compiles standalone) so it can be restored later without
// digging through git history.
//
// **This file is intentionally not imported anywhere.** Importing it does
// nothing visual on its own — the sections are widgets that need to be
// dropped back into the screen's ListView.
//
// To restore (rough sketch):
//   1. import 'archived_sections.dart' in ft_progression_screen.dart,
//   2. inside the ListView children, drop in:
//        ArchivedOverviewSection(
//          completedQuestsCount: viewData.completedQuests.length,
//          unlockedAchievementsCount: viewData.unlocked.length,
//        ),
//        ArchivedStreakSection(viewData: viewData, l10n: l10n, progL10n: progL10n),
//   3. delete the cosmetics inventory section that took their place.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/ft_design_tokens.dart';
import '../domain/progression_models.dart';
import 'progression_l10n.dart';
import 'widgets/ft_progression_primitives.dart';

/// Mirror of the screen's private `_DomainStreak`. Kept public here so the
/// archive file can compile standalone.
class ArchivedDomainStreak {
  const ArchivedDomainStreak({
    required this.domain,
    required this.currentStreak,
    required this.bestStreak,
  });
  final ProgressionDomain domain;
  final int currentStreak;
  final int bestStreak;
}

/// Light view-data the streak section needs.
class ArchivedStreakViewData {
  const ArchivedStreakViewData({
    required this.current,
    required this.best,
  });
  final ArchivedDomainStreak? current;
  final ArchivedDomainStreak? best;
}

class ArchivedOverviewSection extends StatelessWidget {
  const ArchivedOverviewSection({
    super.key,
    required this.completedQuestsCount,
    required this.unlockedAchievementsCount,
  });

  final int completedQuestsCount;
  final int unlockedAchievementsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FtProgSectionHead(
          label: l10n.progSummarySectionLabel,
          accent: FtTokens.accent,
        ),
        const SizedBox(height: 8),
        ArchivedSummaryGrid(
          items: [
            ArchivedSummaryItem(
              label: l10n.progSummaryCompletedQuests,
              value: '$completedQuestsCount',
              tone: FtTokens.steps.color,
              icon: Icons.flag_rounded,
            ),
            ArchivedSummaryItem(
              label: l10n.progSummaryAchievements,
              value: '$unlockedAchievementsCount',
              tone: FtTokens.accent,
              icon: Icons.shield_moon_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class ArchivedStreakSection extends StatelessWidget {
  const ArchivedStreakSection({
    super.key,
    required this.viewData,
    required this.l10n,
    required this.progL10n,
  });

  final ArchivedStreakViewData viewData;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FtProgSectionHead(
          label: l10n.progStreakSectionLabel,
          caption: l10n.progStreakSectionCaption,
          accent: FtTokens.active.color,
        ),
        const SizedBox(height: 10),
        FtProgStreakDuel(
          currentLabel: l10n.progStreakCurrentLabel,
          currentValue: viewData.current?.currentStreak ?? 0,
          currentCaption: viewData.current == null
              ? l10n.progBadgeStreakEmpty
              : progL10n.domainLabel(viewData.current!.domain),
          currentDomain: viewData.current?.domain,
          bestLabel: l10n.progStreakBestLabel,
          bestValue: viewData.best?.bestStreak ?? 0,
          bestCaption: viewData.best == null
              ? l10n.progBadgeStreakHint
              : progL10n.domainLabel(viewData.best!.domain),
          bestDomain: viewData.best?.domain,
          daysSuffix: l10n.progStreakDaysSuffix,
          valueSize: 30,
          currentColor: FtTokens.calories.color,
          currentDim: FtTokens.calories.dim,
          currentGlow: FtTokens.calories.glow,
          bestColor: FtTokens.active.color,
          bestDim: FtTokens.active.dim,
          bestGlow: FtTokens.active.glow,
        ),
      ],
    );
  }
}

class ArchivedSummaryGrid extends StatelessWidget {
  const ArchivedSummaryGrid({super.key, required this.items});
  final List<ArchivedSummaryItem> items;

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
        childAspectRatio: 2.0,
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
            ],
          ),
        );
      },
    );
  }
}

class ArchivedSummaryItem {
  const ArchivedSummaryItem({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });
  final String label;
  final String value;
  final Color tone;
  final IconData icon;
}
