import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/celebration/presentation/widgets/shared/xp_award_pill.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('cs'), Locale('en')],
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('CelebrationXpAwardPill companion bonus badge', () {
    testWidgets('renders without a bonus badge when companionBonus is 0',
        (tester) async {
      await tester
          .pumpWidget(_host(const CelebrationXpAwardPill(amount: 100)));
      // Run out the staggered shimmer + bonus-fade timers so the
      // test exits cleanly.
      // Drain the two `Future.delayed` schedules (shimmer 250 ms,
      // bonus fade 700 ms) + the controllers themselves (900 ms +
      // 520 ms). Pump well past the latest end at ~1220 ms.
      await tester.pump(const Duration(milliseconds: 1500));
      // No "+N" bonus text on the right of the pill when no buff fired.
      expect(find.text('+0'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });

    testWidgets('renders the bonus badge with the companion contribution',
        (tester) async {
      await tester.pumpWidget(_host(const CelebrationXpAwardPill(
        amount: 108,
        companionBonus: 8,
      )));
      // Let the staggered fade controller schedule + advance past
      // its delay so the bonus badge mounts and reaches full opacity.
      // Drain the two `Future.delayed` schedules (shimmer 250 ms,
      // bonus fade 700 ms) + the controllers themselves (900 ms +
      // 520 ms). Pump well past the latest end at ~1220 ms.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('+8'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });
}
