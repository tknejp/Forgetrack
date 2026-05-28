import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/locale_provider.dart';
import 'core/config/constants.dart';
import 'core/navigation/navigator_key.dart';
import 'core/sentry/sentry_consent_gate.dart';
import 'core/services/app_update_service.dart';
import 'features/app_shell/presentation/main_shell.dart';
import 'features/cosmetics/application/cosmetics_provider.dart';
import 'features/health_connect/application/fitness_provider.dart';
import 'features/nutrition/application/kaloricke_tabulky_provider.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'features/onboarding/presentation/force_pick_race_screen.dart';
import 'features/onboarding/presentation/welcome_screen.dart';
import 'l10n/app_localizations.dart';
import 'shared/theme/app_theme.dart';

/// Neutral splash rendered while the routing gate is waiting on async
/// hydration (`OnboardingProvider` prefs read or `CosmeticsProvider`
/// state load). Keeps the home tree from rendering MainShell — and
/// flashing the Google identity avatar through still-unmigrated
/// thumbnail surfaces — for the ~100-500 ms boot window before the
/// gate can make a final decision.
class _RoutingSplash extends StatelessWidget {
  const _RoutingSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E1C),
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFFA78BFA),
          ),
        ),
      ),
    );
  }
}

class ForgetrackApp extends StatefulWidget {
  const ForgetrackApp({super.key});

  @override
  State<ForgetrackApp> createState() => _ForgetrackAppState();
}

class _ForgetrackAppState extends State<ForgetrackApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        Future.wait([
          context.read<FitnessProvider>().refreshOnAppOpen(),
          context.read<KalorickeTabulkyProvider>().refreshOnAppOpen(),
        ]),
      );
      // No-op on dev/prod. On `internal`, asks FAD whether a newer
      // build is available and surfaces the native install dialog.
      // Intentionally NOT awaited and NOT chained to welcome flow —
      // the prompt must never block the home screen from rendering.
      unawaited(AppUpdateService.instance.checkForUpdate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocale = context.watch<LocaleProvider>().locale;
    // Watch onboarding so flipping the flag (e.g. tapping "Continue" on
    // the welcome screen, or running a DevTools factory reset) rebuilds
    // the routing decision without an app restart.
    final onboarding = context.watch<OnboardingProvider>();
    final cosmetics = context.watch<CosmeticsProvider>();

    // Routing gate. Five outcomes:
    //   1. Onboarding prefs still loading (cold boot)        → splash
    //   2. Onboarding not completed                          → WelcomeScreen
    //   3. Signed in, cosmetics state still hydrating        → splash
    //   4. Signed in, no `selectedRaceId` (legacy save)      → ForcePickRaceScreen
    //   5. Otherwise (signed out, or race set, or fresh)     → MainShell
    //
    // The two splash branches are crucial: without them the gate would
    // briefly render MainShell during the async window between provider
    // construction and the first state arriving, then snap back to
    // ForcePickRaceScreen once it loads — flashing the home screen
    // (with the Google identity avatar leaking through unmigrated
    // surfaces) for ~100–500 ms before the swap. Sitting on a neutral
    // splash for the same window keeps the transition invisible.
    //
    // Signed-out users skip the force gate by design — cosmetics writes
    // are uid-keyed, so a degraded read-only mode renders MainShell as
    // before. The signed-in-but-no-uid corner case (auth restoring
    // from cache) is treated as "still hydrating" through branch 3.
    final Widget home;
    if (!onboarding.isHydrated) {
      home = const _RoutingSplash();
    } else if (!onboarding.isCompleted) {
      home = const WelcomeScreen();
    } else if (cosmetics.currentUid != null && cosmetics.state == null) {
      home = const _RoutingSplash();
    } else if (cosmetics.currentUid != null &&
        cosmetics.state!.selectedRaceId == null) {
      home = const ForcePickRaceScreen();
    } else {
      home = const MainShell();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: SentryConsentGate(child: home),
      locale: selectedLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
    );
  }
}
