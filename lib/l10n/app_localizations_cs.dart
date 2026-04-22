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

  @override
  String get exportScreenTitle => 'Export do Google Sheets';

  @override
  String get exportSignInTitle => 'Přihlásit se přes Google';

  @override
  String get exportSignInBody =>
      'Export do Sheets potřebuje váš účet Google pro zápis do tabulky. Pro pokračování se přihlaste.';

  @override
  String get exportSignInButton => 'Přihlásit se';

  @override
  String get exportSignInLoading => 'Přihlašování…';

  @override
  String get exportTargetLabel => 'Cílová tabulka';

  @override
  String get exportTargetMissingBody =>
      'Žádná tabulka zatím není propojená. Při prvním exportu se vytvoří nová tabulka „Forgetrack Data\" ve vašem Google Drive.';

  @override
  String get exportTargetCopyLink => 'Kopírovat odkaz';

  @override
  String get exportTargetLinkCopied => 'Odkaz na tabulku zkopírován';

  @override
  String get exportTargetForgetButton => 'Zapomenout odkaz';

  @override
  String get exportTargetForgetConfirmTitle => 'Zapomenout propojenou tabulku?';

  @override
  String get exportTargetForgetConfirmMessage =>
      'Tímto se pouze odstraní propojení v aplikaci Forgetrack. Samotná tabulka ve vašem Google Drive zůstane.';

  @override
  String get exportTargetForgetConfirmAction => 'Zapomenout';

  @override
  String get exportRangeLabel => 'Rozsah dat';

  @override
  String exportRangeDayCount(int count) {
    return '$count dní';
  }

  @override
  String get exportRangePickButton => 'Vybrat rozsah';

  @override
  String get exportRangeInvalid =>
      'Koncové datum musí být stejné nebo pozdější než počáteční.';

  @override
  String get exportRangePresetLast7 => 'Posl. 7 d';

  @override
  String get exportRangePresetLast30 => 'Posl. 30 d';

  @override
  String get exportRangePresetThisMonth => 'Tento měsíc';

  @override
  String get exportRangePresetLastMonth => 'Minulý měsíc';

  @override
  String get exportFieldsLabel => 'Pole k exportu';

  @override
  String get exportFieldsSelectAll => 'Vše';

  @override
  String get exportFieldsSelectNone => 'Žádné';

  @override
  String get exportCategoryActivity => 'Aktivita';

  @override
  String get exportCategoryBody => 'Tělo';

  @override
  String get exportCategorySleep => 'Spánek';

  @override
  String get exportCategoryNutrition => 'Výživa';

  @override
  String get exportButton => 'Exportovat do Sheets';

  @override
  String get exportButtonRunning => 'Exportuje se…';

  @override
  String exportSummary(int days, int fields, String range) {
    return '$days dní · $fields polí · $range';
  }

  @override
  String exportExplainer(String today) {
    return 'Řádky se slučují podle data – existující data se aktualizují, nová se doplní. Dnes je $today.';
  }

  @override
  String get exportSuccessTitle => 'Export dokončen';

  @override
  String exportSuccessDetail(int rows, int added, int updated) {
    return 'Zapsáno $rows řádků – +$added přidáno, $updated aktualizováno.';
  }

  @override
  String get exportErrorTitle => 'Export selhal';

  @override
  String get exportErrorGeneric => 'Neznámá chyba.';

  @override
  String get exportErrorNotSignedIn =>
      'Nejste přihlášen/a ke Googlu. Přihlaste se pro povolení exportu do Sheets.';

  @override
  String get exportErrorNoFields => 'Vyberte alespoň jedno pole k exportu.';

  @override
  String get exportErrorInvalidRange =>
      'Neplatný rozsah: koncové datum je před počátečním.';

  @override
  String exportErrorPrefix(String message) {
    return 'Export selhal: $message';
  }

  @override
  String get exportFieldSteps => 'Kroky';

  @override
  String get exportFieldActiveCalories => 'Aktivní kalorie';

  @override
  String get exportFieldActiveCaloriesDesc =>
      'Kalorie spálené aktivitou (kcal).';

  @override
  String get exportFieldWeight => 'Váha';

  @override
  String get exportFieldWeightDesc =>
      'Poslední váha zaznamenaná v daný den (kg).';

  @override
  String get exportFieldBodyFat => 'Tělesný tuk';

  @override
  String get exportFieldBodyFatDesc =>
      'Procento tělesného tuku zaznamenané v daný den.';

  @override
  String get exportFieldSleepDuration => 'Délka spánku';

  @override
  String get exportFieldSleepDurationDesc =>
      'Celkový spánek v noci končící tímto datem (minuty).';

  @override
  String get exportFieldSleepBedtime => 'Usnutí';

  @override
  String get exportFieldSleepWake => 'Probuzení';

  @override
  String get exportFieldKcalIn => 'Příjem kalorií';

  @override
  String get exportFieldKcalInDesc =>
      'Kalorie zaznamenané v Kalorických tabulkách (kcal).';

  @override
  String get exportFieldProtein => 'Bílkoviny';

  @override
  String get exportFieldFat => 'Tuky';

  @override
  String get exportFieldCarbs => 'Sacharidy';

  @override
  String get exportFieldFiber => 'Vláknina';

  @override
  String get exportFieldSugar => 'Cukry';

  @override
  String get exportFieldSalt => 'Sůl';

  @override
  String get exportFieldSaturatedFat => 'Nasycené tuky';

  @override
  String get exportHeaderDate => 'Datum';

  @override
  String get exportHeaderSteps => 'Kroky';

  @override
  String get exportHeaderActiveCalories => 'Aktivní kalorie (kcal)';

  @override
  String get exportHeaderWeight => 'Váha (kg)';

  @override
  String get exportHeaderBodyFat => 'Tělesný tuk (%)';

  @override
  String get exportHeaderSleepDuration => 'Spánek (min)';

  @override
  String get exportHeaderSleepBedtime => 'Usnutí';

  @override
  String get exportHeaderSleepWake => 'Probuzení';

  @override
  String get exportHeaderKcalIn => 'Příjem kalorií (kcal)';

  @override
  String get exportHeaderProtein => 'Bílkoviny (g)';

  @override
  String get exportHeaderFat => 'Tuky (g)';

  @override
  String get exportHeaderCarbs => 'Sacharidy (g)';

  @override
  String get exportHeaderFiber => 'Vláknina (g)';

  @override
  String get exportHeaderSugar => 'Cukry (g)';

  @override
  String get exportHeaderSalt => 'Sůl (g)';

  @override
  String get exportHeaderSaturatedFat => 'Nasycené tuky (g)';

  @override
  String get progScreenEyebrow => 'PROGRESSION PROFIL';

  @override
  String get progScreenTitle => 'Tvá dlouhodobá cesta';

  @override
  String get progScreenLoadingHint => 'Připravujeme tvou legendu';

  @override
  String get progScreenEntryTitle => 'Progression profil';

  @override
  String progScreenEntrySubtitle(String levelTitle, int totalXp, int unlocked) {
    return '$levelTitle · $totalXp XP · $unlocked odznaků';
  }

  @override
  String get progOpenCta => 'Otevřít progression profil';

  @override
  String get progBadgeTotalXp => 'CELKEM XP';

  @override
  String progBadgeLevel(int level, String title) {
    return 'LEVEL $level · $title';
  }

  @override
  String progBadgeStreak(int count) {
    return '$count série';
  }

  @override
  String get progBadgeStreakEmpty => 'Žádná aktivní série';

  @override
  String get progBadgeStreakHint => 'Odstartuj svou první sérii';

  @override
  String progBadgeUnlocked(int count) {
    return '$count odemčeno';
  }

  @override
  String get progBadgeAchievements => 'Úspěchy';

  @override
  String progBadgePendingClaims(int count) {
    return '$count k vyzvednutí';
  }

  @override
  String progBadgeXpRange(int current, int max) {
    return '$current / $max XP';
  }

  @override
  String progLastSynced(String time) {
    return 'Naposled synchronizováno $time';
  }

  @override
  String get progStreakSectionLabel => 'Série';

  @override
  String get progStreakSectionCaption =>
      'Aktuální a nejlepší série napříč doménami.';

  @override
  String get progStreakCurrentLabel => 'AKTUÁLNÍ SÉRIE';

  @override
  String get progStreakBestLabel => 'NEJLEPŠÍ SÉRIE';

  @override
  String get progStreakDaysSuffix => 'dní';

  @override
  String get progActiveQuestsLabel => 'Aktivní questy';

  @override
  String progShowAllCount(int count) {
    return 'Zobrazit vše ($count) →';
  }

  @override
  String get progMiniStatTotalXp => 'Celkem XP';

  @override
  String get progMiniStatToNext => 'Do dalšího';

  @override
  String get progMiniStatAchievements => 'Úspěchy';

  @override
  String get progMiniStatQuests => 'Questy';

  @override
  String get progSummarySectionLabel => 'Přehled postupu';

  @override
  String get progSummaryCurrentStreak => 'Aktuální série';

  @override
  String get progSummaryBestStreak => 'Nejlepší série';

  @override
  String get progSummaryCompletedQuests => 'Dokončené questy';

  @override
  String get progSummaryAchievements => 'Úspěchy';

  @override
  String get progSummaryNoActiveChain => 'Zatím žádný řetězec';

  @override
  String get progSummaryBuildConsistency => 'Vybuduj konzistenci';

  @override
  String get progQuestsSectionLabel => 'Questy';

  @override
  String get progQuestsSectionCaption =>
      'Aktivní questy nahoře, dokončené níže.';

  @override
  String get progQuestsActiveHeader => 'AKTIVNÍ QUESTY';

  @override
  String get progQuestsCompletedHeader => 'DOKONČENÉ QUESTY';

  @override
  String get progQuestsEmptyActiveTitle => 'Žádné aktivní questy.';

  @override
  String get progQuestsEmptyActiveCaption =>
      'Prošel jsi aktuální katalog questů.';

  @override
  String get progQuestsEmptyCompletedTitle => 'Zatím žádné dokončené questy.';

  @override
  String get progQuestsEmptyCompletedCaption =>
      'Tvé dokončené milníky se objeví tady.';

  @override
  String get progQuestStatusActive => 'Aktivní';

  @override
  String get progQuestStatusCompleted => 'Dokončeno';

  @override
  String progQuestCompletedOn(String time) {
    return 'Dokončeno $time';
  }

  @override
  String progProgressRatio(int current, int target) {
    return '$current / $target';
  }

  @override
  String progPercent(int value) {
    return '$value %';
  }

  @override
  String get progAchievementsSectionLabel => 'Úspěchy';

  @override
  String get progAchievementsSectionCaption =>
      'Odemčené odznaky a aktuální postup.';

  @override
  String get progAchievementsUnlockedHeader => 'ODEMČENO';

  @override
  String get progAchievementsInProgressHeader => 'V PRŮBĚHU';

  @override
  String get progAchievementsEmptyUnlockedTitle =>
      'Zatím žádný odemčený úspěch.';

  @override
  String get progAchievementsEmptyUnlockedCaption =>
      'Získané odznaky se tu rozsvítí.';

  @override
  String get progAchievementsEmptyInProgressTitle =>
      'Vše v aktuálním katalogu je odemčeno.';

  @override
  String get progAchievementsEmptyInProgressCaption =>
      'Další úspěchy rozšíří tvou cestu.';

  @override
  String get progAchievementStatusUnlocked => 'Odemčeno';

  @override
  String get progAchievementStatusInProgress => 'V průběhu';

  @override
  String get progRewardsSectionLabel => 'Nedávné odměny';

  @override
  String get progRewardsSectionCaption =>
      'Poslední získaná XP napříč doménami.';

  @override
  String get progRewardsPendingTitle => 'Odměny k vyzvednutí';

  @override
  String get progRewardsPendingCaption =>
      'Odměny vázané na cíl se odemknou po uzavření dne nebo týdne. Vyzvednutím se XP připíše do tvého profilu.';

  @override
  String get progRewardsClaimAll => 'Vyzvednout vše';

  @override
  String get progRewardsClaim => 'Vyzvednout';

  @override
  String progRewardsUnlockedAt(String time) {
    return 'Odemčeno $time';
  }

  @override
  String progRewardDetail(String target, String unit, String actual) {
    return 'Cíl $target $unit | Skutečnost $actual $unit';
  }

  @override
  String get progRewardsEmptyTitle => 'Zatím žádné odměny.';

  @override
  String get progRewardsEmptyCaption => 'Dokončené cíle naplní tvůj deník.';

  @override
  String progRewardSubtitle(String domain, int xp) {
    return '$domain · +$xp XP';
  }

  @override
  String get progDomainSteps => 'Kroky';

  @override
  String get progDomainNutrition => 'Výživa';

  @override
  String get progDomainSleep => 'Spánek';

  @override
  String get progDomainActivity => 'Aktivita';

  @override
  String get progRuleDailySteps => 'Denní kroky';

  @override
  String get progRuleDailyCalories => 'Kalorický cíl';

  @override
  String get progRuleDailyProtein => 'Cíl bílkovin';

  @override
  String get progRuleDailySleep => 'Cíl spánku';

  @override
  String get progRuleWeeklyActivity => 'Týdenní aktivita';

  @override
  String get progQuestEarnFirstRewardTitle => 'Získej první odměnu';

  @override
  String get progQuestEarnFirstRewardDesc =>
      'Získej svou první progression odměnu.';

  @override
  String get progQuestDailyTwoGoalsTodayTitle => 'Dvojité vítězství';

  @override
  String get progQuestDailyTwoGoalsTodayDesc =>
      'Splň v aktuálním dni libovolné 2 denní cíle.';

  @override
  String get progQuestDailyTripleWinTodayTitle => 'Trojité vítězství';

  @override
  String get progQuestDailyTripleWinTodayDesc =>
      'Splň v aktuálním dni libovolné 3 denní cíle.';

  @override
  String get progQuestDailyFourPillarsTodayTitle => 'Čtyři pilíře';

  @override
  String get progQuestDailyFourPillarsTodayDesc =>
      'Splň v aktuálním dni všechny 4 denní cíle.';

  @override
  String get progQuestDailyNutritionComboTodayTitle => 'Nutriční kombo';

  @override
  String get progQuestDailyNutritionComboTodayDesc =>
      'Splň v aktuálním dni kalorický i proteinový cíl.';

  @override
  String get progQuestDailyRecoveryFocusTodayTitle => 'Regenerační fokus';

  @override
  String get progQuestDailyRecoveryFocusTodayDesc =>
      'Splň v aktuálním dni cíl kroků i spánku.';

  @override
  String get progQuestDailyStepsTodayTitle => 'Dnešní cíl kroků';

  @override
  String get progQuestDailyStepsTodayDesc =>
      'Splň denní pravidlo kroků v aktuálním dni.';

  @override
  String get progQuestDailyCaloriesTodayTitle => 'Dnešní kalorický cíl';

  @override
  String get progQuestDailyCaloriesTodayDesc =>
      'Splň denní kalorický cíl v aktuálním dni.';

  @override
  String get progQuestDailyProteinTodayTitle => 'Dnešní cíl bílkovin';

  @override
  String get progQuestDailyProteinTodayDesc =>
      'Splň denní pravidlo bílkovin v aktuálním dni.';

  @override
  String get progQuestDailySleepTodayTitle => 'Dnešní cíl spánku';

  @override
  String get progQuestDailySleepTodayDesc =>
      'Splň denní pravidlo spánku v aktuálním dni.';

  @override
  String get progQuestReach500XpTitle => 'Dosáhni 500 XP';

  @override
  String get progQuestReach500XpDesc => 'Nasbírej alespoň 500 XP.';

  @override
  String get progQuestReach2000XpTitle => 'Dosáhni 2 000 XP';

  @override
  String get progQuestReach2000XpDesc => 'Nasbírej alespoň 2 000 XP.';

  @override
  String get progQuestReach5000XpTitle => 'Dosáhni 5 000 XP';

  @override
  String get progQuestReach5000XpDesc => 'Nasbírej alespoň 5 000 XP.';

  @override
  String get progQuestEarn25RewardsTitle => 'Získej 25 odměn';

  @override
  String get progQuestEarn25RewardsDesc =>
      'Nasbírej celkem 25 progression odměn.';

  @override
  String get progQuestEarn100RewardsTitle => 'Získej 100 odměn';

  @override
  String get progQuestEarn100RewardsDesc =>
      'Nasbírej celkem 100 progression odměn.';

  @override
  String get progQuestStepsStreak3Title => 'Série kroků';

  @override
  String get progQuestStepsStreak3Desc => 'Splň denní cíl kroků 3 dny v řadě.';

  @override
  String get progQuestNutritionRewards5Title => 'Rytmus výživy';

  @override
  String get progQuestNutritionRewards5Desc => 'Získej 5 odměn za výživu.';

  @override
  String get progQuestNutritionRewards25Title => 'Mistrovství výživy';

  @override
  String get progQuestNutritionRewards25Desc => 'Získej 25 odměn za výživu.';

  @override
  String get progQuestTotalSteps100kTitle => 'Ujdi 100 tisíc kroků';

  @override
  String get progQuestTotalSteps100kDesc => 'Nasbírej celkem 100 000 kroků.';

  @override
  String get progQuestTotalSteps500kTitle => 'Ujdi 500 tisíc kroků';

  @override
  String get progQuestTotalSteps500kDesc => 'Nasbírej celkem 500 000 kroků.';

  @override
  String get progQuestWeeklyActivityOnceTitle => 'Týdenní aktivita';

  @override
  String get progQuestWeeklyActivityOnceDesc =>
      'Splň týdenní cíl aktivity alespoň jednou.';

  @override
  String get progQuestWeeklyActivity4Title => 'Týdenní tempo aktivity';

  @override
  String get progQuestWeeklyActivity4Desc =>
      'Splň týdenní cíl aktivity čtyřikrát.';

  @override
  String get progQuestWeeklyActivity12Title => 'Legenda týdenní aktivity';

  @override
  String get progQuestWeeklyActivity12Desc =>
      'Splň týdenní cíl aktivity dvanáctkrát.';

  @override
  String get progQuestUnlockStepChainTitle => 'Odemkni Řetěz kroků';

  @override
  String get progQuestUnlockStepChainDesc => 'Odemkni úspěch Řetěz kroků.';

  @override
  String get progQuestStepsStreak7Title => 'Disciplína kroků';

  @override
  String get progQuestStepsStreak7Desc => 'Splň denní cíl kroků 7 dní v řadě.';

  @override
  String get progQuestStepsStreak14Title => 'Strážce kroků';

  @override
  String get progQuestStepsStreak14Desc =>
      'Splň denní cíl kroků 14 dní v řadě.';

  @override
  String get progAchievementFirstRewardTitle => 'První odměna';

  @override
  String get progAchievementFirstRewardDesc =>
      'Získej svou první progression odměnu.';

  @override
  String get progAchievementRewardHunter25Title => 'Lovec odměn';

  @override
  String get progAchievementRewardHunter25Desc =>
      'Získej 25 progression odměn.';

  @override
  String get progAchievementRewardHunter100Title => 'Legenda odměn';

  @override
  String get progAchievementRewardHunter100Desc =>
      'Získej 100 progression odměn.';

  @override
  String get progAchievementPathfinderTitle => 'Stopař';

  @override
  String get progAchievementPathfinderDesc => 'Dosáhni levelu 5 získaným XP.';

  @override
  String get progAchievementForgeKnight5000Title => 'Rytíř kovárny';

  @override
  String get progAchievementForgeKnight5000Desc => 'Nasbírej 5 000 XP.';

  @override
  String get progAchievementLivingLegend15000Title => 'Živá legenda';

  @override
  String get progAchievementLivingLegend15000Desc => 'Nasbírej 15 000 XP.';

  @override
  String get progAchievementSteps100kTitle => 'Stotisícový chodec';

  @override
  String get progAchievementSteps100kDesc => 'Nasbírej celkem 100 000 kroků.';

  @override
  String get progAchievementSteps500kTitle => 'Pochod půl milionu';

  @override
  String get progAchievementSteps500kDesc => 'Nasbírej celkem 500 000 kroků.';

  @override
  String get progAchievementSteps1000000Title => 'Mýtus milionu kroků';

  @override
  String get progAchievementSteps1000000Desc =>
      'Nasbírej celkem 1 000 000 kroků.';

  @override
  String get progAchievementStepChainTitle => 'Řetěz kroků';

  @override
  String get progAchievementStepChainDesc =>
      'Splň denní cíl kroků 3 dny v řadě.';

  @override
  String get progAchievementStepDisciplineTitle => 'Disciplína kroků';

  @override
  String get progAchievementStepDisciplineDesc =>
      'Splň denní cíl kroků 7 dní v řadě.';

  @override
  String get progAchievementStepSovereignTitle => 'Vládce kroků';

  @override
  String get progAchievementStepSovereignDesc =>
      'Splň denní cíl kroků 30 dní v řadě.';

  @override
  String get progAchievementBalancedRhythmTitle => 'Vyvážený rytmus';

  @override
  String get progAchievementBalancedRhythmDesc =>
      'Získej alespoň jednu odměnu za výživu 3 dny v řadě.';

  @override
  String get progAchievementNutritionRewards25Title => 'Mistr maker';

  @override
  String get progAchievementNutritionRewards25Desc =>
      'Získej 25 odměn za výživu.';

  @override
  String get progAchievementWeeklyWarriorTitle => 'Týdenní válečník';

  @override
  String get progAchievementWeeklyWarriorDesc =>
      'Splň týdenní cíl aktivity alespoň jednou.';

  @override
  String get progAchievementWeeklyActivity4Title => 'Předvoj aktivity';

  @override
  String get progAchievementWeeklyActivity4Desc =>
      'Splň týdenní cíl aktivity čtyřikrát.';

  @override
  String get progAchievementWeeklyActivity12Title => 'Ostřílený hýbač';

  @override
  String get progAchievementWeeklyActivity12Desc =>
      'Splň týdenní cíl aktivity dvanáctkrát.';

  @override
  String get progQuestCriterionTotalXp => 'Podle celkového XP';

  @override
  String progQuestCriterionRewardCountWithRule(String rule) {
    return 'Podle: $rule';
  }

  @override
  String get progQuestCriterionRewardCount => 'Podle počtu odměn';

  @override
  String progQuestCriterionStreakWithRule(String rule) {
    return 'Podle série: $rule';
  }

  @override
  String progQuestCriterionStreakWithDomain(String domain) {
    return 'Podle série: $domain';
  }

  @override
  String get progQuestCriterionStreakGeneric => 'Podle konzistence série';

  @override
  String progQuestCriterionTotalRuleValueWithRule(String rule) {
    return 'Podle celkového součtu: $rule';
  }

  @override
  String get progQuestCriterionTotalRuleValueGeneric =>
      'Podle nasbíraného součtu';

  @override
  String progQuestCriterionCurrentPeriodRule(String rule) {
    return 'Pro aktuální období: $rule';
  }

  @override
  String get progQuestCriterionCurrentPeriodGeneric => 'Pro aktuální období';

  @override
  String get progQuestCriterionCurrentPeriodRuleSet =>
      'Pro combo v aktuálním období';

  @override
  String get progQuestCriterionAchievement => 'Podle odemčení úspěchu';

  @override
  String progQuestCriterionCompletionsWithRule(String rule) {
    return 'Podle dokončení: $rule';
  }

  @override
  String get progQuestCriterionCompletionsGeneric => 'Podle dokončení pravidel';

  @override
  String progQuestCriterionDomainRewardsWithDomain(String domain) {
    return 'Podle odměn: $domain';
  }

  @override
  String get progQuestCriterionDomainRewardsGeneric => 'Podle odměn v doméně';
}
