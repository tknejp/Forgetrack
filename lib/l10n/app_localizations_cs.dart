// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Forgetrack';

  @override
  String get navOverview => 'Přehled';

  @override
  String get navActivities => 'Aktivity';

  @override
  String get navNutrition => 'Výživa';

  @override
  String get navBody => 'Tělo';

  @override
  String get screenProfile => 'Profil';

  @override
  String get screenActivities => 'Aktivity';

  @override
  String get screenNutrition => 'Výživa';

  @override
  String get screenBody => 'Tělo';

  @override
  String get periodDay => 'Den';

  @override
  String get periodWeek => 'Týden';

  @override
  String get periodMonth => 'Měsíc';

  @override
  String get periodCustomRangeSoon => 'Vlastní rozsah bude brzy k dispozici';

  @override
  String get caloriesAvgPerDay => 'Průměr / den';

  @override
  String get sleepAverage => 'Průměr';

  @override
  String get stepsTitle => 'Kroky';

  @override
  String get stepsToday => 'Dnes';

  @override
  String get stepsCurrent => 'Aktuálně';

  @override
  String get stepsGoal => 'Cíl';

  @override
  String get stepsRemaining => 'Zbývá';

  @override
  String get stepsAverage => 'Průměr';

  @override
  String stepsAvgPerDay(String value) {
    return '$value / den';
  }

  @override
  String get stepsCompleted => 'Splněno';

  @override
  String get stepsYes => 'Ano';

  @override
  String get stepsNo => 'Ne';

  @override
  String get stepsBestDay => 'Nejlepší den';

  @override
  String get stepsMaxSteps => 'Max kroků';

  @override
  String get caloriesTodayTitle => 'Kalorie dnes';

  @override
  String get caloriesConsumed => 'Přijato';

  @override
  String get caloriesBurned => 'Spáleno';

  @override
  String get caloriesRemaining => 'Zbývá';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroFat => 'Tuk';

  @override
  String get macroCarbs => 'Sacharidy';

  @override
  String get macroFiber => 'Vláknina';

  @override
  String get weightTitle => 'Váha';

  @override
  String get weightGoal => 'Cíl';

  @override
  String get weightAverage => 'Průměr';

  @override
  String get weightMin => 'Min';

  @override
  String get weightMax => 'Max';

  @override
  String get weightBodyFat => 'Tělesný tuk';

  @override
  String get weightLeanMass => 'Svalová hmota';

  @override
  String get weightFatMass => 'Tuková hmota';

  @override
  String get weightMainLabelDay => 'Váha';

  @override
  String get weightVsPrevMeasure => 'Oproti minule';

  @override
  String get weightVsPrevWeek => 'Vs min. týden';

  @override
  String get weightVsPrevMonth => 'Vs min. měsíc';

  @override
  String get weightNoMeasurement => 'Bez záznamu';

  @override
  String get profileExportToSheets => 'Exportovat do Sheets';

  @override
  String get profileSignOut => 'Odhlásit se';

  @override
  String get emptyNoData => 'Zatím žádná data';

  @override
  String get settingsSection => 'Nastavení';

  @override
  String get settingsLanguage => 'Jazyk';

  @override
  String get languageSystemDefault => 'Výchozí systémový';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageCzech => 'Čeština';

  @override
  String get profileNotSignedIn => 'Nepřihlášen';

  @override
  String get profileSignInBenefit =>
      'Synchronizujte tréninky, kalorie a pokrok napříč zařízeními';

  @override
  String get profileContinueWithGoogle => 'Pokračovat s Googlem';

  @override
  String get profileConnectedGoogle => 'Připojeno přes Google';

  @override
  String get profileSignOutConfirmTitle => 'Odhlásit se?';

  @override
  String get profileSignOutConfirmMessage =>
      'Pro synchronizaci dat se budete muset znovu přihlásit.';

  @override
  String get dialogCancel => 'Zrušit';

  @override
  String get sectionPreferences => 'Předvolby';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionAbout => 'O aplikaci';

  @override
  String get sectionAccount => 'Účet';

  @override
  String get settingsTheme => 'Motiv';

  @override
  String get settingsTimeTheme => 'Dynamický motiv dle času';

  @override
  String get settingsTimeThemeDesc =>
      'Přizpůsobuje vzhled aplikace podle aktuální denní doby.';

  @override
  String get themeSystem => 'Systémový';

  @override
  String get themeLight => 'Světlý';

  @override
  String get themeDark => 'Tmavý';

  @override
  String get themeDynamic => 'Dynamický';

  @override
  String get settingsAppVersion => 'Verze aplikace';

  @override
  String get settingsPrivacy => 'Zásady ochrany osobních údajů';

  @override
  String get settingsTerms => 'Podmínky použití';

  @override
  String get settingsFeedback => 'Odeslat zpětnou vazbu';

  @override
  String get settingsClearCache => 'Vymazat lokální data';

  @override
  String get healthNotAvailable => 'Health Connect není k dispozici';

  @override
  String get healthNotAvailableBody =>
      'Nainstalujte aplikaci Health Connect pro sledování kroků, váhy a aktivit.';

  @override
  String get healthInstall => 'Nainstalovat';

  @override
  String get healthPermissionRequired => 'Potřebné oprávnění';

  @override
  String get healthPermissionBody =>
      'Udělte Forgetracku přístup k Health Connect pro zobrazení vašich dat.';

  @override
  String get healthGrantAccess => 'Udělit přístup';

  @override
  String get healthSyncFailed => 'Nepodařilo se načíst zdravotní data';

  @override
  String get healthRetry => 'Zkusit znovu';

  @override
  String healthLastSynced(String time) {
    return 'Synchronizováno: $time';
  }

  @override
  String get ktSectionTitle => 'Synchronizace výživy';

  @override
  String get ktConnectBody =>
      'Připojte se na kaloricketabulky.cz pro automatickou synchronizaci denních nutričních dat.';

  @override
  String get ktEmailHint => 'E-mail';

  @override
  String get ktPasswordHint => 'Heslo';

  @override
  String get ktLoginButton => 'Připojit';

  @override
  String get ktLoggingIn => 'Připojování…';

  @override
  String get ktConnectedBadge => 'Připojeno na kaloricketabulky.cz';

  @override
  String get ktDisconnectButton => 'Odpojit';

  @override
  String get ktDisconnectConfirmTitle => 'Odpojit Kalorické Tabulky?';

  @override
  String get ktDisconnectConfirmMessage =>
      'Vaše nutriční data již nebudou synchronizována z Kalorických Tabulek.';

  @override
  String get ktAuthError => 'Nesprávný e-mail nebo heslo';

  @override
  String get ktSyncError => 'Nepodařilo se synchronizovat nutriční data';

  @override
  String get ktRetry => 'Zkusit znovu';

  @override
  String ktSyncedAt(String time) {
    return 'Synchronizováno: $time';
  }

  @override
  String get ktLoginPrompt =>
      'Připojte Kalorické Tabulky v Nastaveních pro zobrazení nutričních dat.';

  @override
  String get ktGoToSettings => 'Přejít do Nastavení';

  @override
  String get ktNoDiaryData => 'Dnes žádné záznamy v deníku';

  @override
  String get ktNutritionTitle => 'Dnešní výživa';

  @override
  String get sleepTitle => 'Spánek';

  @override
  String get sleepDuration => 'Délka';

  @override
  String get sleepFellAsleep => 'Usnutí';

  @override
  String get sleepWokeUp => 'Probuzení';

  @override
  String get sleepNoData => 'Žádná data o spánku';

  @override
  String get activitiesWeekTotal => 'Tento týden';

  @override
  String get activitiesMonthTotal => 'Tento měsíc';

  @override
  String get activitiesActiveCalories => 'Aktivní kalorie';

  @override
  String get activitiesActiveMins => 'Aktivní min.';

  @override
  String get activitiesWorkouts => 'Tréninky';

  @override
  String get activitiesNoWorkouts => 'Žádné tréninky za posledních 30 dní';

  @override
  String get activitiesRecentActivity => 'Poslední tréninky';

  @override
  String get activitiesDailyAvg => 'Denní průměr';

  @override
  String get activitiesWeeklyAvg => 'Týdenní průměr';

  @override
  String get activitiesWeeklyTrend => '7denní trend';

  @override
  String get activitiesAvgDuration => 'Prům. délka';

  @override
  String get activitiesWorkoutPermissionTitle => 'Potřebný přístup k tréninkům';

  @override
  String get activitiesWorkoutPermissionBody =>
      'Udělte aplikaci Forgetrack přístup k tréninkům v Health Connect pro zobrazení aktivit a statistik.';

  @override
  String get sleepAvg7Day => 'Prům. 7 dní';

  @override
  String get bodyCurrentWeight => 'Aktuální';

  @override
  String get body30DayChange => 'Změna za 30 dní';

  @override
  String get bodyWeightTrend => 'Vývoj váhy';

  @override
  String get bodyComposition => 'Složení těla';

  @override
  String get bodyNoData => 'Žádné záznamy váhy';

  @override
  String get bodyProgressToGoal => 'Postup k cíli';

  @override
  String bodyToGo(String value) {
    return 'Zbývá $value kg';
  }

  @override
  String get bodyAtGoal => 'Cíl splněn!';

  @override
  String get sectionGoals => 'Cíle';

  @override
  String get goalDailySteps => 'Denní kroky';

  @override
  String get goalTargetWeight => 'Cílová váha';

  @override
  String get goalDailyCalories => 'Denní kalorie';

  @override
  String get goalDailyProtein => 'Denní bílkoviny';

  @override
  String get goalSleepHours => 'Spánek';

  @override
  String get goalWeeklyActivity => 'Týdenní aktivita';

  @override
  String get goalUnitSteps => 'kroků';

  @override
  String get goalUnitKcal => 'kcal';

  @override
  String get goalUnitG => 'g';

  @override
  String get goalUnitHours => 'hodin';

  @override
  String get goalUnitMins => 'min';

  @override
  String get goalEditTitle => 'Nastavit cíl';

  @override
  String get goalSave => 'Uložit';

  @override
  String get headerToday => 'Dnes';

  @override
  String get macroSugar => 'Cukry';

  @override
  String get macroSalt => 'Sůl';

  @override
  String get macroSaturatedFat => 'Nas. tuky';

  @override
  String get goalDailyFat => 'Denní tuky';

  @override
  String get goalDailyCarbs => 'Denní sacharidy';

  @override
  String get nutritionPeriod7d => '7 dní';

  @override
  String get nutritionPeriod30d => '30 dní';

  @override
  String get nutritionGoalsTitle => 'Upravit cíle';

  @override
  String get nutritionNoHistoryData => 'Pro toto období nejsou dostupná data';
}
