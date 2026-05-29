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
  String get navQuests => 'Úkoly';

  @override
  String get navHero => 'Hero';

  @override
  String get navSocial => 'Společenstvo';

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
  String get screenSteps => 'Kroky';

  @override
  String get screenNutrition => 'Výživa';

  @override
  String get nutritionEnergyTrend => 'Vývoj kalorií';

  @override
  String get nutritionMacroTrend => 'Vývoj makroživin';

  @override
  String get nutritionHydrationTitle => 'Pitný režim';

  @override
  String get nutritionMacrosDetailTitle => 'Makroživiny';

  @override
  String get nutritionMealsTitle => 'Jídla';

  @override
  String get nutritionMealsEmpty => 'Žádná zaznamenaná jídla';

  @override
  String nutritionFoodItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count položek',
      few: '$count položky',
      one: '1 položka',
      zero: 'žádné položky',
    );
    return '$_temp0';
  }

  @override
  String get nutritionBalanceTitle => 'Energetická bilance';

  @override
  String get nutritionBalanceBasal => 'Bazál';

  @override
  String get nutritionBalanceActive => 'Aktivita';

  @override
  String get nutritionBalanceOutput => 'Výdej';

  @override
  String get nutritionBalanceIntake => 'Příjem';

  @override
  String get nutritionBalanceDeficit => 'Deficit';

  @override
  String get nutritionBalanceSurplus => 'Přebytek';

  @override
  String get nutritionMealsOnlyDayMode =>
      'Detail jídel a bilance jen v denním přehledu';

  @override
  String get screenBody => 'Tělo';

  @override
  String get stepsCurrentStreak => 'Série';

  @override
  String get stepsLinkSubtitle => 'Denní kroky a cíl';

  @override
  String get activitiesByType => 'Podle typu';

  @override
  String get activitiesLinkSubtitle => 'Tréninky, kalorie, čas';

  @override
  String get periodDay => 'Den';

  @override
  String get periodWeek => 'Týden';

  @override
  String get periodMonth => 'Měsíc';

  @override
  String get periodToday => 'Dnes';

  @override
  String get periodCustomRangeSoon => 'Vlastní rozsah bude brzy k dispozici';

  @override
  String get caloriesAvgPerDay => 'Průměr / den';

  @override
  String get homeCardAvgWeek => 'průměr za týden';

  @override
  String get homeCardAvgMonth => 'průměr za měsíc';

  @override
  String get nutritionCardTitle => 'Výživa';

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
  String get weightBodyWater => 'Tělesná voda';

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
      'Povolit připomínky, questy a oznámení ze Společenstva.';

  @override
  String get sectionNotifications => 'Notifikace';

  @override
  String get settingsNotifMasterSubtitle =>
      'Hlavní vypínač — vypnutím utišíš celou aplikaci.';

  @override
  String get settingsNotifProgressionLabel => 'Postup';

  @override
  String get settingsNotifProgressionSubtitle =>
      'Splněné questy a odemčené achievementy.';

  @override
  String get settingsNotifSocialLabel => 'Společenstvo';

  @override
  String get settingsNotifSocialSubtitle =>
      'Žádosti o přátelství a reakce na tvé posty.';

  @override
  String get settingsNotifRemindersLabel => 'Připomínky';

  @override
  String get settingsNotifRemindersSubtitle => 'Denní připomínky cílů.';

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
  String get settingsHubHealthConnectSubtitle => 'Oprávnění a synchronizace';

  @override
  String get settingsHubGoalsSubtitle => 'Kalorie, makra, připomínky';

  @override
  String get settingsHubNotificationsSubtitle => 'Co a kdy ti přijde';

  @override
  String get settingsHubPreferencesSubtitle => 'Jazyk, soukromí';

  @override
  String get settingsHubDataSubtitle => 'Export a správa dat';

  @override
  String get settingsHubAboutSubtitle => 'Verze, zásady, zpětná vazba';

  @override
  String get aboutTagline => 'Tvůj trénink jako RPG dobrodružství';

  @override
  String get aboutDescription =>
      'Forgetrack mění sledování jídla, aktivity a spánku ve hru — plníš questy, sbíráš XP, levelíš svého hrdinu a odemykáš kosmetiku. Propoj Health Connect a Kalorické tabulky a data se načtou automaticky.';

  @override
  String get aboutSectionFaq => 'Časté dotazy';

  @override
  String get aboutSectionContact => 'Kontakt a zpětná vazba';

  @override
  String get aboutContactEmail => 'Napiš nám';

  @override
  String get aboutRateApp => 'Ohodnotit aplikaci';

  @override
  String get aboutWebsite => 'Web';

  @override
  String get aboutFaqCatHc => 'Health Connect';

  @override
  String get aboutFaqCatKt => 'Kalorické tabulky';

  @override
  String get aboutFaqCatGoals => 'Cíle';

  @override
  String get aboutFaqCatData => 'Data a soukromí';

  @override
  String get aboutFaqCatGame => 'Hra a postup';

  @override
  String get aboutFaqHcWhatQ => 'Co je Health Connect a proč ho appka využívá?';

  @override
  String get aboutFaqHcWhatA =>
      'Health Connect je systémové úložiště zdravotních dat od Googlu. Forgetrack z něj čte kroky, aktivitu, spánek a váhu, takže je nemusíš zadávat ručně. Data zůstávají v telefonu a sdílí se jen mezi aplikacemi, kterým to povolíš.';

  @override
  String get aboutFaqHcConnectQ => 'Jak připojím Health Connect?';

  @override
  String get aboutFaqHcConnectA =>
      'V Nastavení → Health Connect klepni na Oprávnění a povol čtení dat, která chceš sledovat. Na některých telefonech je potřeba Health Connect nejdřív nainstalovat z Obchodu Play.';

  @override
  String get aboutFaqHcNoDataQ =>
      'Proč se nezobrazují žádná data z Health Connect?';

  @override
  String get aboutFaqHcNoDataA =>
      'Health Connect sám o sobě data nesbírá — jen je sdílí. Tvoje zdrojová aplikace (Samsung Health, Google Fit, Fitbit apod.) musí mít povolený zápis (push) dat do Health Connect. Zkontroluj to v nastavení dané aplikace v sekci propojení s Health Connect.';

  @override
  String get aboutFaqKtWhatQ =>
      'K čemu slouží propojení s Kalorickými tabulkami?';

  @override
  String get aboutFaqKtWhatA =>
      'Po přihlášení Forgetrack načítá tvůj denní příjem kalorií a makra z účtu na kaloricketabulky.cz, takže nemusíš jídlo zadávat dvakrát.';

  @override
  String get aboutFaqKtConnectQ => 'Jak propojím Kalorické tabulky?';

  @override
  String get aboutFaqKtConnectA =>
      'V Nastavení → Kalorické tabulky se přihlas svým účtem z kaloricketabulky.cz. Přihlášení se uloží, takže se data synchronizují automaticky.';

  @override
  String get aboutFaqGoalsQ => 'Odkud se berou moje výživové cíle?';

  @override
  String get aboutFaqGoalsA =>
      'Ve výchozím stavu si kalorie a makra nastavuješ sám v Nastavení → Cíle. Pokud máš připojené Kalorické tabulky, můžeš tam přepínačem zvolit, aby se denní cíle braly z nich.';

  @override
  String get aboutFaqPrivacyQ =>
      'Jsou moje data v bezpečí a synchronizují se mezi zařízeními?';

  @override
  String get aboutFaqPrivacyA =>
      'Tvůj postup, hrdina a nastavení se zálohují do tvého účtu, takže je máš na všech zařízeních, kde se přihlásíš. Zdravotní data z Health Connect se zpracovávají v telefonu.';

  @override
  String get aboutFaqRpgQ => 'Jak fungují XP, úrovně a questy?';

  @override
  String get aboutFaqRpgA =>
      'Za splněné cíle a aktivitu získáváš XP a postupně levelíš hrdinu. Questy ti dávají krátkodobé výzvy a za jejich splnění tě čekají odměny včetně kosmetiky.';

  @override
  String get sectionAccount => 'Účet';

  @override
  String get settingsHealthConnectSection => 'Health Connect';

  @override
  String get settingsHealthConnectOpen => 'Otevřít Health Connect';

  @override
  String get settingsHealthConnectOpenBody =>
      'Zkontrolujte propojené aplikace, zdroje dat a nastavení Health Connect.';

  @override
  String get settingsHealthConnectPermissions => 'Spravovat oprávnění';

  @override
  String get settingsHealthConnectPermissionsBody =>
      'Povolte přístup ke krokům, kaloriím, váze, spánku a aktivitám.';

  @override
  String get settingsHealthConnectConnected => 'Připojeno';

  @override
  String get settingsHealthConnectNeedsAccess => 'Chybí přístup';

  @override
  String get settingsAppVersion => 'Verze aplikace';

  @override
  String get settingsPrivacy => 'Zásady ochrany osobních údajů';

  @override
  String get settingsTerms => 'Podmínky použití';

  @override
  String get settingsFeedback => 'Odeslat zpětnou vazbu';

  @override
  String get settingsFeedbackUnavailable =>
      'Zpětná vazba je dostupná jen v produkčním buildu';

  @override
  String get settingsCrashReporting => 'Hlášení pádů';

  @override
  String get settingsCrashReportingSubtitle =>
      'Posílat anonymní hlášení pádů, abychom mohli chyby opravovat rychleji.';

  @override
  String get settingsCrashReportingDevBuild =>
      'Dostupné jen v produkčním buildu.';

  @override
  String get settingsCrashReportingRestart =>
      'Změny se projeví po restartu aplikace.';

  @override
  String get sentryConsentTitle => 'Pomoz vylepšit Forgetrack';

  @override
  String get sentryConsentBody =>
      'Můžeme odesílat anonymní hlášení pádů a krátké technické breadcrumby (žádný e-mail, žádná nutriční data, žádné váhy), abychom mohli chyby opravovat rychleji. Volbu změníš kdykoli v Nastavení.';

  @override
  String get sentryConsentAccept => 'Povolit';

  @override
  String get sentryConsentDecline => 'Ne, díky';

  @override
  String get devtoolsForceCrashLabel => 'Vyvolat pád';

  @override
  String get devtoolsForceCrashSubtitle =>
      'Hodí neodchycenou výjimku, abychom ověřili, že Sentry zachytává.';

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
  String get healthShowCachedData => 'Zobrazit uložená data';

  @override
  String get healthOfflineNotice =>
      'Zobrazují se uložená data — klepnutím nastavte Health Connect';

  @override
  String get healthFooterOfflineHint =>
      'Uložená data — klepnutím připojit Health Connect';

  @override
  String get homeOfflineBanner => 'Jste offline — zobrazují se uložená data';

  @override
  String get ktOfflineNotice =>
      'Zobrazují se uložená data — klepnutím připojte Kalorické Tabulky';

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
  String get ktReauthRequired =>
      'Přihlaste se znovu do Kalorických Tabulek pro pokračování synchronizace.';

  @override
  String get ktReauthCta => 'Přihlásit se';

  @override
  String ktReconnecting(int seconds) {
    return 'Připojuji znovu ke Kalorickým Tabulkám… další pokus za ${seconds}s';
  }

  @override
  String get ktReconnectTryNow => 'Zkusit hned';

  @override
  String get ktFooterOfflineHint => 'Uložená data — klepnutím připojit';

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
  String get sleepStageDeep => 'Hluboký';

  @override
  String get sleepStageLight => 'Lehký';

  @override
  String get sleepStageRem => 'REM';

  @override
  String get sleepStageAwake => 'Vzhůru';

  @override
  String get sleepStagesTitle => 'Stádia spánku';

  @override
  String get sleepStagesBreakdown => 'Rozdělení stádií';

  @override
  String get sleepDurationTrend => 'Vývoj délky spánku';

  @override
  String get sleepDeepTrend => 'Hluboký spánek';

  @override
  String get sleepRemTrend => 'REM spánek';

  @override
  String get sleepNoStageData => 'Stádia spánku nejsou k dispozici';

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
  String get homeActivityClaimsHeader => 'Vyzvednout XP za trénink';

  @override
  String activitiesBackfillClaimAll(int xp) {
    return 'Vyzvednout vše · +$xp XP';
  }

  @override
  String activitiesBackfillClaimedToast(int count, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vyzvednuto $count tréninků · +$xp XP',
      few: 'Vyzvednuty $count tréninky · +$xp XP',
      one: 'Vyzvednut $count trénink · +$xp XP',
    );
    return '$_temp0';
  }

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
  String get activityDetailTitle => 'Detail tréninku';

  @override
  String get activityDetailStart => 'Začátek';

  @override
  String get activityDetailEnd => 'Konec';

  @override
  String get activityDetailPace => 'Tempo';

  @override
  String get activityDetailDistance => 'Vzdálenost';

  @override
  String get activityDetailComparison => 'Srovnání';

  @override
  String get activityDetailNoMap => 'GPS data nejsou k dispozici';

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
  String get goalDailyActivity => 'Denní aktivita';

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
  String get goalDailyFiber => 'Denní vláknina';

  @override
  String settingsGoalsNutritionSummary(
      String kcal, String protein, String fat, String carbs, String fiber) {
    return '$kcal kcal · ${protein}B / ${fat}T / ${carbs}S / ${fiber}V g';
  }

  @override
  String get settingsGoalsMacroBreakdownLabel => 'Energie z makroživin';

  @override
  String settingsGoalsMacroBreakdownMismatch(int delta) {
    String _temp0 = intl.Intl.pluralLogic(
      delta,
      locale: localeName,
      other: 'Odchylka $delta kcal',
      few: 'Odchylka $delta kcal',
      one: 'Odchylka $delta kcal',
      zero: 'Odpovídá kalorickému cíli',
    );
    return '$_temp0';
  }

  @override
  String get settingsGoalsActivityHeader => 'Aktivita';

  @override
  String get settingsGoalsNutritionHeader => 'Výživa';

  @override
  String get settingsGoalsSleepHeader => 'Spánek';

  @override
  String get settingsGoalsBodyHeader => 'Tělo';

  @override
  String get onboardingGoalsHealthHeading => 'Tvé denní cíle';

  @override
  String get onboardingGoalsNutritionHeading => 'Výživové cíle';

  @override
  String get nutritionGoalsSourceLabel => 'Zdroj výživových cílů';

  @override
  String get nutritionGoalsSourceLocal => 'Vlastní';

  @override
  String get nutritionGoalsSourceKt => 'Kalorické tabulky';

  @override
  String get nutritionGoalsSourceKtHint =>
      'Denní cíle pro kalorie a makra se berou z tvého účtu Kalorických tabulek, pole níže jsou proto jen pro čtení.';

  @override
  String get nutritionGoalsSourceConnectKt =>
      'Pro použití cílů z KT se nejdřív přihlas ke Kalorickým tabulkám.';

  @override
  String get nutritionGoalsSourceSwitchTitle => 'Cíle z Kalorických tabulek';

  @override
  String get nutritionGoalsSourceSwitchSubtitle =>
      'Ber denní kalorie a makra z KT místo vlastních';

  @override
  String get nutritionGoalsSourceOffCaption =>
      'Cíle pro kalorie a makra si nastav níže. Zapni přepínač, pokud chceš místo toho použít denní cíle z Kalorických tabulek.';

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
  String get exportErrorSignInCancelled =>
      'Přihlášení do Googlu bylo zrušeno. Pro export se prosím přihlaste.';

  @override
  String get exportErrorNetwork =>
      'Bez připojení k internetu. Zkontrolujte síť a zkuste to znovu.';

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
  String get profileTabStats => 'Přehled';

  @override
  String get profileTabInventory => 'Inventář';

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
  String get questsScreenEyebrow => 'ÚKOLY';

  @override
  String get questsScreenTitle => 'Tvoje úkoly a odměny';

  @override
  String get progQuestsActiveHeader => 'AKTIVNÍ ÚKOLY';

  @override
  String progQuestsActiveCount(int count) {
    return '$count aktivních';
  }

  @override
  String get progQuestsDailyGoalsHeader => 'DENNÍ CÍLE';

  @override
  String get progQuestsDailyTasksHeader => 'DENNÍ ÚKOLY';

  @override
  String get progQuestsDailyTasksHint =>
      'Úkoly se denně obměňují — splněné zůstanou viditelné do půlnoci.';

  @override
  String get progQuestsDailyComboHeader => 'DNEŠNÍ KOMBO';

  @override
  String get progQuestsWeeklyHeader => 'TENTO TÝDEN';

  @override
  String get progQuestsChapterHeader => 'KAPITOLY CESTY';

  @override
  String get progQuestsComboHeader => 'DENNÍ COMBO';

  @override
  String get progQuestsDailyChallengeHeader => 'DENNÍ QUEST';

  @override
  String get progQuestsChapterSideQuestsHeader => 'VEDLEJŠÍ ÚKOLY KAPITOLY';

  @override
  String get progSidePilgrimMorningWalkTitle => 'Ranní pochod poutníka';

  @override
  String get progSidePilgrimMorningWalkDesc =>
      'Vyraz na cestu hned po probuzení — splň dnes kroky i aktivní minuty.';

  @override
  String get progSidePilgrimQuietRestTitle => 'Klid poutníka';

  @override
  String get progSidePilgrimQuietRestDesc =>
      'Tělo poutníka potřebuje odpočinek — splň dnes spánek i protein.';

  @override
  String get progSideForestBriskwalkTitle => 'Hbitý krok lesem';

  @override
  String get progSideForestBriskwalkDesc =>
      'Les odměňuje pravidelný pohyb — splň dnes kroky i aktivní minuty.';

  @override
  String get progSideForestCampTitle => 'Tábor pod stromy';

  @override
  String get progSideForestCampDesc =>
      'Klid noci v lese — splň dnes spánek, protein i kalorie.';

  @override
  String get progSideForestClearingTitle => 'Mýtina za úsvitem';

  @override
  String get progSideForestClearingDesc =>
      'Mýtina prověří všechny směry — splň dnes kroky, aktivitu, spánek i protein.';

  @override
  String get progSideMineDeepShaftTitle => 'Hluboká štola';

  @override
  String get progSideMineDeepShaftDesc =>
      'Den v hloubce — splň dnes kroky, aktivitu i spánek.';

  @override
  String get progSideMineForgeFinaleTitle => 'Výheň v jádru hor';

  @override
  String get progSideMineForgeFinaleDesc =>
      'Výheň hoří jen pro plné týmy — splň dnes pět denních cílů včetně jídla.';

  @override
  String get progSidePactMarchTitle => 'Pochod paktu';

  @override
  String get progSidePactMarchDesc =>
      'Pakt jde celý den — splň dnes čtyři ze základů (kroky, aktivita, spánek, kalorie).';

  @override
  String get progSidePactFinaleTitle => 'Pečeť paktu';

  @override
  String get progSidePactFinaleDesc =>
      'Pakt vrcholí dokonalou kombinací — splň dnes šest různých denních cílů.';

  @override
  String get progSideRuinsSteadyDawnTitle => 'Pevné svítání';

  @override
  String get progSideRuinsSteadyDawnDesc =>
      'Disciplína začíná ráno — splň dnes kroky, spánek i protein.';

  @override
  String get progSideRuinsIronIntakeTitle => 'Železná strava';

  @override
  String get progSideRuinsIronIntakeDesc =>
      'Tři makra do soumraku — splň dnes libovolné tři nutriční cíle.';

  @override
  String get progSideMineTorchbearerTitle => 'Nositel pochodně';

  @override
  String get progSideMineTorchbearerDesc =>
      'Otevři novou štolu — splň dnes kroky i aktivní minuty.';

  @override
  String get progSideMineLongHaulTitle => 'Dlouhá šachta';

  @override
  String get progSideMineLongHaulDesc =>
      'Vydrž v hloubce celý den — splň kroky, aktivitu i spánek.';

  @override
  String get progSideForgeMorningAnvilTitle => 'Ranní kovadlina';

  @override
  String get progSideForgeMorningAnvilDesc =>
      'Roztop výheň ještě před polednem — splň dnes kroky i aktivní minuty.';

  @override
  String get progSideForgeFullFurnaceTitle => 'Plná výheň';

  @override
  String get progSideForgeFullFurnaceDesc =>
      'Krm oheň ze všech stran — splň dnes čtyři nutriční cíle.';

  @override
  String get progSideUnderwayWarmCampTitle => 'Teplý tábor';

  @override
  String get progSideUnderwayWarmCampDesc =>
      'Skupina potřebuje sílu na cestu — splň dnes spánek, protein i kalorie.';

  @override
  String get progSideUnderwayLongWatchTitle => 'Dlouhá hlídka';

  @override
  String get progSideUnderwayLongWatchDesc =>
      'Drž tempo i v noci — splň dnes kroky, aktivitu i spánek.';

  @override
  String get progSideFrostboundFirstLightTitle => 'První světlo přísahy';

  @override
  String get progSideFrostboundFirstLightDesc =>
      'Vyraz dřív, než mráz polkne stopy — splň dnes kroky i aktivní minuty.';

  @override
  String get progSideFrostboundLongOathTitle => 'Dlouhá přísaha';

  @override
  String get progSideFrostboundLongOathDesc =>
      'Mráz prověřuje celé tělo — splň dnes kroky, spánek, protein i kalorie.';

  @override
  String get progSideIcewalkerDawnMarchTitle => 'Pochod úsvitem';

  @override
  String get progSideIcewalkerDawnMarchDesc =>
      'Ledem se kráčí brzy — splň dnes kroky, aktivitu i kalorie.';

  @override
  String get progSideIcewalkerProvisionerTitle => 'Zásobovač';

  @override
  String get progSideIcewalkerProvisionerDesc =>
      'Karavana musí jíst kompletně — splň dnes všech pět nutričních cílů.';

  @override
  String get progSideMountainSteepMorningTitle => 'Strmé ráno';

  @override
  String get progSideMountainSteepMorningDesc =>
      'Hřeben se neleze v poledne — splň dnes kroky, aktivitu i spánek.';

  @override
  String get progSideMountainFullRidgeTitle => 'Plný hřeben';

  @override
  String get progSideMountainFullRidgeDesc =>
      'Vrchol vyžaduje celého tebe — splň dnes kroky, aktivitu, spánek, protein i kalorie.';

  @override
  String get progSideDragonroadWardenDawnTitle => 'Strážcovo úsvití';

  @override
  String get progSideDragonroadWardenDawnDesc =>
      'Dračí cesta zkouší disciplínu — splň dnes čtyři ze základů (kroky, aktivita, kalorie, protein).';

  @override
  String get progSideDragonroadIronAppetiteTitle => 'Dračí apetit';

  @override
  String get progSideDragonroadIronAppetiteDesc =>
      'Drak jí pět chodů — splň dnes všech pět nutričních cílů.';

  @override
  String get progSideDragonrockSovereignDawnTitle => 'Trůnní svítání';

  @override
  String get progSideDragonrockSovereignDawnDesc =>
      'Vládce nikdy nehladoví — splň dnes kroky a všechny čtyři makro cíle.';

  @override
  String get progSideDragonrockSovereignVigilTitle => 'Vigilie panovníka';

  @override
  String get progSideDragonrockSovereignVigilDesc =>
      'Pečuješ o celé království sebe sama — splň dnes šest z osmi denních cílů.';

  @override
  String get progSideIcewalkerFinaleTitle => 'Posádka kompletní';

  @override
  String get progSideIcewalkerFinaleDesc =>
      'Karavana stojí pevně, ať mráz dělá co chce — splň dnes šest různých denních cílů.';

  @override
  String get progSideDragonroadFinaleTitle => 'Dračí hodokvas';

  @override
  String get progSideDragonroadFinaleDesc =>
      'Drak požaduje celou tabuli — splň dnes sedm z osmi denních cílů.';

  @override
  String get progSideDragonrockSovereignThroneTitle => 'Trůn Dragonrocku';

  @override
  String get progSideDragonrockSovereignThroneDesc =>
      'Tvůj trůn neuhne — splň dnes sedm denních cílů včetně všech čtyř maker.';

  @override
  String get progSideDragonrockSovereignCrownTitle => 'Koruna nezhasne';

  @override
  String get progSideDragonrockSovereignCrownDesc =>
      'Téměř dokonalý den — splň dnes sedm z osmi denních cílů a podrž tempo až do večera.';

  @override
  String get progSideDragonrockSovereignFinaleTitle => 'Dokonalý den panovníka';

  @override
  String get progSideDragonrockSovereignFinaleDesc =>
      'Vrchol cesty — splň dnes všech osm denních cílů. Bonus za 7+ h spánku i za uzavření před 18:00.';

  @override
  String get progDailyChallengeNutriTripleTitle => 'Trojitá nutri výhra';

  @override
  String get progDailyChallengeNutriTripleDesc =>
      'Splň dnes 3 z 5 nutričních cílů (kalorie, protein, sacharidy, tuky, vláknina).';

  @override
  String get progDailyChallengeActiveDayTitle => 'Aktivní den';

  @override
  String get progDailyChallengeActiveDayDesc =>
      'Splň dnes cíl kroků i aktivních minut.';

  @override
  String get progDailyChallengeFullPlateTitle => 'Plný talíř';

  @override
  String get progDailyChallengeFullPlateDesc =>
      'Splň dnes všech 5 nutričních cílů.';

  @override
  String get progDailyChallengeRecoveryTitle => 'Regenerační den';

  @override
  String get progDailyChallengeRecoveryDesc =>
      'Splň dnes spánek i protein — tělo si zaslouží odpočinek.';

  @override
  String get progDailyChallengeTripleComboTitle => 'Trojkombo';

  @override
  String get progDailyChallengeTripleComboDesc =>
      'Splň dnes kroky, spánek i protein.';

  @override
  String get progDailyChallengeBalancedTitle => 'Vyvážený den';

  @override
  String get progDailyChallengeBalancedDesc =>
      'Splň dnes jakékoli 4 denní cíle z osmi.';

  @override
  String get progQuestsLongTermHeader => 'DLOUHODOBÉ CÍLE';

  @override
  String get progQuestsLongTermAlsoUnlocks => 'Také odemkne';

  @override
  String get progQuestNextStep => 'Další krok';

  @override
  String get progQuestNextStepLocked =>
      'Splň předchozí krok, aby se odemkl další';

  @override
  String get progQuestChainFinaleReward => 'Po dokončení kapitoly';

  @override
  String get cosmeticTypeFrame => 'Rámeček';

  @override
  String get cosmeticTypeRelic => 'Relikvie';

  @override
  String get cosmeticTypeBackground => 'Pozadí';

  @override
  String get cosmeticTypeEmblem => 'Znak';

  @override
  String get cosmeticTypeCompanion => 'Společník';

  @override
  String get cosmeticTypeTitleFlair => 'Titul';

  @override
  String get cosmeticTypeMapEffect => 'Efekt mapy';

  @override
  String get cosmeticTypeSkin => 'Vzhled';

  @override
  String get heroRaceHumanName => 'Človek';

  @override
  String get heroRaceHumanDesc => 'Vytrvalý poutník světa.';

  @override
  String get heroRaceElfName => 'Elf';

  @override
  String get heroRaceElfDesc => 'Tichý strážce lesů a starodávných stezek.';

  @override
  String get heroRaceDwarfName => 'Trpaslík';

  @override
  String get heroRaceDwarfDesc => 'Houževnatý kovář kamenů, mistr hlubin.';

  @override
  String get heroRaceOrcName => 'Skřet';

  @override
  String get heroRaceOrcDesc => 'Divoký bojovník otevřených stepí.';

  @override
  String get heroRaceSpiritName => 'Duch';

  @override
  String get heroRaceSpiritDesc => 'Šepot pradávných lesů, na pomezí světů.';

  @override
  String get heroRaceGolemName => 'Golem';

  @override
  String get heroRaceGolemDesc => 'Probuzený kámen, věčný strážce.';

  @override
  String get cosmeticSkinPilgrimName => 'Plášť poutníka';

  @override
  String get cosmeticSkinPilgrimDesc =>
      'Skromné šaty toho, kdo právě vyšel na cestu.';

  @override
  String get cosmeticSkinPilgrimUnlockHint =>
      'Vyber si rasu při úvodu — podoba zvolená na začátku cesty.';

  @override
  String get cosmeticSkinHunterName => 'Lovecká kůže';

  @override
  String get cosmeticSkinHunterDesc =>
      'Lehká kůže a tichý luk — divoký les nejdřív naučí trpělivosti, teprve pak dá zvěř.';

  @override
  String get cosmeticSkinHunterUnlockHint =>
      'Dosáhni úrovně 12 — pro toho, kdo se naučil číst les ještě dřív, než ho překročil.';

  @override
  String get cosmeticSkinMineName => 'Trpasličí výstroj';

  @override
  String get cosmeticSkinMineDesc =>
      'Pevná výstroj poznamenaná kamenem a výhní — stavěná pro tmu pod horami.';

  @override
  String get cosmeticSkinMineUnlockHint =>
      'Dosáhni úrovně 42 — nošeno hluboko v trpasličích síních.';

  @override
  String get cosmeticSkinFrostwalkerName => 'Zbroj severu';

  @override
  String get cosmeticSkinFrostwalkerDesc =>
      'Kožešiny, ledový dech, kroky bez zvuku — chlad tě začíná poznávat.';

  @override
  String get cosmeticSkinFrostwalkerUnlockHint =>
      'Dosáhni úrovně 65 — vyslouženo při dlouhém přechodu zmrzlé krajiny.';

  @override
  String get cosmeticSkinMageName => 'Roucho sigilů';

  @override
  String get cosmeticSkinMageDesc =>
      'Roucho šité sigily a tichá hůl — svět kolem tebe teď zní o něco hlasitěji.';

  @override
  String get cosmeticSkinMageUnlockHint =>
      'Dosáhni úrovně 85 — získáno těmi, kdo studovali staré vzorce déle než ostatní.';

  @override
  String get cosmeticSkinDragonrockName => 'Zbroj z obsidiánu';

  @override
  String get cosmeticSkinDragonrockDesc =>
      'Pláty z obsidiánu a žhavých uhlíků, poznamenané pevností — co přijde po tomhle, se už nepředstavuje.';

  @override
  String get cosmeticSkinDragonrockUnlockHint =>
      'Dosáhni úrovně 95 — ukováno u bran pevnosti Dračí skály.';

  @override
  String get cosmeticSkinOathboundName => 'Brnění přísahy';

  @override
  String get cosmeticSkinOathboundDesc =>
      'Brnění svázané slibem — každý plát nese závazek dodržený přes dlouhé cesty a temné brány.';

  @override
  String get cosmeticSkinOathboundUnlockHint =>
      'Dosáhni úrovně 30 — přísaha cestě, znamení hlubin.';

  @override
  String get cosmeticSkinExtraName => 'Vypůjčená legenda';

  @override
  String get cosmeticSkinExtraDesc =>
      'Vzhled jen pro vývojáře: ozvěny hrdinů z jiných ság — tvá rasa vkročí do vypůjčené siluety. Udělit přes DevTools.';

  @override
  String get forcePickRaceHeader => 'JEŠTĚ JEDEN KROK';

  @override
  String get forcePickRaceTitle => 'Vyber si hrdinu';

  @override
  String get forcePickRaceSubtitle =>
      'Tvoje cesta začala dřív, než hrdinové měli tvář. Vyber si teď svou rasu — tahle podoba tě bude provázet dál.';

  @override
  String get forcePickRaceCta => 'Potvrdit volbu';

  @override
  String get forcePickRaceCtaBusy => 'Ukládám…';

  @override
  String get forcePickRaceCommitFailed =>
      'Nepodařilo se uložit volbu. Zkus to prosím znovu.';

  @override
  String get progQuestsChapterWaitingHeader => 'PŘIPRAVENÉ KAPITOLY';

  @override
  String get progQuestsChapterWaitingTitle => 'Kapitola odemčena';

  @override
  String get progQuestsChapterWaitingCaption =>
      'Dokonči předchozí kapitolu, abys mohl začít.';

  @override
  String get progQuestsLockedHeader => 'ZAMČENO';

  @override
  String get progQuestsCompletedHeader => 'DOKONČENÉ ÚKOLY';

  @override
  String progQuestsCompletedCount(int count) {
    return '$count dokončených';
  }

  @override
  String get progQuestsEmptyActiveTitle => 'Žádné aktivní úkoly.';

  @override
  String get progQuestsEmptyActiveCaption =>
      'Prošel jsi aktuální katalog úkolů.';

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
  String get progQuestStatusClaimed => 'Splněno';

  @override
  String get progBackfillSectionLabel => 'Historie odměn';

  @override
  String get progBackfillEmptyTitle => 'Zatím nic nezaznamenáno';

  @override
  String get progBackfillEmptyCaption =>
      'Jakmile začneš zaznamenávat kroky, spánek nebo tréninky, denní odměny se objeví zde.';

  @override
  String progBackfillPendingChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count k vyzvednutí',
      few: '$count k vyzvednutí',
      one: '$count k vyzvednutí',
    );
    return '$_temp0';
  }

  @override
  String get progBackfillDayHeaderToday => 'Dnes';

  @override
  String get progBackfillDayHeaderYesterday => 'Včera';

  @override
  String get progBackfillGroupThisWeek => 'Tento týden';

  @override
  String get progBackfillGroupLastWeek => 'Minulý týden';

  @override
  String progBackfillGroupWeeksAgo(int weeks) {
    return 'Před $weeks týdny';
  }

  @override
  String get progBackfillGroupMonthAgo => 'Před měsícem';

  @override
  String progBackfillGroupMonthsAgo(int months) {
    return 'Před $months měsíci';
  }

  @override
  String progBackfillClaimAllDay(int xp) {
    return 'Vyzvednout vše · +$xp XP';
  }

  @override
  String progBackfillClaimedToast(int count, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vyzvednuto $count odměn · +$xp XP',
      few: 'Vyzvednuty $count odměny · +$xp XP',
      one: 'Vyzvednuta $count odměna · +$xp XP',
    );
    return '$_temp0';
  }

  @override
  String progBackfillShowMore(int count) {
    return 'Zobrazit dalších $count dní';
  }

  @override
  String progBackfillShowAllSinceJoin(String date) {
    return 'Zobrazit vše od $date';
  }

  @override
  String get progBackfillGoalUnmet => 'Nesplněno';

  @override
  String get progBackfillGoalNoData => 'Bez záznamu';

  @override
  String get progDailyQuestCompletedTodayBadge =>
      'Hotovo pro dnešek · vrátí se zítra';

  @override
  String get progBackfillDayGoalsLabel => 'Cíle';

  @override
  String get progBackfillDayQuestsLabel => 'Úkoly';

  @override
  String get progBackfillDayActivitiesLabel => 'Tréninky';

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
  String progXpFlatDetail(int xp) {
    return 'Odměna: +$xp XP';
  }

  @override
  String progXpScalingDetail(int baseXp, int previewXp) {
    return 'Odměna: +$baseXp XP základ · po přepočtu na tvůj level +$previewXp XP';
  }

  @override
  String progStreakBestDetail(int days) {
    return 'Nejlepší série: $days dní';
  }

  @override
  String progChapterLockedLabel(int level) {
    return 'Lv $level';
  }

  @override
  String get progChapterLockedSoon => 'Brzy se odemkne';

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
  String get progRuleDailyStepsDesc => 'Splň nastavený denní cíl kroků.';

  @override
  String get progRuleDailyStepsHintedDesc => 'Splň nastavený denní cíl kroků.';

  @override
  String get progRuleDailyCaloriesHintedDesc =>
      'Splň nastavený denní cíl kalorií.';

  @override
  String get progRuleDailyActivityHintedDesc =>
      'Splň nastavený týdenní cíl aktivních minut.';

  @override
  String progBonusXpBeforeHour(int xp, int hour) {
    return '+$xp XP bonus, pokud vyzvedneš do $hour:00';
  }

  @override
  String progBonusXpSleepAtLeast(int xp, int minutes) {
    return '+$xp XP bonus, pokud jsi spal alespoň $minutes min';
  }

  @override
  String get progBonusXpLabel => 'Bonus XP';

  @override
  String get progRuleDailyCalories => 'Kalorický cíl';

  @override
  String get progRuleDailyCaloriesDesc =>
      'Zůstaň ve výchozím 10% rozmezí kalorického cíle.';

  @override
  String get progRuleDailyProtein => 'Cíl bílkovin';

  @override
  String get progRuleDailyProteinDesc => 'Splň nastavený denní cíl bílkovin.';

  @override
  String get progRuleDailyCarbs => 'Cíl sacharidů';

  @override
  String get progRuleDailyCarbsDesc => 'Splň nastavený denní cíl sacharidů.';

  @override
  String get progRuleDailyFat => 'Cíl tuků';

  @override
  String get progRuleDailyFatDesc => 'Splň nastavený denní cíl tuků.';

  @override
  String get progRuleDailyFiber => 'Cíl vlákniny';

  @override
  String get progRuleDailyFiberDesc => 'Splň nastavený denní cíl vlákniny.';

  @override
  String get progRuleDailySleep => 'Cíl spánku';

  @override
  String get progRuleDailySleepDesc =>
      'Splň nastavený cíl délky nočního spánku.';

  @override
  String get progRuleWeeklyActivity => 'Týdenní aktivita';

  @override
  String get progRuleWeeklyActivityDesc =>
      'Nasbírej nastavené týdenní minuty aktivity.';

  @override
  String get progRuleWeeklySteps => 'Týdenní kroky';

  @override
  String get progRuleWeeklyStepsDesc =>
      'Splň denní cíl kroků celý týden — sedminásobek denního cíle.';

  @override
  String get progRuleWeeklySleep => 'Týdenní spánek';

  @override
  String get progRuleWeeklySleepDesc =>
      'Prospi celý týden ve formě — nasbírej sedm nocí v cíli spánku.';

  @override
  String get progRuleDailyWeightLog => 'Záznam váhy';

  @override
  String get progRuleDailyWeightLogDesc =>
      'Zaznamenej dnes váhu alespoň jednou.';

  @override
  String get progRuleDailyWeightGoal => 'Cílová váha';

  @override
  String get progRuleDailyWeightGoalDesc =>
      'Zaznamenej váhu v rozmezí 3 % od cílové váhy.';

  @override
  String progRewardDetailWeightLogged(String actual) {
    return 'Zaznamenáno: $actual kg';
  }

  @override
  String get progQuestFallbackTitle => 'Quest';

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
  String get progComboBalancedStep1Title => 'Vyvážený den · 1 cíl';

  @override
  String get progComboBalancedStep1Desc => 'Splň dnes jakýkoli 1 denní cíl.';

  @override
  String get progComboBalancedStep2Title => 'Vyvážený den · 2 cíle';

  @override
  String get progComboBalancedStep2Desc => 'Splň dnes jakékoli 2 denní cíle.';

  @override
  String get progComboBalancedStep3Title => 'Vyvážený den · 3 cíle';

  @override
  String get progComboBalancedStep3Desc => 'Splň dnes jakékoli 3 denní cíle.';

  @override
  String get progComboBalancedFinaleTitle => 'Vyvážený den · finále';

  @override
  String get progComboBalancedFinaleDesc => 'Splň dnes jakékoli 4 denní cíle.';

  @override
  String get progComboRecoveryStep1Title => 'Regenerace · spánek';

  @override
  String get progComboRecoveryStep1Desc => 'Splň dnes cíl spánku.';

  @override
  String get progComboRecoveryStep2Title => 'Regenerace · spánek + kroky';

  @override
  String get progComboRecoveryStep2Desc => 'Splň dnes cíl spánku a kroků.';

  @override
  String get progComboRecoveryStep3Title =>
      'Regenerace · spánek + kroky + protein';

  @override
  String get progComboRecoveryStep3Desc => 'Splň dnes spánek, kroky a protein.';

  @override
  String get progComboRecoveryFinaleTitle => 'Regenerace · finále';

  @override
  String get progComboRecoveryFinaleDesc =>
      'Splň dnes spánek, kroky, protein a kalorie.';

  @override
  String get progComboNutritionStep1Title => 'Nutriční mistr · kalorie';

  @override
  String get progComboNutritionStep1Desc => 'Splň dnes kalorický cíl.';

  @override
  String get progComboNutritionStep2Title => 'Nutriční mistr · + protein';

  @override
  String get progComboNutritionStep2Desc => 'Splň dnes kalorie a protein.';

  @override
  String get progComboNutritionStep3Title => 'Nutriční mistr · + sacharidy';

  @override
  String get progComboNutritionStep3Desc =>
      'Splň dnes kalorie, protein a sacharidy.';

  @override
  String get progComboNutritionStep4Title => 'Nutriční mistr · + tuky';

  @override
  String get progComboNutritionStep4Desc =>
      'Splň dnes kalorie, protein, sacharidy a tuky.';

  @override
  String get progComboNutritionFinaleTitle => 'Nutriční mistr · finále';

  @override
  String get progComboNutritionFinaleDesc =>
      'Splň dnes všechny makro cíle: kalorie, protein, sacharidy, tuky a vlákninu.';

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
  String get progQuestChainStepStart => 'Start';

  @override
  String get progQuestChainStepEmblem => 'Emblém';

  @override
  String get progQuestSourceForestTrial => 'Lesní zkouška';

  @override
  String get progQuestSourceRuinsDiscipline => 'Ruiny disciplíny';

  @override
  String get progQuestSourceMineDescent => 'Sestup do dolu';

  @override
  String get progQuestSourceForgeMomentum => 'Výheň tempa';

  @override
  String get progQuestSourceUnderwayPact => 'Podzemní pakt';

  @override
  String get progQuestSourceFrostboundOath => 'Mrazivá přísaha';

  @override
  String get progQuestSourceIcewalkerRoute => 'Cesta ledoběžce';

  @override
  String get progQuestSourceMountainAscent => 'Výstup na horu';

  @override
  String get progQuestSourceDragonroad => 'Dračí cesta';

  @override
  String get progQuestSourceDragonrockSovereign => 'Vládce Dračí skály';

  @override
  String get progQuestPilgrimPathOpenTitle => 'Stezka poutníka';

  @override
  String get progQuestPilgrimPathOpenDesc =>
      'Vydej se na svou cestu — tvá první kapitola začíná.';

  @override
  String get progQuestPilgrimPathWarmupTitle => 'Denní rozcvička';

  @override
  String get progQuestPilgrimPathWarmupDesc =>
      'Splň alespoň 2 denní cíle ve 2 různých dnech a nauč se rytmus.';

  @override
  String get progQuestPilgrimPathStepsBuilderTitle => 'Krok za krokem';

  @override
  String get progQuestPilgrimPathStepsBuilderDesc => 'Splň krokový cíl 3×.';

  @override
  String get progQuestPilgrimPathRhythmTitle => 'Kroky i spánek';

  @override
  String get progQuestPilgrimPathRhythmDesc =>
      'Splň krokový i spánkový cíl ve stejný den — dvakrát.';

  @override
  String get progQuestPilgrimPathFinaleTitle => 'Znak poutníka';

  @override
  String get progQuestPilgrimPathFinaleDesc =>
      'Najdi rytmus chůze i odpočinku a získej Znak poutníka.';

  @override
  String get progChapterHintHeader => 'Chybí';

  @override
  String progChapterHintReachLevel(int level) {
    return 'Dosáhni úrovně $level';
  }

  @override
  String progChapterHintFinishChapter(String chapter) {
    return 'Dokonči $chapter';
  }

  @override
  String get progChapterHintGeneric => 'Odemkni další část cesty';

  @override
  String get progQuestForestTrialOpenTitle => 'Lesní zkouška';

  @override
  String get progQuestForestTrialOpenDesc =>
      'Odemkni Lesní zkoušku dosažením 10. úrovně.';

  @override
  String get progQuestForestTrialDailyWins5Title => 'Rytmus stezky';

  @override
  String get progQuestForestTrialDailyWins5Desc =>
      'Na Lesní stezce splň alespoň 2 denní cíle v 5 různých dnech.';

  @override
  String get progQuestForestTrialSteps5Title => 'Pět dní na cestě';

  @override
  String get progQuestForestTrialSteps5Desc =>
      'Na Lesní stezce splň krokový cíl 5krát.';

  @override
  String get progQuestForestTrialRecovery3Title => 'Odpočinek pod stromy';

  @override
  String get progQuestForestTrialRecovery3Desc =>
      'Pod korunami stromů splň cíl kroků i spánku ve stejný den 3krát.';

  @override
  String get progQuestForestTrialFinaleTitle => 'Pečeť lesa';

  @override
  String get progQuestForestTrialFinaleDesc =>
      'Dokonči všechny předchozí úkoly Lesní zkoušky.';

  @override
  String get progQuestRuinsDisciplineOpenTitle => 'Ruiny disciplíny';

  @override
  String get progQuestRuinsDisciplineOpenDesc =>
      'Odemkni Ruiny disciplíny dosažením 20. úrovně.';

  @override
  String get progQuestRuinsDisciplineNutrition7Title => 'Starobylá dávka';

  @override
  String get progQuestRuinsDisciplineNutrition7Desc =>
      'Mezi ruinami splň cíl kalorií i bílkovin 7krát.';

  @override
  String get progQuestRuinsDisciplineWeekly2Title => 'Týdenní obětina';

  @override
  String get progQuestRuinsDisciplineWeekly2Desc =>
      'V Ruinách disciplíny splň týdenní cíl aktivity 2krát.';

  @override
  String get progQuestRuinsDisciplineSteps10Title => 'Deset dní odhodlání';

  @override
  String get progQuestRuinsDisciplineSteps10Desc =>
      'Mezi ruinami splň krokový cíl 10krát.';

  @override
  String get progQuestRuinsDisciplineFinaleTitle => 'Pečeť ruin';

  @override
  String get progQuestRuinsDisciplineFinaleDesc =>
      'Dokonči všechny předchozí úkoly Ruin disciplíny.';

  @override
  String get progQuestMineDescentOpenTitle => 'Sestup do dolů';

  @override
  String get progQuestMineDescentOpenDesc =>
      'Odemkni Sestup do dolů dosažením 30. úrovně.';

  @override
  String get progQuestMineDescentSteps250kTitle => 'Hluboké cesty';

  @override
  String get progQuestMineDescentSteps250kDesc =>
      'V hlubinách dolů ujdi 250 000 kroků.';

  @override
  String get progQuestMineDescentActivityRewards12Title => 'Pracovní příkazy';

  @override
  String get progQuestMineDescentActivityRewards12Desc =>
      'V hlubinách dolů získej 12 odměn za aktivitu.';

  @override
  String get progQuestMineDescentProtein10Title => 'Železné příděly';

  @override
  String get progQuestMineDescentProtein10Desc =>
      'V hlubinách dolů splň cíl bílkovin 10krát.';

  @override
  String get progQuestMineDescentFinaleTitle => 'Pečeť dolů';

  @override
  String get progQuestMineDescentFinaleDesc =>
      'Dokonči všechny předchozí úkoly Sestupu do dolů.';

  @override
  String get progQuestForgeMomentumOpenTitle => 'Výheň tempa';

  @override
  String get progQuestForgeMomentumOpenDesc =>
      'Odemkni Výheň tempa dosažením 40. úrovně.';

  @override
  String get progQuestForgeMomentumWeekly4Title => 'Rozpal výheň';

  @override
  String get progQuestForgeMomentumWeekly4Desc =>
      'Ve Výhni tempa splň týdenní cíl aktivity 4krát.';

  @override
  String get progQuestForgeMomentumSteps20Title => 'Kladivové kroky';

  @override
  String get progQuestForgeMomentumSteps20Desc =>
      'Ve Výhni tempa splň krokový cíl 20krát.';

  @override
  String get progQuestForgeMomentumNutrition15Title => 'Palivo pro plamen';

  @override
  String get progQuestForgeMomentumNutrition15Desc =>
      'Ve Výhni tempa splň cíl kalorií i bílkovin 15krát.';

  @override
  String get progQuestForgeMomentumFinaleTitle => 'Pečeť výhně';

  @override
  String get progQuestForgeMomentumFinaleDesc =>
      'Dokonči všechny předchozí úkoly Výhně tempa.';

  @override
  String get progQuestUnderwayPactOpenTitle => 'Podzemní pakt';

  @override
  String get progQuestUnderwayPactOpenDesc =>
      'Odemkni Podzemní pakt dosažením 50. úrovně.';

  @override
  String get progQuestUnderwayPactFourPillars5Title => 'Čtyři pilíře v hlubině';

  @override
  String get progQuestUnderwayPactFourPillars5Desc =>
      'V Podzemním paktu splň všechny 4 denní cíle 5krát.';

  @override
  String get progQuestUnderwayPactSleep14Title => 'Hluboký odpočinek';

  @override
  String get progQuestUnderwayPactSleep14Desc =>
      'V podzemí splň cíl spánku 14krát.';

  @override
  String get progQuestUnderwayPactRecovery10Title => 'Kamenná obnova';

  @override
  String get progQuestUnderwayPactRecovery10Desc =>
      'V podzemí splň cíl kroků i spánku ve stejný den 10krát.';

  @override
  String get progQuestUnderwayPactFinaleTitle => 'Pečeť podzemí';

  @override
  String get progQuestUnderwayPactFinaleDesc =>
      'Dokonči všechny předchozí úkoly Podzemního paktu.';

  @override
  String get progQuestFrostboundOathOpenTitle => 'Mrazivá přísaha';

  @override
  String get progQuestFrostboundOathOpenDesc =>
      'Odemkni Mrazivou přísahu dosažením 60. úrovně.';

  @override
  String get progQuestFrostboundOathSteps21Title => 'Zmrzlé odhodlání';

  @override
  String get progQuestFrostboundOathSteps21Desc =>
      'V mrazivých zemích splň krokový cíl 21krát.';

  @override
  String get progQuestFrostboundOathSleep21Title => 'Úkryt ve sněhu';

  @override
  String get progQuestFrostboundOathSleep21Desc =>
      'V mrazivých zemích splň cíl spánku 21krát.';

  @override
  String get progQuestFrostboundOathWeekly6Title => 'Studený pochod';

  @override
  String get progQuestFrostboundOathWeekly6Desc =>
      'V Mrazivé přísaze splň týdenní cíl aktivity 6krát.';

  @override
  String get progQuestFrostboundOathFinaleTitle => 'Pečeť mrazu';

  @override
  String get progQuestFrostboundOathFinaleDesc =>
      'Dokonči všechny předchozí úkoly Mrazivé přísahy.';

  @override
  String get progQuestIcewalkerRouteOpenTitle => 'Cesta ledoběžce';

  @override
  String get progQuestIcewalkerRouteOpenDesc =>
      'Odemkni Cestu ledoběžce dosažením 70. úrovně.';

  @override
  String get progQuestIcewalkerRouteSteps500kTitle => 'Přes bílé pláně';

  @override
  String get progQuestIcewalkerRouteSteps500kDesc =>
      'Přes ledové pláně ujdi 500 000 kroků.';

  @override
  String get progQuestIcewalkerRouteRewards150Title => 'Stopy v ledu';

  @override
  String get progQuestIcewalkerRouteRewards150Desc =>
      'Na Cestě ledoběžce získej 150 odměn.';

  @override
  String get progQuestIcewalkerRouteProtein30Title => 'Zimní příděly';

  @override
  String get progQuestIcewalkerRouteProtein30Desc =>
      'Na Cestě ledoběžce splň cíl bílkovin 30krát.';

  @override
  String get progQuestIcewalkerRouteFinaleTitle => 'Pečeť ledu';

  @override
  String get progQuestIcewalkerRouteFinaleDesc =>
      'Dokonči všechny předchozí úkoly Cesty ledoběžce.';

  @override
  String get progQuestMountainAscentOpenTitle => 'Výstup na horu';

  @override
  String get progQuestMountainAscentOpenDesc =>
      'Odemkni Výstup na horu dosažením 80. úrovně.';

  @override
  String get progQuestMountainAscentFourPillars15Title => 'Tábor nad mraky';

  @override
  String get progQuestMountainAscentFourPillars15Desc =>
      'Nad oblaky splň všechny 4 denní cíle 15krát.';

  @override
  String get progQuestMountainAscentSteps30Title => 'Nepřerušený výstup';

  @override
  String get progQuestMountainAscentSteps30Desc =>
      'Během Výstupu na horu splň krokový cíl 30krát.';

  @override
  String get progQuestMountainAscentWeekly10Title => 'Vrcholová rutina';

  @override
  String get progQuestMountainAscentWeekly10Desc =>
      'Během Výstupu na horu splň týdenní cíl aktivity 10krát.';

  @override
  String get progQuestMountainAscentFinaleTitle => 'Pečeť vrcholu';

  @override
  String get progQuestMountainAscentFinaleDesc =>
      'Dokonči všechny předchozí úkoly Výstupu na horu.';

  @override
  String get progQuestDragonroadOpenTitle => 'Dračí cesta';

  @override
  String get progQuestDragonroadOpenDesc =>
      'Odemkni Dračí cestu dosažením 90. úrovně.';

  @override
  String get progQuestDragonroadRewards250Title => 'Šupiny úsilí';

  @override
  String get progQuestDragonroadRewards250Desc =>
      'Na Dračí cestě získej 250 odměn.';

  @override
  String get progQuestDragonroadFourPillars25Title => 'Dračí disciplína';

  @override
  String get progQuestDragonroadFourPillars25Desc =>
      'Na Dračí cestě splň všechny 4 denní cíle 25krát.';

  @override
  String get progQuestDragonroadWeekly12Title => 'Cesta k pevnosti';

  @override
  String get progQuestDragonroadWeekly12Desc =>
      'Na Dračí cestě splň týdenní cíl aktivity 12krát.';

  @override
  String get progQuestDragonroadFinaleTitle => 'Pečeť draka';

  @override
  String get progQuestDragonroadFinaleDesc =>
      'Dokonči všechny předchozí úkoly Dračí cesty.';

  @override
  String get progQuestDragonrockSovereignOpenTitle => 'Vládce Dragonrocku';

  @override
  String get progQuestDragonrockSovereignOpenDesc =>
      'Odemkni vládu nad Dragonrockem dosažením 100. úrovně.';

  @override
  String get progQuestDragonrockSovereignFourPillars30Title => 'Vláda čtyř';

  @override
  String get progQuestDragonrockSovereignFourPillars30Desc =>
      'V Pevnosti Dragonrock splň všechny 4 denní cíle 30krát.';

  @override
  String get progQuestDragonrockSovereignWeekly16Title => 'Rutina pevnosti';

  @override
  String get progQuestDragonrockSovereignWeekly16Desc =>
      'V Pevnosti Dragonrock splň týdenní cíl aktivity 16krát.';

  @override
  String get progQuestDragonrockSovereignSteps50Title => 'Královský pochod';

  @override
  String get progQuestDragonrockSovereignSteps50Desc =>
      'V Pevnosti Dragonrock splň krokový cíl 50krát.';

  @override
  String get progQuestDragonrockSovereignFinaleTitle => 'Pečeť Dragonrocku';

  @override
  String get progQuestDragonrockSovereignFinaleDesc =>
      'Dokonči všechny předchozí úkoly vlády nad Dragonrockem.';

  @override
  String get progAchievementFirstDailyGoalTitle => 'První denní cíl';

  @override
  String get progAchievementFirstDailyGoalDesc =>
      'Dokonči svůj první denní cíl.';

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
  String get progAchievementXp5000000Title => 'Astrální ozvěna';

  @override
  String get progAchievementXp5000000Desc => 'Nasbírej 5 000 000 XP.';

  @override
  String get progAchievementXp10000000Title => 'Kosmický kovář';

  @override
  String get progAchievementXp10000000Desc => 'Nasbírej 10 000 000 XP.';

  @override
  String get progAchievementXp24000000Title => 'Vrchol říše';

  @override
  String get progAchievementXp24000000Desc =>
      'Nasbírej 24 000 000 XP — strop levelu 100.';

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
  String get progAchievementSteps2500000Title => 'Skalní poutník';

  @override
  String get progAchievementSteps2500000Desc =>
      'Nasbírej celkem 2 500 000 kroků.';

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
  String get progAchievementWeeklyActivity36Title => 'Sezóna polární záře';

  @override
  String get progAchievementWeeklyActivity36Desc =>
      'Splň týdenní cíl aktivity šestatřicetkrát.';

  @override
  String get progAchievementWeeklyActivity52Title => 'Celoroční motor';

  @override
  String get progAchievementWeeklyActivity52Desc =>
      'Splň týdenní cíl aktivity dvaapadesátkrát.';

  @override
  String get progAchievementWeeklyActivity104Title => 'Dvouletý motor';

  @override
  String get progAchievementWeeklyActivity104Desc =>
      'Splň týdenní cíl aktivity 104× (dva celé roky).';

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
  String get progAchievementSleepMonth270hTitle => 'Lunární hibernace';

  @override
  String get progAchievementSleepMonth270hDesc =>
      'Nasbírej 270 hodin spánku v libovolném 30denním okně (9h / noc).';

  @override
  String get progAchievementSleepMonth300hTitle => 'Nekonečný sen';

  @override
  String get progAchievementSleepMonth300hDesc =>
      'Nasbírej 300 hodin spánku v libovolném 30denním okně (10h / noc).';

  @override
  String get progAchievementSleep200d1600hTitle => 'Cyklus sovy';

  @override
  String get progAchievementSleep200d1600hDesc =>
      'Nasbírej 1 600 hodin spánku v libovolném 200denním okně (8h / noc).';

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
  String get progAchievementActiveDays21Title => 'Tři týdny na cestě';

  @override
  String get progAchievementActiveDays21Desc => 'Buď aktivní 21 dní.';

  @override
  String get progAchievementActiveDays90Title => 'Sezóna na cestě';

  @override
  String get progAchievementActiveDays90Desc => 'Buď aktivní 90 dní.';

  @override
  String get progAchievementActiveDays365Title => 'Rok poutníka';

  @override
  String get progAchievementActiveDays365Desc => 'Buď aktivní 365 dní.';

  @override
  String get progAchievementChapterCompletionistTitle => 'Strážce kronik';

  @override
  String get progAchievementChapterCompletionistDesc =>
      'Dokonči všechny hlavní kapitoly cesty.';

  @override
  String get progAchievementWeightLogStreak90Title => 'Pevná váha';

  @override
  String get progAchievementWeightLogStreak90Desc =>
      'Zapiš si váhu 90 dní v řadě.';

  @override
  String get progAchievementNightOwlTitle => 'Noční sova';

  @override
  String get progAchievementNightOwlDesc =>
      'Zaznamenej 30 nocí, které začaly v 1:00 nebo později.';

  @override
  String get progAchievementEarlyBirdTitle => 'Ranní ptáče';

  @override
  String get progAchievementEarlyBirdDesc =>
      'Zaznamenej 30 nocí, které začaly před 22:00.';

  @override
  String get progAchievementSummaryNights => 'nocí';

  @override
  String get progAchievementSummaryInOneDay => 'za 1 den';

  @override
  String get progAchievementSummaryComeback => 'po 7denní pauze';

  @override
  String get progAchievementSummaryComebackDays => 'denní comeback';

  @override
  String get progAchievementMarathonDayTitle => 'Maratonský den';

  @override
  String get progAchievementMarathonDayDesc =>
      'Ujdi 42 195 kroků za jeden den.';

  @override
  String get progAchievementStepsDay100kTitle => 'Sto tisíc kroků';

  @override
  String get progAchievementStepsDay100kDesc =>
      'Ujdi 100 000 kroků za jeden den.';

  @override
  String get progAchievementZeroDayRecoveryTitle => 'Comeback';

  @override
  String get progAchievementZeroDayRecoveryDesc =>
      'Vrať se na cestu po 7denní (nebo delší) pauze.';

  @override
  String get progAchievementComebackStreakTitle => 'Nezlomený návrat';

  @override
  String get progAchievementComebackStreakDesc =>
      'Po 7+denní pauze splň 14 aktivních dní v řadě.';

  @override
  String get progAchievementPerfectMonthTitle => 'Dokonalý měsíc';

  @override
  String get progAchievementPerfectMonthDesc =>
      'Splň všechny denní cíle (kroky, kalorie, protein, spánek, aktivita) 30 dní v řadě.';

  @override
  String get progAchievementPerfectStreak100Title => 'Stodenní svatozář';

  @override
  String get progAchievementPerfectStreak100Desc =>
      'Splň všechny denní cíle (kroky, kalorie, protein, spánek, aktivita) 100 dní v řadě.';

  @override
  String get progAchievementBalancedYearTitle => 'Vyvážený rok';

  @override
  String get progAchievementBalancedYearDesc =>
      'Nasbírej 52 dokonalých týdnů — každý den v týdnu byl dokonalý.';

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
      'Získej 22 000 000 XP, splň 250 úkolů a ujdi 10 000 000 kroků.';

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
  String get devtoolsAccessDeniedTitle => 'Přístup odepřen';

  @override
  String get devtoolsAccessDeniedMessage =>
      'Tato obrazovka je vyhrazena pro vývojáře.';

  @override
  String get devtoolsCopied => 'Zkopírováno';

  @override
  String devtoolsCopiedWithLabel(String label) {
    return '$label zkopírováno';
  }

  @override
  String get devtoolsActionDisabledBadge => 'TODO';

  @override
  String get devtoolsSectionApp => 'Aplikace a přihlášení';

  @override
  String get devtoolsDebugModeLabel => 'Režim ladění';

  @override
  String get devtoolsSectionDb => 'Lokální DB / mezipaměť';

  @override
  String get devtoolsSectionHealthPipeline => 'Pipeline zdraví';

  @override
  String get devtoolsSectionSync => 'Diagnostika synchronizace';

  @override
  String devtoolsSyncLogHeader(int count, int max) {
    return 'Sync log  ($count / $max)';
  }

  @override
  String get devtoolsSectionBackground => 'Sync na pozadí';

  @override
  String get devtoolsBackgroundReregisterTitle =>
      'Znovu zaregistrovat sync na pozadí?';

  @override
  String get devtoolsBackgroundClearLogTitle => 'Vymazat sync log?';

  @override
  String get devtoolsSectionNotifications => 'Notifikace';

  @override
  String get devtoolsNotificationsBgToggleLabel =>
      'Povolit ladicí notifikace BG syncu';

  @override
  String get devtoolsNotificationsCopyTokenTitle => 'Zkopírovat FCM token?';

  @override
  String get devtoolsNotificationsSendTestTitle =>
      'Odeslat testovací notifikaci?';

  @override
  String get devtoolsSectionUi => 'UI / propagace providerů';

  @override
  String get devtoolsSectionOverrides => 'Ladicí přepisy metrik';

  @override
  String get devtoolsOverridesHint =>
      'Přepisy se aplikují na dnešní hodnotu napříč aplikací (energetická bilance, vstup do progression, sociální profil). Historie zůstává nedotčená. Vymaž vše pro návrat k živým datům.';

  @override
  String get devtoolsOverridesClearTitle => 'Vymazat ladicí přepisy?';

  @override
  String get devtoolsOverridesClearMessage =>
      'Všechny uložené přepisy metrik budou odstraněny.';

  @override
  String get devtoolsOverridesClearConfirm => 'Vymazat';

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
  String get journeyRewardLockedLabel => 'Odměna';

  @override
  String get journeyLockedTitle => 'Zamčeno';

  @override
  String journeyRequiredXp(Object xp) {
    return 'Potřebné XP: $xp';
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
  String get progEmblemSlotMilestoneTitle1 => 'Insignie I';

  @override
  String get progEmblemSlotMilestoneTitle2 => 'Insignie II';

  @override
  String get progEmblemSlotMilestoneTitle3 => 'Insignie III';

  @override
  String get progEmblemSlotMilestoneTitle4 => 'Insignie IV';

  @override
  String get progEmblemSlotMilestoneTitle5 => 'Insignie V';

  @override
  String get progEmblemSlotMilestoneTitle6 => 'Insignie VI';

  @override
  String progEmblemSlotMilestoneDesc(int slot) {
    return 'Odemkne $slot. místo na štítu emblémů v profilu.';
  }

  @override
  String get celebrationEmblemSlotEyebrow => 'NOVÝ SLOT ODEMČEN';

  @override
  String get celebrationEmblemSlotTitle => 'Odemčen nový slot pro emblém!';

  @override
  String celebrationEmblemSlotDescription(int level) {
    return 'Dosažením levelu $level se ti otevřel další slot na štítu emblémů. Otevři svůj profil a vyber si, který emblém v něm vystavíš.';
  }

  @override
  String get celebrationEmblemSlotRewardName => 'Slot na emblém';

  @override
  String celebrationEmblemSlotRewardSub(int slot, int total) {
    return 'Slot $slot z $total';
  }

  @override
  String get cosmeticBannerPilgrimName => 'Poutnický banner';

  @override
  String get cosmeticBannerPilgrimDesc =>
      'Otlučená železná destička, kterou si nese každý, kdo poprvé vykročí na cestu.';

  @override
  String get cosmeticBannerForestName => 'Lesní banner';

  @override
  String get cosmeticBannerForestDesc =>
      'Mechový bronz a lesní zeleň pro ty, kteří se naučili stezky hvozdu.';

  @override
  String get cosmeticBannerRuinsName => 'Banner ruin';

  @override
  String get cosmeticBannerRuinsDesc =>
      'Popraskané zdivo a plazivý mech připomínají tiché ruiny nad průsmykem.';

  @override
  String get cosmeticBannerMineName => 'Banner starých bran';

  @override
  String get cosmeticBannerMineDesc =>
      'Bronzový klíčový kámen opuštěných důlních bran — znak sestupu pod horu.';

  @override
  String get cosmeticBannerFrostName => 'Mrazový banner';

  @override
  String get cosmeticBannerFrostDesc =>
      'Ledová ocel se závojem fialového jíní — barvy zamrzlých podzemních cest.';

  @override
  String get cosmeticBannerMountainName => 'Horský banner';

  @override
  String get cosmeticBannerMountainDesc =>
      'Pozlacené hřebeny a bouřkové černě pro jezdce, který vyzval vrcholky.';

  @override
  String get cosmeticBannerDragonrockName => 'Banner dračí skály';

  @override
  String get cosmeticBannerDragonrockDesc =>
      'Obsidián protkaný žhavými žilkami, vykovaný u paty Dračí skály.';

  @override
  String get cosmeticFramePilgrimName => 'Poutnický rámeček';

  @override
  String get cosmeticFramePilgrimDesc =>
      'Prostý dřevěný rámeček pro každého, kdo se vydal na cestu.';

  @override
  String get cosmeticFrameWildwoodName => 'Rámeček hvozdu';

  @override
  String get cosmeticFrameWildwoodDesc =>
      'Tmavé dřevo a jemné lesní rytiny pro ty, kteří se naučili číst stezky hvozdu.';

  @override
  String get cosmeticFrameRuinsName => 'Rámeček ruin';

  @override
  String get cosmeticFrameRuinsDesc =>
      'Popraskané zdivo a plíživý mech připomínají tiché ruiny na okraji průsmyku.';

  @override
  String get cosmeticFrameDwarvenName => 'Rámeček starých bran';

  @override
  String get cosmeticFrameDwarvenDesc =>
      'Zvětralý kámen a zašlý bronz z průsmyku, kde se stezka mění v ruiny.';

  @override
  String get cosmeticFrameUnderwaysName => 'Trpasličí rám';

  @override
  String get cosmeticFrameUnderwaysDesc =>
      'Pevný rám z kovaného kovu a důlního kamene, vyrobený v hlubinách trpasličích síní.';

  @override
  String get cosmeticFrameFrostName => 'Mrazový rám';

  @override
  String get cosmeticFrameFrostDesc =>
      'Chladný stříbrný rám s ledovým leskem, zrozený v tichu zamrzlé země.';

  @override
  String get cosmeticFrameMountainName => 'Rám horského vyzyvatele';

  @override
  String get cosmeticFrameMountainDesc =>
      'Temný horský kámen a černěná ocel pro ty, kteří vystoupali k cestě na pevnost.';

  @override
  String get cosmeticFrameDragonrockName => 'Rám dračí skály';

  @override
  String get cosmeticFrameDragonrockDesc =>
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
  String get cosmeticCompanionDevOnlyDesc =>
      'Vývojářský společník. Grant přes DevTools.';

  @override
  String get cosmeticCompanionMonsterEnergyName => 'Monster Energy';

  @override
  String get cosmeticCompanionMonsterEnergyDesc =>
      'Mythická plechovka kofeinového kapitalismu. +13 % XP za aktivitu — kofein kope jen do nohou. A když se v jídelníčku objeví cokoli s „monster“ v názvu, v plechovce něco cinkne.';

  @override
  String get dialogClose => 'Zavřít';

  @override
  String get devGrant => 'Grant';

  @override
  String get devRevoke => 'Revoke';

  @override
  String get cosmeticEquip => 'Vybavit';

  @override
  String get cosmeticUnequip => 'Odebrat z výbavy';

  @override
  String get cosmeticEmblemNoFreeSlot =>
      'Žádné volné místo. Nejdřív některý emblém odebereš nebo si odemkneš další slot vyšším levelem.';

  @override
  String get cosmeticNoAsset => 'NO ASSET';

  @override
  String get cosmeticRequirementsHeader => 'PODMÍNKY';

  @override
  String get listOrSeparator => '— nebo —';

  @override
  String get debugDetailsHeader => 'DETAILY LADĚNÍ';

  @override
  String get debugRowId => 'id';

  @override
  String get debugRowType => 'typ';

  @override
  String get debugRowRarity => 'rarita';

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
  String get debugMissing => '— chybí';

  @override
  String ruleSource(String type, String id) {
    return 'source: $type / $id';
  }

  @override
  String get cosmeticUnlockConditionsHeader => 'PODMÍNKY ODEMČENÍ';

  @override
  String copiedToClipboard(String value) {
    return 'Zkopírováno: $value';
  }

  @override
  String cosmeticUnlockedAt(String date) {
    return 'Odemčeno $date';
  }

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
      'Pokroucený kořen z hvozdu, znak prvního zdolaného týdne aktivity.';

  @override
  String get cosmeticRelicRavineStoneName => 'Kámen rokle';

  @override
  String get cosmeticRelicRavineStoneDesc =>
      'Těžký kámen, který jsi pronesl přes nespočet tisíc kroků.';

  @override
  String get cosmeticRelicRuinSealName => 'Pečeť starých ruin';

  @override
  String get cosmeticRelicRuinSealDesc =>
      'Vosková pečeť — odměna pro ranní ptáčata i noční sovy.';

  @override
  String get cosmeticRelicBridgeKeyName => 'Klíč visutého mostu';

  @override
  String get cosmeticRelicBridgeKeyDesc =>
      'Železný klíč, který otevírá zámky starých mostních bran.';

  @override
  String get cosmeticRelicMinersLanternName => 'Hornická lucerna';

  @override
  String get cosmeticRelicMinersLanternDesc =>
      'Mosazná lucerna získaná po mnoha trojitých kombo vítězstvích.';

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
  String get cosmeticRelicAuroraThreadName => 'Vlákno polární záře';

  @override
  String get cosmeticRelicAuroraThreadDesc =>
      'Vlákno polární záře utkané z třiceti šesti nepřerušených týdnů.';

  @override
  String get cosmeticRelicFrozenLakeHeartName => 'Srdce ledového jezera';

  @override
  String get cosmeticRelicFrozenLakeHeartDesc =>
      'Modře zářící kámen za sto dokonalých dní v řadě.';

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
      'Talisman spletený z lesních trav a mnoha sezón vytrvalých malých výher.';

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
      'Uhlík, který stále hoří po měsíci dokonalé disciplíny.';

  @override
  String get cosmeticRelicSummitFeatherName => 'Vrcholové pero';

  @override
  String get cosmeticRelicSummitFeatherDesc =>
      'Vítr ho přinese jen těm, co překročili každý práh.';

  @override
  String get cosmeticRelicStormcrestPlumeName => 'Bouřné pero';

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
  String get cosmeticCompanionBridgeGargoyleName => 'Mostní gargoyle';

  @override
  String get cosmeticCompanionBridgeGargoyleDesc =>
      'Mládě kamenného gargoyla, které střeží starý most — pečetní přísaha a železný klíč jsou jeho dary.';

  @override
  String get cosmeticCompanionLanternGolemName => 'Lucernový golem';

  @override
  String get cosmeticCompanionLanternGolemDesc =>
      'Malý kamenný golem s lucernou poblikávající v hrudi.';

  @override
  String get cosmeticCompanionCaveLynxName => 'Jeskynní rys';

  @override
  String get cosmeticCompanionCaveLynxDesc =>
      'Rys ze skalního přechodu, který následuje poutníky nesoucí vůni dávných lesů a roklí.';

  @override
  String get cosmeticCompanionAuroraStagName => 'Polární jelen';

  @override
  String get cosmeticCompanionAuroraStagDesc =>
      'Bílý jelen, jehož paroží protkává živá polární záře — vystupuje na ledové pláni jen těm, kdo nesou srdce jezera.';

  @override
  String get cosmeticCompanionIceWispName => 'Ledový přízrak';

  @override
  String get cosmeticCompanionIceWispDesc =>
      'Bledá jiskra tančící nad zamrzlým jezerem těm, kdo nesou lucernu i ledový střep.';

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
  String emblemBuffPerTarget(int percent, String metric) {
    return 'Bonus: +$percent % XP z $metric';
  }

  @override
  String emblemBuffBlanket(int percent) {
    return 'Bonus: +$percent % XP ze všech denních cílů, na které máš nasazený znak';
  }

  @override
  String get emblemBuffComboTarget => 'kombo questů';

  @override
  String get emblemBuffWeightLogTarget => 'denní zápis váhy';

  @override
  String get emblemBuffBannerSubtitle =>
      'Pasivní bonus, dokud máš znak nasazený na desce.';

  @override
  String get emblemBuffEquippedBadge => 'BUFF';

  @override
  String claimToastEmblemBonus(int amount) {
    return '+$amount XP (znak)';
  }

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
  String cosmeticCompanionLevelBadge(int level) {
    return 'Úr. $level';
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
  String get celebrationAchievementEyebrow => 'Úspěch odemčen';

  @override
  String get celebrationLevelEyebrow => 'Level dosažen';

  @override
  String get celebrationTitleEyebrow => 'Titul odemčen';

  @override
  String get celebrationQuestEyebrow => 'Quest dokončen';

  @override
  String get celebrationStreakEyebrow => 'Streak prodloužen';

  @override
  String get celebrationLocationEyebrow => 'Oblast objevena';

  @override
  String get celebrationChapterEyebrow => 'Kapitola dokončena';

  @override
  String get celebrationChapterUnlockedEyebrow => 'Nová kapitola otevřena';

  @override
  String get celebrationMilestoneEyebrow => 'Milník dosažen';

  @override
  String get celebrationRelicEyebrow => 'Relikvie získána';

  @override
  String get celebrationContentUnlockEyebrow => 'Nová kapitola';

  @override
  String get celebrationCompanionReadyEyebrow => 'Společník připraven';

  @override
  String get celebrationGoalEyebrow => 'Cíl splněn';

  @override
  String get celebrationAchievementPackEyebrow => 'Moment';

  @override
  String celebrationAchievementPackTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odemčeno $count úspěchů',
      few: 'Odemčeny $count úspěchy',
      one: 'Odemčen 1 úspěch',
    );
    return '$_temp0';
  }

  @override
  String get celebrationWelcomeBackEyebrow => 'Vítej zpět';

  @override
  String celebrationWelcomeBackTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Čeká na tebe $count odměn',
      few: 'Čekají na tebe $count odměny',
      one: 'Čeká na tebe $count odměna',
    );
    return '$_temp0';
  }

  @override
  String celebrationCosmeticUnlockedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nových odměn',
      few: '$count nové odměny',
      one: 'Nová odměna',
    );
    return '$_temp0';
  }

  @override
  String get celebrationOrphanRewardHint => 'Odměna z postupu';

  @override
  String get celebrationSummaryHint =>
      'Shrnutí pokroku z poslední synchronizace';

  @override
  String celebrationChapterUnlockedSuffix(String name) {
    return 'Odemčena další kapitola: $name';
  }

  @override
  String get celebrationContinue => 'Pokračovat';

  @override
  String get celebrationOpenInventory => 'Otevřít inventář →';

  @override
  String get celebrationClaimCompanion => 'Vyzvedni společníka →';

  @override
  String get cosmeticCompanionClaimableBadge => 'PŘIPRAVEN';

  @override
  String get cosmeticCompanionClaimableHiddenName => 'Tajemný společník';

  @override
  String get cosmeticCompanionClaimCta => 'Vyzvedni společníka';

  @override
  String get cosmeticCompanionClaimableHint =>
      'Spoj potřebné relikvie a vyvolej svého společníka.';

  @override
  String get cosmeticCompanionCelebrationHint =>
      'Otevři jeho kartu v inventáři a vyzvedni jej.';

  @override
  String get cosmeticCompanionClaimingFlavor => 'Spojuji relikvie…';

  @override
  String get cosmeticCompanionClaimStepRitual => 'Připravuji rituál…';

  @override
  String get cosmeticCompanionClaimStepBinding => 'Spojuji relikvie…';

  @override
  String get cosmeticCompanionClaimStepAwakening => 'Probouzím společníka…';

  @override
  String get cosmeticCompanionClaimRevealSubtitle => 'Tvůj nový společník';

  @override
  String get cosmeticCompanionClaimTapToContinue =>
      'Klepni kdekoliv pro pokračování';

  @override
  String get cosmeticBuffSectionTitle => 'Bonus XP';

  @override
  String questStreakChipDays(int count) {
    return '${count}d';
  }

  @override
  String questStreakChipWithBonus(int count, int percent) {
    return '${count}d · +$percent %';
  }

  @override
  String questStreakChipLocked(int count, int percent, int threshold) {
    return '${count}d · +$percent % od ${threshold}d';
  }

  @override
  String progStreakInfoPlainHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní v řadě',
      few: '$count dny v řadě',
      one: '1 den v řadě',
      zero: 'Žádný streak',
    );
    return '$_temp0';
  }

  @override
  String progStreakInfoLiveHeadline(int count, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Streak $count dní',
      few: 'Streak $count dny',
      one: 'Streak 1 den',
    );
    return '$_temp0 · +$percent % XP';
  }

  @override
  String progStreakInfoLiveNextTier(int percent, int threshold) {
    return '+$percent % od streaku $threshold+ dní';
  }

  @override
  String progStreakInfoLiveBonus(int percent) {
    return '+$percent % XP';
  }

  @override
  String progStreakInfoLiveCap(int percent) {
    return 'Maximální bonus: +$percent % XP';
  }

  @override
  String progStreakInfoLockedHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Streak $count dní · bonus zamčen',
      few: 'Streak $count dny · bonus zamčen',
      one: 'Streak 1 den · bonus zamčen',
      zero: 'Bonus zamčen',
    );
    return '$_temp0';
  }

  @override
  String progStreakInfoLockedSubtitle(int daysToUnlock, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      daysToUnlock,
      locale: localeName,
      other: 'Ještě $daysToUnlock dní',
      few: 'Ještě $daysToUnlock dny',
      one: 'Ještě 1 den',
    );
    return '$_temp0 pro +$percent % XP';
  }

  @override
  String progStreakInfoLegendaryHeadline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Legendární streak — $count dní',
      few: 'Legendární streak — $count dny',
      one: 'Legendární streak — 1 den',
    );
    return '$_temp0';
  }

  @override
  String progStreakInfoLegendarySubtitle(int percent) {
    return 'Legendární bonus aktivní — +$percent % XP';
  }

  @override
  String progStreakInfoBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '1 den',
    );
    return 'Rekord: $_temp0';
  }

  @override
  String get heroStatsStreakRecordsTitle => 'Streak rekordy';

  @override
  String heroStatsAchievementsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count úspěchů',
      few: '$count úspěchy',
      one: '1 úspěch',
    );
    return '$_temp0';
  }

  @override
  String get heroStatsDomainColumn => 'Doména';

  @override
  String get heroStatsCurrentColumn => 'Aktuální';

  @override
  String get heroStatsBestColumn => 'Rekord';

  @override
  String heroStatsStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}d',
      one: '1d',
      zero: '0d',
    );
    return '$_temp0';
  }

  @override
  String cosmeticBuffFlat(int percent, String source) {
    return '+$percent % XP $source';
  }

  @override
  String cosmeticBuffEmber(int min, int max) {
    return '+$min–$max % za streak';
  }

  @override
  String cosmeticBuffLanternThreshold(int percent, int days) {
    return '+$percent % za streak ${days}d+';
  }

  @override
  String cosmeticBuffRaven(int daily, int weekly) {
    return '+$daily % XP za denní quest a +$weekly % XP za týdenní';
  }

  @override
  String cosmeticBuffLynx(int opener, int deep) {
    return '+$opener–$deep % XP za chapter questy';
  }

  @override
  String get cosmeticBuffSourceActivityXp => 'za aktivity';

  @override
  String get cosmeticBuffSourceNutritionXp => 'za výživu';

  @override
  String get cosmeticBuffSourceSleepXp => 'za spánek';

  @override
  String get cosmeticBuffSourceBodyXp => 'za vážení';

  @override
  String get cosmeticBuffSourceStreakXp => 'za streak';

  @override
  String get cosmeticBuffSourceQuestXp => 'za denní questy';

  @override
  String get cosmeticBuffSourceChapterXp => 'za chapter questy';

  @override
  String get cosmeticBuffSourceAllXp => 'na vše';

  @override
  String get cosmeticBuffBannerFlatSubtitle =>
      'Pasivní bonus, dokud je společník vybavený';

  @override
  String cosmeticBuffEmberHeadlineLive(int percent) {
    return '+$percent % XP';
  }

  @override
  String cosmeticBuffEmberHeadlineRange(int min, int max) {
    return '+$min → $max % za streak';
  }

  @override
  String cosmeticBuffLanternThresholdHeadline(int percent, int days) {
    return '+$percent % za streak od ${days}d';
  }

  @override
  String cosmeticBuffLanternThresholdSubtitle(int days) {
    return 'Každý z hlavních pěti streaků odemkne bonus, jakmile poprvé překročí ${days}d';
  }

  @override
  String cosmeticBuffLynxHeadlineRange(int opener, int deep) {
    return '+$opener → $deep % XP za chapter questy';
  }

  @override
  String cosmeticBuffEmberSubtitle(int max) {
    return 'Každý hlavní streak roste samostatně (cap +$max %)';
  }

  @override
  String get cosmeticBuffRavenSubtitle =>
      'Větší výplata po dokončení týdenního questu';

  @override
  String cosmeticBuffLynxHeadlineLive(int percent) {
    return '+$percent % XP za chapter questy';
  }

  @override
  String cosmeticBuffLynxSubtitle(int deep) {
    return 'Roste s pozicí v chain řetězci (až +$deep %)';
  }

  @override
  String get cosmeticRelicConsumedBadge => 'Použito';

  @override
  String get cosmeticRelicConsumedHint => 'Použito k vyvolání společníka.';

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
  String get celebrationCloseSemantic => 'Zavřít';

  @override
  String get celebrationTypeAchievement => 'Úspěch';

  @override
  String get celebrationTypeQuest => 'Quest';

  @override
  String get celebrationTypeLevel => 'Level';

  @override
  String get celebrationTypeTitle => 'Titul';

  @override
  String get celebrationTypeStreak => 'Streak';

  @override
  String get celebrationTypeLocation => 'Oblast';

  @override
  String get celebrationTypeCosmetic => 'Kosmetika';

  @override
  String get celebrationKindTitle => 'Titul';

  @override
  String get celebrationKindFrame => 'Rámeček';

  @override
  String get celebrationKindBackground => 'Pozadí';

  @override
  String get celebrationKindCompanion => 'Společník';

  @override
  String get celebrationKindSkin => 'Vzhled';

  @override
  String get celebrationKindBadge => 'Odznak';

  @override
  String get celebrationKindGem => 'Relikvie';

  @override
  String get celebrationKindLocation => 'Oblast';

  @override
  String get celebrationKindXp => 'XP odměna';

  @override
  String get celebrationKindFlame => 'Streak';

  @override
  String get celebrationKindFlag => 'Quest';

  @override
  String get celebrationKindSparkle => 'Odměna';

  @override
  String get socialScreenTitle => 'Tví druzi na cestě';

  @override
  String get socialTabFeed => 'Kronika';

  @override
  String get socialTabLeaderboard => 'Žebříček';

  @override
  String get socialTabFriends => 'Přátelé';

  @override
  String get socialSectionFriendActivity => 'AKTIVITA PŘÁTEL';

  @override
  String get socialFeedEmptyTitle => 'Kronika je prázdná';

  @override
  String get socialFeedEmptySubtitle =>
      'Sdílené achievementy přátel se zobrazí zde.';

  @override
  String get socialFriendsEmptyTitle => 'Žádní přátelé';

  @override
  String get socialFriendsEmptySubtitle =>
      'Přidej přátele vyhledáním jejich přezdívky.';

  @override
  String get socialNotificationsTitle => 'Oznámení';

  @override
  String get socialNotificationsEmptyTitle => 'Nic nového';

  @override
  String get socialNotificationsEmptySubtitle =>
      'Žádosti o přátelství a další aktivita ze Společenstva se objeví zde.';

  @override
  String get socialNotificationsReactionsSection => 'Reakce';

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
  String get socialSearchNoResults => 'Zatím nikdo neodpovídá — piš dál.';

  @override
  String get socialSearchOtherPeopleSection => 'Lidé';

  @override
  String get socialAdd => 'Přidat';

  @override
  String get socialFriendBadge => 'Přátelé';

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
      'Přihlášení přes Google je vyžadováno pro Společenstvo.';

  @override
  String socialStatusBackendUnavailable(String error) {
    return 'Firebase backend nedostupný: $error';
  }

  @override
  String get socialStatusConnecting => 'Připojování ke Společenstvu…';

  @override
  String socialStatusError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get socialEditHandleTitle => 'Změnit přezdívku';

  @override
  String get socialEditHandleDescription =>
      'Přezdívka slouží k vyhledání ve Společenstvu.';

  @override
  String get socialEditHandleValidation => 'Zadej alespoň jeden znak.';

  @override
  String get socialCancel => 'Zrušit';

  @override
  String get socialSave => 'Uložit';

  @override
  String get socialEditHandleTooltip => 'Změnit přezdívku';

  @override
  String get socialEditPhotoTooltip => 'Změnit fotku';

  @override
  String socialHandleSaveFailed(String error) {
    return 'Přezdívku se nepodařilo uložit: $error';
  }

  @override
  String socialHandleSaved(String handle) {
    return 'Přezdívka uložena: @$handle';
  }

  @override
  String get socialTryAgain => 'zkus to znovu';

  @override
  String get socialSelectedLoadout => 'Vybraná\nvýbava';

  @override
  String get socialProfilePinnedAchievements => 'PŘIPNUTÉ ACHIEVEMENTY';

  @override
  String get socialProfileSharedPosts => 'SDÍLENÉ PŘÍSPĚVKY';

  @override
  String get profileStatsSectionTitle => 'STATISTIKY';

  @override
  String get profileStatsEdit => 'Upravit';

  @override
  String get profileStatsSave => 'Hotovo';

  @override
  String get profileStatsCancel => 'Zrušit';

  @override
  String get profileStatsHeroTitle => 'Hrdina';

  @override
  String get profileStatsActivityTitle => 'Aktivita';

  @override
  String get profileStatsSleepTitle => 'Spánek';

  @override
  String get profileStatsBodyTitle => 'Tělo';

  @override
  String get profileStatsNutritionTitle => 'Výživa';

  @override
  String get profileStatsSocialTitle => 'Společenství';

  @override
  String get profileStatLevel => 'Úroveň';

  @override
  String get profileStatTotalXp => 'Celkem XP';

  @override
  String get profileStatUnlockedAchievements => 'Achievementy';

  @override
  String get profileStatGrantedRewards => 'Získané odměny';

  @override
  String get profileStatCosmeticsUnlocked => 'Odemčené kosmetiky';

  @override
  String get profileStatDaysOnApp => 'Dnů na výpravě';

  @override
  String get profileStatStepsLifetime => 'Kroky celkem';

  @override
  String get profileStatStepsAvg30d => 'Průměr kroků / den';

  @override
  String get profileStatActiveDays30d => 'Aktivní dny';

  @override
  String get profileStatSleepAvgDuration => 'Průměr spánku';

  @override
  String get profileStatSleepAvgBedtime => 'Průměr usnutí';

  @override
  String get profileStatSleepAvgWakeTime => 'Průměr probuzení';

  @override
  String get profileStatSleepAvgDeep => 'Hluboký spánek';

  @override
  String get profileStatSleepAvgRem => 'REM spánek';

  @override
  String get profileStatLatestWeight => 'Váha';

  @override
  String get profileStatLatestBodyFat => 'Tělesný tuk';

  @override
  String get profileStatAvgKcal => 'Průměr kcal / den';

  @override
  String get profileStatAvgProtein => 'Průměr bílkoviny / den';

  @override
  String get profileStatAvgFat => 'Průměr tuky / den';

  @override
  String get profileStatAvgCarbs => 'Průměr sacharidy / den';

  @override
  String get profileStatFriendsCount => 'Přátelé';

  @override
  String get profileStatSharedPostsCount => 'Sdílené příspěvky';

  @override
  String get profileStatJoinedAt => 'Hrdina od';

  @override
  String get profileStatsOwnerOnlyBadge => 'jen pro mě';

  @override
  String get profileStatsStreakVisibilityShow => 'Zobrazit ostatním';

  @override
  String get profileStatsStreakVisibilityHide => 'Skryté z profilu';

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
  String get socialProfileCosmetics => 'INVENTÁŘ';

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
  String get socialProfileFriendsChipLabel => 'Přátelé';

  @override
  String get socialProfileNoFriends => 'Žádní přátelé zatím.';

  @override
  String get socialSharedPostDelete => 'Odstranit';

  @override
  String get socialSharedPostMoreTooltip => 'Více';

  @override
  String get socialSharedPostDeleteConfirmTitle => 'Odstranit příspěvek';

  @override
  String get socialSharedPostDeleteConfirmBody =>
      'Tento sdílený příspěvek bude odstraněn z kroniky tvých přátel.';

  @override
  String get socialSharedPostDeleted => 'Příspěvek odstraněn.';

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
  String get cosmeticBannerPilgrimUnlockHint => 'Odměna za zahájení cesty.';

  @override
  String get cosmeticBannerForestUnlockHint => 'Dosáhni úrovně 8.';

  @override
  String get cosmeticBannerRuinsUnlockHint => 'Dosáhni úrovně 23.';

  @override
  String get cosmeticBannerMineUnlockHint => 'Dosáhni úrovně 38.';

  @override
  String get cosmeticBannerFrostUnlockHint => 'Dosáhni úrovně 57.';

  @override
  String get cosmeticBannerMountainUnlockHint => 'Dosáhni úrovně 78.';

  @override
  String get cosmeticBannerDragonrockUnlockHint => 'Dosáhni úrovně 98.';

  @override
  String get cosmeticFramePilgrimUnlockHint => 'Odměna za zahájení cesty.';

  @override
  String get cosmeticFrameWildwoodUnlockHint => 'Dosáhni úrovně 10.';

  @override
  String get cosmeticFrameRuinsUnlockHint => 'Dosáhni úrovně 20.';

  @override
  String get cosmeticFrameDwarvenUnlockHint => 'Dosáhni úrovně 25.';

  @override
  String get cosmeticFrameUnderwaysUnlockHint => 'Dosáhni úrovně 40.';

  @override
  String get cosmeticFrameFrostUnlockHint => 'Dosáhni úrovně 60.';

  @override
  String get cosmeticFrameMountainUnlockHint => 'Dosáhni úrovně 80.';

  @override
  String get cosmeticFrameDragonrockUnlockHint => 'Dosáhni úrovně 100.';

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
  String get cosmeticEmblemForestMarkUnlockHint => 'Dokonči Lesní zkoušku.';

  @override
  String get cosmeticEmblemPilgrimMarkUnlockHint => 'Dokonči Stezku poutníka.';

  @override
  String get cosmeticEmblemRuinSigilUnlockHint => 'Dokonči Ruiny disciplíny.';

  @override
  String get cosmeticEmblemGatekeeperMarkUnlockHint =>
      'Dokonči Sestup do dolu.';

  @override
  String get cosmeticEmblemMineCrestUnlockHint => 'Dokonči Výheň tempa.';

  @override
  String get cosmeticEmblemUnderwaysMarkUnlockHint => 'Dokonči Podzemní pakt.';

  @override
  String get cosmeticEmblemFrostSigilUnlockHint => 'Dokonči Mrazivou přísahu.';

  @override
  String get cosmeticEmblemIcewalkerMarkUnlockHint =>
      'Dokonči Cestu ledoběžce.';

  @override
  String get cosmeticEmblemMountainCrestUnlockHint => 'Dokonči Výstup na horu.';

  @override
  String get cosmeticEmblemDragonMarkUnlockHint => 'Dokonči Dračí cestu.';

  @override
  String get cosmeticEmblemDragonrockEmblemUnlockHint =>
      'Dokonči Vládce Dračí skály.';

  @override
  String get cosmeticRelicCampfireSparkUnlockHint =>
      'Dokonči svůj první denní úkol.';

  @override
  String get cosmeticRelicAncientRootUnlockHint =>
      'Splň poprvé týdenní cíl aktivity.';

  @override
  String get cosmeticRelicRavineStoneUnlockHint =>
      'Ujdi celkem 2 500 000 kroků.';

  @override
  String get cosmeticRelicRuinSealUnlockHint =>
      'Staň se ranním ptáčetem, nebo noční sovou.';

  @override
  String get cosmeticRelicBridgeKeyUnlockHint => 'Získej celkem 100 odměn.';

  @override
  String get cosmeticRelicMinersLanternUnlockHint =>
      'Dokonči 25 trojitých kombo úkolů.';

  @override
  String get cosmeticRelicPolarLanternUnlockHint =>
      'Nasbírej celkem 1 000 hodin spánku.';

  @override
  String get cosmeticRelicFrostShardUnlockHint =>
      'Ujdi celkem 5 000 000 kroků.';

  @override
  String get cosmeticRelicAuroraThreadUnlockHint =>
      'Splň týdenní cíl aktivity 36krát.';

  @override
  String get cosmeticRelicFrozenLakeHeartUnlockHint =>
      'Splň 100 dokonalých dní v řadě.';

  @override
  String get cosmeticRelicDragonScaleUnlockHint =>
      'Naspi 1 600 hodin ve 200denním okně.';

  @override
  String get cosmeticRelicWarmKindlingUnlockHint => 'Splň 3 denní úkoly.';

  @override
  String get cosmeticRelicMoonlitFoxgloveUnlockHint => 'Buď aktivní 21 dní.';

  @override
  String get cosmeticRelicWildwoodCharmUnlockHint => 'Buď aktivní 90 dní.';

  @override
  String get cosmeticRelicAshenOmenUnlockHint => 'Splň týdenní aktivitu 4×.';

  @override
  String get cosmeticRelicOathboundMarkUnlockHint =>
      'Ujdi celkem 1 000 000 kroků.';

  @override
  String get cosmeticRelicDeepEmberCoreUnlockHint =>
      'Splň 30 dokonalých dní v řadě.';

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
      'Získej Ruinovou pečeť a Popelové znamení.';

  @override
  String get cosmeticCompanionBridgeGargoyleUnlockHint =>
      'Získej Pečeť přísahy a Klíč mostu.';

  @override
  String get cosmeticCompanionLanternGolemUnlockHint =>
      'Získej Hluboké uhlíkové jádro a Hornickou lucernu.';

  @override
  String get cosmeticCompanionCaveLynxUnlockHint =>
      'Získej Lesní amulet a Kámen rokle.';

  @override
  String get cosmeticCompanionAuroraStagUnlockHint =>
      'Získej Srdce ledového jezera a Vlákno polární záře.';

  @override
  String get cosmeticCompanionIceWispUnlockHint =>
      'Získej Polární lucernu a Ledový střep.';

  @override
  String get cosmeticCompanionMountainGryphonUnlockHint =>
      'Získej Vrcholové a Bouřné peří.';

  @override
  String get cosmeticCompanionDragonlingUnlockHint =>
      'Dosáhni úrovně 95 a získej Dračí šupinu a Srdce dračí skály.';

  @override
  String get coachLogExportTitle => 'Coach Log Export';

  @override
  String get coachLogExportCurrentWeekButton => 'Exportovat aktuální týden';

  @override
  String get coachLogExportRangeButton => 'Exportovat rozsah';

  @override
  String get coachLogExportRunning => 'Exportuje se…';

  @override
  String coachLogExportSuccessWeeks(int count) {
    return 'Exportováno $count týdnů';
  }

  @override
  String get coachLogExportOpenSheets => 'Otevřít v Sheets';

  @override
  String get coachLogExportDescription =>
      'Zapíše týdenní blok coach logu — váhu, kroky, kalorie, makra — do záložky Coach Log ve vaší Forgetrack tabulce.';

  @override
  String get coachLogExportQuickButtonSetting => 'Rychlý export na přehledu';

  @override
  String get coachLogExportQuickButtonSettingSubtitle =>
      'Zobrazí na přehledu tlačítko pro export aktuálního týdne na jedno klepnutí.';

  @override
  String get onboardingTitle => 'Vítej v Forgetracku';

  @override
  String get onboardingSubtitle =>
      'Měř své zdraví, plň cíle a proměň úsilí v XP.';

  @override
  String get onboardingAboutTitle => 'O čem to je';

  @override
  String get onboardingAboutBody =>
      'Forgetrack stahuje kroky, spánek a aktivitu z Health Connectu, synchronizuje výživu z Kalorických Tabulek a denní i týdenní cíle proměňuje v cestu plnou questů, levelů a odměn.';

  @override
  String get onboardingStepsTitle => 'Nastav integrace';

  @override
  String get onboardingStepsHint =>
      'Všechno je volitelné. Cokoli můžeš přeskočit a později připojit nebo změnit v Nastavení.';

  @override
  String get onboardingGoogleTitle => 'Přihlásit přes Google';

  @override
  String get onboardingGoogleBody =>
      'Uloží tvůj progres do cloudu a synchronizuje napříč zařízeními.';

  @override
  String get onboardingGoogleAction => 'Přihlásit';

  @override
  String onboardingGoogleConnected(String email) {
    return 'Přihlášen jako $email';
  }

  @override
  String get onboardingKtTitle => 'Připojit Kalorické Tabulky';

  @override
  String get onboardingKtBody => 'Importuje výživu a váhu z tvého KT deníku.';

  @override
  String onboardingKtConnected(String email) {
    return 'Připojeno jako $email';
  }

  @override
  String get onboardingKtEmailHint => 'E-mail KT';

  @override
  String get onboardingKtPasswordHint => 'Heslo';

  @override
  String get onboardingKtAction => 'Přihlásit';

  @override
  String get onboardingHealthTitle => 'Health Connect';

  @override
  String get onboardingHealthBody =>
      'Povol Forgetracku číst kroky, kalorie, spánek a aktivitu z Health Connectu. Tvoje záznamy zůstávají v Health Connectu — nikdy je nekopírujeme ani neupravujeme.';

  @override
  String get onboardingHealthAction => 'Udělit přístup';

  @override
  String get onboardingHealthConnected => 'Přístup k Health Connectu udělen';

  @override
  String get onboardingSheetsTitle => 'Export do Google Sheets';

  @override
  String get onboardingSheetsBody =>
      'Volitelné: exportuj týdenní souhrny do Google Sheets. Forgetrack zapisuje pouze do tabulek, které sám vytvořil.';

  @override
  String get onboardingSheetsAction => 'Povolit přístup k Sheets';

  @override
  String get onboardingSheetsConnected => 'Přístup k Sheets udělen';

  @override
  String get onboardingNotificationsTitle => 'Notifikace';

  @override
  String get onboardingNotificationsBody =>
      'Denní připomenutí, postup questů a oznámení o odměnách.';

  @override
  String get onboardingNotificationsAction => 'Zapnout';

  @override
  String get onboardingNotificationsConnected => 'Notifikace zapnuté';

  @override
  String get onboardingFooterNote =>
      'Vše můžeš později měnit v Nastavení aplikace.';

  @override
  String get onboardingContinue => 'Pokračovat do aplikace';

  @override
  String get onboardingSkip => 'Přeskočit';

  @override
  String get welcomeSkip => 'Přeskočit';

  @override
  String get welcomeCtaStart => 'Začít cestu';

  @override
  String get welcomeCtaContinue => 'Pokračovat';

  @override
  String get welcomeCtaFinish => 'Vstoupit do hry';

  @override
  String get welcomeStep1Title => 'Vyber si tvář';

  @override
  String get welcomeStep1Subtitle =>
      'Takhle tě uvidí ostatní hráči v žebříčku. Nemůžeš se rozhodnout? Změníš to kdykoliv v profilu.';

  @override
  String get welcomeStep1SubtitleAccent => 'Nemůžeš se rozhodnout?';

  @override
  String get welcomeStep1HeroLabel => 'TVŮJ START';

  @override
  String welcomeStep1HeroXpProgress(int into, int toNext) {
    return '$into / $toNext XP do dalšího levelu';
  }

  @override
  String get welcomeStep1HeroPill => 'LVL 1';

  @override
  String get welcomeStep2Title => 'Ulož si svůj postup';

  @override
  String get welcomeStep2Subtitle =>
      'Přihlas se přes Google a tvé levely, série a achievementy zůstanou bezpečně v cloudu — i když přejdeš na nový telefon.';

  @override
  String get welcomeStep2GoogleSignIn => 'Přihlásit se přes Google';

  @override
  String get welcomeStep2GoogleSignedIn => 'Přihlášen';

  @override
  String welcomeStep2GoogleSignedInAs(String email) {
    return 'Přihlášen jako $email';
  }

  @override
  String get welcomeStep2Benefit1 => 'Synchronizace mezi tvými zařízeními';

  @override
  String get welcomeStep2Benefit2 => 'Zálohovaný postup a achievementy';

  @override
  String get welcomeStep2Benefit3 => 'Funguje i offline';

  @override
  String get welcomeStep2Footnote =>
      'Nemusíš se rozhodovat hned — funguje to i bez účtu.';

  @override
  String get welcomeStep3Title => 'Připoj svoje data';

  @override
  String get welcomeStep3Subtitle =>
      'Forgetrack čte z Health Connectu kroky, spánek a aktivitu — a proměňuje je v XP. Tvoje záznamy z toho ven nejdou; jen se z nich čte.';

  @override
  String get welcomeStep3DataSteps => 'Kroky';

  @override
  String get welcomeStep3DataCalories => 'Kalorie';

  @override
  String get welcomeStep3DataSleep => 'Spánek';

  @override
  String get welcomeStep3DataActivity => 'Aktivita';

  @override
  String get welcomeStep3Cta => 'Povolit Health Connect';

  @override
  String get welcomeStep3CtaConnected => 'Health Connect je propojený';

  @override
  String get welcomeStep3Privacy =>
      'Tvá data zůstávají v Health Connectu — Forgetrack je nikdy nekopíruje ani neupravuje.';

  @override
  String get welcomeStep4Title => 'Poslední doladění';

  @override
  String get welcomeStep4Subtitle =>
      'Volitelné — všechno můžeš nastavit i později v aplikaci.';

  @override
  String get welcomeStep4KtTitle => 'Kalorické Tabulky';

  @override
  String get welcomeStep4KtSubtitle => 'Importovat výživu a váhu z KT deníku';

  @override
  String get welcomeStep4KtConnected => 'Připojeno';

  @override
  String get welcomeStep4NotifTitle => 'Notifikace';

  @override
  String get welcomeStep4NotifSubtitle =>
      'Připomenutí questů a oznámení o odměnách';

  @override
  String get welcomeStep4QuestsLabel => 'PRVNÍ QUESTY';

  @override
  String get welcomeKtSheetTitle => 'Kalorické Tabulky';

  @override
  String get welcomeKtSheetSubtitle => 'Přihlas se ke svému KT účtu';

  @override
  String get welcomeKtSheetEmailHint => 'E-mail KT';

  @override
  String get welcomeKtSheetPasswordHint => 'Heslo';

  @override
  String get welcomeKtSheetSubmit => 'Přihlásit a propojit';

  @override
  String get welcomeKtSheetFootnote =>
      'Forgetrack používá tvé přihlášení jen ke čtení deníku z KT.';

  @override
  String get cosmeticsTabAll => 'Vše';

  @override
  String get cosmeticsEmptyUnlockedTitle => 'Zatím žádná odemčená kosmetika.';

  @override
  String get cosmeticsEmptyUnlockedCaption =>
      'Nové kousky se objeví po splnění úspěchů a milníků.';

  @override
  String get cosmeticsNotSignedInTitle => 'Inventář není dostupný.';

  @override
  String get cosmeticsNotSignedInCaption =>
      'Přihlas se pro přístup ke kosmetice.';

  @override
  String get cosmeticsEquippedSectionLabel => 'Vybaveno';

  @override
  String get cosmeticsEquippedSectionCaption =>
      'Aktuální vzhled profilu a cesty';

  @override
  String get cosmeticsEquippedEmptyTitle => 'Zatím nic není vybavené.';

  @override
  String get cosmeticsEquippedEmptyCaption =>
      'Klepni na odemčenou kosmetiku níže a vyber Vybavit.';

  @override
  String get cosmeticTypeBanner => 'Banner';

  @override
  String get cosmeticTypePluralFrame => 'Rámečky';

  @override
  String get cosmeticTypePluralRelic => 'Relikvie';

  @override
  String get cosmeticTypePluralBackground => 'Pozadí';

  @override
  String get cosmeticTypePluralEmblem => 'Znaky';

  @override
  String get cosmeticTypePluralCompanion => 'Společníci';

  @override
  String get cosmeticTypePluralTitleFlair => 'Tituly';

  @override
  String get cosmeticTypePluralMapEffect => 'Efekty mapy';

  @override
  String get cosmeticTypePluralSkin => 'Vzhledy';

  @override
  String get cosmeticTypePluralBanner => 'Bannery';

  @override
  String get notifChannelProgressionName => 'Postup';

  @override
  String get notifChannelProgressionDescription =>
      'Dokončené questy a odemčené achievementy';

  @override
  String get notifChannelSocialName => 'Společenstvo';

  @override
  String get notifChannelSocialDescription =>
      'Žádosti o přátelství a reakce na příspěvky';

  @override
  String get notifChannelRemindersName => 'Připomínky';

  @override
  String get notifChannelRemindersDescription => 'Denní připomínky cílů';

  @override
  String get notifQuestCompletedTitle => 'Quest dokončen! 🏆';

  @override
  String notifQuestCompletedBody(String questTitle, int xp) {
    return '$questTitle · +$xp XP';
  }

  @override
  String get notifAchievementUnlockedTitle => 'Achievement odemčen! ⚔️';

  @override
  String notifAchievementUnlockedBody(String title, String description) {
    return '$title – $description';
  }

  @override
  String get notifFriendRequestTitle => 'Žádost o přátelství';

  @override
  String notifFriendRequestBody(String name) {
    return '$name ti poslal/a žádost o přátelství';
  }

  @override
  String get notifFriendRequestAcceptedTitle => 'Žádost o přátelství přijata';

  @override
  String notifFriendRequestAcceptedBody(String name) {
    return '$name přijal/a tvoji žádost';
  }

  @override
  String notifReactionTitle(String actor, String emoji) {
    return '$actor reagoval/a $emoji';
  }

  @override
  String get notifGoalReminderTitle => 'Jak jde dnešek? 🎯';

  @override
  String get notifGoalReminderBody => 'Nezapomeň splnit svoje denní cíle';
}
