import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/celebration_event.dart';
import '../../../domain/models/celebration_reward.dart';
import 'reward_card.dart';

/// Fanned stack of reward cards with swipe + tap interactions.
/// `controller` exposes [activeIndex] and `setActive` so the parent can wire
/// the primary CTA / pagination dots to the same state.
class RewardCardStack extends StatefulWidget {
  const RewardCardStack({
    super.key,
    required this.event,
    required this.controller,
  });

  final CelebrationEvent event;
  final RewardStackController controller;

  @override
  State<RewardCardStack> createState() => _RewardCardStackState();
}

class _RewardCardStackState extends State<RewardCardStack> {
  double _drag = 0;
  bool _dragging = false;

  void _onPanStart(DragStartDetails _) {
    _dragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _drag += details.delta.dx);
  }

  void _onPanEnd(DragEndDetails _) {
    const threshold = 45.0;
    final last = widget.event.rewards.length - 1;
    if (_drag <= -threshold && widget.controller.activeIndex < last) {
      widget.controller.setActive(widget.controller.activeIndex + 1);
    } else if (_drag >= threshold && widget.controller.activeIndex > 0) {
      widget.controller.setActive(widget.controller.activeIndex - 1);
    }
    _dragging = false;
    setState(() => _drag = 0);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onActiveChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onActiveChanged);
    super.dispose();
  }

  void _onActiveChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rewards = widget.event.rewards;
    final active = widget.controller.activeIndex;

    // Paint order: cards farthest from active are painted first (behind),
    // the active card is painted last so it sits visually on top of all
    // siblings. ValueKey on each card lets Flutter preserve State across
    // re-orderings instead of destroying / recreating the widgets.
    final paintOrder = List<int>.generate(rewards.length, (i) => i)
      ..sort((a, b) {
        final oa = (a - active).abs();
        final ob = (b - active).abs();
        return ob.compareTo(oa);
      });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: RewardCard.width + 80,
        height: RewardCard.height + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final i in paintOrder)
              KeyedSubtree(
                key: ValueKey(rewards[i].id),
                child: _buildPositionedCard(
                  index: i,
                  active: i == active,
                  offset: i - active,
                  reward: rewards[i],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedCard({
    required int index,
    required bool active,
    required int offset,
    required CelebrationReward reward,
  }) {
    // Inactive cards trail at 0.4× of the drag for a subtle parallax.
    final dragNudge = active ? _drag : _drag * 0.4;
    final translateX = offset * 40.0 + dragNudge;
    final translateY = offset.abs() * 8.0;
    final rotateRad = (offset * 4.0 +
            (active ? (_drag / 280) * 8.0 : 0.0)) *
        math.pi /
        180.0;
    final scale = active ? 1.0 : 0.92;
    final opacity = offset.abs() > 2 ? 0.0 : 1.0;

    final card = AnimatedScale(
      scale: scale,
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 450),
      curve: const Cubic(0.2, 0.9, 0.3, 1.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (active) {
            widget.controller.advance();
          } else {
            widget.controller.setActive(index);
          }
        },
        child: RewardCard(
          reward: reward,
          type: widget.event.type,
          active: active,
        ),
      ),
    );

    return Positioned(
      child: IgnorePointer(
        ignoring: opacity == 0,
        child: AnimatedContainer(
          duration:
              _dragging ? Duration.zero : const Duration(milliseconds: 450),
          curve: const Cubic(0.2, 0.9, 0.3, 1.0),
          transform: Matrix4.identity()
            ..translateByDouble(translateX, translateY, 0, 1)
            ..rotateZ(rotateRad),
          transformAlignment: Alignment.center,
          child: Opacity(opacity: opacity, child: card),
        ),
      ),
    );
  }
}

/// Small mutable holder so the parent (CelebrationFullscreen) can drive
/// active-index changes from the primary CTA + pagination dots without
/// needing to reach into the stack widget's State.
class RewardStackController extends ChangeNotifier {
  RewardStackController({required this.rewardCount});

  final int rewardCount;
  int _activeIndex = 0;

  int get activeIndex => _activeIndex;

  bool get atLast => _activeIndex >= rewardCount - 1;

  void setActive(int i) {
    final clamped = i.clamp(0, rewardCount - 1);
    if (clamped == _activeIndex) return;
    _activeIndex = clamped;
    notifyListeners();
  }

  void advance() {
    if (_activeIndex < rewardCount - 1) {
      _activeIndex += 1;
      notifyListeners();
    }
  }
}
