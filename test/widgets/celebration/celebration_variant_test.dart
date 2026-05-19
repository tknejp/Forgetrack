// R.5.b — Celebration variant smoke tests.
//
// Three structural snapshots covering the two visual variants and the
// orthogonal animation path that breaks most easily in refactors:
//
//   * topsheet — single XP claim (no rewards strip);
//   * fullscreen — legendary chapter completion with a reward stack;
//   * fullscreen — companion claim reveal with a companion reward (the
//     identity-reveal path that motivated the Phase 11 lifecycle merge).
//
// Pixel goldens were tried first and ruled out — the celebration overlay
// composites three FX layers (AuraLayer, RaysLayer, ParticlesLayer) that
// each drive an `AnimationController..repeat()` and a seeded but
// time-coupled particle field. Both `pump(timed)` and `pump()` produced
// reproducible structure but non-reproducible rasterised particle
// positions across runs, which would have made the pixel-diff gate
// noisier than useful. The ADR `r5b-celebration-golden-tests` records
// the pivot. The assertions below cover the regression surface the
// goldens were intended to guard: header text, reward identity,
// XP pill presence, and the per-reward kind tag.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/celebration/domain/models/celebration_event.dart';
import 'package:forgetrack/features/celebration/domain/models/celebration_reward.dart';
import 'package:forgetrack/features/celebration/presentation/widgets/fullscreen/celebration_fullscreen.dart';
import 'package:forgetrack/features/celebration/presentation/widgets/shared/xp_award_pill.dart';
import 'package:forgetrack/features/celebration/presentation/widgets/topsheet/celebration_topsheet.dart';
import 'package:forgetrack/l10n/app_localizations.dart';
import 'package:forgetrack/shared/domain/rarity.dart';

const Size _phoneSurface = Size(390, 844);

Widget _wrap(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('cs'),
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    home: Scaffold(
      backgroundColor: const Color(0xFF0B0F1E),
      body: child,
    ),
  );
}

Future<void> _pumpThroughEntry(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(_phoneSurface);
  await tester.pumpWidget(_wrap(widget));
  // Drain the staged-entry animation timers (700ms topsheet, 900ms
  // fullscreen) plus the XP pill's 250ms entry delay. Cannot use
  // pumpAndSettle — the FX layers' `..repeat()` controllers never
  // settle.
  await tester.pump(const Duration(milliseconds: 1500));
}

void main() {
  group('CelebrationTopsheet', () {
    testWidgets('single XP claim renders header + XP pill', (tester) async {
      final event = CelebrationEvent(
        id: 'test|xp|1',
        type: CelebrationType.quest,
        eyebrow: (l10n) => 'QUEST DOKONČEN',
        title: (l10n) => 'Dnešní kalorický cíl',
        description: (l10n) => 'Splněno na 100 %',
        rewards: const [],
        headRarity: Rarity.common,
        xpAward: const CelebrationXpAward(50),
      );

      await _pumpThroughEntry(
        tester,
        CelebrationTopsheet(event: event, onDismiss: () {}),
      );

      expect(find.text('QUEST DOKONČEN'), findsOneWidget);
      expect(find.text('Dnešní kalorický cíl'), findsOneWidget);
      expect(find.text('Splněno na 100 %'), findsOneWidget);
      expect(find.byType(CelebrationXpAwardPill), findsOneWidget);
      // No rewards bundled, so the strip section never renders.
      expect(find.text('Odměny'.toUpperCase()), findsNothing);
    });
  });

  group('CelebrationFullscreen', () {
    testWidgets('legendary chapter completion renders reward stack',
        (tester) async {
      var inventoryOpened = false;
      final event = CelebrationEvent(
        id: 'test|chapter|1',
        type: CelebrationType.achievement,
        eyebrow: (l10n) => 'KAPITOLA DOKONČENA',
        title: (l10n) => 'Horský vyzyvatel',
        description: (l10n) => 'Pokořil jsi všechny vrcholy první kapitoly.',
        rewards: [
          CelebrationReward(
            id: 'cosmetic-frame-legendary',
            name: (l10n) => 'Rám horského vyzyvatele',
            sub: (l10n) => 'Legendární rám',
            rarity: Rarity.legendary,
            kind: CelebrationRewardKind.frame,
          ),
          CelebrationReward(
            id: 'title-mountain',
            name: (l10n) => 'Horský vyzyvatel',
            sub: (l10n) => 'Nový titul',
            rarity: Rarity.epic,
            kind: CelebrationRewardKind.title,
          ),
        ],
        headRarity: Rarity.legendary,
        xpAward: const CelebrationXpAward(500),
        variantOverride: CelebrationVariant.fullscreen,
      );

      await _pumpThroughEntry(
        tester,
        CelebrationFullscreen(
          event: event,
          onDismiss: () {},
          onOpenInventory: ({String? focusCompanionId}) {
            inventoryOpened = true;
          },
        ),
      );

      expect(find.text('KAPITOLA DOKONČENA'), findsOneWidget);
      // Title appears twice — once in the header, once as the title-reward
      // card's name. Both renders are intentional; the assertion guards
      // that the header reaches the screen alongside the reward stack.
      expect(find.text('Horský vyzyvatel'), findsWidgets);
      expect(find.byType(CelebrationXpAwardPill), findsOneWidget);
      // The frame reward makes the wearable secondary CTA appear. The
      // copy is the inventory-open label because none of the rewards is
      // a companion.
      expect(find.text('Otevřít inventář →'), findsOneWidget);
      expect(inventoryOpened, isFalse, reason: 'CTA only fires on tap');
    });

    testWidgets('companion claim reveal surfaces the claim-companion CTA',
        (tester) async {
      String? focusedCompanion;
      final event = CelebrationEvent(
        id: 'test|companion|1',
        type: CelebrationType.cosmetic,
        eyebrow: (l10n) => 'NOVÝ SPOLEČNÍK',
        title: (l10n) => 'Horský rys',
        description: (l10n) => 'Připojil se k tvé výpravě.',
        rewards: [
          CelebrationReward(
            id: 'companion-cave-lynx',
            name: (l10n) => 'Horský rys',
            sub: (l10n) => 'Vzácný společník',
            rarity: Rarity.rare,
            kind: CelebrationRewardKind.companion,
          ),
        ],
        headRarity: Rarity.rare,
        variantOverride: CelebrationVariant.fullscreen,
      );

      await _pumpThroughEntry(
        tester,
        CelebrationFullscreen(
          event: event,
          onDismiss: () {},
          onOpenInventory: ({String? focusCompanionId}) {
            focusedCompanion = focusCompanionId;
          },
        ),
      );

      expect(find.text('NOVÝ SPOLEČNÍK'), findsOneWidget);
      expect(find.text('Horský rys'), findsWidgets);
      expect(find.text('Připojil se k tvé výpravě.'), findsOneWidget);
      // Companion-flavoured secondary CTA replaces the generic
      // "Otevřít inventář →" copy when a companion reward is present.
      final claimCta = find.text('Vyzvedni společníka →');
      expect(claimCta, findsOneWidget);

      await tester.tap(claimCta);
      await tester.pump();
      // Reward id is namespaced `companion-<id>`; the fullscreen strips
      // the prefix before handing it to the inventory CTA so the
      // inventory screen can land on the cave-lynx details sheet.
      expect(focusedCompanion, 'cave-lynx');
    });
  });
}
