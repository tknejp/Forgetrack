import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forgetrack/shared/widgets/xp_claim_pill.dart';

void main() {
  group('XpClaimPill', () {
    testWidgets('renders locked and claimed states with expected labels',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                XpClaimPill(data: XpClaimPillData.locked(80)),
                  XpClaimPill(
                  data: XpClaimPillData.claimed(120),
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
              child: XpClaimPill(
                data: XpClaimPillData.claimable(
                  140,
                  onTap: (center) => tappedCenter = center,
                ),
              ),
            ),
          ),
        ),
      );

      final pillFinder = find.byType(XpClaimPill);
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
