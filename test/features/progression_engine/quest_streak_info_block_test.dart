import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/cosmetics/domain/companion_buff.dart';
import 'package:forgetrack/features/progression_engine/presentation/widgets/quest_streak_info_block.dart';
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

const _accent = Color(0xFFFF8C2A);

void main() {
  group('QuestStreakInfoBlock — plain mode (no streak buff)', () {
    testWidgets('renders day count when streak is positive', (tester) async {
      await tester.pumpWidget(_host(const QuestStreakInfoBlock(
        currentStreak: 5,
        bestStreak: 5,
        accent: _accent,
      )));
      expect(find.text('5 days in a row'), findsOneWidget);
    });

    testWidgets('renders "no streak yet" placeholder at zero',
        (tester) async {
      await tester.pumpWidget(_host(const QuestStreakInfoBlock(
        currentStreak: 0,
        bestStreak: 0,
        accent: _accent,
      )));
      expect(find.text('No streak yet'), findsOneWidget);
    });

    testWidgets(
      'shows best streak only when it differs from current',
      (tester) async {
        // current == best → no "best" line (avoids duplication).
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 7,
          bestStreak: 7,
          accent: _accent,
        )));
        expect(find.textContaining('Best ever'), findsNothing);

        // current < best → best line surfaces.
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 3,
          bestStreak: 12,
          accent: _accent,
        )));
        expect(find.text('Best ever: 12 days'), findsOneWidget);
      },
    );
  });

  group('QuestStreakInfoBlock — Ember Sprite (StreakLengthCompanionBuff)',
      () {
    testWidgets(
      'locked variant — tier 0 (streak 0–1) teaches the unlock condition',
      (tester) async {
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 1,
          bestStreak: 1,
          accent: _accent,
          buff: StreakLengthCompanionBuff(),
          // Ember tier 0 → resolvedPercent = 0.
        )));
        expect(find.text('1-day streak · bonus locked'), findsOneWidget);
        // Headline carries the buff state; subtitle teaches the
        // unlock target (tier 1 sits at 2-day streak, paying 5 %).
        expect(
          find.text('1 more day for +5% XP at a 2-day streak'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'live variant — tier 1 shows current bonus + next-tier hint',
      (tester) async {
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 4,
          bestStreak: 6,
          accent: _accent,
          buff: StreakLengthCompanionBuff(),
          resolvedPercent: CompanionBuffPercents.emberTier1, // 5 %
        )));
        expect(find.text('4-day streak · +5% XP'), findsOneWidget);
        expect(
          find.text(
            '+${CompanionBuffPercents.emberTier2}% from '
            '${CompanionBuffPercents.emberTier2Threshold}-day streak',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'live variant — tier 4 (cap) drops the next-tier hint and stays '
      'silent about the legendary milestone',
      (tester) async {
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 30,
          bestStreak: 30,
          accent: _accent,
          buff: StreakLengthCompanionBuff(),
          resolvedPercent: CompanionBuffPercents.emberTier4, // 20 %
        )));
        expect(
          find.text(
            'Top tier reached — current bonus +${CompanionBuffPercents.emberTier4}% XP',
          ),
          findsOneWidget,
        );
        // Critical: nothing in the cap subtitle leaks the silent
        // 100-day milestone.
        expect(find.textContaining('100'), findsNothing);
      },
    );

    testWidgets(
      'legendary variant — 100+ streak reveals the silent bonus',
      (tester) async {
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 120,
          bestStreak: 120,
          accent: _accent,
          buff: StreakLengthCompanionBuff(),
          resolvedPercent: CompanionBuffPercents.emberLegendary, // 100 %
        )));
        expect(find.text('120-day legendary streak'), findsOneWidget);
        expect(find.text('Legendary bonus active — +100% XP'), findsOneWidget);
      },
    );
  });

  group(
    'QuestStreakInfoBlock — Lantern Golem (StreakThresholdFlatCompanionBuff)',
    () {
      testWidgets(
        'locked variant — below 7-day threshold shows remaining days',
        (tester) async {
          await tester.pumpWidget(_host(const QuestStreakInfoBlock(
            currentStreak: 3,
            bestStreak: 4,
            accent: _accent,
            buff: StreakThresholdFlatCompanionBuff(
              percent: CompanionBuffPercents.lanternGolemPercent,
              minStreak: CompanionBuffPercents.lanternGolemThreshold,
            ),
            // Below threshold → resolvedPercent = 0.
          )));
          expect(find.text('3-day streak · bonus locked'), findsOneWidget);
          // Lantern's threshold is 7 d → 4 more days from a 3-day
          // streak. Subtitle pluralises the remaining-days noun.
          expect(
            find.text(
              '4 more days for +${CompanionBuffPercents.lanternGolemPercent}% '
              'XP at a ${CompanionBuffPercents.lanternGolemThreshold}-day streak',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'live variant — at threshold pays out flat, no next-tier hint',
        (tester) async {
          await tester.pumpWidget(_host(const QuestStreakInfoBlock(
            currentStreak: 7,
            bestStreak: 7,
            accent: _accent,
            buff: StreakThresholdFlatCompanionBuff(
              percent: CompanionBuffPercents.lanternGolemPercent,
              minStreak: CompanionBuffPercents.lanternGolemThreshold,
            ),
            resolvedPercent: CompanionBuffPercents.lanternGolemPercent,
          )));
          expect(
            find.text(
              '7-day streak · +${CompanionBuffPercents.lanternGolemPercent}% XP',
            ),
            findsOneWidget,
          );
          // Lantern is flat — the cap line surfaces because there's
          // no further visible tier.
          expect(
            find.text(
              'Top tier reached — current bonus '
              '+${CompanionBuffPercents.lanternGolemPercent}% XP',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'legendary variant — 100+ streak reveals the silent bonus',
        (tester) async {
          await tester.pumpWidget(_host(const QuestStreakInfoBlock(
            currentStreak: 100,
            bestStreak: 100,
            accent: _accent,
            buff: StreakThresholdFlatCompanionBuff(
              percent: CompanionBuffPercents.lanternGolemPercent,
              minStreak: CompanionBuffPercents.lanternGolemThreshold,
            ),
            resolvedPercent: CompanionBuffPercents.lanternLegendary,
          )));
          expect(find.text('100-day legendary streak'), findsOneWidget);
        },
      );
    },
  );

  group('QuestStreakInfoBlock — non-streak buffs fall through to plain', () {
    testWidgets(
      'Forest Fox (FlatCompanionBuff) does not unlock streak chrome',
      (tester) async {
        await tester.pumpWidget(_host(const QuestStreakInfoBlock(
          currentStreak: 5,
          bestStreak: 5,
          accent: _accent,
          buff: FlatCompanionBuff(
            kind: RewardSourceKind.nutritionXp,
            percent: 10,
          ),
          // Flat buff never resolves through the streak path; even if
          // the caller passes a percent it's a no-op because the
          // widget's "live" mode is gated on streak buffs.
        )));
        expect(find.text('5 days in a row'), findsOneWidget);
        // No locked / live / legendary markers.
        expect(find.textContaining('locked'), findsNothing);
        expect(find.textContaining('legendary'), findsNothing);
      },
    );
  });

  group('QuestStreakInfoBlock — Czech locale', () {
    testWidgets(
      'pluralisation: 1 / 2 / 5 days resolve to the right form',
      (tester) async {
        await tester.pumpWidget(_host(
          const QuestStreakInfoBlock(
            currentStreak: 1,
            bestStreak: 1,
            accent: _accent,
          ),
          locale: const Locale('cs'),
        ));
        expect(find.text('1 den v řadě'), findsOneWidget);

        await tester.pumpWidget(_host(
          const QuestStreakInfoBlock(
            currentStreak: 3,
            bestStreak: 3,
            accent: _accent,
          ),
          locale: const Locale('cs'),
        ));
        expect(find.text('3 dny v řadě'), findsOneWidget);

        await tester.pumpWidget(_host(
          const QuestStreakInfoBlock(
            currentStreak: 14,
            bestStreak: 14,
            accent: _accent,
          ),
          locale: const Locale('cs'),
        ));
        expect(find.text('14 dní v řadě'), findsOneWidget);
      },
    );
  });
}
