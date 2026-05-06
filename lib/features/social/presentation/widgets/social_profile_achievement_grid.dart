import 'package:flutter/material.dart';
import 'package:forgetrack/shared/presentation/achievement_badge_specs.dart';

import '../../../../features/progression/domain/progression_models.dart';
import '../../../progression/domain/catalog/rule_catalog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/tiny_pill.dart';
import '../social_profile_utils.dart';

// ── Achievement grid ──────────────────────────────────────────────────────────

class FriendAchievementsGrid extends StatelessWidget {
  const FriendAchievementsGrid({
    super.key,
    required this.achievements,
    required this.l10n,
  });

  final List<ProgressionAchievement> achievements;
  final AppLocalizations l10n;

  static const _difficultyOrder = {
    'extraHard': 0,
    'hard': 1,
    'medium': 2,
    'easy': 3,
  };

  @override
  Widget build(BuildContext context) {
    final sorted = List<ProgressionAchievement>.from(achievements)
      ..sort((a, b) {
        final aOrder =
            _difficultyOrder[a.difficulty.toString().split('.').last] ?? 99;
        final bOrder =
            _difficultyOrder[b.difficulty.toString().split('.').last] ?? 99;
        return aOrder.compareTo(bOrder);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 620 ? 4 : 3;
        final aspectRatio = width >= 620 ? 0.98 : 0.9;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _FriendAchievementTile(
              achievement: sorted[index],
              l10n: l10n,
            );
          },
        );
      },
    );
  }
}

class _FriendAchievementTile extends StatelessWidget {
  const _FriendAchievementTile({
    required this.achievement,
    required this.l10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final badge = achievementBadgeSpec(achievement);
    final color = badge.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showFriendAchievementDetailsSheet(
        context,
        achievement: achievement,
        l10n: l10n,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.13),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: color.withValues(alpha: 0.27)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                friendAchievementDisplayLabel(achievement, context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Tokens.fontSizeTiny,
                  fontWeight: FontWeight.w700,
                  color: color,
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

class _FriendAchievementEmojiBadge extends StatelessWidget {
  const _FriendAchievementEmojiBadge({
    required this.emoji,
    required this.color,
  });

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Center(
        child:
            Text(emoji, style: const TextStyle(fontSize: Tokens.fontSizeTitle)),
      ),
    );
  }
}

class _FriendAchievementDetailsSheet extends StatelessWidget {
  const _FriendAchievementDetailsSheet({
    required this.achievement,
    required this.l10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final badge = achievementBadgeSpec(achievement);
    final color = badge.color;
    final locale = Localizations.localeOf(context).toString();
    final summary = friendAchievementCompactSummary(
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
                _FriendAchievementEmojiBadge(
                  emoji: badge.emoji,
                  color: color,
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
                  label: l10n.progAchievementStatusUnlocked,
                  color: color,
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
                  label: friendAchievementDifficultyLabel(achievement, l10n),
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
            if (achievement.unlockedAt != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(Tokens.radiusTile),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(
                  l10n.progQuestCompletedOn(
                    formatAchievementDateTime(achievement.unlockedAt!, locale),
                  ),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeSmall,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.9),
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

void _showFriendAchievementDetailsSheet(
  BuildContext context, {
  required ProgressionAchievement achievement,
  required AppLocalizations l10n,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _FriendAchievementDetailsSheet(
      achievement: achievement,
      l10n: l10n,
    ),
  );
}
