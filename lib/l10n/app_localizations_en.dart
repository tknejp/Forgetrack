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
  String get settingsTheme => 'Theme';

  @override
  String get settingsTimeTheme => 'Dynamic Time Theme';

  @override
  String get settingsTimeThemeDesc =>
      'Adjusts visuals based on the current time of day.';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDynamic => 'Dynamic';

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
  String get progScreenEyebrow => 'PROGRESSION PROFILE';

  @override
  String get progScreenTitle => 'Your long-term journey';

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
      'Active quests first, completed ones below.';

  @override
  String get progQuestsActiveHeader => 'ACTIVE QUESTS';

  @override
  String get progQuestsCompletedHeader => 'COMPLETED QUESTS';

  @override
  String get progQuestsEmptyActiveTitle => 'No active quests right now.';

  @override
  String get progQuestsEmptyActiveCaption =>
      'You have cleared the current static quest catalog.';

  @override
  String get progQuestsEmptyCompletedTitle => 'No completed quests yet.';

  @override
  String get progQuestsEmptyCompletedCaption =>
      'Your finished milestones will appear here.';

  @override
  String get progQuestStatusActive => 'Active';

  @override
  String get progQuestStatusCompleted => 'Completed';

  @override
  String progQuestCompletedOn(String time) {
    return 'Completed $time';
  }

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
  String get progAchievementPathfinderTitle => 'Pathfinder';

  @override
  String get progAchievementPathfinderDesc =>
      'Reach level 5 through earned XP.';

  @override
  String get progAchievementForgeKnight5000Title => 'Forge Knight';

  @override
  String get progAchievementForgeKnight5000Desc => 'Accumulate 5,000 XP.';

  @override
  String get progAchievementLivingLegend15000Title => 'Living Legend';

  @override
  String get progAchievementLivingLegend15000Desc => 'Accumulate 15,000 XP.';

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
  String get progAchievementBalancedRhythmTitle => 'Balanced Rhythm';

  @override
  String get progAchievementBalancedRhythmDesc =>
      'Earn at least one nutrition reward for 3 periods in a row.';

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
}
