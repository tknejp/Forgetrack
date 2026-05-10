import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/celebration_controller.dart';
import '../domain/models/celebration_event.dart';
import '../domain/services/celebration_router.dart';
import 'widgets/fullscreen/celebration_fullscreen.dart';
import 'widgets/topsheet/celebration_topsheet.dart';

/// Mounts inside the main shell's Stack. Watches [CelebrationController] and
/// either renders the topsheet inline (Variant D) or pushes the fullscreen
/// route (Variant C).
///
/// `onOpenInventory` is invoked when the user taps the secondary CTA in a
/// fullscreen celebration that has at least one wearable cosmetic reward.
/// The host pops the celebration first so the inventory navigation feels
/// unsuspended.
class CelebrationOverlayHost extends StatefulWidget {
  const CelebrationOverlayHost({
    super.key,
    this.onOpenInventory,
    this.router = const CelebrationRouter(),
  });

  final VoidCallback? onOpenInventory;
  final CelebrationRouter router;

  @override
  State<CelebrationOverlayHost> createState() => _CelebrationOverlayHostState();
}

class _CelebrationOverlayHostState extends State<CelebrationOverlayHost> {
  String? _shownFullscreenId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CelebrationController>();
    final event = controller.current;

    if (event == null) {
      // Reset the dedupe marker so the same id can later re-show in the
      // (rare) case the queue replays it.
      _shownFullscreenId = null;
      // The host owns its full Positioned.fill area in main_shell. When
      // no celebration is up we render a transparent ignore-pointer so
      // taps fall through to the underlying tabs / page view.
      return const IgnorePointer(child: SizedBox.expand());
    }

    final variant = widget.router.resolve(event);

    if (variant == CelebrationVariant.fullscreen) {
      _scheduleFullscreen(event, controller);
      // While the route is being pushed (post-frame) we still need to
      // occupy the host's slot without blocking the page-view beneath.
      return const IgnorePointer(child: SizedBox.expand());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Tap anywhere on the screen to dismiss the topsheet. The claim
        // and close buttons inside the topsheet have their own opaque
        // gesture detectors and win the gesture arena over this one, so
        // tapping them performs their action instead of dismissing.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: controller.dismiss,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CelebrationTopsheet(
            key: ValueKey(event.id),
            event: event,
            onDismiss: controller.dismiss,
            onClaimAttempt: controller.claim,
          ),
        ),
      ],
    );
  }

  void _scheduleFullscreen(
    CelebrationEvent event,
    CelebrationController controller,
  ) {
    if (_shownFullscreenId == event.id) return;
    _shownFullscreenId = event.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await openCelebrationFullscreen(
        context: context,
        event: event,
        onOpenInventory: widget.onOpenInventory,
      );
      if (!mounted) return;
      // The route can also be popped programmatically (close button / open
      // inventory CTA). Either way, finish the controller's lifecycle.
      controller.dismiss();
    });
  }
}
