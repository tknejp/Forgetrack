import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../domain/progression/player/player_achievement_lifecycle.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/tiny_pill.dart';
import '../../cosmetics/application/cosmetics_provider.dart';
import '../../cosmetics/domain/cosmetic_catalog.dart';
import '../../cosmetics/domain/cosmetic_models.dart';
import '../../cosmetics/presentation/widgets/cosmetic_asset_thumb.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'widgets/engine_companion_pill.dart' show showEngineRewardPreviewSheet;
import '../../journey/presentation/widgets/journey_preview_card.dart';
import '../../social/application/social_provider.dart';
import '../../social/domain/social_models.dart';
import '../application/adapters/engine_achievement_view.dart';
import '../application/progression_engine_provider.dart';
import '../domain/progression_domain_chrome.dart';
import 'widgets/progression_overview_section.dart';
import 'widgets/progression_primitives.dart';

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

typedef _HeroChrome = ({bool showLoading, String? error});

class _HeroScreenState extends State<HeroScreen> {
  @override
  Widget build(BuildContext context) {
    // Phase 1.2 / 1.3 pattern: HeroScreen.build() does not watch the
    // ProgressionEngineProvider directly. A Selector with a Dart 3 record
    // discriminator only rebuilds when loading/error chrome flips —
    // engine ticks (XP, quest claim, journal updates) leave this build
    // path untouched. ProgressionOverviewSection + JourneyPreviewCard
    // own their own context.watch; _AchievementsSliverSection owns its
    // own context.watch + the expensive buildEngineAchievementViews
    // computation that previously ran at screen level on every notify.
    return Selector<ProgressionEngineProvider, _HeroChrome>(
      selector: (_, p) => (
        showLoading: p.isLoading && p.rewardHistory.isEmpty,
        error: p.error,
      ),
      builder: (context, chrome, _) {
        if (chrome.showLoading) {
          return ProgressionScaffold(
            child: ListView(
              padding:
                  EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 24),
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

        final error = chrome.error;
        return ProgressionScaffold(
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<ProgressionEngineProvider>().refresh(),
            color: Tokens.accent,
            backgroundColor: Tokens.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (error != null)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        14, widget.topContentInset + 8, 14, 0),
                    sliver: SliverToBoxAdapter(
                      child: ProgressionErrorBanner(message: error),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    error != null ? 16 : widget.topContentInset + 16,
                    14,
                    0,
                  ),
                  sliver: const SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      ProgressionOverviewSection(),
                      SizedBox(height: Tokens.spaceLg),
                      JourneyPreviewCard(),
                      SizedBox(height: Tokens.spaceLg),
                    ]),
                  ),
                ),
                const _AchievementsSliverSection(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Achievements ──────────────────────────────────────────────────────────────

class _AchievementsSliverSection extends StatelessWidget {
  const _AchievementsSliverSection();

  @override
  Widget build(BuildContext context) {
    // Section self-watches: the heavy buildEngineAchievementViews + two
    // sorted comprehensions used to run on every engine notify at the
    // HeroScreen.build() level (overview / journey already had their
    // own watches — three deep recomputes per tick). Moved here so the
    // chrome-level Selector skips the screen rebuild entirely.
    final progression = context.watch<ProgressionEngineProvider>();
    final l10n = context.l10n;
    final views = buildEngineAchievementViews(progression, l10n);
    // Phase 8: route state filters through the sealed
    // PlayerAchievementLifecycle exposed by EngineAchievementView.lifecycle.
    int compareViews(EngineAchievementView a, EngineAchievementView b) {
      final rarity = b.display.rarity.index.compareTo(a.display.rarity.index);
      if (rarity != 0) return rarity;
      final at = a.unlockedAt?.millisecondsSinceEpoch ?? 0;
      final bt = b.unlockedAt?.millisecondsSinceEpoch ?? 0;
      final date = bt.compareTo(at);
      if (date != 0) return date;
      return b.node.sortOrder.compareTo(a.node.sortOrder);
    }

    final unlocked = [
      for (final v in views)
        if (v.lifecycle is AchievementUnlocked) v,
    ]..sort(compareViews);
    final inProgress = [
      for (final v in views)
        if (v.lifecycle is! AchievementUnlocked) v,
    ]..sort(compareViews);
    final achievements = [...unlocked, ...inProgress];

    final header = ProgSectionHead(
      label: l10n.progAchievementsSectionLabel,
      caption: l10n.progAchievementsSectionCaption,
      accent: Tokens.accent,
    );

    if (achievements.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            header,
            const SizedBox(height: Tokens.spaceSm),
            ProgressionEmptyLine(
              title: l10n.progAchievementsEmptyUnlockedTitle,
              caption: l10n.progAchievementsEmptyUnlockedCaption,
            ),
          ]),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, Tokens.spaceSm),
          sliver: SliverToBoxAdapter(child: header),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
          sliver: _AchievementBadgeSliverGrid(
            achievements: achievements,
            l10n: l10n,
          ),
        ),
      ],
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
    final unlocked = view.lifecycle is AchievementUnlocked;
    final emoji = view.display.badgeEmoji ?? '';
    final itemReward = _firstNonXpReward(view.node.rewards);
    final progress = view.progress.clamp(0.0, 1.0);
    final showProgressBar = !unlocked && progress > 0;
    final borderRadius = BorderRadius.circular(Tokens.radiusInner);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAchievementDetailsSheet(
        context,
        view: view,
        l10n: l10n,
      ),
      child: Container(
        // `clipBehavior: antiAlias` so the bottom progress bar sits
        // strictly inside the tile's rounded corners — without it the
        // bar's straight bottom edges peek past the tile's rounded
        // outline near the bottom-left / bottom-right corners.
        clipBehavior: Clip.antiAlias,
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
          borderRadius: borderRadius,
          border: Border.all(
            color: unlocked
                ? color.withValues(alpha: 0.27)
                : const Color(0x0FFFFFFF),
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    // Phase 0.2 invariant: blurRadius < 12 on tiles
                    // that pay first-paint cost when entering viewport.
                    color: color.withValues(alpha: 0.2),
                    blurRadius: Tokens.glowSm,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Positioned.fill so the icon + label stay centred within
            // the *full* tile bounds regardless of which positioned
            // siblings (reward badge, progress bar) are present. A
            // bare Column in the Stack collapses to the wider child's
            // intrinsic width and gets anchored to top-start, which
            // visibly shifted shorter labels off-centre.
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
            if (itemReward != null)
              Positioned(
                top: 5,
                right: 5,
                child: _RewardCornerBadge(
                  icon: _rewardIconFor(itemReward),
                  color: color,
                  unlocked: unlocked,
                ),
              ),
            if (showProgressBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _AchievementTileProgress(
                  progress: progress,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tile-bottom progress indicator for in-progress achievements. Flat 3-px
/// bar with no labels — purely a peripheral hint of how close the player
/// is to unlocking.
class _AchievementTileProgress extends StatelessWidget {
  const _AchievementTileProgress({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (_, constraints) => Stack(
          children: [
            Container(color: Colors.white.withValues(alpha: 0.04)),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: constraints.maxWidth * progress,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCornerBadge extends StatelessWidget {
  const _RewardCornerBadge({
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  final IconData icon;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    // Locked tiles get a much quieter badge — same shape, lower alpha
    // across fill / border / glyph — so the gift hint doesn't visually
    // compete with the unlocked achievements above it in the grid.
    final c = unlocked ? color : Tokens.onSurfaceFaint;
    final fillAlpha = unlocked ? 0.18 : 0.08;
    final borderAlpha = unlocked ? 0.32 : 0.14;
    final iconAlpha = unlocked ? 1.0 : 0.55;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: c.withValues(alpha: fillAlpha),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: borderAlpha)),
      ),
      child: Icon(icon, size: 11, color: c.withValues(alpha: iconAlpha)),
    );
  }
}

RewardDefinition? _firstNonXpReward(List<RewardDefinition> rewards) {
  for (final r in rewards) {
    if (r is XpReward || r is BonusXpReward) continue;
    return r;
  }
  return null;
}

IconData _rewardIconFor(RewardDefinition reward) => switch (reward) {
      XpReward() || BonusXpReward() => Icons.bolt_rounded,
      CosmeticReward() => Icons.card_giftcard_rounded,
      ChapterUnlockReward() => Icons.menu_book_rounded,
      CompanionAvailabilityReward() => Icons.groups_2_rounded,
      TitleReward() => Icons.workspace_premium_rounded,
      EmblemReward() => Icons.military_tech_rounded,
      RelicReward() => Icons.diamond_rounded,
    };

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
    final unlocked = view.lifecycle is AchievementUnlocked;
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
            if (view.node.rewards.isNotEmpty) ...[
              const SizedBox(height: 14),
              _AchievementRewardsSection(view: view, color: color, l10n: l10n),
            ],
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

class _AchievementRewardsSection extends StatelessWidget {
  const _AchievementRewardsSection({
    required this.view,
    required this.color,
    required this.l10n,
  });

  final EngineAchievementView view;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final unlocked = view.lifecycle is AchievementUnlocked;
    final xpAmount = unlocked
        ? view.previewXp
        : view.node.rewards
            .whereType<XpReward>()
            .fold<int>(0, (sum, r) => sum + r.amount);
    final nonXp = [
      for (final r in view.node.rewards)
        if (r is! XpReward && r is! BonusXpReward) r,
    ];
    if (xpAmount <= 0 && nonXp.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.progQuestDetailRewards,
          style: const TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w800,
            color: Tokens.onSurfaceMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: Tokens.spaceSm),
        if (xpAmount > 0) ...[
          _XpRewardChip(amount: xpAmount, color: color, unlocked: unlocked),
          if (nonXp.isNotEmpty) const SizedBox(height: 8),
        ],
        for (var i = 0; i < nonXp.length; i++) ...[
          _RewardCard(
            reward: nonXp[i],
            unlocked: unlocked,
            accent: color,
            l10n: l10n,
          ),
          if (i < nonXp.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _XpRewardChip extends StatelessWidget {
  const _XpRewardChip({
    required this.amount,
    required this.color,
    required this.unlocked,
  });

  final int amount;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final c = unlocked ? color : Tokens.onSurfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: c.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            '+$amount XP',
            style: TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w800,
              color: c,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.unlocked,
    required this.accent,
    required this.l10n,
  });

  final RewardDefinition reward;
  final bool unlocked;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cosmeticId = _cosmeticIdOf(reward);
    final definition =
        cosmeticId == null ? null : const CosmeticCatalog().byId(cosmeticId);
    final name = definition?.name(l10n) ?? _fallbackName(reward);
    final subtitleParts = <String>[
      _typeLabel(reward, definition, l10n),
      if (definition != null) definition.rarity.label(l10n),
    ];
    final subtitle = subtitleParts.where((s) => s.isNotEmpty).join(' · ');
    final color = unlocked ? accent : Tokens.onSurfaceMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showEngineRewardPreviewSheet(
        context,
        reward: reward,
        unlocked: unlocked,
        accent: accent,
        l10n: l10n,
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            if (cosmeticId != null)
              CosmeticAssetThumb(
                cosmeticId: cosmeticId,
                size: 48,
                borderRadius: 10,
                dimmed: !unlocked,
                fallbackColor: color,
                fallbackIcon: _fallbackIcon(reward),
                raceId: context.watch<CosmeticsProvider>().currentRaceId,
              )
            else
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.24)),
                ),
                child: Icon(_fallbackIcon(reward), size: 26, color: color),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeSmall,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Tokens.fontSizeMicro,
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  static String? _cosmeticIdOf(RewardDefinition r) => switch (r) {
        CosmeticReward(:final cosmeticId) => cosmeticId,
        EmblemReward(:final emblemId) => emblemId,
        TitleReward(:final titleId) => titleId,
        RelicReward(:final relicId) => relicId,
        CompanionAvailabilityReward(:final companionId) => companionId,
        _ => null,
      };

  static String _fallbackName(RewardDefinition r) => switch (r) {
        CosmeticReward(:final cosmeticId) => cosmeticId,
        EmblemReward(:final emblemId) => emblemId,
        TitleReward(:final titleId) => titleId,
        RelicReward(:final relicId) => relicId,
        CompanionAvailabilityReward(:final companionId) => companionId,
        ChapterUnlockReward(:final chapterId) => chapterId,
        XpReward() || BonusXpReward() => 'XP',
      };

  static IconData _fallbackIcon(RewardDefinition r) => switch (r) {
        XpReward() || BonusXpReward() => Icons.bolt_rounded,
        CosmeticReward() => Icons.card_giftcard_rounded,
        ChapterUnlockReward() => Icons.menu_book_rounded,
        CompanionAvailabilityReward() => Icons.groups_2_rounded,
        TitleReward() => Icons.workspace_premium_rounded,
        EmblemReward() => Icons.military_tech_rounded,
        RelicReward() => Icons.diamond_rounded,
      };

  static String _typeLabel(
    RewardDefinition r,
    Cosmetic? definition,
    AppLocalizations l10n,
  ) {
    if (definition != null) {
      return switch (definition.type) {
        CosmeticType.frame => l10n.cosmeticTypeFrame,
        CosmeticType.relic => l10n.cosmeticTypeRelic,
        CosmeticType.background => l10n.cosmeticTypeBackground,
        CosmeticType.emblem => l10n.cosmeticTypeEmblem,
        CosmeticType.companion => l10n.cosmeticTypeCompanion,
        CosmeticType.titleFlair => l10n.cosmeticTypeTitleFlair,
        CosmeticType.mapEffect => l10n.cosmeticTypeMapEffect,
        CosmeticType.skin => l10n.cosmeticTypeSkin,
      };
    }
    return switch (r) {
      XpReward() || BonusXpReward() => 'XP',
      CosmeticReward() => l10n.cosmeticTypeFrame,
      ChapterUnlockReward() => l10n.progQuestsChapterHeader,
      CompanionAvailabilityReward() => l10n.cosmeticTypeCompanion,
      TitleReward() => l10n.cosmeticTypeTitleFlair,
      EmblemReward() => l10n.cosmeticTypeEmblem,
      RelicReward() => l10n.cosmeticTypeRelic,
    };
  }
}

