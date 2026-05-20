import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/features/social/presentation/widgets/hero_streak_stats_card.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('cs')],
    locale: locale,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('HeroStreakStatsCard', () {
    testWidgets(
      'renders title + achievements pill; rows revealed on tap',
      (tester) async {
        await tester.pumpWidget(_host(HeroStreakStatsCard(
          achievementsCount: 17,
          rows: [
            for (final domain in ProgressionDomain.values)
              DomainStreakRow(
                domain: domain,
                currentStreak: 3,
                bestStreak: 12,
              ),
          ],
        )));

        expect(find.text('Streak records'), findsOneWidget);
        expect(find.text('17 achievements'), findsOneWidget);

        // Card starts collapsed — domain rows are not in the tree yet.
        expect(find.text('3d'), findsNothing);

        await tester.tap(find.text('Streak records'));
        await tester.pumpAndSettle();

        // Each of the 5 domain rows surfaces — labels come from the
        // shared chrome extension, so finding the count finds the row.
        // 5 current cells + 5 best cells = 10 total day cells.
        expect(find.text('3d'), findsNWidgets(5));
        expect(find.text('12d'), findsNWidgets(5));
      },
    );

    testWidgets(
      'unknown streak (null) renders as a dash placeholder',
      (tester) async {
        // Mimics the friend-profile case where the Firestore wire
        // format doesn't carry current-streak or non-steps/nutrition
        // best — the rest of the table must surface as "—" rather
        // than misleadingly showing 0.
        await tester.pumpWidget(_host(const HeroStreakStatsCard(
          achievementsCount: 4,
          rows: [
            DomainStreakRow(
              domain: ProgressionDomain.steps,
              currentStreak: null,
              bestStreak: 21,
            ),
            DomainStreakRow(
              domain: ProgressionDomain.sleep,
              currentStreak: null,
              bestStreak: null,
            ),
          ],
        )));

        // Expand the collapsed-by-default card before inspecting rows.
        await tester.tap(find.text('Streak records'));
        await tester.pumpAndSettle();

        // Steps row → current = "—", best = "21d".
        expect(find.text('21d'), findsOneWidget);
        // Sleep row → both cells "—" + steps' current "—" = 3 dashes.
        expect(find.text('—'), findsNWidgets(3));
      },
    );

    testWidgets(
      'achievements pill pluralises through l10n',
      (tester) async {
        // English singular.
        await tester.pumpWidget(_host(const HeroStreakStatsCard(
          achievementsCount: 1,
          rows: [],
        )));
        expect(find.text('1 achievement'), findsOneWidget);
      },
    );

    testWidgets(
      'Czech locale flips the title + plural achievements correctly',
      (tester) async {
        await tester.pumpWidget(_host(
          const HeroStreakStatsCard(
            achievementsCount: 3,
            rows: [],
          ),
          locale: const Locale('cs'),
        ));
        expect(find.text('Streak rekordy'), findsOneWidget);
        expect(find.text('3 úspěchy'), findsOneWidget);
      },
    );
  });
}
