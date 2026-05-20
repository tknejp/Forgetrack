import 'package:forgetrack/domain/progression/catalog/ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/features/progression_engine/application/progression_engine_provider.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';
import 'package:forgetrack/domain/progression/catalog/claim_policy.dart';
import 'package:forgetrack/domain/progression/catalog/progression_entry.dart';
import 'package:forgetrack/domain/progression/catalog/reward_definition.dart';
import 'package:forgetrack/features/progression_engine/presentation/quests_screen.dart';
import 'package:forgetrack/l10n/app_localizations.dart';

Quest _node(String id, int xp) => DailyQuest(
      id: ProgressionEntryId(id),
      objectiveId: ObjectiveId('${id}_objective'),
      claimPolicy: ClaimPolicy.manual,
      titleKey: (_) => 'Title $id',
      descriptionKey: (_) => 'Desc $id',
      rewards: [XpReward(amount: xp)],
    );

EngineQuestProgress _progress({
  required String id,
  required int baseXp,
  required bool isAvailable,
  bool isCompleted = false,
  double progress = 0.5,
}) =>
    EngineQuestProgress(
      node: _node(id, baseXp),
      actualValue: 5000,
      targetValue: 10000,
      progress: progress,
      isCompleted: isCompleted,
      isAvailableForClaim: isAvailable,
      baseXp: baseXp,
      previewXp: baseXp,
      domain: ProgressionDomain.steps,
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('QuestSectionPanel', () {
    testWidgets('shows empty-state line when quests is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return QuestSectionPanel(
                header: l10n.progQuestsDailyGoalsHeader,
                color: Colors.blue,
                countLabel: null,
                emptyTitle: 'Empty title',
                emptyCaption: 'Empty caption',
                claimAllLabel: l10n.progQuestClaimAll,
                l10n: l10n,
                quests: const [],
                claimable: const [],
                enabled: true,
                pillKeyFor: (id) => GlobalKey(),
                onClaim: (_, {Offset? from}) async {},
                onClaimAll: (_) async {},
              );
            },
          ),
        ),
      );

      expect(find.text('Empty title'), findsOneWidget);
      expect(find.text('Empty caption'), findsOneWidget);
    });

    testWidgets(
        'shows a card per quest and the claim-all button when more than one is claimable',
        (tester) async {
      final claimable = [
        _progress(id: 'q1', baseXp: 80, isAvailable: true),
        _progress(id: 'q2', baseXp: 120, isAvailable: true),
      ];
      var receivedClaimAll = 0;

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return QuestSectionPanel(
                header: l10n.progQuestsDailyGoalsHeader,
                color: Colors.blue,
                countLabel: null,
                emptyTitle: 'Empty title',
                emptyCaption: 'Empty caption',
                claimAllLabel: l10n.progQuestClaimAll,
                l10n: l10n,
                quests: claimable,
                claimable: claimable,
                enabled: true,
                pillKeyFor: (id) => GlobalKey(debugLabel: id),
                onClaim: (_, {Offset? from}) async {},
                onClaimAll: (q) async {
                  receivedClaimAll = q.length;
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Title q1'), findsOneWidget);
      expect(find.text('Title q2'), findsOneWidget);

      final claimAll = find.text(
        AppLocalizations.of(
          tester.element(find.text('Title q1')),
        ).progQuestClaimAll,
      );
      expect(claimAll, findsOneWidget);

      await tester.tap(claimAll);
      await tester.pump();
      expect(receivedClaimAll, 2);
    });

    testWidgets('hides the claim-all button when only one quest is claimable',
        (tester) async {
      final quests = [
        _progress(id: 'q1', baseXp: 80, isAvailable: true),
      ];

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return QuestSectionPanel(
                header: l10n.progQuestsDailyGoalsHeader,
                color: Colors.blue,
                countLabel: null,
                emptyTitle: 'Empty title',
                emptyCaption: 'Empty caption',
                claimAllLabel: l10n.progQuestClaimAll,
                l10n: l10n,
                quests: quests,
                claimable: quests,
                enabled: true,
                pillKeyFor: (id) => GlobalKey(debugLabel: id),
                onClaim: (_, {Offset? from}) async {},
                onClaimAll: (_) async {},
              );
            },
          ),
        ),
      );

      // Card present but no separate "Claim all" affordance — the
      // single-quest case relies on the card's pill.
      expect(find.text('Title q1'), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.text('Title q1')),
      );
      expect(find.text(l10n.progQuestClaimAll), findsNothing);
    });
  });
}
