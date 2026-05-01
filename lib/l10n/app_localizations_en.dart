// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Forgetrack';

  @override
  String get navOverview => 'Overview';

  @override
  String get navQuests => 'Quests';

  @override
  String get navHero => 'Hero';

  @override
  String get navSocial => 'Social';

  @override
  String get navActivities => 'Activities';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navBody => 'Body';

  @override
  String get screenProfile => 'Profile';

  @override
  String get screenActivities => 'Activities';

  @override
  String get screenNutrition => 'Nutrition';

  @override
  String get screenBody => 'Body';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodCustomRangeSoon => 'Custom range coming soon';

  @override
  String get caloriesAvgPerDay => 'Avg / day';

  @override
  String get sleepAverage => 'Average';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get stepsToday => 'Today';

  @override
  String get stepsCurrent => 'Current';

  @override
  String get stepsGoal => 'Goal';

  @override
  String get stepsRemaining => 'Remaining';

  @override
  String get stepsAverage => 'Average';

  @override
  String stepsAvgPerDay(String value) {
    return '$value / day';
  }

  @override
  String get stepsCompleted => 'Completed';

  @override
  String get stepsYes => 'Yes';

  @override
  String get stepsNo => 'No';

  @override
  String get stepsBestDay => 'Best day';

  @override
  String get stepsMaxSteps => 'Max steps';

  @override
  String get caloriesTodayTitle => 'Calories today';

  @override
  String get caloriesConsumed => 'Consumed';

  @override
  String get caloriesBurned => 'Burned';

  @override
  String get caloriesRemaining => 'Remaining';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFiber => 'Fiber';

  @override
  String get weightTitle => 'Weight';

  @override
  String get weightGoal => 'Goal';

  @override
  String get weightAverage => 'Average';

  @override
  String get weightMin => 'Min';

  @override
  String get weightMax => 'Max';

  @override
  String get weightBodyFat => 'Body fat';

  @override
  String get weightLeanMass => 'Lean mass';

  @override
  String get weightFatMass => 'Fat mass';

  @override
  String get weightMainLabelDay => 'Weight';

  @override
  String get weightVsPrevMeasure => 'vs prev.';

  @override
  String get weightVsPrevWeek => 'vs prev. week';

  @override
  String get weightVsPrevMonth => 'vs prev. month';

  @override
  String get weightNoMeasurement => 'No record';

  @override
  String get profileExportToSheets => 'Export to Sheets';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get emptyNoData => 'No data yet';

  @override
  String get settingsSection => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageCzech => 'Čeština';

  @override
  String get profileNotSignedIn => 'Not signed in';

  @override
  String get profileSignInBenefit =>
      'Sync workouts, calories and progress across devices';

  @override
  String get profileContinueWithGoogle => 'Continue with Google';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get profileConnectedGoogle => 'Connected with Google';

  @override
  String get profileSignOutConfirmTitle => 'Sign out?';

  @override
  String get profileSignOutConfirmMessage =>
      'You\'ll need to sign in again to sync your data.';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionAbout => 'About';

  @override
  String get sectionAccount => 'Account';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsFeedback => 'Send feedback';

  @override
  String get settingsClearCache => 'Clear local data';

  @override
  String get healthNotAvailable => 'Health Connect unavailable';

  @override
  String get healthNotAvailableBody =>
      'Install the Health Connect app to track your steps, weight and activity data.';

  @override
  String get healthInstall => 'Install';

  @override
  String get healthPermissionRequired => 'Permission required';

  @override
  String get healthPermissionBody =>
      'Grant Forgetrack access to Health Connect to display your real fitness data.';

  @override
  String get healthGrantAccess => 'Grant access';

  @override
  String get healthSyncFailed => 'Could not load health data';

  @override
  String get healthRetry => 'Retry';

  @override
  String healthLastSynced(String time) {
    return 'Synced: $time';
  }

  @override
  String get ktSectionTitle => 'Nutrition Sync';

  @override
  String get ktConnectBody =>
      'Connect to kaloricketabulky.cz to automatically sync your daily nutrition data.';

  @override
  String get ktEmailHint => 'Email';

  @override
  String get ktPasswordHint => 'Password';

  @override
  String get ktLoginButton => 'Connect';

  @override
  String get ktLoggingIn => 'Connecting…';

  @override
  String get ktConnectedBadge => 'Connected to kaloricketabulky.cz';

  @override
  String get ktDisconnectButton => 'Disconnect';

  @override
  String get ktDisconnectConfirmTitle => 'Disconnect Kalorické Tabulky?';

  @override
  String get ktDisconnectConfirmMessage =>
      'Your nutrition data will no longer sync from Kalorické Tabulky.';

  @override
  String get ktAuthError => 'Invalid email or password';

  @override
  String get ktSyncError => 'Could not sync nutrition data';

  @override
  String get ktRetry => 'Retry';

  @override
  String ktSyncedAt(String time) {
    return 'Synced: $time';
  }

  @override
  String get ktLoginPrompt =>
      'Connect Kalorické Tabulky in Settings to view your nutrition data.';

  @override
  String get ktGoToSettings => 'Go to Settings';

  @override
  String get ktNoDiaryData => 'No diary entries for today';

  @override
  String get ktNutritionTitle => 'Today\'s Nutrition';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get sleepDuration => 'Duration';

  @override
  String get sleepFellAsleep => 'Fell asleep';

  @override
  String get sleepWokeUp => 'Woke up';

  @override
  String get sleepNoData => 'No sleep data recorded';

  @override
  String get homeOpenDetailCta => 'Open details';

  @override
  String get activitiesWeekTotal => 'This week';

  @override
  String get activitiesMonthTotal => 'This month';

  @override
  String get activitiesActiveCalories => 'Active calories';

  @override
  String get activitiesActiveMins => 'Active min.';

  @override
  String get activitiesWorkouts => 'Workouts';

  @override
  String get activitiesNoWorkouts => 'No workouts in the last 30 days';

  @override
  String get activitiesRecentActivity => 'Recent workouts';

  @override
  String get activitiesDailyAvg => 'Daily avg';

  @override
  String get activitiesWeeklyAvg => 'Weekly avg';

  @override
  String get activitiesWeeklyTrend => '7-day trend';

  @override
  String get activitiesAvgDuration => 'Avg. duration';

  @override
  String get activitiesWorkoutPermissionTitle => 'Workout access needed';

  @override
  String get activitiesWorkoutPermissionBody =>
      'Grant Forgetrack access to your workout data in Health Connect to see activity history and stats.';

  @override
  String get sleepAvg7Day => '7-day avg';

  @override
  String get bodyCurrentWeight => 'Current';

  @override
  String get body30DayChange => '30-day change';

  @override
  String get bodyWeightTrend => 'Weight trend';

  @override
  String get bodyComposition => 'Body composition';

  @override
  String get bodyNoData => 'No weight data recorded';

  @override
  String get weightProgressExplanation =>
      'This percentage shows progress toward your goal based on your recorded weight history.';

  @override
  String get weightProgressExplanationLoss =>
      'This percentage shows progress from your highest recorded weight toward your goal, not current weight divided by goal.';

  @override
  String get weightProgressExplanationGain =>
      'This percentage shows progress from your lowest recorded weight toward your goal, not current weight divided by goal.';

  @override
  String get bodyProgressToGoal => 'Progress to goal';

  @override
  String bodyToGo(String value) {
    return '$value kg to go';
  }

  @override
  String get bodyAtGoal => 'Goal reached!';

  @override
  String get sectionGoals => 'Goals';

  @override
  String get goalDailySteps => 'Daily steps';

  @override
  String get goalTargetWeight => 'Target weight';

  @override
  String get goalDailyCalories => 'Daily calories';

  @override
  String get goalDailyProtein => 'Daily protein';

  @override
  String get goalSleepHours => 'Sleep';

  @override
  String get goalWeeklyActivity => 'Weekly activity';

  @override
  String get goalUnitSteps => 'steps';

  @override
  String get goalUnitKcal => 'kcal';

  @override
  String get goalUnitG => 'g';

  @override
  String get goalUnitHours => 'hours';

  @override
  String get goalUnitMins => 'min';

  @override
  String get goalUnitKg => 'kg';

  @override
  String get goalEditTitle => 'Set goal';

  @override
  String get goalSave => 'Save';

  @override
  String get headerToday => 'Today';

  @override
  String get macroSugar => 'Sugar';

  @override
  String get macroSalt => 'Salt';

  @override
  String get macroSaturatedFat => 'Sat. fat';

  @override
  String get goalDailyFat => 'Daily fat';

  @override
  String get goalDailyCarbs => 'Daily carbs';

  @override
  String get nutritionPeriod7d => '7 days';

  @override
  String get nutritionPeriod30d => '30 days';

  @override
  String get nutritionGoalsTitle => 'Edit goals';

  @override
  String get nutritionNoHistoryData => 'Not enough data for this period';

  @override
  String get exportScreenTitle => 'Export to Google Sheets';

  @override
  String get exportSignInTitle => 'Sign in with Google';

  @override
  String get exportSignInBody =>
      'Sheets export needs your Google account to write to your spreadsheet. Sign in to continue.';

  @override
  String get exportSignInButton => 'Sign in';

  @override
  String get exportSignInLoading => 'Signing in…';

  @override
  String get exportAuthorizationNote =>
      'Export may ask for Google Sheets permission when you run it.';

  @override
  String get exportTargetLabel => 'Target spreadsheet';

  @override
  String get exportTargetMissingBody =>
      'No spreadsheet linked yet. A new \"Forgetrack Data\" spreadsheet will be created in your Google Drive on the first export.';

  @override
  String get exportTargetCopyLink => 'Copy link';

  @override
  String get exportTargetLinkCopied => 'Spreadsheet link copied';

  @override
  String get exportTargetForgetButton => 'Forget link';

  @override
  String get exportTargetForgetConfirmTitle => 'Forget linked spreadsheet?';

  @override
  String get exportTargetForgetConfirmMessage =>
      'This only removes the link inside Forgetrack. The spreadsheet itself will remain in your Google Drive.';

  @override
  String get exportTargetForgetConfirmAction => 'Forget';

  @override
  String get exportRangeLabel => 'Date range';

  @override
  String exportRangeDayCount(int count) {
    return '$count day(s)';
  }

  @override
  String get exportRangePickButton => 'Choose range';

  @override
  String get exportRangeInvalid =>
      'End date must be on or after the start date.';

  @override
  String get exportRangePresetLast7 => 'Last 7d';

  @override
  String get exportRangePresetLast30 => 'Last 30d';

  @override
  String get exportRangePresetThisMonth => 'This month';

  @override
  String get exportRangePresetLastMonth => 'Last month';

  @override
  String get exportFieldsLabel => 'Fields to export';

  @override
  String get exportFieldsSelectAll => 'All';

  @override
  String get exportFieldsSelectNone => 'None';

  @override
  String get exportCategoryActivity => 'Activity';

  @override
  String get exportCategoryBody => 'Body';

  @override
  String get exportCategorySleep => 'Sleep';

  @override
  String get exportCategoryNutrition => 'Nutrition';

  @override
  String get exportButton => 'Export to Sheets';

  @override
  String get exportButtonRunning => 'Exporting…';

  @override
  String exportSummary(int days, int fields, String range) {
    return '$days day(s) · $fields field(s) · $range';
  }

  @override
  String exportExplainer(String today) {
    return 'Rows are merged by date — existing dates are updated, new ones are appended. Today is $today.';
  }

  @override
  String get exportSuccessTitle => 'Export complete';

  @override
  String exportSuccessDetail(int rows, int added, int updated) {
    return 'Wrote $rows row(s) — +$added added, $updated updated.';
  }

  @override
  String get exportErrorTitle => 'Export failed';

  @override
  String get exportErrorGeneric => 'Unknown error.';

  @override
  String get exportErrorNotSignedIn =>
      'Not signed in to Google. Sign in to enable Sheets export.';

  @override
  String get exportErrorNoFields => 'Select at least one field to export.';

  @override
  String get exportErrorInvalidRange =>
      'Invalid range: the end date is before the start date.';

  @override
  String exportErrorPrefix(String message) {
    return 'Export failed: $message';
  }

  @override
  String get exportFieldSteps => 'Steps';

  @override
  String get exportFieldActiveCalories => 'Active calories';

  @override
  String get exportFieldActiveCaloriesDesc =>
      'Calories burned through activity (kcal).';

  @override
  String get exportFieldWeight => 'Weight';

  @override
  String get exportFieldWeightDesc => 'Latest weight recorded on the day (kg).';

  @override
  String get exportFieldBodyFat => 'Body fat';

  @override
  String get exportFieldBodyFatDesc =>
      'Body-fat percentage recorded on the day.';

  @override
  String get exportFieldSleepDuration => 'Sleep duration';

  @override
  String get exportFieldSleepDurationDesc =>
      'Total sleep on the night ending on this date (minutes).';

  @override
  String get exportFieldSleepBedtime => 'Bedtime';

  @override
  String get exportFieldSleepWake => 'Wake time';

  @override
  String get exportFieldKcalIn => 'Calories in';

  @override
  String get exportFieldKcalInDesc =>
      'Calories logged via Kalorické tabulky (kcal).';

  @override
  String get exportFieldProtein => 'Protein';

  @override
  String get exportFieldFat => 'Fat';

  @override
  String get exportFieldCarbs => 'Carbs';

  @override
  String get exportFieldFiber => 'Fiber';

  @override
  String get exportFieldSugar => 'Sugar';

  @override
  String get exportFieldSalt => 'Salt';

  @override
  String get exportFieldSaturatedFat => 'Saturated fat';

  @override
  String get exportHeaderDate => 'Date';

  @override
  String get exportHeaderSteps => 'Steps';

  @override
  String get exportHeaderActiveCalories => 'Active calories (kcal)';

  @override
  String get exportHeaderWeight => 'Weight (kg)';

  @override
  String get exportHeaderBodyFat => 'Body fat (%)';

  @override
  String get exportHeaderSleepDuration => 'Sleep (min)';

  @override
  String get exportHeaderSleepBedtime => 'Bedtime';

  @override
  String get exportHeaderSleepWake => 'Wake time';

  @override
  String get exportHeaderKcalIn => 'Calories in (kcal)';

  @override
  String get exportHeaderProtein => 'Protein (g)';

  @override
  String get exportHeaderFat => 'Fat (g)';

  @override
  String get exportHeaderCarbs => 'Carbs (g)';

  @override
  String get exportHeaderFiber => 'Fiber (g)';

  @override
  String get exportHeaderSugar => 'Sugar (g)';

  @override
  String get exportHeaderSalt => 'Salt (g)';

  @override
  String get exportHeaderSaturatedFat => 'Saturated fat (g)';

  @override
  String get progScreenEyebrow => 'HERO PROFILE';

  @override
  String get progScreenTitle => 'Your hero journey';

  @override
  String get progScreenLoadingHint => 'Preparing your legend';

  @override
  String get progScreenEntryTitle => 'Progression profile';

  @override
  String progScreenEntrySubtitle(String levelTitle, int totalXp, int unlocked) {
    return '$levelTitle · $totalXp XP · $unlocked achievements';
  }

  @override
  String get progOpenCta => 'Open progression profile';

  @override
  String get progBadgeTotalXp => 'TOTAL XP';

  @override
  String progBadgeLevel(int level, String title) {
    return 'LEVEL $level · $title';
  }

  @override
  String progBadgeStreak(int count) {
    return '$count streak';
  }

  @override
  String get progBadgeStreakEmpty => 'No current streak';

  @override
  String get progBadgeStreakHint => 'Build your first chain';

  @override
  String progBadgeUnlocked(int count) {
    return '$count unlocked';
  }

  @override
  String get progBadgeAchievements => 'Achievements';

  @override
  String progBadgePendingClaims(int count) {
    return '$count to claim';
  }

  @override
  String progBadgeXpRange(int current, int max) {
    return '$current / $max XP';
  }

  @override
  String progLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get progStreakSectionLabel => 'Streaks';

  @override
  String get progStreakSectionCaption =>
      'Current and best streaks across your domains.';

  @override
  String get progStreakCurrentLabel => 'CURRENT STREAK';

  @override
  String get progStreakBestLabel => 'BEST STREAK';

  @override
  String get progStreakDaysSuffix => 'days';

  @override
  String get progActiveQuestsLabel => 'Active quests';

  @override
  String progShowAllCount(int count) {
    return 'Show all ($count) →';
  }

  @override
  String get progMiniStatTotalXp => 'Total XP';

  @override
  String get progMiniStatToNext => 'To next';

  @override
  String get progMiniStatAchievements => 'Achievements';

  @override
  String get progMiniStatQuests => 'Quests';

  @override
  String get progSummarySectionLabel => 'Progression Summary';

  @override
  String get progSummaryCurrentStreak => 'Current Streak';

  @override
  String get progSummaryBestStreak => 'Best Streak';

  @override
  String get progSummaryCompletedQuests => 'Completed Quests';

  @override
  String get progSummaryAchievements => 'Achievements';

  @override
  String get progSummaryNoActiveChain => 'No active chain yet';

  @override
  String get progSummaryBuildConsistency => 'Build consistency';

  @override
  String get progQuestsSectionLabel => 'Quests';

  @override
  String get progQuestsSectionCaption =>
      'Active and locked quests first, completed ones below.';

  @override
  String get questsScreenEyebrow => 'QUESTS';

  @override
  String get questsScreenTitle => 'Your quests and rewards';

  @override
  String get progQuestsActiveHeader => 'ACTIVE QUESTS';

  @override
  String get progQuestsLockedHeader => 'LOCKED QUESTS';

  @override
  String get progQuestsCompletedHeader => 'COMPLETED QUESTS';

  @override
  String get progQuestsEmptyActiveTitle => 'No active quests right now.';

  @override
  String get progQuestsEmptyActiveCaption =>
      'You have cleared the current static quest catalog.';

  @override
  String get progQuestsEmptyLockedTitle => 'No locked quests right now.';

  @override
  String get progQuestsEmptyLockedCaption =>
      'New gated quests will appear here when there is something to unlock later.';

  @override
  String get progQuestsEmptyCompletedTitle => 'No completed quests yet.';

  @override
  String get progQuestsEmptyCompletedCaption =>
      'Your finished milestones will appear here.';

  @override
  String get progQuestStatusActive => 'Active';

  @override
  String get progQuestStatusLocked => 'Locked';

  @override
  String get progQuestStatusClaimed => 'Claimed';

  @override
  String get progQuestStatusCompleted => 'Completed';

  @override
  String get progQuestClaimAll => 'Claim all quests';

  @override
  String get progQuestClaim => 'Claim quest';

  @override
  String progQuestCompletedOn(String time) {
    return 'Completed $time';
  }

  @override
  String get progQuestDetailRewards => 'Rewards';

  @override
  String get progQuestDetailUnlocksNext => 'Unlocks next';

  @override
  String get progQuestDetailLockedBecause => 'Locked because';

  @override
  String progQuestDetailRequiresLevel(int level) {
    return 'Requires level $level';
  }

  @override
  String progQuestDetailTrackDays(int days) {
    return 'Track $days days';
  }

  @override
  String progQuestDetailCompleteQuest(String quest) {
    return 'Complete $quest';
  }

  @override
  String get progQuestDetailRelatedGoals => 'Related goals';

  @override
  String get progQuestDetailTapForDetails => 'Tap for details';

  @override
  String get progQuestDetailHiddenUntilUnlocked => 'Hidden until unlocked';

  @override
  String get progQuestDetailHiddenReward => 'Hidden';

  @override
  String get progQuestDetailNoFollowUp => 'No follow-up quest yet';

  @override
  String progProgressRatio(int current, int target) {
    return '$current / $target';
  }

  @override
  String progPercent(int value) {
    return '$value%';
  }

  @override
  String get progAchievementsSectionLabel => 'Achievements';

  @override
  String get progAchievementsSectionCaption =>
      'Unlocked badges and current progress.';

  @override
  String get progAchievementsUnlockedHeader => 'UNLOCKED';

  @override
  String get progAchievementsInProgressHeader => 'IN PROGRESS';

  @override
  String get progAchievementsEmptyUnlockedTitle =>
      'No achievements unlocked yet.';

  @override
  String get progAchievementsEmptyUnlockedCaption =>
      'Your earned badges will light up here.';

  @override
  String get progAchievementsEmptyInProgressTitle =>
      'Everything in the current catalog is unlocked.';

  @override
  String get progAchievementsEmptyInProgressCaption =>
      'Add more achievements to expand the journey.';

  @override
  String get progAchievementStatusUnlocked => 'Unlocked';

  @override
  String get progAchievementStatusInProgress => 'In progress';

  @override
  String get progRewardsSectionLabel => 'Recent Rewards';

  @override
  String get progRewardsSectionCaption =>
      'Latest XP grants earned across your domains.';

  @override
  String get progRewardsPendingTitle => 'Pending Rewards';

  @override
  String get progRewardsPendingCaption =>
      'Goal-bound rewards unlock after the day or week closes. Claiming adds XP to your profile.';

  @override
  String get progRewardsClaimAll => 'Claim all';

  @override
  String get progRewardsClaim => 'Claim';

  @override
  String progRewardsUnlockedAt(String time) {
    return 'Unlocked $time';
  }

  @override
  String progRewardDetail(String target, String unit, String actual) {
    return 'Target $target $unit | Actual $actual $unit';
  }

  @override
  String get progRewardsEmptyTitle => 'No rewards granted yet.';

  @override
  String get progRewardsEmptyCaption =>
      'Completed goals will start filling your journal.';

  @override
  String progRewardSubtitle(String domain, int xp) {
    return '$domain · +$xp XP';
  }

  @override
  String get progDomainSteps => 'Steps';

  @override
  String get progDomainNutrition => 'Nutrition';

  @override
  String get progDomainSleep => 'Sleep';

  @override
  String get progDomainActivity => 'Activity';

  @override
  String get progRuleDailySteps => 'Daily Steps';

  @override
  String get progRuleDailyCalories => 'Calorie Target';

  @override
  String get progRuleDailyProtein => 'Protein Target';

  @override
  String get progRuleDailySleep => 'Sleep Target';

  @override
  String get progRuleWeeklyActivity => 'Weekly Activity';

  @override
  String get progRuleDailyWeightLog => 'Weight Log';

  @override
  String get progRuleDailyWeightGoal => 'Weight Goal';

  @override
  String progRewardDetailWeightLogged(String actual) {
    return 'Logged: $actual kg';
  }

  @override
  String get progQuestEarnFirstRewardTitle => 'Earn First Reward';

  @override
  String get progQuestEarnFirstRewardDesc =>
      'Earn your first progression reward.';

  @override
  String get progQuestDailyTwoGoalsTodayTitle => 'Double Win';

  @override
  String get progQuestDailyTwoGoalsTodayDesc =>
      'Complete any 2 daily goals in the current day.';

  @override
  String get progQuestDailyTripleWinTodayTitle => 'Triple Win';

  @override
  String get progQuestDailyTripleWinTodayDesc =>
      'Complete any 3 daily goals in the current day.';

  @override
  String get progQuestDailyFourPillarsTodayTitle => 'Four Pillars';

  @override
  String get progQuestDailyFourPillarsTodayDesc =>
      'Complete all 4 daily goals in the current day.';

  @override
  String get progQuestDailyNutritionComboTodayTitle => 'Nutrition Combo';

  @override
  String get progQuestDailyNutritionComboTodayDesc =>
      'Complete both calorie and protein goals in the current day.';

  @override
  String get progQuestDailyRecoveryFocusTodayTitle => 'Recovery Focus';

  @override
  String get progQuestDailyRecoveryFocusTodayDesc =>
      'Complete both steps and sleep goals in the current day.';

  @override
  String get progQuestDailyStepsTodayTitle => 'Today\'s Step Goal';

  @override
  String get progQuestDailyStepsTodayDesc =>
      'Complete the daily steps rule in the current day.';

  @override
  String get progQuestDailyCaloriesTodayTitle => 'Today\'s Calorie Goal';

  @override
  String get progQuestDailyCaloriesTodayDesc =>
      'Complete the daily calorie rule in the current day.';

  @override
  String get progQuestDailyProteinTodayTitle => 'Today\'s Protein Goal';

  @override
  String get progQuestDailyProteinTodayDesc =>
      'Complete the daily protein rule in the current day.';

  @override
  String get progQuestDailySleepTodayTitle => 'Today\'s Sleep Goal';

  @override
  String get progQuestDailySleepTodayDesc =>
      'Complete the daily sleep rule in the current day.';

  @override
  String get progQuestReach500XpTitle => 'Reach 500 XP';

  @override
  String get progQuestReach500XpDesc => 'Accumulate at least 500 XP.';

  @override
  String get progQuestReach2000XpTitle => 'Reach 2,000 XP';

  @override
  String get progQuestReach2000XpDesc => 'Accumulate at least 2,000 XP.';

  @override
  String get progQuestReach5000XpTitle => 'Reach 5,000 XP';

  @override
  String get progQuestReach5000XpDesc => 'Accumulate at least 5,000 XP.';

  @override
  String get progQuestEarn25RewardsTitle => 'Earn 25 Rewards';

  @override
  String get progQuestEarn25RewardsDesc =>
      'Collect 25 progression rewards in total.';

  @override
  String get progQuestEarn100RewardsTitle => 'Earn 100 Rewards';

  @override
  String get progQuestEarn100RewardsDesc =>
      'Collect 100 progression rewards in total.';

  @override
  String get progQuestStepsStreak3Title => 'Steps Streak';

  @override
  String get progQuestStepsStreak3Desc =>
      'Complete the daily steps rule 3 periods in a row.';

  @override
  String get progQuestNutritionRewards5Title => 'Nutrition Rhythm';

  @override
  String get progQuestNutritionRewards5Desc => 'Earn 5 nutrition rewards.';

  @override
  String get progQuestNutritionRewards25Title => 'Nutrition Mastery';

  @override
  String get progQuestNutritionRewards25Desc => 'Earn 25 nutrition rewards.';

  @override
  String get progQuestTotalSteps100kTitle => 'Walk 100K Steps';

  @override
  String get progQuestTotalSteps100kDesc => 'Accumulate 100,000 total steps.';

  @override
  String get progQuestTotalSteps500kTitle => 'Walk 500K Steps';

  @override
  String get progQuestTotalSteps500kDesc => 'Accumulate 500,000 total steps.';

  @override
  String get progQuestWeeklyActivityOnceTitle => 'Weekly Activity';

  @override
  String get progQuestWeeklyActivityOnceDesc =>
      'Complete the weekly activity rule once.';

  @override
  String get progQuestWeeklyActivity4Title => 'Weekly Activity Momentum';

  @override
  String get progQuestWeeklyActivity4Desc =>
      'Complete the weekly activity rule 4 times.';

  @override
  String get progQuestWeeklyActivity12Title => 'Weekly Activity Legend';

  @override
  String get progQuestWeeklyActivity12Desc =>
      'Complete the weekly activity rule 12 times.';

  @override
  String get progQuestUnlockStepChainTitle => 'Unlock Step Chain';

  @override
  String get progQuestUnlockStepChainDesc =>
      'Unlock the Step Chain achievement.';

  @override
  String get progQuestStepsStreak7Title => 'Step Discipline';

  @override
  String get progQuestStepsStreak7Desc =>
      'Complete the daily steps rule 7 periods in a row.';

  @override
  String get progQuestStepsStreak14Title => 'Step Guardian';

  @override
  String get progQuestStepsStreak14Desc =>
      'Complete the daily steps rule 14 periods in a row.';

  @override
  String get progAchievementFirstRewardTitle => 'First Reward';

  @override
  String get progAchievementFirstRewardDesc =>
      'Earn your first progression reward.';

  @override
  String get progAchievementRewardHunter25Title => 'Reward Hunter';

  @override
  String get progAchievementRewardHunter25Desc =>
      'Earn 25 progression rewards.';

  @override
  String get progAchievementRewardHunter100Title => 'Reward Legend';

  @override
  String get progAchievementRewardHunter100Desc =>
      'Earn 100 progression rewards.';

  @override
  String get progAchievementPathfinderTitle => 'Wanderer';

  @override
  String get progAchievementPathfinderDesc =>
      'Reach level 5 through earned XP.';

  @override
  String get progAchievementTrailVanguardLevel10Title => 'Pathfinder';

  @override
  String get progAchievementTrailVanguardLevel10Desc =>
      'Reach level 10 through earned XP.';

  @override
  String get progAchievementForgeKnightLevel15Title => 'Forge Knight';

  @override
  String get progAchievementForgeKnightLevel15Desc =>
      'Reach level 15 through earned XP.';

  @override
  String get progAchievementIronWardenLevel20Title => 'Iron Warden';

  @override
  String get progAchievementIronWardenLevel20Desc =>
      'Reach level 20 through earned XP.';

  @override
  String get progAchievementStormHeraldLevel25Title => 'Storm Herald';

  @override
  String get progAchievementStormHeraldLevel25Desc =>
      'Reach level 25 through earned XP.';

  @override
  String get progAchievementDawnSentinelLevel30Title => 'Castle Lord';

  @override
  String get progAchievementDawnSentinelLevel30Desc =>
      'Reach level 30 through earned XP.';

  @override
  String get progAchievementRiftWalkerLevel40Title => 'Dragon Rider';

  @override
  String get progAchievementRiftWalkerLevel40Desc =>
      'Reach level 40 through earned XP.';

  @override
  String get progAchievementForgeKnight5000Title => 'Forge Knight';

  @override
  String get progAchievementForgeKnight5000Desc => 'Accumulate 5,000 XP.';

  @override
  String get progAchievementLivingLegend15000Title => 'Living Legend';

  @override
  String get progAchievementLivingLegend15000Desc => 'Accumulate 15,000 XP.';

  @override
  String get progAchievementXp100000Title => 'Ascendant';

  @override
  String get progAchievementXp100000Desc => 'Accumulate 100,000 XP.';

  @override
  String get progAchievementXp1000000Title => 'Radiant Ascension';

  @override
  String get progAchievementXp1000000Desc => 'Accumulate 1,000,000 XP.';

  @override
  String get progAchievementMythicRangerLevel50Title => 'Mythic Ranger';

  @override
  String get progAchievementMythicRangerLevel50Desc =>
      'Reach level 50 through earned XP.';

  @override
  String get progAchievementTitanForgerLevel60Title => 'Titan Forger';

  @override
  String get progAchievementTitanForgerLevel60Desc =>
      'Reach level 60 through earned XP.';

  @override
  String get progAchievementAstralChampionLevel70Title => 'Astral Champion';

  @override
  String get progAchievementAstralChampionLevel70Desc =>
      'Reach level 70 through earned XP.';

  @override
  String get progAchievementEternalParagonLevel80Title => 'Eternal Paragon';

  @override
  String get progAchievementEternalParagonLevel80Desc =>
      'Reach level 80 through earned XP.';

  @override
  String get progAchievementRealmSovereignLevel90Title => 'Realm Sovereign';

  @override
  String get progAchievementRealmSovereignLevel90Desc =>
      'Reach level 90 through earned XP.';

  @override
  String get progAchievementLivingLegendLevel100Title => 'Living Legend';

  @override
  String get progAchievementLivingLegendLevel100Desc =>
      'Reach level 100 through earned XP.';

  @override
  String get progAchievementSteps100kTitle => 'Centurion Walker';

  @override
  String get progAchievementSteps100kDesc => 'Accumulate 100,000 total steps.';

  @override
  String get progAchievementSteps500kTitle => 'Half-Million March';

  @override
  String get progAchievementSteps500kDesc => 'Accumulate 500,000 total steps.';

  @override
  String get progAchievementSteps1000000Title => 'Million Step Myth';

  @override
  String get progAchievementSteps1000000Desc =>
      'Accumulate 1,000,000 total steps.';

  @override
  String get progAchievementSteps5000000Title => 'Gemstone Path';

  @override
  String get progAchievementSteps5000000Desc =>
      'Accumulate 5,000,000 total steps.';

  @override
  String get progAchievementSteps10000000Title => 'Summit of Legends';

  @override
  String get progAchievementSteps10000000Desc =>
      'Accumulate 10,000,000 total steps.';

  @override
  String get progAchievementStepsMonth300kTitle => 'Trail Builder';

  @override
  String get progAchievementStepsMonth300kDesc =>
      'Accumulate 300,000 steps across any 30-day window.';

  @override
  String get progAchievementStepsMonth600kTitle => 'Iron Pilgrim';

  @override
  String get progAchievementStepsMonth600kDesc =>
      'Accumulate 600,000 steps across any 30-day window.';

  @override
  String get progAchievementStepChainTitle => 'Step Chain';

  @override
  String get progAchievementStepChainDesc =>
      'Hit the daily steps rule for 3 periods in a row.';

  @override
  String get progAchievementStepDisciplineTitle => 'Step Discipline';

  @override
  String get progAchievementStepDisciplineDesc =>
      'Hit the daily steps rule for 7 periods in a row.';

  @override
  String get progAchievementStepSovereignTitle => 'Step Sovereign';

  @override
  String get progAchievementStepSovereignDesc =>
      'Hit the daily steps rule for 30 periods in a row.';

  @override
  String get progAchievementStepCenturionTitle => 'Iron Chain';

  @override
  String get progAchievementStepCenturionDesc =>
      'Hit the daily steps rule for 100 periods in a row.';

  @override
  String get progAchievementBalancedRhythmTitle => 'Balanced Rhythm';

  @override
  String get progAchievementBalancedRhythmDesc =>
      'Earn at least one nutrition reward for 3 periods in a row.';

  @override
  String get progAchievementNutritionStreak30Title => 'Macro Momentum';

  @override
  String get progAchievementNutritionStreak30Desc =>
      'Earn at least one nutrition reward for 30 periods in a row.';

  @override
  String get progAchievementNutritionStreak100Title => 'Kitchen Discipline';

  @override
  String get progAchievementNutritionStreak100Desc =>
      'Earn at least one nutrition reward for 100 periods in a row.';

  @override
  String get progAchievementNutritionRewards25Title => 'Macro Maestro';

  @override
  String get progAchievementNutritionRewards25Desc =>
      'Earn 25 nutrition rewards.';

  @override
  String get progAchievementWeeklyWarriorTitle => 'Weekly Warrior';

  @override
  String get progAchievementWeeklyWarriorDesc =>
      'Complete the weekly activity rule at least once.';

  @override
  String get progAchievementWeeklyActivity4Title => 'Activity Vanguard';

  @override
  String get progAchievementWeeklyActivity4Desc =>
      'Complete the weekly activity rule 4 times.';

  @override
  String get progAchievementWeeklyActivity12Title => 'Seasoned Mover';

  @override
  String get progAchievementWeeklyActivity12Desc =>
      'Complete the weekly activity rule 12 times.';

  @override
  String get progAchievementWeeklyActivity24Title => 'Unbroken Momentum';

  @override
  String get progAchievementWeeklyActivity24Desc =>
      'Complete the weekly activity rule 24 times.';

  @override
  String get progAchievementWeeklyActivity52Title => 'Yearlong Engine';

  @override
  String get progAchievementWeeklyActivity52Desc =>
      'Complete the weekly activity rule 52 times.';

  @override
  String get progAchievementSleep250hTitle => 'Rested Soul';

  @override
  String get progAchievementSleep250hDesc =>
      'Accumulate 250 hours of tracked sleep.';

  @override
  String get progAchievementSleep1000hTitle => 'Dream Archivist';

  @override
  String get progAchievementSleep1000hDesc =>
      'Accumulate 1,000 hours of tracked sleep.';

  @override
  String get progAchievementSleepMonth225hTitle => 'Deep Reset';

  @override
  String get progAchievementSleepMonth225hDesc =>
      'Accumulate 225 hours of sleep across any 30-day window.';

  @override
  String get progAchievementSleepMonth240hTitle => 'Perfect Recovery';

  @override
  String get progAchievementSleepMonth240hDesc =>
      'Accumulate 240 hours of sleep across any 30-day window.';

  @override
  String get progAchievementDifficultyEasy => 'Easy';

  @override
  String get progAchievementDifficultyMedium => 'Medium';

  @override
  String get progAchievementDifficultyHard => 'Hard';

  @override
  String get progAchievementDifficultyExtraHard => 'Extra Hard';

  @override
  String get progQuestCriterionTotalXp => 'Based on total XP';

  @override
  String progQuestCriterionRewardCountWithRule(String rule) {
    return 'Based on $rule';
  }

  @override
  String get progQuestCriterionRewardCount => 'Based on reward count';

  @override
  String progQuestCriterionStreakWithRule(String rule) {
    return 'Based on $rule streak';
  }

  @override
  String progQuestCriterionStreakWithDomain(String domain) {
    return 'Based on $domain streak';
  }

  @override
  String get progQuestCriterionStreakGeneric => 'Based on streak consistency';

  @override
  String progQuestCriterionTotalRuleValueWithRule(String rule) {
    return 'Based on total $rule';
  }

  @override
  String get progQuestCriterionTotalRuleValueGeneric =>
      'Based on accumulated total';

  @override
  String progQuestCriterionCurrentPeriodRule(String rule) {
    return 'For the current period: $rule';
  }

  @override
  String get progQuestCriterionCurrentPeriodGeneric => 'For the current period';

  @override
  String get progQuestCriterionCurrentPeriodRuleSet =>
      'For a current-period combo';

  @override
  String get progQuestCriterionAchievement => 'Based on achievement unlock';

  @override
  String progQuestCriterionCompletionsWithRule(String rule) {
    return 'Based on $rule completions';
  }

  @override
  String get progQuestCriterionCompletionsGeneric =>
      'Based on rule completions';

  @override
  String progQuestCriterionDomainRewardsWithDomain(String domain) {
    return 'Based on $domain rewards';
  }

  @override
  String get progQuestCriterionDomainRewardsGeneric =>
      'Based on domain rewards';

  @override
  String get settingsDeveloperTools => 'Developer Tools';

  @override
  String get devtoolsTitle => 'Developer Tools';

  @override
  String get journeyTitle => 'Hero Journey';

  @override
  String get journeyPreviewKicker => 'HERO JOURNEY';

  @override
  String get journeyOpenMap => 'Open map';

  @override
  String get journeyPanHint => 'Swipe for more';

  @override
  String get journeyHistoryHeader => 'Milestone history';

  @override
  String get journeyLastMilestone => 'Last milestone';

  @override
  String get journeyNextGoal => 'Next goal';

  @override
  String get journeyTitleLabel => 'Title';

  @override
  String get journeyFilterAll => 'All';

  @override
  String get journeyFilterLevels => 'Levels';

  @override
  String get journeyFilterTitles => 'Titles';

  @override
  String get journeyFilterAchievements => 'Achievements';

  @override
  String get journeyFilterQuests => 'Quests';

  @override
  String get journeyEventLevelReached => 'Level reached';

  @override
  String get journeyEventTitleUnlocked => 'Title unlocked';

  @override
  String get journeyEventAchievementUnlocked => 'Achievement unlocked';

  @override
  String get journeyEventQuestCompleted => 'Quest completed';

  @override
  String get journeyMilestoneReached => 'Milestone reached';

  @override
  String get journeyBadgeLocked => 'LOCKED';

  @override
  String get journeyBadgeHere => 'HERE';

  @override
  String get journeyTypeLevel => 'LEVEL';

  @override
  String get journeyTypeTitle => 'TITLE';

  @override
  String get journeyTypeAchievement => 'ACHIEVEMENT';

  @override
  String get journeyTypeQuest => 'QUEST';

  @override
  String get journeyEmptyMapTitle => 'Your journey starts now';

  @override
  String get journeyEmptyMapBody =>
      'Complete a quest, unlock an achievement or log activity — milestones will start appearing on the map.';

  @override
  String get journeyEmptyFeedAll =>
      'No milestones yet. Complete a quest or unlock an achievement.';

  @override
  String get journeyEmptyFeedFiltered => 'No milestones in this category yet.';

  @override
  String get journeyMiniMapEmpty =>
      'Milestones will appear once you reach your first goal.';

  @override
  String get journeyRelativeNow => 'just now';

  @override
  String journeyRelativeMinutes(int count) {
    return '$count min ago';
  }

  @override
  String journeyRelativeHours(int count) {
    return '$count h ago';
  }

  @override
  String journeyRelativeDays(int count) {
    return '$count days ago';
  }

  @override
  String journeyRelativeWeeks(int count) {
    return '$count weeks ago';
  }

  @override
  String journeyRelativeMonths(int count) {
    return '$count months ago';
  }

  @override
  String journeyRelativeYears(int count) {
    return '$count years ago';
  }

  @override
  String get journeyStartLabel => 'Journey begins';

  @override
  String get journeyStartDescription => 'The beginning of your hero journey.';

  @override
  String journeyStartSublabel(Object level, Object title) {
    return 'Level $level · $title';
  }

  @override
  String journeyLevelLabel(Object level) {
    return 'Level $level';
  }

  @override
  String journeyLevelWithTitle(Object level, Object title) {
    return 'Level $level · $title';
  }

  @override
  String journeyTotalXp(Object xp) {
    return '$xp XP total';
  }

  @override
  String get progLevelTitle1 => 'Wanderer';

  @override
  String get progLevelTitle5 => 'Trail Explorer';

  @override
  String get progLevelTitle10 => 'Ranger of the Wildwood';

  @override
  String get progLevelTitle15 => 'Guardian of the Pass';

  @override
  String get progLevelTitle20 => 'Conqueror of Ruins';

  @override
  String get progLevelTitle25 => 'Keeper of the Old Gates';

  @override
  String get progLevelTitle30 => 'Delver of the Depths';

  @override
  String get progLevelTitle40 => 'Dwarven Ally';

  @override
  String get progLevelTitle50 => 'Lord of the Underground Paths';

  @override
  String get progLevelTitle60 => 'Guardian of Frost';

  @override
  String get progLevelTitle70 => 'Icewalker';

  @override
  String get progLevelTitle80 => 'Mountain Challenger';

  @override
  String get progLevelTitle90 => 'Dragon Rider';

  @override
  String get progLevelTitle100 => 'Lord of Dragonrock';

  @override
  String progLevelAchievementDesc(int level) {
    return 'Reach level $level through earned XP.';
  }

  @override
  String get cosmeticFrameLvl1Name => 'Pilgrim\'s Frame';

  @override
  String get cosmeticFrameLvl1Desc =>
      'A plain wooden frame for anyone who set out on the road.';

  @override
  String get cosmeticFrameLvl10Name => 'Wildwood Frame';

  @override
  String get cosmeticFrameLvl10Desc =>
      'Dark wood and subtle forest carvings for those who learned to read the paths of the wildwood.';

  @override
  String get cosmeticFrameLvl25Name => 'Old Gates Frame';

  @override
  String get cosmeticFrameLvl25Desc =>
      'Weathered stone and aged bronze from the pass where the trail gives way to ruins.';

  @override
  String get cosmeticFrameLvl40Name => 'Dwarven Frame';

  @override
  String get cosmeticFrameLvl40Desc =>
      'A sturdy frame of forged metal and mine stone, crafted in the depths of dwarven halls.';

  @override
  String get cosmeticFrameLvl60Name => 'Frost Frame';

  @override
  String get cosmeticFrameLvl60Desc =>
      'A cold silver frame with an icy sheen, born in the silence of the frozen lands.';

  @override
  String get cosmeticFrameLvl80Name => 'Mountain Challenger\'s Frame';

  @override
  String get cosmeticFrameLvl80Desc =>
      'Dark mountain stone and blackened steel for those who climbed toward the fortress path.';

  @override
  String get cosmeticFrameLvl100Name => 'Dragonrock Frame';

  @override
  String get cosmeticFrameLvl100Desc =>
      'A legendary frame of obsidian, dragonstone, and golden details, reserved for the lord of Dragonrock.';

  @override
  String get cosmeticRelicOldCompassName => 'Old Compass';

  @override
  String get cosmeticRelicOldCompassDesc =>
      'A brass compass whose needle sometimes points the wrong way.';

  @override
  String get cosmeticBackgroundForestTrailName => 'Forest Trail';

  @override
  String get cosmeticBackgroundForestTrailDesc =>
      'A misty path winding under the tall canopy.';

  @override
  String get cosmeticEmblemForestMarkName => 'Forest Mark';

  @override
  String get cosmeticEmblemForestMarkDesc =>
      'A sigil carved into bark — the first travellers\' greeting.';

  @override
  String get cosmeticFrameRuinedBronzeName => 'Ruined Bronze';

  @override
  String get cosmeticFrameRuinedBronzeDesc =>
      'A patina-coated frame pulled from ancient ruins.';

  @override
  String get cosmeticRelicOldGateKeyName => 'Old Gate Key';

  @override
  String get cosmeticRelicOldGateKeyDesc =>
      'A heavy key whose lock no longer exists.';

  @override
  String get cosmeticBackgroundCampName => 'Pilgrim Camp';

  @override
  String get cosmeticBackgroundCampDesc =>
      'A circle of stones around a fading fire — the road begins here.';

  @override
  String get cosmeticBackgroundRavineName => 'Rocky Ravine';

  @override
  String get cosmeticBackgroundRavineDesc =>
      'A narrow cut between cliffs where the wind never stops moving.';

  @override
  String get cosmeticBackgroundRuinsName => 'Ancient Ruins';

  @override
  String get cosmeticBackgroundRuinsDesc =>
      'Broken halls weathered by centuries beyond the pass.';

  @override
  String get cosmeticBackgroundBridgeCrossingName => 'Bridge Crossing';

  @override
  String get cosmeticBackgroundBridgeCrossingDesc =>
      'Suspended ropes span the deep gorge between old roads.';

  @override
  String get cosmeticBackgroundMinesName => 'Mining Settlement';

  @override
  String get cosmeticBackgroundMinesDesc =>
      'Smoke and lantern light from the mountain\'s working heart.';

  @override
  String get cosmeticBackgroundFrostlandsName => 'Frostlands';

  @override
  String get cosmeticBackgroundFrostlandsDesc =>
      'Snow-pale ground that swallows footsteps and sound.';

  @override
  String get cosmeticBackgroundFrozenLakeName => 'Frozen Lake';

  @override
  String get cosmeticBackgroundFrozenLakeDesc =>
      'Still ice over still water — the long quiet before the climb.';

  @override
  String get cosmeticBackgroundRockyMountainsName => 'Rocky Mountains';

  @override
  String get cosmeticBackgroundRockyMountainsDesc =>
      'Black ridges and thin air on the road to the fortress.';

  @override
  String get cosmeticBackgroundDragonrockFortressName => 'Dragonrock Fortress';

  @override
  String get cosmeticBackgroundDragonrockFortressDesc =>
      'The obsidian keep at the end of the journey.';

  @override
  String get cosmeticEmblemPilgrimMarkName => 'Pilgrim Mark';

  @override
  String get cosmeticEmblemPilgrimMarkDesc =>
      'A traveller\'s badge worn by those who chose the road.';

  @override
  String get cosmeticEmblemRuinSigilName => 'Ruin Sigil';

  @override
  String get cosmeticEmblemRuinSigilDesc =>
      'A seal struck for those who walked the old halls.';

  @override
  String get cosmeticEmblemGatekeeperMarkName => 'Gatekeeper Mark';

  @override
  String get cosmeticEmblemGatekeeperMarkDesc =>
      'A bronze badge given to those who passed the old gates.';

  @override
  String get cosmeticEmblemMineCrestName => 'Mine Crest';

  @override
  String get cosmeticEmblemMineCrestDesc =>
      'A miner\'s emblem honouring those who reached the deep workings.';

  @override
  String get cosmeticEmblemUnderwaysMarkName => 'Underways Mark';

  @override
  String get cosmeticEmblemUnderwaysMarkDesc =>
      'A sigil for those who learned the paths beneath the mountain.';

  @override
  String get cosmeticEmblemFrostSigilName => 'Frost Sigil';

  @override
  String get cosmeticEmblemFrostSigilDesc =>
      'A pale-silver badge given to wanderers of the frozen north.';

  @override
  String get cosmeticEmblemIcewalkerMarkName => 'Icewalker Mark';

  @override
  String get cosmeticEmblemIcewalkerMarkDesc =>
      'A badge worn by those who held their pace across the ice.';

  @override
  String get cosmeticEmblemMountainCrestName => 'Mountain Challenger Crest';

  @override
  String get cosmeticEmblemMountainCrestDesc =>
      'An ironclad emblem for those who climbed toward the fortress.';

  @override
  String get cosmeticEmblemDragonMarkName => 'Dragon Mark';

  @override
  String get cosmeticEmblemDragonMarkDesc =>
      'A scaled sigil branded into those who faced the dragon road.';

  @override
  String get cosmeticEmblemDragonrockEmblemName => 'Dragonrock Emblem';

  @override
  String get cosmeticEmblemDragonrockEmblemDesc =>
      'The black-and-gold seal of the lord of Dragonrock.';

  @override
  String get cosmeticRelicCampfireSparkName => 'Campfire Spark';

  @override
  String get cosmeticRelicCampfireSparkDesc =>
      'The first ember from the first night out.';

  @override
  String get cosmeticRelicPilgrimCloakName => 'Pilgrim Cloak';

  @override
  String get cosmeticRelicPilgrimCloakDesc =>
      'Travel-worn wool that has already seen one full week of the road.';

  @override
  String get cosmeticRelicTrailCompassName => 'Trail Compass';

  @override
  String get cosmeticRelicTrailCompassDesc =>
      'A small forest compass earned by completing seven daily quests.';

  @override
  String get cosmeticRelicAncientRootName => 'Ancient Root';

  @override
  String get cosmeticRelicAncientRootDesc =>
      'A twisted root from the old forest, marker of seven days unbroken.';

  @override
  String get cosmeticRelicRavineStoneName => 'Ravine Stone';

  @override
  String get cosmeticRelicRavineStoneDesc =>
      'A heavy stone carried over a hundred thousand steps.';

  @override
  String get cosmeticRelicRuinSealName => 'Ruin Seal';

  @override
  String get cosmeticRelicRuinSealDesc =>
      'A wax seal pressed for completing the first weekly quest.';

  @override
  String get cosmeticRelicBridgeKeyName => 'Bridge Key';

  @override
  String get cosmeticRelicBridgeKeyDesc =>
      'An iron key that turns the locks on the old bridge gates.';

  @override
  String get cosmeticRelicMinersLanternName => 'Miner\'s Lantern';

  @override
  String get cosmeticRelicMinersLanternDesc =>
      'A brass lantern earned by completing fifty quests.';

  @override
  String get cosmeticRelicPolarLanternName => 'Polar Lantern';

  @override
  String get cosmeticRelicPolarLanternDesc =>
      'A pale-flame lantern for those who reached the frostlands.';

  @override
  String get cosmeticRelicFrostShardName => 'Frost Shard';

  @override
  String get cosmeticRelicFrostShardDesc =>
      'A splinter of true frost, cold to the touch under any sun.';

  @override
  String get cosmeticRelicFrozenLakeHeartName => 'Frozen Lake Heart';

  @override
  String get cosmeticRelicFrozenLakeHeartDesc =>
      'A blue-cored stone earned at one million total steps.';

  @override
  String get cosmeticRelicDragonScaleName => 'Dragon Scale';

  @override
  String get cosmeticRelicDragonScaleDesc =>
      'A black scale with a faint heat under its surface.';

  @override
  String get cosmeticRelicDragonCrownName => 'Dragon Crown';

  @override
  String get cosmeticRelicDragonCrownDesc =>
      'A circlet of dragon-tooth iron earned across two hundred and fifty quests.';

  @override
  String get cosmeticRelicDragonrockCrownName => 'Dragonrock Crown';

  @override
  String get cosmeticRelicDragonrockCrownDesc =>
      'The endgame crown of Dragonrock — proof of both quest mastery and a finished climb.';

  @override
  String get cosmeticFrameDisciplineName => 'Flame of Discipline';

  @override
  String get cosmeticFrameDisciplineDesc =>
      'Earned by holding the line for seven days in a row.';

  @override
  String get cosmeticFrameEnduranceName => 'Endurance Frame';

  @override
  String get cosmeticFrameEnduranceDesc =>
      'Forged for those who keep moving through a thirty-day streak.';

  @override
  String get cosmeticFrameSteelName => 'Steel Frame';

  @override
  String get cosmeticFrameSteelDesc =>
      'Hard steel for the unbroken — fifty days unbroken.';

  @override
  String get cosmeticFrameEternalFlameName => 'Eternal Flame Frame';

  @override
  String get cosmeticFrameEternalFlameDesc =>
      'A frame for the rare hundred-day flame that never gutters.';

  @override
  String get cosmeticFrameBalanceName => 'Balance Frame';

  @override
  String get cosmeticFrameBalanceDesc =>
      'Earned by stringing together seven perfect days.';

  @override
  String get cosmeticFrameMasterRoutineName => 'Master Routine Frame';

  @override
  String get cosmeticFrameMasterRoutineDesc =>
      'A gilded frame for twelve perfect weeks — the master of the rhythm.';

  @override
  String get cosmeticFrameEndlessTrailName => 'Endless Trail Frame';

  @override
  String get cosmeticFrameEndlessTrailDesc =>
      'Awarded for walking 600,000 steps within 30 days.';

  @override
  String get cosmeticFrameWorldwalkerName => 'Worldwalker Frame';

  @override
  String get cosmeticFrameWorldwalkerDesc =>
      'A legend\'s frame, ten million steps deep.';

  @override
  String get cosmeticCompanionEmberSpriteName => 'Ember Sprite';

  @override
  String get cosmeticCompanionEmberSpriteDesc =>
      'A small spark that follows the steady-footed.';

  @override
  String get cosmeticCompanionForestFoxName => 'Forest Fox';

  @override
  String get cosmeticCompanionForestFoxDesc =>
      'A quiet wildwood fox that pads alongside seasoned walkers.';

  @override
  String get cosmeticCompanionRuinRavenName => 'Ruin Raven';

  @override
  String get cosmeticCompanionRuinRavenDesc =>
      'A black bird from the old halls, seen most often after a weekly quest is closed.';

  @override
  String get cosmeticCompanionLanternGolemName => 'Lantern Golem';

  @override
  String get cosmeticCompanionLanternGolemDesc =>
      'A small stone golem with a flickering lantern in its chest.';

  @override
  String get cosmeticCompanionIceWispName => 'Ice Wisp';

  @override
  String get cosmeticCompanionIceWispDesc =>
      'A pale spark drawn out of the frozen lake by those who carry both shard and heart.';

  @override
  String get cosmeticCompanionMountainGryphonName => 'Mountain Gryphon';

  @override
  String get cosmeticCompanionMountainGryphonDesc =>
      'A grey gryphon that rides the high ridges with its chosen walker.';

  @override
  String get cosmeticCompanionDragonlingName => 'Dragonling';

  @override
  String get cosmeticCompanionDragonlingDesc =>
      'A small dragon that recognises only the lord of Dragonrock.';

  @override
  String cosmeticUnlockHintLevel(int level) {
    return 'Unlocked at level $level.';
  }

  @override
  String cosmeticUnlockHintStreak(int days) {
    return 'Unlocked by reaching a $days-day streak.';
  }

  @override
  String cosmeticUnlockHintTotalSteps(int steps) {
    return 'Unlocked at $steps total steps.';
  }

  @override
  String cosmeticUnlockHintMonthlySteps(int steps) {
    return 'Unlocked by walking $steps steps within 30 days.';
  }

  @override
  String cosmeticUnlockHintQuestsCompleted(int count) {
    return 'Unlocked after completing $count quests.';
  }

  @override
  String cosmeticUnlockHintPerfectDays(int count) {
    return 'Unlocked after $count perfect days.';
  }

  @override
  String cosmeticUnlockHintPerfectWeeks(int count) {
    return 'Unlocked after $count perfect weeks.';
  }

  @override
  String cosmeticUnlockHintActiveDays(int days) {
    return 'Unlocked after $days active days.';
  }

  @override
  String get cosmeticUnlockHintCompound =>
      'Unlocked by completing several milestones.';

  @override
  String get progAchievementWelcomeToJourneyTitle => 'Welcome to the Journey';

  @override
  String get progAchievementWelcomeToJourneyDesc => 'You set out on the road.';

  @override
  String get progAchievementStepsStreak50Title => 'Iron Resolve';

  @override
  String get progAchievementStepsStreak50Desc =>
      'Hit the daily steps rule for 50 periods in a row.';

  @override
  String get cosmeticEquippedBadge => 'EQUIPPED';

  @override
  String get cosmeticUnknown => 'Unknown cosmetic';

  @override
  String get cosmeticRarityCommon => 'Common';

  @override
  String get cosmeticRarityRare => 'Rare';

  @override
  String get cosmeticRarityEpic => 'Epic';

  @override
  String get cosmeticRarityLegendary => 'Legendary';

  @override
  String get celebrationCosmeticUnlockedEyebrow => 'Inventory unlocked';

  @override
  String get socialTabFeed => 'Feed';

  @override
  String get socialTabActivity => 'Activity';

  @override
  String get socialTabLeaderboard => 'Leaderboard';

  @override
  String get socialTabFriends => 'Friends';

  @override
  String get socialSectionRecentActivity => 'RECENT ACTIVITY';

  @override
  String get socialSectionFriendActivity => 'FRIEND ACTIVITY';

  @override
  String get socialNoNotificationsTitle => 'No notifications';

  @override
  String get socialNoNotificationsSubtitle =>
      'Reactions from friends on your shared achievements will appear here.';

  @override
  String get socialFeedEmptyTitle => 'Feed is empty';

  @override
  String get socialFeedEmptySubtitle =>
      'Shared achievements from friends will appear here.';

  @override
  String get socialFriendsEmptyTitle => 'No friends yet';

  @override
  String get socialFriendsEmptySubtitle =>
      'Add friends by searching for their handle.';

  @override
  String socialFriendsSectionCount(int count) {
    return 'FRIENDS  •  $count';
  }

  @override
  String get socialFriendRequestsTitle => 'Friend requests';

  @override
  String socialOutgoingRequestsCount(int count) {
    return 'Sent requests • $count';
  }

  @override
  String get socialFriendRequestAccepted => 'Request accepted.';

  @override
  String get socialFriendRequestDeclined => 'Request declined.';

  @override
  String get socialFriendRequestSent => 'Friend request sent.';

  @override
  String socialErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get socialWantsToBeFriend => 'Wants to become your friend';

  @override
  String get socialAccept => 'Accept';

  @override
  String get socialDecline => 'Decline';

  @override
  String get socialAwaitingConfirmation => 'Waiting for confirmation';

  @override
  String get socialPending => 'Pending';

  @override
  String get socialSearchHint => 'Search by handle…';

  @override
  String get socialSearchButton => 'Find';

  @override
  String get socialAdd => 'Add';

  @override
  String socialHandleLevel(String handle, int level) {
    return '@$handle · Level $level';
  }

  @override
  String socialLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String socialFriendCount(int count) {
    return '$count friends';
  }

  @override
  String get socialLeaderboardThisWeek => 'This week';

  @override
  String get socialLeaderboardAllTime => 'All time';

  @override
  String get socialLeaderboardSoonTitle => 'Coming soon';

  @override
  String get socialLeaderboardSoonSubtitle =>
      'Weekly leaderboard will be available soon.';

  @override
  String get socialLeaderboardEmptyTitle => 'Leaderboard is empty';

  @override
  String get socialLeaderboardEmptySubtitle =>
      'Add friends and compare your results.';

  @override
  String get socialLeaderboardTopPlayers => 'TOP PLAYERS';

  @override
  String get socialYouBadge => 'You!';

  @override
  String socialYouSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get socialXpLabel => 'XP';

  @override
  String get socialStatusSignInRequired =>
      'Google sign-in is required for social features.';

  @override
  String socialStatusBackendUnavailable(String error) {
    return 'Firebase backend unavailable: $error';
  }

  @override
  String get socialStatusConnecting => 'Connecting to social backend…';

  @override
  String socialStatusError(String error) {
    return 'Error: $error';
  }

  @override
  String get socialEditHandleTitle => 'Change Social ID';

  @override
  String get socialEditHandleDescription =>
      'Your ID is used to find you in Social.';

  @override
  String get socialEditHandleValidation => 'Enter at least one character.';

  @override
  String get socialCancel => 'Cancel';

  @override
  String get socialSave => 'Save';

  @override
  String get socialEditHandleTooltip => 'Change ID';

  @override
  String get socialEditPhotoTooltip => 'Change photo';

  @override
  String socialHandleSaveFailed(String error) {
    return 'ID could not be saved: $error';
  }

  @override
  String socialHandleSaved(String handle) {
    return 'Social ID saved: @$handle';
  }

  @override
  String socialPhotoPickFailed(String error) {
    return 'Photo selection failed: $error';
  }

  @override
  String socialPhotoSaveFailed(String error) {
    return 'Photo could not be saved: $error';
  }

  @override
  String get socialPhotoSaved => 'Profile photo saved.';

  @override
  String get socialTryAgain => 'try again';

  @override
  String get socialSelectedLoadout => 'Selected\nloadout';

  @override
  String get socialProfilePinnedAchievements => 'PINNED ACHIEVEMENTS';

  @override
  String get socialProfileSharedPosts => 'SHARED POSTS';

  @override
  String get socialProfileStatsAchievements => 'ACHIEVEMENTS';

  @override
  String get socialProfileStatsBestStreak => 'BEST STREAK';

  @override
  String get socialProfileStatsStepsStreak => 'STEPS STREAK';

  @override
  String socialDaysShort(int count) {
    return '$count d';
  }

  @override
  String get socialPinnedEmptyMine =>
      'You have nothing pinned yet. Open an achievement detail and pin it to your profile.';

  @override
  String get socialPinnedEmptyOther => 'No pinned achievements.';

  @override
  String get socialPinnedUnavailable =>
      'Pinned achievements are no longer available.';

  @override
  String get socialSharedPostsEmpty => 'No shared posts yet.';

  @override
  String get socialProfileCosmetics => 'COSMETICS';

  @override
  String get socialAddFriend => 'Add friend';

  @override
  String get socialRequestSent => 'Request sent';

  @override
  String get socialRemoveFriend => 'Remove friend';

  @override
  String get socialRemoveFriendConfirmTitle => 'Remove friend';

  @override
  String socialRemoveFriendConfirmBody(String name) {
    return 'Do you really want to remove $name from your friends?';
  }

  @override
  String get socialNotificationReactedPrefix => ' reacted ';

  @override
  String get socialNotificationReactedSuffix => ' to your achievement ';

  @override
  String get socialNotificationOpenPost => 'View post';

  @override
  String get socialAchievementUnlockedAction => 'unlocked an achievement';

  @override
  String socialReactorsTitle(int count) {
    return 'Reacted ($count)';
  }

  @override
  String get socialProfileFriendsTitle => 'FRIENDS';

  @override
  String get socialProfileNoFriends => 'No friends yet.';

  @override
  String socialFriendLevelSubtitle(int level, String title) {
    return 'Level $level $title';
  }

  @override
  String socialFriendHandleLevelSubtitle(
      String handle, int level, String title) {
    return '@$handle - Level $level $title';
  }

  @override
  String get socialRelativeNow => 'just now';

  @override
  String socialRelativeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String socialRelativeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get socialRelativeYesterday => 'yesterday';

  @override
  String socialRelativeDaysAgo(int count) {
    return '$count days ago';
  }
}
