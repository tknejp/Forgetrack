import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/widgets/ft/ft_xp_claim_pill.dart';

void main() {
  group('FtXpClaimPill', () {
    testWidgets('renders locked and claimed states with expected labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                FtXpClaimPill(data: FtXpClaimPillData.locked(80)),
                FtXpClaimPill(
                  data: FtXpClaimPillData.claimed(120),
                  claimedLabel: 'Claimed',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('80 XP'), findsOneWidget);
      expect(find.text('Claimed'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('invokes the claim callback with the pill center',
        (tester) async {
      Offset? tappedCenter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FtXpClaimPill(
                data: FtXpClaimPillData.claimable(
                  140,
                  onTap: (center) => tappedCenter = center,
                ),
              ),
            ),
          ),
        ),
      );

      final pillFinder = find.byType(FtXpClaimPill);
      final expectedCenter = tester.getCenter(pillFinder);

      await tester.tap(pillFinder);
      await tester.pump();

      expect(find.text('+140 XP'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(tappedCenter, isNotNull);
      expect((tappedCenter! - expectedCenter).distance, lessThan(0.001));
    });
  });
}
