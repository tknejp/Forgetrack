import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forgetrack/features/cosmetics/presentation/widgets/companion_claim_morph.dart';

void main() {
  group('CompanionClaimMorph', () {
    testWidgets('animates to the resolved slot rect then invokes onComplete',
        (tester) async {
      final slotKey = GlobalKey();
      var completes = 0;
      // Drive the animation in a short test duration so we don't
      // burn 1.15 s of pump time. The widget's behavior is
      // duration-agnostic — we only need to verify the lifecycle.
      const duration = Duration(milliseconds: 200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 200,
                  width: 130,
                  height: 130,
                  child: SizedBox(key: slotKey),
                ),
                CompanionClaimMorph(
                  assetPath: null,
                  color: const Color(0xFFFF8C2A),
                  sourceCenter: const Offset(200, 400),
                  destSlotKey: slotKey,
                  duration: duration,
                  onComplete: () => completes++,
                ),
              ],
            ),
          ),
        ),
      );

      // Lets initState's post-frame callback resolve the slot rect
      // and start the controller, then runs out the animation.
      await tester.pumpAndSettle();
      expect(completes, 1);
    });

    testWidgets('falls back to source position when slot is unmounted',
        (tester) async {
      final slotKey = GlobalKey();
      var completes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompanionClaimMorph(
              assetPath: null,
              color: const Color(0xFFFF8C2A),
              sourceCenter: const Offset(50, 50),
              destSlotKey: slotKey,
              duration: const Duration(milliseconds: 100),
              onComplete: () => completes++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(completes, 1);
    });
  });
}
