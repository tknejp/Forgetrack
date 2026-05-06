// Localization extensions for domain models.
//
// Lives in a separate file — not in progression_models.dart — because these
// extensions depend on the catalog layer (progression_rule_catalog), which in
// turn depends on progression_models. Putting them here avoids a circular
// import while keeping the catalogs and models themselves free of l10n logic.

import '../../../l10n/app_localizations.dart';
import 'progression_models.dart';
import 'catalog/rule_catalog.dart';

// ── Quest ─────────────────────────────────────────────────────────────────────

extension ProgressionQuestLocalizedValues on ProgressionQuest {
  String localizedSourceLabel(AppLocalizations l10n) =>
      sourceLabel?.call(l10n) ?? localizedCriterionDescriptor(l10n);

  String localizedChainStepLabel(AppLocalizations l10n) =>
      chainStepLabel?.call(l10n) ?? '';

  String localizedCriterionDescriptor(AppLocalizations l10n) =>
      criterionType.descriptor(
        l10n,
        ruleTitle:
            ruleId != null ? ProgressionRuleCatalog.titleForId(ruleId!, l10n) : null,
        domainLabel: domain?.label(l10n),
        sourceLabel: sourceLabel,
      );
}

// ── Quest criterion ───────────────────────────────────────────────────────────

extension ProgressionQuestCriterionTypeDescriptor
    on ProgressionQuestCriterionType {
  String descriptor(
    AppLocalizations l10n, {
    String? ruleTitle,
    String? domainLabel,
    ProgressionLocalizedText? sourceLabel,
  }) {
    switch (this) {
      case ProgressionQuestCriterionType.chapterStarted:
        return sourceLabel?.call(l10n) ?? l10n.progQuestSourceJourney;
      case ProgressionQuestCriterionType.totalXpAtLeast:
        return l10n.progQuestCriterionTotalXp;
      case ProgressionQuestCriterionType.rewardCountAtLeast:
        if (ruleTitle != null) {
          return l10n.progQuestCriterionRewardCountWithRule(ruleTitle);
        }
        return l10n.progQuestCriterionRewardCount;
      case ProgressionQuestCriterionType.bestStreakAtLeast:
        if (ruleTitle != null) {
          return l10n.progQuestCriterionStreakWithRule(ruleTitle);
        }
        if (domainLabel != null) {
          return l10n.progQuestCriterionStreakWithDomain(domainLabel);
        }
        return l10n.progQuestCriterionStreakGeneric;
      case ProgressionQuestCriterionType.totalRuleValueAtLeast:
        if (ruleTitle != null) {
          return l10n.progQuestCriterionTotalRuleValueWithRule(ruleTitle);
        }
        return l10n.progQuestCriterionTotalRuleValueGeneric;
      case ProgressionQuestCriterionType.currentPeriodRuleCompletion:
        if (ruleTitle != null) {
          return l10n.progQuestCriterionCurrentPeriodRule(ruleTitle);
        }
        return l10n.progQuestCriterionCurrentPeriodGeneric;
      case ProgressionQuestCriterionType.currentPeriodRuleSetAtLeast:
      case ProgressionQuestCriterionType.ruleSetCompletionsAtLeast:
        return l10n.progQuestCriterionCurrentPeriodRuleSet;
      case ProgressionQuestCriterionType.achievementUnlocked:
        return l10n.progQuestCriterionAchievement;
      case ProgressionQuestCriterionType.ruleCompletionsAtLeast:
        if (ruleTitle != null) {
          return l10n.progQuestCriterionCompletionsWithRule(ruleTitle);
        }
        return l10n.progQuestCriterionCompletionsGeneric;
      case ProgressionQuestCriterionType.domainRewardCountAtLeast:
        if (domainLabel != null) {
          return l10n.progQuestCriterionDomainRewardsWithDomain(domainLabel);
        }
        return l10n.progQuestCriterionDomainRewardsGeneric;
    }
  }
}
