import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../cosmetics/presentation/widgets/cosmetics_inventory_section.dart';
import '../../../journey/presentation/widgets/journey_preview_card.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../../progression_engine/presentation/adapters/engine_achievement_view.dart';
import '../../../social/application/social_provider.dart';
import '../../../social/domain/social_models.dart';
import '../../../progression_engine/presentation/widgets/progression_primitives.dart';
import '../widgets/progression_overview_section.dart';
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
    final progression = context.watch<ProgressionEngineProvider>();
    final views = buildEngineAchievementViews(progression, l10n);
    final unlocked = [
      for (final v in views)
        if (v.unlocked) v,
    ]..sort((a, b) {
        final rarity = b.display.rarity.index.compareTo(a.display.rarity.index);
        if (rarity != 0) return rarity;
        final at = a.unlockedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.unlockedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final inProgress = [
      for (final v in views)
        if (!v.unlocked) v,
    ]..sort((a, b) {
        final rarity = b.display.rarity.index.compareTo(a.display.rarity.index);
        if (rarity != 0) return rarity;
        return b.progress.compareTo(a.progress);
      });

    if (progression.isLoading && progression.rewardHistory.isEmpty) {
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
                  const ProgressionOverviewSection(),
                  const SizedBox(height: Tokens.spaceLg),
                  // ARCHIVED 2026-04-29: "Přehled postupu" + "Série" sections
                  // moved to archived_sections.dart. Replaced by inventory.
                  const CosmeticsInventorySection(),
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
              unlocked: unlocked,
              inProgress: inProgress,
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

  final List<EngineAchievementView> unlocked;
  final List<EngineAchievementView> inProgress;
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

  final List<EngineAchievementView> achievements;
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
              view: achievements[index],
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
    required this.view,
    required this.l10n,
  });

  final EngineAchievementView view;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = view.display.accentColor;
    final unlocked = view.unlocked;
    final emoji = view.display.badgeEmoji ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAchievementDetailsSheet(
        context,
        view: view,
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
              emoji,
              style: TextStyle(
                fontSize: 22,
                color: unlocked ? null : const Color(0x66FFFFFF),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _achievementDisplayLabel(view, l10n),
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
    required this.view,
    required this.l10n,
  });

  final EngineAchievementView view;
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
      widget.view.id,
      resolvedTitle: widget.view.display.title(widget.l10n),
      resolvedDescription: widget.view.display.description(widget.l10n),
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
      achievementId: widget.view.id,
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
    final view = widget.view;
    final l10n = widget.l10n;
    final color = view.display.accentColor;
    final emoji = view.display.badgeEmoji ?? '';
    final locale = Localizations.localeOf(context).toString();
    final unlocked = view.unlocked;
    final progressLabel = l10n.progProgressRatio(
      view.currentValue,
      view.targetValue,
    );
    final summary = _achievementCompactSummary(view, l10n, locale);
    final subjectLabel = view.display.subjectLabel?.call(l10n) ??
        view.display.domain?.label(l10n);
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
                  emoji: emoji,
                  color: color,
                  unlocked: unlocked,
                ),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.display.title(l10n),
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
              view.display.description(l10n),
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
                  label: view.display.rarity.label(l10n),
                  color: color,
                ),
                TinyPill(
                  label: progressLabel,
                  color: color,
                ),
                if (subjectLabel != null)
                  TinyPill(
                    label: subjectLabel,
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
                    value: unlocked ? 1 : view.progress,
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
                  if (unlocked && view.unlockedAt != null) ...[
                    const SizedBox(height: Tokens.spaceXs),
                    Text(
                      l10n.progQuestCompletedOn(
                        progressionFormatDateTime(view.unlockedAt!, locale),
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
                achievementId: view.id,
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
  required EngineAchievementView view,
  required AppLocalizations l10n,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _AchievementDetailsSheet(
      view: view,
      l10n: l10n,
    ),
  );
}

// ── Achievement display helpers ───────────────────────────────────────────────

String _achievementDisplayLabel(
  EngineAchievementView view,
  AppLocalizations l10n,
) {
  final levelTarget = view.levelTarget;
  if (levelTarget != null) return 'LEVEL $levelTarget';
  return view.display.title(l10n).toUpperCase();
}

String _achievementCompactSummary(
  EngineAchievementView view,
  AppLocalizations l10n,
  String locale,
) {
  // Level milestones get a "LEVEL N" summary regardless of how the
  // resolver shaped the underlying achievement.
  final levelTarget = view.levelTarget;
  if (levelTarget != null) return 'LEVEL $levelTarget';

  final subject = view.display.subjectLabel?.call(l10n) ??
      view.display.domain?.label(l10n);
  final target = view.display.targetValue ?? view.targetValue;
  if (target <= 0) {
    return view.display.title(l10n);
  }
  if (subject != null && subject.isNotEmpty) {
    return '${_formatCompactInt(target, locale)} $subject';
  }
  return '${_formatCompactInt(target, locale)} XP';
}

String _formatCompactInt(int value, String locale) {
  return NumberFormat.compact(locale: locale).format(value);
}

