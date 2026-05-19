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
  String get screenSteps => 'Steps';

  @override
  String get screenNutrition => 'Nutrition';

  @override
  String get nutritionEnergyTrend => 'Calorie trend';

  @override
  String get nutritionMacroTrend => 'Macro trend';

  @override
  String get nutritionHydrationTitle => 'Hydration';

  @override
  String get nutritionMacrosDetailTitle => 'Macronutrients';

  @override
  String get nutritionMealsTitle => 'Meals';

  @override
  String get nutritionMealsEmpty => 'No meals logged';

  @override
  String nutritionFoodItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'no items',
    );
    return '$_temp0';
  }

  @override
  String get nutritionBalanceTitle => 'Energy balance';

  @override
  String get nutritionBalanceBasal => 'Basal';

  @override
  String get nutritionBalanceActive => 'Active';

  @override
  String get nutritionBalanceOutput => 'Output';

  @override
  String get nutritionBalanceIntake => 'Intake';

  @override
  String get nutritionBalanceDeficit => 'Deficit';

  @override
  String get nutritionBalanceSurplus => 'Surplus';

  @override
  String get nutritionMealsOnlyDayMode =>
      'Meal & balance details only available in day mode';

  @override
  String get screenBody => 'Body';

  @override
  String get stepsCurrentStreak => 'Streak';

  @override
  String get stepsLinkSubtitle => 'Daily steps & goal';

  @override
  String get activitiesByType => 'By type';

  @override
  String get activitiesLinkSubtitle => 'Workouts, calories, time';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodToday => 'Today';

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
  String get weightBodyWater => 'Body water';

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
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Allow reminders, quest updates and social alerts.';

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
  String get settingsHealthConnectSection => 'Health Connect';

  @override
  String get settingsHealthConnectOpen => 'Open Health Connect';

  @override
  String get settingsHealthConnectOpenBody =>
      'Review connected apps, data sources and Health Connect settings.';

  @override
  String get settingsHealthConnectPermissions => 'Manage permissions';

  @override
  String get settingsHealthConnectPermissionsBody =>
      'Grant access to steps, calories, weight, sleep and activity data.';

  @override
  String get settingsHealthConnectConnected => 'Connected';

  @override
  String get settingsHealthConnectNeedsAccess => 'Needs access';

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
  String get healthShowCachedData => 'Show saved data';

  @override
  String get healthOfflineNotice =>
      'Showing saved data — tap to set up Health Connect';

  @override
  String get homeOfflineBanner => 'You\'re offline — showing saved data';

  @override
  String get ktOfflineNotice =>
      'Showing saved data — tap to connect Kalorické Tabulky';

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
  String get sleepStageDeep => 'Deep';

  @override
  String get sleepStageLight => 'Light';

  @override
  String get sleepStageRem => 'REM';

  @override
  String get sleepStageAwake => 'Awake';

  @override
  String get sleepStagesTitle => 'Sleep stages';

  @override
  String get sleepStagesBreakdown => 'Stage breakdown';

  @override
  String get sleepDurationTrend => 'Sleep duration trend';

  @override
  String get sleepDeepTrend => 'Deep sleep';

  @override
  String get sleepRemTrend => 'REM sleep';

  @override
  String get sleepNoStageData => 'Stage data is unavailable';

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
  String get homeActivityClaimsHeader => 'Claim XP per workout';

  @override
  String activitiesBackfillClaimAll(int xp) {
    return 'Claim all · +$xp XP';
  }

  @override
  String activitiesBackfillClaimedToast(int count, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Claimed $count workouts · +$xp XP',
      one: 'Claimed $count workout · +$xp XP',
    );
    return '$_temp0';
  }

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
  String get activityDetailTitle => 'Activity detail';

  @override
  String get activityDetailStart => 'Start';

  @override
  String get activityDetailEnd => 'End';

  @override
  String get activityDetailPace => 'Pace';

  @override
  String get activityDetailDistance => 'Distance';

  @override
  String get activityDetailComparison => 'Comparison';

  @override
  String get activityDetailNoMap => 'GPS data unavailable';

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
  String get goalDailyFiber => 'Daily fiber';

  @override
  String settingsGoalsNutritionSummary(
      String kcal, String protein, String fat, String carbs, String fiber) {
    return '$kcal kcal · ${protein}P / ${fat}F / ${carbs}C / ${fiber}Fi g';
  }

  @override
  String get settingsGoalsMacroBreakdownLabel => 'Calories from macros';

  @override
  String settingsGoalsMacroBreakdownMismatch(int delta) {
    String _temp0 = intl.Intl.pluralLogic(
      delta,
      locale: localeName,
      other: '$delta kcal off',
      zero: 'matches',
    );
    return 'Doesn\'t match calorie goal ($_temp0)';
  }

  @override
  String get settingsGoalsActivityHeader => 'Activity';

  @override
  String get settingsGoalsNutritionHeader => 'Nutrition';

  @override
  String get settingsGoalsSleepHeader => 'Sleep';

  @override
  String get settingsGoalsBodyHeader => 'Body';

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
  String get exportErrorSignInCancelled =>
      'Google sign-in was cancelled. Please sign in to export.';

  @override
  String get exportErrorNetwork =>
      'No internet connection. Check your network and try again.';

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
      'Active quests first, completed ones below.';

  @override
  String get questsScreenEyebrow => 'QUESTS';

  @override
  String get questsScreenTitle => 'Your quests and rewards';

  @override
  String get progQuestsActiveHeader => 'ACTIVE QUESTS';

  @override
  String progQuestsActiveCount(int count) {
    return '$count active';
  }

  @override
  String get progQuestsDailyGoalsHeader => 'DAILY GOALS';

  @override
  String get progQuestsDailyTasksHeader => 'DAILY TASKS';

  @override
  String get progQuestsDailyTasksHint =>
      'Tasks rotate every day — completed ones stay visible until midnight.';

  @override
  String get progQuestsDailyComboHeader => 'TODAY\'S COMBO';

  @override
  String get progQuestsWeeklyHeader => 'THIS WEEK';

  @override
  String get progQuestsChapterHeader => 'JOURNEY CHAPTERS';

  @override
  String get progQuestsComboHeader => 'DAILY COMBO';

  @override
  String get progQuestsDailyChallengeHeader => 'DAILY QUEST';

  @override
  String get progQuestsChapterSideQuestsHeader => 'CHAPTER SIDE QUESTS';

  @override
  String get progSidePilgrimMorningWalkTitle => 'Pilgrim\'s morning walk';

  @override
  String get progSidePilgrimMorningWalkDesc =>
      'Set out on the path right after waking — meet today\'s steps and activity goals.';

  @override
  String get progSidePilgrimQuietRestTitle => 'Pilgrim\'s quiet rest';

  @override
  String get progSidePilgrimQuietRestDesc =>
      'A pilgrim\'s body needs rest — meet today\'s sleep and protein goals.';

  @override
  String get progSideForestBriskwalkTitle => 'Brisk walk through the woods';

  @override
  String get progSideForestBriskwalkDesc =>
      'The forest rewards steady movement — finish today\'s steps and active minutes.';

  @override
  String get progSideForestCampTitle => 'Camp beneath the trees';

  @override
  String get progSideForestCampDesc =>
      'Quiet night in the woods — meet today\'s sleep, protein and calorie goals.';

  @override
  String get progSideForestClearingTitle => 'Clearing at first light';

  @override
  String get progSideForestClearingDesc =>
      'The clearing tests every angle — finish today\'s steps, activity, sleep and protein.';

  @override
  String get progSideMineDeepShaftTitle => 'Deep shaft';

  @override
  String get progSideMineDeepShaftDesc =>
      'A day spent in the deep — finish today\'s steps, activity and sleep.';

  @override
  String get progSideMineForgeFinaleTitle => 'Forge at the mountain\'s core';

  @override
  String get progSideMineForgeFinaleDesc =>
      'The forge fires only for complete crews — meet five daily goals today, food included.';

  @override
  String get progSidePactMarchTitle => 'Pact march';

  @override
  String get progSidePactMarchDesc =>
      'The pact marches all day — meet four basics today (steps, activity, sleep, calories).';

  @override
  String get progSidePactFinaleTitle => 'Seal of the pact';

  @override
  String get progSidePactFinaleDesc =>
      'The pact peaks in a perfect blend — meet six different daily goals today.';

  @override
  String get progSideRuinsSteadyDawnTitle => 'Steady dawn';

  @override
  String get progSideRuinsSteadyDawnDesc =>
      'Discipline starts at sunrise — finish today\'s steps, sleep and protein.';

  @override
  String get progSideRuinsIronIntakeTitle => 'Iron intake';

  @override
  String get progSideRuinsIronIntakeDesc =>
      'Three macros before dusk — meet any three of today\'s nutrition goals.';

  @override
  String get progSideMineTorchbearerTitle => 'Torchbearer';

  @override
  String get progSideMineTorchbearerDesc =>
      'Open a new shaft — finish today\'s steps and active minutes.';

  @override
  String get progSideMineLongHaulTitle => 'Long haul';

  @override
  String get progSideMineLongHaulDesc =>
      'Stay deep all day — finish today\'s steps, activity and sleep.';

  @override
  String get progSideForgeMorningAnvilTitle => 'Morning anvil';

  @override
  String get progSideForgeMorningAnvilDesc =>
      'Heat the forge before noon — finish today\'s steps and active minutes.';

  @override
  String get progSideForgeFullFurnaceTitle => 'Full furnace';

  @override
  String get progSideForgeFullFurnaceDesc =>
      'Feed the fire from every side — meet four of today\'s nutrition goals.';

  @override
  String get progSideUnderwayWarmCampTitle => 'Warm camp';

  @override
  String get progSideUnderwayWarmCampDesc =>
      'The party needs strength — meet today\'s sleep, protein and calorie goals.';

  @override
  String get progSideUnderwayLongWatchTitle => 'Long watch';

  @override
  String get progSideUnderwayLongWatchDesc =>
      'Hold the pace into the night — finish today\'s steps, activity and sleep.';

  @override
  String get progSideFrostboundFirstLightTitle => 'First light of the oath';

  @override
  String get progSideFrostboundFirstLightDesc =>
      'Move before the frost swallows your tracks — finish today\'s steps and active minutes.';

  @override
  String get progSideFrostboundLongOathTitle => 'Long oath';

  @override
  String get progSideFrostboundLongOathDesc =>
      'Frost tests the whole body — finish today\'s steps, sleep, protein and calories.';

  @override
  String get progSideIcewalkerDawnMarchTitle => 'Dawn march';

  @override
  String get progSideIcewalkerDawnMarchDesc =>
      'Ice is walked early — finish today\'s steps, activity and calories.';

  @override
  String get progSideIcewalkerProvisionerTitle => 'Provisioner';

  @override
  String get progSideIcewalkerProvisionerDesc =>
      'The caravan eats complete — meet all five of today\'s nutrition goals.';

  @override
  String get progSideMountainSteepMorningTitle => 'Steep morning';

  @override
  String get progSideMountainSteepMorningDesc =>
      'The ridge isn\'t climbed at noon — finish today\'s steps, activity and sleep.';

  @override
  String get progSideMountainFullRidgeTitle => 'Full ridge';

  @override
  String get progSideMountainFullRidgeDesc =>
      'The summit demands the whole of you — finish today\'s steps, activity, sleep, protein and calories.';

  @override
  String get progSideDragonroadWardenDawnTitle => 'Warden\'s dawn';

  @override
  String get progSideDragonroadWardenDawnDesc =>
      'The dragon road tests discipline — meet four basics today (steps, activity, calories, protein).';

  @override
  String get progSideDragonroadIronAppetiteTitle => 'Dragon\'s appetite';

  @override
  String get progSideDragonroadIronAppetiteDesc =>
      'The dragon eats five courses — meet all five nutrition goals today.';

  @override
  String get progSideDragonrockSovereignDawnTitle => 'Sovereign\'s dawn';

  @override
  String get progSideDragonrockSovereignDawnDesc =>
      'A sovereign never starves — finish today\'s steps and all four macro goals.';

  @override
  String get progSideDragonrockSovereignVigilTitle => 'Sovereign\'s vigil';

  @override
  String get progSideDragonrockSovereignVigilDesc =>
      'Tend the whole kingdom of yourself — meet six of today\'s eight daily goals.';

  @override
  String get progSideIcewalkerFinaleTitle => 'Crew complete';

  @override
  String get progSideIcewalkerFinaleDesc =>
      'The caravan stands tall no matter the cold — meet six different daily goals today.';

  @override
  String get progSideDragonroadFinaleTitle => 'Dragon\'s banquet';

  @override
  String get progSideDragonroadFinaleDesc =>
      'The dragon demands a full table — meet seven of today\'s eight daily goals.';

  @override
  String get progSideDragonrockSovereignThroneTitle => 'Throne of Dragonrock';

  @override
  String get progSideDragonrockSovereignThroneDesc =>
      'Your throne does not yield — meet seven daily goals today, all four macros included.';

  @override
  String get progSideDragonrockSovereignCrownTitle => 'Unbroken crown';

  @override
  String get progSideDragonrockSovereignCrownDesc =>
      'An almost-perfect day — meet seven of today\'s eight daily goals and hold the pace till evening.';

  @override
  String get progSideDragonrockSovereignFinaleTitle =>
      'Sovereign\'s perfect day';

  @override
  String get progSideDragonrockSovereignFinaleDesc =>
      'The summit of the journey — meet all eight of today\'s daily goals. Bonus for 7+ h sleep and for finishing before 18:00.';

  @override
  String get progDailyChallengeNutriTripleTitle => 'Triple nutrition win';

  @override
  String get progDailyChallengeNutriTripleDesc =>
      'Meet today\'s goal on 3 of 5 nutrition macros (calories, protein, carbs, fat, fiber).';

  @override
  String get progDailyChallengeActiveDayTitle => 'Active day';

  @override
  String get progDailyChallengeActiveDayDesc =>
      'Meet today\'s steps and activity goals.';

  @override
  String get progDailyChallengeFullPlateTitle => 'Full plate';

  @override
  String get progDailyChallengeFullPlateDesc =>
      'Meet today\'s goal on all 5 nutrition macros.';

  @override
  String get progDailyChallengeRecoveryTitle => 'Recovery day';

  @override
  String get progDailyChallengeRecoveryDesc =>
      'Meet today\'s sleep and protein goals — give the body a break.';

  @override
  String get progDailyChallengeTripleComboTitle => 'Triple combo';

  @override
  String get progDailyChallengeTripleComboDesc =>
      'Meet today\'s steps, sleep and protein goals.';

  @override
  String get progDailyChallengeBalancedTitle => 'Balanced day';

  @override
  String get progDailyChallengeBalancedDesc =>
      'Meet any 4 of today\'s 8 daily goals.';

  @override
  String get progQuestsLongTermHeader => 'LONG-TERM GOALS';

  @override
  String get progQuestsLongTermAlsoUnlocks => 'Also unlocks';

  @override
  String get progQuestNextStep => 'Next step';

  @override
  String get progQuestNextStepLocked =>
      'Complete the previous step to unlock the next one';

  @override
  String get progQuestChainFinaleReward => 'Chapter finale reward';

  @override
  String get cosmeticTypeFrame => 'Frame';

  @override
  String get cosmeticTypeRelic => 'Relic';

  @override
  String get cosmeticTypeBackground => 'Background';

  @override
  String get cosmeticTypeEmblem => 'Emblem';

  @override
  String get cosmeticTypeCompanion => 'Companion';

  @override
  String get cosmeticTypeTitleFlair => 'Title';

  @override
  String get cosmeticTypeMapEffect => 'Map effect';

  @override
  String get progQuestsChapterWaitingHeader => 'UPCOMING CHAPTERS';

  @override
  String get progQuestsChapterWaitingTitle => 'Chapter unlocked';

  @override
  String get progQuestsChapterWaitingCaption =>
      'Complete the previous chapter to begin.';

  @override
  String get progQuestsLockedHeader => 'LOCKED';

  @override
  String get progQuestsCompletedHeader => 'COMPLETED QUESTS';

  @override
  String progQuestsCompletedCount(int count) {
    return '$count completed';
  }

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
  String get progBackfillSectionLabel => 'Reward history';

  @override
  String get progBackfillEmptyTitle => 'Nothing logged yet';

  @override
  String get progBackfillEmptyCaption =>
      'Once you start logging steps, sleep or workouts, your daily rewards will show up here.';

  @override
  String progBackfillPendingChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to claim',
      one: '$count to claim',
    );
    return '$_temp0';
  }

  @override
  String get progBackfillDayHeaderToday => 'Today';

  @override
  String get progBackfillDayHeaderYesterday => 'Yesterday';

  @override
  String get progBackfillGroupThisWeek => 'This week';

  @override
  String get progBackfillGroupLastWeek => 'Last week';

  @override
  String progBackfillGroupWeeksAgo(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String get progBackfillGroupMonthAgo => 'A month ago';

  @override
  String progBackfillGroupMonthsAgo(int months) {
    return '$months months ago';
  }

  @override
  String progBackfillClaimAllDay(int xp) {
    return 'Claim all · +$xp XP';
  }

  @override
  String progBackfillClaimedToast(int count, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Claimed $count rewards · +$xp XP',
      one: 'Claimed $count reward · +$xp XP',
    );
    return '$_temp0';
  }

  @override
  String progBackfillShowMore(int count) {
    return 'Show $count more days';
  }

  @override
  String progBackfillShowAllSinceJoin(String date) {
    return 'Show all since $date';
  }

  @override
  String get progBackfillGoalUnmet => 'Not met';

  @override
  String get progBackfillGoalNoData => 'No data';

  @override
  String get progDailyQuestCompletedTodayBadge =>
      'Done for today · returns tomorrow';

  @override
  String get progBackfillDayGoalsLabel => 'Goals';

  @override
  String get progBackfillDayQuestsLabel => 'Quests';

  @override
  String get progBackfillDayActivitiesLabel => 'Workouts';

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
  String get progQuestDetailGoal => 'Goal';

  @override
  String get progQuestDetailNextInChain => 'Next in chain';

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
  String progXpFlatDetail(int xp) {
    return 'Reward: +$xp XP';
  }

  @override
  String progXpScalingDetail(int baseXp, int previewXp) {
    return 'Reward: +$baseXp XP base · scaled to +$previewXp XP at your level';
  }

  @override
  String progStreakBestDetail(int days) {
    return 'Best streak: $days days';
  }

  @override
  String progChapterLockedLabel(int level) {
    return 'Lv $level';
  }

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
  String get progRuleDailyStepsDesc =>
      'Reach the configured daily steps target.';

  @override
  String get progRuleDailyStepsHintedDesc =>
      'Reach the configured daily steps target.';

  @override
  String get progRuleDailyCaloriesHintedDesc =>
      'Reach the configured daily calories target.';

  @override
  String get progRuleDailyActivityHintedDesc =>
      'Reach the configured weekly activity-minutes target.';

  @override
  String progBonusXpBeforeHour(int xp, int hour) {
    return '+$xp XP bonus if you claim before $hour:00';
  }

  @override
  String progBonusXpSleepAtLeast(int xp, int minutes) {
    return '+$xp XP bonus if you slept at least $minutes min';
  }

  @override
  String get progBonusXpLabel => 'Bonus XP';

  @override
  String get progRuleDailyCalories => 'Calorie Target';

  @override
  String get progRuleDailyCaloriesDesc =>
      'Stay within the default 10% calorie target window.';

  @override
  String get progRuleDailyProtein => 'Protein Target';

  @override
  String get progRuleDailyProteinDesc =>
      'Reach the configured daily protein target.';

  @override
  String get progRuleDailyCarbs => 'Carb Target';

  @override
  String get progRuleDailyCarbsDesc =>
      'Reach the configured daily carbohydrate target.';

  @override
  String get progRuleDailyFat => 'Fat Target';

  @override
  String get progRuleDailyFatDesc => 'Reach the configured daily fat target.';

  @override
  String get progRuleDailyFiber => 'Fiber Target';

  @override
  String get progRuleDailyFiberDesc =>
      'Reach the configured daily fiber target.';

  @override
  String get progRuleDailySleep => 'Sleep Target';

  @override
  String get progRuleDailySleepDesc =>
      'Reach the configured nightly sleep duration target.';

  @override
  String get progRuleWeeklyActivity => 'Weekly Activity';

  @override
  String get progRuleWeeklyActivityDesc =>
      'Accumulate the configured weekly activity minutes.';

  @override
  String get progRuleDailyWeightLog => 'Weight Log';

  @override
  String get progRuleDailyWeightLogDesc =>
      'Log your weight at least once today.';

  @override
  String get progRuleDailyWeightGoal => 'Weight Goal';

  @override
  String get progRuleDailyWeightGoalDesc =>
      'Log a weight within 3% of your target weight.';

  @override
  String progRewardDetailWeightLogged(String actual) {
    return 'Logged: $actual kg';
  }

  @override
  String get progQuestFallbackTitle => 'Quest';

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
  String get progQuestComboInitiate10Title => 'Combo Initiate';

  @override
  String get progQuestComboInitiate10Desc =>
      'Complete 10 combo quests of any kind.';

  @override
  String get progQuestDailyNutritionComboTodayTitle => 'Nutrition Combo';

  @override
  String get progQuestDailyNutritionComboTodayDesc =>
      'Complete both calorie and protein goals in the current day.';

  @override
  String get progQuestDailyNutritionCarbsComboTodayTitle => 'Macro Trio';

  @override
  String get progQuestDailyNutritionCarbsComboTodayDesc =>
      'Complete calorie, protein, and carb goals in the current day.';

  @override
  String get progQuestDailyNutritionFatComboTodayTitle => 'Macro Quartet';

  @override
  String get progQuestDailyNutritionFatComboTodayDesc =>
      'Complete calorie, protein, carb, and fat goals in the current day.';

  @override
  String get progQuestDailyNutritionFiberComboTodayTitle => 'Full Plate Combo';

  @override
  String get progQuestDailyNutritionFiberComboTodayDesc =>
      'Complete calorie, protein, carb, fat, and fiber goals in the current day.';

  @override
  String get progQuestNutritionRhythm3Title => 'Balanced Rhythm';

  @override
  String get progQuestNutritionRhythm3Desc =>
      'Earn at least one nutrition reward for 3 periods in a row.';

  @override
  String get progQuestDailyRecoveryFocusTodayTitle => 'Recovery Focus';

  @override
  String get progQuestDailyRecoveryFocusTodayDesc =>
      'Complete both steps and sleep goals in the current day.';

  @override
  String get progComboBalancedStep1Title => 'Balanced day · 1 goal';

  @override
  String get progComboBalancedStep1Desc => 'Complete any 1 daily goal today.';

  @override
  String get progComboBalancedStep2Title => 'Balanced day · 2 goals';

  @override
  String get progComboBalancedStep2Desc => 'Complete any 2 daily goals today.';

  @override
  String get progComboBalancedStep3Title => 'Balanced day · 3 goals';

  @override
  String get progComboBalancedStep3Desc => 'Complete any 3 daily goals today.';

  @override
  String get progComboBalancedFinaleTitle => 'Balanced day · finale';

  @override
  String get progComboBalancedFinaleDesc => 'Complete any 4 daily goals today.';

  @override
  String get progComboRecoveryStep1Title => 'Recovery · sleep';

  @override
  String get progComboRecoveryStep1Desc => 'Meet today\'s sleep goal.';

  @override
  String get progComboRecoveryStep2Title => 'Recovery · sleep + steps';

  @override
  String get progComboRecoveryStep2Desc =>
      'Meet today\'s sleep and steps goals.';

  @override
  String get progComboRecoveryStep3Title =>
      'Recovery · sleep + steps + protein';

  @override
  String get progComboRecoveryStep3Desc =>
      'Meet today\'s sleep, steps and protein goals.';

  @override
  String get progComboRecoveryFinaleTitle => 'Recovery · finale';

  @override
  String get progComboRecoveryFinaleDesc =>
      'Meet today\'s sleep, steps, protein and calories goals.';

  @override
  String get progComboNutritionStep1Title => 'Nutrition master · calories';

  @override
  String get progComboNutritionStep1Desc => 'Meet today\'s calorie goal.';

  @override
  String get progComboNutritionStep2Title => 'Nutrition master · + protein';

  @override
  String get progComboNutritionStep2Desc =>
      'Meet today\'s calorie and protein goals.';

  @override
  String get progComboNutritionStep3Title => 'Nutrition master · + carbs';

  @override
  String get progComboNutritionStep3Desc =>
      'Meet today\'s calorie, protein and carb goals.';

  @override
  String get progComboNutritionStep4Title => 'Nutrition master · + fat';

  @override
  String get progComboNutritionStep4Desc =>
      'Meet today\'s calorie, protein, carb and fat goals.';

  @override
  String get progComboNutritionFinaleTitle => 'Nutrition master · finale';

  @override
  String get progComboNutritionFinaleDesc =>
      'Meet all macro goals today: calories, protein, carbs, fat and fiber.';

  @override
  String get progQuestSleepTotal250hTitle => 'Rested Soul';

  @override
  String get progQuestSleepTotal250hDesc =>
      'Accumulate 250 hours of tracked sleep.';

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
  String get progQuestDailyCarbsTodayTitle => 'Today\'s Carb Goal';

  @override
  String get progQuestDailyCarbsTodayDesc =>
      'Complete the daily carb rule in the current day.';

  @override
  String get progQuestDailyFatTodayTitle => 'Today\'s Fat Goal';

  @override
  String get progQuestDailyFatTodayDesc =>
      'Complete the daily fat rule in the current day.';

  @override
  String get progQuestDailyFiberTodayTitle => 'Today\'s Fiber Goal';

  @override
  String get progQuestDailyFiberTodayDesc =>
      'Complete the daily fiber rule in the current day.';

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
  String get progQuestReach25000XpTitle => 'Reach 25,000 XP';

  @override
  String get progQuestReach25000XpDesc => 'Accumulate at least 25,000 XP.';

  @override
  String get progQuestReach100000XpTitle => 'Reach 100,000 XP';

  @override
  String get progQuestReach100000XpDesc => 'Accumulate at least 100,000 XP.';

  @override
  String get progQuestReach1000000XpTitle => 'Reach 1,000,000 XP';

  @override
  String get progQuestReach1000000XpDesc => 'Accumulate at least 1,000,000 XP.';

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
  String get progQuestEarn250RewardsTitle => 'Earn 250 Rewards';

  @override
  String get progQuestEarn250RewardsDesc =>
      'Collect 250 progression rewards in total.';

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
  String get progQuestNutritionRewards100Title => 'Macro Legend';

  @override
  String get progQuestNutritionRewards100Desc => 'Earn 100 nutrition rewards.';

  @override
  String get progQuestTotalSteps100kTitle => 'Walk 100K Steps';

  @override
  String get progQuestTotalSteps100kDesc => 'Accumulate 100,000 total steps.';

  @override
  String get progQuestTotalSteps500kTitle => 'Walk 500K Steps';

  @override
  String get progQuestTotalSteps500kDesc => 'Accumulate 500,000 total steps.';

  @override
  String get progQuestTotalSteps1mTitle => 'Walk 1M Steps';

  @override
  String get progQuestTotalSteps1mDesc => 'Accumulate 1,000,000 total steps.';

  @override
  String get progQuestTotalSteps5mTitle => 'Walk 5M Steps';

  @override
  String get progQuestTotalSteps5mDesc => 'Accumulate 5,000,000 total steps.';

  @override
  String get progQuestTotalSteps10mTitle => 'Walk 10M Steps';

  @override
  String get progQuestTotalSteps10mDesc => 'Accumulate 10,000,000 total steps.';

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
  String get progQuestWeeklyActivity24Title => 'Unbroken Momentum';

  @override
  String get progQuestWeeklyActivity24Desc =>
      'Complete the weekly activity rule 24 times.';

  @override
  String get progQuestWeeklyActivity52Title => 'Yearlong Engine';

  @override
  String get progQuestWeeklyActivity52Desc =>
      'Complete the weekly activity rule 52 times.';

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
  String get progQuestStepsStreak30Title => 'Step Sovereign';

  @override
  String get progQuestStepsStreak30Desc =>
      'Complete the daily steps rule 30 periods in a row.';

  @override
  String get progQuestStepsStreak50Title => 'Iron Resolve';

  @override
  String get progQuestStepsStreak50Desc =>
      'Complete the daily steps rule 50 periods in a row.';

  @override
  String get progQuestStepsStreak100Title => 'Iron Chain';

  @override
  String get progQuestStepsStreak100Desc =>
      'Complete the daily steps rule 100 periods in a row.';

  @override
  String get progQuestSourceJourney => 'Journey';

  @override
  String get progQuestSourceDailyCombo => 'Daily Combo';

  @override
  String get progQuestSourceNutrition => 'Nutrition';

  @override
  String get progQuestSourceRecovery => 'Recovery';

  @override
  String get progQuestSourceDailyGoal => 'Daily Goal';

  @override
  String get progQuestSourceSteps => 'Steps';

  @override
  String get progQuestSourceStepChain => 'Step Chain';

  @override
  String get progQuestSourceWeekly => 'Weekly';

  @override
  String get progQuestChainStepSteps => 'Steps';

  @override
  String get progQuestChainStepKcal => 'Kcal';

  @override
  String get progQuestChainStepProtein => 'Protein';

  @override
  String get progQuestChainStepCarbs => 'Carbs';

  @override
  String get progQuestChainStepFat => 'Fat';

  @override
  String get progQuestChainStepFiber => 'Fiber';

  @override
  String get progQuestChainStepSleep => 'Sleep';

  @override
  String get progQuestChainStepBadge => 'Badge';

  @override
  String get progQuestChainStepStart => 'Start';

  @override
  String get progQuestChainStepEmblem => 'Emblem';

  @override
  String get progQuestSourceForestTrial => 'Forest Trial';

  @override
  String get progQuestSourceRuinsDiscipline => 'Ruins of Discipline';

  @override
  String get progQuestSourceMineDescent => 'Mine Descent';

  @override
  String get progQuestSourceForgeMomentum => 'Forge of Momentum';

  @override
  String get progQuestSourceUnderwayPact => 'Underway Pact';

  @override
  String get progQuestSourceFrostboundOath => 'Frostbound Oath';

  @override
  String get progQuestSourceIcewalkerRoute => 'Icewalker’s Route';

  @override
  String get progQuestSourceMountainAscent => 'Mountain Ascent';

  @override
  String get progQuestSourceDragonroad => 'Dragonroad';

  @override
  String get progQuestSourceDragonrockSovereign => 'Dragonrock Sovereign';

  @override
  String get progQuestPilgrimPathOpenTitle => 'Pilgrim\'s Path';

  @override
  String get progQuestPilgrimPathOpenDesc =>
      'Set out on your journey — your first chapter begins here.';

  @override
  String get progQuestPilgrimPathFirstStepsTitle => 'First steps';

  @override
  String get progQuestPilgrimPathFirstStepsDesc =>
      'Complete the daily steps goal and start walking the path.';

  @override
  String get progQuestPilgrimPathFirstSleepTitle => 'First rest';

  @override
  String get progQuestPilgrimPathFirstSleepDesc =>
      'Complete the daily sleep goal and recover for the road ahead.';

  @override
  String get progQuestPilgrimPathFirstRewardTitle => 'Provisions for the road';

  @override
  String get progQuestPilgrimPathFirstRewardDesc =>
      'Strength fuels the path into the deep forest — hit today\'s protein goal.';

  @override
  String get progQuestPilgrimPathFinaleTitle => 'Pilgrim\'s Mark';

  @override
  String get progQuestPilgrimPathFinaleDesc =>
      'Walk, rest, gather provisions — then claim the Pilgrim\'s Mark.';

  @override
  String get progQuestForestTrialOpenTitle => 'Forest Trial';

  @override
  String get progQuestForestTrialOpenDesc =>
      'Start the Forest Trial after reaching level 10.';

  @override
  String get progQuestForestTrialDailyWins5Title => 'Trail Rhythm';

  @override
  String get progQuestForestTrialDailyWins5Desc =>
      'On the Forest Trail, complete at least 2 daily goals on 5 different days.';

  @override
  String get progQuestForestTrialSteps5Title => 'Five Days on the Path';

  @override
  String get progQuestForestTrialSteps5Desc =>
      'On the Forest Trail, complete your step goal 5 times.';

  @override
  String get progQuestForestTrialRecovery3Title => 'Rest Beneath the Trees';

  @override
  String get progQuestForestTrialRecovery3Desc =>
      'On the Forest Trail, complete your step and sleep goals on the same day 3 times.';

  @override
  String get progQuestForestTrialFinaleTitle => 'Forest Trial Complete';

  @override
  String get progQuestForestTrialFinaleDesc =>
      'Complete the previous Forest Trial quests.';

  @override
  String get progQuestRuinsDisciplineOpenTitle => 'Ruins of Discipline';

  @override
  String get progQuestRuinsDisciplineOpenDesc =>
      'Start the Ruins of Discipline after reaching level 20.';

  @override
  String get progQuestRuinsDisciplineNutrition7Title => 'Ancient Ration';

  @override
  String get progQuestRuinsDisciplineNutrition7Desc =>
      'In the Ruins of Discipline, complete your calorie and protein goals together 7 times.';

  @override
  String get progQuestRuinsDisciplineWeekly2Title => 'Weekly Offering';

  @override
  String get progQuestRuinsDisciplineWeekly2Desc =>
      'In the Ruins of Discipline, complete the weekly activity goal 2 times.';

  @override
  String get progQuestRuinsDisciplineSteps10Title => 'Ten-Day Resolve';

  @override
  String get progQuestRuinsDisciplineSteps10Desc =>
      'In the Ruins of Discipline, complete your step goal 10 times.';

  @override
  String get progQuestRuinsDisciplineFinaleTitle => 'Ruins Trial Complete';

  @override
  String get progQuestRuinsDisciplineFinaleDesc =>
      'Complete the previous Ruins of Discipline quests.';

  @override
  String get progQuestMineDescentOpenTitle => 'Mine Descent';

  @override
  String get progQuestMineDescentOpenDesc =>
      'Start the Mine Descent after reaching level 30.';

  @override
  String get progQuestMineDescentSteps250kTitle => 'Deep Roads';

  @override
  String get progQuestMineDescentSteps250kDesc =>
      'During the Mine Descent, walk 250,000 steps.';

  @override
  String get progQuestMineDescentActivityRewards12Title => 'Work Orders';

  @override
  String get progQuestMineDescentActivityRewards12Desc =>
      'During the Mine Descent, claim 12 activity-related rewards.';

  @override
  String get progQuestMineDescentProtein10Title => 'Iron Rations';

  @override
  String get progQuestMineDescentProtein10Desc =>
      'During the Mine Descent, complete your protein goal 10 times.';

  @override
  String get progQuestMineDescentFinaleTitle => 'Mine Trial Complete';

  @override
  String get progQuestMineDescentFinaleDesc =>
      'Complete the previous Mine Descent quests.';

  @override
  String get progQuestForgeMomentumOpenTitle => 'Forge of Momentum';

  @override
  String get progQuestForgeMomentumOpenDesc =>
      'Start the Forge of Momentum after reaching level 40.';

  @override
  String get progQuestForgeMomentumWeekly4Title => 'Heat the Forge';

  @override
  String get progQuestForgeMomentumWeekly4Desc =>
      'At the Forge of Momentum, complete the weekly activity goal 4 times.';

  @override
  String get progQuestForgeMomentumSteps20Title => 'Hammer Steps';

  @override
  String get progQuestForgeMomentumSteps20Desc =>
      'At the Forge of Momentum, complete the step goal 20 times.';

  @override
  String get progQuestForgeMomentumNutrition15Title => 'Fuel the Flame';

  @override
  String get progQuestForgeMomentumNutrition15Desc =>
      'At the Forge of Momentum, complete your calorie and protein goals together 15 times.';

  @override
  String get progQuestForgeMomentumFinaleTitle => 'Forge Trial Complete';

  @override
  String get progQuestForgeMomentumFinaleDesc =>
      'Complete the previous Forge of Momentum quests.';

  @override
  String get progQuestUnderwayPactOpenTitle => 'Underway Pact';

  @override
  String get progQuestUnderwayPactOpenDesc =>
      'Start the Underway Pact after reaching level 50.';

  @override
  String get progQuestUnderwayPactFourPillars5Title => 'Four Pillars Below';

  @override
  String get progQuestUnderwayPactFourPillars5Desc =>
      'In the Underway Pact, complete all 4 daily goals 5 times.';

  @override
  String get progQuestUnderwayPactSleep14Title => 'Deep Rest';

  @override
  String get progQuestUnderwayPactSleep14Desc =>
      'In the Underway Pact, complete your sleep goal 14 times.';

  @override
  String get progQuestUnderwayPactRecovery10Title => 'Stonebound Recovery';

  @override
  String get progQuestUnderwayPactRecovery10Desc =>
      'In the Underway Pact, complete your step and sleep goals on the same day 10 times.';

  @override
  String get progQuestUnderwayPactFinaleTitle => 'Underway Trial Complete';

  @override
  String get progQuestUnderwayPactFinaleDesc =>
      'Complete the previous Underway Pact quests.';

  @override
  String get progQuestFrostboundOathOpenTitle => 'Frostbound Oath';

  @override
  String get progQuestFrostboundOathOpenDesc =>
      'Start the Frostbound Oath after reaching level 60.';

  @override
  String get progQuestFrostboundOathSteps21Title => 'Frozen Resolve';

  @override
  String get progQuestFrostboundOathSteps21Desc =>
      'Under the Frostbound Oath, complete your step goal 21 times.';

  @override
  String get progQuestFrostboundOathSleep21Title => 'Shelter in the Snow';

  @override
  String get progQuestFrostboundOathSleep21Desc =>
      'Under the Frostbound Oath, complete your sleep goal 21 times.';

  @override
  String get progQuestFrostboundOathWeekly6Title => 'Cold March';

  @override
  String get progQuestFrostboundOathWeekly6Desc =>
      'Under the Frostbound Oath, complete the weekly activity goal 6 times.';

  @override
  String get progQuestFrostboundOathFinaleTitle => 'Frost Trial Complete';

  @override
  String get progQuestFrostboundOathFinaleDesc =>
      'Complete the previous Frostbound Oath quests.';

  @override
  String get progQuestIcewalkerRouteOpenTitle => 'Icewalker’s Route';

  @override
  String get progQuestIcewalkerRouteOpenDesc =>
      'Start Icewalker’s Route after reaching level 70.';

  @override
  String get progQuestIcewalkerRouteSteps500kTitle => 'Across White Plains';

  @override
  String get progQuestIcewalkerRouteSteps500kDesc =>
      'On Icewalker’s Route, walk 500,000 steps.';

  @override
  String get progQuestIcewalkerRouteRewards150Title => 'Traces in Ice';

  @override
  String get progQuestIcewalkerRouteRewards150Desc =>
      'On Icewalker’s Route, claim 150 rewards.';

  @override
  String get progQuestIcewalkerRouteProtein30Title => 'Winter Rations';

  @override
  String get progQuestIcewalkerRouteProtein30Desc =>
      'On Icewalker’s Route, complete your protein goal 30 times.';

  @override
  String get progQuestIcewalkerRouteFinaleTitle => 'Ice Seal';

  @override
  String get progQuestIcewalkerRouteFinaleDesc =>
      'Complete the previous Icewalker’s Route quests.';

  @override
  String get progQuestMountainAscentOpenTitle => 'Mountain Ascent';

  @override
  String get progQuestMountainAscentOpenDesc =>
      'Start the Mountain Ascent after reaching level 80.';

  @override
  String get progQuestMountainAscentFourPillars15Title =>
      'Camp Above the Clouds';

  @override
  String get progQuestMountainAscentFourPillars15Desc =>
      'Above the clouds, complete all 4 daily goals 15 times.';

  @override
  String get progQuestMountainAscentSteps30Title => 'Unbroken Ascent';

  @override
  String get progQuestMountainAscentSteps30Desc =>
      'During the Mountain Ascent, complete your step goal 30 times.';

  @override
  String get progQuestMountainAscentWeekly10Title => 'Summit Routine';

  @override
  String get progQuestMountainAscentWeekly10Desc =>
      'During the Mountain Ascent, complete the weekly activity goal 10 times.';

  @override
  String get progQuestMountainAscentFinaleTitle => 'Summit Seal';

  @override
  String get progQuestMountainAscentFinaleDesc =>
      'Complete the previous Mountain Ascent quests.';

  @override
  String get progQuestDragonroadOpenTitle => 'Dragonroad';

  @override
  String get progQuestDragonroadOpenDesc =>
      'Unlock the Dragonroad by reaching level 90.';

  @override
  String get progQuestDragonroadRewards250Title => 'Scales of Effort';

  @override
  String get progQuestDragonroadRewards250Desc =>
      'During the Dragonroad, earn 250 rewards.';

  @override
  String get progQuestDragonroadFourPillars25Title => 'Dragon Discipline';

  @override
  String get progQuestDragonroadFourPillars25Desc =>
      'During the Dragonroad, complete all 4 daily goals 25 times.';

  @override
  String get progQuestDragonroadWeekly12Title => 'Path to the Fortress';

  @override
  String get progQuestDragonroadWeekly12Desc =>
      'During the Dragonroad, complete the weekly activity goal 12 times.';

  @override
  String get progQuestDragonroadFinaleTitle => 'Dragon Seal';

  @override
  String get progQuestDragonroadFinaleDesc =>
      'Complete the previous Dragonroad quests.';

  @override
  String get progQuestDragonrockSovereignOpenTitle => 'Dragonrock Sovereign';

  @override
  String get progQuestDragonrockSovereignOpenDesc =>
      'Claim Dragonrock sovereignty after reaching level 100.';

  @override
  String get progQuestDragonrockSovereignFourPillars30Title => 'Rule of Four';

  @override
  String get progQuestDragonrockSovereignFourPillars30Desc =>
      'Within Dragonrock Fortress, complete all 4 daily goals 30 times.';

  @override
  String get progQuestDragonrockSovereignWeekly16Title => 'Fortress Routine';

  @override
  String get progQuestDragonrockSovereignWeekly16Desc =>
      'Within Dragonrock Fortress, complete the weekly activity goal 16 times.';

  @override
  String get progQuestDragonrockSovereignSteps50Title => 'Royal March';

  @override
  String get progQuestDragonrockSovereignSteps50Desc =>
      'Within Dragonrock Fortress, complete your step goal 50 times.';

  @override
  String get progQuestDragonrockSovereignFinaleTitle => 'Dragonrock Seal';

  @override
  String get progQuestDragonrockSovereignFinaleDesc =>
      'Complete the previous Dragonrock Sovereign quests.';

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
  String get progAchievementSteps2500000Title => 'Highland Strider';

  @override
  String get progAchievementSteps2500000Desc =>
      'Accumulate 2,500,000 total steps.';

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
  String get progAchievementWeeklyActivity36Title => 'Aurora Season';

  @override
  String get progAchievementWeeklyActivity36Desc =>
      'Complete the weekly activity rule 36 times.';

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
  String get progAchievementDailyQuest3Title => 'First Steps';

  @override
  String get progAchievementDailyQuest3Desc => 'Complete 3 daily quests.';

  @override
  String get progAchievementDailyQuest7Title => 'Steady Hand';

  @override
  String get progAchievementDailyQuest7Desc => 'Complete 7 daily quests.';

  @override
  String get progAchievementQuestHunter250Title => 'Quest Hunter';

  @override
  String get progAchievementQuestHunter250Desc =>
      'Complete 250 quests in total.';

  @override
  String get progAchievementActiveDays7Title => 'A Week on the Road';

  @override
  String get progAchievementActiveDays7Desc => 'Be active for 7 days.';

  @override
  String get progAchievementActiveDays90Title => 'A Season on the Road';

  @override
  String get progAchievementActiveDays90Desc => 'Be active for 90 days.';

  @override
  String get progAchievementPerfectDays7Title => 'Balanced Week';

  @override
  String get progAchievementPerfectDays7Desc =>
      'Complete all daily goals on 7 different days.';

  @override
  String get progAchievementPerfectWeeks12Title => 'Master of Routine';

  @override
  String get progAchievementPerfectWeeks12Desc =>
      'Complete a perfect week 12 times.';

  @override
  String get progAchievementComboVictory10Title => 'Combo Initiate';

  @override
  String get progAchievementComboVictory10Desc =>
      'Complete 10 combo quests of any kind.';

  @override
  String get progAchievementComboTripleVictory25Title => 'Triple Threat';

  @override
  String get progAchievementComboTripleVictory25Desc =>
      'Complete 25 triple-or-better combo quests.';

  @override
  String get progAchievementComboTripleVictory100Title => 'Combo Sovereign';

  @override
  String get progAchievementComboTripleVictory100Desc =>
      'Complete 100 triple-or-better combo quests.';

  @override
  String get progAchievementDragonrockTrialTitle => 'Dragonrock Trial';

  @override
  String get progAchievementDragonrockTrialDesc =>
      'Reach level 100, complete 250 quests, and walk 10,000,000 steps.';

  @override
  String get progAchievementSummaryComposite => 'all conditions';

  @override
  String get progAchievementSummaryDailyQuests => 'daily quests';

  @override
  String get progAchievementSummaryWeeklyQuests => 'weekly quests';

  @override
  String get progAchievementSummaryTotalQuests => 'quests';

  @override
  String get progAchievementSummaryActiveDays => 'active days';

  @override
  String get progAchievementSummaryPerfectDays => 'perfect days';

  @override
  String get progAchievementSummaryPerfectWeeks => 'perfect weeks';

  @override
  String get progAchievementSummaryComboQuests => 'combo quests';

  @override
  String get progAchievementSummaryTripleComboQuests => 'triple combo quests';

  @override
  String get progAchievementDifficultyEasy => 'Easy';

  @override
  String get progAchievementDifficultyMedium => 'Medium';

  @override
  String get progAchievementDifficultyHard => 'Hard';

  @override
  String get progAchievementDifficultyExtraHard => 'Extra Hard';

  @override
  String get progAchievementDifficultyMythic => 'Impossible';

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
  String get cosmeticFramePilgrimName => 'Pilgrim\'s Frame';

  @override
  String get cosmeticFramePilgrimDesc =>
      'A plain wooden frame for anyone who set out on the road.';

  @override
  String get cosmeticFrameWildwoodName => 'Wildwood Frame';

  @override
  String get cosmeticFrameWildwoodDesc =>
      'Dark wood and subtle forest carvings for those who learned to read the paths of the wildwood.';

  @override
  String get cosmeticFrameRuinsName => 'Ruins Frame';

  @override
  String get cosmeticFrameRuinsDesc =>
      'Cracked stonework and creeping moss recall the silent ruins on the edge of the pass.';

  @override
  String get cosmeticFrameDwarvenName => 'Old Gates Frame';

  @override
  String get cosmeticFrameDwarvenDesc =>
      'Weathered stone and aged bronze from the pass where the trail gives way to ruins.';

  @override
  String get cosmeticFrameUnderwaysName => 'Dwarven Frame';

  @override
  String get cosmeticFrameUnderwaysDesc =>
      'A sturdy frame of forged metal and mine stone, crafted in the depths of dwarven halls.';

  @override
  String get cosmeticFrameFrostName => 'Frost Frame';

  @override
  String get cosmeticFrameFrostDesc =>
      'A cold silver frame with an icy sheen, born in the silence of the frozen lands.';

  @override
  String get cosmeticFrameMountainName => 'Mountain Challenger\'s Frame';

  @override
  String get cosmeticFrameMountainDesc =>
      'Dark mountain stone and blackened steel for those who climbed toward the fortress path.';

  @override
  String get cosmeticFrameDragonrockName => 'Dragonrock Frame';

  @override
  String get cosmeticFrameDragonrockDesc =>
      'A legendary frame of obsidian, dragonstone, and golden details, reserved for the lord of Dragonrock.';

  @override
  String get cosmeticFrameDeveloperTomName => 'Developer Frame';

  @override
  String get cosmeticFrameDeveloperTomDesc =>
      'Special frame unlocked through a Firebase entitlement.';

  @override
  String get cosmeticBackgroundDevAltarName => 'Dev: Altar';

  @override
  String get cosmeticBackgroundDevCampName => 'Dev: Camp';

  @override
  String get cosmeticBackgroundDevHackerName => 'Dev: Hacker';

  @override
  String get cosmeticBackgroundDevLordName => 'Dev: Lord';

  @override
  String get cosmeticBackgroundDevMinesName => 'Dev: Mines';

  @override
  String get cosmeticBackgroundDevThroneName => 'Dev: Throne';

  @override
  String get cosmeticBackgroundDevOnlyDesc =>
      'Developer-only background. Grant via DevTools.';

  @override
  String get cosmeticCompanionDevOnlyDesc =>
      'Developer-only companion. Grant via DevTools.';

  @override
  String get cosmeticCompanionMonsterEnergyName => 'Monster Energy';

  @override
  String get dialogClose => 'Close';

  @override
  String get devGrant => 'Grant';

  @override
  String get devRevoke => 'Revoke';

  @override
  String get cosmeticEquip => 'Equip';

  @override
  String get cosmeticUnequip => 'Unequip';

  @override
  String get cosmeticNoAsset => 'NO ASSET';

  @override
  String get cosmeticRequirementsHeader => 'REQUIREMENTS';

  @override
  String get listOrSeparator => '— or —';

  @override
  String get debugDetailsHeader => 'DEBUG DETAILS';

  @override
  String get debugRowId => 'id';

  @override
  String get debugRowType => 'type';

  @override
  String get debugRowRarity => 'rarity';

  @override
  String get debugRowRegion => 'region';

  @override
  String get debugRowAssetKey => 'assetKey';

  @override
  String get debugRowPreviewAssetKey => 'previewAssetKey';

  @override
  String get debugRowSortOrder => 'sortOrder';

  @override
  String get debugRowIsPremium => 'isPremium';

  @override
  String get debugRowIsEnabled => 'isEnabled';

  @override
  String get debugRowMetadata => 'metadata';

  @override
  String get debugRowUnlockedAt => 'unlockedAt';

  @override
  String get debugRowSourceType => 'sourceType';

  @override
  String get debugRowSourceId => 'sourceId';

  @override
  String get debugMissing => '— missing';

  @override
  String ruleSource(String type, String id) {
    return 'source: $type / $id';
  }

  @override
  String get cosmeticUnlockConditionsHeader => 'UNLOCK CONDITIONS';

  @override
  String copiedToClipboard(String value) {
    return 'Copied: $value';
  }

  @override
  String cosmeticUnlockedAt(String date) {
    return 'Unlocked $date';
  }

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
  String get cosmeticRelicAncientRootName => 'Ancient Root';

  @override
  String get cosmeticRelicAncientRootDesc =>
      'A twisted root from the old forest, marker of seven days unbroken.';

  @override
  String get cosmeticRelicRavineStoneName => 'Ravine Stone';

  @override
  String get cosmeticRelicRavineStoneDesc =>
      'A heavy stone carried over millions of steps.';

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
  String get cosmeticRelicAuroraThreadName => 'Aurora Thread';

  @override
  String get cosmeticRelicAuroraThreadDesc =>
      'A strand of aurora light, woven from thirty-six unbroken weeks.';

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
  String get cosmeticRelicWarmKindlingName => 'Warm Kindling';

  @override
  String get cosmeticRelicWarmKindlingDesc =>
      'A small bundle of dry tinder gathered before the second sunrise.';

  @override
  String get cosmeticRelicMoonlitFoxgloveName => 'Moonlit Foxglove';

  @override
  String get cosmeticRelicMoonlitFoxgloveDesc =>
      'A pale flower that only opens for travelers who keep moving.';

  @override
  String get cosmeticRelicWildwoodCharmName => 'Wildwood Charm';

  @override
  String get cosmeticRelicWildwoodCharmDesc =>
      'A token braided from forest grasses and many seasons of steady wins.';

  @override
  String get cosmeticRelicAshenOmenName => 'Ashen Omen';

  @override
  String get cosmeticRelicAshenOmenDesc =>
      'A burnt mark left on the ruined stones by a steadier walker.';

  @override
  String get cosmeticRelicOathboundMarkName => 'Oathbound Mark';

  @override
  String get cosmeticRelicOathboundMarkDesc =>
      'A sealed promise carved into bone — kept across many small victories.';

  @override
  String get cosmeticRelicDeepEmberCoreName => 'Deep Ember Core';

  @override
  String get cosmeticRelicDeepEmberCoreDesc =>
      'A coal that still burns after a million careful steps in the deep.';

  @override
  String get cosmeticRelicSummitFeatherName => 'Summit Feather';

  @override
  String get cosmeticRelicSummitFeatherDesc =>
      'Found on the wind only by those who cross every threshold.';

  @override
  String get cosmeticRelicStormcrestPlumeName => 'Stormcrest Plume';

  @override
  String get cosmeticRelicStormcrestPlumeDesc =>
      'A feather marked by a year of weekly storms outwalked.';

  @override
  String get cosmeticRelicDragonrockHeartName => 'Dragonrock Heart';

  @override
  String get cosmeticRelicDragonrockHeartDesc =>
      'The forge-warm core of the mountain itself, given only to those who finish the trial.';

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
  String get cosmeticCompanionBridgeGargoyleName => 'Bridge Gargoyle';

  @override
  String get cosmeticCompanionBridgeGargoyleDesc =>
      'A stone gargoyle hatchling that guards the old bridge — sealed-bone oath and iron key are its tribute.';

  @override
  String get cosmeticCompanionLanternGolemName => 'Lantern Golem';

  @override
  String get cosmeticCompanionLanternGolemDesc =>
      'A small stone golem with a flickering lantern in its chest.';

  @override
  String get cosmeticCompanionCaveLynxName => 'Cave Lynx';

  @override
  String get cosmeticCompanionCaveLynxDesc =>
      'A lynx from the rocky descent who follows walkers carrying the scent of distant forests and ravines.';

  @override
  String get cosmeticCompanionAuroraStagName => 'Aurora Stag';

  @override
  String get cosmeticCompanionAuroraStagDesc =>
      'A white stag whose antlers weave living aurora — it emerges on the ice plain only for walkers carrying the lake\'s heart.';

  @override
  String get cosmeticCompanionIceWispName => 'Ice Wisp';

  @override
  String get cosmeticCompanionIceWispDesc =>
      'A pale spark drawn out over the frozen lake by those who carry both lantern and shard.';

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
  String get cosmeticHiddenName => '???';

  @override
  String get cosmeticUnknownReward => 'Unknown reward';

  @override
  String get cosmeticHiddenUnlockCondition =>
      'Unlock condition not yet revealed.';

  @override
  String cosmeticPartialProgress(int completed, int total) {
    return '$completed/$total conditions met';
  }

  @override
  String cosmeticCompanionLevelGate(int level) {
    return 'Reach level $level';
  }

  @override
  String cosmeticCompanionLevelBadge(int level) {
    return 'Lv $level';
  }

  @override
  String get cosmeticRarityCommon => 'Common';

  @override
  String get cosmeticRarityUncommon => 'Uncommon';

  @override
  String get cosmeticRarityRare => 'Rare';

  @override
  String get cosmeticRarityEpic => 'Epic';

  @override
  String get cosmeticRarityLegendary => 'Legendary';

  @override
  String get cosmeticRarityMythic => 'Mythic';

  @override
  String get celebrationCosmeticUnlockedEyebrow => 'Inventory unlocked';

  @override
  String get celebrationAchievementEyebrow => 'Achievement unlocked';

  @override
  String get celebrationLevelEyebrow => 'Level reached';

  @override
  String get celebrationTitleEyebrow => 'Title unlocked';

  @override
  String get celebrationQuestEyebrow => 'Quest completed';

  @override
  String get celebrationStreakEyebrow => 'Streak extended';

  @override
  String get celebrationLocationEyebrow => 'Region discovered';

  @override
  String get celebrationChapterEyebrow => 'Chapter complete';

  @override
  String get celebrationChapterUnlockedEyebrow => 'New chapter unlocked';

  @override
  String get celebrationMilestoneEyebrow => 'Milestone reached';

  @override
  String get celebrationRelicEyebrow => 'Relic acquired';

  @override
  String get celebrationContentUnlockEyebrow => 'New chapter';

  @override
  String get celebrationCompanionReadyEyebrow => 'Companion ready';

  @override
  String get celebrationGoalEyebrow => 'Goal complete';

  @override
  String get celebrationAchievementPackEyebrow => 'Moment';

  @override
  String celebrationAchievementPackTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achievements unlocked',
      one: '1 achievement unlocked',
    );
    return '$_temp0';
  }

  @override
  String get celebrationWelcomeBackEyebrow => 'Welcome back';

  @override
  String celebrationWelcomeBackTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rewards waiting for you',
      one: '$count reward waiting for you',
    );
    return '$_temp0';
  }

  @override
  String celebrationCosmeticUnlockedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new rewards',
      one: 'New reward',
    );
    return '$_temp0';
  }

  @override
  String get celebrationOrphanRewardHint => 'Reward from your progress';

  @override
  String get celebrationSummaryHint => 'Summary from the latest sync';

  @override
  String celebrationChapterUnlockedSuffix(String name) {
    return 'Next chapter unlocked: $name';
  }

  @override
  String get celebrationContinue => 'Continue';

  @override
  String get celebrationOpenInventory => 'Open inventory →';

  @override
  String get celebrationClaimCompanion => 'Claim companion →';

  @override
  String get cosmeticCompanionClaimableBadge => 'READY';

  @override
  String get cosmeticCompanionClaimableHiddenName => 'Mysterious companion';

  @override
  String get cosmeticCompanionClaimCta => 'Claim companion';

  @override
  String get cosmeticCompanionClaimableHint =>
      'Fuse the required relics and summon your companion.';

  @override
  String get cosmeticCompanionCelebrationHint =>
      'Open its card in your inventory to claim it.';

  @override
  String get cosmeticCompanionClaimingFlavor => 'Forging companion…';

  @override
  String get cosmeticCompanionClaimStepRitual => 'Preparing the ritual…';

  @override
  String get cosmeticCompanionClaimStepBinding => 'Binding the relics…';

  @override
  String get cosmeticCompanionClaimStepAwakening => 'Awakening your companion…';

  @override
  String get cosmeticCompanionClaimRevealSubtitle => 'Your new companion';

  @override
  String get cosmeticCompanionClaimTapToContinue => 'Tap anywhere to continue';

  @override
  String get cosmeticRelicConsumedBadge => 'Used';

  @override
  String get cosmeticRelicConsumedHint => 'Used to summon a companion.';

  @override
  String celebrationLevelTitle(int level, String title) {
    return 'Level $level · $title';
  }

  @override
  String celebrationLevelTitleNoTitle(int level) {
    return 'Level $level';
  }

  @override
  String celebrationLevelDecorativeTitle(int level, String name) {
    return 'Level $level · $name';
  }

  @override
  String celebrationXpRewardName(int xp) {
    return '+$xp XP';
  }

  @override
  String celebrationLevelRewardName(int level) {
    return 'Level $level';
  }

  @override
  String get celebrationCloseSemantic => 'Close';

  @override
  String get celebrationTypeAchievement => 'Achievement';

  @override
  String get celebrationTypeQuest => 'Quest';

  @override
  String get celebrationTypeLevel => 'Level';

  @override
  String get celebrationTypeTitle => 'Title';

  @override
  String get celebrationTypeStreak => 'Streak';

  @override
  String get celebrationTypeLocation => 'Region';

  @override
  String get celebrationTypeCosmetic => 'Cosmetic';

  @override
  String get celebrationKindTitle => 'Title';

  @override
  String get celebrationKindFrame => 'Frame';

  @override
  String get celebrationKindBackground => 'Background';

  @override
  String get celebrationKindCompanion => 'Companion';

  @override
  String get celebrationKindBadge => 'Badge';

  @override
  String get celebrationKindGem => 'Relic';

  @override
  String get celebrationKindLocation => 'Region';

  @override
  String get celebrationKindXp => 'XP reward';

  @override
  String get celebrationKindFlame => 'Streak';

  @override
  String get celebrationKindFlag => 'Quest';

  @override
  String get celebrationKindSparkle => 'Reward';

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

  @override
  String get cosmeticFramePilgrimUnlockHint =>
      'Reward for starting your journey.';

  @override
  String get cosmeticFrameWildwoodUnlockHint => 'Reach level 10.';

  @override
  String get cosmeticFrameRuinsUnlockHint => 'Reach level 20.';

  @override
  String get cosmeticFrameDwarvenUnlockHint => 'Reach level 25.';

  @override
  String get cosmeticFrameUnderwaysUnlockHint => 'Reach level 40.';

  @override
  String get cosmeticFrameFrostUnlockHint => 'Reach level 60.';

  @override
  String get cosmeticFrameMountainUnlockHint => 'Reach level 80.';

  @override
  String get cosmeticFrameDragonrockUnlockHint => 'Reach level 100.';

  @override
  String get cosmeticFrameDisciplineUnlockHint =>
      'Maintain a 7-day step streak.';

  @override
  String get cosmeticFrameEnduranceUnlockHint =>
      'Maintain a 30-day step streak.';

  @override
  String get cosmeticFrameSteelUnlockHint => 'Maintain a 50-day step streak.';

  @override
  String get cosmeticFrameEternalFlameUnlockHint =>
      'Maintain a 100-day step streak.';

  @override
  String get cosmeticFrameBalanceUnlockHint =>
      'Achieve 7 perfect activity days.';

  @override
  String get cosmeticFrameMasterRoutineUnlockHint =>
      'Achieve 12 perfect activity weeks.';

  @override
  String get cosmeticFrameEndlessTrailUnlockHint =>
      'Walk 600,000 steps within 30 days.';

  @override
  String get cosmeticFrameWorldwalkerUnlockHint =>
      'Walk 10,000,000 total steps.';

  @override
  String get cosmeticBackgroundForestTrailUnlockHint => 'Reach level 5.';

  @override
  String get cosmeticBackgroundCampUnlockHint => 'Complete your first quest.';

  @override
  String get cosmeticBackgroundRavineUnlockHint => 'Reach level 15.';

  @override
  String get cosmeticBackgroundRuinsUnlockHint => 'Reach level 25.';

  @override
  String get cosmeticBackgroundBridgeCrossingUnlockHint => 'Reach level 35.';

  @override
  String get cosmeticBackgroundMinesUnlockHint => 'Reach level 45.';

  @override
  String get cosmeticBackgroundFrostlandsUnlockHint => 'Reach level 60.';

  @override
  String get cosmeticBackgroundFrozenLakeUnlockHint => 'Reach level 75.';

  @override
  String get cosmeticBackgroundRockyMountainsUnlockHint => 'Reach level 80.';

  @override
  String get cosmeticBackgroundDragonrockFortressUnlockHint =>
      'Reach level 95.';

  @override
  String get cosmeticEmblemForestMarkUnlockHint => 'Complete the Forest Trial.';

  @override
  String get cosmeticEmblemPilgrimMarkUnlockHint =>
      'Complete the Pilgrim\'s Path.';

  @override
  String get cosmeticEmblemRuinSigilUnlockHint =>
      'Complete the Ruins of Discipline.';

  @override
  String get cosmeticEmblemGatekeeperMarkUnlockHint =>
      'Complete the Mine Descent.';

  @override
  String get cosmeticEmblemMineCrestUnlockHint =>
      'Complete the Forge of Momentum.';

  @override
  String get cosmeticEmblemUnderwaysMarkUnlockHint =>
      'Complete the Underway Pact.';

  @override
  String get cosmeticEmblemFrostSigilUnlockHint =>
      'Complete the Frostbound Oath.';

  @override
  String get cosmeticEmblemIcewalkerMarkUnlockHint =>
      'Complete the Icewalker Route.';

  @override
  String get cosmeticEmblemMountainCrestUnlockHint =>
      'Complete the Mountain Ascent.';

  @override
  String get cosmeticEmblemDragonMarkUnlockHint => 'Complete the Dragonroad.';

  @override
  String get cosmeticEmblemDragonrockEmblemUnlockHint =>
      'Complete the Dragonrock Sovereign.';

  @override
  String get cosmeticRelicCampfireSparkUnlockHint =>
      'Complete your first daily quest.';

  @override
  String get cosmeticRelicAncientRootUnlockHint =>
      'Maintain a 7-day step streak.';

  @override
  String get cosmeticRelicRavineStoneUnlockHint =>
      'Walk 2,500,000 total steps.';

  @override
  String get cosmeticRelicRuinSealUnlockHint =>
      'Complete your first weekly quest.';

  @override
  String get cosmeticRelicBridgeKeyUnlockHint => 'Complete 3 weekly quests.';

  @override
  String get cosmeticRelicMinersLanternUnlockHint => 'Complete 50 quests.';

  @override
  String get cosmeticRelicPolarLanternUnlockHint => 'Reach level 55.';

  @override
  String get cosmeticRelicFrostShardUnlockHint => 'Reach level 65.';

  @override
  String get cosmeticRelicAuroraThreadUnlockHint =>
      'Complete the weekly activity rule 36 times.';

  @override
  String get cosmeticRelicFrozenLakeHeartUnlockHint =>
      'Walk 1,000,000 total steps.';

  @override
  String get cosmeticRelicDragonScaleUnlockHint => 'Reach level 85.';

  @override
  String get cosmeticRelicWarmKindlingUnlockHint => 'Complete 3 daily quests.';

  @override
  String get cosmeticRelicMoonlitFoxgloveUnlockHint =>
      'Stay active for 7 days.';

  @override
  String get cosmeticRelicWildwoodCharmUnlockHint => 'Be active for 90 days.';

  @override
  String get cosmeticRelicAshenOmenUnlockHint =>
      'Complete the weekly activity rule 4 times.';

  @override
  String get cosmeticRelicOathboundMarkUnlockHint =>
      'Complete 10 combo quests.';

  @override
  String get cosmeticRelicDeepEmberCoreUnlockHint =>
      'Walk 1,000,000 total steps.';

  @override
  String get cosmeticRelicSummitFeatherUnlockHint =>
      'Complete 100 triple combo quests.';

  @override
  String get cosmeticRelicStormcrestPlumeUnlockHint =>
      'Complete the weekly activity rule 52 times.';

  @override
  String get cosmeticRelicDragonrockHeartUnlockHint =>
      'Complete the Dragonrock Trial.';

  @override
  String get cosmeticCompanionEmberSpriteUnlockHint =>
      'Stay active for 7 days or complete 3 daily quests.';

  @override
  String get cosmeticCompanionForestFoxUnlockHint =>
      'Obtain the Forest Mark and the Ancient Root.';

  @override
  String get cosmeticCompanionRuinRavenUnlockHint =>
      'Obtain the Ruin Seal and the Ashen Omen.';

  @override
  String get cosmeticCompanionBridgeGargoyleUnlockHint =>
      'Obtain the Oathbound Mark and the Bridge Key.';

  @override
  String get cosmeticCompanionLanternGolemUnlockHint =>
      'Obtain the Deep Ember Core and the Miner\'s Lantern.';

  @override
  String get cosmeticCompanionCaveLynxUnlockHint =>
      'Obtain the Wildwood Charm and the Ravine Stone.';

  @override
  String get cosmeticCompanionAuroraStagUnlockHint =>
      'Obtain the Frozen Lake Heart and the Aurora Thread.';

  @override
  String get cosmeticCompanionIceWispUnlockHint =>
      'Obtain the Polar Lantern and the Frost Shard.';

  @override
  String get cosmeticCompanionMountainGryphonUnlockHint =>
      'Obtain the Summit Feather and the Stormcrest Plume.';

  @override
  String get cosmeticCompanionDragonlingUnlockHint =>
      'Reach level 95 and obtain the Dragon Scale and the Dragonrock Heart.';

  @override
  String get coachLogExportTitle => 'Coach Log Export';

  @override
  String get coachLogExportCurrentWeekButton => 'Export current week';

  @override
  String get coachLogExportRangeButton => 'Export range';

  @override
  String get coachLogExportRunning => 'Exporting…';

  @override
  String coachLogExportSuccessWeeks(int count) {
    return 'Exported $count week(s)';
  }

  @override
  String get coachLogExportOpenSheets => 'Open in Sheets';

  @override
  String get coachLogExportDescription =>
      'Writes a weekly coach-log block — weight, steps, calories, macros — into the Coach Log tab of your Forgetrack spreadsheet.';

  @override
  String get onboardingTitle => 'Welcome to Forgetrack';

  @override
  String get onboardingSubtitle =>
      'Track your health, hit goals, and turn the work into XP.';

  @override
  String get onboardingAboutTitle => 'What it does';

  @override
  String get onboardingAboutBody =>
      'Forgetrack pulls steps, sleep, and activity from Health Connect, syncs nutrition from Kaloričke Tabulky, and turns daily/weekly goals into a journey of quests, levels and rewards.';

  @override
  String get onboardingStepsTitle => 'Set up your integrations';

  @override
  String get onboardingStepsHint =>
      'All of these are optional. You can skip any and connect or change them later in Settings.';

  @override
  String get onboardingGoogleTitle => 'Sign in with Google';

  @override
  String get onboardingGoogleBody =>
      'Saves your progression to the cloud and syncs across devices.';

  @override
  String get onboardingGoogleAction => 'Sign in';

  @override
  String onboardingGoogleConnected(String email) {
    return 'Signed in as $email';
  }

  @override
  String get onboardingKtTitle => 'Connect Kaloričke Tabulky';

  @override
  String get onboardingKtBody =>
      'Imports nutrition and weight from your KT diary.';

  @override
  String onboardingKtConnected(String email) {
    return 'Connected as $email';
  }

  @override
  String get onboardingKtEmailHint => 'KT email';

  @override
  String get onboardingKtPasswordHint => 'Password';

  @override
  String get onboardingKtAction => 'Log in';

  @override
  String get onboardingHealthTitle => 'Health Connect';

  @override
  String get onboardingHealthBody =>
      'Allow Forgetrack to read steps, calories, sleep and activity from Health Connect. Your records stay in Health Connect — they are never copied or modified.';

  @override
  String get onboardingHealthAction => 'Grant access';

  @override
  String get onboardingHealthConnected => 'Health Connect access granted';

  @override
  String get onboardingSheetsTitle => 'Google Sheets export';

  @override
  String get onboardingSheetsBody =>
      'Optional: export weekly summaries to a Google Sheet. Forgetrack only writes to spreadsheets it creates for you.';

  @override
  String get onboardingSheetsAction => 'Allow Sheets access';

  @override
  String get onboardingSheetsConnected => 'Sheets access granted';

  @override
  String get onboardingNotificationsTitle => 'Notifications';

  @override
  String get onboardingNotificationsBody =>
      'Daily reminders, quest progress, and reward unlocks.';

  @override
  String get onboardingNotificationsAction => 'Enable';

  @override
  String get onboardingNotificationsConnected => 'Notifications enabled';

  @override
  String get onboardingFooterNote =>
      'You can change all of this later under Settings.';

  @override
  String get onboardingContinue => 'Continue to app';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeCtaStart => 'Begin your journey';

  @override
  String get welcomeCtaContinue => 'Continue';

  @override
  String get welcomeCtaFinish => 'Enter the game';

  @override
  String get welcomeStep1Title => 'Welcome, hero.';

  @override
  String get welcomeStep1Subtitle =>
      'Forgetrack turns your health into a journey of quests — steps, sleep and food become XP, levels and titles.';

  @override
  String get welcomeStep1SubtitleAccent => 'a journey of quests';

  @override
  String get welcomeStep1HeroLabel => 'YOUR START';

  @override
  String welcomeStep1HeroXpProgress(int into, int toNext) {
    return '$into / $toNext XP to the next level';
  }

  @override
  String get welcomeStep1HeroPill => '+50 XP';

  @override
  String get welcomeStep2Title => 'Save your progress';

  @override
  String get welcomeStep2Subtitle =>
      'Sign in with Google and your levels, streaks and achievements stay safely in the cloud — even when you switch phones.';

  @override
  String get welcomeStep2GoogleSignIn => 'Sign in with Google';

  @override
  String get welcomeStep2GoogleSignedIn => 'Signed in';

  @override
  String welcomeStep2GoogleSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get welcomeStep2Benefit1 => 'Sync between your devices';

  @override
  String get welcomeStep2Benefit2 => 'Backed-up progress and achievements';

  @override
  String get welcomeStep2Benefit3 => 'Works offline too';

  @override
  String get welcomeStep2Footnote =>
      'You don\'t have to decide right now — it works without an account too.';

  @override
  String get welcomeStep3Title => 'Connect your data';

  @override
  String get welcomeStep3Subtitle =>
      'Forgetrack reads steps, sleep and activity from Health Connect and turns them into XP. Your records never leave Health Connect — only read.';

  @override
  String get welcomeStep3DataSteps => 'Steps';

  @override
  String get welcomeStep3DataCalories => 'Calories';

  @override
  String get welcomeStep3DataSleep => 'Sleep';

  @override
  String get welcomeStep3DataActivity => 'Activity';

  @override
  String get welcomeStep3Cta => 'Allow Health Connect';

  @override
  String get welcomeStep3CtaConnected => 'Health Connect is connected';

  @override
  String get welcomeStep3Privacy =>
      'Your data stays inside Health Connect — Forgetrack never copies or modifies it.';

  @override
  String get welcomeStep4Title => 'Final touches';

  @override
  String get welcomeStep4Subtitle =>
      'Optional — you can set everything up later in the app.';

  @override
  String get welcomeStep4KtTitle => 'Kaloričke Tabulky';

  @override
  String get welcomeStep4KtSubtitle =>
      'Import nutrition and weight from your KT diary';

  @override
  String get welcomeStep4KtConnected => 'Connected';

  @override
  String get welcomeStep4NotifTitle => 'Notifications';

  @override
  String get welcomeStep4NotifSubtitle => 'Quest reminders and reward alerts';

  @override
  String get welcomeStep4QuestsLabel => 'FIRST QUESTS';

  @override
  String get welcomeKtSheetTitle => 'Kaloričke Tabulky';

  @override
  String get welcomeKtSheetSubtitle => 'Sign in to your KT account';

  @override
  String get welcomeKtSheetEmailHint => 'KT email';

  @override
  String get welcomeKtSheetPasswordHint => 'Password';

  @override
  String get welcomeKtSheetSubmit => 'Sign in and connect';

  @override
  String get welcomeKtSheetFootnote =>
      'Forgetrack uses your sign-in only to read the KT diary.';
}
