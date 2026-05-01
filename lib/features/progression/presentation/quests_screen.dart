import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/progression_models.dart';
import '../domain/progression_level_policy.dart';
import '../application/progression_provider.dart';
import 'progression_l10n.dart';
import 'quest_detail_view_model.dart';
import 'widgets/progression_domain_theme.dart';
import 'widgets/progression_primitives.dart';
import 'widgets/progression_internals.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/ft_expand_chevron.dart';
import '../../../shared/widgets/tiny_pill.dart';
import '../../../shared/widgets/xp_claim_pill.dart';
import '../../../shared/widgets/xp_sparkle_overlay.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({
    super.key,
    required this.barKey,
    required this.outerController,
    this.topContentInset = 0,
  });
  final GlobalKey barKey;
  final PageController outerController;
  final double topContentInset;

  @override
  State<QuestsScreen> createState() => _FtQuestsScreenState();
}

class _FtQuestsScreenState extends State<QuestsScreen> {
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
      XpSparkleLauncher.launchToKey(
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
    XpSparkleLauncher.launchManyToKey(
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
      XpSparkleLauncher.launchToKey(
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
    XpSparkleLauncher.launchManyToKey(
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
    final viewData = ProgressionViewData.from(progression);

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
      return ProgressionScaffold(
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const ProgressionLoadingBlock(height: 180),
            const SizedBox(height: Tokens.spaceMd),
            const ProgressionLoadingBlock(height: 220),
            const SizedBox(height: Tokens.spaceMd),
            const ProgressionLoadingBlock(height: 140),
          ],
        ),
      );
    }

    return ProgressionScaffold(
      child: Column(
        children: [
          if (progression.error != null)
            Padding(
              padding:
                  EdgeInsets.fromLTRB(14, widget.topContentInset + 8, 14, 0),
              child: ProgressionErrorBanner(message: progression.error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: progression.refresh,
              color: Tokens.accent,
              backgroundColor: Tokens.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  14,
                  progression.error != null ? 16 : widget.topContentInset + 16,
                  14,
                  28,
                ),
                children: [
                  ProgSectionHead(
                    label: l10n.progQuestsSectionLabel,
                    caption: l10n.progQuestsSectionCaption,
                    accent: Tokens.steps.color,
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  _QuestsSection(
                    active: viewData.activeQuests,
                    locked: viewData.lockedQuests,
                    completed: viewData.completedQuests,
                    allQuests: viewData.allQuests,
                    profile: viewData.profile,
                    trackedDaysElapsed: viewData.trackedDaysElapsed,
                    isRefreshing: progression.isRefreshing,
                    questPillKeys: _questPillKeys,
                    onClaimQuest: _claimQuestReward,
                    onClaimAllQuests: _claimAllQuestRewards,
                    l10n: l10n,
                    progL10n: progL10n,
                  ),
                  const SizedBox(height: Tokens.spaceLg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ProgSectionHead(
                          label: l10n.progRewardsPendingTitle,
                          accent: Tokens.accent,
                        ),
                      ),
                      if (viewData.pendingRewards.isNotEmpty)
                        _ClaimAllButton(
                          enabled: !progression.isRefreshing,
                          label: l10n.progRewardsClaimAll,
                          color: const Color(0xFFFFBD2E),
                          onTap: (center) => _claimAllRewards(
                            viewData.pendingRewards,
                            fallbackFrom: center,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  if (viewData.pendingRewards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        l10n.progRewardsEmptyTitle,
                        style: const TextStyle(
                          fontSize: Tokens.fontSizeSmall,
                          color: Tokens.onSurfaceMuted,
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
                  const SizedBox(height: Tokens.spaceLg),
                  ProgSectionHead(
                    label: l10n.progRewardsSectionLabel,
                    caption: l10n.progRewardsSectionCaption,
                    accent: Tokens.calories.color,
                  ),
                  const SizedBox(height: Tokens.spaceSm),
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

// ── Pending rewards ───────────────────────────────────────────────────────────

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < pendingRewards.length; i++) ...[
          if (i > 0) const SizedBox(height: Tokens.spaceSm),
          _PendingRewardCard(
            reward: pendingRewards[i],
            enabled: !isRefreshing,
            pillKey: rewardPillKeys[pendingRewards[i].rewardKey],
            onClaim: onClaimReward,
          ),
        ],
      ],
    );
  }
}

class _ClaimAllButton extends StatelessWidget {
  const _ClaimAllButton({
    required this.enabled,
    required this.label,
    required this.onTap,
    this.color,
  });

  final bool enabled;
  final String label;
  final void Function(Offset center) onTap;
  final Color? color;

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
              ? (color ?? Tokens.accent).withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Tokens.radiusIcon),
          border: Border.all(
            color: enabled
                ? (color ?? Tokens.accent).withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color:
                enabled ? (color ?? Tokens.accent) : Tokens.onSurfaceFaint,
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
    final color = ProgressionDomainTheme.colorFor(reward.domain);
    final locale = Localizations.localeOf(context).toString();
    final l10n = context.l10n;
    final progL10n = ProgressionL10n(l10n);
    final progression = context.watch<ProgressionProvider>();
    final displayXp = _computeDisplayXp(reward, progression.profile);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgDomIco(domain: reward.domain, size: 28),
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
                        fontSize: Tokens.fontSizeMicro,
                        fontWeight: FontWeight.w600,
                        color: Tokens.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Tokens.spaceSm),
              XpClaimPill(
                key: pillKey,
                data: XpClaimPillData.claimable(
                  displayXp,
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
                    progressionFormatDateTime(reward.unlockedAt, locale),
                  ),
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.82),
                  ),
                ),
              ),
              if (!enabled)
                Text(
                  l10n.progRewardsClaim,
                  style: const TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w800,
                    color: Tokens.onSurfaceFaint,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  int _computeDisplayXp(
      ProgressionRewardGrant grant, ProgressionProfile profile) {
    if (grant.isClaimed) {
      return grant.effectiveXpGranted;
    }
    final levelPolicy = ProgressionLevelPolicy();
    final baseXp = grant.baseXp ?? grant.xpGranted;
    return levelPolicy.scaledRewardXp(baseXp: baseXp, level: profile.level);
  }
}

// ── Quests section ────────────────────────────────────────────────────────────

class _QuestsSection extends StatefulWidget {
  const _QuestsSection({
    required this.active,
    required this.locked,
    required this.completed,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
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
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
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
  String? _expandedQuestId;

  void _toggleQuest(String questId) {
    setState(() {
      _expandedQuestId = _expandedQuestId == questId ? null : questId;
    });
  }

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
          color: Tokens.active.color,
        ),
        const SizedBox(height: 10),
        if (widget.active.isEmpty)
          ProgressionEmptyLine(
            title: widget.l10n.progQuestsEmptyActiveTitle,
            caption: widget.l10n.progQuestsEmptyActiveCaption,
          )
        else
          for (int i = 0; i < widget.active.length; i++) ...[
            if (i > 0) const SizedBox(height: Tokens.spaceSm),
            _ActiveQuestCard(
              quest: widget.active[i],
              allQuests: widget.allQuests,
              profile: widget.profile,
              trackedDaysElapsed: widget.trackedDaysElapsed,
              isExpanded: _expandedQuestId == widget.active[i].id,
              onToggle: () => _toggleQuest(widget.active[i].id),
              l10n: widget.l10n,
              progL10n: widget.progL10n,
            ),
          ],
        const SizedBox(height: Tokens.spaceXl),
        _SubHeader(
          label: widget.l10n.progQuestsLockedHeader,
          color: Tokens.onSurfaceMuted,
        ),
        const SizedBox(height: 10),
        if (widget.locked.isEmpty)
          ProgressionEmptyLine(
            title: widget.l10n.progQuestsEmptyLockedTitle,
            caption: widget.l10n.progQuestsEmptyLockedCaption,
          )
        else
          for (int i = 0; i < widget.locked.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _LockedQuestRow(
              quest: widget.locked[i],
              allQuests: widget.allQuests,
              profile: widget.profile,
              trackedDaysElapsed: widget.trackedDaysElapsed,
              isExpanded: _expandedQuestId == widget.locked[i].id,
              onToggle: () => _toggleQuest(widget.locked[i].id),
              l10n: widget.l10n,
              progL10n: widget.progL10n,
            ),
          ],
        const SizedBox(height: Tokens.spaceXl),
        Row(
          children: [
            Expanded(
              child: _SubHeader(
                label: widget.l10n.progQuestsCompletedHeader,
                color: Tokens.onSurfaceMuted,
              ),
            ),
            if (claimableCompleted.isNotEmpty)
              _ClaimAllButton(
                enabled: !widget.isRefreshing,
                label: widget.l10n.progQuestClaimAll,
                color: const Color(0xFFFFBD2E),
                onTap: (center) => widget.onClaimAllQuests(
                  claimableCompleted,
                  fallbackFrom: center,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.completed.isEmpty)
          ProgressionEmptyLine(
            title: widget.l10n.progQuestsEmptyCompletedTitle,
            caption: widget.l10n.progQuestsEmptyCompletedCaption,
          )
        else
          for (int i = 0; i < completedToShow.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _CompletedQuestRow(
              quest: completedToShow[i],
              allQuests: widget.allQuests,
              profile: widget.profile,
              trackedDaysElapsed: widget.trackedDaysElapsed,
              isExpanded: _expandedQuestId == completedToShow[i].id,
              onToggle: () => _toggleQuest(completedToShow[i].id),
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
          const SizedBox(height: Tokens.spaceSm),
          GestureDetector(
            onTap: () => setState(() => _showAllCompleted = true),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                widget.l10n.progShowAllCount(widget.completed.length),
                style: const TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w700,
                  color: Tokens.accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Quest cards ───────────────────────────────────────────────────────────────

class _ActiveQuestCard extends StatelessWidget {
  const _ActiveQuestCard({
    required this.quest,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = ProgressionDomainTheme.resolveForQuest(quest);
    final token = ProgressionDomainTheme.tokenFor(domain);
    final color = token.color;
    final descriptor = progL10n.questCriterionDescriptor(quest);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: token.gradient,
          borderRadius: BorderRadius.circular(Tokens.radiusTile),
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
                ProgDomIco(domain: domain, size: 30),
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
                          fontSize: Tokens.fontSizeBody,
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
                          fontSize: Tokens.fontSizeCaption,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                _QuestRewardPill(quest: quest),
                const SizedBox(width: 6),
                ExpandChevron(
                  expanded: isExpanded,
                  color: color.withValues(alpha: 0.82),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ProgressBar(
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
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  isExpanded
                      ? l10n.progPercent(_safePercent(quest.progress))
                      : l10n.progQuestDetailTapForDetails,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeCaption,
                    fontWeight: FontWeight.w700,
                    color: isExpanded ? color : Tokens.onSurfaceFaint,
                  ),
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: Tokens.spaceMd),
              _QuestDetailPanel(
                quest: quest,
                allQuests: allQuests,
                profile: profile,
                trackedDaysElapsed: trackedDaysElapsed,
                l10n: l10n,
                progL10n: progL10n,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LockedQuestRow extends StatelessWidget {
  const _LockedQuestRow({
    required this.quest,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = ProgressionDomainTheme.resolveForQuest(quest);
    final detail = QuestDetailViewModel.build(
      quest: quest,
      allQuests: allQuests,
      profile: profile,
      trackedDaysElapsed: trackedDaysElapsed,
    );
    final color = ProgressionDomainTheme.colorFor(domain);
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.016),
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProgDomIco(domain: domain, size: 26),
                      const Positioned(
                        right: -3,
                        bottom: -3,
                        child: Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: Tokens.onSurfaceFaint,
                        ),
                      ),
                    ],
                  ),
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
                            fontSize: Tokens.fontSizeSmall,
                            fontWeight: FontWeight.w700,
                            color: Tokens.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _primaryUnlockReasonText(
                            detail,
                            allQuests,
                            l10n,
                            progL10n,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: Tokens.fontSizeMicro,
                            fontWeight: FontWeight.w600,
                            color: Tokens.onSurfaceFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Tokens.spaceSm),
                  _HiddenRewardPill(label: l10n.progQuestDetailHiddenReward),
                  const SizedBox(width: 6),
                  ExpandChevron(
                  expanded: isExpanded,
                  color: color.withValues(alpha: 0.82),
                  size: 20,
                ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 10),
                _QuestDetailPanel(
                  quest: quest,
                  allQuests: allQuests,
                  profile: profile,
                  trackedDaysElapsed: trackedDaysElapsed,
                  l10n: l10n,
                  progL10n: progL10n,
                  color: color,
                  mysteryLocked: true,
                ),
              ],
            ],
          ),
        ),
    );
  }
}

class _CompletedQuestRow extends StatelessWidget {
  const _CompletedQuestRow({
    required this.quest,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
    required this.isExpanded,
    required this.onToggle,
    required this.l10n,
    required this.progL10n,
    required this.enabled,
    required this.pillKey,
    required this.onClaimQuest,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
  final bool isExpanded;
  final VoidCallback onToggle;
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
    final domain = ProgressionDomainTheme.resolveForQuest(quest);
    final color = ProgressionDomainTheme.colorFor(domain);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ProgDomIco(domain: domain, size: 26),
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
                          fontSize: Tokens.fontSizeSmall,
                          fontWeight: FontWeight.w700,
                          color: Tokens.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        quest.completedAt != null
                            ? l10n.progQuestCompletedOn(
                                progressionFormatDateTime(
                                    quest.completedAt!, locale))
                            : progL10n.questCriterionDescriptor(quest),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Tokens.fontSizeMicro,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                _QuestRewardPill(
                  key: pillKey,
                  quest: quest,
                  claimedLabel: l10n.progQuestStatusClaimed,
                  onClaim: enabled
                      ? (center) => onClaimQuest(quest, from: center)
                      : null,
                ),
                const SizedBox(width: 6),
                ExpandChevron(
                  expanded: isExpanded,
                  color: color.withValues(alpha: 0.82),
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              _QuestDetailPanel(
                quest: quest,
                allQuests: allQuests,
                profile: profile,
                trackedDaysElapsed: trackedDaysElapsed,
                l10n: l10n,
                progL10n: progL10n,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quest detail panel ────────────────────────────────────────────────────────

class _QuestDetailPanel extends StatelessWidget {
  const _QuestDetailPanel({
    required this.quest,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
    required this.l10n,
    required this.progL10n,
    required this.color,
    this.mysteryLocked = false,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;
  final Color color;
  final bool mysteryLocked;

  @override
  Widget build(BuildContext context) {
    final detail = QuestDetailViewModel.build(
      quest: quest,
      allQuests: allQuests,
      profile: profile,
      trackedDaysElapsed: trackedDaysElapsed,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(height: 10),
        if (mysteryLocked)
          _QuestDetailTextSection(
            label: l10n.progQuestDetailLockedBecause,
            color: color,
            lines: detail.unlockReasons.isEmpty
                ? [l10n.progQuestDetailHiddenUntilUnlocked]
                : [
                    for (final reason in detail.unlockReasons)
                      _unlockReasonText(
                        reason,
                        allQuests,
                        l10n,
                        progL10n,
                      ),
                  ],
          )
        else ...[
          Text(
            progL10n.questDescription(quest),
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              color: Tokens.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _QuestDetailLine(
          label: l10n.progQuestDetailRewards,
          value: mysteryLocked
              ? l10n.progQuestDetailHiddenUntilUnlocked
              : '+${quest.rewardXp} XP',
          color: color,
        ),
        const SizedBox(height: Tokens.spaceSm),
        if (mysteryLocked)
          _QuestDetailLine(
            label: l10n.progQuestDetailUnlocksNext,
            value: l10n.progQuestDetailHiddenUntilUnlocked,
            color: color,
          )
        else
          _QuestDetailTextSection(
            label: l10n.progQuestDetailUnlocksNext,
            color: color,
            lines: detail.unlocksNext.isEmpty
                ? [l10n.progQuestDetailNoFollowUp]
                : [
                    for (final nextQuest in detail.unlocksNext)
                      progL10n.questTitle(nextQuest),
                  ],
          ),
        if (!mysteryLocked && detail.relatedRuleIds.isNotEmpty) ...[
          const SizedBox(height: Tokens.spaceSm),
          Text(
            l10n.progQuestDetailRelatedGoals.toUpperCase(),
            style: TextStyle(
              fontSize: Tokens.fontSizeTiny,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.76),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final ruleId in detail.relatedRuleIds)
                TinyPill(
                  label: progL10n.ruleTitle(ruleId),
                  color: color.withValues(alpha: 0.9),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _QuestDetailTextSection extends StatelessWidget {
  const _QuestDetailTextSection({
    required this.label,
    required this.lines,
    required this.color,
  });

  final String label;
  final List<String> lines;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: Tokens.fontSizeTiny,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: 0.76),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 3),
          Text(
            lines[i],
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Tokens.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestDetailLine extends StatelessWidget {
  const _QuestDetailLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: Tokens.fontSizeTiny,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.76),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}


// ── Quest reward pills ────────────────────────────────────────────────────────

class _HiddenRewardPill extends StatelessWidget {
  const _HiddenRewardPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            size: 11,
            color: Tokens.onSurfaceFaint,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: Tokens.onSurfaceFaint,
            ),
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
        ? XpClaimPillData.claimed(quest.rewardXp)
        : quest.isRewardClaimable
            ? XpClaimPillData.claimable(
                quest.rewardXp,
                onTap: onClaim ?? (_) {},
              )
            : XpClaimPillData.locked(quest.rewardXp);

    return XpClaimPill(
      data: data,
      claimedLabel: claimedLabel,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

// ── History feed ──────────────────────────────────────────────────────────────

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
      return ProgressionEmptyLine(
        title: l10n.progRewardsEmptyTitle,
        caption: l10n.progRewardsEmptyCaption,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
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
    final color = ProgressionDomainTheme.colorFor(domain);
    final xpLabel = _formatFullInt(grant.effectiveXpGranted, locale);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProgDomIco(domain: domain, size: 30),
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
                        fontSize: Tokens.fontSizeMicro,
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
                      fontSize: Tokens.fontSizeSmall,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA89BFF),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    progressionFormatDateTime(
                        grant.claimedAt ?? grant.unlockedAt, locale),
                    style: const TextStyle(
                      fontSize: Tokens.fontSizeTiny,
                      fontWeight: FontWeight.w600,
                      color: Tokens.onSurfaceFaint,
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
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: Tokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quest sub-header ──────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: Tokens.fontSizeMicro,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ── Utility functions ─────────────────────────────────────────────────────────

String _rewardDetailText(
  ProgressionRewardGrant reward,
  AppLocalizations l10n,
) {
  if (reward.ruleId == 'daily_weight_log') {
    final actual = _formatRewardMetric(reward.ruleId, reward.actualValue);
    return l10n.progRewardDetailWeightLogged(actual);
  }
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
    case 'daily_weight_goal':
      return l10n.goalUnitKg;
    default:
      return '';
  }
}

String _primaryUnlockReasonText(
  QuestDetailViewModel detail,
  List<ProgressionQuest> allQuests,
  AppLocalizations l10n,
  ProgressionL10n progL10n,
) {
  if (detail.unlockReasons.isEmpty) {
    return l10n.progQuestDetailHiddenUntilUnlocked;
  }
  return _unlockReasonText(
    detail.unlockReasons.first,
    allQuests,
    l10n,
    progL10n,
  );
}

String _unlockReasonText(
  QuestUnlockReason reason,
  List<ProgressionQuest> allQuests,
  AppLocalizations l10n,
  ProgressionL10n progL10n,
) {
  switch (reason.type) {
    case QuestUnlockReasonType.prerequisiteQuest:
      final prerequisite = _questById(allQuests, reason.questId);
      return l10n.progQuestDetailCompleteQuest(
        prerequisite == null
            ? (reason.questId ?? '')
            : progL10n.questTitle(prerequisite),
      );
    case QuestUnlockReasonType.level:
      return l10n.progQuestDetailRequiresLevel(reason.value ?? 0);
    case QuestUnlockReasonType.trackedDays:
      return l10n.progQuestDetailTrackDays(reason.value ?? 0);
  }
}

ProgressionQuest? _questById(List<ProgressionQuest> quests, String? questId) {
  if (questId == null) return null;
  for (final quest in quests) {
    if (quest.id == questId) return quest;
  }
  return null;
}

int _safePercent(double progress) {
  final pct = progress * 100;
  if (pct.isNaN || pct.isInfinite) return 0;
  return pct.clamp(0, 100).round();
}

String _formatFullInt(int value, String locale) {
  return NumberFormat.decimalPattern(locale).format(value);
}
