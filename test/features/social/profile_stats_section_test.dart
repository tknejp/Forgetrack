// Widget-level tests for [ProfileStatsSection].
//
// Scope is restricted to the foreign-profile (`isMe: false`) path because
// the owner path watches FitnessProvider / KalorickeTabulkyProvider /
// ProgressionEngineProvider / CosmeticsProvider, all of which require
// non-trivial setup (Isar, Firestore stubs, l10n providers). The
// foreign path renders strictly from `widget.profile.stats` and
// `widget.profile.statVisibilityOverrides`, which is exactly the surface
// covered here.
//
// Edit-mode commit-flow validation lives in
// `profile_stat_catalog_test.dart` (pure policy) — wiring the owner
// path through the section would require a provider harness that is
// disproportionate to what it would catch.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/social/domain/achievement_share.dart';
import 'package:forgetrack/features/social/domain/social_user_profile.dart';
import 'package:forgetrack/features/social/presentation/widgets/profile_stats_section.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

SocialUserProfile _profile({
  Set<String> statVisibilityOverrides = const <String>{},
  SocialUserStats? stats,
}) {
  return SocialUserProfile(
    uid: 'friend-uid',
    displayName: 'Friend',
    handle: 'friend',
    email: 'friend@example.com',
    socialEnabled: true,
    pinnedAchievementIds: const [],
    statVisibilityOverrides: statVisibilityOverrides,
    createdAt: DateTime(2024, 1, 1),
    stats: stats ??
        const SocialUserStats(
          level: 12,
          totalXp: 4500,
          unlockedAchievementCount: 8,
          grantedRewardCount: 17,
          bestStepsStreak: 23,
          bestNutritionStreak: 9,
          stepsLifetime: 2340000,
          stepsAvg30d: 7800,
          activeDays30d: 25,
          avgSleepMinutes7d: 410,
          latestWeightKg: 82.4,
          avgKcal7d: 2200,
        ),
    equippedCosmetics: const SocialEquippedCosmetics.empty(),
  );
}

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
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('ProfileStatsSection (foreign profile)', () {
    testWidgets(
      'renders catalog-default rows; hides sensitive defaults',
      (tester) async {
        await tester.pumpWidget(_host(
          ProfileStatsSection(
            profile: _profile(),
            isMe: false,
            friendCount: 4,
            sharedPostsCount: 2,
          ),
        ));

        // Hrdina card is visible — expand to inspect rows.
        expect(find.text('Hero'), findsOneWidget);
        await tester.tap(find.text('Hero'));
        await tester.pumpAndSettle();

        // Default-visible rows on the wire.
        expect(find.text('Level'), findsOneWidget);
        expect(find.text('Total XP'), findsOneWidget);
        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('Days on the quest'), findsOneWidget);

        // Default-hidden rows must not appear on a foreign profile
        // unless the owner explicitly opted in.
        expect(find.text('Granted rewards'), findsNothing);
        expect(find.text('Cosmetics unlocked'), findsNothing);
      },
    );

    testWidgets(
      'owner opt-in publishes a default-hidden row on foreign view',
      (tester) async {
        // XOR semantics — flipping the override on a default-hidden
        // key publishes it to foreign viewers.
        await tester.pumpWidget(_host(
          ProfileStatsSection(
            profile: _profile(
              statVisibilityOverrides: const {'hero.grantedRewards'},
            ),
            isMe: false,
          ),
        ));
        await tester.tap(find.text('Hero'));
        await tester.pumpAndSettle();
        expect(find.text('Granted rewards'), findsOneWidget);
      },
    );

    testWidgets(
      'override flips a default-visible row to hidden',
      (tester) async {
        await tester.pumpWidget(_host(
          ProfileStatsSection(
            profile: _profile(statVisibilityOverrides: const {'hero.level'}),
            isMe: false,
          ),
        ));
        await tester.tap(find.text('Hero'));
        await tester.pumpAndSettle();
        expect(find.text('Level'), findsNothing);
        // Sanity: other default-visible rows still render.
        expect(find.text('Total XP'), findsOneWidget);
      },
    );

    testWidgets(
      'a card with zero visible rows is suppressed entirely',
      (tester) async {
        // Body card descriptors are all default-hidden — foreign
        // profile must not see the card header at all.
        await tester.pumpWidget(_host(
          ProfileStatsSection(
            profile: _profile(),
            isMe: false,
          ),
        ));
        expect(find.text('Body'), findsNothing);
        expect(find.text('Nutrition'), findsNothing);
        expect(find.text('Sleep'), findsNothing);
      },
    );

    testWidgets(
      'owner pencil affordance is absent on foreign profile',
      (tester) async {
        await tester.pumpWidget(_host(
          ProfileStatsSection(
            profile: _profile(),
            isMe: false,
          ),
        ));
        expect(find.byIcon(Icons.edit_rounded), findsNothing);
        // Section header still renders.
        expect(find.text('STATS'), findsOneWidget);
      },
    );

    testWidgets(
      'social card shows shared friend / posts counts',
      (tester) async {
        await tester.pumpWidget(_host(
          ProfileStatsSection(
            profile: _profile(),
            isMe: false,
            friendCount: 7,
            sharedPostsCount: 3,
          ),
        ));
        expect(find.text('Community'), findsOneWidget);
        await tester.tap(find.text('Community'));
        await tester.pumpAndSettle();
        expect(find.text('Friends'), findsOneWidget);
        expect(find.text('Shared posts'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      },
    );
  });
}

// `_` linter sanity — the unused import below would trigger when no
// SocialAchievementShare reference exists. Keep the import live so a
// future test can pull in share helpers without re-discovering it.
// ignore_for_file: unused_element
typedef _SocialAchievementShareRef = SocialAchievementShare;
