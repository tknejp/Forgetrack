import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en')
  ];

  /// Application name in the title bar
  ///
  /// In en, this message translates to:
  /// **'Forgetrack'**
  String get appTitle;

  /// Bottom navigation label for the Overview tab
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// Bottom navigation label for the Activities tab
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get navActivities;

  /// Bottom navigation label for the Nutrition tab
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// Bottom navigation label for the Body/Weight tab
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get navBody;

  /// AppBar title for the Profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get screenProfile;

  /// AppBar title for the Activities screen
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get screenActivities;

  /// AppBar title for the Nutrition screen
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get screenNutrition;

  /// AppBar title for the Body screen
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get screenBody;

  /// Segmented button label for 'day' period
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// Segmented button label for 'week' period
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// Segmented button label for 'month' period
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// Snackbar shown when user taps the custom range placeholder button
  ///
  /// In en, this message translates to:
  /// **'Custom range coming soon'**
  String get periodCustomRangeSoon;

  /// Calorie card subtitle shown in week/month mode indicating values are daily averages
  ///
  /// In en, this message translates to:
  /// **'Avg / day'**
  String get caloriesAvgPerDay;

  /// Label for average sleep duration in week/month mode
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get sleepAverage;

  /// Steps card title
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsTitle;

  /// Label for today's step count
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get stepsToday;

  /// General label for the main step value in day mode
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get stepsCurrent;

  /// Label for step goal
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get stepsGoal;

  /// Label for remaining steps
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get stepsRemaining;

  /// Label for average steps
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get stepsAverage;

  /// Average steps per day display
  ///
  /// In en, this message translates to:
  /// **'{value} / day'**
  String stepsAvgPerDay(String value);

  /// Label for whether daily step goal was completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stepsCompleted;

  /// Goal completed: yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get stepsYes;

  /// Goal completed: no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get stepsNo;

  /// Label for the day with most steps
  ///
  /// In en, this message translates to:
  /// **'Best day'**
  String get stepsBestDay;

  /// Label for the maximum step count in history
  ///
  /// In en, this message translates to:
  /// **'Max steps'**
  String get stepsMaxSteps;

  /// Calorie summary card title
  ///
  /// In en, this message translates to:
  /// **'Calories today'**
  String get caloriesTodayTitle;

  /// Label for calories consumed
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get caloriesConsumed;

  /// Label for calories burned through exercise
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get caloriesBurned;

  /// Label for remaining calorie budget
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get caloriesRemaining;

  /// Macro nutrient: protein
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// Macro nutrient: fat
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// Macro nutrient: carbohydrates
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// Macro nutrient: dietary fiber
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get macroFiber;

  /// Weight card title
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTitle;

  /// Label for goal weight
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get weightGoal;

  /// Label for average weight (week/month mode)
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get weightAverage;

  /// Label for minimum weight in period
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get weightMin;

  /// Label for maximum weight in period
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get weightMax;

  /// Label for body fat percentage
  ///
  /// In en, this message translates to:
  /// **'Body fat'**
  String get weightBodyFat;

  /// Label for lean body mass
  ///
  /// In en, this message translates to:
  /// **'Lean mass'**
  String get weightLeanMass;

  /// Label for fat mass
  ///
  /// In en, this message translates to:
  /// **'Fat mass'**
  String get weightFatMass;

  /// Column label for the main weight value in day mode
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightMainLabelDay;

  /// Trend label in day mode: vs previous measurement
  ///
  /// In en, this message translates to:
  /// **'vs prev.'**
  String get weightVsPrevMeasure;

  /// Trend label in week mode
  ///
  /// In en, this message translates to:
  /// **'vs prev. week'**
  String get weightVsPrevWeek;

  /// Trend label in month mode
  ///
  /// In en, this message translates to:
  /// **'vs prev. month'**
  String get weightVsPrevMonth;

  /// Shown when no weight was recorded for the selected day
  ///
  /// In en, this message translates to:
  /// **'No record'**
  String get weightNoMeasurement;

  /// Button to export data to Google Sheets
  ///
  /// In en, this message translates to:
  /// **'Export to Sheets'**
  String get profileExportToSheets;

  /// Button to sign out of the account
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// Empty state placeholder when no data is available
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get emptyNoData;

  /// Header label for the Settings section in Profile
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// Label for the language selector setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Option to follow the device system locale
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Language option: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language option: Czech
  ///
  /// In en, this message translates to:
  /// **'Čeština'**
  String get languageCzech;

  /// Header text when no user is authenticated
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profileNotSignedIn;

  /// Short benefit subtitle shown below sign-in CTA
  ///
  /// In en, this message translates to:
  /// **'Sync workouts, calories and progress across devices'**
  String get profileSignInBenefit;

  /// Label for the Google sign-in CTA button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get profileContinueWithGoogle;

  /// Badge shown when user is signed in via Google
  ///
  /// In en, this message translates to:
  /// **'Connected with Google'**
  String get profileConnectedGoogle;

  /// Title of the sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutConfirmTitle;

  /// Body text of the sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to sync your data.'**
  String get profileSignOutConfirmMessage;

  /// Generic cancel button label for dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Settings section header: preferences
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get sectionPreferences;

  /// Settings section header: data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get sectionData;

  /// Settings section header: about the app
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// Settings section header: account / danger zone
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// Label for the theme mode setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme mode option: follow system setting
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme mode option: always light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme mode option: always dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Label for the app version row
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// Label for the privacy policy row
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// Label for the terms of service row
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// Label for the send feedback row
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsFeedback;

  /// Label for the clear local cache row
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get settingsClearCache;

  /// Title shown when Health Connect is not installed
  ///
  /// In en, this message translates to:
  /// **'Health Connect unavailable'**
  String get healthNotAvailable;

  /// Body text when Health Connect is not installed
  ///
  /// In en, this message translates to:
  /// **'Install the Health Connect app to track your steps, weight and activity data.'**
  String get healthNotAvailableBody;

  /// Button to install Health Connect from the Play Store
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get healthInstall;

  /// Title shown when Health Connect permissions are missing
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get healthPermissionRequired;

  /// Body text when Health Connect permissions are missing
  ///
  /// In en, this message translates to:
  /// **'Grant Forgetrack access to Health Connect to display your real fitness data.'**
  String get healthPermissionBody;

  /// Button to request Health Connect permissions
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get healthGrantAccess;

  /// Error banner text when a health data sync fails
  ///
  /// In en, this message translates to:
  /// **'Could not load health data'**
  String get healthSyncFailed;

  /// Button to retry a failed health data load
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get healthRetry;

  /// Timestamp label shown after a successful health data sync
  ///
  /// In en, this message translates to:
  /// **'Synced: {time}'**
  String healthLastSynced(String time);

  /// Profile section header for Kalorické Tabulky integration
  ///
  /// In en, this message translates to:
  /// **'Nutrition Sync'**
  String get ktSectionTitle;

  /// Subtitle shown in the KT login card when not connected
  ///
  /// In en, this message translates to:
  /// **'Connect to kaloricketabulky.cz to automatically sync your daily nutrition data.'**
  String get ktConnectBody;

  /// Email text field hint for KT login
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ktEmailHint;

  /// Password text field hint for KT login
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get ktPasswordHint;

  /// Primary button to submit KT login credentials
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get ktLoginButton;

  /// Loading label shown while KT login request is in flight
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get ktLoggingIn;

  /// Badge label shown when user is connected to KT
  ///
  /// In en, this message translates to:
  /// **'Connected to kaloricketabulky.cz'**
  String get ktConnectedBadge;

  /// Button to remove KT credentials and disconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get ktDisconnectButton;

  /// Title of the KT disconnect confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Disconnect Kalorické Tabulky?'**
  String get ktDisconnectConfirmTitle;

  /// Body text of the KT disconnect confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Your nutrition data will no longer sync from Kalorické Tabulky.'**
  String get ktDisconnectConfirmMessage;

  /// Error message shown when KT login credentials are rejected
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get ktAuthError;

  /// Error message when a KT data fetch fails
  ///
  /// In en, this message translates to:
  /// **'Could not sync nutrition data'**
  String get ktSyncError;

  /// Button to retry a failed KT data sync
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ktRetry;

  /// Timestamp label shown after a successful KT nutrition sync
  ///
  /// In en, this message translates to:
  /// **'Synced: {time}'**
  String ktSyncedAt(String time);

  /// Empty-state text in Nutrition screen when not connected to KT
  ///
  /// In en, this message translates to:
  /// **'Connect Kalorické Tabulky in Settings to view your nutrition data.'**
  String get ktLoginPrompt;

  /// CTA button in the Nutrition empty state that opens Profile/Settings
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get ktGoToSettings;

  /// Empty-state text when the user is connected but has no diary entries today
  ///
  /// In en, this message translates to:
  /// **'No diary entries for today'**
  String get ktNoDiaryData;

  /// Section title in the Nutrition screen for today's macro overview
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nutrition'**
  String get ktNutritionTitle;

  /// Sleep card title
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTitle;

  /// Label for total sleep duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sleepDuration;

  /// Label for the time the user fell asleep
  ///
  /// In en, this message translates to:
  /// **'Fell asleep'**
  String get sleepFellAsleep;

  /// Label for the time the user woke up
  ///
  /// In en, this message translates to:
  /// **'Woke up'**
  String get sleepWokeUp;

  /// Empty state text when no sleep data is available
  ///
  /// In en, this message translates to:
  /// **'No sleep data recorded'**
  String get sleepNoData;

  /// Label for this week's step total in Activities screen
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get activitiesWeekTotal;

  /// Label for this month's step total in Activities screen
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get activitiesMonthTotal;

  /// Section title for active calories in Activities screen
  ///
  /// In en, this message translates to:
  /// **'Active calories'**
  String get activitiesActiveCalories;

  /// Label for active minutes in Activities screen
  ///
  /// In en, this message translates to:
  /// **'Active min.'**
  String get activitiesActiveMins;

  /// Section title for workout list in Activities screen
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get activitiesWorkouts;

  /// Empty state when no workouts are available
  ///
  /// In en, this message translates to:
  /// **'No workouts in the last 30 days'**
  String get activitiesNoWorkouts;

  /// Section header for recent workout list
  ///
  /// In en, this message translates to:
  /// **'Recent workouts'**
  String get activitiesRecentActivity;

  /// Label for daily average value
  ///
  /// In en, this message translates to:
  /// **'Daily avg'**
  String get activitiesDailyAvg;

  /// Label for weekly average value
  ///
  /// In en, this message translates to:
  /// **'Weekly avg'**
  String get activitiesWeeklyAvg;

  /// Label for 7-day steps bar chart section
  ///
  /// In en, this message translates to:
  /// **'7-day trend'**
  String get activitiesWeeklyTrend;

  /// Label for average workout duration in workout stats card
  ///
  /// In en, this message translates to:
  /// **'Avg. duration'**
  String get activitiesAvgDuration;

  /// Title in the workout permission card when WORKOUT permission is not granted
  ///
  /// In en, this message translates to:
  /// **'Workout access needed'**
  String get activitiesWorkoutPermissionTitle;

  /// Body text in the workout permission card
  ///
  /// In en, this message translates to:
  /// **'Grant Forgetrack access to your workout data in Health Connect to see activity history and stats.'**
  String get activitiesWorkoutPermissionBody;

  /// Label for 7-day average sleep duration in Body screen sleep section
  ///
  /// In en, this message translates to:
  /// **'7-day avg'**
  String get sleepAvg7Day;

  /// Label for current weight value in Body screen
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bodyCurrentWeight;

  /// Label for 30-day weight change in Body screen
  ///
  /// In en, this message translates to:
  /// **'30-day change'**
  String get body30DayChange;

  /// Section title for weight trend chart
  ///
  /// In en, this message translates to:
  /// **'Weight trend'**
  String get bodyWeightTrend;

  /// Section title for body composition (fat%, lean mass)
  ///
  /// In en, this message translates to:
  /// **'Body composition'**
  String get bodyComposition;

  /// Empty state when no weight data is available in Body screen
  ///
  /// In en, this message translates to:
  /// **'No weight data recorded'**
  String get bodyNoData;

  /// Label for progress bar toward target weight
  ///
  /// In en, this message translates to:
  /// **'Progress to goal'**
  String get bodyProgressToGoal;

  /// Remaining distance to target weight
  ///
  /// In en, this message translates to:
  /// **'{value} kg to go'**
  String bodyToGo(String value);

  /// Message shown when current weight equals or is better than goal weight
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get bodyAtGoal;

  /// Settings section header for user goals
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get sectionGoals;

  /// Goal label: daily step count
  ///
  /// In en, this message translates to:
  /// **'Daily steps'**
  String get goalDailySteps;

  /// Goal label: target body weight
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get goalTargetWeight;

  /// Goal label: daily calorie intake target
  ///
  /// In en, this message translates to:
  /// **'Daily calories'**
  String get goalDailyCalories;

  /// Goal label: daily protein intake target
  ///
  /// In en, this message translates to:
  /// **'Daily protein'**
  String get goalDailyProtein;

  /// Goal label: sleep duration goal
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get goalSleepHours;

  /// Goal label: weekly activity minutes goal
  ///
  /// In en, this message translates to:
  /// **'Weekly activity'**
  String get goalWeeklyActivity;

  /// Unit suffix for step count goals
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get goalUnitSteps;

  /// Unit suffix for calorie goals
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get goalUnitKcal;

  /// Unit suffix for gram-based goals (protein)
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get goalUnitG;

  /// Unit suffix for sleep hours goal
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get goalUnitHours;

  /// Unit suffix for activity minutes goal
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get goalUnitMins;

  /// Dialog title when editing a goal value
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get goalEditTitle;

  /// Confirm button in goal edit dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalSave;

  /// Button in the day-mode date header that jumps back to today's date
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get headerToday;

  /// Nutrient label: sugar
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get macroSugar;

  /// Nutrient label: salt / sodium
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get macroSalt;

  /// Nutrient label: saturated fat (compact)
  ///
  /// In en, this message translates to:
  /// **'Sat. fat'**
  String get macroSaturatedFat;

  /// Goal label: daily fat intake target
  ///
  /// In en, this message translates to:
  /// **'Daily fat'**
  String get goalDailyFat;

  /// Goal label: daily carbohydrate intake target
  ///
  /// In en, this message translates to:
  /// **'Daily carbs'**
  String get goalDailyCarbs;

  /// Nutrition screen period selector: last 7 days
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get nutritionPeriod7d;

  /// Nutrition screen period selector: last 30 days
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get nutritionPeriod30d;

  /// Button in nutrition screen that opens goal editing in Profile
  ///
  /// In en, this message translates to:
  /// **'Edit goals'**
  String get nutritionGoalsTitle;

  /// Empty state shown in nutrition screen when historical averages cannot be computed
  ///
  /// In en, this message translates to:
  /// **'Not enough data for this period'**
  String get nutritionNoHistoryData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
