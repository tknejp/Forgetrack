import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/time_theme_provider.dart';
import 'screens/ft_main_shell.dart';
import 'theme/app_theme.dart';
import 'theme/time_theme.dart';

class ForgetrackApp extends StatelessWidget {
  const ForgetrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedLocale  = context.watch<LocaleProvider>().locale;
    final themeProvider   = context.watch<ThemeProvider>();
    final timeProvider    = context.watch<TimeThemeProvider>();

    final isDynamic = themeProvider.choice == AppThemeMode.dynamic;

    // ── Effective ThemeMode ─────────────────────────────────────────────────
    // Dynamic mode auto-switches light/dark based on the time segment.
    // Dawn → afternoon are light; sunset → night are dark.
    final ThemeMode effectiveMode;
    if (isDynamic) {
      const lightSegments = {
        TimeSegment.dawn,
        TimeSegment.morning,
        TimeSegment.noon,
        TimeSegment.afternoon,
      };
      effectiveMode = lightSegments.contains(timeProvider.segment)
          ? ThemeMode.light
          : ThemeMode.dark;
    } else {
      effectiveMode = themeProvider.mode;
    }

    // ── Time palette ────────────────────────────────────────────────────────
    // Active when Dynamic theme mode is on, or when the background toggle
    // is on (so backgrounds and palette always stay in sync).
    final timePalette = (isDynamic || timeProvider.enabled)
        ? timeProvider.visuals.palette
        : null;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(timePalette),
      darkTheme: AppTheme.dark(timePalette),
      themeMode: effectiveMode,
      home: const FtMainShell(),

      // ── Localization setup ────────────────────────────────────────────────
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
