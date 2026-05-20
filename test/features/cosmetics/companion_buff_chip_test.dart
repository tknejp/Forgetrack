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
      expect(find.text('+8 % XP za aktivity'), findsOneWidget);
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
        find.text('+5 % XP za denní quest / +30 % XP za týdenní'),
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
            '+25–65 % XP za chapter questy (roste s hloubkou řetězce)'),
        findsOneWidget,
      );
    });
  });

  group('CompanionBuffBanner live tiers', () {
    testWidgets(
        'Lynx headline shows live percent when chain position is known',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const CompanionBuffBanner(
            buff: ChapterDepthCompanionBuff(),
            // chainOrder 4 → deep tier → +65 %.
            currentChapterChainPosition: 4,
          ),
        ),
      );
      // The live ARB key renders the resolved tier inline.
      expect(
        find.textContaining('65'),
        findsWidgets,
        reason:
            'Banner should headline the deep-tier live percent (65) when '
            'the player is at or past chain position 4.',
      );
    });

    testWidgets(
        'Lynx falls back to range when chain position is null',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const CompanionBuffBanner(
            buff: ChapterDepthCompanionBuff(),
            currentChapterChainPosition: null,
          ),
        ),
      );
      // No active chain → range headline still mentions both ends.
      expect(find.textContaining('25'), findsWidgets);
      expect(find.textContaining('65'), findsWidgets);
    });
  });
}
