import '../../domain/progression_models.dart';
import '../widgets/progression_internals.dart';
import '../../../../l10n/app_localizations.dart';
import 'quest_daily_selection.dart';

enum QuestSectionType {
  chapter,
  dailyGoals,
  dailyCombo,
  weekly,
  longTerm,
  upcomingChapters,
  locked,
  completed,
}

enum QuestCardType {
  active,
  locked,
  completed,
}

class QuestCardViewModel {
  const QuestCardViewModel({
    required this.quest,
    required this.type,
    required this.showChainPreview,
  });

  final ProgressionQuest quest;
  final QuestCardType type;
  final bool showChainPreview;
}

class QuestSectionViewModel {
  const QuestSectionViewModel({
    required this.type,
    required this.title,
    required this.quests,
    this.subtitle,
    this.isCollapsedByDefault = false,
    this.showEmptyState = false,
    this.totalQuestCount,
    this.claimableCompleted = const <ProgressionQuest>[],
  });

  final QuestSectionType type;
  final String title;
  final String? subtitle;
  final List<QuestCardViewModel> quests;
  final bool isCollapsedByDefault;
  final bool showEmptyState;
  final int? totalQuestCount;
  final List<ProgressionQuest> claimableCompleted;

  bool get isEmpty => quests.isEmpty;
}

class QuestScreenSections {
  const QuestScreenSections({
    required this.sections,
    required this.completedTotalCount,
  });

  final List<QuestSectionViewModel> sections;
  final int completedTotalCount;
}

class QuestScreenSectionsBuilder {
  const QuestScreenSectionsBuilder({
    required this.viewData,
    required this.l10n,
    required this.completedCompactLimit,
    required this.showAllCompleted,
  });

  final ProgressionViewData viewData;
  final AppLocalizations l10n;
  final int completedCompactLimit;
  final bool showAllCompleted;

  QuestScreenSections build() {
    final completedToShow = showAllCompleted
        ? viewData.completedQuests
        : viewData.completedQuests
            .take(completedCompactLimit)
            .toList(growable: false);
    final claimableCompleted = viewData.completedQuests
        .where((quest) => quest.isRewardClaimable)
        .toList(growable: false);
    final visibleLockedQuests = _visibleLockedQuests();

    final sections = <QuestSectionViewModel>[
      if (viewData.chapterQuests.isNotEmpty)
        _activeSection(
          type: QuestSectionType.chapter,
          title: l10n.progQuestsChapterHeader,
          quests: viewData.chapterQuests,
        ),
      _activeSection(
        type: QuestSectionType.dailyGoals,
        title: l10n.progQuestsDailyGoalsHeader,
        quests: viewData.dailyGoalQuests,
        showEmptyState: true,
      ),
      _activeSection(
        type: QuestSectionType.dailyCombo,
        title: l10n.progQuestsDailyComboHeader,
        quests: viewData.dailyComboQuests,
        showEmptyState: true,
      ),
      if (viewData.weeklyQuests.isNotEmpty)
        _activeSection(
          type: QuestSectionType.weekly,
          title: l10n.progQuestsWeeklyHeader,
          quests: viewData.weeklyQuests,
        ),
      if (viewData.longTermQuests.isNotEmpty)
        _activeSection(
          type: QuestSectionType.longTerm,
          title: l10n.progQuestsLongTermHeader,
          quests: viewData.longTermQuests,
        ),
      if (viewData.waitingChapterQuests.isNotEmpty)
        QuestSectionViewModel(
          type: QuestSectionType.upcomingChapters,
          title: l10n.progQuestsChapterWaitingHeader,
          subtitle: l10n.progQuestsChapterWaitingCaption,
          quests: [
            for (final quest in viewData.waitingChapterQuests)
              QuestCardViewModel(
                quest: quest,
                type: QuestCardType.locked,
                showChainPreview:
                    QuestDisplayPolicy.shouldShowChainPreview(quest),
              ),
          ],
        ),
      if (visibleLockedQuests.isNotEmpty)
        QuestSectionViewModel(
          type: QuestSectionType.locked,
          title: l10n.progQuestsLockedHeader,
          quests: [
            for (final quest in visibleLockedQuests)
              QuestCardViewModel(
                quest: quest,
                type: QuestCardType.locked,
                showChainPreview: QuestDisplayPolicy.shouldShowChainPreview(
                  quest,
                ),
              ),
          ],
        ),
      QuestSectionViewModel(
        type: QuestSectionType.completed,
        title: l10n.progQuestsCompletedHeader,
        quests: [
          for (final quest in completedToShow)
            QuestCardViewModel(
              quest: quest,
              type: QuestCardType.completed,
              showChainPreview: QuestDisplayPolicy.shouldShowChainPreview(
                quest,
              ),
            ),
        ],
        showEmptyState: true,
        totalQuestCount: viewData.completedQuests.length,
        claimableCompleted: claimableCompleted,
      ),
    ];

    return QuestScreenSections(
      sections: sections,
      completedTotalCount: viewData.completedQuests.length,
    );
  }

  QuestSectionViewModel _activeSection({
    required QuestSectionType type,
    required String title,
    required List<ProgressionQuest> quests,
    bool showEmptyState = false,
  }) {
    return QuestSectionViewModel(
      type: type,
      title: title,
      quests: [
        for (final quest in quests)
          QuestCardViewModel(
            quest: quest,
            type: QuestCardType.active,
            showChainPreview: QuestDisplayPolicy.shouldShowChainPreview(quest),
          ),
      ],
      showEmptyState: showEmptyState,
    );
  }

  List<ProgressionQuest> _visibleLockedQuests() {
    final nonChapterLocked = viewData.lockedQuests
        .where((quest) => !QuestDisplayPolicy.isChapterQuest(quest))
        .toList(growable: false);
    final nextLockedChapter = _nextLockedChapterQuest();

    return [
      ...nonChapterLocked,
      if (nextLockedChapter != null) nextLockedChapter,
    ];
  }

  ProgressionQuest? _nextLockedChapterQuest() {
    final hasActiveChapter = viewData.chapterQuests.any(
      (quest) => QuestDisplayPolicy.isChapterQuest(quest) && !quest.isCompleted,
    );
    if (hasActiveChapter) {
      return null;
    }
    if (viewData.waitingChapterQuests.isNotEmpty) {
      return null;
    }

    final chapterLocked = viewData.lockedQuests
        .where(QuestDisplayPolicy.isChapterQuest)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (chapterLocked.isEmpty) {
      return null;
    }

    return chapterLocked.firstWhere(
      QuestDisplayPolicy.isChapterOpenQuest,
      orElse: () => chapterLocked.first,
    );
  }
}

class QuestDisplayPolicy {
  const QuestDisplayPolicy._();

  static bool shouldShowChainPreview(ProgressionQuest quest) {
    if (isDailyGoalQuest(quest)) return false;
    return quest.chainId != null && quest.chainId!.isNotEmpty;
  }

  static bool isChapterQuest(ProgressionQuest quest) {
    return quest.displayBucket == ProgressionQuestDisplayBucket.chapter ||
        quest.category == ProgressionQuestCategory.chapter;
  }

  static bool isChapterOpenQuest(ProgressionQuest quest) {
    return isChapterQuest(quest) &&
        quest.criterionType == ProgressionQuestCriterionType.chapterStarted &&
        quest.prerequisiteQuestIds.isEmpty;
  }

  static bool isChapterRewardNode(
    ProgressionQuest quest,
    List<ProgressionQuest> allQuests,
  ) {
    if (!isChapterQuest(quest)) return false;
    if (quest.cosmeticRewards.isNotEmpty) {
      return true;
    }

    final chainId = quest.chainId;
    if (chainId == null || chainId.isEmpty) return false;
    final chapterChain = allQuests
        .where((candidate) => candidate.chainId == chainId)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return chapterChain.isNotEmpty && chapterChain.last.id == quest.id;
  }
}
