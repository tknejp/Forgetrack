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
  String get navQuests => 'Questy';

  @override
  String get navHero => 'Hero';

  @override
  String get navSocial => 'Social';

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
  String get settingsNotifications => 'Notifikace';

  @override
  String get settingsNotificationsSubtitle =>
      'Povolit připomínky, questy a social upozornění.';

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
  String get authSigningIn => 'Přihlašování...';

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
  String get homeOpenDetailCta => 'Otevřít detail';

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
  String get weightProgressExplanation =>
      'Procento ukazuje postup k cíli na základě zaznamenané historie váhy.';

  @override
  String get weightProgressExplanationLoss =>
      'Procento ukazuje postup od nejvyšší zaznamenané váhy k cíli, ne poměr aktuální váhy vůči cíli.';

  @override
  String get weightProgressExplanationGain =>
      'Procento ukazuje postup od nejnižší zaznamenané váhy k cíli, ne poměr aktuální váhy vůči cíli.';

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
  String get goalUnitKg => 'kg';

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
  String get exportAuthorizationNote =>
      'Při exportu si aplikace může vyžádat oprávnění pro Google Sheets.';

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
  String get progScreenEyebrow => 'HERO PROFIL';

  @override
  String get progScreenTitle => 'Tvoje hero cesta';

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
  String get progMiniStatToNext => 'Do dalšího levelu';

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
  String get questsScreenEyebrow => 'QUESTY';

  @override
  String get questsScreenTitle => 'Tvoje questy a odměny';

  @override
  String get progQuestsActiveHeader => 'AKTIVNÍ QUESTY';

  @override
  String progQuestsActiveCount(int count) {
    return '$count aktivních';
  }

  @override
  String get progQuestsLockedHeader => 'ZAMČENÉ QUESTY';

  @override
  String get progQuestsCompletedHeader => 'DOKONČENÉ QUESTY';

  @override
  String progQuestsCompletedCount(int count) {
    return '$count dokončených';
  }

  @override
  String get progQuestsEmptyActiveTitle => 'Žádné aktivní questy.';

  @override
  String get progQuestsEmptyActiveCaption =>
      'Prošel jsi aktuální katalog questů.';

  @override
  String get progQuestsEmptyLockedTitle =>
      'Teď tu nejsou žádné zamčené questy.';

  @override
  String get progQuestsEmptyLockedCaption =>
      'Další gated questy se objeví tady, až bude co odemykat.';

  @override
  String get progQuestsEmptyCompletedTitle => 'Zatím žádné dokončené questy.';

  @override
  String get progQuestsEmptyCompletedCaption =>
      'Tvé dokončené milníky se objeví tady.';

  @override
  String get progQuestStatusActive => 'Aktivní';

  @override
  String get progQuestStatusLocked => 'Zamčeno';

  @override
  String get progQuestStatusClaimed => 'Vyzvednuto';

  @override
  String get progQuestStatusCompleted => 'Dokončeno';

  @override
  String get progQuestClaimAll => 'Vyzvednout questy';

  @override
  String get progQuestClaim => 'Vyzvednout quest';

  @override
  String progQuestCompletedOn(String time) {
    return 'Dokončeno $time';
  }

  @override
  String get progQuestDetailRewards => 'Odměny';

  @override
  String get progQuestDetailUnlocksNext => 'Odemkne dál';

  @override
  String get progQuestDetailLockedBecause => 'Zamčeno kvůli';

  @override
  String progQuestDetailRequiresLevel(int level) {
    return 'Vyžaduje level $level';
  }

  @override
  String progQuestDetailTrackDays(int days) {
    return 'Trackuj $days dní';
  }

  @override
  String progQuestDetailCompleteQuest(String quest) {
    return 'Dokonči $quest';
  }

  @override
  String get progQuestDetailRelatedGoals => 'Související cíle';

  @override
  String get progQuestDetailTapForDetails => 'Klepni pro detail';

  @override
  String get progQuestDetailHiddenUntilUnlocked => 'Skryto do odemčení';

  @override
  String get progQuestDetailHiddenReward => 'Skryto';

  @override
  String get progQuestDetailNoFollowUp => 'Zatím bez navazujícího questu';

  @override
  String get progQuestDetailGoal => 'Cíl';

  @override
  String get progQuestDetailNextInChain => 'Další v řadě';

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
  String get progRuleDailyCarbs => 'Cíl sacharidů';

  @override
  String get progRuleDailyFat => 'Cíl tuků';

  @override
  String get progRuleDailyFiber => 'Cíl vlákniny';

  @override
  String get progRuleDailySleep => 'Cíl spánku';

  @override
  String get progRuleWeeklyActivity => 'Týdenní aktivita';

  @override
  String get progRuleDailyWeightLog => 'Záznam váhy';

  @override
  String get progRuleDailyWeightGoal => 'Cílová váha';

  @override
  String progRewardDetailWeightLogged(String actual) {
    return 'Zaznamenáno: $actual kg';
  }

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
  String get progQuestComboInitiate10Title => 'Kombo zasvěcenec';

  @override
  String get progQuestComboInitiate10Desc =>
      'Splň 10 kombo questů libovolného typu.';

  @override
  String get progQuestDailyNutritionComboTodayTitle => 'Nutriční kombo';

  @override
  String get progQuestDailyNutritionComboTodayDesc =>
      'Splň v aktuálním dni kalorický i proteinový cíl.';

  @override
  String get progQuestDailyNutritionCarbsComboTodayTitle => 'Makro trojice';

  @override
  String get progQuestDailyNutritionCarbsComboTodayDesc =>
      'Splň v aktuálním dni kalorie, bílkoviny a sacharidy.';

  @override
  String get progQuestDailyNutritionFatComboTodayTitle => 'Makro čtveřice';

  @override
  String get progQuestDailyNutritionFatComboTodayDesc =>
      'Splň v aktuálním dni kalorie, bílkoviny, sacharidy a tuky.';

  @override
  String get progQuestDailyNutritionFiberComboTodayTitle => 'Kompletní talíř';

  @override
  String get progQuestDailyNutritionFiberComboTodayDesc =>
      'Splň v aktuálním dni kalorie, bílkoviny, sacharidy, tuky i vlákninu.';

  @override
  String get progQuestNutritionRhythm3Title => 'Vyvážený rytmus';

  @override
  String get progQuestNutritionRhythm3Desc =>
      'Získej aspoň jednu výživovou odměnu 3 období v řadě.';

  @override
  String get progQuestDailyRecoveryFocusTodayTitle => 'Regenerační fokus';

  @override
  String get progQuestDailyRecoveryFocusTodayDesc =>
      'Splň v aktuálním dni cíl kroků i spánku.';

  @override
  String get progQuestSleepTotal250hTitle => 'Odpočatá duše';

  @override
  String get progQuestSleepTotal250hDesc =>
      'Nasbírej 250 hodin sledovaného spánku.';

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
  String get progQuestDailyCarbsTodayTitle => 'Dnešní cíl sacharidů';

  @override
  String get progQuestDailyCarbsTodayDesc =>
      'Splň denní pravidlo sacharidů v aktuálním dni.';

  @override
  String get progQuestDailyFatTodayTitle => 'Dnešní cíl tuků';

  @override
  String get progQuestDailyFatTodayDesc =>
      'Splň denní pravidlo tuků v aktuálním dni.';

  @override
  String get progQuestDailyFiberTodayTitle => 'Dnešní cíl vlákniny';

  @override
  String get progQuestDailyFiberTodayDesc =>
      'Splň denní pravidlo vlákniny v aktuálním dni.';

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
  String get progQuestReach25000XpTitle => 'Dosáhni 25 000 XP';

  @override
  String get progQuestReach25000XpDesc => 'Nasbírej alespoň 25 000 XP.';

  @override
  String get progQuestReach100000XpTitle => 'Dosáhni 100 000 XP';

  @override
  String get progQuestReach100000XpDesc => 'Nasbírej alespoň 100 000 XP.';

  @override
  String get progQuestReach1000000XpTitle => 'Dosáhni 1 000 000 XP';

  @override
  String get progQuestReach1000000XpDesc => 'Nasbírej alespoň 1 000 000 XP.';

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
  String get progQuestEarn250RewardsTitle => 'Získej 250 odměn';

  @override
  String get progQuestEarn250RewardsDesc =>
      'Nasbírej celkem 250 progression odměn.';

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
  String get progQuestNutritionRewards100Title => 'Legenda maker';

  @override
  String get progQuestNutritionRewards100Desc => 'Získej 100 odměn za výživu.';

  @override
  String get progQuestTotalSteps100kTitle => 'Ujdi 100 tisíc kroků';

  @override
  String get progQuestTotalSteps100kDesc => 'Nasbírej celkem 100 000 kroků.';

  @override
  String get progQuestTotalSteps500kTitle => 'Ujdi 500 tisíc kroků';

  @override
  String get progQuestTotalSteps500kDesc => 'Nasbírej celkem 500 000 kroků.';

  @override
  String get progQuestTotalSteps1mTitle => 'Ujdi 1 milion kroků';

  @override
  String get progQuestTotalSteps1mDesc => 'Nasbírej celkem 1 000 000 kroků.';

  @override
  String get progQuestTotalSteps5mTitle => 'Ujdi 5 milionů kroků';

  @override
  String get progQuestTotalSteps5mDesc => 'Nasbírej celkem 5 000 000 kroků.';

  @override
  String get progQuestTotalSteps10mTitle => 'Ujdi 10 milionů kroků';

  @override
  String get progQuestTotalSteps10mDesc => 'Nasbírej celkem 10 000 000 kroků.';

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
  String get progQuestWeeklyActivity24Title => 'Nepřerušený tah';

  @override
  String get progQuestWeeklyActivity24Desc =>
      'Splň týdenní cíl aktivity 24krát.';

  @override
  String get progQuestWeeklyActivity52Title => 'Roční motor';

  @override
  String get progQuestWeeklyActivity52Desc =>
      'Splň týdenní cíl aktivity 52krát.';

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
  String get progQuestStepsStreak30Title => 'Vládce kroků';

  @override
  String get progQuestStepsStreak30Desc =>
      'Splň denní cíl kroků 30 dní v řadě.';

  @override
  String get progQuestStepsStreak50Title => 'Železné odhodlání';

  @override
  String get progQuestStepsStreak50Desc =>
      'Splň denní cíl kroků 50 dní v řadě.';

  @override
  String get progQuestStepsStreak100Title => 'Železný řetěz';

  @override
  String get progQuestStepsStreak100Desc =>
      'Splň denní cíl kroků 100 dní v řadě.';

  @override
  String get progQuestSourceJourney => 'Cesta';

  @override
  String get progQuestSourceDailyCombo => 'Denní kombo';

  @override
  String get progQuestSourceNutrition => 'Výživa';

  @override
  String get progQuestSourceRecovery => 'Regenerace';

  @override
  String get progQuestSourceDailyGoal => 'Denní cíl';

  @override
  String get progQuestSourceSteps => 'Kroky';

  @override
  String get progQuestSourceStepChain => 'Řetěz kroků';

  @override
  String get progQuestSourceWeekly => 'Týdenní';

  @override
  String get progQuestChainStepSteps => 'Kroky';

  @override
  String get progQuestChainStepKcal => 'Kcal';

  @override
  String get progQuestChainStepProtein => 'Protein';

  @override
  String get progQuestChainStepCarbs => 'Sach.';

  @override
  String get progQuestChainStepFat => 'Tuky';

  @override
  String get progQuestChainStepFiber => 'Vlák.';

  @override
  String get progQuestChainStepSleep => 'Spánek';

  @override
  String get progQuestChainStepBadge => 'Odznak';

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
  String get progAchievementPathfinderTitle => 'Tulák';

  @override
  String get progAchievementPathfinderDesc => 'Dosáhni levelu 5 získaným XP.';

  @override
  String get progAchievementTrailVanguardLevel10Title => 'Stopař';

  @override
  String get progAchievementTrailVanguardLevel10Desc =>
      'Dosáhni levelu 10 pomocí získaného XP.';

  @override
  String get progAchievementForgeKnightLevel15Title => 'Rytíř kovárny';

  @override
  String get progAchievementForgeKnightLevel15Desc =>
      'Dosáhni levelu 15 pomocí získaného XP.';

  @override
  String get progAchievementIronWardenLevel20Title => 'Železný strážce';

  @override
  String get progAchievementIronWardenLevel20Desc =>
      'Dosáhni levelu 20 pomocí získaného XP.';

  @override
  String get progAchievementStormHeraldLevel25Title => 'Posel bouře';

  @override
  String get progAchievementStormHeraldLevel25Desc =>
      'Dosáhni levelu 25 pomocí získaného XP.';

  @override
  String get progAchievementDawnSentinelLevel30Title => 'Hradní pán';

  @override
  String get progAchievementDawnSentinelLevel30Desc =>
      'Dosáhni levelu 30 pomocí získaného XP.';

  @override
  String get progAchievementRiftWalkerLevel40Title => 'Dračí jezdec';

  @override
  String get progAchievementRiftWalkerLevel40Desc =>
      'Dosáhni levelu 40 pomocí získaného XP.';

  @override
  String get progAchievementForgeKnight5000Title => 'Rytíř kovárny';

  @override
  String get progAchievementForgeKnight5000Desc => 'Nasbírej 5 000 XP.';

  @override
  String get progAchievementLivingLegend15000Title => 'Živá legenda';

  @override
  String get progAchievementLivingLegend15000Desc => 'Nasbírej 15 000 XP.';

  @override
  String get progAchievementXp100000Title => 'Vzestupný';

  @override
  String get progAchievementXp100000Desc => 'Nasbírej 100 000 XP.';

  @override
  String get progAchievementXp1000000Title => 'Zářný vzestup';

  @override
  String get progAchievementXp1000000Desc => 'Nasbírej 1 000 000 XP.';

  @override
  String get progAchievementMythicRangerLevel50Title => 'Mytický ranger';

  @override
  String get progAchievementMythicRangerLevel50Desc =>
      'Dosáhni levelu 50 pomocí získaného XP.';

  @override
  String get progAchievementTitanForgerLevel60Title => 'Tvůrce titánů';

  @override
  String get progAchievementTitanForgerLevel60Desc =>
      'Dosáhni levelu 60 pomocí získaného XP.';

  @override
  String get progAchievementAstralChampionLevel70Title => 'Astrální šampion';

  @override
  String get progAchievementAstralChampionLevel70Desc =>
      'Dosáhni levelu 70 pomocí získaného XP.';

  @override
  String get progAchievementEternalParagonLevel80Title => 'Věčný paragón';

  @override
  String get progAchievementEternalParagonLevel80Desc =>
      'Dosáhni levelu 80 pomocí získaného XP.';

  @override
  String get progAchievementRealmSovereignLevel90Title => 'Vládce říše';

  @override
  String get progAchievementRealmSovereignLevel90Desc =>
      'Dosáhni levelu 90 pomocí získaného XP.';

  @override
  String get progAchievementLivingLegendLevel100Title => 'Živá legenda';

  @override
  String get progAchievementLivingLegendLevel100Desc =>
      'Dosáhni levelu 100 pomocí získaného XP.';

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
  String get progAchievementSteps5000000Title => 'Stezka drahokamů';

  @override
  String get progAchievementSteps5000000Desc =>
      'Nasbírej celkem 5 000 000 kroků.';

  @override
  String get progAchievementSteps10000000Title => 'Vrchol legend';

  @override
  String get progAchievementSteps10000000Desc =>
      'Nasbírej celkem 10 000 000 kroků.';

  @override
  String get progAchievementStepsMonth300kTitle => 'Stavitel trasy';

  @override
  String get progAchievementStepsMonth300kDesc =>
      'Nasbírej 300 000 kroků v libovolném 30denním okně.';

  @override
  String get progAchievementStepsMonth600kTitle => 'Železný poutník';

  @override
  String get progAchievementStepsMonth600kDesc =>
      'Nasbírej 600 000 kroků v libovolném 30denním okně.';

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
  String get progAchievementStepCenturionTitle => 'Železný řetěz';

  @override
  String get progAchievementStepCenturionDesc =>
      'Splň denní cíl kroků 100 dní v řadě.';

  @override
  String get progAchievementBalancedRhythmTitle => 'Vyvážený rytmus';

  @override
  String get progAchievementBalancedRhythmDesc =>
      'Získej alespoň jednu odměnu za výživu 3 dny v řadě.';

  @override
  String get progAchievementNutritionStreak30Title => 'Makro momentum';

  @override
  String get progAchievementNutritionStreak30Desc =>
      'Získej alespoň jednu odměnu za výživu 30 dní v řadě.';

  @override
  String get progAchievementNutritionStreak100Title => 'Disciplína kuchyně';

  @override
  String get progAchievementNutritionStreak100Desc =>
      'Získej alespoň jednu odměnu za výživu 100 dní v řadě.';

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
  String get progAchievementWeeklyActivity24Title => 'Nepřerušené tempo';

  @override
  String get progAchievementWeeklyActivity24Desc =>
      'Splň týdenní cíl aktivity čtyřiadvacetkrát.';

  @override
  String get progAchievementWeeklyActivity52Title => 'Celoroční motor';

  @override
  String get progAchievementWeeklyActivity52Desc =>
      'Splň týdenní cíl aktivity dvaapadesátkrát.';

  @override
  String get progAchievementSleep250hTitle => 'Odpočatá duše';

  @override
  String get progAchievementSleep250hDesc =>
      'Nasbírej 250 hodin zaznamenaného spánku.';

  @override
  String get progAchievementSleep1000hTitle => 'Archiv snů';

  @override
  String get progAchievementSleep1000hDesc =>
      'Nasbírej 1 000 hodin zaznamenaného spánku.';

  @override
  String get progAchievementSleepMonth225hTitle => 'Hluboký reset';

  @override
  String get progAchievementSleepMonth225hDesc =>
      'Nasbírej 225 hodin spánku v libovolném 30denním okně.';

  @override
  String get progAchievementSleepMonth240hTitle => 'Dokonalá regenerace';

  @override
  String get progAchievementSleepMonth240hDesc =>
      'Nasbírej 240 hodin spánku v libovolném 30denním okně.';

  @override
  String get progAchievementDailyQuest3Title => 'První kroky';

  @override
  String get progAchievementDailyQuest3Desc => 'Splň 3 denní úkoly.';

  @override
  String get progAchievementDailyQuest7Title => 'Pevná ruka';

  @override
  String get progAchievementDailyQuest7Desc => 'Splň 7 denních úkolů.';

  @override
  String get progAchievementQuestHunter250Title => 'Lovec úkolů';

  @override
  String get progAchievementQuestHunter250Desc => 'Splň celkem 250 úkolů.';

  @override
  String get progAchievementActiveDays7Title => 'Týden na cestě';

  @override
  String get progAchievementActiveDays7Desc => 'Buď aktivní 7 dní.';

  @override
  String get progAchievementPerfectDays7Title => 'Vyvážený týden';

  @override
  String get progAchievementPerfectDays7Desc =>
      'Splň všechny denní cíle během 7 různých dnů.';

  @override
  String get progAchievementPerfectWeeks12Title => 'Mistr rutiny';

  @override
  String get progAchievementPerfectWeeks12Desc =>
      'Splň 12 dokonalých týdnů celkem.';

  @override
  String get progAchievementComboVictory10Title => 'Začátečník v kombech';

  @override
  String get progAchievementComboVictory10Desc =>
      'Splň 10 kombo úkolů libovolného typu.';

  @override
  String get progAchievementComboTripleVictory25Title => 'Trojitá hrozba';

  @override
  String get progAchievementComboTripleVictory25Desc =>
      'Splň 25 trojitých nebo vyšších kombo úkolů.';

  @override
  String get progAchievementComboTripleVictory100Title => 'Vládce komb';

  @override
  String get progAchievementComboTripleVictory100Desc =>
      'Splň 100 trojitých nebo vyšších kombo úkolů.';

  @override
  String get progAchievementDragonrockTrialTitle => 'Zkouška Dračí skály';

  @override
  String get progAchievementDragonrockTrialDesc =>
      'Dosáhni úrovně 100, splň 250 úkolů a ujdi 10 000 000 kroků.';

  @override
  String get progAchievementSummaryComposite => 'všechny podmínky';

  @override
  String get progAchievementSummaryDailyQuests => 'denních úkolů';

  @override
  String get progAchievementSummaryWeeklyQuests => 'týdenních úkolů';

  @override
  String get progAchievementSummaryTotalQuests => 'úkolů';

  @override
  String get progAchievementSummaryActiveDays => 'aktivních dní';

  @override
  String get progAchievementSummaryPerfectDays => 'dokonalých dní';

  @override
  String get progAchievementSummaryPerfectWeeks => 'dokonalých týdnů';

  @override
  String get progAchievementSummaryComboQuests => 'kombo úkolů';

  @override
  String get progAchievementSummaryTripleComboQuests => 'trojitých kombo úkolů';

  @override
  String get progAchievementDifficultyEasy => 'Lehké';

  @override
  String get progAchievementDifficultyMedium => 'Střední';

  @override
  String get progAchievementDifficultyHard => 'Těžké';

  @override
  String get progAchievementDifficultyExtraHard => 'Extra těžké';

  @override
  String get progAchievementDifficultyMythic => 'Nemožné';

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

  @override
  String get settingsDeveloperTools => 'Nástroje vývojáře';

  @override
  String get devtoolsTitle => 'Nástroje vývojáře';

  @override
  String get journeyTitle => 'Cesta hrdiny';

  @override
  String get journeyPreviewKicker => 'CESTA HRDINY';

  @override
  String get journeyOpenMap => 'Otevřít mapu';

  @override
  String get journeyPanHint => 'Posuň pro více';

  @override
  String get journeyHistoryHeader => 'Historie milníků';

  @override
  String get journeyLastMilestone => 'Posl. milník';

  @override
  String get journeyNextGoal => 'Další cíl';

  @override
  String get journeyTitleLabel => 'Titul';

  @override
  String get journeyFilterAll => 'Vše';

  @override
  String get journeyFilterLevels => 'Levely';

  @override
  String get journeyFilterTitles => 'Tituly';

  @override
  String get journeyFilterAchievements => 'Úspěchy';

  @override
  String get journeyFilterQuests => 'Questy';

  @override
  String get journeyEventLevelReached => 'Level dosažen';

  @override
  String get journeyEventTitleUnlocked => 'Titul odemčen';

  @override
  String get journeyEventAchievementUnlocked => 'Úspěch odemčen';

  @override
  String get journeyEventQuestCompleted => 'Quest dokončen';

  @override
  String get journeyMilestoneReached => 'Milník dosažen';

  @override
  String get journeyBadgeLocked => 'ZAMČENO';

  @override
  String get journeyBadgeHere => 'TADY';

  @override
  String get journeyTypeLevel => 'LEVEL';

  @override
  String get journeyTypeTitle => 'TITUL';

  @override
  String get journeyTypeAchievement => 'ÚSPĚCH';

  @override
  String get journeyTypeQuest => 'QUEST';

  @override
  String get journeyEmptyMapTitle => 'Tvá cesta právě začíná';

  @override
  String get journeyEmptyMapBody =>
      'Splň první quest, odemkni úspěch nebo zaznamenej aktivitu — milníky se začnou objevovat na mapě.';

  @override
  String get journeyEmptyFeedAll =>
      'Zatím tu žádné události nejsou. Splň první quest nebo odemkni úspěch.';

  @override
  String get journeyEmptyFeedFiltered =>
      'V této kategorii zatím žádné události nejsou.';

  @override
  String get journeyMiniMapEmpty =>
      'Tvé milníky se objeví, jakmile dosáhneš prvního cíle.';

  @override
  String get journeyRelativeNow => 'právě teď';

  @override
  String journeyRelativeMinutes(int count) {
    return 'před $count min';
  }

  @override
  String journeyRelativeHours(int count) {
    return 'před $count h';
  }

  @override
  String journeyRelativeDays(int count) {
    return 'před $count dny';
  }

  @override
  String journeyRelativeWeeks(int count) {
    return 'před $count týdny';
  }

  @override
  String journeyRelativeMonths(int count) {
    return 'před $count měsíci';
  }

  @override
  String journeyRelativeYears(int count) {
    return 'před $count lety';
  }

  @override
  String get journeyStartLabel => 'Začátek cesty';

  @override
  String get journeyStartDescription => 'Začátek tvé hrdinské cesty.';

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
    return '$xp XP celkem';
  }

  @override
  String get progLevelTitle1 => 'Poutník';

  @override
  String get progLevelTitle5 => 'Průzkumník stezek';

  @override
  String get progLevelTitle10 => 'Hraničář hvozdu';

  @override
  String get progLevelTitle15 => 'Strážce průsmyku';

  @override
  String get progLevelTitle20 => 'Dobyvatel ruin';

  @override
  String get progLevelTitle25 => 'Klíčník starých bran';

  @override
  String get progLevelTitle30 => 'Sestupník hlubin';

  @override
  String get progLevelTitle40 => 'Trpasličí spojenec';

  @override
  String get progLevelTitle50 => 'Pán podzemních cest';

  @override
  String get progLevelTitle60 => 'Strážce mrazu';

  @override
  String get progLevelTitle70 => 'Ledový chodec';

  @override
  String get progLevelTitle80 => 'Horský vyzyvatel';

  @override
  String get progLevelTitle90 => 'Dračí jezdec';

  @override
  String get progLevelTitle100 => 'Pán dračí skály';

  @override
  String progLevelAchievementDesc(int level) {
    return 'Dosáhni levelu $level pomocí získaného XP.';
  }

  @override
  String get cosmeticFrameLvl1Name => 'Poutnický rámeček';

  @override
  String get cosmeticFrameLvl1Desc =>
      'Prostý dřevěný rámeček pro každého, kdo se vydal na cestu.';

  @override
  String get cosmeticFrameLvl10Name => 'Rámeček hvozdu';

  @override
  String get cosmeticFrameLvl10Desc =>
      'Tmavé dřevo a jemné lesní rytiny pro ty, kteří se naučili číst stezky hvozdu.';

  @override
  String get cosmeticFrameLvl25Name => 'Rámeček starých bran';

  @override
  String get cosmeticFrameLvl25Desc =>
      'Zvětralý kámen a zašlý bronz z průsmyku, kde se stezka mění v ruiny.';

  @override
  String get cosmeticFrameLvl40Name => 'Trpasličí rám';

  @override
  String get cosmeticFrameLvl40Desc =>
      'Pevný rám z kovaného kovu a důlního kamene, vyrobený v hlubinách trpasličích síní.';

  @override
  String get cosmeticFrameLvl60Name => 'Mrazový rám';

  @override
  String get cosmeticFrameLvl60Desc =>
      'Chladný stříbrný rám s ledovým leskem, zrozený v tichu zamrzlé země.';

  @override
  String get cosmeticFrameLvl80Name => 'Rám horského vyzyvatele';

  @override
  String get cosmeticFrameLvl80Desc =>
      'Temný horský kámen a černěná ocel pro ty, kteří vystoupali k cestě na pevnost.';

  @override
  String get cosmeticFrameLvl100Name => 'Rám dračí skály';

  @override
  String get cosmeticFrameLvl100Desc =>
      'Legendární rám z obsidiánu, dračího kamene a zlatých detailů, určený pro pána dračí skály.';

  @override
  String get cosmeticFrameDeveloperTomName => 'Vyvojarsky ramecek';

  @override
  String get cosmeticFrameDeveloperTomDesc =>
      'Specialni ramecek odemceny pres Firebase entitlement.';

  @override
  String get cosmeticBackgroundDevAltarName => 'Dev: Oltar';

  @override
  String get cosmeticBackgroundDevCampName => 'Dev: Tabor';

  @override
  String get cosmeticBackgroundDevHackerName => 'Dev: Hacker';

  @override
  String get cosmeticBackgroundDevLordName => 'Dev: Lord';

  @override
  String get cosmeticBackgroundDevMinesName => 'Dev: Doly';

  @override
  String get cosmeticBackgroundDevThroneName => 'Dev: Trun';

  @override
  String get cosmeticBackgroundDevOnlyDesc =>
      'Vyvojarske pozadi. Grant pres DevTools.';

  @override
  String get cosmeticBackgroundForestTrailName => 'Lesní stezka';

  @override
  String get cosmeticBackgroundForestTrailDesc =>
      'Mlžná pěšina vedoucí pod koruny vysokých stromů.';

  @override
  String get cosmeticEmblemForestMarkName => 'Znak lesa';

  @override
  String get cosmeticEmblemForestMarkDesc =>
      'Znamení vyryté do kůry — pozdrav prvních cestovatelů.';

  @override
  String get cosmeticFrameRuinedBronzeName => 'Ruined Bronze';

  @override
  String get cosmeticFrameRuinedBronzeDesc =>
      'A patina-coated frame pulled from ancient ruins.';

  @override
  String get cosmeticBackgroundCampName => 'Tábor poutníků';

  @override
  String get cosmeticBackgroundCampDesc =>
      'Kruh kamenů kolem dohasínajícího ohně — odsud se vyráží na cestu.';

  @override
  String get cosmeticBackgroundRavineName => 'Skalní rokle';

  @override
  String get cosmeticBackgroundRavineDesc =>
      'Úzký zářez mezi stěnami, kde vítr nikdy neztichne.';

  @override
  String get cosmeticBackgroundRuinsName => 'Staré ruiny';

  @override
  String get cosmeticBackgroundRuinsDesc =>
      'Rozpadlé síně omleté staletími za průsmykem.';

  @override
  String get cosmeticBackgroundBridgeCrossingName => 'Visuté mosty';

  @override
  String get cosmeticBackgroundBridgeCrossingDesc =>
      'Lana napjatá nad propastí mezi starými cestami.';

  @override
  String get cosmeticBackgroundMinesName => 'Hornická osada';

  @override
  String get cosmeticBackgroundMinesDesc =>
      'Kouř a světlo luceren ze srdce hor, kde se neustále pracuje.';

  @override
  String get cosmeticBackgroundFrostlandsName => 'Mrazivé kraje';

  @override
  String get cosmeticBackgroundFrostlandsDesc =>
      'Sněhem zalitá pláň, která polyká kroky i zvuk.';

  @override
  String get cosmeticBackgroundFrozenLakeName => 'Zamrzlé jezero';

  @override
  String get cosmeticBackgroundFrozenLakeDesc =>
      'Tichý led nad tichou vodou — dlouhý klid před výstupem.';

  @override
  String get cosmeticBackgroundRockyMountainsName => 'Skalnaté hory';

  @override
  String get cosmeticBackgroundRockyMountainsDesc =>
      'Černé hřebeny a řídký vzduch na cestě k pevnosti.';

  @override
  String get cosmeticBackgroundDragonrockFortressName => 'Pevnost Dračí skály';

  @override
  String get cosmeticBackgroundDragonrockFortressDesc =>
      'Obsidiánová pevnost na konci cesty.';

  @override
  String get cosmeticEmblemPilgrimMarkName => 'Znamení poutníka';

  @override
  String get cosmeticEmblemPilgrimMarkDesc =>
      'Znak cestovatelů, kteří se rozhodli vyrazit na cestu.';

  @override
  String get cosmeticEmblemRuinSigilName => 'Pečeť ruin';

  @override
  String get cosmeticEmblemRuinSigilDesc =>
      'Razítko pro ty, kdo prošli starými síněmi.';

  @override
  String get cosmeticEmblemGatekeeperMarkName => 'Znamení strážce bran';

  @override
  String get cosmeticEmblemGatekeeperMarkDesc =>
      'Bronzové znamení pro ty, kdo prošli starými branami.';

  @override
  String get cosmeticEmblemMineCrestName => 'Hornický erb';

  @override
  String get cosmeticEmblemMineCrestDesc =>
      'Hornické znamení, které dostávají ti, kdo dorazili do hlubokých štol.';

  @override
  String get cosmeticEmblemUnderwaysMarkName => 'Znak podzemních cest';

  @override
  String get cosmeticEmblemUnderwaysMarkDesc =>
      'Znak pro ty, kdo se naučili stezky pod horami.';

  @override
  String get cosmeticEmblemFrostSigilName => 'Pečeť mrazu';

  @override
  String get cosmeticEmblemFrostSigilDesc =>
      'Stříbrná pečeť pro pocestné mrazivého severu.';

  @override
  String get cosmeticEmblemIcewalkerMarkName => 'Znak ledového poutníka';

  @override
  String get cosmeticEmblemIcewalkerMarkDesc =>
      'Znamení pro ty, kdo udrželi tempo i napříč ledem.';

  @override
  String get cosmeticEmblemMountainCrestName => 'Erb horského vyzyvatele';

  @override
  String get cosmeticEmblemMountainCrestDesc =>
      'Železný erb pro ty, kdo vystoupali ke hradbám pevnosti.';

  @override
  String get cosmeticEmblemDragonMarkName => 'Dračí znamení';

  @override
  String get cosmeticEmblemDragonMarkDesc =>
      'Šupinatá pečeť pro ty, kdo se vydali dračí cestou.';

  @override
  String get cosmeticEmblemDragonrockEmblemName => 'Emblém Dračí skály';

  @override
  String get cosmeticEmblemDragonrockEmblemDesc =>
      'Černo-zlatá pečeť pána Dračí skály.';

  @override
  String get cosmeticRelicCampfireSparkName => 'Jiskra táborového ohně';

  @override
  String get cosmeticRelicCampfireSparkDesc =>
      'První uhlík z první noci na cestě.';

  @override
  String get cosmeticRelicAncientRootName => 'Kořen starého lesa';

  @override
  String get cosmeticRelicAncientRootDesc =>
      'Pokroucený kořen z hvozdu, znak sedmi nepřerušených dní.';

  @override
  String get cosmeticRelicRavineStoneName => 'Kámen rokle';

  @override
  String get cosmeticRelicRavineStoneDesc =>
      'Těžký kámen donesený přes sto tisíc kroků.';

  @override
  String get cosmeticRelicRuinSealName => 'Pečeť starých ruin';

  @override
  String get cosmeticRelicRuinSealDesc =>
      'Vosková pečeť za splnění prvního týdenního questu.';

  @override
  String get cosmeticRelicBridgeKeyName => 'Klíč visutého mostu';

  @override
  String get cosmeticRelicBridgeKeyDesc =>
      'Železný klíč, který otevírá zámky starých mostních bran.';

  @override
  String get cosmeticRelicMinersLanternName => 'Hornická lucerna';

  @override
  String get cosmeticRelicMinersLanternDesc =>
      'Mosazná lucerna za splnění padesáti questů.';

  @override
  String get cosmeticRelicPolarLanternName => 'Polární lucerna';

  @override
  String get cosmeticRelicPolarLanternDesc =>
      'Lucerna s bledým plamenem pro ty, kdo dorazili do mrazivých krajů.';

  @override
  String get cosmeticRelicFrostShardName => 'Ledový střep';

  @override
  String get cosmeticRelicFrostShardDesc =>
      'Úlomek pravého ledu, chladný i pod letním sluncem.';

  @override
  String get cosmeticRelicFrozenLakeHeartName => 'Srdce ledového jezera';

  @override
  String get cosmeticRelicFrozenLakeHeartDesc =>
      'Modře zářící kámen za milion celkových kroků.';

  @override
  String get cosmeticRelicDragonScaleName => 'Dračí šupina';

  @override
  String get cosmeticRelicDragonScaleDesc =>
      'Černá šupina, jejíž povrch sálá tichým žárem.';

  @override
  String get cosmeticRelicWarmKindlingName => 'Hřejivé třísky';

  @override
  String get cosmeticRelicWarmKindlingDesc =>
      'Malý svazek suchého troudu nasbíraný před druhým východem slunce.';

  @override
  String get cosmeticRelicMoonlitFoxgloveName => 'Měsíční náprstník';

  @override
  String get cosmeticRelicMoonlitFoxgloveDesc =>
      'Bledá květina, která se otevírá jen poutníkům, co nezastavují.';

  @override
  String get cosmeticRelicWildwoodCharmName => 'Lesní amulet';

  @override
  String get cosmeticRelicWildwoodCharmDesc =>
      'Talisman spletený z lesních trav a drobných ustálených vítězství.';

  @override
  String get cosmeticRelicAshenOmenName => 'Popelná věštba';

  @override
  String get cosmeticRelicAshenOmenDesc =>
      'Spálená stopa v kamení rozvalin, kterou nechal ten, kdo už neselhává.';

  @override
  String get cosmeticRelicOathboundMarkName => 'Slibem stvrzená pečeť';

  @override
  String get cosmeticRelicOathboundMarkDesc =>
      'Slib vyrytý do kosti — dodržen mnoha drobnými vítězstvími.';

  @override
  String get cosmeticRelicDeepEmberCoreName => 'Žhavé jádro';

  @override
  String get cosmeticRelicDeepEmberCoreDesc =>
      'Uhlík, který stále hoří po milionu opatrných kroků v hlubinách.';

  @override
  String get cosmeticRelicSummitFeatherName => 'Vrcholové pero';

  @override
  String get cosmeticRelicSummitFeatherDesc =>
      'Vítr ho přinese jen těm, co překročili každý práh.';

  @override
  String get cosmeticRelicStormcrestPlumeName => 'Bouřné péro';

  @override
  String get cosmeticRelicStormcrestPlumeDesc =>
      'Pero značené rokem překonaných týdenních bouří.';

  @override
  String get cosmeticRelicDragonrockHeartName => 'Srdce Dračí skály';

  @override
  String get cosmeticRelicDragonrockHeartDesc =>
      'Žhavé jádro samotné hory, dáno jen těm, kdo dokončí Dragonrock Trial.';

  @override
  String get cosmeticFrameDisciplineName => 'Plamen disciplíny';

  @override
  String get cosmeticFrameDisciplineDesc =>
      'Získáno udržením linie po sedm dní v řadě.';

  @override
  String get cosmeticFrameEnduranceName => 'Rámeček vytrvalosti';

  @override
  String get cosmeticFrameEnduranceDesc =>
      'Vykováno pro ty, kdo nezpomalí ani po třiceti dnech v řadě.';

  @override
  String get cosmeticFrameSteelName => 'Ocelový rám';

  @override
  String get cosmeticFrameSteelDesc =>
      'Tvrdá ocel pro ty, kdo padesát dní nepřerušili tempo.';

  @override
  String get cosmeticFrameEternalFlameName => 'Věčný plamen';

  @override
  String get cosmeticFrameEternalFlameDesc =>
      'Rám pro vzácný stodenní plamen, který nikdy nezhasne.';

  @override
  String get cosmeticFrameBalanceName => 'Rámeček rovnováhy';

  @override
  String get cosmeticFrameBalanceDesc =>
      'Získáno za sedm perfektních dní za sebou.';

  @override
  String get cosmeticFrameMasterRoutineName => 'Zlatý rám rutiny';

  @override
  String get cosmeticFrameMasterRoutineDesc =>
      'Pozlacený rám za dvanáct perfektních týdnů — mistr rytmu.';

  @override
  String get cosmeticFrameEndlessTrailName => 'Rámeček nekonečné stezky';

  @override
  String get cosmeticFrameEndlessTrailDesc => 'Za 600 000 kroků během 30 dní.';

  @override
  String get cosmeticFrameWorldwalkerName => 'Rám světoběžníka';

  @override
  String get cosmeticFrameWorldwalkerDesc =>
      'Rám legend, deset milionů kroků hluboký.';

  @override
  String get cosmeticCompanionEmberSpriteName => 'Jiskřička';

  @override
  String get cosmeticCompanionEmberSpriteDesc =>
      'Malá jiskra, která doprovází ty, kdo udrží tempo.';

  @override
  String get cosmeticCompanionForestFoxName => 'Lesní liška';

  @override
  String get cosmeticCompanionForestFoxDesc =>
      'Tichá liška ze hvozdu, která kráčí po boku zkušených poutníků.';

  @override
  String get cosmeticCompanionRuinRavenName => 'Havran ruin';

  @override
  String get cosmeticCompanionRuinRavenDesc =>
      'Černý pták ze starých síní, nejčastěji k vidění po splnění týdenního questu.';

  @override
  String get cosmeticCompanionLanternGolemName => 'Lucernový golem';

  @override
  String get cosmeticCompanionLanternGolemDesc =>
      'Malý kamenný golem s lucernou poblikávající v hrudi.';

  @override
  String get cosmeticCompanionIceWispName => 'Ledový přízrak';

  @override
  String get cosmeticCompanionIceWispDesc =>
      'Bledá jiskra vyvolaná ze zamrzlého jezera těmi, kdo nesou střep i srdce.';

  @override
  String get cosmeticCompanionMountainGryphonName => 'Horský gryf';

  @override
  String get cosmeticCompanionMountainGryphonDesc =>
      'Šedý gryf, který letí nad hřebeny po boku svého zvoleného poutníka.';

  @override
  String get cosmeticCompanionDragonlingName => 'Dračí mládě';

  @override
  String get cosmeticCompanionDragonlingDesc =>
      'Malý drak, který přijímá pouze pána Dračí skály.';

  @override
  String cosmeticUnlockHintLevel(int level) {
    return 'Odemkne se na levelu $level.';
  }

  @override
  String cosmeticUnlockHintStreak(int days) {
    return 'Odemkne se za ${days}denní streak.';
  }

  @override
  String cosmeticUnlockHintTotalSteps(int steps) {
    return 'Odemkne se po $steps celkových krocích.';
  }

  @override
  String cosmeticUnlockHintMonthlySteps(int steps) {
    return 'Odemkne se za $steps kroků během 30 dní.';
  }

  @override
  String cosmeticUnlockHintQuestsCompleted(int count) {
    return 'Odemkne se po splnění $count questů.';
  }

  @override
  String cosmeticUnlockHintPerfectDays(int count) {
    return 'Odemkne se po $count perfektních dnech.';
  }

  @override
  String cosmeticUnlockHintPerfectWeeks(int count) {
    return 'Odemkne se po $count perfektních týdnech.';
  }

  @override
  String cosmeticUnlockHintActiveDays(int days) {
    return 'Odemkne se po $days aktivních dnech.';
  }

  @override
  String get cosmeticUnlockHintCompound =>
      'Odemkne se po splnění více milníků.';

  @override
  String get progAchievementWelcomeToJourneyTitle => 'Vítej na cestě';

  @override
  String get progAchievementWelcomeToJourneyDesc => 'Vyrazil jsi na cestu.';

  @override
  String get progAchievementStepsStreak50Title => 'Železná vůle';

  @override
  String get progAchievementStepsStreak50Desc =>
      'Splň pravidlo denních kroků 50 dní v řadě.';

  @override
  String get cosmeticEquippedBadge => 'VYBAVENO';

  @override
  String get cosmeticUnknown => 'Neznámá kosmetika';

  @override
  String get cosmeticHiddenName => '???';

  @override
  String get cosmeticUnknownReward => 'Neznámá odměna';

  @override
  String get cosmeticHiddenUnlockCondition =>
      'Podmínka odemčení dosud nebyla odhalena.';

  @override
  String cosmeticPartialProgress(int completed, int total) {
    return '$completed/$total podmínek splněno';
  }

  @override
  String cosmeticCompanionLevelGate(int level) {
    return 'Dosáhni úrovně $level';
  }

  @override
  String get cosmeticRarityCommon => 'Běžné';

  @override
  String get cosmeticRarityUncommon => 'Neobvyklé';

  @override
  String get cosmeticRarityRare => 'Vzácné';

  @override
  String get cosmeticRarityEpic => 'Epické';

  @override
  String get cosmeticRarityLegendary => 'Legendární';

  @override
  String get cosmeticRarityMythic => 'Mytické';

  @override
  String get celebrationCosmeticUnlockedEyebrow => 'Odemčeno v inventáři';

  @override
  String get socialTabFeed => 'Feed';

  @override
  String get socialTabActivity => 'Aktivita';

  @override
  String get socialTabLeaderboard => 'Žebříček';

  @override
  String get socialTabFriends => 'Přátelé';

  @override
  String get socialSectionRecentActivity => 'NEDÁVNÁ AKTIVITA';

  @override
  String get socialSectionFriendActivity => 'AKTIVITA PŘÁTEL';

  @override
  String get socialNoNotificationsTitle => 'Žádné upozornění';

  @override
  String get socialNoNotificationsSubtitle =>
      'Zde uvidíš reakce přátel na tvoje sdílené achievementy.';

  @override
  String get socialFeedEmptyTitle => 'Feed je prázdný';

  @override
  String get socialFeedEmptySubtitle =>
      'Sdílené achievementy přátel se zobrazí zde.';

  @override
  String get socialFriendsEmptyTitle => 'Žádní přátelé';

  @override
  String get socialFriendsEmptySubtitle =>
      'Přidej přátele vyhledáním jejich přezdívky.';

  @override
  String socialFriendsSectionCount(int count) {
    return 'PŘÁTELÉ  •  $count';
  }

  @override
  String get socialFriendRequestsTitle => 'Žádosti o přátelství';

  @override
  String socialOutgoingRequestsCount(int count) {
    return 'Odeslané žádosti • $count';
  }

  @override
  String get socialFriendRequestAccepted => 'Žádost přijata.';

  @override
  String get socialFriendRequestDeclined => 'Žádost odmítnuta.';

  @override
  String get socialFriendRequestSent => 'Žádost o přátelství odeslána.';

  @override
  String socialErrorWithMessage(String message) {
    return 'Chyba: $message';
  }

  @override
  String get socialWantsToBeFriend => 'Chce se stát tvým přítelem';

  @override
  String get socialAccept => 'Přijmout';

  @override
  String get socialDecline => 'Odmítnout';

  @override
  String get socialAwaitingConfirmation => 'Čeká na potvrzení';

  @override
  String get socialPending => 'Pending';

  @override
  String get socialSearchHint => 'Hledat podle přezdívky…';

  @override
  String get socialSearchButton => 'Najít';

  @override
  String get socialAdd => 'Přidat';

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
    return '$count přátel';
  }

  @override
  String get socialLeaderboardThisWeek => 'Tento týden';

  @override
  String get socialLeaderboardAllTime => 'Celkem';

  @override
  String get socialLeaderboardSoonTitle => 'Brzy dostupné';

  @override
  String get socialLeaderboardSoonSubtitle =>
      'Týdenní žebříček bude brzy dostupný.';

  @override
  String get socialLeaderboardEmptyTitle => 'Žebříček je prázdný';

  @override
  String get socialLeaderboardEmptySubtitle =>
      'Přidej přátele a porovnej své výsledky.';

  @override
  String get socialLeaderboardTopPlayers => 'TOP HRÁČI';

  @override
  String get socialYouBadge => 'Ty!';

  @override
  String socialYouSuffix(String name) {
    return '$name (ty)';
  }

  @override
  String get socialXpLabel => 'XP';

  @override
  String get socialStatusSignInRequired =>
      'Přihlášení přes Google je vyžadováno pro sociální funkce.';

  @override
  String socialStatusBackendUnavailable(String error) {
    return 'Firebase backend nedostupný: $error';
  }

  @override
  String get socialStatusConnecting => 'Připojování k sociálnímu backendu…';

  @override
  String socialStatusError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get socialEditHandleTitle => 'Změnit Social ID';

  @override
  String get socialEditHandleDescription =>
      'ID slouží pro vyhledání v social části.';

  @override
  String get socialEditHandleValidation => 'Zadej alespoň jeden znak.';

  @override
  String get socialCancel => 'Zrušit';

  @override
  String get socialSave => 'Uložit';

  @override
  String get socialEditHandleTooltip => 'Změnit ID';

  @override
  String get socialEditPhotoTooltip => 'Změnit fotku';

  @override
  String socialHandleSaveFailed(String error) {
    return 'ID se nepodařilo uložit: $error';
  }

  @override
  String socialHandleSaved(String handle) {
    return 'Social ID uloženo: @$handle';
  }

  @override
  String socialPhotoPickFailed(String error) {
    return 'Výběr fotky se nepodařil: $error';
  }

  @override
  String socialPhotoSaveFailed(String error) {
    return 'Fotku se nepodařilo uložit: $error';
  }

  @override
  String get socialPhotoSaved => 'Profilová fotka uložena.';

  @override
  String get socialTryAgain => 'zkus to znovu';

  @override
  String get socialSelectedLoadout => 'Vybraná\nvýbava';

  @override
  String get socialProfilePinnedAchievements => 'PŘIPNUTÉ ACHIEVEMENTY';

  @override
  String get socialProfileSharedPosts => 'SDÍLENÉ PŘÍSPĚVKY';

  @override
  String get socialProfileStatsAchievements => 'ÚSPĚCHY';

  @override
  String get socialProfileStatsBestStreak => 'NEJL. SÉRIE';

  @override
  String get socialProfileStatsStepsStreak => 'KROKY SÉRIE';

  @override
  String socialDaysShort(int count) {
    return '$count d';
  }

  @override
  String get socialPinnedEmptyMine =>
      'Zatím nemáš nic připnutého. Otevři detail achievementu a připni ho na profil.';

  @override
  String get socialPinnedEmptyOther => 'Žádné připnuté achievementy.';

  @override
  String get socialPinnedUnavailable =>
      'Připnuté achievementy už nejsou dostupné.';

  @override
  String get socialSharedPostsEmpty => 'Žádné sdílené příspěvky zatím.';

  @override
  String get socialProfileCosmetics => 'KOSMETIKA';

  @override
  String get socialAddFriend => 'Přidat přítele';

  @override
  String get socialRequestSent => 'Žádost odeslána';

  @override
  String get socialRemoveFriend => 'Odebrat přítele';

  @override
  String get socialRemoveFriendConfirmTitle => 'Odebrat přítele';

  @override
  String socialRemoveFriendConfirmBody(String name) {
    return 'Opravdu chceš odebrat $name ze seznamu přátel?';
  }

  @override
  String get socialNotificationReactedPrefix => ' reagoval(a) ';

  @override
  String get socialNotificationReactedSuffix => ' na tvůj achievement ';

  @override
  String get socialNotificationOpenPost => 'Zobrazit příspěvek';

  @override
  String get socialAchievementUnlockedAction => 'odemkl(a) achievement';

  @override
  String socialReactorsTitle(int count) {
    return 'Reagovali ($count)';
  }

  @override
  String get socialProfileFriendsTitle => 'PŘÁTELÉ';

  @override
  String get socialProfileNoFriends => 'Žádní přátelé zatím.';

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
  String get socialRelativeNow => 'právě teď';

  @override
  String socialRelativeMinutesAgo(int count) {
    return 'před $count min';
  }

  @override
  String socialRelativeHoursAgo(int count) {
    return 'před $count hod';
  }

  @override
  String get socialRelativeYesterday => 'včera';

  @override
  String socialRelativeDaysAgo(int count) {
    return 'před $count dny';
  }

  @override
  String get cosmeticFrameLvl1UnlockHint => 'Odměna za zahájení cesty.';

  @override
  String get cosmeticFrameLvl10UnlockHint => 'Dosáhni úrovně 10.';

  @override
  String get cosmeticFrameLvl25UnlockHint => 'Dosáhni úrovně 25.';

  @override
  String get cosmeticFrameLvl40UnlockHint => 'Dosáhni úrovně 40.';

  @override
  String get cosmeticFrameLvl60UnlockHint => 'Dosáhni úrovně 60.';

  @override
  String get cosmeticFrameLvl80UnlockHint => 'Dosáhni úrovně 80.';

  @override
  String get cosmeticFrameLvl100UnlockHint => 'Dosáhni úrovně 100.';

  @override
  String get cosmeticFrameDisciplineUnlockHint =>
      'Udržuj 7denní krokovací sérii.';

  @override
  String get cosmeticFrameEnduranceUnlockHint =>
      'Udržuj 30denní krokovací sérii.';

  @override
  String get cosmeticFrameSteelUnlockHint => 'Udržuj 50denní krokovací sérii.';

  @override
  String get cosmeticFrameEternalFlameUnlockHint =>
      'Udržuj 100denní krokovací sérii.';

  @override
  String get cosmeticFrameBalanceUnlockHint =>
      'Dosáhni 7 dokonalých dní aktivity.';

  @override
  String get cosmeticFrameMasterRoutineUnlockHint =>
      'Dosáhni 12 dokonalých týdnů aktivity.';

  @override
  String get cosmeticFrameEndlessTrailUnlockHint =>
      'Ujdi 600 000 kroků za 30 dní.';

  @override
  String get cosmeticFrameWorldwalkerUnlockHint =>
      'Ujdi celkem 10 000 000 kroků.';

  @override
  String get cosmeticBackgroundForestTrailUnlockHint => 'Dosáhni úrovně 5.';

  @override
  String get cosmeticBackgroundCampUnlockHint => 'Dokonči svůj první úkol.';

  @override
  String get cosmeticBackgroundRavineUnlockHint => 'Dosáhni úrovně 15.';

  @override
  String get cosmeticBackgroundRuinsUnlockHint => 'Dosáhni úrovně 25.';

  @override
  String get cosmeticBackgroundBridgeCrossingUnlockHint => 'Dosáhni úrovně 35.';

  @override
  String get cosmeticBackgroundMinesUnlockHint => 'Dosáhni úrovně 45.';

  @override
  String get cosmeticBackgroundFrostlandsUnlockHint => 'Dosáhni úrovně 60.';

  @override
  String get cosmeticBackgroundFrozenLakeUnlockHint => 'Dosáhni úrovně 75.';

  @override
  String get cosmeticBackgroundRockyMountainsUnlockHint => 'Dosáhni úrovně 80.';

  @override
  String get cosmeticBackgroundDragonrockFortressUnlockHint =>
      'Dosáhni úrovně 95.';

  @override
  String get cosmeticEmblemForestMarkUnlockHint => 'Dosáhni úrovně 10.';

  @override
  String get cosmeticEmblemPilgrimMarkUnlockHint => 'Vydej se na cestu.';

  @override
  String get cosmeticEmblemRuinSigilUnlockHint => 'Dosáhni úrovně 20.';

  @override
  String get cosmeticEmblemGatekeeperMarkUnlockHint => 'Dosáhni úrovně 30.';

  @override
  String get cosmeticEmblemMineCrestUnlockHint => 'Dosáhni úrovně 40.';

  @override
  String get cosmeticEmblemUnderwaysMarkUnlockHint => 'Dosáhni úrovně 50.';

  @override
  String get cosmeticEmblemFrostSigilUnlockHint => 'Dosáhni úrovně 60.';

  @override
  String get cosmeticEmblemIcewalkerMarkUnlockHint => 'Dosáhni úrovně 70.';

  @override
  String get cosmeticEmblemMountainCrestUnlockHint => 'Dosáhni úrovně 80.';

  @override
  String get cosmeticEmblemDragonMarkUnlockHint => 'Dosáhni úrovně 90.';

  @override
  String get cosmeticEmblemDragonrockEmblemUnlockHint => 'Dosáhni úrovně 100.';

  @override
  String get cosmeticRelicCampfireSparkUnlockHint =>
      'Dokonči svůj první denní úkol.';

  @override
  String get cosmeticRelicAncientRootUnlockHint =>
      'Udržuj 7denní krokovací sérii.';

  @override
  String get cosmeticRelicRavineStoneUnlockHint => 'Ujdi celkem 100 000 kroků.';

  @override
  String get cosmeticRelicRuinSealUnlockHint =>
      'Dokonči svůj první týdenní úkol.';

  @override
  String get cosmeticRelicBridgeKeyUnlockHint => 'Dokonči 3 týdenní úkoly.';

  @override
  String get cosmeticRelicMinersLanternUnlockHint => 'Dokonči celkem 50 úkolů.';

  @override
  String get cosmeticRelicPolarLanternUnlockHint => 'Dosáhni úrovně 55.';

  @override
  String get cosmeticRelicFrostShardUnlockHint => 'Dosáhni úrovně 65.';

  @override
  String get cosmeticRelicFrozenLakeHeartUnlockHint =>
      'Ujdi celkem 1 000 000 kroků.';

  @override
  String get cosmeticRelicDragonScaleUnlockHint => 'Dosáhni úrovně 85.';

  @override
  String get cosmeticRelicWarmKindlingUnlockHint => 'Splň 3 denní úkoly.';

  @override
  String get cosmeticRelicMoonlitFoxgloveUnlockHint => 'Buď aktivní 7 dní.';

  @override
  String get cosmeticRelicWildwoodCharmUnlockHint => 'Splň 7 denních úkolů.';

  @override
  String get cosmeticRelicAshenOmenUnlockHint => 'Splň týdenní aktivitu 4×.';

  @override
  String get cosmeticRelicOathboundMarkUnlockHint => 'Splň 10 kombo úkolů.';

  @override
  String get cosmeticRelicDeepEmberCoreUnlockHint =>
      'Naber 1 000 000 kroků celkem.';

  @override
  String get cosmeticRelicSummitFeatherUnlockHint =>
      'Splň 100 trojitých kombo úkolů.';

  @override
  String get cosmeticRelicStormcrestPlumeUnlockHint =>
      'Splň týdenní aktivitu 52×.';

  @override
  String get cosmeticRelicDragonrockHeartUnlockHint =>
      'Dokonči Dragonrock Trial.';

  @override
  String get cosmeticCompanionEmberSpriteUnlockHint =>
      'Buď aktivní 7 dní nebo dokonči 3 denní úkoly.';

  @override
  String get cosmeticCompanionForestFoxUnlockHint =>
      'Získej Lesní znak a Pradávný kořen.';

  @override
  String get cosmeticCompanionRuinRavenUnlockHint =>
      'Získej Ruinové pečetidlo a dokonči první týdenní úkol.';

  @override
  String get cosmeticCompanionLanternGolemUnlockHint =>
      'Získej Hornickou lucernu a dokonči 75 úkolů.';

  @override
  String get cosmeticCompanionIceWispUnlockHint =>
      'Získej Ledový střep a Srdce zmrzlého jezera.';

  @override
  String get cosmeticCompanionMountainGryphonUnlockHint =>
      'Dosáhni úrovně 80 a získej Srdce zmrzlého jezera.';

  @override
  String get cosmeticCompanionDragonlingUnlockHint =>
      'Dosáhni úrovně 100 a získej Dračí korunu pevnosti.';
}
