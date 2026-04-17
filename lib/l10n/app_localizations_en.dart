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
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get stepsToday => 'Today';

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
  String get weightCurrent => 'Current';

  @override
  String get weightGoal => 'Goal';

  @override
  String get weightDifference => 'Difference';

  @override
  String get weight7Days => '7 days';

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
  String get weightStatus => 'Status';

  @override
  String get weightGoalAchieved => 'Goal achieved';

  @override
  String get weightInProgress => 'In progress';

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
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

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
}
