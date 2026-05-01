import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/locale_provider.dart';
import 'core/config/constants.dart';
import 'core/navigation/navigator_key.dart';
import 'features/app_shell/presentation/main_shell.dart';
import 'l10n/app_localizations.dart';
import 'shared/theme/app_theme.dart';

class ForgetrackApp extends StatelessWidget {
  const ForgetrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedLocale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const MainShell(),
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
