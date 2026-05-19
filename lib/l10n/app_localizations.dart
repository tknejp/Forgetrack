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

  /// AppBar title for the Steps screen
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get screenSteps;

  /// AppBar title for the Nutrition screen
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get screenNutrition;

  /// Title of the per-day calorie trend chart on the Nutrition screen
  ///
  /// In en, this message translates to:
  /// **'Calorie trend'**
  String get nutritionEnergyTrend;

  /// Title of the per-day macro trend chart with a Protein/Fat/Carbs toggle
  ///
  /// In en, this message translates to:
  /// **'Macro trend'**
  String get nutritionMacroTrend;

  /// Header for the hydration card showing water intake vs goal
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get nutritionHydrationTitle;

  /// Header for the per-period macro detail card
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get nutritionMacrosDetailTitle;

  /// Header for the per-meal breakdown card on the Nutrition screen
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get nutritionMealsTitle;

  /// Empty-state copy when the selected day has no logged meals
  ///
  /// In en, this message translates to:
  /// **'No meals logged'**
  String get nutritionMealsEmpty;

  /// Plural item count shown in meal headers, e.g. '4 items'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no items} one{1 item} other{{count} items}}'**
  String nutritionFoodItems(int count);

  /// Header for the daily energy balance card (basal + active vs intake)
  ///
  /// In en, this message translates to:
  /// **'Energy balance'**
  String get nutritionBalanceTitle;

  /// BMR label inside the energy balance card
  ///
  /// In en, this message translates to:
  /// **'Basal'**
  String get nutritionBalanceBasal;

  /// Active calories label inside the energy balance card
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get nutritionBalanceActive;

  /// Total output (basal + active) label inside the energy balance card
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get nutritionBalanceOutput;

  /// Calorie intake label inside the energy balance card
  ///
  /// In en, this message translates to:
  /// **'Intake'**
  String get nutritionBalanceIntake;

  /// Badge label when intake < output
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get nutritionBalanceDeficit;

  /// Badge label when intake > output
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get nutritionBalanceSurplus;

  /// Hint shown in week/month modes explaining that meal & balance cards live in day mode
  ///
  /// In en, this message translates to:
  /// **'Meal & balance details only available in day mode'**
  String get nutritionMealsOnlyDayMode;

  /// AppBar title for the Body screen
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get screenBody;

  /// Label for consecutive-days-at-goal streak count on the Steps screen
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get stepsCurrentStreak;

  /// Subtitle on the Steps shortcut card shown on the Activities screen
  ///
  /// In en, this message translates to:
  /// **'Daily steps & goal'**
  String get stepsLinkSubtitle;

  /// Section header for the activity-type breakdown bar chart on the Activities screen
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get activitiesByType;

  /// Subtitle on the Activities shortcut card shown on the Steps screen
  ///
  /// In en, this message translates to:
  /// **'Workouts, calories, time'**
  String get activitiesLinkSubtitle;

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

  /// Pill button that resets the period navigator back to the current day / week / month
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

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

  /// Label for body water mass
  ///
  /// In en, this message translates to:
  /// **'Body water'**
  String get weightBodyWater;

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

  /// Label for the notifications toggle setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Subtitle for the notifications toggle setting
  ///
  /// In en, this message translates to:
  /// **'Allow reminders, quest updates and social alerts.'**
  String get settingsNotificationsSubtitle;

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

  /// Settings section header for Health Connect integration
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get settingsHealthConnectSection;

  /// Settings row label that opens Health Connect settings
  ///
  /// In en, this message translates to:
  /// **'Open Health Connect'**
  String get settingsHealthConnectOpen;

  /// Settings row subtitle for opening Health Connect
  ///
  /// In en, this message translates to:
  /// **'Review connected apps, data sources and Health Connect settings.'**
  String get settingsHealthConnectOpenBody;

  /// Settings row label to request/manage Health Connect permissions
  ///
  /// In en, this message translates to:
  /// **'Manage permissions'**
  String get settingsHealthConnectPermissions;

  /// Settings row subtitle for Health Connect permissions
  ///
  /// In en, this message translates to:
  /// **'Grant access to steps, calories, weight, sleep and activity data.'**
  String get settingsHealthConnectPermissionsBody;

  /// Status label when Health Connect permissions are granted
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsHealthConnectConnected;

  /// Status label when Health Connect permissions are missing
  ///
  /// In en, this message translates to:
  /// **'Needs access'**
  String get settingsHealthConnectNeedsAccess;

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

  /// Tertiary action on the Health Connect prompt card that lets the user view previously cached fitness data without re-granting permissions
  ///
  /// In en, this message translates to:
  /// **'Show saved data'**
  String get healthShowCachedData;

  /// Inline banner shown above HC-driven cards when user opted into viewing cached data instead of granting permissions
  ///
  /// In en, this message translates to:
  /// **'Showing saved data — tap to set up Health Connect'**
  String get healthOfflineNotice;

  /// Inline banner shown on the home overview when the device has no network connectivity, so users know data may be stale
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — showing saved data'**
  String get homeOfflineBanner;

  /// Inline banner shown above the calorie card when the user opted into viewing cached nutrition data instead of logging in
  ///
  /// In en, this message translates to:
  /// **'Showing saved data — tap to connect Kalorické Tabulky'**
  String get ktOfflineNotice;

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

  /// Sleep stage: deep sleep
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get sleepStageDeep;

  /// Sleep stage: light sleep
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get sleepStageLight;

  /// Sleep stage: REM sleep
  ///
  /// In en, this message translates to:
  /// **'REM'**
  String get sleepStageRem;

  /// Sleep stage: awake during the night
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get sleepStageAwake;

  /// Title of the sleep-stage timeline card
  ///
  /// In en, this message translates to:
  /// **'Sleep stages'**
  String get sleepStagesTitle;

  /// Title of the stage percentage / duration breakdown card
  ///
  /// In en, this message translates to:
  /// **'Stage breakdown'**
  String get sleepStagesBreakdown;

  /// Title of the trend card showing total sleep over time
  ///
  /// In en, this message translates to:
  /// **'Sleep duration trend'**
  String get sleepDurationTrend;

  /// Title of the trend card showing deep sleep over time
  ///
  /// In en, this message translates to:
  /// **'Deep sleep'**
  String get sleepDeepTrend;

  /// Title of the trend card showing REM sleep over time
  ///
  /// In en, this message translates to:
  /// **'REM sleep'**
  String get sleepRemTrend;

  /// Empty state shown on the stage timeline when no stage data is recorded
  ///
  /// In en, this message translates to:
  /// **'Stage data is unavailable'**
  String get sleepNoStageData;

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

  /// Section header above the per-activity claim list in the expanded home activity card.
  ///
  /// In en, this message translates to:
  /// **'Claim XP per workout'**
  String get homeActivityClaimsHeader;

  /// Bulk-claim button inside the backfill banner. xp is the total preview XP across every claimable workout in the retroactive window.
  ///
  /// In en, this message translates to:
  /// **'Claim all · +{xp} XP'**
  String activitiesBackfillClaimAll(int xp);

  /// Snackbar shown after a successful bulk claim.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Claimed {count} workout · +{xp} XP} other{Claimed {count} workouts · +{xp} XP}}'**
  String activitiesBackfillClaimedToast(int count, int xp);

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

  /// Header title on the single-activity detail screen
  ///
  /// In en, this message translates to:
  /// **'Activity detail'**
  String get activityDetailTitle;

  /// Label for activity start time
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get activityDetailStart;

  /// Label for activity end time
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get activityDetailEnd;

  /// Label for pace (time per km)
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get activityDetailPace;

  /// Label for activity distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get activityDetailDistance;

  /// Header for the activity comparison chart
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get activityDetailComparison;

  /// Placeholder shown when an activity has no GPS route to render on a map
  ///
  /// In en, this message translates to:
  /// **'GPS data unavailable'**
  String get activityDetailNoMap;

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

  /// Goal label: daily fiber intake target.
  ///
  /// In en, this message translates to:
  /// **'Daily fiber'**
  String get goalDailyFiber;

  /// One-line summary on the nutrition section header. Macros are abbreviated (P/F/C/Fi) so the summary fits without wrapping.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {protein}P / {fat}F / {carbs}C / {fiber}Fi g'**
  String settingsGoalsNutritionSummary(
      String kcal, String protein, String fat, String carbs, String fiber);

  /// Info-row label inside the nutrition section that shows the kcal total derived from current macro targets (4 kcal/g protein, 9 kcal/g fat, 4 kcal/g carbs).
  ///
  /// In en, this message translates to:
  /// **'Calories from macros'**
  String get settingsGoalsMacroBreakdownLabel;

  /// Sub-label warning when the macro-derived kcal total drifts from the calorie target by more than tolerance.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match calorie goal ({delta, plural, =0{matches} other{{delta} kcal off}})'**
  String settingsGoalsMacroBreakdownMismatch(int delta);

  /// Nicer header for the activity goals expandable in settings.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get settingsGoalsActivityHeader;

  /// Nicer header for the nutrition goals expandable in settings.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get settingsGoalsNutritionHeader;

  /// Nicer header for the sleep goals expandable in settings.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get settingsGoalsSleepHeader;

  /// Nicer header for the body goals expandable in settings.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get settingsGoalsBodyHeader;

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

  /// Shown when the user cancels the Google sign-in / authorization sheet
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled. Please sign in to export.'**
  String get exportErrorSignInCancelled;

  /// Shown when the export fails due to a network/connectivity error
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get exportErrorNetwork;

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
  /// **'Active quests first, completed ones below.'**
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

  /// No description provided for @progQuestsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String progQuestsActiveCount(int count);

  /// No description provided for @progQuestsDailyGoalsHeader.
  ///
  /// In en, this message translates to:
  /// **'DAILY GOALS'**
  String get progQuestsDailyGoalsHeader;

  /// No description provided for @progQuestsDailyTasksHeader.
  ///
  /// In en, this message translates to:
  /// **'DAILY TASKS'**
  String get progQuestsDailyTasksHeader;

  /// No description provided for @progQuestsDailyTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Tasks rotate every day — completed ones stay visible until midnight.'**
  String get progQuestsDailyTasksHint;

  /// No description provided for @progQuestsDailyComboHeader.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S COMBO'**
  String get progQuestsDailyComboHeader;

  /// No description provided for @progQuestsWeeklyHeader.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get progQuestsWeeklyHeader;

  /// No description provided for @progQuestsChapterHeader.
  ///
  /// In en, this message translates to:
  /// **'JOURNEY CHAPTERS'**
  String get progQuestsChapterHeader;

  /// No description provided for @progQuestsComboHeader.
  ///
  /// In en, this message translates to:
  /// **'DAILY COMBO'**
  String get progQuestsComboHeader;

  /// No description provided for @progQuestsDailyChallengeHeader.
  ///
  /// In en, this message translates to:
  /// **'DAILY QUEST'**
  String get progQuestsDailyChallengeHeader;

  /// No description provided for @progQuestsChapterSideQuestsHeader.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER SIDE QUESTS'**
  String get progQuestsChapterSideQuestsHeader;

  /// No description provided for @progSidePilgrimMorningWalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim\'s morning walk'**
  String get progSidePilgrimMorningWalkTitle;

  /// No description provided for @progSidePilgrimMorningWalkDesc.
  ///
  /// In en, this message translates to:
  /// **'Set out on the path right after waking — meet today\'s steps and activity goals.'**
  String get progSidePilgrimMorningWalkDesc;

  /// No description provided for @progSidePilgrimQuietRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim\'s quiet rest'**
  String get progSidePilgrimQuietRestTitle;

  /// No description provided for @progSidePilgrimQuietRestDesc.
  ///
  /// In en, this message translates to:
  /// **'A pilgrim\'s body needs rest — meet today\'s sleep and protein goals.'**
  String get progSidePilgrimQuietRestDesc;

  /// No description provided for @progSideForestBriskwalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Brisk walk through the woods'**
  String get progSideForestBriskwalkTitle;

  /// No description provided for @progSideForestBriskwalkDesc.
  ///
  /// In en, this message translates to:
  /// **'The forest rewards steady movement — finish today\'s steps and active minutes.'**
  String get progSideForestBriskwalkDesc;

  /// No description provided for @progSideForestCampTitle.
  ///
  /// In en, this message translates to:
  /// **'Camp beneath the trees'**
  String get progSideForestCampTitle;

  /// No description provided for @progSideForestCampDesc.
  ///
  /// In en, this message translates to:
  /// **'Quiet night in the woods — meet today\'s sleep, protein and calorie goals.'**
  String get progSideForestCampDesc;

  /// No description provided for @progSideForestClearingTitle.
  ///
  /// In en, this message translates to:
  /// **'Clearing at first light'**
  String get progSideForestClearingTitle;

  /// No description provided for @progSideForestClearingDesc.
  ///
  /// In en, this message translates to:
  /// **'The clearing tests every angle — finish today\'s steps, activity, sleep and protein.'**
  String get progSideForestClearingDesc;

  /// No description provided for @progSideMineDeepShaftTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep shaft'**
  String get progSideMineDeepShaftTitle;

  /// No description provided for @progSideMineDeepShaftDesc.
  ///
  /// In en, this message translates to:
  /// **'A day spent in the deep — finish today\'s steps, activity and sleep.'**
  String get progSideMineDeepShaftDesc;

  /// No description provided for @progSideMineForgeFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Forge at the mountain\'s core'**
  String get progSideMineForgeFinaleTitle;

  /// No description provided for @progSideMineForgeFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'The forge fires only for complete crews — meet five daily goals today, food included.'**
  String get progSideMineForgeFinaleDesc;

  /// No description provided for @progSidePactMarchTitle.
  ///
  /// In en, this message translates to:
  /// **'Pact march'**
  String get progSidePactMarchTitle;

  /// No description provided for @progSidePactMarchDesc.
  ///
  /// In en, this message translates to:
  /// **'The pact marches all day — meet four basics today (steps, activity, sleep, calories).'**
  String get progSidePactMarchDesc;

  /// No description provided for @progSidePactFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Seal of the pact'**
  String get progSidePactFinaleTitle;

  /// No description provided for @progSidePactFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'The pact peaks in a perfect blend — meet six different daily goals today.'**
  String get progSidePactFinaleDesc;

  /// No description provided for @progSideRuinsSteadyDawnTitle.
  ///
  /// In en, this message translates to:
  /// **'Steady dawn'**
  String get progSideRuinsSteadyDawnTitle;

  /// No description provided for @progSideRuinsSteadyDawnDesc.
  ///
  /// In en, this message translates to:
  /// **'Discipline starts at sunrise — finish today\'s steps, sleep and protein.'**
  String get progSideRuinsSteadyDawnDesc;

  /// No description provided for @progSideRuinsIronIntakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Iron intake'**
  String get progSideRuinsIronIntakeTitle;

  /// No description provided for @progSideRuinsIronIntakeDesc.
  ///
  /// In en, this message translates to:
  /// **'Three macros before dusk — meet any three of today\'s nutrition goals.'**
  String get progSideRuinsIronIntakeDesc;

  /// No description provided for @progSideMineTorchbearerTitle.
  ///
  /// In en, this message translates to:
  /// **'Torchbearer'**
  String get progSideMineTorchbearerTitle;

  /// No description provided for @progSideMineTorchbearerDesc.
  ///
  /// In en, this message translates to:
  /// **'Open a new shaft — finish today\'s steps and active minutes.'**
  String get progSideMineTorchbearerDesc;

  /// No description provided for @progSideMineLongHaulTitle.
  ///
  /// In en, this message translates to:
  /// **'Long haul'**
  String get progSideMineLongHaulTitle;

  /// No description provided for @progSideMineLongHaulDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay deep all day — finish today\'s steps, activity and sleep.'**
  String get progSideMineLongHaulDesc;

  /// No description provided for @progSideForgeMorningAnvilTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning anvil'**
  String get progSideForgeMorningAnvilTitle;

  /// No description provided for @progSideForgeMorningAnvilDesc.
  ///
  /// In en, this message translates to:
  /// **'Heat the forge before noon — finish today\'s steps and active minutes.'**
  String get progSideForgeMorningAnvilDesc;

  /// No description provided for @progSideForgeFullFurnaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Full furnace'**
  String get progSideForgeFullFurnaceTitle;

  /// No description provided for @progSideForgeFullFurnaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Feed the fire from every side — meet four of today\'s nutrition goals.'**
  String get progSideForgeFullFurnaceDesc;

  /// No description provided for @progSideUnderwayWarmCampTitle.
  ///
  /// In en, this message translates to:
  /// **'Warm camp'**
  String get progSideUnderwayWarmCampTitle;

  /// No description provided for @progSideUnderwayWarmCampDesc.
  ///
  /// In en, this message translates to:
  /// **'The party needs strength — meet today\'s sleep, protein and calorie goals.'**
  String get progSideUnderwayWarmCampDesc;

  /// No description provided for @progSideUnderwayLongWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Long watch'**
  String get progSideUnderwayLongWatchTitle;

  /// No description provided for @progSideUnderwayLongWatchDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold the pace into the night — finish today\'s steps, activity and sleep.'**
  String get progSideUnderwayLongWatchDesc;

  /// No description provided for @progSideFrostboundFirstLightTitle.
  ///
  /// In en, this message translates to:
  /// **'First light of the oath'**
  String get progSideFrostboundFirstLightTitle;

  /// No description provided for @progSideFrostboundFirstLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Move before the frost swallows your tracks — finish today\'s steps and active minutes.'**
  String get progSideFrostboundFirstLightDesc;

  /// No description provided for @progSideFrostboundLongOathTitle.
  ///
  /// In en, this message translates to:
  /// **'Long oath'**
  String get progSideFrostboundLongOathTitle;

  /// No description provided for @progSideFrostboundLongOathDesc.
  ///
  /// In en, this message translates to:
  /// **'Frost tests the whole body — finish today\'s steps, sleep, protein and calories.'**
  String get progSideFrostboundLongOathDesc;

  /// No description provided for @progSideIcewalkerDawnMarchTitle.
  ///
  /// In en, this message translates to:
  /// **'Dawn march'**
  String get progSideIcewalkerDawnMarchTitle;

  /// No description provided for @progSideIcewalkerDawnMarchDesc.
  ///
  /// In en, this message translates to:
  /// **'Ice is walked early — finish today\'s steps, activity and calories.'**
  String get progSideIcewalkerDawnMarchDesc;

  /// No description provided for @progSideIcewalkerProvisionerTitle.
  ///
  /// In en, this message translates to:
  /// **'Provisioner'**
  String get progSideIcewalkerProvisionerTitle;

  /// No description provided for @progSideIcewalkerProvisionerDesc.
  ///
  /// In en, this message translates to:
  /// **'The caravan eats complete — meet all five of today\'s nutrition goals.'**
  String get progSideIcewalkerProvisionerDesc;

  /// No description provided for @progSideMountainSteepMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Steep morning'**
  String get progSideMountainSteepMorningTitle;

  /// No description provided for @progSideMountainSteepMorningDesc.
  ///
  /// In en, this message translates to:
  /// **'The ridge isn\'t climbed at noon — finish today\'s steps, activity and sleep.'**
  String get progSideMountainSteepMorningDesc;

  /// No description provided for @progSideMountainFullRidgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Full ridge'**
  String get progSideMountainFullRidgeTitle;

  /// No description provided for @progSideMountainFullRidgeDesc.
  ///
  /// In en, this message translates to:
  /// **'The summit demands the whole of you — finish today\'s steps, activity, sleep, protein and calories.'**
  String get progSideMountainFullRidgeDesc;

  /// No description provided for @progSideDragonroadWardenDawnTitle.
  ///
  /// In en, this message translates to:
  /// **'Warden\'s dawn'**
  String get progSideDragonroadWardenDawnTitle;

  /// No description provided for @progSideDragonroadWardenDawnDesc.
  ///
  /// In en, this message translates to:
  /// **'The dragon road tests discipline — meet four basics today (steps, activity, calories, protein).'**
  String get progSideDragonroadWardenDawnDesc;

  /// No description provided for @progSideDragonroadIronAppetiteTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragon\'s appetite'**
  String get progSideDragonroadIronAppetiteTitle;

  /// No description provided for @progSideDragonroadIronAppetiteDesc.
  ///
  /// In en, this message translates to:
  /// **'The dragon eats five courses — meet all five nutrition goals today.'**
  String get progSideDragonroadIronAppetiteDesc;

  /// No description provided for @progSideDragonrockSovereignDawnTitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereign\'s dawn'**
  String get progSideDragonrockSovereignDawnTitle;

  /// No description provided for @progSideDragonrockSovereignDawnDesc.
  ///
  /// In en, this message translates to:
  /// **'A sovereign never starves — finish today\'s steps and all four macro goals.'**
  String get progSideDragonrockSovereignDawnDesc;

  /// No description provided for @progSideDragonrockSovereignVigilTitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereign\'s vigil'**
  String get progSideDragonrockSovereignVigilTitle;

  /// No description provided for @progSideDragonrockSovereignVigilDesc.
  ///
  /// In en, this message translates to:
  /// **'Tend the whole kingdom of yourself — meet six of today\'s eight daily goals.'**
  String get progSideDragonrockSovereignVigilDesc;

  /// No description provided for @progSideIcewalkerFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Crew complete'**
  String get progSideIcewalkerFinaleTitle;

  /// No description provided for @progSideIcewalkerFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'The caravan stands tall no matter the cold — meet six different daily goals today.'**
  String get progSideIcewalkerFinaleDesc;

  /// No description provided for @progSideDragonroadFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragon\'s banquet'**
  String get progSideDragonroadFinaleTitle;

  /// No description provided for @progSideDragonroadFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'The dragon demands a full table — meet seven of today\'s eight daily goals.'**
  String get progSideDragonroadFinaleDesc;

  /// No description provided for @progSideDragonrockSovereignThroneTitle.
  ///
  /// In en, this message translates to:
  /// **'Throne of Dragonrock'**
  String get progSideDragonrockSovereignThroneTitle;

  /// No description provided for @progSideDragonrockSovereignThroneDesc.
  ///
  /// In en, this message translates to:
  /// **'Your throne does not yield — meet seven daily goals today, all four macros included.'**
  String get progSideDragonrockSovereignThroneDesc;

  /// No description provided for @progSideDragonrockSovereignCrownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unbroken crown'**
  String get progSideDragonrockSovereignCrownTitle;

  /// No description provided for @progSideDragonrockSovereignCrownDesc.
  ///
  /// In en, this message translates to:
  /// **'An almost-perfect day — meet seven of today\'s eight daily goals and hold the pace till evening.'**
  String get progSideDragonrockSovereignCrownDesc;

  /// No description provided for @progSideDragonrockSovereignFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereign\'s perfect day'**
  String get progSideDragonrockSovereignFinaleTitle;

  /// No description provided for @progSideDragonrockSovereignFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'The summit of the journey — meet all eight of today\'s daily goals. Bonus for 7+ h sleep and for finishing before 18:00.'**
  String get progSideDragonrockSovereignFinaleDesc;

  /// No description provided for @progDailyChallengeNutriTripleTitle.
  ///
  /// In en, this message translates to:
  /// **'Triple nutrition win'**
  String get progDailyChallengeNutriTripleTitle;

  /// No description provided for @progDailyChallengeNutriTripleDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s goal on 3 of 5 nutrition macros (calories, protein, carbs, fat, fiber).'**
  String get progDailyChallengeNutriTripleDesc;

  /// No description provided for @progDailyChallengeActiveDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Active day'**
  String get progDailyChallengeActiveDayTitle;

  /// No description provided for @progDailyChallengeActiveDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s steps and activity goals.'**
  String get progDailyChallengeActiveDayDesc;

  /// No description provided for @progDailyChallengeFullPlateTitle.
  ///
  /// In en, this message translates to:
  /// **'Full plate'**
  String get progDailyChallengeFullPlateTitle;

  /// No description provided for @progDailyChallengeFullPlateDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s goal on all 5 nutrition macros.'**
  String get progDailyChallengeFullPlateDesc;

  /// No description provided for @progDailyChallengeRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery day'**
  String get progDailyChallengeRecoveryTitle;

  /// No description provided for @progDailyChallengeRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s sleep and protein goals — give the body a break.'**
  String get progDailyChallengeRecoveryDesc;

  /// No description provided for @progDailyChallengeTripleComboTitle.
  ///
  /// In en, this message translates to:
  /// **'Triple combo'**
  String get progDailyChallengeTripleComboTitle;

  /// No description provided for @progDailyChallengeTripleComboDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s steps, sleep and protein goals.'**
  String get progDailyChallengeTripleComboDesc;

  /// No description provided for @progDailyChallengeBalancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced day'**
  String get progDailyChallengeBalancedTitle;

  /// No description provided for @progDailyChallengeBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet any 4 of today\'s 8 daily goals.'**
  String get progDailyChallengeBalancedDesc;

  /// No description provided for @progQuestsLongTermHeader.
  ///
  /// In en, this message translates to:
  /// **'LONG-TERM GOALS'**
  String get progQuestsLongTermHeader;

  /// No description provided for @progQuestsLongTermAlsoUnlocks.
  ///
  /// In en, this message translates to:
  /// **'Also unlocks'**
  String get progQuestsLongTermAlsoUnlocks;

  /// No description provided for @progQuestNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get progQuestNextStep;

  /// No description provided for @progQuestNextStepLocked.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous step to unlock the next one'**
  String get progQuestNextStepLocked;

  /// No description provided for @progQuestChainFinaleReward.
  ///
  /// In en, this message translates to:
  /// **'Chapter finale reward'**
  String get progQuestChainFinaleReward;

  /// No description provided for @cosmeticTypeFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get cosmeticTypeFrame;

  /// No description provided for @cosmeticTypeRelic.
  ///
  /// In en, this message translates to:
  /// **'Relic'**
  String get cosmeticTypeRelic;

  /// No description provided for @cosmeticTypeBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get cosmeticTypeBackground;

  /// No description provided for @cosmeticTypeEmblem.
  ///
  /// In en, this message translates to:
  /// **'Emblem'**
  String get cosmeticTypeEmblem;

  /// No description provided for @cosmeticTypeCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get cosmeticTypeCompanion;

  /// No description provided for @cosmeticTypeTitleFlair.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get cosmeticTypeTitleFlair;

  /// No description provided for @cosmeticTypeMapEffect.
  ///
  /// In en, this message translates to:
  /// **'Map effect'**
  String get cosmeticTypeMapEffect;

  /// No description provided for @progQuestsChapterWaitingHeader.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING CHAPTERS'**
  String get progQuestsChapterWaitingHeader;

  /// No description provided for @progQuestsChapterWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter unlocked'**
  String get progQuestsChapterWaitingTitle;

  /// No description provided for @progQuestsChapterWaitingCaption.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous chapter to begin.'**
  String get progQuestsChapterWaitingCaption;

  /// No description provided for @progQuestsLockedHeader.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get progQuestsLockedHeader;

  /// No description provided for @progQuestsCompletedHeader.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED QUESTS'**
  String get progQuestsCompletedHeader;

  /// No description provided for @progQuestsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String progQuestsCompletedCount(int count);

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

  /// Quest screen section header for the per-day backfill list (audit log + retroactive claim).
  ///
  /// In en, this message translates to:
  /// **'Reward history'**
  String get progBackfillSectionLabel;

  /// Empty state title when the player has no past days with logged activity.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get progBackfillEmptyTitle;

  /// Empty state caption for the backfill section.
  ///
  /// In en, this message translates to:
  /// **'Once you start logging steps, sleep or workouts, your daily rewards will show up here.'**
  String get progBackfillEmptyCaption;

  /// Count chip on a day card header signalling unclaimed rewards on that day.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} to claim} other{{count} to claim}}'**
  String progBackfillPendingChip(int count);

  /// Relative-date label for a backfill day card representing today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get progBackfillDayHeaderToday;

  /// Relative-date label for a backfill day card representing yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get progBackfillDayHeaderYesterday;

  /// Group header above day cards from the calendar week containing today.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get progBackfillGroupThisWeek;

  /// Group header above day cards from the calendar week before this one.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get progBackfillGroupLastWeek;

  /// Group header for older weeks (2-3 weeks ago).
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String progBackfillGroupWeeksAgo(int weeks);

  /// Group header for day cards roughly one month back.
  ///
  /// In en, this message translates to:
  /// **'A month ago'**
  String get progBackfillGroupMonthAgo;

  /// Group header for day cards multiple months back.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String progBackfillGroupMonthsAgo(int months);

  /// Bulk-claim button at the bottom of an expanded day card.
  ///
  /// In en, this message translates to:
  /// **'Claim all · +{xp} XP'**
  String progBackfillClaimAllDay(int xp);

  /// Snackbar shown after a successful bulk backfill claim.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Claimed {count} reward · +{xp} XP} other{Claimed {count} rewards · +{xp} XP}}'**
  String progBackfillClaimedToast(int count, int xp);

  /// Footer button that expands the backfill list to show older days.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more days'**
  String progBackfillShowMore(int count);

  /// Footer button that expands the backfill list all the way back to the player's join date.
  ///
  /// In en, this message translates to:
  /// **'Show all since {date}'**
  String progBackfillShowAllSinceJoin(String date);

  /// Trailing label on a daily-goal row when the target wasn't reached that day (no claim possible).
  ///
  /// In en, this message translates to:
  /// **'Not met'**
  String get progBackfillGoalUnmet;

  /// Trailing label on a daily-goal row when the underlying data source has no record for that day.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get progBackfillGoalNoData;

  /// Subtle caption shown under a daily-section quest card when the quest is completed today — telling the player the slot is locked until midnight rotation.
  ///
  /// In en, this message translates to:
  /// **'Done for today · returns tomorrow'**
  String get progDailyQuestCompletedTodayBadge;

  /// Mini section heading above the daily-goal rows inside an expanded backfill day card.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get progBackfillDayGoalsLabel;

  /// Mini section heading above the daily-quest rows inside an expanded backfill day card.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get progBackfillDayQuestsLabel;

  /// Mini section heading above the activity rows inside an expanded backfill day card.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get progBackfillDayActivitiesLabel;

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

  /// No description provided for @progQuestDetailRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get progQuestDetailRewards;

  /// No description provided for @progQuestDetailUnlocksNext.
  ///
  /// In en, this message translates to:
  /// **'Unlocks next'**
  String get progQuestDetailUnlocksNext;

  /// No description provided for @progQuestDetailLockedBecause.
  ///
  /// In en, this message translates to:
  /// **'Locked because'**
  String get progQuestDetailLockedBecause;

  /// No description provided for @progQuestDetailRequiresLevel.
  ///
  /// In en, this message translates to:
  /// **'Requires level {level}'**
  String progQuestDetailRequiresLevel(int level);

  /// No description provided for @progQuestDetailTrackDays.
  ///
  /// In en, this message translates to:
  /// **'Track {days} days'**
  String progQuestDetailTrackDays(int days);

  /// No description provided for @progQuestDetailCompleteQuest.
  ///
  /// In en, this message translates to:
  /// **'Complete {quest}'**
  String progQuestDetailCompleteQuest(String quest);

  /// No description provided for @progQuestDetailRelatedGoals.
  ///
  /// In en, this message translates to:
  /// **'Related goals'**
  String get progQuestDetailRelatedGoals;

  /// No description provided for @progQuestDetailTapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get progQuestDetailTapForDetails;

  /// No description provided for @progQuestDetailHiddenUntilUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Hidden until unlocked'**
  String get progQuestDetailHiddenUntilUnlocked;

  /// No description provided for @progQuestDetailHiddenReward.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get progQuestDetailHiddenReward;

  /// No description provided for @progQuestDetailNoFollowUp.
  ///
  /// In en, this message translates to:
  /// **'No follow-up quest yet'**
  String get progQuestDetailNoFollowUp;

  /// No description provided for @progQuestDetailGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get progQuestDetailGoal;

  /// No description provided for @progQuestDetailNextInChain.
  ///
  /// In en, this message translates to:
  /// **'Next in chain'**
  String get progQuestDetailNextInChain;

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

  /// No description provided for @progXpFlatDetail.
  ///
  /// In en, this message translates to:
  /// **'Reward: +{xp} XP'**
  String progXpFlatDetail(int xp);

  /// No description provided for @progXpScalingDetail.
  ///
  /// In en, this message translates to:
  /// **'Reward: +{baseXp} XP base · scaled to +{previewXp} XP at your level'**
  String progXpScalingDetail(int baseXp, int previewXp);

  /// No description provided for @progStreakBestDetail.
  ///
  /// In en, this message translates to:
  /// **'Best streak: {days} days'**
  String progStreakBestDetail(int days);

  /// No description provided for @progChapterLockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String progChapterLockedLabel(int level);

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

  /// No description provided for @progRuleDailyStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily steps target.'**
  String get progRuleDailyStepsDesc;

  /// No description provided for @progRuleDailyStepsHintedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily steps target.'**
  String get progRuleDailyStepsHintedDesc;

  /// No description provided for @progRuleDailyCaloriesHintedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily calories target.'**
  String get progRuleDailyCaloriesHintedDesc;

  /// No description provided for @progRuleDailyActivityHintedDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured weekly activity-minutes target.'**
  String get progRuleDailyActivityHintedDesc;

  /// No description provided for @progBonusXpBeforeHour.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP bonus if you claim before {hour}:00'**
  String progBonusXpBeforeHour(int xp, int hour);

  /// No description provided for @progBonusXpSleepAtLeast.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP bonus if you slept at least {minutes} min'**
  String progBonusXpSleepAtLeast(int xp, int minutes);

  /// No description provided for @progBonusXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus XP'**
  String get progBonusXpLabel;

  /// No description provided for @progRuleDailyCalories.
  ///
  /// In en, this message translates to:
  /// **'Calorie Target'**
  String get progRuleDailyCalories;

  /// No description provided for @progRuleDailyCaloriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay within the default 10% calorie target window.'**
  String get progRuleDailyCaloriesDesc;

  /// No description provided for @progRuleDailyProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein Target'**
  String get progRuleDailyProtein;

  /// No description provided for @progRuleDailyProteinDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily protein target.'**
  String get progRuleDailyProteinDesc;

  /// No description provided for @progRuleDailyCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carb Target'**
  String get progRuleDailyCarbs;

  /// No description provided for @progRuleDailyCarbsDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily carbohydrate target.'**
  String get progRuleDailyCarbsDesc;

  /// No description provided for @progRuleDailyFat.
  ///
  /// In en, this message translates to:
  /// **'Fat Target'**
  String get progRuleDailyFat;

  /// No description provided for @progRuleDailyFatDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily fat target.'**
  String get progRuleDailyFatDesc;

  /// No description provided for @progRuleDailyFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber Target'**
  String get progRuleDailyFiber;

  /// No description provided for @progRuleDailyFiberDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured daily fiber target.'**
  String get progRuleDailyFiberDesc;

  /// No description provided for @progRuleDailySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep Target'**
  String get progRuleDailySleep;

  /// No description provided for @progRuleDailySleepDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach the configured nightly sleep duration target.'**
  String get progRuleDailySleepDesc;

  /// No description provided for @progRuleWeeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get progRuleWeeklyActivity;

  /// No description provided for @progRuleWeeklyActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate the configured weekly activity minutes.'**
  String get progRuleWeeklyActivityDesc;

  /// No description provided for @progRuleDailyWeightLog.
  ///
  /// In en, this message translates to:
  /// **'Weight Log'**
  String get progRuleDailyWeightLog;

  /// No description provided for @progRuleDailyWeightLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Log your weight at least once today.'**
  String get progRuleDailyWeightLogDesc;

  /// No description provided for @progRuleDailyWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight Goal'**
  String get progRuleDailyWeightGoal;

  /// No description provided for @progRuleDailyWeightGoalDesc.
  ///
  /// In en, this message translates to:
  /// **'Log a weight within 3% of your target weight.'**
  String get progRuleDailyWeightGoalDesc;

  /// No description provided for @progRewardDetailWeightLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged: {actual} kg'**
  String progRewardDetailWeightLogged(String actual);

  /// No description provided for @progQuestFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Quest'**
  String get progQuestFallbackTitle;

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

  /// No description provided for @progQuestComboInitiate10Title.
  ///
  /// In en, this message translates to:
  /// **'Combo Initiate'**
  String get progQuestComboInitiate10Title;

  /// No description provided for @progQuestComboInitiate10Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 combo quests of any kind.'**
  String get progQuestComboInitiate10Desc;

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

  /// No description provided for @progQuestDailyNutritionCarbsComboTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro Trio'**
  String get progQuestDailyNutritionCarbsComboTodayTitle;

  /// No description provided for @progQuestDailyNutritionCarbsComboTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete calorie, protein, and carb goals in the current day.'**
  String get progQuestDailyNutritionCarbsComboTodayDesc;

  /// No description provided for @progQuestDailyNutritionFatComboTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Macro Quartet'**
  String get progQuestDailyNutritionFatComboTodayTitle;

  /// No description provided for @progQuestDailyNutritionFatComboTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete calorie, protein, carb, and fat goals in the current day.'**
  String get progQuestDailyNutritionFatComboTodayDesc;

  /// No description provided for @progQuestDailyNutritionFiberComboTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Plate Combo'**
  String get progQuestDailyNutritionFiberComboTodayTitle;

  /// No description provided for @progQuestDailyNutritionFiberComboTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete calorie, protein, carb, fat, and fiber goals in the current day.'**
  String get progQuestDailyNutritionFiberComboTodayDesc;

  /// No description provided for @progQuestNutritionRhythm3Title.
  ///
  /// In en, this message translates to:
  /// **'Balanced Rhythm'**
  String get progQuestNutritionRhythm3Title;

  /// No description provided for @progQuestNutritionRhythm3Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn at least one nutrition reward for 3 periods in a row.'**
  String get progQuestNutritionRhythm3Desc;

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

  /// No description provided for @progComboBalancedStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Balanced day · 1 goal'**
  String get progComboBalancedStep1Title;

  /// No description provided for @progComboBalancedStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete any 1 daily goal today.'**
  String get progComboBalancedStep1Desc;

  /// No description provided for @progComboBalancedStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Balanced day · 2 goals'**
  String get progComboBalancedStep2Title;

  /// No description provided for @progComboBalancedStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete any 2 daily goals today.'**
  String get progComboBalancedStep2Desc;

  /// No description provided for @progComboBalancedStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Balanced day · 3 goals'**
  String get progComboBalancedStep3Title;

  /// No description provided for @progComboBalancedStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete any 3 daily goals today.'**
  String get progComboBalancedStep3Desc;

  /// No description provided for @progComboBalancedFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Balanced day · finale'**
  String get progComboBalancedFinaleTitle;

  /// No description provided for @progComboBalancedFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete any 4 daily goals today.'**
  String get progComboBalancedFinaleDesc;

  /// No description provided for @progComboRecoveryStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Recovery · sleep'**
  String get progComboRecoveryStep1Title;

  /// No description provided for @progComboRecoveryStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s sleep goal.'**
  String get progComboRecoveryStep1Desc;

  /// No description provided for @progComboRecoveryStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Recovery · sleep + steps'**
  String get progComboRecoveryStep2Title;

  /// No description provided for @progComboRecoveryStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s sleep and steps goals.'**
  String get progComboRecoveryStep2Desc;

  /// No description provided for @progComboRecoveryStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Recovery · sleep + steps + protein'**
  String get progComboRecoveryStep3Title;

  /// No description provided for @progComboRecoveryStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s sleep, steps and protein goals.'**
  String get progComboRecoveryStep3Desc;

  /// No description provided for @progComboRecoveryFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery · finale'**
  String get progComboRecoveryFinaleTitle;

  /// No description provided for @progComboRecoveryFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s sleep, steps, protein and calories goals.'**
  String get progComboRecoveryFinaleDesc;

  /// No description provided for @progComboNutritionStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition master · calories'**
  String get progComboNutritionStep1Title;

  /// No description provided for @progComboNutritionStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s calorie goal.'**
  String get progComboNutritionStep1Desc;

  /// No description provided for @progComboNutritionStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition master · + protein'**
  String get progComboNutritionStep2Title;

  /// No description provided for @progComboNutritionStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s calorie and protein goals.'**
  String get progComboNutritionStep2Desc;

  /// No description provided for @progComboNutritionStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition master · + carbs'**
  String get progComboNutritionStep3Title;

  /// No description provided for @progComboNutritionStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s calorie, protein and carb goals.'**
  String get progComboNutritionStep3Desc;

  /// No description provided for @progComboNutritionStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition master · + fat'**
  String get progComboNutritionStep4Title;

  /// No description provided for @progComboNutritionStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Meet today\'s calorie, protein, carb and fat goals.'**
  String get progComboNutritionStep4Desc;

  /// No description provided for @progComboNutritionFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition master · finale'**
  String get progComboNutritionFinaleTitle;

  /// No description provided for @progComboNutritionFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Meet all macro goals today: calories, protein, carbs, fat and fiber.'**
  String get progComboNutritionFinaleDesc;

  /// No description provided for @progQuestSleepTotal250hTitle.
  ///
  /// In en, this message translates to:
  /// **'Rested Soul'**
  String get progQuestSleepTotal250hTitle;

  /// No description provided for @progQuestSleepTotal250hDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 250 hours of tracked sleep.'**
  String get progQuestSleepTotal250hDesc;

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

  /// No description provided for @progQuestDailyCarbsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Carb Goal'**
  String get progQuestDailyCarbsTodayTitle;

  /// No description provided for @progQuestDailyCarbsTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily carb rule in the current day.'**
  String get progQuestDailyCarbsTodayDesc;

  /// No description provided for @progQuestDailyFatTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Fat Goal'**
  String get progQuestDailyFatTodayTitle;

  /// No description provided for @progQuestDailyFatTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily fat rule in the current day.'**
  String get progQuestDailyFatTodayDesc;

  /// No description provided for @progQuestDailyFiberTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Fiber Goal'**
  String get progQuestDailyFiberTodayTitle;

  /// No description provided for @progQuestDailyFiberTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily fiber rule in the current day.'**
  String get progQuestDailyFiberTodayDesc;

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

  /// No description provided for @progQuestReach25000XpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 25,000 XP'**
  String get progQuestReach25000XpTitle;

  /// No description provided for @progQuestReach25000XpDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate at least 25,000 XP.'**
  String get progQuestReach25000XpDesc;

  /// No description provided for @progQuestReach100000XpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 100,000 XP'**
  String get progQuestReach100000XpTitle;

  /// No description provided for @progQuestReach100000XpDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate at least 100,000 XP.'**
  String get progQuestReach100000XpDesc;

  /// No description provided for @progQuestReach1000000XpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach 1,000,000 XP'**
  String get progQuestReach1000000XpTitle;

  /// No description provided for @progQuestReach1000000XpDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate at least 1,000,000 XP.'**
  String get progQuestReach1000000XpDesc;

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

  /// No description provided for @progQuestEarn250RewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn 250 Rewards'**
  String get progQuestEarn250RewardsTitle;

  /// No description provided for @progQuestEarn250RewardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect 250 progression rewards in total.'**
  String get progQuestEarn250RewardsDesc;

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

  /// No description provided for @progQuestNutritionRewards100Title.
  ///
  /// In en, this message translates to:
  /// **'Macro Legend'**
  String get progQuestNutritionRewards100Title;

  /// No description provided for @progQuestNutritionRewards100Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 100 nutrition rewards.'**
  String get progQuestNutritionRewards100Desc;

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

  /// No description provided for @progQuestTotalSteps1mTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk 1M Steps'**
  String get progQuestTotalSteps1mTitle;

  /// No description provided for @progQuestTotalSteps1mDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 1,000,000 total steps.'**
  String get progQuestTotalSteps1mDesc;

  /// No description provided for @progQuestTotalSteps5mTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk 5M Steps'**
  String get progQuestTotalSteps5mTitle;

  /// No description provided for @progQuestTotalSteps5mDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 5,000,000 total steps.'**
  String get progQuestTotalSteps5mDesc;

  /// No description provided for @progQuestTotalSteps10mTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk 10M Steps'**
  String get progQuestTotalSteps10mTitle;

  /// No description provided for @progQuestTotalSteps10mDesc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 10,000,000 total steps.'**
  String get progQuestTotalSteps10mDesc;

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

  /// No description provided for @progQuestWeeklyActivity24Title.
  ///
  /// In en, this message translates to:
  /// **'Unbroken Momentum'**
  String get progQuestWeeklyActivity24Title;

  /// No description provided for @progQuestWeeklyActivity24Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 24 times.'**
  String get progQuestWeeklyActivity24Desc;

  /// No description provided for @progQuestWeeklyActivity52Title.
  ///
  /// In en, this message translates to:
  /// **'Yearlong Engine'**
  String get progQuestWeeklyActivity52Title;

  /// No description provided for @progQuestWeeklyActivity52Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 52 times.'**
  String get progQuestWeeklyActivity52Desc;

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

  /// No description provided for @progQuestStepsStreak30Title.
  ///
  /// In en, this message translates to:
  /// **'Step Sovereign'**
  String get progQuestStepsStreak30Title;

  /// No description provided for @progQuestStepsStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule 30 periods in a row.'**
  String get progQuestStepsStreak30Desc;

  /// No description provided for @progQuestStepsStreak50Title.
  ///
  /// In en, this message translates to:
  /// **'Iron Resolve'**
  String get progQuestStepsStreak50Title;

  /// No description provided for @progQuestStepsStreak50Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule 50 periods in a row.'**
  String get progQuestStepsStreak50Desc;

  /// No description provided for @progQuestStepsStreak100Title.
  ///
  /// In en, this message translates to:
  /// **'Iron Chain'**
  String get progQuestStepsStreak100Title;

  /// No description provided for @progQuestStepsStreak100Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps rule 100 periods in a row.'**
  String get progQuestStepsStreak100Desc;

  /// No description provided for @progQuestSourceJourney.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get progQuestSourceJourney;

  /// No description provided for @progQuestSourceDailyCombo.
  ///
  /// In en, this message translates to:
  /// **'Daily Combo'**
  String get progQuestSourceDailyCombo;

  /// No description provided for @progQuestSourceNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get progQuestSourceNutrition;

  /// No description provided for @progQuestSourceRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get progQuestSourceRecovery;

  /// No description provided for @progQuestSourceDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get progQuestSourceDailyGoal;

  /// No description provided for @progQuestSourceSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get progQuestSourceSteps;

  /// No description provided for @progQuestSourceStepChain.
  ///
  /// In en, this message translates to:
  /// **'Step Chain'**
  String get progQuestSourceStepChain;

  /// No description provided for @progQuestSourceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get progQuestSourceWeekly;

  /// No description provided for @progQuestChainStepSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get progQuestChainStepSteps;

  /// No description provided for @progQuestChainStepKcal.
  ///
  /// In en, this message translates to:
  /// **'Kcal'**
  String get progQuestChainStepKcal;

  /// No description provided for @progQuestChainStepProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get progQuestChainStepProtein;

  /// No description provided for @progQuestChainStepCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get progQuestChainStepCarbs;

  /// No description provided for @progQuestChainStepFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get progQuestChainStepFat;

  /// No description provided for @progQuestChainStepFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get progQuestChainStepFiber;

  /// No description provided for @progQuestChainStepSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get progQuestChainStepSleep;

  /// No description provided for @progQuestChainStepBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get progQuestChainStepBadge;

  /// No description provided for @progQuestChainStepStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get progQuestChainStepStart;

  /// No description provided for @progQuestChainStepEmblem.
  ///
  /// In en, this message translates to:
  /// **'Emblem'**
  String get progQuestChainStepEmblem;

  /// No description provided for @progQuestSourceForestTrial.
  ///
  /// In en, this message translates to:
  /// **'Forest Trial'**
  String get progQuestSourceForestTrial;

  /// No description provided for @progQuestSourceRuinsDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Ruins of Discipline'**
  String get progQuestSourceRuinsDiscipline;

  /// No description provided for @progQuestSourceMineDescent.
  ///
  /// In en, this message translates to:
  /// **'Mine Descent'**
  String get progQuestSourceMineDescent;

  /// No description provided for @progQuestSourceForgeMomentum.
  ///
  /// In en, this message translates to:
  /// **'Forge of Momentum'**
  String get progQuestSourceForgeMomentum;

  /// No description provided for @progQuestSourceUnderwayPact.
  ///
  /// In en, this message translates to:
  /// **'Underway Pact'**
  String get progQuestSourceUnderwayPact;

  /// No description provided for @progQuestSourceFrostboundOath.
  ///
  /// In en, this message translates to:
  /// **'Frostbound Oath'**
  String get progQuestSourceFrostboundOath;

  /// No description provided for @progQuestSourceIcewalkerRoute.
  ///
  /// In en, this message translates to:
  /// **'Icewalker’s Route'**
  String get progQuestSourceIcewalkerRoute;

  /// No description provided for @progQuestSourceMountainAscent.
  ///
  /// In en, this message translates to:
  /// **'Mountain Ascent'**
  String get progQuestSourceMountainAscent;

  /// No description provided for @progQuestSourceDragonroad.
  ///
  /// In en, this message translates to:
  /// **'Dragonroad'**
  String get progQuestSourceDragonroad;

  /// No description provided for @progQuestSourceDragonrockSovereign.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Sovereign'**
  String get progQuestSourceDragonrockSovereign;

  /// No description provided for @progQuestPilgrimPathOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim\'s Path'**
  String get progQuestPilgrimPathOpenTitle;

  /// No description provided for @progQuestPilgrimPathOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Set out on your journey — your first chapter begins here.'**
  String get progQuestPilgrimPathOpenDesc;

  /// No description provided for @progQuestPilgrimPathFirstStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'First steps'**
  String get progQuestPilgrimPathFirstStepsTitle;

  /// No description provided for @progQuestPilgrimPathFirstStepsDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily steps goal and start walking the path.'**
  String get progQuestPilgrimPathFirstStepsDesc;

  /// No description provided for @progQuestPilgrimPathFirstSleepTitle.
  ///
  /// In en, this message translates to:
  /// **'First rest'**
  String get progQuestPilgrimPathFirstSleepTitle;

  /// No description provided for @progQuestPilgrimPathFirstSleepDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the daily sleep goal and recover for the road ahead.'**
  String get progQuestPilgrimPathFirstSleepDesc;

  /// No description provided for @progQuestPilgrimPathFirstRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Provisions for the road'**
  String get progQuestPilgrimPathFirstRewardTitle;

  /// No description provided for @progQuestPilgrimPathFirstRewardDesc.
  ///
  /// In en, this message translates to:
  /// **'Strength fuels the path into the deep forest — hit today\'s protein goal.'**
  String get progQuestPilgrimPathFirstRewardDesc;

  /// No description provided for @progQuestPilgrimPathFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim\'s Mark'**
  String get progQuestPilgrimPathFinaleTitle;

  /// No description provided for @progQuestPilgrimPathFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Walk, rest, gather provisions — then claim the Pilgrim\'s Mark.'**
  String get progQuestPilgrimPathFinaleDesc;

  /// No description provided for @progQuestForestTrialOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Forest Trial'**
  String get progQuestForestTrialOpenTitle;

  /// No description provided for @progQuestForestTrialOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Forest Trial after reaching level 10.'**
  String get progQuestForestTrialOpenDesc;

  /// No description provided for @progQuestForestTrialDailyWins5Title.
  ///
  /// In en, this message translates to:
  /// **'Trail Rhythm'**
  String get progQuestForestTrialDailyWins5Title;

  /// No description provided for @progQuestForestTrialDailyWins5Desc.
  ///
  /// In en, this message translates to:
  /// **'On the Forest Trail, complete at least 2 daily goals on 5 different days.'**
  String get progQuestForestTrialDailyWins5Desc;

  /// No description provided for @progQuestForestTrialSteps5Title.
  ///
  /// In en, this message translates to:
  /// **'Five Days on the Path'**
  String get progQuestForestTrialSteps5Title;

  /// No description provided for @progQuestForestTrialSteps5Desc.
  ///
  /// In en, this message translates to:
  /// **'On the Forest Trail, complete your step goal 5 times.'**
  String get progQuestForestTrialSteps5Desc;

  /// No description provided for @progQuestForestTrialRecovery3Title.
  ///
  /// In en, this message translates to:
  /// **'Rest Beneath the Trees'**
  String get progQuestForestTrialRecovery3Title;

  /// No description provided for @progQuestForestTrialRecovery3Desc.
  ///
  /// In en, this message translates to:
  /// **'On the Forest Trail, complete your step and sleep goals on the same day 3 times.'**
  String get progQuestForestTrialRecovery3Desc;

  /// No description provided for @progQuestForestTrialFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Forest Trial Complete'**
  String get progQuestForestTrialFinaleTitle;

  /// No description provided for @progQuestForestTrialFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Forest Trial quests.'**
  String get progQuestForestTrialFinaleDesc;

  /// No description provided for @progQuestRuinsDisciplineOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Ruins of Discipline'**
  String get progQuestRuinsDisciplineOpenTitle;

  /// No description provided for @progQuestRuinsDisciplineOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Ruins of Discipline after reaching level 20.'**
  String get progQuestRuinsDisciplineOpenDesc;

  /// No description provided for @progQuestRuinsDisciplineNutrition7Title.
  ///
  /// In en, this message translates to:
  /// **'Ancient Ration'**
  String get progQuestRuinsDisciplineNutrition7Title;

  /// No description provided for @progQuestRuinsDisciplineNutrition7Desc.
  ///
  /// In en, this message translates to:
  /// **'In the Ruins of Discipline, complete your calorie and protein goals together 7 times.'**
  String get progQuestRuinsDisciplineNutrition7Desc;

  /// No description provided for @progQuestRuinsDisciplineWeekly2Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Offering'**
  String get progQuestRuinsDisciplineWeekly2Title;

  /// No description provided for @progQuestRuinsDisciplineWeekly2Desc.
  ///
  /// In en, this message translates to:
  /// **'In the Ruins of Discipline, complete the weekly activity goal 2 times.'**
  String get progQuestRuinsDisciplineWeekly2Desc;

  /// No description provided for @progQuestRuinsDisciplineSteps10Title.
  ///
  /// In en, this message translates to:
  /// **'Ten-Day Resolve'**
  String get progQuestRuinsDisciplineSteps10Title;

  /// No description provided for @progQuestRuinsDisciplineSteps10Desc.
  ///
  /// In en, this message translates to:
  /// **'In the Ruins of Discipline, complete your step goal 10 times.'**
  String get progQuestRuinsDisciplineSteps10Desc;

  /// No description provided for @progQuestRuinsDisciplineFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Ruins Trial Complete'**
  String get progQuestRuinsDisciplineFinaleTitle;

  /// No description provided for @progQuestRuinsDisciplineFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Ruins of Discipline quests.'**
  String get progQuestRuinsDisciplineFinaleDesc;

  /// No description provided for @progQuestMineDescentOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Mine Descent'**
  String get progQuestMineDescentOpenTitle;

  /// No description provided for @progQuestMineDescentOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Mine Descent after reaching level 30.'**
  String get progQuestMineDescentOpenDesc;

  /// No description provided for @progQuestMineDescentSteps250kTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep Roads'**
  String get progQuestMineDescentSteps250kTitle;

  /// No description provided for @progQuestMineDescentSteps250kDesc.
  ///
  /// In en, this message translates to:
  /// **'During the Mine Descent, walk 250,000 steps.'**
  String get progQuestMineDescentSteps250kDesc;

  /// No description provided for @progQuestMineDescentActivityRewards12Title.
  ///
  /// In en, this message translates to:
  /// **'Work Orders'**
  String get progQuestMineDescentActivityRewards12Title;

  /// No description provided for @progQuestMineDescentActivityRewards12Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Mine Descent, claim 12 activity-related rewards.'**
  String get progQuestMineDescentActivityRewards12Desc;

  /// No description provided for @progQuestMineDescentProtein10Title.
  ///
  /// In en, this message translates to:
  /// **'Iron Rations'**
  String get progQuestMineDescentProtein10Title;

  /// No description provided for @progQuestMineDescentProtein10Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Mine Descent, complete your protein goal 10 times.'**
  String get progQuestMineDescentProtein10Desc;

  /// No description provided for @progQuestMineDescentFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Mine Trial Complete'**
  String get progQuestMineDescentFinaleTitle;

  /// No description provided for @progQuestMineDescentFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Mine Descent quests.'**
  String get progQuestMineDescentFinaleDesc;

  /// No description provided for @progQuestForgeMomentumOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Forge of Momentum'**
  String get progQuestForgeMomentumOpenTitle;

  /// No description provided for @progQuestForgeMomentumOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Forge of Momentum after reaching level 40.'**
  String get progQuestForgeMomentumOpenDesc;

  /// No description provided for @progQuestForgeMomentumWeekly4Title.
  ///
  /// In en, this message translates to:
  /// **'Heat the Forge'**
  String get progQuestForgeMomentumWeekly4Title;

  /// No description provided for @progQuestForgeMomentumWeekly4Desc.
  ///
  /// In en, this message translates to:
  /// **'At the Forge of Momentum, complete the weekly activity goal 4 times.'**
  String get progQuestForgeMomentumWeekly4Desc;

  /// No description provided for @progQuestForgeMomentumSteps20Title.
  ///
  /// In en, this message translates to:
  /// **'Hammer Steps'**
  String get progQuestForgeMomentumSteps20Title;

  /// No description provided for @progQuestForgeMomentumSteps20Desc.
  ///
  /// In en, this message translates to:
  /// **'At the Forge of Momentum, complete the step goal 20 times.'**
  String get progQuestForgeMomentumSteps20Desc;

  /// No description provided for @progQuestForgeMomentumNutrition15Title.
  ///
  /// In en, this message translates to:
  /// **'Fuel the Flame'**
  String get progQuestForgeMomentumNutrition15Title;

  /// No description provided for @progQuestForgeMomentumNutrition15Desc.
  ///
  /// In en, this message translates to:
  /// **'At the Forge of Momentum, complete your calorie and protein goals together 15 times.'**
  String get progQuestForgeMomentumNutrition15Desc;

  /// No description provided for @progQuestForgeMomentumFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Forge Trial Complete'**
  String get progQuestForgeMomentumFinaleTitle;

  /// No description provided for @progQuestForgeMomentumFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Forge of Momentum quests.'**
  String get progQuestForgeMomentumFinaleDesc;

  /// No description provided for @progQuestUnderwayPactOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Underway Pact'**
  String get progQuestUnderwayPactOpenTitle;

  /// No description provided for @progQuestUnderwayPactOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Underway Pact after reaching level 50.'**
  String get progQuestUnderwayPactOpenDesc;

  /// No description provided for @progQuestUnderwayPactFourPillars5Title.
  ///
  /// In en, this message translates to:
  /// **'Four Pillars Below'**
  String get progQuestUnderwayPactFourPillars5Title;

  /// No description provided for @progQuestUnderwayPactFourPillars5Desc.
  ///
  /// In en, this message translates to:
  /// **'In the Underway Pact, complete all 4 daily goals 5 times.'**
  String get progQuestUnderwayPactFourPillars5Desc;

  /// No description provided for @progQuestUnderwayPactSleep14Title.
  ///
  /// In en, this message translates to:
  /// **'Deep Rest'**
  String get progQuestUnderwayPactSleep14Title;

  /// No description provided for @progQuestUnderwayPactSleep14Desc.
  ///
  /// In en, this message translates to:
  /// **'In the Underway Pact, complete your sleep goal 14 times.'**
  String get progQuestUnderwayPactSleep14Desc;

  /// No description provided for @progQuestUnderwayPactRecovery10Title.
  ///
  /// In en, this message translates to:
  /// **'Stonebound Recovery'**
  String get progQuestUnderwayPactRecovery10Title;

  /// No description provided for @progQuestUnderwayPactRecovery10Desc.
  ///
  /// In en, this message translates to:
  /// **'In the Underway Pact, complete your step and sleep goals on the same day 10 times.'**
  String get progQuestUnderwayPactRecovery10Desc;

  /// No description provided for @progQuestUnderwayPactFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Underway Trial Complete'**
  String get progQuestUnderwayPactFinaleTitle;

  /// No description provided for @progQuestUnderwayPactFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Underway Pact quests.'**
  String get progQuestUnderwayPactFinaleDesc;

  /// No description provided for @progQuestFrostboundOathOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Frostbound Oath'**
  String get progQuestFrostboundOathOpenTitle;

  /// No description provided for @progQuestFrostboundOathOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Frostbound Oath after reaching level 60.'**
  String get progQuestFrostboundOathOpenDesc;

  /// No description provided for @progQuestFrostboundOathSteps21Title.
  ///
  /// In en, this message translates to:
  /// **'Frozen Resolve'**
  String get progQuestFrostboundOathSteps21Title;

  /// No description provided for @progQuestFrostboundOathSteps21Desc.
  ///
  /// In en, this message translates to:
  /// **'Under the Frostbound Oath, complete your step goal 21 times.'**
  String get progQuestFrostboundOathSteps21Desc;

  /// No description provided for @progQuestFrostboundOathSleep21Title.
  ///
  /// In en, this message translates to:
  /// **'Shelter in the Snow'**
  String get progQuestFrostboundOathSleep21Title;

  /// No description provided for @progQuestFrostboundOathSleep21Desc.
  ///
  /// In en, this message translates to:
  /// **'Under the Frostbound Oath, complete your sleep goal 21 times.'**
  String get progQuestFrostboundOathSleep21Desc;

  /// No description provided for @progQuestFrostboundOathWeekly6Title.
  ///
  /// In en, this message translates to:
  /// **'Cold March'**
  String get progQuestFrostboundOathWeekly6Title;

  /// No description provided for @progQuestFrostboundOathWeekly6Desc.
  ///
  /// In en, this message translates to:
  /// **'Under the Frostbound Oath, complete the weekly activity goal 6 times.'**
  String get progQuestFrostboundOathWeekly6Desc;

  /// No description provided for @progQuestFrostboundOathFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Frost Trial Complete'**
  String get progQuestFrostboundOathFinaleTitle;

  /// No description provided for @progQuestFrostboundOathFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Frostbound Oath quests.'**
  String get progQuestFrostboundOathFinaleDesc;

  /// No description provided for @progQuestIcewalkerRouteOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Icewalker’s Route'**
  String get progQuestIcewalkerRouteOpenTitle;

  /// No description provided for @progQuestIcewalkerRouteOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start Icewalker’s Route after reaching level 70.'**
  String get progQuestIcewalkerRouteOpenDesc;

  /// No description provided for @progQuestIcewalkerRouteSteps500kTitle.
  ///
  /// In en, this message translates to:
  /// **'Across White Plains'**
  String get progQuestIcewalkerRouteSteps500kTitle;

  /// No description provided for @progQuestIcewalkerRouteSteps500kDesc.
  ///
  /// In en, this message translates to:
  /// **'On Icewalker’s Route, walk 500,000 steps.'**
  String get progQuestIcewalkerRouteSteps500kDesc;

  /// No description provided for @progQuestIcewalkerRouteRewards150Title.
  ///
  /// In en, this message translates to:
  /// **'Traces in Ice'**
  String get progQuestIcewalkerRouteRewards150Title;

  /// No description provided for @progQuestIcewalkerRouteRewards150Desc.
  ///
  /// In en, this message translates to:
  /// **'On Icewalker’s Route, claim 150 rewards.'**
  String get progQuestIcewalkerRouteRewards150Desc;

  /// No description provided for @progQuestIcewalkerRouteProtein30Title.
  ///
  /// In en, this message translates to:
  /// **'Winter Rations'**
  String get progQuestIcewalkerRouteProtein30Title;

  /// No description provided for @progQuestIcewalkerRouteProtein30Desc.
  ///
  /// In en, this message translates to:
  /// **'On Icewalker’s Route, complete your protein goal 30 times.'**
  String get progQuestIcewalkerRouteProtein30Desc;

  /// No description provided for @progQuestIcewalkerRouteFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Ice Seal'**
  String get progQuestIcewalkerRouteFinaleTitle;

  /// No description provided for @progQuestIcewalkerRouteFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Icewalker’s Route quests.'**
  String get progQuestIcewalkerRouteFinaleDesc;

  /// No description provided for @progQuestMountainAscentOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Mountain Ascent'**
  String get progQuestMountainAscentOpenTitle;

  /// No description provided for @progQuestMountainAscentOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Start the Mountain Ascent after reaching level 80.'**
  String get progQuestMountainAscentOpenDesc;

  /// No description provided for @progQuestMountainAscentFourPillars15Title.
  ///
  /// In en, this message translates to:
  /// **'Camp Above the Clouds'**
  String get progQuestMountainAscentFourPillars15Title;

  /// No description provided for @progQuestMountainAscentFourPillars15Desc.
  ///
  /// In en, this message translates to:
  /// **'Above the clouds, complete all 4 daily goals 15 times.'**
  String get progQuestMountainAscentFourPillars15Desc;

  /// No description provided for @progQuestMountainAscentSteps30Title.
  ///
  /// In en, this message translates to:
  /// **'Unbroken Ascent'**
  String get progQuestMountainAscentSteps30Title;

  /// No description provided for @progQuestMountainAscentSteps30Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Mountain Ascent, complete your step goal 30 times.'**
  String get progQuestMountainAscentSteps30Desc;

  /// No description provided for @progQuestMountainAscentWeekly10Title.
  ///
  /// In en, this message translates to:
  /// **'Summit Routine'**
  String get progQuestMountainAscentWeekly10Title;

  /// No description provided for @progQuestMountainAscentWeekly10Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Mountain Ascent, complete the weekly activity goal 10 times.'**
  String get progQuestMountainAscentWeekly10Desc;

  /// No description provided for @progQuestMountainAscentFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Summit Seal'**
  String get progQuestMountainAscentFinaleTitle;

  /// No description provided for @progQuestMountainAscentFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Mountain Ascent quests.'**
  String get progQuestMountainAscentFinaleDesc;

  /// No description provided for @progQuestDragonroadOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragonroad'**
  String get progQuestDragonroadOpenTitle;

  /// No description provided for @progQuestDragonroadOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock the Dragonroad by reaching level 90.'**
  String get progQuestDragonroadOpenDesc;

  /// No description provided for @progQuestDragonroadRewards250Title.
  ///
  /// In en, this message translates to:
  /// **'Scales of Effort'**
  String get progQuestDragonroadRewards250Title;

  /// No description provided for @progQuestDragonroadRewards250Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Dragonroad, earn 250 rewards.'**
  String get progQuestDragonroadRewards250Desc;

  /// No description provided for @progQuestDragonroadFourPillars25Title.
  ///
  /// In en, this message translates to:
  /// **'Dragon Discipline'**
  String get progQuestDragonroadFourPillars25Title;

  /// No description provided for @progQuestDragonroadFourPillars25Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Dragonroad, complete all 4 daily goals 25 times.'**
  String get progQuestDragonroadFourPillars25Desc;

  /// No description provided for @progQuestDragonroadWeekly12Title.
  ///
  /// In en, this message translates to:
  /// **'Path to the Fortress'**
  String get progQuestDragonroadWeekly12Title;

  /// No description provided for @progQuestDragonroadWeekly12Desc.
  ///
  /// In en, this message translates to:
  /// **'During the Dragonroad, complete the weekly activity goal 12 times.'**
  String get progQuestDragonroadWeekly12Desc;

  /// No description provided for @progQuestDragonroadFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragon Seal'**
  String get progQuestDragonroadFinaleTitle;

  /// No description provided for @progQuestDragonroadFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Dragonroad quests.'**
  String get progQuestDragonroadFinaleDesc;

  /// No description provided for @progQuestDragonrockSovereignOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Sovereign'**
  String get progQuestDragonrockSovereignOpenTitle;

  /// No description provided for @progQuestDragonrockSovereignOpenDesc.
  ///
  /// In en, this message translates to:
  /// **'Claim Dragonrock sovereignty after reaching level 100.'**
  String get progQuestDragonrockSovereignOpenDesc;

  /// No description provided for @progQuestDragonrockSovereignFourPillars30Title.
  ///
  /// In en, this message translates to:
  /// **'Rule of Four'**
  String get progQuestDragonrockSovereignFourPillars30Title;

  /// No description provided for @progQuestDragonrockSovereignFourPillars30Desc.
  ///
  /// In en, this message translates to:
  /// **'Within Dragonrock Fortress, complete all 4 daily goals 30 times.'**
  String get progQuestDragonrockSovereignFourPillars30Desc;

  /// No description provided for @progQuestDragonrockSovereignWeekly16Title.
  ///
  /// In en, this message translates to:
  /// **'Fortress Routine'**
  String get progQuestDragonrockSovereignWeekly16Title;

  /// No description provided for @progQuestDragonrockSovereignWeekly16Desc.
  ///
  /// In en, this message translates to:
  /// **'Within Dragonrock Fortress, complete the weekly activity goal 16 times.'**
  String get progQuestDragonrockSovereignWeekly16Desc;

  /// No description provided for @progQuestDragonrockSovereignSteps50Title.
  ///
  /// In en, this message translates to:
  /// **'Royal March'**
  String get progQuestDragonrockSovereignSteps50Title;

  /// No description provided for @progQuestDragonrockSovereignSteps50Desc.
  ///
  /// In en, this message translates to:
  /// **'Within Dragonrock Fortress, complete your step goal 50 times.'**
  String get progQuestDragonrockSovereignSteps50Desc;

  /// No description provided for @progQuestDragonrockSovereignFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Seal'**
  String get progQuestDragonrockSovereignFinaleTitle;

  /// No description provided for @progQuestDragonrockSovereignFinaleDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the previous Dragonrock Sovereign quests.'**
  String get progQuestDragonrockSovereignFinaleDesc;

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

  /// No description provided for @progAchievementSteps2500000Title.
  ///
  /// In en, this message translates to:
  /// **'Highland Strider'**
  String get progAchievementSteps2500000Title;

  /// No description provided for @progAchievementSteps2500000Desc.
  ///
  /// In en, this message translates to:
  /// **'Accumulate 2,500,000 total steps.'**
  String get progAchievementSteps2500000Desc;

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

  /// No description provided for @progAchievementWeeklyActivity36Title.
  ///
  /// In en, this message translates to:
  /// **'Aurora Season'**
  String get progAchievementWeeklyActivity36Title;

  /// No description provided for @progAchievementWeeklyActivity36Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 36 times.'**
  String get progAchievementWeeklyActivity36Desc;

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

  /// No description provided for @progAchievementDailyQuest3Title.
  ///
  /// In en, this message translates to:
  /// **'First Steps'**
  String get progAchievementDailyQuest3Title;

  /// No description provided for @progAchievementDailyQuest3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 daily quests.'**
  String get progAchievementDailyQuest3Desc;

  /// No description provided for @progAchievementDailyQuest7Title.
  ///
  /// In en, this message translates to:
  /// **'Steady Hand'**
  String get progAchievementDailyQuest7Title;

  /// No description provided for @progAchievementDailyQuest7Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 7 daily quests.'**
  String get progAchievementDailyQuest7Desc;

  /// No description provided for @progAchievementQuestHunter250Title.
  ///
  /// In en, this message translates to:
  /// **'Quest Hunter'**
  String get progAchievementQuestHunter250Title;

  /// No description provided for @progAchievementQuestHunter250Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 250 quests in total.'**
  String get progAchievementQuestHunter250Desc;

  /// No description provided for @progAchievementActiveDays7Title.
  ///
  /// In en, this message translates to:
  /// **'A Week on the Road'**
  String get progAchievementActiveDays7Title;

  /// No description provided for @progAchievementActiveDays7Desc.
  ///
  /// In en, this message translates to:
  /// **'Be active for 7 days.'**
  String get progAchievementActiveDays7Desc;

  /// No description provided for @progAchievementActiveDays90Title.
  ///
  /// In en, this message translates to:
  /// **'A Season on the Road'**
  String get progAchievementActiveDays90Title;

  /// No description provided for @progAchievementActiveDays90Desc.
  ///
  /// In en, this message translates to:
  /// **'Be active for 90 days.'**
  String get progAchievementActiveDays90Desc;

  /// No description provided for @progAchievementPerfectDays7Title.
  ///
  /// In en, this message translates to:
  /// **'Balanced Week'**
  String get progAchievementPerfectDays7Title;

  /// No description provided for @progAchievementPerfectDays7Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete all daily goals on 7 different days.'**
  String get progAchievementPerfectDays7Desc;

  /// No description provided for @progAchievementPerfectWeeks12Title.
  ///
  /// In en, this message translates to:
  /// **'Master of Routine'**
  String get progAchievementPerfectWeeks12Title;

  /// No description provided for @progAchievementPerfectWeeks12Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete a perfect week 12 times.'**
  String get progAchievementPerfectWeeks12Desc;

  /// No description provided for @progAchievementComboVictory10Title.
  ///
  /// In en, this message translates to:
  /// **'Combo Initiate'**
  String get progAchievementComboVictory10Title;

  /// No description provided for @progAchievementComboVictory10Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 combo quests of any kind.'**
  String get progAchievementComboVictory10Desc;

  /// No description provided for @progAchievementComboTripleVictory25Title.
  ///
  /// In en, this message translates to:
  /// **'Triple Threat'**
  String get progAchievementComboTripleVictory25Title;

  /// No description provided for @progAchievementComboTripleVictory25Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 25 triple-or-better combo quests.'**
  String get progAchievementComboTripleVictory25Desc;

  /// No description provided for @progAchievementComboTripleVictory100Title.
  ///
  /// In en, this message translates to:
  /// **'Combo Sovereign'**
  String get progAchievementComboTripleVictory100Title;

  /// No description provided for @progAchievementComboTripleVictory100Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 triple-or-better combo quests.'**
  String get progAchievementComboTripleVictory100Desc;

  /// No description provided for @progAchievementDragonrockTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Trial'**
  String get progAchievementDragonrockTrialTitle;

  /// No description provided for @progAchievementDragonrockTrialDesc.
  ///
  /// In en, this message translates to:
  /// **'Reach level 100, complete 250 quests, and walk 10,000,000 steps.'**
  String get progAchievementDragonrockTrialDesc;

  /// No description provided for @progAchievementSummaryComposite.
  ///
  /// In en, this message translates to:
  /// **'all conditions'**
  String get progAchievementSummaryComposite;

  /// No description provided for @progAchievementSummaryDailyQuests.
  ///
  /// In en, this message translates to:
  /// **'daily quests'**
  String get progAchievementSummaryDailyQuests;

  /// No description provided for @progAchievementSummaryWeeklyQuests.
  ///
  /// In en, this message translates to:
  /// **'weekly quests'**
  String get progAchievementSummaryWeeklyQuests;

  /// No description provided for @progAchievementSummaryTotalQuests.
  ///
  /// In en, this message translates to:
  /// **'quests'**
  String get progAchievementSummaryTotalQuests;

  /// No description provided for @progAchievementSummaryActiveDays.
  ///
  /// In en, this message translates to:
  /// **'active days'**
  String get progAchievementSummaryActiveDays;

  /// No description provided for @progAchievementSummaryPerfectDays.
  ///
  /// In en, this message translates to:
  /// **'perfect days'**
  String get progAchievementSummaryPerfectDays;

  /// No description provided for @progAchievementSummaryPerfectWeeks.
  ///
  /// In en, this message translates to:
  /// **'perfect weeks'**
  String get progAchievementSummaryPerfectWeeks;

  /// No description provided for @progAchievementSummaryComboQuests.
  ///
  /// In en, this message translates to:
  /// **'combo quests'**
  String get progAchievementSummaryComboQuests;

  /// No description provided for @progAchievementSummaryTripleComboQuests.
  ///
  /// In en, this message translates to:
  /// **'triple combo quests'**
  String get progAchievementSummaryTripleComboQuests;

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

  /// No description provided for @progAchievementDifficultyMythic.
  ///
  /// In en, this message translates to:
  /// **'Impossible'**
  String get progAchievementDifficultyMythic;

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

  /// No description provided for @cosmeticFramePilgrimName.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim\'s Frame'**
  String get cosmeticFramePilgrimName;

  /// No description provided for @cosmeticFramePilgrimDesc.
  ///
  /// In en, this message translates to:
  /// **'A plain wooden frame for anyone who set out on the road.'**
  String get cosmeticFramePilgrimDesc;

  /// No description provided for @cosmeticFrameWildwoodName.
  ///
  /// In en, this message translates to:
  /// **'Wildwood Frame'**
  String get cosmeticFrameWildwoodName;

  /// No description provided for @cosmeticFrameWildwoodDesc.
  ///
  /// In en, this message translates to:
  /// **'Dark wood and subtle forest carvings for those who learned to read the paths of the wildwood.'**
  String get cosmeticFrameWildwoodDesc;

  /// No description provided for @cosmeticFrameRuinsName.
  ///
  /// In en, this message translates to:
  /// **'Ruins Frame'**
  String get cosmeticFrameRuinsName;

  /// No description provided for @cosmeticFrameRuinsDesc.
  ///
  /// In en, this message translates to:
  /// **'Cracked stonework and creeping moss recall the silent ruins on the edge of the pass.'**
  String get cosmeticFrameRuinsDesc;

  /// No description provided for @cosmeticFrameDwarvenName.
  ///
  /// In en, this message translates to:
  /// **'Old Gates Frame'**
  String get cosmeticFrameDwarvenName;

  /// No description provided for @cosmeticFrameDwarvenDesc.
  ///
  /// In en, this message translates to:
  /// **'Weathered stone and aged bronze from the pass where the trail gives way to ruins.'**
  String get cosmeticFrameDwarvenDesc;

  /// No description provided for @cosmeticFrameUnderwaysName.
  ///
  /// In en, this message translates to:
  /// **'Dwarven Frame'**
  String get cosmeticFrameUnderwaysName;

  /// No description provided for @cosmeticFrameUnderwaysDesc.
  ///
  /// In en, this message translates to:
  /// **'A sturdy frame of forged metal and mine stone, crafted in the depths of dwarven halls.'**
  String get cosmeticFrameUnderwaysDesc;

  /// No description provided for @cosmeticFrameFrostName.
  ///
  /// In en, this message translates to:
  /// **'Frost Frame'**
  String get cosmeticFrameFrostName;

  /// No description provided for @cosmeticFrameFrostDesc.
  ///
  /// In en, this message translates to:
  /// **'A cold silver frame with an icy sheen, born in the silence of the frozen lands.'**
  String get cosmeticFrameFrostDesc;

  /// No description provided for @cosmeticFrameMountainName.
  ///
  /// In en, this message translates to:
  /// **'Mountain Challenger\'s Frame'**
  String get cosmeticFrameMountainName;

  /// No description provided for @cosmeticFrameMountainDesc.
  ///
  /// In en, this message translates to:
  /// **'Dark mountain stone and blackened steel for those who climbed toward the fortress path.'**
  String get cosmeticFrameMountainDesc;

  /// No description provided for @cosmeticFrameDragonrockName.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Frame'**
  String get cosmeticFrameDragonrockName;

  /// No description provided for @cosmeticFrameDragonrockDesc.
  ///
  /// In en, this message translates to:
  /// **'A legendary frame of obsidian, dragonstone, and golden details, reserved for the lord of Dragonrock.'**
  String get cosmeticFrameDragonrockDesc;

  /// No description provided for @cosmeticFrameDeveloperTomName.
  ///
  /// In en, this message translates to:
  /// **'Developer Frame'**
  String get cosmeticFrameDeveloperTomName;

  /// No description provided for @cosmeticFrameDeveloperTomDesc.
  ///
  /// In en, this message translates to:
  /// **'Special frame unlocked through a Firebase entitlement.'**
  String get cosmeticFrameDeveloperTomDesc;

  /// No description provided for @cosmeticBackgroundDevAltarName.
  ///
  /// In en, this message translates to:
  /// **'Dev: Altar'**
  String get cosmeticBackgroundDevAltarName;

  /// No description provided for @cosmeticBackgroundDevCampName.
  ///
  /// In en, this message translates to:
  /// **'Dev: Camp'**
  String get cosmeticBackgroundDevCampName;

  /// No description provided for @cosmeticBackgroundDevHackerName.
  ///
  /// In en, this message translates to:
  /// **'Dev: Hacker'**
  String get cosmeticBackgroundDevHackerName;

  /// No description provided for @cosmeticBackgroundDevLordName.
  ///
  /// In en, this message translates to:
  /// **'Dev: Lord'**
  String get cosmeticBackgroundDevLordName;

  /// No description provided for @cosmeticBackgroundDevMinesName.
  ///
  /// In en, this message translates to:
  /// **'Dev: Mines'**
  String get cosmeticBackgroundDevMinesName;

  /// No description provided for @cosmeticBackgroundDevThroneName.
  ///
  /// In en, this message translates to:
  /// **'Dev: Throne'**
  String get cosmeticBackgroundDevThroneName;

  /// No description provided for @cosmeticBackgroundDevOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Developer-only background. Grant via DevTools.'**
  String get cosmeticBackgroundDevOnlyDesc;

  /// No description provided for @cosmeticCompanionDevOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Developer-only companion. Grant via DevTools.'**
  String get cosmeticCompanionDevOnlyDesc;

  /// No description provided for @cosmeticCompanionMonsterEnergyName.
  ///
  /// In en, this message translates to:
  /// **'Monster Energy'**
  String get cosmeticCompanionMonsterEnergyName;

  /// Generic close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Developer tools: grant cosmetic button label
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get devGrant;

  /// Developer tools: revoke cosmetic button label
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get devRevoke;

  /// Button to equip a cosmetic
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get cosmeticEquip;

  /// Button to unequip a cosmetic
  ///
  /// In en, this message translates to:
  /// **'Unequip'**
  String get cosmeticUnequip;

  /// DevTools pill shown when cosmetic asset is missing
  ///
  /// In en, this message translates to:
  /// **'NO ASSET'**
  String get cosmeticNoAsset;

  /// Header for companion requirements checklist
  ///
  /// In en, this message translates to:
  /// **'REQUIREMENTS'**
  String get cosmeticRequirementsHeader;

  /// Separator text between alternative unlock rules
  ///
  /// In en, this message translates to:
  /// **'— or —'**
  String get listOrSeparator;

  /// Header for debug details expansion tile
  ///
  /// In en, this message translates to:
  /// **'DEBUG DETAILS'**
  String get debugDetailsHeader;

  /// Label for debug row: id
  ///
  /// In en, this message translates to:
  /// **'id'**
  String get debugRowId;

  /// Label for debug row: type
  ///
  /// In en, this message translates to:
  /// **'type'**
  String get debugRowType;

  /// Label for debug row: rarity
  ///
  /// In en, this message translates to:
  /// **'rarity'**
  String get debugRowRarity;

  /// Label for debug row: region
  ///
  /// In en, this message translates to:
  /// **'region'**
  String get debugRowRegion;

  /// Label for debug row: asset key
  ///
  /// In en, this message translates to:
  /// **'assetKey'**
  String get debugRowAssetKey;

  /// Label for debug row: preview asset key
  ///
  /// In en, this message translates to:
  /// **'previewAssetKey'**
  String get debugRowPreviewAssetKey;

  /// Label for debug row: sort order
  ///
  /// In en, this message translates to:
  /// **'sortOrder'**
  String get debugRowSortOrder;

  /// Label for debug row: is premium
  ///
  /// In en, this message translates to:
  /// **'isPremium'**
  String get debugRowIsPremium;

  /// Label for debug row: is enabled
  ///
  /// In en, this message translates to:
  /// **'isEnabled'**
  String get debugRowIsEnabled;

  /// Label for debug row: metadata
  ///
  /// In en, this message translates to:
  /// **'metadata'**
  String get debugRowMetadata;

  /// Label for debug row: unlocked at
  ///
  /// In en, this message translates to:
  /// **'unlockedAt'**
  String get debugRowUnlockedAt;

  /// Label for debug row: source type
  ///
  /// In en, this message translates to:
  /// **'sourceType'**
  String get debugRowSourceType;

  /// Label for debug row: source id
  ///
  /// In en, this message translates to:
  /// **'sourceId'**
  String get debugRowSourceId;

  /// Placeholder when a debug value is missing
  ///
  /// In en, this message translates to:
  /// **'— missing'**
  String get debugMissing;

  /// Formatted rule source
  ///
  /// In en, this message translates to:
  /// **'source: {type} / {id}'**
  String ruleSource(String type, String id);

  /// Header for unlock conditions section
  ///
  /// In en, this message translates to:
  /// **'UNLOCK CONDITIONS'**
  String get cosmeticUnlockConditionsHeader;

  /// Snackbar shown after copying a value to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied: {value}'**
  String copiedToClipboard(String value);

  /// Label showing when a cosmetic was unlocked
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String cosmeticUnlockedAt(String date);

  /// No description provided for @cosmeticBackgroundForestTrailName.
  ///
  /// In en, this message translates to:
  /// **'Forest Trail'**
  String get cosmeticBackgroundForestTrailName;

  /// No description provided for @cosmeticBackgroundForestTrailDesc.
  ///
  /// In en, this message translates to:
  /// **'A misty path winding under the tall canopy.'**
  String get cosmeticBackgroundForestTrailDesc;

  /// No description provided for @cosmeticEmblemForestMarkName.
  ///
  /// In en, this message translates to:
  /// **'Forest Mark'**
  String get cosmeticEmblemForestMarkName;

  /// No description provided for @cosmeticEmblemForestMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A sigil carved into bark — the first travellers\' greeting.'**
  String get cosmeticEmblemForestMarkDesc;

  /// No description provided for @cosmeticFrameRuinedBronzeName.
  ///
  /// In en, this message translates to:
  /// **'Ruined Bronze'**
  String get cosmeticFrameRuinedBronzeName;

  /// No description provided for @cosmeticFrameRuinedBronzeDesc.
  ///
  /// In en, this message translates to:
  /// **'A patina-coated frame pulled from ancient ruins.'**
  String get cosmeticFrameRuinedBronzeDesc;

  /// No description provided for @cosmeticBackgroundCampName.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim Camp'**
  String get cosmeticBackgroundCampName;

  /// No description provided for @cosmeticBackgroundCampDesc.
  ///
  /// In en, this message translates to:
  /// **'A circle of stones around a fading fire — the road begins here.'**
  String get cosmeticBackgroundCampDesc;

  /// No description provided for @cosmeticBackgroundRavineName.
  ///
  /// In en, this message translates to:
  /// **'Rocky Ravine'**
  String get cosmeticBackgroundRavineName;

  /// No description provided for @cosmeticBackgroundRavineDesc.
  ///
  /// In en, this message translates to:
  /// **'A narrow cut between cliffs where the wind never stops moving.'**
  String get cosmeticBackgroundRavineDesc;

  /// No description provided for @cosmeticBackgroundRuinsName.
  ///
  /// In en, this message translates to:
  /// **'Ancient Ruins'**
  String get cosmeticBackgroundRuinsName;

  /// No description provided for @cosmeticBackgroundRuinsDesc.
  ///
  /// In en, this message translates to:
  /// **'Broken halls weathered by centuries beyond the pass.'**
  String get cosmeticBackgroundRuinsDesc;

  /// No description provided for @cosmeticBackgroundBridgeCrossingName.
  ///
  /// In en, this message translates to:
  /// **'Bridge Crossing'**
  String get cosmeticBackgroundBridgeCrossingName;

  /// No description provided for @cosmeticBackgroundBridgeCrossingDesc.
  ///
  /// In en, this message translates to:
  /// **'Suspended ropes span the deep gorge between old roads.'**
  String get cosmeticBackgroundBridgeCrossingDesc;

  /// No description provided for @cosmeticBackgroundMinesName.
  ///
  /// In en, this message translates to:
  /// **'Mining Settlement'**
  String get cosmeticBackgroundMinesName;

  /// No description provided for @cosmeticBackgroundMinesDesc.
  ///
  /// In en, this message translates to:
  /// **'Smoke and lantern light from the mountain\'s working heart.'**
  String get cosmeticBackgroundMinesDesc;

  /// No description provided for @cosmeticBackgroundFrostlandsName.
  ///
  /// In en, this message translates to:
  /// **'Frostlands'**
  String get cosmeticBackgroundFrostlandsName;

  /// No description provided for @cosmeticBackgroundFrostlandsDesc.
  ///
  /// In en, this message translates to:
  /// **'Snow-pale ground that swallows footsteps and sound.'**
  String get cosmeticBackgroundFrostlandsDesc;

  /// No description provided for @cosmeticBackgroundFrozenLakeName.
  ///
  /// In en, this message translates to:
  /// **'Frozen Lake'**
  String get cosmeticBackgroundFrozenLakeName;

  /// No description provided for @cosmeticBackgroundFrozenLakeDesc.
  ///
  /// In en, this message translates to:
  /// **'Still ice over still water — the long quiet before the climb.'**
  String get cosmeticBackgroundFrozenLakeDesc;

  /// No description provided for @cosmeticBackgroundRockyMountainsName.
  ///
  /// In en, this message translates to:
  /// **'Rocky Mountains'**
  String get cosmeticBackgroundRockyMountainsName;

  /// No description provided for @cosmeticBackgroundRockyMountainsDesc.
  ///
  /// In en, this message translates to:
  /// **'Black ridges and thin air on the road to the fortress.'**
  String get cosmeticBackgroundRockyMountainsDesc;

  /// No description provided for @cosmeticBackgroundDragonrockFortressName.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Fortress'**
  String get cosmeticBackgroundDragonrockFortressName;

  /// No description provided for @cosmeticBackgroundDragonrockFortressDesc.
  ///
  /// In en, this message translates to:
  /// **'The obsidian keep at the end of the journey.'**
  String get cosmeticBackgroundDragonrockFortressDesc;

  /// No description provided for @cosmeticEmblemPilgrimMarkName.
  ///
  /// In en, this message translates to:
  /// **'Pilgrim Mark'**
  String get cosmeticEmblemPilgrimMarkName;

  /// No description provided for @cosmeticEmblemPilgrimMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A traveller\'s badge worn by those who chose the road.'**
  String get cosmeticEmblemPilgrimMarkDesc;

  /// No description provided for @cosmeticEmblemRuinSigilName.
  ///
  /// In en, this message translates to:
  /// **'Ruin Sigil'**
  String get cosmeticEmblemRuinSigilName;

  /// No description provided for @cosmeticEmblemRuinSigilDesc.
  ///
  /// In en, this message translates to:
  /// **'A seal struck for those who walked the old halls.'**
  String get cosmeticEmblemRuinSigilDesc;

  /// No description provided for @cosmeticEmblemGatekeeperMarkName.
  ///
  /// In en, this message translates to:
  /// **'Gatekeeper Mark'**
  String get cosmeticEmblemGatekeeperMarkName;

  /// No description provided for @cosmeticEmblemGatekeeperMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A bronze badge given to those who passed the old gates.'**
  String get cosmeticEmblemGatekeeperMarkDesc;

  /// No description provided for @cosmeticEmblemMineCrestName.
  ///
  /// In en, this message translates to:
  /// **'Mine Crest'**
  String get cosmeticEmblemMineCrestName;

  /// No description provided for @cosmeticEmblemMineCrestDesc.
  ///
  /// In en, this message translates to:
  /// **'A miner\'s emblem honouring those who reached the deep workings.'**
  String get cosmeticEmblemMineCrestDesc;

  /// No description provided for @cosmeticEmblemUnderwaysMarkName.
  ///
  /// In en, this message translates to:
  /// **'Underways Mark'**
  String get cosmeticEmblemUnderwaysMarkName;

  /// No description provided for @cosmeticEmblemUnderwaysMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A sigil for those who learned the paths beneath the mountain.'**
  String get cosmeticEmblemUnderwaysMarkDesc;

  /// No description provided for @cosmeticEmblemFrostSigilName.
  ///
  /// In en, this message translates to:
  /// **'Frost Sigil'**
  String get cosmeticEmblemFrostSigilName;

  /// No description provided for @cosmeticEmblemFrostSigilDesc.
  ///
  /// In en, this message translates to:
  /// **'A pale-silver badge given to wanderers of the frozen north.'**
  String get cosmeticEmblemFrostSigilDesc;

  /// No description provided for @cosmeticEmblemIcewalkerMarkName.
  ///
  /// In en, this message translates to:
  /// **'Icewalker Mark'**
  String get cosmeticEmblemIcewalkerMarkName;

  /// No description provided for @cosmeticEmblemIcewalkerMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A badge worn by those who held their pace across the ice.'**
  String get cosmeticEmblemIcewalkerMarkDesc;

  /// No description provided for @cosmeticEmblemMountainCrestName.
  ///
  /// In en, this message translates to:
  /// **'Mountain Challenger Crest'**
  String get cosmeticEmblemMountainCrestName;

  /// No description provided for @cosmeticEmblemMountainCrestDesc.
  ///
  /// In en, this message translates to:
  /// **'An ironclad emblem for those who climbed toward the fortress.'**
  String get cosmeticEmblemMountainCrestDesc;

  /// No description provided for @cosmeticEmblemDragonMarkName.
  ///
  /// In en, this message translates to:
  /// **'Dragon Mark'**
  String get cosmeticEmblemDragonMarkName;

  /// No description provided for @cosmeticEmblemDragonMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A scaled sigil branded into those who faced the dragon road.'**
  String get cosmeticEmblemDragonMarkDesc;

  /// No description provided for @cosmeticEmblemDragonrockEmblemName.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Emblem'**
  String get cosmeticEmblemDragonrockEmblemName;

  /// No description provided for @cosmeticEmblemDragonrockEmblemDesc.
  ///
  /// In en, this message translates to:
  /// **'The black-and-gold seal of the lord of Dragonrock.'**
  String get cosmeticEmblemDragonrockEmblemDesc;

  /// No description provided for @cosmeticRelicCampfireSparkName.
  ///
  /// In en, this message translates to:
  /// **'Campfire Spark'**
  String get cosmeticRelicCampfireSparkName;

  /// No description provided for @cosmeticRelicCampfireSparkDesc.
  ///
  /// In en, this message translates to:
  /// **'The first ember from the first night out.'**
  String get cosmeticRelicCampfireSparkDesc;

  /// No description provided for @cosmeticRelicAncientRootName.
  ///
  /// In en, this message translates to:
  /// **'Ancient Root'**
  String get cosmeticRelicAncientRootName;

  /// No description provided for @cosmeticRelicAncientRootDesc.
  ///
  /// In en, this message translates to:
  /// **'A twisted root from the old forest, marker of seven days unbroken.'**
  String get cosmeticRelicAncientRootDesc;

  /// No description provided for @cosmeticRelicRavineStoneName.
  ///
  /// In en, this message translates to:
  /// **'Ravine Stone'**
  String get cosmeticRelicRavineStoneName;

  /// No description provided for @cosmeticRelicRavineStoneDesc.
  ///
  /// In en, this message translates to:
  /// **'A heavy stone carried over millions of steps.'**
  String get cosmeticRelicRavineStoneDesc;

  /// No description provided for @cosmeticRelicRuinSealName.
  ///
  /// In en, this message translates to:
  /// **'Ruin Seal'**
  String get cosmeticRelicRuinSealName;

  /// No description provided for @cosmeticRelicRuinSealDesc.
  ///
  /// In en, this message translates to:
  /// **'A wax seal pressed for completing the first weekly quest.'**
  String get cosmeticRelicRuinSealDesc;

  /// No description provided for @cosmeticRelicBridgeKeyName.
  ///
  /// In en, this message translates to:
  /// **'Bridge Key'**
  String get cosmeticRelicBridgeKeyName;

  /// No description provided for @cosmeticRelicBridgeKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'An iron key that turns the locks on the old bridge gates.'**
  String get cosmeticRelicBridgeKeyDesc;

  /// No description provided for @cosmeticRelicMinersLanternName.
  ///
  /// In en, this message translates to:
  /// **'Miner\'s Lantern'**
  String get cosmeticRelicMinersLanternName;

  /// No description provided for @cosmeticRelicMinersLanternDesc.
  ///
  /// In en, this message translates to:
  /// **'A brass lantern earned by completing fifty quests.'**
  String get cosmeticRelicMinersLanternDesc;

  /// No description provided for @cosmeticRelicPolarLanternName.
  ///
  /// In en, this message translates to:
  /// **'Polar Lantern'**
  String get cosmeticRelicPolarLanternName;

  /// No description provided for @cosmeticRelicPolarLanternDesc.
  ///
  /// In en, this message translates to:
  /// **'A pale-flame lantern for those who reached the frostlands.'**
  String get cosmeticRelicPolarLanternDesc;

  /// No description provided for @cosmeticRelicFrostShardName.
  ///
  /// In en, this message translates to:
  /// **'Frost Shard'**
  String get cosmeticRelicFrostShardName;

  /// No description provided for @cosmeticRelicFrostShardDesc.
  ///
  /// In en, this message translates to:
  /// **'A splinter of true frost, cold to the touch under any sun.'**
  String get cosmeticRelicFrostShardDesc;

  /// No description provided for @cosmeticRelicAuroraThreadName.
  ///
  /// In en, this message translates to:
  /// **'Aurora Thread'**
  String get cosmeticRelicAuroraThreadName;

  /// No description provided for @cosmeticRelicAuroraThreadDesc.
  ///
  /// In en, this message translates to:
  /// **'A strand of aurora light, woven from thirty-six unbroken weeks.'**
  String get cosmeticRelicAuroraThreadDesc;

  /// No description provided for @cosmeticRelicFrozenLakeHeartName.
  ///
  /// In en, this message translates to:
  /// **'Frozen Lake Heart'**
  String get cosmeticRelicFrozenLakeHeartName;

  /// No description provided for @cosmeticRelicFrozenLakeHeartDesc.
  ///
  /// In en, this message translates to:
  /// **'A blue-cored stone earned at one million total steps.'**
  String get cosmeticRelicFrozenLakeHeartDesc;

  /// No description provided for @cosmeticRelicDragonScaleName.
  ///
  /// In en, this message translates to:
  /// **'Dragon Scale'**
  String get cosmeticRelicDragonScaleName;

  /// No description provided for @cosmeticRelicDragonScaleDesc.
  ///
  /// In en, this message translates to:
  /// **'A black scale with a faint heat under its surface.'**
  String get cosmeticRelicDragonScaleDesc;

  /// No description provided for @cosmeticRelicWarmKindlingName.
  ///
  /// In en, this message translates to:
  /// **'Warm Kindling'**
  String get cosmeticRelicWarmKindlingName;

  /// No description provided for @cosmeticRelicWarmKindlingDesc.
  ///
  /// In en, this message translates to:
  /// **'A small bundle of dry tinder gathered before the second sunrise.'**
  String get cosmeticRelicWarmKindlingDesc;

  /// No description provided for @cosmeticRelicMoonlitFoxgloveName.
  ///
  /// In en, this message translates to:
  /// **'Moonlit Foxglove'**
  String get cosmeticRelicMoonlitFoxgloveName;

  /// No description provided for @cosmeticRelicMoonlitFoxgloveDesc.
  ///
  /// In en, this message translates to:
  /// **'A pale flower that only opens for travelers who keep moving.'**
  String get cosmeticRelicMoonlitFoxgloveDesc;

  /// No description provided for @cosmeticRelicWildwoodCharmName.
  ///
  /// In en, this message translates to:
  /// **'Wildwood Charm'**
  String get cosmeticRelicWildwoodCharmName;

  /// No description provided for @cosmeticRelicWildwoodCharmDesc.
  ///
  /// In en, this message translates to:
  /// **'A token braided from forest grasses and many seasons of steady wins.'**
  String get cosmeticRelicWildwoodCharmDesc;

  /// No description provided for @cosmeticRelicAshenOmenName.
  ///
  /// In en, this message translates to:
  /// **'Ashen Omen'**
  String get cosmeticRelicAshenOmenName;

  /// No description provided for @cosmeticRelicAshenOmenDesc.
  ///
  /// In en, this message translates to:
  /// **'A burnt mark left on the ruined stones by a steadier walker.'**
  String get cosmeticRelicAshenOmenDesc;

  /// No description provided for @cosmeticRelicOathboundMarkName.
  ///
  /// In en, this message translates to:
  /// **'Oathbound Mark'**
  String get cosmeticRelicOathboundMarkName;

  /// No description provided for @cosmeticRelicOathboundMarkDesc.
  ///
  /// In en, this message translates to:
  /// **'A sealed promise carved into bone — kept across many small victories.'**
  String get cosmeticRelicOathboundMarkDesc;

  /// No description provided for @cosmeticRelicDeepEmberCoreName.
  ///
  /// In en, this message translates to:
  /// **'Deep Ember Core'**
  String get cosmeticRelicDeepEmberCoreName;

  /// No description provided for @cosmeticRelicDeepEmberCoreDesc.
  ///
  /// In en, this message translates to:
  /// **'A coal that still burns after a million careful steps in the deep.'**
  String get cosmeticRelicDeepEmberCoreDesc;

  /// No description provided for @cosmeticRelicSummitFeatherName.
  ///
  /// In en, this message translates to:
  /// **'Summit Feather'**
  String get cosmeticRelicSummitFeatherName;

  /// No description provided for @cosmeticRelicSummitFeatherDesc.
  ///
  /// In en, this message translates to:
  /// **'Found on the wind only by those who cross every threshold.'**
  String get cosmeticRelicSummitFeatherDesc;

  /// No description provided for @cosmeticRelicStormcrestPlumeName.
  ///
  /// In en, this message translates to:
  /// **'Stormcrest Plume'**
  String get cosmeticRelicStormcrestPlumeName;

  /// No description provided for @cosmeticRelicStormcrestPlumeDesc.
  ///
  /// In en, this message translates to:
  /// **'A feather marked by a year of weekly storms outwalked.'**
  String get cosmeticRelicStormcrestPlumeDesc;

  /// No description provided for @cosmeticRelicDragonrockHeartName.
  ///
  /// In en, this message translates to:
  /// **'Dragonrock Heart'**
  String get cosmeticRelicDragonrockHeartName;

  /// No description provided for @cosmeticRelicDragonrockHeartDesc.
  ///
  /// In en, this message translates to:
  /// **'The forge-warm core of the mountain itself, given only to those who finish the trial.'**
  String get cosmeticRelicDragonrockHeartDesc;

  /// No description provided for @cosmeticFrameDisciplineName.
  ///
  /// In en, this message translates to:
  /// **'Flame of Discipline'**
  String get cosmeticFrameDisciplineName;

  /// No description provided for @cosmeticFrameDisciplineDesc.
  ///
  /// In en, this message translates to:
  /// **'Earned by holding the line for seven days in a row.'**
  String get cosmeticFrameDisciplineDesc;

  /// No description provided for @cosmeticFrameEnduranceName.
  ///
  /// In en, this message translates to:
  /// **'Endurance Frame'**
  String get cosmeticFrameEnduranceName;

  /// No description provided for @cosmeticFrameEnduranceDesc.
  ///
  /// In en, this message translates to:
  /// **'Forged for those who keep moving through a thirty-day streak.'**
  String get cosmeticFrameEnduranceDesc;

  /// No description provided for @cosmeticFrameSteelName.
  ///
  /// In en, this message translates to:
  /// **'Steel Frame'**
  String get cosmeticFrameSteelName;

  /// No description provided for @cosmeticFrameSteelDesc.
  ///
  /// In en, this message translates to:
  /// **'Hard steel for the unbroken — fifty days unbroken.'**
  String get cosmeticFrameSteelDesc;

  /// No description provided for @cosmeticFrameEternalFlameName.
  ///
  /// In en, this message translates to:
  /// **'Eternal Flame Frame'**
  String get cosmeticFrameEternalFlameName;

  /// No description provided for @cosmeticFrameEternalFlameDesc.
  ///
  /// In en, this message translates to:
  /// **'A frame for the rare hundred-day flame that never gutters.'**
  String get cosmeticFrameEternalFlameDesc;

  /// No description provided for @cosmeticFrameBalanceName.
  ///
  /// In en, this message translates to:
  /// **'Balance Frame'**
  String get cosmeticFrameBalanceName;

  /// No description provided for @cosmeticFrameBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Earned by stringing together seven perfect days.'**
  String get cosmeticFrameBalanceDesc;

  /// No description provided for @cosmeticFrameMasterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Master Routine Frame'**
  String get cosmeticFrameMasterRoutineName;

  /// No description provided for @cosmeticFrameMasterRoutineDesc.
  ///
  /// In en, this message translates to:
  /// **'A gilded frame for twelve perfect weeks — the master of the rhythm.'**
  String get cosmeticFrameMasterRoutineDesc;

  /// No description provided for @cosmeticFrameEndlessTrailName.
  ///
  /// In en, this message translates to:
  /// **'Endless Trail Frame'**
  String get cosmeticFrameEndlessTrailName;

  /// No description provided for @cosmeticFrameEndlessTrailDesc.
  ///
  /// In en, this message translates to:
  /// **'Awarded for walking 600,000 steps within 30 days.'**
  String get cosmeticFrameEndlessTrailDesc;

  /// No description provided for @cosmeticFrameWorldwalkerName.
  ///
  /// In en, this message translates to:
  /// **'Worldwalker Frame'**
  String get cosmeticFrameWorldwalkerName;

  /// No description provided for @cosmeticFrameWorldwalkerDesc.
  ///
  /// In en, this message translates to:
  /// **'A legend\'s frame, ten million steps deep.'**
  String get cosmeticFrameWorldwalkerDesc;

  /// No description provided for @cosmeticCompanionEmberSpriteName.
  ///
  /// In en, this message translates to:
  /// **'Ember Sprite'**
  String get cosmeticCompanionEmberSpriteName;

  /// No description provided for @cosmeticCompanionEmberSpriteDesc.
  ///
  /// In en, this message translates to:
  /// **'A small spark that follows the steady-footed.'**
  String get cosmeticCompanionEmberSpriteDesc;

  /// No description provided for @cosmeticCompanionForestFoxName.
  ///
  /// In en, this message translates to:
  /// **'Forest Fox'**
  String get cosmeticCompanionForestFoxName;

  /// No description provided for @cosmeticCompanionForestFoxDesc.
  ///
  /// In en, this message translates to:
  /// **'A quiet wildwood fox that pads alongside seasoned walkers.'**
  String get cosmeticCompanionForestFoxDesc;

  /// No description provided for @cosmeticCompanionRuinRavenName.
  ///
  /// In en, this message translates to:
  /// **'Ruin Raven'**
  String get cosmeticCompanionRuinRavenName;

  /// No description provided for @cosmeticCompanionRuinRavenDesc.
  ///
  /// In en, this message translates to:
  /// **'A black bird from the old halls, seen most often after a weekly quest is closed.'**
  String get cosmeticCompanionRuinRavenDesc;

  /// No description provided for @cosmeticCompanionBridgeGargoyleName.
  ///
  /// In en, this message translates to:
  /// **'Bridge Gargoyle'**
  String get cosmeticCompanionBridgeGargoyleName;

  /// No description provided for @cosmeticCompanionBridgeGargoyleDesc.
  ///
  /// In en, this message translates to:
  /// **'A stone gargoyle hatchling that guards the old bridge — sealed-bone oath and iron key are its tribute.'**
  String get cosmeticCompanionBridgeGargoyleDesc;

  /// No description provided for @cosmeticCompanionLanternGolemName.
  ///
  /// In en, this message translates to:
  /// **'Lantern Golem'**
  String get cosmeticCompanionLanternGolemName;

  /// No description provided for @cosmeticCompanionLanternGolemDesc.
  ///
  /// In en, this message translates to:
  /// **'A small stone golem with a flickering lantern in its chest.'**
  String get cosmeticCompanionLanternGolemDesc;

  /// No description provided for @cosmeticCompanionCaveLynxName.
  ///
  /// In en, this message translates to:
  /// **'Cave Lynx'**
  String get cosmeticCompanionCaveLynxName;

  /// No description provided for @cosmeticCompanionCaveLynxDesc.
  ///
  /// In en, this message translates to:
  /// **'A lynx from the rocky descent who follows walkers carrying the scent of distant forests and ravines.'**
  String get cosmeticCompanionCaveLynxDesc;

  /// No description provided for @cosmeticCompanionAuroraStagName.
  ///
  /// In en, this message translates to:
  /// **'Aurora Stag'**
  String get cosmeticCompanionAuroraStagName;

  /// No description provided for @cosmeticCompanionAuroraStagDesc.
  ///
  /// In en, this message translates to:
  /// **'A white stag whose antlers weave living aurora — it emerges on the ice plain only for walkers carrying the lake\'s heart.'**
  String get cosmeticCompanionAuroraStagDesc;

  /// No description provided for @cosmeticCompanionIceWispName.
  ///
  /// In en, this message translates to:
  /// **'Ice Wisp'**
  String get cosmeticCompanionIceWispName;

  /// No description provided for @cosmeticCompanionIceWispDesc.
  ///
  /// In en, this message translates to:
  /// **'A pale spark drawn out over the frozen lake by those who carry both lantern and shard.'**
  String get cosmeticCompanionIceWispDesc;

  /// No description provided for @cosmeticCompanionMountainGryphonName.
  ///
  /// In en, this message translates to:
  /// **'Mountain Gryphon'**
  String get cosmeticCompanionMountainGryphonName;

  /// No description provided for @cosmeticCompanionMountainGryphonDesc.
  ///
  /// In en, this message translates to:
  /// **'A grey gryphon that rides the high ridges with its chosen walker.'**
  String get cosmeticCompanionMountainGryphonDesc;

  /// No description provided for @cosmeticCompanionDragonlingName.
  ///
  /// In en, this message translates to:
  /// **'Dragonling'**
  String get cosmeticCompanionDragonlingName;

  /// No description provided for @cosmeticCompanionDragonlingDesc.
  ///
  /// In en, this message translates to:
  /// **'A small dragon that recognises only the lord of Dragonrock.'**
  String get cosmeticCompanionDragonlingDesc;

  /// No description provided for @cosmeticUnlockHintLevel.
  ///
  /// In en, this message translates to:
  /// **'Unlocked at level {level}.'**
  String cosmeticUnlockHintLevel(int level);

  /// No description provided for @cosmeticUnlockHintStreak.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by reaching a {days}-day streak.'**
  String cosmeticUnlockHintStreak(int days);

  /// No description provided for @cosmeticUnlockHintTotalSteps.
  ///
  /// In en, this message translates to:
  /// **'Unlocked at {steps} total steps.'**
  String cosmeticUnlockHintTotalSteps(int steps);

  /// No description provided for @cosmeticUnlockHintMonthlySteps.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by walking {steps} steps within 30 days.'**
  String cosmeticUnlockHintMonthlySteps(int steps);

  /// No description provided for @cosmeticUnlockHintQuestsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Unlocked after completing {count} quests.'**
  String cosmeticUnlockHintQuestsCompleted(int count);

  /// No description provided for @cosmeticUnlockHintPerfectDays.
  ///
  /// In en, this message translates to:
  /// **'Unlocked after {count} perfect days.'**
  String cosmeticUnlockHintPerfectDays(int count);

  /// No description provided for @cosmeticUnlockHintPerfectWeeks.
  ///
  /// In en, this message translates to:
  /// **'Unlocked after {count} perfect weeks.'**
  String cosmeticUnlockHintPerfectWeeks(int count);

  /// No description provided for @cosmeticUnlockHintActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Unlocked after {days} active days.'**
  String cosmeticUnlockHintActiveDays(int days);

  /// No description provided for @cosmeticUnlockHintCompound.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by completing several milestones.'**
  String get cosmeticUnlockHintCompound;

  /// No description provided for @progAchievementWelcomeToJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Journey'**
  String get progAchievementWelcomeToJourneyTitle;

  /// No description provided for @progAchievementWelcomeToJourneyDesc.
  ///
  /// In en, this message translates to:
  /// **'You set out on the road.'**
  String get progAchievementWelcomeToJourneyDesc;

  /// No description provided for @progAchievementStepsStreak50Title.
  ///
  /// In en, this message translates to:
  /// **'Iron Resolve'**
  String get progAchievementStepsStreak50Title;

  /// No description provided for @progAchievementStepsStreak50Desc.
  ///
  /// In en, this message translates to:
  /// **'Hit the daily steps rule for 50 periods in a row.'**
  String get progAchievementStepsStreak50Desc;

  /// No description provided for @cosmeticEquippedBadge.
  ///
  /// In en, this message translates to:
  /// **'EQUIPPED'**
  String get cosmeticEquippedBadge;

  /// No description provided for @cosmeticUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown cosmetic'**
  String get cosmeticUnknown;

  /// No description provided for @cosmeticHiddenName.
  ///
  /// In en, this message translates to:
  /// **'???'**
  String get cosmeticHiddenName;

  /// No description provided for @cosmeticUnknownReward.
  ///
  /// In en, this message translates to:
  /// **'Unknown reward'**
  String get cosmeticUnknownReward;

  /// No description provided for @cosmeticHiddenUnlockCondition.
  ///
  /// In en, this message translates to:
  /// **'Unlock condition not yet revealed.'**
  String get cosmeticHiddenUnlockCondition;

  /// No description provided for @cosmeticPartialProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} conditions met'**
  String cosmeticPartialProgress(int completed, int total);

  /// No description provided for @cosmeticCompanionLevelGate.
  ///
  /// In en, this message translates to:
  /// **'Reach level {level}'**
  String cosmeticCompanionLevelGate(int level);

  /// No description provided for @cosmeticCompanionLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String cosmeticCompanionLevelBadge(int level);

  /// No description provided for @cosmeticRarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get cosmeticRarityCommon;

  /// No description provided for @cosmeticRarityUncommon.
  ///
  /// In en, this message translates to:
  /// **'Uncommon'**
  String get cosmeticRarityUncommon;

  /// No description provided for @cosmeticRarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get cosmeticRarityRare;

  /// No description provided for @cosmeticRarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get cosmeticRarityEpic;

  /// No description provided for @cosmeticRarityLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get cosmeticRarityLegendary;

  /// No description provided for @cosmeticRarityMythic.
  ///
  /// In en, this message translates to:
  /// **'Mythic'**
  String get cosmeticRarityMythic;

  /// No description provided for @celebrationCosmeticUnlockedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Inventory unlocked'**
  String get celebrationCosmeticUnlockedEyebrow;

  /// No description provided for @celebrationAchievementEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get celebrationAchievementEyebrow;

  /// No description provided for @celebrationLevelEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Level reached'**
  String get celebrationLevelEyebrow;

  /// No description provided for @celebrationTitleEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Title unlocked'**
  String get celebrationTitleEyebrow;

  /// No description provided for @celebrationQuestEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Quest completed'**
  String get celebrationQuestEyebrow;

  /// No description provided for @celebrationStreakEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Streak extended'**
  String get celebrationStreakEyebrow;

  /// No description provided for @celebrationLocationEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Region discovered'**
  String get celebrationLocationEyebrow;

  /// No description provided for @celebrationChapterEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Chapter complete'**
  String get celebrationChapterEyebrow;

  /// No description provided for @celebrationChapterUnlockedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'New chapter unlocked'**
  String get celebrationChapterUnlockedEyebrow;

  /// No description provided for @celebrationMilestoneEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Milestone reached'**
  String get celebrationMilestoneEyebrow;

  /// No description provided for @celebrationRelicEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Relic acquired'**
  String get celebrationRelicEyebrow;

  /// No description provided for @celebrationContentUnlockEyebrow.
  ///
  /// In en, this message translates to:
  /// **'New chapter'**
  String get celebrationContentUnlockEyebrow;

  /// No description provided for @celebrationCompanionReadyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Companion ready'**
  String get celebrationCompanionReadyEyebrow;

  /// No description provided for @celebrationGoalEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Goal complete'**
  String get celebrationGoalEyebrow;

  /// No description provided for @celebrationAchievementPackEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Moment'**
  String get celebrationAchievementPackEyebrow;

  /// No description provided for @celebrationAchievementPackTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 achievement unlocked} other{{count} achievements unlocked}}'**
  String celebrationAchievementPackTitle(int count);

  /// No description provided for @celebrationWelcomeBackEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get celebrationWelcomeBackEyebrow;

  /// No description provided for @celebrationWelcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} reward waiting for you} other{{count} rewards waiting for you}}'**
  String celebrationWelcomeBackTitle(int count);

  /// No description provided for @celebrationCosmeticUnlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{New reward} other{{count} new rewards}}'**
  String celebrationCosmeticUnlockedTitle(int count);

  /// No description provided for @celebrationOrphanRewardHint.
  ///
  /// In en, this message translates to:
  /// **'Reward from your progress'**
  String get celebrationOrphanRewardHint;

  /// No description provided for @celebrationSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Summary from the latest sync'**
  String get celebrationSummaryHint;

  /// No description provided for @celebrationChapterUnlockedSuffix.
  ///
  /// In en, this message translates to:
  /// **'Next chapter unlocked: {name}'**
  String celebrationChapterUnlockedSuffix(String name);

  /// No description provided for @celebrationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get celebrationContinue;

  /// No description provided for @celebrationOpenInventory.
  ///
  /// In en, this message translates to:
  /// **'Open inventory →'**
  String get celebrationOpenInventory;

  /// Secondary CTA on fullscreen celebration when a companion-availability reward is present.
  ///
  /// In en, this message translates to:
  /// **'Claim companion →'**
  String get celebrationClaimCompanion;

  /// Pill on a companion grid card whose availability node is pending claim.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get cosmeticCompanionClaimableBadge;

  /// Placeholder name shown for a claimable-but-not-yet-claimed companion.
  ///
  /// In en, this message translates to:
  /// **'Mysterious companion'**
  String get cosmeticCompanionClaimableHiddenName;

  /// Action button in the companion details sheet that triggers the claim animation.
  ///
  /// In en, this message translates to:
  /// **'Claim companion'**
  String get cosmeticCompanionClaimCta;

  /// Hint shown above the claim animation in the companion details sheet — describes the action the player is about to take by tapping the claim button below.
  ///
  /// In en, this message translates to:
  /// **'Fuse the required relics and summon your companion.'**
  String get cosmeticCompanionClaimableHint;

  /// Hint shown on the standalone companion-availability celebration — points the player to the inventory where the claim animation lives.
  ///
  /// In en, this message translates to:
  /// **'Open its card in your inventory to claim it.'**
  String get cosmeticCompanionCelebrationHint;

  /// Flavor text shown during the claim animation.
  ///
  /// In en, this message translates to:
  /// **'Forging companion…'**
  String get cosmeticCompanionClaimingFlavor;

  /// Status label shown during the opening fly-in phase of the companion claim ritual (t < 600ms).
  ///
  /// In en, this message translates to:
  /// **'Preparing the ritual…'**
  String get cosmeticCompanionClaimStepRitual;

  /// Status label shown while the relics orbit and pull to the center (600 ≤ t < 2400ms).
  ///
  /// In en, this message translates to:
  /// **'Binding the relics…'**
  String get cosmeticCompanionClaimStepBinding;

  /// Status label shown while the companion sprite materializes (2900 ≤ t < 4700ms).
  ///
  /// In en, this message translates to:
  /// **'Awakening your companion…'**
  String get cosmeticCompanionClaimStepAwakening;

  /// Subtitle shown beneath the companion name at the reveal moment (t ≥ 4700ms).
  ///
  /// In en, this message translates to:
  /// **'Your new companion'**
  String get cosmeticCompanionClaimRevealSubtitle;

  /// Hint shown at the bottom of the reveal hold screen — instructs the player to tap to advance into the morph handoff.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to continue'**
  String get cosmeticCompanionClaimTapToContinue;

  /// Header above the companion XP buff chip in the details sheet + hero card.
  ///
  /// In en, this message translates to:
  /// **'XP bonus'**
  String get cosmeticBuffSectionTitle;

  /// Flat companion buff label. {percent} is integer; {source} is one of the cosmeticBuffSource* strings.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% XP {source}'**
  String cosmeticBuffFlat(int percent, String source);

  /// Ember Sprite dynamic buff — streak-length tier range.
  ///
  /// In en, this message translates to:
  /// **'+{min}–{max}% XP from streak (grows with flame)'**
  String cosmeticBuffEmber(int min, int max);

  /// Ruin Raven dynamic buff — daily vs weekly quest emphasis.
  ///
  /// In en, this message translates to:
  /// **'+{daily}% daily / +{weekly}% weekly quest XP'**
  String cosmeticBuffRaven(int daily, int weekly);

  /// Cave Lynx dynamic buff — chapter chain depth range.
  ///
  /// In en, this message translates to:
  /// **'+{opener}–{deep}% chapter XP (grows with chain depth)'**
  String cosmeticBuffLynx(int opener, int deep);

  /// No description provided for @cosmeticBuffSourceActivityXp.
  ///
  /// In en, this message translates to:
  /// **'from activities'**
  String get cosmeticBuffSourceActivityXp;

  /// No description provided for @cosmeticBuffSourceNutritionXp.
  ///
  /// In en, this message translates to:
  /// **'from nutrition'**
  String get cosmeticBuffSourceNutritionXp;

  /// No description provided for @cosmeticBuffSourceSleepXp.
  ///
  /// In en, this message translates to:
  /// **'from sleep'**
  String get cosmeticBuffSourceSleepXp;

  /// No description provided for @cosmeticBuffSourceStreakXp.
  ///
  /// In en, this message translates to:
  /// **'from streak'**
  String get cosmeticBuffSourceStreakXp;

  /// No description provided for @cosmeticBuffSourceQuestXp.
  ///
  /// In en, this message translates to:
  /// **'from quests'**
  String get cosmeticBuffSourceQuestXp;

  /// No description provided for @cosmeticBuffSourceChapterXp.
  ///
  /// In en, this message translates to:
  /// **'from chapter quests'**
  String get cosmeticBuffSourceChapterXp;

  /// No description provided for @cosmeticBuffSourceAllXp.
  ///
  /// In en, this message translates to:
  /// **'from all XP'**
  String get cosmeticBuffSourceAllXp;

  /// Pill shown on a relic that has been used to summon a companion.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get cosmeticRelicConsumedBadge;

  /// Detail hint shown on a relic that has been consumed by a companion claim.
  ///
  /// In en, this message translates to:
  /// **'Used to summon a companion.'**
  String get cosmeticRelicConsumedHint;

  /// No description provided for @celebrationLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {title}'**
  String celebrationLevelTitle(int level, String title);

  /// No description provided for @celebrationLevelTitleNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String celebrationLevelTitleNoTitle(int level);

  /// No description provided for @celebrationLevelDecorativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {name}'**
  String celebrationLevelDecorativeTitle(int level, String name);

  /// No description provided for @celebrationXpRewardName.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String celebrationXpRewardName(int xp);

  /// No description provided for @celebrationLevelRewardName.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String celebrationLevelRewardName(int level);

  /// No description provided for @celebrationCloseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get celebrationCloseSemantic;

  /// No description provided for @celebrationTypeAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get celebrationTypeAchievement;

  /// No description provided for @celebrationTypeQuest.
  ///
  /// In en, this message translates to:
  /// **'Quest'**
  String get celebrationTypeQuest;

  /// No description provided for @celebrationTypeLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get celebrationTypeLevel;

  /// No description provided for @celebrationTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get celebrationTypeTitle;

  /// No description provided for @celebrationTypeStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get celebrationTypeStreak;

  /// No description provided for @celebrationTypeLocation.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get celebrationTypeLocation;

  /// No description provided for @celebrationTypeCosmetic.
  ///
  /// In en, this message translates to:
  /// **'Cosmetic'**
  String get celebrationTypeCosmetic;

  /// No description provided for @celebrationKindTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get celebrationKindTitle;

  /// No description provided for @celebrationKindFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get celebrationKindFrame;

  /// No description provided for @celebrationKindBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get celebrationKindBackground;

  /// No description provided for @celebrationKindCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get celebrationKindCompanion;

  /// No description provided for @celebrationKindBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get celebrationKindBadge;

  /// No description provided for @celebrationKindGem.
  ///
  /// In en, this message translates to:
  /// **'Relic'**
  String get celebrationKindGem;

  /// No description provided for @celebrationKindLocation.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get celebrationKindLocation;

  /// No description provided for @celebrationKindXp.
  ///
  /// In en, this message translates to:
  /// **'XP reward'**
  String get celebrationKindXp;

  /// No description provided for @celebrationKindFlame.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get celebrationKindFlame;

  /// No description provided for @celebrationKindFlag.
  ///
  /// In en, this message translates to:
  /// **'Quest'**
  String get celebrationKindFlag;

  /// No description provided for @celebrationKindSparkle.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get celebrationKindSparkle;

  /// No description provided for @socialTabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get socialTabFeed;

  /// No description provided for @socialTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get socialTabActivity;

  /// No description provided for @socialTabLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get socialTabLeaderboard;

  /// No description provided for @socialTabFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get socialTabFriends;

  /// No description provided for @socialSectionRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get socialSectionRecentActivity;

  /// No description provided for @socialSectionFriendActivity.
  ///
  /// In en, this message translates to:
  /// **'FRIEND ACTIVITY'**
  String get socialSectionFriendActivity;

  /// No description provided for @socialNoNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get socialNoNotificationsTitle;

  /// No description provided for @socialNoNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reactions from friends on your shared achievements will appear here.'**
  String get socialNoNotificationsSubtitle;

  /// No description provided for @socialFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed is empty'**
  String get socialFeedEmptyTitle;

  /// No description provided for @socialFeedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared achievements from friends will appear here.'**
  String get socialFeedEmptySubtitle;

  /// No description provided for @socialFriendsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get socialFriendsEmptyTitle;

  /// No description provided for @socialFriendsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add friends by searching for their handle.'**
  String get socialFriendsEmptySubtitle;

  /// No description provided for @socialFriendsSectionCount.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS  •  {count}'**
  String socialFriendsSectionCount(int count);

  /// No description provided for @socialFriendRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get socialFriendRequestsTitle;

  /// No description provided for @socialOutgoingRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'Sent requests • {count}'**
  String socialOutgoingRequestsCount(int count);

  /// No description provided for @socialFriendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted.'**
  String get socialFriendRequestAccepted;

  /// No description provided for @socialFriendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get socialFriendRequestDeclined;

  /// No description provided for @socialFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent.'**
  String get socialFriendRequestSent;

  /// No description provided for @socialErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String socialErrorWithMessage(String message);

  /// No description provided for @socialWantsToBeFriend.
  ///
  /// In en, this message translates to:
  /// **'Wants to become your friend'**
  String get socialWantsToBeFriend;

  /// No description provided for @socialAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get socialAccept;

  /// No description provided for @socialDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get socialDecline;

  /// No description provided for @socialAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get socialAwaitingConfirmation;

  /// No description provided for @socialPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get socialPending;

  /// No description provided for @socialSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by handle…'**
  String get socialSearchHint;

  /// No description provided for @socialSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get socialSearchButton;

  /// No description provided for @socialAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get socialAdd;

  /// No description provided for @socialHandleLevel.
  ///
  /// In en, this message translates to:
  /// **'@{handle} · Level {level}'**
  String socialHandleLevel(String handle, int level);

  /// No description provided for @socialLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String socialLevelLabel(int level);

  /// No description provided for @socialFriendCount.
  ///
  /// In en, this message translates to:
  /// **'{count} friends'**
  String socialFriendCount(int count);

  /// No description provided for @socialLeaderboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get socialLeaderboardThisWeek;

  /// No description provided for @socialLeaderboardAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get socialLeaderboardAllTime;

  /// No description provided for @socialLeaderboardSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get socialLeaderboardSoonTitle;

  /// No description provided for @socialLeaderboardSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly leaderboard will be available soon.'**
  String get socialLeaderboardSoonSubtitle;

  /// No description provided for @socialLeaderboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard is empty'**
  String get socialLeaderboardEmptyTitle;

  /// No description provided for @socialLeaderboardEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add friends and compare your results.'**
  String get socialLeaderboardEmptySubtitle;

  /// No description provided for @socialLeaderboardTopPlayers.
  ///
  /// In en, this message translates to:
  /// **'TOP PLAYERS'**
  String get socialLeaderboardTopPlayers;

  /// No description provided for @socialYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You!'**
  String get socialYouBadge;

  /// No description provided for @socialYouSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String socialYouSuffix(String name);

  /// No description provided for @socialXpLabel.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get socialXpLabel;

  /// No description provided for @socialStatusSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is required for social features.'**
  String get socialStatusSignInRequired;

  /// No description provided for @socialStatusBackendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Firebase backend unavailable: {error}'**
  String socialStatusBackendUnavailable(String error);

  /// No description provided for @socialStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to social backend…'**
  String get socialStatusConnecting;

  /// No description provided for @socialStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String socialStatusError(String error);

  /// No description provided for @socialEditHandleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Social ID'**
  String get socialEditHandleTitle;

  /// No description provided for @socialEditHandleDescription.
  ///
  /// In en, this message translates to:
  /// **'Your ID is used to find you in Social.'**
  String get socialEditHandleDescription;

  /// No description provided for @socialEditHandleValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one character.'**
  String get socialEditHandleValidation;

  /// No description provided for @socialCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get socialCancel;

  /// No description provided for @socialSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get socialSave;

  /// No description provided for @socialEditHandleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change ID'**
  String get socialEditHandleTooltip;

  /// No description provided for @socialEditPhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get socialEditPhotoTooltip;

  /// No description provided for @socialHandleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'ID could not be saved: {error}'**
  String socialHandleSaveFailed(String error);

  /// No description provided for @socialHandleSaved.
  ///
  /// In en, this message translates to:
  /// **'Social ID saved: @{handle}'**
  String socialHandleSaved(String handle);

  /// No description provided for @socialPhotoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo selection failed: {error}'**
  String socialPhotoPickFailed(String error);

  /// No description provided for @socialPhotoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo could not be saved: {error}'**
  String socialPhotoSaveFailed(String error);

  /// No description provided for @socialPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo saved.'**
  String get socialPhotoSaved;

  /// No description provided for @socialTryAgain.
  ///
  /// In en, this message translates to:
  /// **'try again'**
  String get socialTryAgain;

  /// No description provided for @socialSelectedLoadout.
  ///
  /// In en, this message translates to:
  /// **'Selected\nloadout'**
  String get socialSelectedLoadout;

  /// No description provided for @socialProfilePinnedAchievements.
  ///
  /// In en, this message translates to:
  /// **'PINNED ACHIEVEMENTS'**
  String get socialProfilePinnedAchievements;

  /// No description provided for @socialProfileSharedPosts.
  ///
  /// In en, this message translates to:
  /// **'SHARED POSTS'**
  String get socialProfileSharedPosts;

  /// No description provided for @socialProfileStatsAchievements.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENTS'**
  String get socialProfileStatsAchievements;

  /// No description provided for @socialProfileStatsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'BEST STREAK'**
  String get socialProfileStatsBestStreak;

  /// No description provided for @socialProfileStatsStepsStreak.
  ///
  /// In en, this message translates to:
  /// **'STEPS STREAK'**
  String get socialProfileStatsStepsStreak;

  /// No description provided for @socialDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String socialDaysShort(int count);

  /// No description provided for @socialPinnedEmptyMine.
  ///
  /// In en, this message translates to:
  /// **'You have nothing pinned yet. Open an achievement detail and pin it to your profile.'**
  String get socialPinnedEmptyMine;

  /// No description provided for @socialPinnedEmptyOther.
  ///
  /// In en, this message translates to:
  /// **'No pinned achievements.'**
  String get socialPinnedEmptyOther;

  /// No description provided for @socialPinnedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pinned achievements are no longer available.'**
  String get socialPinnedUnavailable;

  /// No description provided for @socialSharedPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared posts yet.'**
  String get socialSharedPostsEmpty;

  /// No description provided for @socialProfileCosmetics.
  ///
  /// In en, this message translates to:
  /// **'COSMETICS'**
  String get socialProfileCosmetics;

  /// No description provided for @socialAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get socialAddFriend;

  /// No description provided for @socialRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get socialRequestSent;

  /// No description provided for @socialRemoveFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get socialRemoveFriend;

  /// No description provided for @socialRemoveFriendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get socialRemoveFriendConfirmTitle;

  /// No description provided for @socialRemoveFriendConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to remove {name} from your friends?'**
  String socialRemoveFriendConfirmBody(String name);

  /// No description provided for @socialNotificationReactedPrefix.
  ///
  /// In en, this message translates to:
  /// **' reacted '**
  String get socialNotificationReactedPrefix;

  /// No description provided for @socialNotificationReactedSuffix.
  ///
  /// In en, this message translates to:
  /// **' to your achievement '**
  String get socialNotificationReactedSuffix;

  /// No description provided for @socialNotificationOpenPost.
  ///
  /// In en, this message translates to:
  /// **'View post'**
  String get socialNotificationOpenPost;

  /// No description provided for @socialAchievementUnlockedAction.
  ///
  /// In en, this message translates to:
  /// **'unlocked an achievement'**
  String get socialAchievementUnlockedAction;

  /// No description provided for @socialReactorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reacted ({count})'**
  String socialReactorsTitle(int count);

  /// No description provided for @socialProfileFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'FRIENDS'**
  String get socialProfileFriendsTitle;

  /// No description provided for @socialProfileNoFriends.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.'**
  String get socialProfileNoFriends;

  /// No description provided for @socialFriendLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} {title}'**
  String socialFriendLevelSubtitle(int level, String title);

  /// No description provided for @socialFriendHandleLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'@{handle} - Level {level} {title}'**
  String socialFriendHandleLevelSubtitle(
      String handle, int level, String title);

  /// No description provided for @socialRelativeNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get socialRelativeNow;

  /// No description provided for @socialRelativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String socialRelativeMinutesAgo(int count);

  /// No description provided for @socialRelativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String socialRelativeHoursAgo(int count);

  /// No description provided for @socialRelativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get socialRelativeYesterday;

  /// No description provided for @socialRelativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String socialRelativeDaysAgo(int count);

  /// No description provided for @cosmeticFramePilgrimUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reward for starting your journey.'**
  String get cosmeticFramePilgrimUnlockHint;

  /// No description provided for @cosmeticFrameWildwoodUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 10.'**
  String get cosmeticFrameWildwoodUnlockHint;

  /// No description provided for @cosmeticFrameRuinsUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 20.'**
  String get cosmeticFrameRuinsUnlockHint;

  /// No description provided for @cosmeticFrameDwarvenUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 25.'**
  String get cosmeticFrameDwarvenUnlockHint;

  /// No description provided for @cosmeticFrameUnderwaysUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 40.'**
  String get cosmeticFrameUnderwaysUnlockHint;

  /// No description provided for @cosmeticFrameFrostUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 60.'**
  String get cosmeticFrameFrostUnlockHint;

  /// No description provided for @cosmeticFrameMountainUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 80.'**
  String get cosmeticFrameMountainUnlockHint;

  /// No description provided for @cosmeticFrameDragonrockUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 100.'**
  String get cosmeticFrameDragonrockUnlockHint;

  /// No description provided for @cosmeticFrameDisciplineUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 7-day step streak.'**
  String get cosmeticFrameDisciplineUnlockHint;

  /// No description provided for @cosmeticFrameEnduranceUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 30-day step streak.'**
  String get cosmeticFrameEnduranceUnlockHint;

  /// No description provided for @cosmeticFrameSteelUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 50-day step streak.'**
  String get cosmeticFrameSteelUnlockHint;

  /// No description provided for @cosmeticFrameEternalFlameUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 100-day step streak.'**
  String get cosmeticFrameEternalFlameUnlockHint;

  /// No description provided for @cosmeticFrameBalanceUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Achieve 7 perfect activity days.'**
  String get cosmeticFrameBalanceUnlockHint;

  /// No description provided for @cosmeticFrameMasterRoutineUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Achieve 12 perfect activity weeks.'**
  String get cosmeticFrameMasterRoutineUnlockHint;

  /// No description provided for @cosmeticFrameEndlessTrailUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Walk 600,000 steps within 30 days.'**
  String get cosmeticFrameEndlessTrailUnlockHint;

  /// No description provided for @cosmeticFrameWorldwalkerUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Walk 10,000,000 total steps.'**
  String get cosmeticFrameWorldwalkerUnlockHint;

  /// No description provided for @cosmeticBackgroundForestTrailUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 5.'**
  String get cosmeticBackgroundForestTrailUnlockHint;

  /// No description provided for @cosmeticBackgroundCampUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete your first quest.'**
  String get cosmeticBackgroundCampUnlockHint;

  /// No description provided for @cosmeticBackgroundRavineUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 15.'**
  String get cosmeticBackgroundRavineUnlockHint;

  /// No description provided for @cosmeticBackgroundRuinsUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 25.'**
  String get cosmeticBackgroundRuinsUnlockHint;

  /// No description provided for @cosmeticBackgroundBridgeCrossingUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 35.'**
  String get cosmeticBackgroundBridgeCrossingUnlockHint;

  /// No description provided for @cosmeticBackgroundMinesUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 45.'**
  String get cosmeticBackgroundMinesUnlockHint;

  /// No description provided for @cosmeticBackgroundFrostlandsUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 60.'**
  String get cosmeticBackgroundFrostlandsUnlockHint;

  /// No description provided for @cosmeticBackgroundFrozenLakeUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 75.'**
  String get cosmeticBackgroundFrozenLakeUnlockHint;

  /// No description provided for @cosmeticBackgroundRockyMountainsUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 80.'**
  String get cosmeticBackgroundRockyMountainsUnlockHint;

  /// No description provided for @cosmeticBackgroundDragonrockFortressUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 95.'**
  String get cosmeticBackgroundDragonrockFortressUnlockHint;

  /// No description provided for @cosmeticEmblemForestMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Forest Trial.'**
  String get cosmeticEmblemForestMarkUnlockHint;

  /// No description provided for @cosmeticEmblemPilgrimMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Pilgrim\'s Path.'**
  String get cosmeticEmblemPilgrimMarkUnlockHint;

  /// No description provided for @cosmeticEmblemRuinSigilUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Ruins of Discipline.'**
  String get cosmeticEmblemRuinSigilUnlockHint;

  /// No description provided for @cosmeticEmblemGatekeeperMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Mine Descent.'**
  String get cosmeticEmblemGatekeeperMarkUnlockHint;

  /// No description provided for @cosmeticEmblemMineCrestUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Forge of Momentum.'**
  String get cosmeticEmblemMineCrestUnlockHint;

  /// No description provided for @cosmeticEmblemUnderwaysMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Underway Pact.'**
  String get cosmeticEmblemUnderwaysMarkUnlockHint;

  /// No description provided for @cosmeticEmblemFrostSigilUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Frostbound Oath.'**
  String get cosmeticEmblemFrostSigilUnlockHint;

  /// No description provided for @cosmeticEmblemIcewalkerMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Icewalker Route.'**
  String get cosmeticEmblemIcewalkerMarkUnlockHint;

  /// No description provided for @cosmeticEmblemMountainCrestUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Mountain Ascent.'**
  String get cosmeticEmblemMountainCrestUnlockHint;

  /// No description provided for @cosmeticEmblemDragonMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Dragonroad.'**
  String get cosmeticEmblemDragonMarkUnlockHint;

  /// No description provided for @cosmeticEmblemDragonrockEmblemUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Dragonrock Sovereign.'**
  String get cosmeticEmblemDragonrockEmblemUnlockHint;

  /// No description provided for @cosmeticRelicCampfireSparkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete your first daily quest.'**
  String get cosmeticRelicCampfireSparkUnlockHint;

  /// No description provided for @cosmeticRelicAncientRootUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 7-day step streak.'**
  String get cosmeticRelicAncientRootUnlockHint;

  /// No description provided for @cosmeticRelicRavineStoneUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Walk 2,500,000 total steps.'**
  String get cosmeticRelicRavineStoneUnlockHint;

  /// No description provided for @cosmeticRelicRuinSealUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete your first weekly quest.'**
  String get cosmeticRelicRuinSealUnlockHint;

  /// No description provided for @cosmeticRelicBridgeKeyUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 weekly quests.'**
  String get cosmeticRelicBridgeKeyUnlockHint;

  /// No description provided for @cosmeticRelicMinersLanternUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete 50 quests.'**
  String get cosmeticRelicMinersLanternUnlockHint;

  /// No description provided for @cosmeticRelicPolarLanternUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 55.'**
  String get cosmeticRelicPolarLanternUnlockHint;

  /// No description provided for @cosmeticRelicFrostShardUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 65.'**
  String get cosmeticRelicFrostShardUnlockHint;

  /// No description provided for @cosmeticRelicAuroraThreadUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 36 times.'**
  String get cosmeticRelicAuroraThreadUnlockHint;

  /// No description provided for @cosmeticRelicFrozenLakeHeartUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Walk 1,000,000 total steps.'**
  String get cosmeticRelicFrozenLakeHeartUnlockHint;

  /// No description provided for @cosmeticRelicDragonScaleUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 85.'**
  String get cosmeticRelicDragonScaleUnlockHint;

  /// No description provided for @cosmeticRelicWarmKindlingUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 daily quests.'**
  String get cosmeticRelicWarmKindlingUnlockHint;

  /// No description provided for @cosmeticRelicMoonlitFoxgloveUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Stay active for 7 days.'**
  String get cosmeticRelicMoonlitFoxgloveUnlockHint;

  /// No description provided for @cosmeticRelicWildwoodCharmUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Be active for 90 days.'**
  String get cosmeticRelicWildwoodCharmUnlockHint;

  /// No description provided for @cosmeticRelicAshenOmenUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 4 times.'**
  String get cosmeticRelicAshenOmenUnlockHint;

  /// No description provided for @cosmeticRelicOathboundMarkUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete 10 combo quests.'**
  String get cosmeticRelicOathboundMarkUnlockHint;

  /// No description provided for @cosmeticRelicDeepEmberCoreUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Walk 1,000,000 total steps.'**
  String get cosmeticRelicDeepEmberCoreUnlockHint;

  /// No description provided for @cosmeticRelicSummitFeatherUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete 100 triple combo quests.'**
  String get cosmeticRelicSummitFeatherUnlockHint;

  /// No description provided for @cosmeticRelicStormcrestPlumeUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the weekly activity rule 52 times.'**
  String get cosmeticRelicStormcrestPlumeUnlockHint;

  /// No description provided for @cosmeticRelicDragonrockHeartUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the Dragonrock Trial.'**
  String get cosmeticRelicDragonrockHeartUnlockHint;

  /// No description provided for @cosmeticCompanionEmberSpriteUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Stay active for 7 days or complete 3 daily quests.'**
  String get cosmeticCompanionEmberSpriteUnlockHint;

  /// No description provided for @cosmeticCompanionForestFoxUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Forest Mark and the Ancient Root.'**
  String get cosmeticCompanionForestFoxUnlockHint;

  /// No description provided for @cosmeticCompanionRuinRavenUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Ruin Seal and the Ashen Omen.'**
  String get cosmeticCompanionRuinRavenUnlockHint;

  /// No description provided for @cosmeticCompanionBridgeGargoyleUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Oathbound Mark and the Bridge Key.'**
  String get cosmeticCompanionBridgeGargoyleUnlockHint;

  /// No description provided for @cosmeticCompanionLanternGolemUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Deep Ember Core and the Miner\'s Lantern.'**
  String get cosmeticCompanionLanternGolemUnlockHint;

  /// No description provided for @cosmeticCompanionCaveLynxUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Wildwood Charm and the Ravine Stone.'**
  String get cosmeticCompanionCaveLynxUnlockHint;

  /// No description provided for @cosmeticCompanionAuroraStagUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Frozen Lake Heart and the Aurora Thread.'**
  String get cosmeticCompanionAuroraStagUnlockHint;

  /// No description provided for @cosmeticCompanionIceWispUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Polar Lantern and the Frost Shard.'**
  String get cosmeticCompanionIceWispUnlockHint;

  /// No description provided for @cosmeticCompanionMountainGryphonUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Obtain the Summit Feather and the Stormcrest Plume.'**
  String get cosmeticCompanionMountainGryphonUnlockHint;

  /// No description provided for @cosmeticCompanionDragonlingUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Reach level 95 and obtain the Dragon Scale and the Dragonrock Heart.'**
  String get cosmeticCompanionDragonlingUnlockHint;

  /// Screen title and settings tile for the Bushido coach-log export screen
  ///
  /// In en, this message translates to:
  /// **'Coach Log Export'**
  String get coachLogExportTitle;

  /// Button that exports the current ISO week up to today
  ///
  /// In en, this message translates to:
  /// **'Export current week'**
  String get coachLogExportCurrentWeekButton;

  /// Button that exports the selected date range
  ///
  /// In en, this message translates to:
  /// **'Export range'**
  String get coachLogExportRangeButton;

  /// Label shown while the coach-log export is in progress
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get coachLogExportRunning;

  /// Success message after a successful export
  ///
  /// In en, this message translates to:
  /// **'Exported {count} week(s)'**
  String coachLogExportSuccessWeeks(int count);

  /// Button that opens the exported spreadsheet in Google Sheets
  ///
  /// In en, this message translates to:
  /// **'Open in Sheets'**
  String get coachLogExportOpenSheets;

  /// Short description shown on the coach-log export screen
  ///
  /// In en, this message translates to:
  /// **'Writes a weekly coach-log block — weight, steps, calories, macros — into the Coach Log tab of your Forgetrack spreadsheet.'**
  String get coachLogExportDescription;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Forgetrack'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your health, hit goals, and turn the work into XP.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get onboardingAboutTitle;

  /// No description provided for @onboardingAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Forgetrack pulls steps, sleep, and activity from Health Connect, syncs nutrition from Kaloričke Tabulky, and turns daily/weekly goals into a journey of quests, levels and rewards.'**
  String get onboardingAboutBody;

  /// No description provided for @onboardingStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your integrations'**
  String get onboardingStepsTitle;

  /// No description provided for @onboardingStepsHint.
  ///
  /// In en, this message translates to:
  /// **'All of these are optional. You can skip any and connect or change them later in Settings.'**
  String get onboardingStepsHint;

  /// No description provided for @onboardingGoogleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get onboardingGoogleTitle;

  /// No description provided for @onboardingGoogleBody.
  ///
  /// In en, this message translates to:
  /// **'Saves your progression to the cloud and syncs across devices.'**
  String get onboardingGoogleBody;

  /// No description provided for @onboardingGoogleAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onboardingGoogleAction;

  /// No description provided for @onboardingGoogleConnected.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String onboardingGoogleConnected(String email);

  /// No description provided for @onboardingKtTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Kaloričke Tabulky'**
  String get onboardingKtTitle;

  /// No description provided for @onboardingKtBody.
  ///
  /// In en, this message translates to:
  /// **'Imports nutrition and weight from your KT diary.'**
  String get onboardingKtBody;

  /// No description provided for @onboardingKtConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected as {email}'**
  String onboardingKtConnected(String email);

  /// No description provided for @onboardingKtEmailHint.
  ///
  /// In en, this message translates to:
  /// **'KT email'**
  String get onboardingKtEmailHint;

  /// No description provided for @onboardingKtPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get onboardingKtPasswordHint;

  /// No description provided for @onboardingKtAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get onboardingKtAction;

  /// No description provided for @onboardingHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Connect'**
  String get onboardingHealthTitle;

  /// No description provided for @onboardingHealthBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Forgetrack to read steps, calories, sleep and activity from Health Connect. Your records stay in Health Connect — they are never copied or modified.'**
  String get onboardingHealthBody;

  /// No description provided for @onboardingHealthAction.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get onboardingHealthAction;

  /// No description provided for @onboardingHealthConnected.
  ///
  /// In en, this message translates to:
  /// **'Health Connect access granted'**
  String get onboardingHealthConnected;

  /// No description provided for @onboardingSheetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Sheets export'**
  String get onboardingSheetsTitle;

  /// No description provided for @onboardingSheetsBody.
  ///
  /// In en, this message translates to:
  /// **'Optional: export weekly summaries to a Google Sheet. Forgetrack only writes to spreadsheets it creates for you.'**
  String get onboardingSheetsBody;

  /// No description provided for @onboardingSheetsAction.
  ///
  /// In en, this message translates to:
  /// **'Allow Sheets access'**
  String get onboardingSheetsAction;

  /// No description provided for @onboardingSheetsConnected.
  ///
  /// In en, this message translates to:
  /// **'Sheets access granted'**
  String get onboardingSheetsConnected;

  /// No description provided for @onboardingNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingNotificationsTitle;

  /// No description provided for @onboardingNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders, quest progress, and reward unlocks.'**
  String get onboardingNotificationsBody;

  /// No description provided for @onboardingNotificationsAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get onboardingNotificationsAction;

  /// No description provided for @onboardingNotificationsConnected.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get onboardingNotificationsConnected;

  /// No description provided for @onboardingFooterNote.
  ///
  /// In en, this message translates to:
  /// **'You can change all of this later under Settings.'**
  String get onboardingFooterNote;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to app'**
  String get onboardingContinue;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkip;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// No description provided for @welcomeCtaStart.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey'**
  String get welcomeCtaStart;

  /// No description provided for @welcomeCtaContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get welcomeCtaContinue;

  /// No description provided for @welcomeCtaFinish.
  ///
  /// In en, this message translates to:
  /// **'Enter the game'**
  String get welcomeCtaFinish;

  /// No description provided for @welcomeStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome, hero.'**
  String get welcomeStep1Title;

  /// No description provided for @welcomeStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Forgetrack turns your health into a journey of quests — steps, sleep and food become XP, levels and titles.'**
  String get welcomeStep1Subtitle;

  /// Highlighted phrase inside welcomeStep1Subtitle. Must appear verbatim within the subtitle string for the in-text colouring to find it.
  ///
  /// In en, this message translates to:
  /// **'a journey of quests'**
  String get welcomeStep1SubtitleAccent;

  /// No description provided for @welcomeStep1HeroLabel.
  ///
  /// In en, this message translates to:
  /// **'YOUR START'**
  String get welcomeStep1HeroLabel;

  /// No description provided for @welcomeStep1HeroXpProgress.
  ///
  /// In en, this message translates to:
  /// **'{into} / {toNext} XP to the next level'**
  String welcomeStep1HeroXpProgress(int into, int toNext);

  /// No description provided for @welcomeStep1HeroPill.
  ///
  /// In en, this message translates to:
  /// **'+50 XP'**
  String get welcomeStep1HeroPill;

  /// No description provided for @welcomeStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get welcomeStep2Title;

  /// No description provided for @welcomeStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google and your levels, streaks and achievements stay safely in the cloud — even when you switch phones.'**
  String get welcomeStep2Subtitle;

  /// No description provided for @welcomeStep2GoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get welcomeStep2GoogleSignIn;

  /// No description provided for @welcomeStep2GoogleSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get welcomeStep2GoogleSignedIn;

  /// No description provided for @welcomeStep2GoogleSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String welcomeStep2GoogleSignedInAs(String email);

  /// No description provided for @welcomeStep2Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Sync between your devices'**
  String get welcomeStep2Benefit1;

  /// No description provided for @welcomeStep2Benefit2.
  ///
  /// In en, this message translates to:
  /// **'Backed-up progress and achievements'**
  String get welcomeStep2Benefit2;

  /// No description provided for @welcomeStep2Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Works offline too'**
  String get welcomeStep2Benefit3;

  /// No description provided for @welcomeStep2Footnote.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to decide right now — it works without an account too.'**
  String get welcomeStep2Footnote;

  /// No description provided for @welcomeStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Connect your data'**
  String get welcomeStep3Title;

  /// No description provided for @welcomeStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Forgetrack reads steps, sleep and activity from Health Connect and turns them into XP. Your records never leave Health Connect — only read.'**
  String get welcomeStep3Subtitle;

  /// No description provided for @welcomeStep3DataSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get welcomeStep3DataSteps;

  /// No description provided for @welcomeStep3DataCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get welcomeStep3DataCalories;

  /// No description provided for @welcomeStep3DataSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get welcomeStep3DataSleep;

  /// No description provided for @welcomeStep3DataActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get welcomeStep3DataActivity;

  /// No description provided for @welcomeStep3Cta.
  ///
  /// In en, this message translates to:
  /// **'Allow Health Connect'**
  String get welcomeStep3Cta;

  /// No description provided for @welcomeStep3CtaConnected.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is connected'**
  String get welcomeStep3CtaConnected;

  /// No description provided for @welcomeStep3Privacy.
  ///
  /// In en, this message translates to:
  /// **'Your data stays inside Health Connect — Forgetrack never copies or modifies it.'**
  String get welcomeStep3Privacy;

  /// No description provided for @welcomeStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Final touches'**
  String get welcomeStep4Title;

  /// No description provided for @welcomeStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — you can set everything up later in the app.'**
  String get welcomeStep4Subtitle;

  /// No description provided for @welcomeStep4KtTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaloričke Tabulky'**
  String get welcomeStep4KtTitle;

  /// No description provided for @welcomeStep4KtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import nutrition and weight from your KT diary'**
  String get welcomeStep4KtSubtitle;

  /// No description provided for @welcomeStep4KtConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get welcomeStep4KtConnected;

  /// No description provided for @welcomeStep4NotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get welcomeStep4NotifTitle;

  /// No description provided for @welcomeStep4NotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quest reminders and reward alerts'**
  String get welcomeStep4NotifSubtitle;

  /// No description provided for @welcomeStep4QuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'FIRST QUESTS'**
  String get welcomeStep4QuestsLabel;

  /// No description provided for @welcomeKtSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaloričke Tabulky'**
  String get welcomeKtSheetTitle;

  /// No description provided for @welcomeKtSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your KT account'**
  String get welcomeKtSheetSubtitle;

  /// No description provided for @welcomeKtSheetEmailHint.
  ///
  /// In en, this message translates to:
  /// **'KT email'**
  String get welcomeKtSheetEmailHint;

  /// No description provided for @welcomeKtSheetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get welcomeKtSheetPasswordHint;

  /// No description provided for @welcomeKtSheetSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in and connect'**
  String get welcomeKtSheetSubmit;

  /// No description provided for @welcomeKtSheetFootnote.
  ///
  /// In en, this message translates to:
  /// **'Forgetrack uses your sign-in only to read the KT diary.'**
  String get welcomeKtSheetFootnote;
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
