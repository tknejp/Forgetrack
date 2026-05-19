import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:forgetrack/features/cosmetics/domain/cosmetic_models.dart';
import 'package:forgetrack/features/cosmetics/presentation/widgets/companion_claim_forging.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

String _embername(AppLocalizations _) => 'Jiskřička';
String _empty(AppLocalizations _) => '';

void main() {
  group('CompanionClaimForging', () {
    const companion = Companion(
      id: CosmeticId('companion_test'),
      rarity: Rarity.common,
      region: CosmeticRegion.neutral,
      name: _embername,
      description: _empty,
    );

    Widget host({
      required Future<void> Function() onReveal,
      required VoidCallback onComplete,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('cs')],
        locale: const Locale('cs'),
        home: Scaffold(
          body: CompanionClaimForging(
            companion: companion,
            assetPath: null,
            relicIds: const ['relic_a', 'relic_b'],
            color: const Color(0xFF7C6FFF),
            onReveal: onReveal,
            onComplete: onComplete,
          ),
        ),
      );
    }

    testWidgets('crossfades through the four status labels', (tester) async {
      await tester.pumpWidget(host(
        onReveal: () async {},
        onComplete: () {},
      ));
      // Frame at t ≈ 0
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Připravuji rituál…'), findsAtLeastNWidgets(1));

      // 600 → 2400 ms: binding label.
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Spojuji relikvie…'), findsAtLeastNWidgets(1));

      // 2900 → 4700 ms: awakening label.
      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.text('Probouzím společníka…'), findsAtLeastNWidgets(1));

      // ≥ 4700 ms: reveal — companion name + subtitle.
      // Cumulative pumps: 100 + 800 + 2200 = 3100 ms so far.
      // Need to land past 4700 ms; pump 1700 ms to t = 4800.
      await tester.pump(const Duration(milliseconds: 1700));
      // AnimatedSwitcher mounts both the old + new label during the
      // crossfade, so allow the multiple finder.
      expect(find.text('Jiskřička'), findsAtLeastNWidgets(1));
      expect(find.text('Tvůj nový společník'), findsAtLeastNWidgets(1));

      // Settle to end so the controller stops cleanly before teardown.
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('fires onReveal and onComplete at timeline boundaries',
        (tester) async {
      var revealCount = 0;
      var completeCount = 0;
      await tester.pumpWidget(host(
        onReveal: () async {
          revealCount++;
        },
        onComplete: () => completeCount++,
      ));

      // Before reveal threshold — neither callback fires.
      await tester.pump(const Duration(milliseconds: 4500));
      expect(revealCount, 0);
      expect(completeCount, 0);

      // Cross 4700 ms reveal marker.
      await tester.pump(const Duration(milliseconds: 400));
      expect(revealCount, 1);
      expect(completeCount, 0);

      // Cross 5400 ms total + the deferred post-frame callback.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(completeCount, 1);
      // Reveal only fires once even though listeners keep ticking.
      expect(revealCount, 1);
    });

    testWidgets('tap-to-skip jumps the controller to settle and completes',
        (tester) async {
      var revealCount = 0;
      var completeCount = 0;
      await tester.pumpWidget(host(
        onReveal: () async {
          revealCount++;
        },
        onComplete: () => completeCount++,
      ));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(CompanionClaimForging));
      // Listener tick after snap-to-end fires the reveal haptic + claim.
      await tester.pump();
      // Status callback fires on the post-frame.
      await tester.pump();
      expect(revealCount, 1);
      expect(completeCount, 1);
    });
  });
}
