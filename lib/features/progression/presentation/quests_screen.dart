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
    for (final quest in [
      ...viewData.activeQuests,
      ...viewData.completedQuests,
    ]) {
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
            color: enabled ? (color ?? Tokens.accent) : Tokens.onSurfaceFaint,
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
        Row(
          children: [
            Expanded(
              child: _SubHeader(
                label: widget.l10n.progQuestsActiveHeader,
                color: Tokens.active.color,
                vivid: true,
              ),
            ),
            Text(
              widget.l10n.progQuestsActiveCount(widget.active.length),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w600,
                color: Tokens.onSurfaceMuted,
              ),
            ),
          ],
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
              enabled: !widget.isRefreshing,
              pillKey: widget.active[i].rewardKey == null
                  ? null
                  : widget.questPillKeys[widget.active[i].rewardKey!],
              onClaimQuest: widget.onClaimQuest,
            ),
          ],
        if (widget.locked.isNotEmpty) ...[
          const SizedBox(height: Tokens.spaceXl),
          _SubHeader(
            label: widget.l10n.progQuestsLockedHeader,
            color: Tokens.onSurfaceMuted,
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < widget.locked.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _LockedQuestRow(
              quest: widget.locked[i],
              allQuests: widget.allQuests,
              profile: widget.profile,
              trackedDaysElapsed: widget.trackedDaysElapsed,
              l10n: widget.l10n,
              progL10n: widget.progL10n,
            ),
          ],
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
            Text(
              widget.l10n.progQuestsCompletedCount(completedToShow.length),
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w600,
                color: Tokens.onSurfaceMuted,
              ),
            ),
            if (claimableCompleted.isNotEmpty) ...[
              const SizedBox(width: 12),
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
    final domain = ProgressionDomainTheme.resolveForQuest(quest);
    final color = ProgressionDomainTheme.colorFor(domain);
    final descriptor = progL10n.questSourceLabel(quest);
    final assetSize =
        isExpanded ? Tokens.questAssetExpanded : Tokens.questAssetCollapsed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(Tokens.questCardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFF111423),
          borderRadius: BorderRadius.circular(Tokens.questCardRadius),
          border: Border.all(
            color: isExpanded
                ? Tokens.accent.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (isExpanded)
              BoxShadow(
                color: Tokens.accent.withValues(alpha: 0.18),
                blurRadius: Tokens.glowXl,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestAsset(quest: quest, size: assetSize, color: color),
                const SizedBox(width: Tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progL10n.questTitle(quest),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        descriptor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Tokens.spaceSm),
                _QuestRewardPill(
                  key: pillKey,
                  quest: quest,
                  enabled: enabled,
                  onClaimQuest: enabled && quest.isRewardClaimable
                      ? (center) => onClaimQuest(quest, from: center)
                      : null,
                ),
                const SizedBox(width: 6),
                ExpandChevron(
                  expanded: isExpanded,
                  color: Tokens.onSurfaceMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceSm),
            Row(
              children: [
                SizedBox(width: assetSize + Tokens.spaceMd),
                Expanded(
                  child: _QuestChainPreview(
                    quest: quest,
                    allQuests: allQuests,
                    color: color,
                    progL10n: progL10n,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceSm),
            _QuestProgressRow(quest: quest, color: color),
            if (isExpanded) ...[
              const SizedBox(height: Tokens.spaceSm),
              _QuestExpandedDetails(
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

class _QuestChainPreview extends StatelessWidget {
  const _QuestChainPreview({
    required this.quest,
    required this.allQuests,
    required this.color,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final Color color;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final preview = _chainWindowFor(quest, allQuests, maxNodes: 4);
    final nodes = preview.nodes;
    if (nodes.isEmpty) return const SizedBox.shrink();

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (preview.hasMoreBefore) ...[
          _QuestChainMore(color: color),
          _QuestChainConnector(color: color),
        ],
        for (int i = 0; i < nodes.length; i++) ...[
          if (i > 0) _QuestChainConnector(color: color),
          _QuestChainNode(
            quest: nodes[i],
            isCurrent: nodes[i].id == quest.id,
            color: color,
            progL10n: progL10n,
          ),
        ],
        if (preview.hasMoreAfter) ...[
          _QuestChainConnector(color: color),
          _QuestChainMore(color: color),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) {
          return Align(alignment: Alignment.centerLeft, child: row);
        }
        return SizedBox(
          width: constraints.maxWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: row,
            ),
          ),
        );
      },
    );
  }
}

({List<ProgressionQuest> nodes, bool hasMoreBefore, bool hasMoreAfter})
    _chainWindowFor(
  ProgressionQuest quest,
  List<ProgressionQuest> allQuests, {
  int maxNodes = 3,
}) {
  final chainId = quest.chainId;
  if (chainId == null || chainId.isEmpty) {
    return (nodes: [quest], hasMoreBefore: false, hasMoreAfter: false);
  }
  final chain = allQuests
      .where((candidate) => candidate.chainId == chainId)
      .toList(growable: false)
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  if (chain.length <= maxNodes) {
    return (nodes: chain, hasMoreBefore: false, hasMoreAfter: false);
  }

  final index = chain.indexWhere((candidate) => candidate.id == quest.id);
  if (index == -1) {
    return (nodes: [quest], hasMoreBefore: false, hasMoreAfter: false);
  }
  if (maxNodes <= 1) {
    return (
      nodes: [chain[index]],
      hasMoreBefore: index > 0,
      hasMoreAfter: index < chain.length - 1,
    );
  }

  var start = index;
  if (index > 0 && chain[index - 1].isCompleted) {
    start = index - 1;
  }
  if (start + maxNodes > chain.length) {
    start = chain.length - maxNodes;
  }
  final end = start + maxNodes;
  return (
    nodes: chain.sublist(start, end),
    hasMoreBefore: start > 0,
    hasMoreAfter: end < chain.length,
  );
}

class _QuestChainConnector extends StatelessWidget {
  const _QuestChainConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Tokens.questChainConnectorWidth,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: color.withValues(alpha: 0.32),
    );
  }
}

class _QuestChainMore extends StatelessWidget {
  const _QuestChainMore({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Tokens.questChainNodeHeight,
      height: Tokens.questChainNodeHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(
        '…',
        style: TextStyle(
          height: 0.9,
          fontSize: Tokens.fontSizeCaption,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _QuestChainNode extends StatelessWidget {
  const _QuestChainNode({
    required this.quest,
    required this.isCurrent,
    required this.color,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final bool isCurrent;
  final Color color;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final completed = quest.isCompleted;
    final locked = quest.isLocked;
    final lockedAchievement = locked &&
        quest.criterionType ==
            ProgressionQuestCriterionType.achievementUnlocked;
    final localizedLabel = progL10n.questChainStepLabel(quest);
    final label =
        localizedLabel.isEmpty ? _compactTargetLabel(quest) : localizedLabel;
    final bg = completed
        ? Tokens.success.withValues(alpha: 0.10)
        : isCurrent
            ? color.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.045);
    final border = completed
        ? Tokens.success.withValues(alpha: 0.30)
        : isCurrent
            ? color.withValues(alpha: 0.70)
            : Colors.white.withValues(alpha: 0.08);
    final fg = completed
        ? Tokens.success
        : isCurrent
            ? Colors.white
            : Tokens.onSurfaceMuted;

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(
        minWidth: Tokens.questChainNodeMinWidth,
        minHeight: Tokens.questChainNodeHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
            const Icon(Icons.check_rounded, size: 12, color: Tokens.success)
          else if (locked && !isCurrent)
            Icon(
              lockedAchievement
                  ? Icons.emoji_events_rounded
                  : Icons.lock_rounded,
              size: 12,
              color: lockedAchievement
                  ? Tokens.xp.withValues(alpha: 0.72)
                  : Tokens.onSurfaceFaint,
            )
          else
            Text(
              label,
              style: TextStyle(
                fontSize: Tokens.fontSizeMicro,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestProgressRow extends StatelessWidget {
  const _QuestProgressRow({required this.quest, required this.color});

  final ProgressionQuest quest;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ProgressBar(
            value: quest.progress,
            color: color,
            glow: color.withValues(alpha: 0.36),
            height: Tokens.questProgressHeight,
          ),
        ),
        const SizedBox(width: Tokens.spaceSm),
        Text(
          '${quest.currentValue} / ${quest.targetValue}',
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            fontWeight: FontWeight.w800,
            color: Tokens.onSurface,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}

class _QuestAsset extends StatelessWidget {
  const _QuestAsset({
    required this.quest,
    required this.size,
    required this.color,
  });

  final ProgressionQuest quest;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = quest.assetKey;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.24),
                  blurRadius: Tokens.glowXl,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (asset == null || asset.isEmpty)
            ProgDomIco(
              domain: ProgressionDomainTheme.resolveForQuest(quest),
              size: size * 0.58,
            )
          else
            Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Quest asset failed to load: $asset — $error');
                return ProgDomIco(
                  domain: ProgressionDomainTheme.resolveForQuest(quest),
                  size: size * 0.58,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _QuestExpandedDetails extends StatelessWidget {
  const _QuestExpandedDetails({
    required this.quest,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
    required this.l10n,
    required this.progL10n,
    required this.color,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final detail = QuestDetailViewModel.build(
      quest: quest,
      allQuests: allQuests,
      profile: profile,
      trackedDaysElapsed: trackedDaysElapsed,
    );
    final catalogNext = [
      for (final id in quest.nextQuestIds) _questById(allQuests, id),
    ].whereType<ProgressionQuest>().toList(growable: false);
    final nextQuest = catalogNext.isNotEmpty
        ? catalogNext.first
        : (detail.unlocksNext.isEmpty ? null : detail.unlocksNext.first);
    final next = nextQuest == null
        ? l10n.progQuestDetailNoFollowUp
        : progL10n.questTitle(nextQuest);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(height: Tokens.spaceSm),
        _QuestDetailLine(
          label: l10n.progQuestDetailGoal,
          value: progL10n.questDescription(quest),
          color: color,
        ),
        const SizedBox(height: Tokens.spaceSm),
        _QuestDetailLine(
          label: l10n.progQuestDetailNextInChain,
          value: next,
          color: color,
        ),
      ],
    );
  }
}

String _compactTargetLabel(ProgressionQuest q) {
  // Prefer a compact numeric label (e.g., 100k, 1M) or small integer for combo quests.
  final value = q.targetValue;
  if (value >= 1000000) {
    final d = value / 1000000;
    return d.truncateToDouble() == d
        ? '${d.toInt()}M'
        : '${d.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final d = value / 1000;
    return d.truncateToDouble() == d
        ? '${d.toInt()}k'
        : '${d.toStringAsFixed(1)}k';
  }
  return value.toString();
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
    final isClaimable = quest.isRewardClaimable;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isClaimable
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD35A).withValues(alpha: 0.08),
                    const Color(0xFFF2A82E).withValues(alpha: 0.03),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: 0.01),
                  ],
                ),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(
            color: isClaimable
                ? const Color(0xFFFFD35A).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: isClaimable
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD35A).withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _QuestAsset(
                  quest: quest,
                  size: Tokens.questAssetCompleted,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progL10n.questTitle(quest),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isClaimable
                              ? Colors.white
                              : Tokens.onSurfaceMuted,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${quest.completedAt != null ? l10n.progQuestCompletedOn(progressionFormatDateTime(quest.completedAt!, locale)) : progL10n.questCriterionDescriptor(quest)} · +${quest.rewardXp} XP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isClaimable
                              ? Colors.white.withValues(alpha: 0.66)
                              : color.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CompletedQuestStatusChip(
                  key: pillKey,
                  quest: quest,
                  l10n: l10n,
                  enabled: enabled,
                  onClaimQuest: enabled
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
              _QuestExpandedDetails(
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

class _CompletedQuestStatusChip extends StatelessWidget {
  const _CompletedQuestStatusChip({
    super.key,
    required this.quest,
    required this.l10n,
    required this.enabled,
    required this.onClaimQuest,
  });

  final ProgressionQuest quest;
  final AppLocalizations l10n;
  final bool enabled;
  final void Function(Offset center)? onClaimQuest;

  @override
  Widget build(BuildContext context) {
    final isClaimable = quest.isRewardClaimable;
    final label = isClaimable
        ? '+${quest.rewardXp} XP'
        : quest.isRewardClaimed
            ? l10n.progQuestStatusClaimed
            : l10n.progQuestStatusCompleted;
    final color = isClaimable
        ? Tokens.xp
        : quest.isRewardClaimed
            ? Tokens.success.withValues(alpha: 0.78)
            : Tokens.onSurfaceMuted;
    final bg = isClaimable
        ? Tokens.xp.withValues(alpha: 0.15)
        : quest.isRewardClaimed
            ? Tokens.success.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.04);
    final border = isClaimable
        ? Tokens.xp.withValues(alpha: 0.30)
        : quest.isRewardClaimed
            ? Tokens.success.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.08);
    final icon = isClaimable ? Icons.bolt_rounded : Icons.check_rounded;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (!isClaimable || !enabled || onClaimQuest == null) return chip;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final box = context.findRenderObject() as RenderBox?;
        final center = box == null
            ? Offset.zero
            : box.localToGlobal(Offset.zero) +
                Offset(box.size.width / 2, box.size.height / 2);
        onClaimQuest!(center);
      },
      child: chip,
    );
  }
}

class _LockedQuestRow extends StatelessWidget {
  const _LockedQuestRow({
    required this.quest,
    required this.allQuests,
    required this.profile,
    required this.trackedDaysElapsed,
    required this.l10n,
    required this.progL10n,
  });

  final ProgressionQuest quest;
  final List<ProgressionQuest> allQuests;
  final ProgressionProfile profile;
  final int trackedDaysElapsed;
  final AppLocalizations l10n;
  final ProgressionL10n progL10n;

  @override
  Widget build(BuildContext context) {
    final domain = ProgressionDomainTheme.resolveForQuest(quest);
    final color = ProgressionDomainTheme.colorFor(domain);
    final detail = QuestDetailViewModel.build(
      quest: quest,
      allQuests: allQuests,
      profile: profile,
      trackedDaysElapsed: trackedDaysElapsed,
    );
    final reason = detail.unlockReasons.isEmpty
        ? l10n.progQuestStatusLocked
        : _lockReasonLabel(detail.unlockReasons.first, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.018),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: 0.56,
            child: _QuestAsset(
              quest: quest,
              size: Tokens.questAssetCompleted,
              color: color,
            ),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Tokens.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: Tokens.questChainNodeHeight,
            height: Tokens.questChainNodeHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 13,
              color: Tokens.onSurfaceFaint,
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: Tokens.fontSizeCaption,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Quest reward pills ────────────────────────────────────────────────────────

class _QuestRewardPill extends StatelessWidget {
  const _QuestRewardPill({
    super.key,
    required this.quest,
    this.enabled = true,
    this.onClaimQuest,
  });

  final ProgressionQuest quest;
  final bool enabled;
  final void Function(Offset center)? onClaimQuest;

  @override
  Widget build(BuildContext context) {
    final appearance = quest.isRewardClaimable
        ? (
            color: Tokens.xp,
            bg: Tokens.xp.withValues(alpha: 0.18),
            border: Tokens.xp.withValues(alpha: 0.34),
            icon: Icons.bolt_rounded,
            label: '+${quest.rewardXp} XP',
          )
        : quest.isRewardClaimed
            ? (
                color: Tokens.success.withValues(alpha: 0.88),
                bg: Tokens.success.withValues(alpha: 0.10),
                border: Tokens.success.withValues(alpha: 0.18),
                icon: Icons.check_rounded,
                label: '+${quest.rewardXp} XP',
              )
            : (
                color: Tokens.onSurfaceMuted,
                bg: Colors.white.withValues(alpha: 0.055),
                border: Colors.white.withValues(alpha: 0.09),
                icon: Icons.bolt_rounded,
                label: '${quest.rewardXp} XP',
              );

    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.questXpPillHorizontal,
        vertical: Tokens.questXpPillVertical,
      ),
      decoration: BoxDecoration(
        color: appearance.bg,
        borderRadius: BorderRadius.circular(Tokens.radiusProgress),
        border: Border.all(color: appearance.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, size: 10, color: appearance.color),
          const SizedBox(width: 2),
          Text(
            appearance.label,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w800,
              color: appearance.color,
            ),
          ),
        ],
      ),
    );

    if (!quest.isRewardClaimable || !enabled || onClaimQuest == null) {
      return pill;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final box = context.findRenderObject() as RenderBox?;
        final center = box == null
            ? Offset.zero
            : box.localToGlobal(Offset.zero) +
                Offset(box.size.width / 2, box.size.height / 2);
        onClaimQuest!(center);
      },
      child: pill,
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
  const _SubHeader({
    required this.label,
    required this.color,
    this.vivid = false,
  });
  final String label;
  final Color color;
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: Tokens.fontSizeMicro,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.0,
            shadows: vivid
                ? [
                    Shadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
        if (vivid) ...[
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0)
                ],
              ),
            ),
          ),
        ],
      ],
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
    case 'daily_carbs':
    case 'daily_fat':
    case 'daily_fiber':
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
    case 'daily_carbs':
    case 'daily_fat':
    case 'daily_fiber':
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

ProgressionQuest? _questById(List<ProgressionQuest> quests, String? questId) {
  if (questId == null) return null;
  for (final quest in quests) {
    if (quest.id == questId) return quest;
  }
  return null;
}

String _lockReasonLabel(
  QuestUnlockReason reason,
  AppLocalizations l10n,
) {
  switch (reason.type) {
    case QuestUnlockReasonType.level:
      return l10n.progQuestDetailRequiresLevel(reason.value ?? 0);
    case QuestUnlockReasonType.trackedDays:
      return l10n.progQuestDetailTrackDays(reason.value ?? 0);
    case QuestUnlockReasonType.prerequisiteQuest:
      return l10n.progQuestDetailCompleteQuest(reason.questId ?? '');
  }
}

String _formatFullInt(int value, String locale) {
  return NumberFormat.decimalPattern(locale).format(value);
}
