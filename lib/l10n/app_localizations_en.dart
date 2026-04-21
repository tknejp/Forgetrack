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
}
