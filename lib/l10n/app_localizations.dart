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

  /// Bottom navigation label for the Quests tab
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get navQuests;

  /// Bottom navigation label for the Hero tab
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get navHero;

  /// Bottom navigation label for the Social tab
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get navSocial;

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

  /// Generic loading label shown while Google sign-in is in progress
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authSigningIn;

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

  /// Label for the Dynamic Time Theme toggle setting
  ///
  /// In en, this message translates to:
  /// **'Dynamic Time Theme'**
  String get settingsTimeTheme;

  /// Short description for the Dynamic Time Theme toggle
  ///
  /// In en, this message translates to:
  /// **'Adjusts visuals based on the current time of day.'**
  String get settingsTimeThemeDesc;

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

  /// Theme mode option: auto light/dark + palette driven by time of day
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get themeDynamic;

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

  /// Shortcut button on an expanded overview card that opens the corresponding detail screen
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get homeOpenDetailCta;

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

  /// Generic helper text explaining weight progress calculation
  ///
  /// In en, this message translates to:
  /// **'This percentage shows progress toward your goal based on your recorded weight history.'**
  String get weightProgressExplanation;

  /// Helper text explaining weight-loss progress calculation
  ///
  /// In en, this message translates to:
  /// **'This percentage shows progress from your highest recorded weight toward your goal, not current weight divided by goal.'**
  String get weightProgressExplanationLoss;

  /// Helper text explaining weight-gain progress calculation
  ///
  /// In en, this message translates to:
  /// **'This percentage shows progress from your lowest recorded weight toward your goal, not current weight divided by goal.'**
  String get weightProgressExplanationGain;

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

  /// Unit suffix for weight in kilograms
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get goalUnitKg;

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

  /// AppBar title of the Sheets export screen
  ///
  /// In en, this message translates to:
  /// **'Export to Google Sheets'**
  String get exportScreenTitle;

  /// Card title shown when the user must authenticate before exporting
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get exportSignInTitle;

  /// Body text inside the sign-in required card
  ///
  /// In en, this message translates to:
  /// **'Sheets export needs your Google account to write to your spreadsheet. Sign in to continue.'**
  String get exportSignInBody;

  /// CTA button to start Google sign-in from the export screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get exportSignInButton;

  /// Loading label on the sign-in button while auth is in progress
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get exportSignInLoading;

  /// Note explaining that Sheets export authorization may be requested on demand
  ///
  /// In en, this message translates to:
  /// **'Export may ask for Google Sheets permission when you run it.'**
  String get exportAuthorizationNote;

  /// Section label for the target spreadsheet card
  ///
  /// In en, this message translates to:
  /// **'Target spreadsheet'**
  String get exportTargetLabel;

  /// Body text shown when no spreadsheet is linked yet
  ///
  /// In en, this message translates to:
  /// **'No spreadsheet linked yet. A new \"Forgetrack Data\" spreadsheet will be created in your Google Drive on the first export.'**
  String get exportTargetMissingBody;

  /// Tooltip on the copy spreadsheet link icon button
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get exportTargetCopyLink;

  /// Snackbar shown after the spreadsheet link is copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet link copied'**
  String get exportTargetLinkCopied;

  /// Button that unlinks the spreadsheet from the app
  ///
  /// In en, this message translates to:
  /// **'Forget link'**
  String get exportTargetForgetButton;

  /// Title of the confirmation dialog shown before unlinking the spreadsheet
  ///
  /// In en, this message translates to:
  /// **'Forget linked spreadsheet?'**
  String get exportTargetForgetConfirmTitle;

  /// Body of the confirmation dialog shown before unlinking the spreadsheet
  ///
  /// In en, this message translates to:
  /// **'This only removes the link inside Forgetrack. The spreadsheet itself will remain in your Google Drive.'**
  String get exportTargetForgetConfirmMessage;

  /// Destructive action label in the forget-spreadsheet confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get exportTargetForgetConfirmAction;

  /// Section label for the date range picker
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get exportRangeLabel;

  /// Day count pill shown next to the range label
  ///
  /// In en, this message translates to:
  /// **'{count} day(s)'**
  String exportRangeDayCount(int count);

  /// Button that opens the date range picker
  ///
  /// In en, this message translates to:
  /// **'Choose range'**
  String get exportRangePickButton;

  /// Validation message shown when the selected range is invalid
  ///
  /// In en, this message translates to:
  /// **'End date must be on or after the start date.'**
  String get exportRangeInvalid;

  /// Preset chip that selects the last 7 days
  ///
  /// In en, this message translates to:
  /// **'Last 7d'**
  String get exportRangePresetLast7;

  /// Preset chip that selects the last 30 days
  ///
  /// In en, this message translates to:
  /// **'Last 30d'**
  String get exportRangePresetLast30;

  /// Preset chip that selects the current month up to today
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get exportRangePresetThisMonth;

  /// Preset chip that selects the entirety of the previous month
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get exportRangePresetLastMonth;

  /// Section label for the list of exportable fields
  ///
  /// In en, this message translates to:
  /// **'Fields to export'**
  String get exportFieldsLabel;

  /// Link that selects all exportable fields
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exportFieldsSelectAll;

  /// Link that clears all selected export fields
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get exportFieldsSelectNone;

  /// Export field category heading: activity-related metrics
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get exportCategoryActivity;

  /// Export field category heading: body measurements
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get exportCategoryBody;

  /// Export field category heading: sleep metrics
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get exportCategorySleep;

  /// Export field category heading: nutrition metrics
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get exportCategoryNutrition;

  /// Primary button that triggers the Sheets export
  ///
  /// In en, this message translates to:
  /// **'Export to Sheets'**
  String get exportButton;

  /// Primary button label while an export is running
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exportButtonRunning;

  /// Compact summary shown above the export button
  ///
  /// In en, this message translates to:
  /// **'{days} day(s) · {fields} field(s) · {range}'**
  String exportSummary(int days, int fields, String range);

  /// Footer note explaining merge-by-date semantics
  ///
  /// In en, this message translates to:
  /// **'Rows are merged by date — existing dates are updated, new ones are appended. Today is {today}.'**
  String exportExplainer(String today);

  /// Title of the success banner shown after a successful export
  ///
  /// In en, this message translates to:
  /// **'Export complete'**
  String get exportSuccessTitle;

  /// Detail line in the success banner and snackbar
  ///
  /// In en, this message translates to:
  /// **'Wrote {rows} row(s) — +{added} added, {updated} updated.'**
  String exportSuccessDetail(int rows, int added, int updated);

  /// Title of the error banner shown when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportErrorTitle;

  /// Fallback message for an unknown export error
  ///
  /// In en, this message translates to:
  /// **'Unknown error.'**
  String get exportErrorGeneric;

  /// Error message when the user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'Not signed in to Google. Sign in to enable Sheets export.'**
  String get exportErrorNotSignedIn;

  /// Validation message when no fields are selected
  ///
  /// In en, this message translates to:
  /// **'Select at least one field to export.'**
  String get exportErrorNoFields;

  /// Validation message when the end date precedes the start date
  ///
  /// In en, this message translates to:
  /// **'Invalid range: the end date is before the start date.'**
  String get exportErrorInvalidRange;

  /// Generic wrapper used when an unexpected error must be surfaced
  ///
  /// In en, this message translates to:
  /// **'Export failed: {message}'**
  String exportErrorPrefix(String message);

  /// Field label: step count for the day
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get exportFieldSteps;

  /// Field label: calories burned through activity
  ///
  /// In en, this message translates to:
  /// **'Active calories'**
  String get exportFieldActiveCalories;

  /// Description for the active calories export field
  ///
  /// In en, this message translates to:
  /// **'Calories burned through activity (kcal).'**
  String get exportFieldActiveCaloriesDesc;

  /// Field label: body weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get exportFieldWeight;

  /// Description for the weight export field
  ///
  /// In en, this message translates to:
  /// **'Latest weight recorded on the day (kg).'**
  String get exportFieldWeightDesc;

  /// Field label: body fat percentage
  ///
  /// In en, this message translates to:
  /// **'Body fat'**
  String get exportFieldBodyFat;

  /// Description for the body fat export field
  ///
  /// In en, this message translates to:
  /// **'Body-fat percentage recorded on the day.'**
  String get exportFieldBodyFatDesc;

  /// Field label: total sleep duration
  ///
  /// In en, this message translates to:
  /// **'Sleep duration'**
  String get exportFieldSleepDuration;

  /// Description for the sleep duration export field
  ///
  /// In en, this message translates to:
  /// **'Total sleep on the night ending on this date (minutes).'**
  String get exportFieldSleepDurationDesc;

  /// Field label: bedtime (time user fell asleep)
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get exportFieldSleepBedtime;

  /// Field label: wake time
  ///
  /// In en, this message translates to:
  /// **'Wake time'**
  String get exportFieldSleepWake;

  /// Field label: calories consumed
  ///
  /// In en, this message translates to:
  /// **'Calories in'**
  String get exportFieldKcalIn;

  /// Description for the calories-in export field
  ///
  /// In en, this message translates to:
  /// **'Calories logged via Kalorické tabulky (kcal).'**
  String get exportFieldKcalInDesc;

  /// Field label: protein intake
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get exportFieldProtein;

  /// Field label: fat intake
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get exportFieldFat;

  /// Field label: carbohydrate intake
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get exportFieldCarbs;

  /// Field label: dietary fiber intake
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get exportFieldFiber;

  /// Field label: sugar intake
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get exportFieldSugar;

  /// Field label: salt intake
  ///
  /// In en, this message translates to:
  /// **'Salt'**
  String get exportFieldSalt;

  /// Field label: saturated fat intake
  ///
  /// In en, this message translates to:
  /// **'Saturated fat'**
  String get exportFieldSaturatedFat;

  /// Sheet column A header — the merge-key date column
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportHeaderDate;

  /// Sheet column header for steps
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get exportHeaderSteps;

  /// Sheet column header for active calories
  ///
  /// In en, this message translates to:
  /// **'Active calories (kcal)'**
  String get exportHeaderActiveCalories;

  /// Sheet column header for body weight
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get exportHeaderWeight;

  /// Sheet column header for body fat percentage
  ///
  /// In en, this message translates to:
  /// **'Body fat (%)'**
  String get exportHeaderBodyFat;

  /// Sheet column header for sleep duration in minutes
  ///
  /// In en, this message translates to:
  /// **'Sleep (min)'**
  String get exportHeaderSleepDuration;

  /// Sheet column header for bedtime
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get exportHeaderSleepBedtime;

  /// Sheet column header for wake time
  ///
  /// In en, this message translates to:
  /// **'Wake time'**
  String get exportHeaderSleepWake;

  /// Sheet column header for calories consumed
  ///
  /// In en, this message translates to:
  /// **'Calories in (kcal)'**
  String get exportHeaderKcalIn;

  /// Sheet column header for protein intake
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get exportHeaderProtein;

  /// Sheet column header for fat intake
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get exportHeaderFat;

  /// Sheet column header for carbohydrate intake
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get exportHeaderCarbs;

  /// Sheet column header for fiber intake
  ///
  /// In en, this message translates to:
  /// **'Fiber (g)'**
  String get exportHeaderFiber;

  /// Sheet column header for sugar intake
  ///
  /// In en, this message translates to:
  /// **'Sugar (g)'**
  String get exportHeaderSugar;

  /// Sheet column header for salt intake
  ///
  /// In en, this message translates to:
  /// **'Salt (g)'**
  String get exportHeaderSalt;

  /// Sheet column header for saturated fat intake
  ///
  /// In en, this message translates to:
  /// **'Saturated fat (g)'**
  String get exportHeaderSaturatedFat;

  /// No description provided for @progScreenEyebrow.
  ///
  /// In en, this message translates to:
  /// **'HERO PROFILE'**
  String get progScreenEyebrow;

  /// No description provided for @progScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your hero journey'**
  String get progScreenTitle;

  /// No description provided for @progScreenLoadingHint.
  ///
  /// In en, this message translates to:
  /// **'Preparing your legend'**
  String get progScreenLoadingHint;

  /// No description provided for @progScreenEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Progression profile'**
  String get progScreenEntryTitle;

  /// No description provided for @progScreenEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{levelTitle} · {totalXp} XP · {unlocked} achievements'**
  String progScreenEntrySubtitle(String levelTitle, int totalXp, int unlocked);

  /// No description provided for @progOpenCta.
  ///
  /// In en, this message translates to:
  /// **'Open progression profile'**
  String get progOpenCta;

  /// No description provided for @progBadgeTotalXp.
  ///
  /// In en, this message translates to:
  /// **'TOTAL XP'**
  String get progBadgeTotalXp;

  /// No description provided for @progBadgeLevel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level} · {title}'**
  String progBadgeLevel(int level, String title);

  /// No description provided for @progBadgeStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} streak'**
  String progBadgeStreak(int count);

  /// No description provided for @progBadgeStreakEmpty.
  ///
  /// In en, this message translates to:
  /// **'No current streak'**
  String get progBadgeStreakEmpty;

  /// No description provided for @progBadgeStreakHint.
  ///
  /// In en, this message translates to:
  /// **'Build your first chain'**
  String get progBadgeStreakHint;

  /// No description provided for @progBadgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'{count} unlocked'**
  String progBadgeUnlocked(int count);

  /// No description provided for @progBadgeAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get progBadgeAchievements;

  /// No description provided for @progBadgePendingClaims.
  ///
  /// In en, this message translates to:
  /// **'{count} to claim'**
  String progBadgePendingClaims(int count);

  /// No description provided for @progBadgeXpRange.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} XP'**
  String progBadgeXpRange(int current, int max);

  /// No description provided for @progLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String progLastSynced(String time);

  /// No description provided for @progStreakSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get progStreakSectionLabel;

  /// No description provided for @progStreakSectionCaption.
  ///
  /// In en, this message translates to:
  /// **'Current and best streaks across your domains.'**
  String get progStreakSectionCaption;

  /// No description provided for @progStreakCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STREAK'**
  String get progStreakCurrentLabel;

  /// No description provided for @progStreakBestLabel.
  ///
  /// In en, this message translates to:
  /// **'BEST STREAK'**
  String get progStreakBestLabel;

  /// No description provided for @progStreakDaysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get progStreakDaysSuffix;

  /// No description provided for @progActiveQuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active quests'**
  String get progActiveQuestsLabel;

  /// No description provided for @progShowAllCount.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count}) →'**
  String progShowAllCount(int count);

  /// No description provided for @progMiniStatTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get progMiniStatTotalXp;

  /// No description provided for @progMiniStatToNext.
  ///
  /// In en, this message translates to:
  /// **'To next'**
  String get progMiniStatToNext;

  /// No description provided for @progMiniStatAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get progMiniStatAchievements;

  /// No description provided for @progMiniStatQuests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get progMiniStatQuests;

  /// No description provided for @progSummarySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Progression Summary'**
  String get progSummarySectionLabel;

  /// No description provided for @progSummaryCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get progSummaryCurrentStreak;

  /// No description provided for @progSummaryBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get progSummaryBestStreak;

  /// No description provided for @progSummaryCompletedQuests.
  ///
  /// In en, this message translates to:
  /// **'Completed Quests'**
  String get progSummaryCompletedQuests;

  /// No description provided for @progSummaryAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get progSummaryAchievements;

  /// No description provided for @progSummaryNoActiveChain.
  ///
  /// In en, this message translates to:
  /// **'No active chain yet'**
  String get progSummaryNoActiveChain;

  /// No description provided for @progSummaryBuildConsistency.
  ///
  /// In en, this message translates to:
  /// **'Build consistency'**
  String get progSummaryBuildConsistency;

  /// No description provided for @progQuestsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get progQuestsSectionLabel;

  /// No description provided for @progQuestsSectionCaption.
  ///
  /// In en, this message translates to:
  /// **'Active and locked quests first, completed ones below.'**
  String get progQuestsSectionCaption;

  /// No description provided for @questsScreenEyebrow.
  ///
  /// In en, this message translates to:
  /// **'QUESTS'**
  String get questsScreenEyebrow;

  /// No description provided for @questsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your quests and rewards'**
  String get questsScreenTitle;

  /// No description provided for @progQuestsActiveHeader.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE QUESTS'**
  String get progQuestsActiveHeader;

  /// No description provided for @progQuestsLockedHeader.
  ///
  /// In en, this message translates to:
  /// **'LOCKED QUESTS'**
  String get progQuestsLockedHeader;

  /// No description provided for @progQuestsCompletedHeader.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED QUESTS'**
  String get progQuestsCompletedHeader;

  /// No description provided for @progQuestsEmptyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active quests right now.'**
  String get progQuestsEmptyActiveTitle;

  /// No description provided for @progQuestsEmptyActiveCaption.
  ///
  /// In en, this message translates to:
  /// **'You have cleared the current static quest catalog.'**
  String get progQuestsEmptyActiveCaption;

  /// No description provided for @progQuestsEmptyLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'No locked quests right now.'**
  String get progQuestsEmptyLockedTitle;

  /// No description provided for @progQuestsEmptyLockedCaption.
  ///
  /// In en, this message translates to:
  /// **'New gated quests will appear here when there is something to unlock later.'**
  String get progQuestsEmptyLockedCaption;

  /// No description provided for @progQuestsEmptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed quests yet.'**
  String get progQuestsEmptyCompletedTitle;

  /// No description provided for @progQuestsEmptyCompletedCaption.
  ///
  /// In en, this message translates to:
  /// **'Your finished milestones will appear here.'**
  String get progQuestsEmptyCompletedCaption;

  /// No description provided for @progQuestStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get progQuestStatusActive;

  /// No description provided for @progQuestStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get progQuestStatusLocked;

  /// No description provided for @progQuestStatusClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get progQuestStatusClaimed;

  /// No description provided for @progQuestStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get progQuestStatusCompleted;

  /// No description provided for @progQuestClaimAll.
  ///
  /// In en, this message translates to:
  /// **'Claim all quests'**
  String get progQuestClaimAll;

  /// No description provided for @progQuestClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim quest'**
  String get progQuestClaim;

  /// No description provided for @progQuestCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed {time}'**
  String progQuestCompletedOn(String time);

  /// No description provided for @progProgressRatio.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target}'**
  String progProgressRatio(int current, int target);

  /// No description provided for @progPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String progPercent(int value);

  /// No description provided for @progAchievementsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get progAchievementsSectionLabel;

  /// No description provided for @progAchievementsSectionCaption.
  ///
  /// In en, this message translates to:
  /// **'Unlocked badges and current progress.'**
  String get progAchievementsSectionCaption;

  /// No description provided for @progAchievementsUnlockedHeader.
  ///
  /// In en, this message translates to:
  /// **'UNLOCKED'**
  String get progAchievementsUnlockedHeader;

  /// No description provided for @progAchievementsInProgressHeader.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get progAchievementsInProgressHeader;

  /// No description provided for @progAchievementsEmptyUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'No achievements unlocked yet.'**
  String get progAchievementsEmptyUnlockedTitle;

  /// No description provided for @progAchievementsEmptyUnlockedCaption.
  ///
  /// In en, this message translates to:
  /// **'Your earned badges will light up here.'**
  String get progAchievementsEmptyUnlockedCaption;

  /// No description provided for @progAchievementsEmptyInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything in the current catalog is unlocked.'**
  String get progAchievementsEmptyInProgressTitle;

  /// No description provided for @progAchievementsEmptyInProgressCaption.
  ///
  /// In en, this message translates to:
  /// **'Add more achievements to expand the journey.'**
  String get progAchievementsEmptyInProgressCaption;

  /// No description provided for @progAchievementStatusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get progAchievementStatusUnlocked;

  /// No description provided for @progAchievementStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get progAchievementStatusInProgress;

  /// No description provided for @progRewardsSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Rewards'**
  String get progRewardsSectionLabel;

  /// No description provided for @progRewardsSectionCaption.
  ///
  /// In en, this message translates to:
  /// **'Latest XP grants earned across your domains.'**
  String get progRewardsSectionCaption;

  /// No description provided for @progRewardsPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Rewards'**
  String get progRewardsPendingTitle;

  /// No description provided for @progRewardsPendingCaption.
  ///
  /// In en, this message translates to:
  /// **'Goal-bound rewards unlock after the day or week closes. Claiming adds XP to your profile.'**
  String get progRewardsPendingCaption;

  /// No description provided for @progRewardsClaimAll.
  ///
  /// In en, this message translates to:
  /// **'Claim all'**
  String get progRewardsClaimAll;

  /// No description provided for @progRewardsClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get progRewardsClaim;

  /// No description provided for @progRewardsUnlockedAt.
  ///
  /// In en, this message translates to:
  /// **'Unlocked {time}'**
  String progRewardsUnlockedAt(String time);

  /// No description provided for @progRewardDetail.
  ///
  /// In en, this message translates to:
  /// **'Target {target} {unit} | Actual {actual} {unit}'**
  String progRewardDetail(String target, String unit, String actual);

  /// No description provided for @progRewardsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rewards granted yet.'**
  String get progRewardsEmptyTitle;

  /// No description provided for @progRewardsEmptyCaption.
  ///
  /// In en, this message translates to:
  /// **'Completed goals will start filling your journal.'**
  String get progRewardsEmptyCaption;

  /// No description provided for @progRewardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{domain} · +{xp} XP'**
  String progRewardSubtitle(String domain, int xp);

  /// No description provided for @progDomainSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get progDomainSteps;

  /// No description provided for @progDomainNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get progDomainNutrition;

  /// No description provided for @progDomainSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get progDomainSleep;

  /// No description provided for @progDomainActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get progDomainActivity;

  /// No description provided for @progRuleDailySteps.
  ///
  /// In en, this message translates to:
  /// **'Daily Steps'**
  String get progRuleDailySteps;

  /// No description provided for @progRuleDailyCalories.
  ///
  /// In en, this message translates to:
  /// **'Calorie Target'**
  String get progRuleDailyCalories;

  /// No description provided for @progRuleDailyProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein Target'**
  String get progRuleDailyProtein;

  /// No description provided for @progRuleDailySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep Target'**
  String get progRuleDailySleep;

  /// No description provided for @progRuleWeeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get progRuleWeeklyActivity;

  /// No description provided for @progRuleDailyWeightLog.
  ///
  /// In en, this message translates to:
  /// **'Weight Log'**
  String get progRuleDailyWeightLog;

  /// No description provided for @progRuleDailyWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight Goal'**
  String get progRuleDailyWeightGoal;

  /// No description provided for @progRewardDetailWeightLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged: {actual} kg'**
  String progRewardDetailWeightLogged(String actual);

  /// No description provided for @progQuestEarnFirstRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn First Reward'**
  String get progQuestEarnFirstRewardTitle;

  /// No description provided for @progQuestEarnFirstRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn your first progression reward.'**
  String get progQuestEarnFirstRewardDesc;

  /// No description provided for @progQuestDailyTwoGoalsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Double Win'**
  String get progQuestDailyTwoGoalsTodayTitle;

  /// No description provided for @progQuestDailyTwoGoalsTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete any 2 daily goals in the current day.'**
  String get progQuestDailyTwoGoalsTodayDesc;

  /// No description provided for @progQuestDailyTripleWinTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Triple Win'**
  String get progQuestDailyTripleWinTodayTitle;

  /// No description provided for @progQuestDailyTripleWinTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete any 3 daily goals in the current day.'**
  String get progQuestDailyTripleWinTodayDesc;

  /// No description provided for @progQuestDailyFourPillarsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Four Pillars'**
  String get progQuestDailyFourPillarsTodayTitle;

  /// No description provided for @progQuestDailyFourPillarsTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete all 4 daily goals in the current day.'**
  String get progQuestDailyFourPillarsTodayDesc;

  /// No description provided for @progQuestDailyNutritionComboTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Combo'**
  String get progQuestDailyNutritionComboTodayTitle;

  /// No description provided for @progQuestDailyNutritionComboTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete both calorie and protein goals in the current day.'**
  String get progQuestDailyNutritionComboTodayDesc;

  /// No description provided for @progQuestDailyRecoveryFocusTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Focus'**
  String get progQuestDailyRecoveryFocusTodayTitle;

  /// No description provided for @progQuestDailyRecoveryFocusTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete both steps and sleep goals in the current day.'**
  String get progQuestDailyRecoveryFocusTodayDesc;

  /// No description provided for @progQuestDailyStepsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Step Goal'**
  String get progQuestDailyStepsTodayTitle;

  /// No description provided for @progQuestDailyStepsTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule in the current day.'**
  String get progQuestDailyStepsTodayDesc;

  /// No description provided for @progQuestDailyCaloriesTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Calorie Goal'**
  String get progQuestDailyCaloriesTodayTitle;

  /// No description provided for @progQuestDailyCaloriesTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily calorie rule in the current day.'**
  String get progQuestDailyCaloriesTodayDesc;

  /// No description provided for @progQuestDailyProteinTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Protein Goal'**
  String get progQuestDailyProteinTodayTitle;

  /// No description provided for @progQuestDailyProteinTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily protein rule in the current day.'**
  String get progQuestDailyProteinTodayDesc;

  /// No description provided for @progQuestDailySleepTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sleep Goal'**
  String get progQuestDailySleepTodayTitle;

  /// No description provided for @progQuestDailySleepTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily sleep rule in the current day.'**
  String get progQuestDailySleepTodayDesc;

  /// No description provided for @progQuestReach500XpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 500 XP'**
  String get progQuestReach500XpTitle;

  /// No description provided for @progQuestReach500XpDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate at least 500 XP.'**
  String get progQuestReach500XpDesc;

  /// No description provided for @progQuestReach2000XpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 2,000 XP'**
  String get progQuestReach2000XpTitle;

  /// No description provided for @progQuestReach2000XpDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate at least 2,000 XP.'**
  String get progQuestReach2000XpDesc;

  /// No description provided for @progQuestReach5000XpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 5,000 XP'**
  String get progQuestReach5000XpTitle;

  /// No description provided for @progQuestReach5000XpDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate at least 5,000 XP.'**
  String get progQuestReach5000XpDesc;

  /// No description provided for @progQuestEarn25RewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn 25 Rewards'**
  String get progQuestEarn25RewardsTitle;

  /// No description provided for @progQuestEarn25RewardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect 25 progression rewards in total.'**
  String get progQuestEarn25RewardsDesc;

  /// No description provided for @progQuestEarn100RewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn 100 Rewards'**
  String get progQuestEarn100RewardsTitle;

  /// No description provided for @progQuestEarn100RewardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect 100 progression rewards in total.'**
  String get progQuestEarn100RewardsDesc;

  /// No description provided for @progQuestStepsStreak3Title.
  ///
  /// In en, this message translates to:
  /// **'Steps Streak'**
  String get progQuestStepsStreak3Title;

  /// No description provided for @progQuestStepsStreak3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule 3 periods in a row.'**
  String get progQuestStepsStreak3Desc;

  /// No description provided for @progQuestNutritionRewards5Title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Rhythm'**
  String get progQuestNutritionRewards5Title;

  /// No description provided for @progQuestNutritionRewards5Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 5 nutrition rewards.'**
  String get progQuestNutritionRewards5Desc;

  /// No description provided for @progQuestNutritionRewards25Title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Mastery'**
  String get progQuestNutritionRewards25Title;

  /// No description provided for @progQuestNutritionRewards25Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 25 nutrition rewards.'**
  String get progQuestNutritionRewards25Desc;

  /// No description provided for @progQuestTotalSteps100kTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk 100K Steps'**
  String get progQuestTotalSteps100kTitle;

  /// No description provided for @progQuestTotalSteps100kDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 100,000 total steps.'**
  String get progQuestTotalSteps100kDesc;

  /// No description provided for @progQuestTotalSteps500kTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk 500K Steps'**
  String get progQuestTotalSteps500kTitle;

  /// No description provided for @progQuestTotalSteps500kDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 500,000 total steps.'**
  String get progQuestTotalSteps500kDesc;

  /// No description provided for @progQuestWeeklyActivityOnceTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get progQuestWeeklyActivityOnceTitle;

  /// No description provided for @progQuestWeeklyActivityOnceDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule once.'**
  String get progQuestWeeklyActivityOnceDesc;

  /// No description provided for @progQuestWeeklyActivity4Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity Momentum'**
  String get progQuestWeeklyActivity4Title;

  /// No description provided for @progQuestWeeklyActivity4Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 4 times.'**
  String get progQuestWeeklyActivity4Desc;

  /// No description provided for @progQuestWeeklyActivity12Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity Legend'**
  String get progQuestWeeklyActivity12Title;

  /// No description provided for @progQuestWeeklyActivity12Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 12 times.'**
  String get progQuestWeeklyActivity12Desc;

  /// No description provided for @progQuestUnlockStepChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Step Chain'**
  String get progQuestUnlockStepChainTitle;

  /// No description provided for @progQuestUnlockStepChainDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock the Step Chain achievement.'**
  String get progQuestUnlockStepChainDesc;

  /// No description provided for @progQuestStepsStreak7Title.
  ///
  /// In en, this message translates to:
  /// **'Step Discipline'**
  String get progQuestStepsStreak7Title;

  /// No description provided for @progQuestStepsStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule 7 periods in a row.'**
  String get progQuestStepsStreak7Desc;

  /// No description provided for @progQuestStepsStreak14Title.
  ///
  /// In en, this message translates to:
  /// **'Step Guardian'**
  String get progQuestStepsStreak14Title;

  /// No description provided for @progQuestStepsStreak14Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule 14 periods in a row.'**
  String get progQuestStepsStreak14Desc;

  /// No description provided for @progAchievementFirstRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'First Reward'**
  String get progAchievementFirstRewardTitle;

  /// No description provided for @progAchievementFirstRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn your first progression reward.'**
  String get progAchievementFirstRewardDesc;

  /// No description provided for @progAchievementRewardHunter25Title.
  ///
  /// In en, this message translates to:
  /// **'Reward Hunter'**
  String get progAchievementRewardHunter25Title;

  /// No description provided for @progAchievementRewardHunter25Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 25 progression rewards.'**
  String get progAchievementRewardHunter25Desc;

  /// No description provided for @progAchievementRewardHunter100Title.
  ///
  /// In en, this message translates to:
  /// **'Reward Legend'**
  String get progAchievementRewardHunter100Title;

  /// No description provided for @progAchievementRewardHunter100Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 100 progression rewards.'**
  String get progAchievementRewardHunter100Desc;

  /// No description provided for @progAchievementPathfinderTitle.
  ///
  /// In en, this message translates to:
  /// **'Wanderer'**
  String get progAchievementPathfinderTitle;

  /// No description provided for @progAchievementPathfinderDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 5 through earned XP.'**
  String get progAchievementPathfinderDesc;

  /// No description provided for @progAchievementTrailVanguardLevel10Title.
  ///
  /// In en, this message translates to:
  /// **'Pathfinder'**
  String get progAchievementTrailVanguardLevel10Title;

  /// No description provided for @progAchievementTrailVanguardLevel10Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 10 through earned XP.'**
  String get progAchievementTrailVanguardLevel10Desc;

  /// No description provided for @progAchievementForgeKnightLevel15Title.
  ///
  /// In en, this message translates to:
  /// **'Forge Knight'**
  String get progAchievementForgeKnightLevel15Title;

  /// No description provided for @progAchievementForgeKnightLevel15Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 15 through earned XP.'**
  String get progAchievementForgeKnightLevel15Desc;

  /// No description provided for @progAchievementIronWardenLevel20Title.
  ///
  /// In en, this message translates to:
  /// **'Iron Warden'**
  String get progAchievementIronWardenLevel20Title;

  /// No description provided for @progAchievementIronWardenLevel20Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 20 through earned XP.'**
  String get progAchievementIronWardenLevel20Desc;

  /// No description provided for @progAchievementStormHeraldLevel25Title.
  ///
  /// In en, this message translates to:
  /// **'Storm Herald'**
  String get progAchievementStormHeraldLevel25Title;

  /// No description provided for @progAchievementStormHeraldLevel25Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 25 through earned XP.'**
  String get progAchievementStormHeraldLevel25Desc;

  /// No description provided for @progAchievementDawnSentinelLevel30Title.
  ///
  /// In en, this message translates to:
  /// **'Castle Lord'**
  String get progAchievementDawnSentinelLevel30Title;

  /// No description provided for @progAchievementDawnSentinelLevel30Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 30 through earned XP.'**
  String get progAchievementDawnSentinelLevel30Desc;

  /// No description provided for @progAchievementRiftWalkerLevel40Title.
  ///
  /// In en, this message translates to:
  /// **'Dragon Rider'**
  String get progAchievementRiftWalkerLevel40Title;

  /// No description provided for @progAchievementRiftWalkerLevel40Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 40 through earned XP.'**
  String get progAchievementRiftWalkerLevel40Desc;

  /// No description provided for @progAchievementForgeKnight5000Title.
  ///
  /// In en, this message translates to:
  /// **'Forge Knight'**
  String get progAchievementForgeKnight5000Title;

  /// No description provided for @progAchievementForgeKnight5000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 5,000 XP.'**
  String get progAchievementForgeKnight5000Desc;

  /// No description provided for @progAchievementLivingLegend15000Title.
  ///
  /// In en, this message translates to:
  /// **'Living Legend'**
  String get progAchievementLivingLegend15000Title;

  /// No description provided for @progAchievementLivingLegend15000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 15,000 XP.'**
  String get progAchievementLivingLegend15000Desc;

  /// No description provided for @progAchievementXp100000Title.
  ///
  /// In en, this message translates to:
  /// **'Ascendant'**
  String get progAchievementXp100000Title;

  /// No description provided for @progAchievementXp100000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 100,000 XP.'**
  String get progAchievementXp100000Desc;

  /// No description provided for @progAchievementXp1000000Title.
  ///
  /// In en, this message translates to:
  /// **'Radiant Ascension'**
  String get progAchievementXp1000000Title;

  /// No description provided for @progAchievementXp1000000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 1,000,000 XP.'**
  String get progAchievementXp1000000Desc;

  /// No description provided for @progAchievementMythicRangerLevel50Title.
  ///
  /// In en, this message translates to:
  /// **'Mythic Ranger'**
  String get progAchievementMythicRangerLevel50Title;

  /// No description provided for @progAchievementMythicRangerLevel50Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 50 through earned XP.'**
  String get progAchievementMythicRangerLevel50Desc;

  /// No description provided for @progAchievementTitanForgerLevel60Title.
  ///
  /// In en, this message translates to:
  /// **'Titan Forger'**
  String get progAchievementTitanForgerLevel60Title;

  /// No description provided for @progAchievementTitanForgerLevel60Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 60 through earned XP.'**
  String get progAchievementTitanForgerLevel60Desc;

  /// No description provided for @progAchievementAstralChampionLevel70Title.
  ///
  /// In en, this message translates to:
  /// **'Astral Champion'**
  String get progAchievementAstralChampionLevel70Title;

  /// No description provided for @progAchievementAstralChampionLevel70Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 70 through earned XP.'**
  String get progAchievementAstralChampionLevel70Desc;

  /// No description provided for @progAchievementEternalParagonLevel80Title.
  ///
  /// In en, this message translates to:
  /// **'Eternal Paragon'**
  String get progAchievementEternalParagonLevel80Title;

  /// No description provided for @progAchievementEternalParagonLevel80Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 80 through earned XP.'**
  String get progAchievementEternalParagonLevel80Desc;

  /// No description provided for @progAchievementRealmSovereignLevel90Title.
  ///
  /// In en, this message translates to:
  /// **'Realm Sovereign'**
  String get progAchievementRealmSovereignLevel90Title;

  /// No description provided for @progAchievementRealmSovereignLevel90Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 90 through earned XP.'**
  String get progAchievementRealmSovereignLevel90Desc;

  /// No description provided for @progAchievementLivingLegendLevel100Title.
  ///
  /// In en, this message translates to:
  /// **'Living Legend'**
  String get progAchievementLivingLegendLevel100Title;

  /// No description provided for @progAchievementLivingLegendLevel100Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 100 through earned XP.'**
  String get progAchievementLivingLegendLevel100Desc;

  /// No description provided for @progAchievementSteps100kTitle.
  ///
  /// In en, this message translates to:
  /// **'Centurion Walker'**
  String get progAchievementSteps100kTitle;

  /// No description provided for @progAchievementSteps100kDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 100,000 total steps.'**
  String get progAchievementSteps100kDesc;

  /// No description provided for @progAchievementSteps500kTitle.
  ///
  /// In en, this message translates to:
  /// **'Half-Million March'**
  String get progAchievementSteps500kTitle;

  /// No description provided for @progAchievementSteps500kDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 500,000 total steps.'**
  String get progAchievementSteps500kDesc;

  /// No description provided for @progAchievementSteps1000000Title.
  ///
  /// In en, this message translates to:
  /// **'Million Step Myth'**
  String get progAchievementSteps1000000Title;

  /// No description provided for @progAchievementSteps1000000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 1,000,000 total steps.'**
  String get progAchievementSteps1000000Desc;

  /// No description provided for @progAchievementSteps5000000Title.
  ///
  /// In en, this message translates to:
  /// **'Gemstone Path'**
  String get progAchievementSteps5000000Title;

  /// No description provided for @progAchievementSteps5000000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 5,000,000 total steps.'**
  String get progAchievementSteps5000000Desc;

  /// No description provided for @progAchievementSteps10000000Title.
  ///
  /// In en, this message translates to:
  /// **'Summit of Legends'**
  String get progAchievementSteps10000000Title;

  /// No description provided for @progAchievementSteps10000000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 10,000,000 total steps.'**
  String get progAchievementSteps10000000Desc;

  /// No description provided for @progAchievementStepsMonth300kTitle.
  ///
  /// In en, this message translates to:
  /// **'Trail Builder'**
  String get progAchievementStepsMonth300kTitle;

  /// No description provided for @progAchievementStepsMonth300kDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 300,000 steps across any 30-day window.'**
  String get progAchievementStepsMonth300kDesc;

  /// No description provided for @progAchievementStepsMonth600kTitle.
  ///
  /// In en, this message translates to:
  /// **'Iron Pilgrim'**
  String get progAchievementStepsMonth600kTitle;

  /// No description provided for @progAchievementStepsMonth600kDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 600,000 steps across any 30-day window.'**
  String get progAchievementStepsMonth600kDesc;

  /// No description provided for @progAchievementStepChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Step Chain'**
  String get progAchievementStepChainTitle;

  /// No description provided for @progAchievementStepChainDesc.
  ///
  /// In en, this message translates to:
  /// **'Hit the daily steps rule for 3 periods in a row.'**
  String get progAchievementStepChainDesc;

  /// No description provided for @progAchievementStepDisciplineTitle.
  ///
  /// In en, this message translates to:
  /// **'Step Discipline'**
  String get progAchievementStepDisciplineTitle;

  /// No description provided for @progAchievementStepDisciplineDesc.
  ///
  /// In en, this message translates to:
  /// **'Hit the daily steps rule for 7 periods in a row.'**
  String get progAchievementStepDisciplineDesc;

  /// No description provided for @progAchievementStepSovereignTitle.
  ///
  /// In en, this message translates to:
  /// **'Step Sovereign'**
  String get progAchievementStepSovereignTitle;

  /// No description provided for @progAchievementStepSovereignDesc.
  ///
  /// In en, this message translates to:
  /// **'Hit the daily steps rule for 30 periods in a row.'**
  String get progAchievementStepSovereignDesc;

  /// No description provided for @progAchievementStepCenturionTitle.
  ///
  /// In en, this message translates to:
  /// **'Iron Chain'**
  String get progAchievementStepCenturionTitle;

  /// No description provided for @progAchievementStepCenturionDesc.
  ///
  /// In en, this message translates to:
  /// **'Hit the daily steps rule for 100 periods in a row.'**
  String get progAchievementStepCenturionDesc;

  /// No description provided for @progAchievementBalancedRhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced Rhythm'**
  String get progAchievementBalancedRhythmTitle;

  /// No description provided for @progAchievementBalancedRhythmDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn at least one nutrition reward for 3 periods in a row.'**
  String get progAchievementBalancedRhythmDesc;

  /// No description provided for @progAchievementNutritionStreak30Title.
  ///
  /// In en, this message translates to:
  /// **'Macro Momentum'**
  String get progAchievementNutritionStreak30Title;

  /// No description provided for @progAchievementNutritionStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn at least one nutrition reward for 30 periods in a row.'**
  String get progAchievementNutritionStreak30Desc;

  /// No description provided for @progAchievementNutritionStreak100Title.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Discipline'**
  String get progAchievementNutritionStreak100Title;

  /// No description provided for @progAchievementNutritionStreak100Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn at least one nutrition reward for 100 periods in a row.'**
  String get progAchievementNutritionStreak100Desc;

  /// No description provided for @progAchievementNutritionRewards25Title.
  ///
  /// In en, this message translates to:
  /// **'Macro Maestro'**
  String get progAchievementNutritionRewards25Title;

  /// No description provided for @progAchievementNutritionRewards25Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 25 nutrition rewards.'**
  String get progAchievementNutritionRewards25Desc;

  /// No description provided for @progAchievementWeeklyWarriorTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Warrior'**
  String get progAchievementWeeklyWarriorTitle;

  /// No description provided for @progAchievementWeeklyWarriorDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule at least once.'**
  String get progAchievementWeeklyWarriorDesc;

  /// No description provided for @progAchievementWeeklyActivity4Title.
  ///
  /// In en, this message translates to:
  /// **'Activity Vanguard'**
  String get progAchievementWeeklyActivity4Title;

  /// No description provided for @progAchievementWeeklyActivity4Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 4 times.'**
  String get progAchievementWeeklyActivity4Desc;

  /// No description provided for @progAchievementWeeklyActivity12Title.
  ///
  /// In en, this message translates to:
  /// **'Seasoned Mover'**
  String get progAchievementWeeklyActivity12Title;

  /// No description provided for @progAchievementWeeklyActivity12Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 12 times.'**
  String get progAchievementWeeklyActivity12Desc;

  /// No description provided for @progAchievementWeeklyActivity24Title.
  ///
  /// In en, this message translates to:
  /// **'Unbroken Momentum'**
  String get progAchievementWeeklyActivity24Title;

  /// No description provided for @progAchievementWeeklyActivity24Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 24 times.'**
  String get progAchievementWeeklyActivity24Desc;

  /// No description provided for @progAchievementWeeklyActivity52Title.
  ///
  /// In en, this message translates to:
  /// **'Yearlong Engine'**
  String get progAchievementWeeklyActivity52Title;

  /// No description provided for @progAchievementWeeklyActivity52Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 52 times.'**
  String get progAchievementWeeklyActivity52Desc;

  /// No description provided for @progAchievementSleep250hTitle.
  ///
  /// In en, this message translates to:
  /// **'Rested Soul'**
  String get progAchievementSleep250hTitle;

  /// No description provided for @progAchievementSleep250hDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 250 hours of tracked sleep.'**
  String get progAchievementSleep250hDesc;

  /// No description provided for @progAchievementSleep1000hTitle.
  ///
  /// In en, this message translates to:
  /// **'Dream Archivist'**
  String get progAchievementSleep1000hTitle;

  /// No description provided for @progAchievementSleep1000hDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 1,000 hours of tracked sleep.'**
  String get progAchievementSleep1000hDesc;

  /// No description provided for @progAchievementSleepMonth225hTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep Reset'**
  String get progAchievementSleepMonth225hTitle;

  /// No description provided for @progAchievementSleepMonth225hDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 225 hours of sleep across any 30-day window.'**
  String get progAchievementSleepMonth225hDesc;

  /// No description provided for @progAchievementSleepMonth240hTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect Recovery'**
  String get progAchievementSleepMonth240hTitle;

  /// No description provided for @progAchievementSleepMonth240hDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 240 hours of sleep across any 30-day window.'**
  String get progAchievementSleepMonth240hDesc;

  /// No description provided for @progAchievementDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get progAchievementDifficultyEasy;

  /// No description provided for @progAchievementDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get progAchievementDifficultyMedium;

  /// No description provided for @progAchievementDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get progAchievementDifficultyHard;

  /// No description provided for @progAchievementDifficultyExtraHard.
  ///
  /// In en, this message translates to:
  /// **'Extra Hard'**
  String get progAchievementDifficultyExtraHard;

  /// No description provided for @progQuestCriterionTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Based on total XP'**
  String get progQuestCriterionTotalXp;

  /// No description provided for @progQuestCriterionRewardCountWithRule.
  ///
  /// In en, this message translates to:
  /// **'Based on {rule}'**
  String progQuestCriterionRewardCountWithRule(String rule);

  /// No description provided for @progQuestCriterionRewardCount.
  ///
  /// In en, this message translates to:
  /// **'Based on reward count'**
  String get progQuestCriterionRewardCount;

  /// No description provided for @progQuestCriterionStreakWithRule.
  ///
  /// In en, this message translates to:
  /// **'Based on {rule} streak'**
  String progQuestCriterionStreakWithRule(String rule);

  /// No description provided for @progQuestCriterionStreakWithDomain.
  ///
  /// In en, this message translates to:
  /// **'Based on {domain} streak'**
  String progQuestCriterionStreakWithDomain(String domain);

  /// No description provided for @progQuestCriterionStreakGeneric.
  ///
  /// In en, this message translates to:
  /// **'Based on streak consistency'**
  String get progQuestCriterionStreakGeneric;

  /// No description provided for @progQuestCriterionTotalRuleValueWithRule.
  ///
  /// In en, this message translates to:
  /// **'Based on total {rule}'**
  String progQuestCriterionTotalRuleValueWithRule(String rule);

  /// No description provided for @progQuestCriterionTotalRuleValueGeneric.
  ///
  /// In en, this message translates to:
  /// **'Based on accumulated total'**
  String get progQuestCriterionTotalRuleValueGeneric;

  /// No description provided for @progQuestCriterionCurrentPeriodRule.
  ///
  /// In en, this message translates to:
  /// **'For the current period: {rule}'**
  String progQuestCriterionCurrentPeriodRule(String rule);

  /// No description provided for @progQuestCriterionCurrentPeriodGeneric.
  ///
  /// In en, this message translates to:
  /// **'For the current period'**
  String get progQuestCriterionCurrentPeriodGeneric;

  /// No description provided for @progQuestCriterionCurrentPeriodRuleSet.
  ///
  /// In en, this message translates to:
  /// **'For a current-period combo'**
  String get progQuestCriterionCurrentPeriodRuleSet;

  /// No description provided for @progQuestCriterionAchievement.
  ///
  /// In en, this message translates to:
  /// **'Based on achievement unlock'**
  String get progQuestCriterionAchievement;

  /// No description provided for @progQuestCriterionCompletionsWithRule.
  ///
  /// In en, this message translates to:
  /// **'Based on {rule} completions'**
  String progQuestCriterionCompletionsWithRule(String rule);

  /// No description provided for @progQuestCriterionCompletionsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Based on rule completions'**
  String get progQuestCriterionCompletionsGeneric;

  /// No description provided for @progQuestCriterionDomainRewardsWithDomain.
  ///
  /// In en, this message translates to:
  /// **'Based on {domain} rewards'**
  String progQuestCriterionDomainRewardsWithDomain(String domain);

  /// No description provided for @progQuestCriterionDomainRewardsGeneric.
  ///
  /// In en, this message translates to:
  /// **'Based on domain rewards'**
  String get progQuestCriterionDomainRewardsGeneric;

  /// Settings section title for the developer tools entry
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get settingsDeveloperTools;

  /// Title of the developer tools screen
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get devtoolsTitle;

  /// No description provided for @journeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Hero Journey'**
  String get journeyTitle;

  /// No description provided for @journeyPreviewKicker.
  ///
  /// In en, this message translates to:
  /// **'HERO JOURNEY'**
  String get journeyPreviewKicker;

  /// No description provided for @journeyOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get journeyOpenMap;

  /// No description provided for @journeyPanHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe for more'**
  String get journeyPanHint;

  /// No description provided for @journeyHistoryHeader.
  ///
  /// In en, this message translates to:
  /// **'Milestone history'**
  String get journeyHistoryHeader;

  /// No description provided for @journeyLastMilestone.
  ///
  /// In en, this message translates to:
  /// **'Last milestone'**
  String get journeyLastMilestone;

  /// No description provided for @journeyNextGoal.
  ///
  /// In en, this message translates to:
  /// **'Next goal'**
  String get journeyNextGoal;

  /// No description provided for @journeyTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get journeyTitleLabel;

  /// No description provided for @journeyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get journeyFilterAll;

  /// No description provided for @journeyFilterLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get journeyFilterLevels;

  /// No description provided for @journeyFilterTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get journeyFilterTitles;

  /// No description provided for @journeyFilterAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get journeyFilterAchievements;

  /// No description provided for @journeyFilterQuests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get journeyFilterQuests;

  /// No description provided for @journeyEventLevelReached.
  ///
  /// In en, this message translates to:
  /// **'Level reached'**
  String get journeyEventLevelReached;

  /// No description provided for @journeyEventTitleUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Title unlocked'**
  String get journeyEventTitleUnlocked;

  /// No description provided for @journeyEventAchievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get journeyEventAchievementUnlocked;

  /// No description provided for @journeyEventQuestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Quest completed'**
  String get journeyEventQuestCompleted;

  /// No description provided for @journeyMilestoneReached.
  ///
  /// In en, this message translates to:
  /// **'Milestone reached'**
  String get journeyMilestoneReached;

  /// No description provided for @journeyBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get journeyBadgeLocked;

  /// No description provided for @journeyBadgeHere.
  ///
  /// In en, this message translates to:
  /// **'HERE'**
  String get journeyBadgeHere;

  /// No description provided for @journeyTypeLevel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get journeyTypeLevel;

  /// No description provided for @journeyTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get journeyTypeTitle;

  /// No description provided for @journeyTypeAchievement.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT'**
  String get journeyTypeAchievement;

  /// No description provided for @journeyTypeQuest.
  ///
  /// In en, this message translates to:
  /// **'QUEST'**
  String get journeyTypeQuest;

  /// No description provided for @journeyEmptyMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts now'**
  String get journeyEmptyMapTitle;

  /// No description provided for @journeyEmptyMapBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a quest, unlock an achievement or log activity — milestones will start appearing on the map.'**
  String get journeyEmptyMapBody;

  /// No description provided for @journeyEmptyFeedAll.
  ///
  /// In en, this message translates to:
  /// **'No milestones yet. Complete a quest or unlock an achievement.'**
  String get journeyEmptyFeedAll;

  /// No description provided for @journeyEmptyFeedFiltered.
  ///
  /// In en, this message translates to:
  /// **'No milestones in this category yet.'**
  String get journeyEmptyFeedFiltered;

  /// No description provided for @journeyMiniMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Milestones will appear once you reach your first goal.'**
  String get journeyMiniMapEmpty;

  /// No description provided for @journeyRelativeNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get journeyRelativeNow;

  /// No description provided for @journeyRelativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String journeyRelativeMinutes(int count);

  /// No description provided for @journeyRelativeHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String journeyRelativeHours(int count);

  /// No description provided for @journeyRelativeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String journeyRelativeDays(int count);

  /// No description provided for @journeyRelativeWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String journeyRelativeWeeks(int count);

  /// No description provided for @journeyRelativeMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String journeyRelativeMonths(int count);

  /// No description provided for @journeyRelativeYears.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String journeyRelativeYears(int count);

  /// No description provided for @journeyStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Journey begins'**
  String get journeyStartLabel;

  /// No description provided for @journeyStartDescription.
  ///
  /// In en, this message translates to:
  /// **'The beginning of your hero journey.'**
  String get journeyStartDescription;

  /// No description provided for @journeyStartSublabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {title}'**
  String journeyStartSublabel(Object level, Object title);

  /// No description provided for @journeyLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String journeyLevelLabel(Object level);

  /// No description provided for @journeyLevelWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {title}'**
  String journeyLevelWithTitle(Object level, Object title);

  /// No description provided for @journeyTotalXp.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP total'**
  String journeyTotalXp(Object xp);

  /// No description provided for @progLevelTitle1.
  ///
  /// In en, this message translates to:
  /// **'Wanderer'**
  String get progLevelTitle1;

  /// No description provided for @progLevelTitle5.
  ///
  /// In en, this message translates to:
  /// **'Trail Explorer'**
  String get progLevelTitle5;

  /// No description provided for @progLevelTitle10.
  ///
  /// In en, this message translates to:
  /// **'Ranger of the Wildwood'**
  String get progLevelTitle10;

  /// No description provided for @progLevelTitle15.
  ///
  /// In en, this message translates to:
  /// **'Guardian of the Pass'**
  String get progLevelTitle15;

  /// No description provided for @progLevelTitle20.
  ///
  /// In en, this message translates to:
  /// **'Conqueror of Ruins'**
  String get progLevelTitle20;

  /// No description provided for @progLevelTitle25.
  ///
  /// In en, this message translates to:
  /// **'Keeper of the Old Gates'**
  String get progLevelTitle25;

  /// No description provided for @progLevelTitle30.
  ///
  /// In en, this message translates to:
  /// **'Delver of the Depths'**
  String get progLevelTitle30;

  /// No description provided for @progLevelTitle40.
  ///
  /// In en, this message translates to:
  /// **'Dwarven Ally'**
  String get progLevelTitle40;

  /// No description provided for @progLevelTitle50.
  ///
  /// In en, this message translates to:
  /// **'Lord of the Underground Paths'**
  String get progLevelTitle50;

  /// No description provided for @progLevelTitle60.
  ///
  /// In en, this message translates to:
  /// **'Guardian of Frost'**
  String get progLevelTitle60;

  /// No description provided for @progLevelTitle70.
  ///
  /// In en, this message translates to:
  /// **'Icewalker'**
  String get progLevelTitle70;

  /// No description provided for @progLevelTitle80.
  ///
  /// In en, this message translates to:
  /// **'Mountain Challenger'**
  String get progLevelTitle80;

  /// No description provided for @progLevelTitle90.
  ///
  /// In en, this message translates to:
  /// **'Dragon Rider'**
  String get progLevelTitle90;

  /// No description provided for @progLevelTitle100.
  ///
  /// In en, this message translates to:
  /// **'Lord of Dragonrock'**
  String get progLevelTitle100;

  /// No description provided for @progLevelAchievementDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach level {level} through earned XP.'**
  String progLevelAchievementDesc(int level);
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
