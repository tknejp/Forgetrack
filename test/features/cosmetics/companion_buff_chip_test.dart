import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/domain/companion_buff.dart';
import 'package:forgetrack/features/cosmetics/presentation/widgets/companion_buff_chip.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('cs')],
    locale: const Locale('cs'),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('CompanionBuffChip', () {
    testWidgets('renders the flat buff percent + source kind',
        (tester) async {
      await tester.pumpWidget(_host(const CompanionBuffChip(
        buff: FlatCompanionBuff(
          kind: RewardSourceKind.activityXp,
          percent: 8,
        ),
        color: Color(0xFF7C6FFF),
      )));
      expect(find.text('+8 % XP z aktivit'), findsOneWidget);
    });

    testWidgets('renders the Ember streak range', (tester) async {
      await tester.pumpWidget(_host(const CompanionBuffChip(
        buff: StreakLengthCompanionBuff(),
        color: Color(0xFFFF8C2A),
      )));
      expect(
        find.text('+3–12 % XP ze streaku (roste s plamenem)'),
        findsOneWidget,
      );
    });

    testWidgets('renders the Raven daily / weekly split', (tester) async {
      await tester.pumpWidget(_host(const CompanionBuffChip(
        buff: WeeklyEmphasisCompanionBuff(),
        color: Color(0xFF7C6FFF),
      )));
      expect(
        find.text('+5 % denní / +30 % týdenní quest XP'),
        findsOneWidget,
      );
    });

    testWidgets('renders the Lynx chain depth range', (tester) async {
      await tester.pumpWidget(_host(const CompanionBuffChip(
        buff: ChapterDepthCompanionBuff(),
        color: Color(0xFFB388FF),
      )));
      expect(
        find.text(
            '+25–65 % XP z chapter questů (roste s hloubkou řetězce)'),
        findsOneWidget,
      );
    });
  });
}
