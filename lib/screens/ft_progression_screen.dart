import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../features/progression/domain/progression_models.dart';
import '../features/social/application/social_provider.dart';
import '../features/progression/presentation/progression_l10n.dart';
import '../features/progression/presentation/progression_provider.dart';
import '../features/progression/presentation/widgets/ft_progression_domain_theme.dart';
import '../features/progression/presentation/widgets/ft_progression_primitives.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../theme/ft_design_tokens.dart';
import '../widgets/ft/ft_progress_bar.dart';
import '../widgets/ft/ft_xp_claim_pill.dart';
import '../widgets/ft/ft_xp_sparkle_overlay.dart';

class FtQuestsScreen extends StatefulWidget {
  const FtQuestsScreen({
    super.key,
    required this.barKey,
    required this.outerController,
    this.topContentInset = 0,
  });
  final GlobalKey barKey;
  final PageController outerController;
  final double topContentInset;

  @override
  State<FtQuestsScreen> createState() => _FtQuestsScreenState();
}

class _FtQuestsScreenState extends State<FtQuestsScreen> {
  final Map<String, GlobalKey> _rewardPillKeys = {};
  final Map<String, GlobalKey> _questPillKeys = {};

  GlobalKey _pillKeyFor(Map<String, GlobalKey> store, String id) =>
      store.putIfAbsent(id, () => GlobalKey(debugLabel: id));

  Offset? _centerOfKey(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) +
        Offset(box.size.width / 2, box.size.height / 2);
  }

  Future<void> _claimReward(
    ProgressionRewardGrant reward, {
    Offset? from,
  }) async {
    final origin =
        from ?? _centerOfKey(_pillKeyFor(_rewardPillKeys, reward.rewardKey));
    if (origin != null) {
      FtXpSparkleLauncher.launchToKey(
        context,
        from: origin,
        targetKey: widget.barKey,
      );
    }
    await context.read<ProgressionProvider>().claimReward(reward.rewardKey);
  }

  Future<void> _claimAllRewards(
    List<ProgressionRewardGrant> rewards, {
    required Offset fallbackFrom,
  }) async {
    final points = rewards
        .map((reward) =>
            _centerOfKey(_pillKeyFor(_rewardPillKeys, reward.rewardKey)))
        .whereType<Offset>()
        .toList(growable: false);
    FtXpSparkleLauncher.launchManyToKey(
      context,
      fromPoints: points.isEmpty ? [fallbackFrom] : points,
      targetKey: widget.barKey,
    );
    await context.read<ProgressionProvider>().claimAllRewards();
  }

  Future<void> _claimQuestReward(
    ProgressionQuest quest, {
    Offset? from,
  }) async {
    final rewardKey = quest.rewardKey;
    if (rewardKey == null) return;

    final origin = from ?? _centerOfKey(_pillKeyFor(_questPillKeys, rewardKey));
    if (origin != null) {
      FtXpSparkleLauncher.launchToKey(
        context,
        from: origin,
        targetKey: widget.barKey,
      );
    }
    await context.read<ProgressionProvider>().claimQuestReward(rewardKey);
  }

  Future<void> _claimAllQuestRewards(
    List<ProgressionQuest> quests, {
    required Offset fallbackFrom,
  }) async {
    final rewardKeys = quests
        .map((quest) => quest.rewardKey)
        .whereType<String>()
        .toList(growable: false);
    final points = rewardKeys
        .map(
            (rewardKey) => _centerOfKey(_pillKeyFor(_questPillKeys, rewardKey)))
        .whereType<Offset>()
        .toList(growable: false);
    FtXpSparkleLauncher.launchManyToKey(
      context,
      fromPoints: points.isEmpty ? [fallbackFrom] : points,
      targetKey: widget.barKey,
    );
    await context.read<ProgressionProvider>().claimAllQuestRewards();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);
    final progression = context.watch<ProgressionProvider>();
    final viewData = _ProgressionViewData.from(progression);

    for (final reward in viewData.pendingRewards) {
      _pillKeyFor(_rewardPillKeys, reward.rewardKey);
    }
    for (final quest in viewData.completedQuests) {
      final rewardKey = quest.rewardKey;
      if (rewardKey != null) {
        _pillKeyFor(_questPillKeys, rewardKey);
      }
    }

    if (progression.isLoading && progression.rewardGrants.isEmpty) {
      return _ProgressionScaffold(
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const _LoadingBlock(height: 180),
            const SizedBox(height: 12),
            const _LoadingBlock(height: 220),
            const SizedBox(height: 12),
            const _LoadingBlock(height: 140),
          ],
        ),
      );
    }

    return _ProgressionScaffold(
      child: Column(
        children: [
          if (progression.error != null)
            Padding(
              padding:
                  EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 0),
              child: _InlineErrorBanner(message: progression.error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: progression.refresh,
              color: FtTokens.accent,
              backgroundColor: FtTokens.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  14,
                  progression.error != null ? 16 : widget.topContentInset + 16,
                  14,
                  28,
                ),
                children: [
                  FtProgSectionHead(
                    label: l10n.progQuestsSectionLabel,
                    caption: l10n.progQuestsSectionCaption,
                    accent: FtTokens.steps.color,
                  ),
                  const SizedBox(height: 8),
                  _QuestsSection(
                    active: viewData.activeQuests,
                    locked: viewData.lockedQuests,
                    completed: viewData.completedQuests,
                    isRefreshing: progression.isRefreshing,
                    questPillKeys: _questPillKeys,
                    onClaimQuest: _claimQuestReward,
                    onClaimAllQuests: _claimAllQuestRewards,
                    l10n: l10n,
                    progL10n: progL10n,
                  ),
                  const SizedBox(height: 16),
                  FtProgSectionHead(
                    label: l10n.progRewardsPendingTitle,
                    caption: l10n.progRewardsPendingCaption,
                    accent: FtTokens.accent,
                  ),
                  const SizedBox(height: 8),
                  if (viewData.pendingRewards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        l10n.progRewardsEmptyTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: FtTokens.onSurfaceMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    _PendingRewardsSection(
                      pendingRewards: viewData.pendingRewards,
                      isRefreshing: progression.isRefreshing,
                      rewardPillKeys: _rewardPillKeys,
                      onClaimReward: _claimReward,
                      onClaimAllRewards: _claimAllRewards,
                    ),
                  const SizedBox(height: 16),
                  FtProgSectionHead(
                    label: l10n.progRewardsSectionLabel,
                    caption: l10n.progRewardsSectionCaption,
                    accent: FtTokens.calories.color,
                  ),
                  const SizedBox(height: 8),
                  _HistoryFeed(
                    grants: viewData.rewardHistory,
                    l10n: l10n,
                    progL10n: progL10n,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FtProgressionScreen extends StatefulWidget {
  const FtProgressionScreen({
    super.key,
    required this.barKey,
    required this.outerController,
    this.topContentInset = 0,
  });
  final GlobalKey barKey;
  final PageController outerController;
  final double topContentInset;

  @override
  State<FtProgressionScreen> createState() => _FtProgressionScreenState();
}

class _FtProgressionScreenState extends State<FtProgressionScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);
    final progression = context.watch<ProgressionProvider>();
    final viewData = _ProgressionViewData.from(progression);

    if (progression.isLoading && progression.rewardGrants.isEmpty) {
      return _ProgressionScaffold(
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const _LoadingBlock(height: 180),
            const SizedBox(height: 12),
            const _LoadingBlock(height: 140),
            const SizedBox(height: 12),
            const _LoadingBlock(height: 120),
          ],
        ),
      );
    }

    return _ProgressionScaffold(
      child: Column(
        children: [
          if (progression.error != null)
            Padding(
              padding:
                  EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 0),
              child: _InlineErrorBanner(message: progression.error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: progression.refresh,
              color: FtTokens.accent,
              backgroundColor: FtTokens.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  14,
                  progression.error != null ? 16 : widget.topContentInset + 16,
                  14,
                  28,
                ),
                children: [
                  FtProgSectionHead(
                    label: l10n.progSummarySectionLabel,
                    accent: FtTokens.accent,
                  ),
                  const SizedBox(height: 8),
                  _SummaryGrid(
                    items: [
                      _SummaryItem(
                        label: l10n.progSummaryCompletedQuests,
                        value: '${viewData.completedQuests.length}',
                        tone: FtTokens.steps.color,
                        icon: Icons.flag_rounded,
                      ),
                      _SummaryItem(
                        label: l10n.progSummaryAchievements,
                        value: '${viewData.unlocked.length}',
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
                  ),
                  const SizedBox(height: 16),
                  FtProgSectionHead(
                    label: l10n.progAchievementsSectionLabel,
                    caption: l10n.progAchievementsSectionCaption,
                    accent: FtTokens.accent,
                  ),
                  const SizedBox(height: 8),
                  _AchievementsSection(
                    unlocked: viewData.unlocked,
                    inProgress: viewData.inProgress,
                    l10n: l10n,
                    progL10n: progL10n,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRewardsSection extends StatelessWidget {
  const _PendingRewardsSection({
    required this.pendingRewards,
    required this.isRefreshing,
    required this.rewardPillKeys,
    required this.onClaimReward,
    required this.onClaimAllRewards,
  });

  final List<ProgressionRewardGrant> pendingRewards;
  final bool isRefreshing;
  final Map<String, GlobalKey> rewardPillKeys;
  final Future<void> Function(
    ProgressionRewardGrant reward, {
    Offset? from,
  }) onClaimReward;
  final Future<void> Function(
    List<ProgressionRewardGrant> rewards, {
    required Offset fallbackFrom,
  }) onClaimAllRewards;

  @override
  Widget build(BuildContext context) {
    if (pendingRewards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1A7C6FFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FtTokens.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.progRewardsPendingTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _ClaimAllButton(
                enabled: !isRefreshing,
                label: context.l10n.progRewardsClaimAll,
                onTap: (center) =>
                    onClaimAllRewards(pendingRewards, fallbackFrom: center),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.progRewardsPendingCaption,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: FtTokens.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < pendingRewards.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _PendingRewardCard(
              reward: pendingRewards[i],
              enabled: !isRefreshing,
              pillKey: rewardPillKeys[pendingRewards[i].rewardKey],
              onClaim: onClaimReward,
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimAllButton extends StatelessWidget {
  const _ClaimAllButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final void Function(Offset center) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              final box = context.findRenderObject() as RenderBox?;
              final center = box == null
                  ? Offset.zero
                  : box.localToGlobal(Offset.zero) +
                      Offset(box.size.width / 2, box.size.height / 2);
              onTap(center);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: enabled
              ? FtTokens.accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? FtTokens.accent.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: enabled ? FtTokens.accent : FtTokens.onSurfaceFaint,
          ),
        ),
      ),
    );
  }
}

class _PendingRewardCard extends StatelessWidget {
  const _PendingRewardCard({
    required this.reward,
    required this.enabled,
    required this.pillKey,
    required this.onClaim,
  });

  final ProgressionRewardGrant reward;
  final bool enabled;
  final GlobalKey? pillKey;
  final Future<void> Function(
    ProgressionRewardGrant reward, {
    Offset? from,
  }) onClaim;

  @override
  Widget build(BuildContext context) {
    final color = FtProgressionDomainTheme.colorFor(reward.domain);
    final locale = Localizations.localeOf(context).toString();
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FtProgDomIco(domain: reward.domain, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progL10n.ruleTitle(reward.ruleId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _rewardDetailText(reward, l10n),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FtTokens.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FtXpClaimPill(
                key: pillKey,
                data: FtXpClaimPillData.claimable(
                  reward.xpGranted,
                  onTap: enabled
                      ? (center) => onClaim(reward, from: center)
                      : (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.progRewardsUnlockedAt(
                    _formatDateTime(reward.unlockedAt, locale),
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.82),
                  ),
                ),
              ),
              if (!enabled)
                Text(
                  l10n.progRewardsClaim,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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
        childAspectRatio: 2.4,
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

class _SummaryItem {
  const _SummaryItem({
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

class _QuestsSection extends StatefulWidget {
  const _QuestsSection({
    required this.active,
    required this.locked,
    required this.completed,
    required this.isRefreshing,
    required this.questPillKeys,
    required this.onClaimQuest,
    required this.onClaimAllQuests,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionQuest> active;
  final List<ProgressionQuest> locked;
  final List<ProgressionQuest> completed;
  final bool isRefreshing;
  final Map<String, GlobalKey> questPillKeys;
  final Future<void> Function(
    ProgressionQuest quest, {
    Offset? from,
  }) onClaimQuest;
  final Future<void> Function(
    List<ProgressionQuest> quests, {
    required Offset fallbackFrom,
  }) onClaimAllQuests;
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
    final claimableCompleted = widget.completed
        .where((quest) => quest.isRewardClaimable)
        .toList(growable: false);

    return Column(
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
        const SizedBox(height: 20),
        _SubHeader(
          label: widget.l10n.progQuestsLockedHeader,
          color: FtTokens.onSurfaceMuted,
        ),
        const SizedBox(height: 10),
        if (widget.locked.isEmpty)
          _EmptyLine(
            title: widget.l10n.progQuestsEmptyLockedTitle,
            caption: widget.l10n.progQuestsEmptyLockedCaption,
          )
        else
          for (int i = 0; i < widget.locked.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _LockedQuestRow(
              quest: widget.locked[i],
              progL10n: widget.progL10n,
            ),
          ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _SubHeader(
                label: widget.l10n.progQuestsCompletedHeader,
                color: FtTokens.onSurfaceMuted,
              ),
            ),
            if (claimableCompleted.isNotEmpty)
              _ClaimAllButton(
                enabled: !widget.isRefreshing,
                label: widget.l10n.progQuestClaimAll,
                onTap: (center) => widget.onClaimAllQuests(
                  claimableCompleted,
                  fallbackFrom: center,
                ),
              ),
          ],
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
              enabled: !widget.isRefreshing,
              pillKey: completedToShow[i].rewardKey == null
                  ? null
                  : widget.questPillKeys[completedToShow[i].rewardKey!],
              onClaimQuest: widget.onClaimQuest,
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
        boxShadow: [
          BoxShadow(
              color: token.glow, blurRadius: 16, offset: const Offset(0, 3))
        ],
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
              _QuestRewardPill(quest: quest),
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
                l10n.progPercent(_safePercent(quest.progress)),
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

class _LockedQuestRow extends StatelessWidget {
  const _LockedQuestRow({
    required this.quest,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = FtProgressionDomainTheme.resolveForQuest(quest);
    return Opacity(
      opacity: 0.82,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
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
                    progL10n.questDescription(quest),
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
            ),
            const SizedBox(width: 8),
            _QuestRewardPill(quest: quest),
          ],
        ),
      ),
    );
  }
}

class _CompletedQuestRow extends StatelessWidget {
  const _CompletedQuestRow({
    required this.quest,
    required this.l10n,
    required this.progL10n,
    required this.enabled,
    required this.pillKey,
    required this.onClaimQuest,
  });

  final ProgressionQuest quest;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;
  final bool enabled;
  final GlobalKey? pillKey;
  final Future<void> Function(
    ProgressionQuest quest, {
    Offset? from,
  }) onClaimQuest;

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
          _QuestRewardPill(
            key: pillKey,
            quest: quest,
            claimedLabel: l10n.progQuestStatusClaimed,
            onClaim:
                enabled ? (center) => onClaimQuest(quest, from: center) : null,
          ),
        ],
      ),
    );
  }
}

class _QuestRewardPill extends StatelessWidget {
  const _QuestRewardPill({
    super.key,
    required this.quest,
    this.claimedLabel,
    this.onClaim,
  });

  final ProgressionQuest quest;
  final String? claimedLabel;
  final void Function(Offset center)? onClaim;

  @override
  Widget build(BuildContext context) {
    final data = quest.isRewardClaimed
        ? FtXpClaimPillData.claimed(quest.rewardXp)
        : quest.isRewardClaimable
            ? FtXpClaimPillData.claimable(
                quest.rewardXp,
                onTap: onClaim ?? (_) {},
              )
            : FtXpClaimPillData.locked(quest.rewardXp);

    return FtXpClaimPill(
      data: data,
      claimedLabel: claimedLabel,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    final achievements = [...unlocked, ...inProgress];
    if (achievements.isEmpty) {
      return _EmptyLine(
        title: l10n.progAchievementsEmptyUnlockedTitle,
        caption: l10n.progAchievementsEmptyUnlockedCaption,
      );
    }
    return _AchievementBadgeGrid(
      achievements: achievements,
      l10n: l10n,
      progL10n: progL10n,
    );
  }
}

class _AchievementBadgeGrid extends StatelessWidget {
  const _AchievementBadgeGrid({
    required this.achievements,
    required this.l10n,
    required this.progL10n,
  });

  final List<ProgressionAchievement> achievements;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 620 ? 4 : 3;
        final aspectRatio = width >= 620 ? 0.98 : 0.9;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) => _AchievementTile(
            achievement: achievements[index],
            l10n: l10n,
            progL10n: progL10n,
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
    required this.progL10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final achievement = this.achievement;
    final badge = _achievementBadgeSpec(achievement);
    final color = badge.color;
    final unlocked = achievement.unlocked;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAchievementDetailsSheet(
        context,
        achievement: achievement,
        l10n: l10n,
        progL10n: progL10n,
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.45,
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
            borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(fontSize: 22),
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
                    fontSize: FtTokens.fontSizeTiny,
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
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class _AchievementDetailsSheet extends StatefulWidget {
  const _AchievementDetailsSheet({
    required this.achievement,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionAchievement achievement;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  State<_AchievementDetailsSheet> createState() =>
      _AchievementDetailsSheetState();
}

class _AchievementDetailsSheetState extends State<_AchievementDetailsSheet> {
  bool _sharing = false;
  bool _shared = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    final social = context.read<SocialProvider>();
    await social.shareAchievement(widget.achievement.id);
    if (!mounted) return;
    setState(() {
      _sharing = false;
      _shared = social.error == null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: FtTokens.surface,
        content: Text(
          social.error == null
              ? 'Achievement sdílen do feedu přátel.'
              : 'Chyba: ${social.error}',
          style: const TextStyle(color: FtTokens.onSurface),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final l10n = widget.l10n;
    final progL10n = widget.progL10n;
    final badge = _achievementBadgeSpec(achievement);
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
      progL10n,
      locale,
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: FtTokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AchievementEmojiBadge(
                  emoji: badge.emoji,
                  color: color,
                  unlocked: unlocked,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progL10n.achievementTitle(achievement),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FtProgTinyPill(
                  label: unlocked
                      ? l10n.progAchievementStatusUnlocked
                      : l10n.progAchievementStatusInProgress,
                  color: unlocked ? color : FtTokens.onSurfaceMuted,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              progL10n.achievementDescription(achievement),
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: FtTokens.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FtProgTinyPill(
                  label: _achievementDifficultyLabel(achievement, l10n),
                  color: color,
                ),
                FtProgTinyPill(
                  label: progressLabel,
                  color: color,
                ),
                if (achievement.ruleId != null)
                  FtProgTinyPill(
                    label: progL10n.ruleTitle(achievement.ruleId!),
                    color: color.withValues(alpha: 0.88),
                  )
                else if (achievement.domain != null)
                  FtProgTinyPill(
                    label: progL10n.domainLabel(achievement.domain!),
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FtProgressBar(
                    value: unlocked ? 1 : achievement.progress,
                    color: color,
                    glow: color.withValues(alpha: 0.35),
                    height: 4,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    progressLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (unlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.progQuestCompletedOn(
                        _formatDateTime(achievement.unlockedAt!, locale),
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
                      color: _shared
                          ? Colors.white.withValues(alpha: 0.05)
                          : null,
                      borderRadius: BorderRadius.circular(14),
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
                            _shared
                                ? Icons.check_rounded
                                : Icons.share_rounded,
                            size: 16,
                            color: _shared
                                ? FtTokens.onSurfaceMuted
                                : color,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _shared
                              ? 'Sdíleno'
                              : _sharing
                                  ? 'Sdílení...'
                                  : 'Sdílet do feedu přátel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _shared
                                ? FtTokens.onSurfaceMuted
                                : color,
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

void _showAchievementDetailsSheet(
  BuildContext context, {
  required ProgressionAchievement achievement,
  required AppLocalizations l10n,
  required ProgressionL10n progL10n,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _AchievementDetailsSheet(
      achievement: achievement,
      l10n: l10n,
      progL10n: progL10n,
    ),
  );
}

@immutable
class _AchievementBadgeSpec {
  const _AchievementBadgeSpec({
    required this.emoji,
    required this.color,
  });

  final String emoji;
  final Color color;
}

_AchievementBadgeSpec _achievementBadgeSpec(
    ProgressionAchievement achievement) {
  final color = FtProgressionDomainTheme.colorForAchievementDifficulty(
    achievement.difficulty,
  );
  final levelTarget = _achievementLevelTarget(achievement);
  if (levelTarget != null) {
    switch (levelTarget) {
      case 5:
      case 10:
        return _AchievementBadgeSpec(emoji: '🧭', color: color);
      case 15:
        return _AchievementBadgeSpec(emoji: '⚒️', color: color);
      case 20:
        return _AchievementBadgeSpec(emoji: '🛡️', color: color);
      case 25:
        return _AchievementBadgeSpec(emoji: '🌩️', color: color);
      case 30:
        return _AchievementBadgeSpec(emoji: '🌅', color: color);
      case 40:
        return _AchievementBadgeSpec(emoji: '🌀', color: color);
      default:
        return _AchievementBadgeSpec(emoji: '👑', color: color);
    }
  }
  switch (achievement.id) {
    case 'first_reward':
      return _AchievementBadgeSpec(
        emoji: '🏆',
        color: color,
      );
    case 'reward_hunter_25':
    case 'reward_hunter_100':
      return _AchievementBadgeSpec(
        emoji: '⚔️',
        color: color,
      );
    case 'xp_100000':
    case 'xp_1000000':
      return _AchievementBadgeSpec(
        emoji: '🔥',
        color: color,
      );
    case 'steps_total_100k':
    case 'steps_total_500k':
    case 'steps_total_1000000':
    case 'steps_total_5000000':
    case 'steps_total_10000000':
    case 'steps_month_300k':
    case 'steps_month_600k':
      return _AchievementBadgeSpec(
        emoji: '🛡️',
        color: color,
      );
    case 'nutrition_rewards_25':
    case 'sleep_total_250h':
    case 'sleep_total_1000h':
    case 'sleep_month_225h':
    case 'sleep_month_240h':
      return _AchievementBadgeSpec(
        emoji: '💎',
        color: color,
      );
    case 'steps_streak_30':
    case 'steps_streak_100':
      return _AchievementBadgeSpec(
        emoji: '👑',
        color: color,
      );
    case 'steps_streak_3':
    case 'steps_streak_7':
      return _AchievementBadgeSpec(
        emoji: '🔥',
        color: color,
      );
    case 'weekly_activity_mastery':
    case 'weekly_activity_4':
    case 'weekly_activity_12':
    case 'weekly_activity_24':
    case 'weekly_activity_52':
      return _AchievementBadgeSpec(
        emoji: '⚡',
        color: color,
      );
    case 'nutrition_streak_3':
    case 'nutrition_streak_30':
    case 'nutrition_streak_100':
      return _AchievementBadgeSpec(
        emoji: '🥗',
        color: color,
      );
    default:
      return _AchievementBadgeSpec(
        emoji: '🏅',
        color: color,
      );
  }
}

String _achievementDisplayLabel(
  ProgressionAchievement achievement,
  BuildContext context,
) {
  final isCzech = Localizations.localeOf(context).languageCode == 'cs';
  final levelTarget = _achievementLevelTarget(achievement);
  if (levelTarget != null) {
    return 'LEVEL $levelTarget';
  }
  switch (achievement.id) {
    case 'first_reward':
      return isCzech ? 'PRVNÍ ODMĚNA' : 'FIRST REWARD';
    case 'reward_hunter_25':
      return isCzech ? '25 ODMĚN' : '25 REWARDS';
    case 'reward_hunter_100':
      return isCzech ? '100 ODMĚN' : '100 REWARDS';
    case 'xp_100000':
      return '100K XP';
    case 'xp_1000000':
      return '1M XP';
    case 'steps_total_100k':
      return isCzech ? '100K KROKŮ' : '100K STEPS';
    case 'steps_total_500k':
      return isCzech ? '500K KROKŮ' : '500K STEPS';
    case 'steps_total_1000000':
      return isCzech ? '1M KROKŮ' : '1M STEPS';
    case 'steps_total_5000000':
      return isCzech ? '5M KROKŮ' : '5M STEPS';
    case 'steps_total_10000000':
      return isCzech ? '10M KROKŮ' : '10M STEPS';
    case 'steps_month_300k':
      return isCzech ? '300K / 30 DNÍ' : '300K / 30 DAYS';
    case 'steps_month_600k':
      return isCzech ? '600K / 30 DNÍ' : '600K / 30 DAYS';
    case 'steps_streak_3':
      return isCzech ? '3 DNY' : '3-DAY STREAK';
    case 'steps_streak_7':
      return isCzech ? '7 DNÍ' : '7-DAY STREAK';
    case 'steps_streak_30':
      return isCzech ? '30 DNÍ' : '30-DAY STREAK';
    case 'steps_streak_100':
      return isCzech ? '100 DNÍ' : '100-DAY STREAK';
    case 'nutrition_streak_3':
      return isCzech ? '3 DNY VÝŽIVY' : '3-DAY FUEL';
    case 'nutrition_streak_30':
      return isCzech ? '30 DNÍ VÝŽIVY' : '30-DAY NUTRITION';
    case 'nutrition_streak_100':
      return isCzech ? '100 DNÍ VÝŽIVY' : '100-DAY NUTRITION';
    case 'nutrition_rewards_25':
      return isCzech ? '25 ODMĚN VÝŽIVY' : '25 FOOD WINS';
    case 'weekly_activity_mastery':
      return isCzech ? 'TÝDENNÍ WIN' : 'WEEKLY WIN';
    case 'weekly_activity_4':
      return isCzech ? '4 TÝDNY' : '4 WEEK WINS';
    case 'weekly_activity_12':
      return isCzech ? '12 TÝDNŮ' : '12 WEEK WINS';
    case 'weekly_activity_24':
      return isCzech ? '24 TÝDNŮ' : '24 WEEK WINS';
    case 'weekly_activity_52':
      return isCzech ? '52 TÝDNŮ' : '52 WEEK WINS';
    case 'sleep_total_250h':
      return isCzech ? '250 H SPÁNKU' : '250H SLEEP';
    case 'sleep_total_1000h':
      return isCzech ? '1000 H SPÁNKU' : '1000H SLEEP';
    case 'sleep_month_225h':
      return isCzech ? '225 H / 30 DNÍ' : '225H / 30 DAYS';
    case 'sleep_month_240h':
      return isCzech ? '240 H / 30 DNÍ' : '240H / 30 DAYS';
    default:
      return ProgressionL10n(context.l10n)
          .achievementTitle(achievement)
          .toUpperCase();
  }
}

int _achievementDifficultyRank(ProgressionAchievementDifficulty difficulty) {
  switch (difficulty) {
    case ProgressionAchievementDifficulty.easy:
      return 0;
    case ProgressionAchievementDifficulty.medium:
      return 1;
    case ProgressionAchievementDifficulty.hard:
      return 2;
    case ProgressionAchievementDifficulty.extraHard:
      return 3;
  }
}

String _achievementDifficultyLabel(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
) {
  switch (achievement.difficulty) {
    case ProgressionAchievementDifficulty.easy:
      return l10n.progAchievementDifficultyEasy;
    case ProgressionAchievementDifficulty.medium:
      return l10n.progAchievementDifficultyMedium;
    case ProgressionAchievementDifficulty.hard:
      return l10n.progAchievementDifficultyHard;
    case ProgressionAchievementDifficulty.extraHard:
      return l10n.progAchievementDifficultyExtraHard;
  }
}

int? _achievementLevelTarget(ProgressionAchievement achievement) {
  final match = RegExp(r'_level_(\d+)$').firstMatch(achievement.id);
  return match == null ? null : int.tryParse(match.group(1)!);
}

String _achievementCompactSummary(
  ProgressionAchievement achievement,
  AppLocalizations l10n,
  ProgressionL10n progL10n,
  String locale,
) {
  switch (achievement.criterionType) {
    case ProgressionAchievementCriterionType.totalXpAtLeast:
      final levelTarget = _achievementLevelTarget(achievement);
      if (levelTarget != null) {
        return 'LEVEL $levelTarget';
      }
      return '${_formatCompactInt(achievement.targetValue, locale)} XP';
    case ProgressionAchievementCriterionType.rewardCountAtLeast:
      if (achievement.ruleId != null) {
        return '${achievement.targetValue}x ${progL10n.ruleTitle(achievement.ruleId!)}';
      }
      if (achievement.domain != null) {
        return '${achievement.targetValue}x ${progL10n.domainLabel(achievement.domain!)}';
      }
      return '${achievement.targetValue} ${l10n.progRewardsSectionLabel}';
    case ProgressionAchievementCriterionType.bestStreakAtLeast:
      return '${achievement.targetValue} ${l10n.progStreakDaysSuffix}';
    case ProgressionAchievementCriterionType.totalRuleValueAtLeast:
    case ProgressionAchievementCriterionType.bestRollingWindowRuleValueAtLeast:
      return _achievementTargetSummary(achievement, l10n, locale);
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
  final unit = _achievementUnitForRule(achievement.ruleId, l10n);
  return '${_formatCompactInt(achievement.targetValue, locale)} $unit';
}

String _achievementUnitForRule(String? ruleId, AppLocalizations l10n) {
  switch (ruleId) {
    case 'daily_steps':
      return l10n.goalUnitSteps;
    case 'daily_calories':
      return l10n.goalUnitKcal;
    case 'daily_protein':
      return l10n.goalUnitG;
    case 'daily_sleep':
      return l10n.goalUnitHours;
    case 'weekly_activity':
      return l10n.goalUnitMins;
    default:
      return '';
  }
}

String _formatCompactInt(int value, String locale) {
  return NumberFormat.compact(locale: locale).format(value);
}

String _formatFullInt(int value, String locale) {
  return NumberFormat.decimalPattern(locale).format(value);
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
    final xpLabel = _formatFullInt(grant.xpGranted, locale);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    '+$xpLabel XP',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA89BFF),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _formatDateTime(
                        grant.claimedAt ?? grant.unlockedAt, locale),
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
          const SizedBox(height: 6),
          Text(
            _rewardDetailText(grant, context.l10n),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: FtTokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _rewardDetailText(
  ProgressionRewardGrant reward,
  AppLocalizations l10n,
) {
  final unit = _rewardUnit(reward.ruleId, l10n);
  final target = _formatRewardMetric(reward.ruleId, reward.targetValue);
  final actual = _formatRewardMetric(reward.ruleId, reward.actualValue);
  return l10n.progRewardDetail(target, unit, actual);
}

String _formatRewardMetric(String ruleId, double value) {
  final safe = (value.isNaN || value.isInfinite) ? 0.0 : value;
  switch (ruleId) {
    case 'daily_steps':
    case 'daily_sleep':
    case 'weekly_activity':
      return safe.round().toString();
    case 'daily_calories':
    case 'daily_protein':
      return safe.toStringAsFixed(safe.truncateToDouble() == safe ? 0 : 1);
    default:
      return safe.toStringAsFixed(safe.truncateToDouble() == safe ? 0 : 1);
  }
}

String _rewardUnit(String ruleId, AppLocalizations l10n) {
  switch (ruleId) {
    case 'daily_steps':
      return l10n.goalUnitSteps;
    case 'daily_calories':
      return l10n.goalUnitKcal;
    case 'daily_protein':
      return l10n.goalUnitG;
    case 'daily_sleep':
    case 'weekly_activity':
      return l10n.goalUnitMins;
    default:
      return '';
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

class _ProgressionViewData {
  const _ProgressionViewData({
    required this.profile,
    required this.xpSpan,
    required this.unlocked,
    required this.inProgress,
    required this.activeQuests,
    required this.lockedQuests,
    required this.completedQuests,
    required this.pendingRewards,
    required this.rewardHistory,
    required this.current,
    required this.best,
  });

  factory _ProgressionViewData.from(ProgressionProvider progression) {
    final profile = progression.profile;
    final unlocked = progression.achievements
        .where((a) => a.unlocked)
        .toList(growable: false)
      ..sort((a, b) {
        final difficulty = _achievementDifficultyRank(b.difficulty)
            .compareTo(_achievementDifficultyRank(a.difficulty));
        if (difficulty != 0) return difficulty;
        final at = a.unlockedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.unlockedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final inProgress = progression.achievements
        .where((a) => !a.unlocked)
        .toList(growable: false)
      ..sort((a, b) {
        final difficulty = _achievementDifficultyRank(b.difficulty)
            .compareTo(_achievementDifficultyRank(a.difficulty));
        if (difficulty != 0) return difficulty;
        return b.progress.compareTo(a.progress);
      });
    final activeQuests = [...progression.activeQuests]
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final lockedQuests = [...progression.lockedQuests]..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) return byPriority;
        final bySortOrder = a.sortOrder.compareTo(b.sortOrder);
        if (bySortOrder != 0) return bySortOrder;
        return a.id.compareTo(b.id);
      });
    final completedQuests = [...progression.completedQuests]..sort((a, b) {
        if (a.isRewardClaimable != b.isRewardClaimable) {
          return a.isRewardClaimable ? -1 : 1;
        }
        final at = a.completedAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.completedAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final pendingRewards = [...progression.pendingRewards]
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final rewardHistory = [...progression.claimedRewards]..sort((a, b) {
        final aTime = a.claimedAt ?? a.unlockedAt;
        final bTime = b.claimedAt ?? b.unlockedAt;
        return bTime.compareTo(aTime);
      });

    return _ProgressionViewData(
      profile: profile,
      xpSpan: (profile.nextLevelXp - profile.levelFloorXp).clamp(1, 1 << 30),
      unlocked: unlocked,
      inProgress: inProgress,
      activeQuests: activeQuests,
      lockedQuests: lockedQuests,
      completedQuests: completedQuests,
      pendingRewards: pendingRewards,
      rewardHistory: rewardHistory,
      current: _topStreak(progression, best: false),
      best: _topStreak(progression, best: true),
    );
  }

  final ProgressionProfile profile;
  final int xpSpan;
  final List<ProgressionAchievement> unlocked;
  final List<ProgressionAchievement> inProgress;
  final List<ProgressionQuest> activeQuests;
  final List<ProgressionQuest> lockedQuests;
  final List<ProgressionQuest> completedQuests;
  final List<ProgressionRewardGrant> pendingRewards;
  final List<ProgressionRewardGrant> rewardHistory;
  final _DomainStreak? current;
  final _DomainStreak? best;
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

int _safePercent(double progress) {
  final pct = progress * 100;
  if (pct.isNaN || pct.isInfinite) return 0;
  return pct.clamp(0, 100).round();
}

String _formatDateTime(DateTime value, String locale) {
  return DateFormat('d MMM · HH:mm', locale).format(value);
}
