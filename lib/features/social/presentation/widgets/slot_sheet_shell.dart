import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Shared chrome for the profile hero slot sheets (companion / skin /
/// emblem). Owns the top margin, surface decoration, drag handle, and
/// a scroll view so a single sheet that overflows on small screens
/// behaves the same as one that fits.
///
/// Drag-to-dismiss: a raw `Listener` runs in parallel with the gesture
/// arena. When the inner [SingleChildScrollView] grows tall enough to
/// scroll, the scroll view claims every vertical drag and Flutter's
/// built-in modal-sheet dismiss never fires. The listener tracks
/// downward pointer motion while the scroll view is pinned at offset
/// 0 and pops the route once the accumulated drag passes the
/// dismiss threshold. Sheets that DON'T overflow (skin / emblem on
/// most devices) still get drag-dismiss for free via the same path —
/// the listener fires whether or not the scroll view is scrollable,
/// so all three sheets behave identically.
class SlotSheetShell extends StatefulWidget {
  const SlotSheetShell({super.key, required this.child});

  /// The sheet's payload (header + current block + picker grid). The
  /// shell adds the surrounding margin, surface, drag handle, and
  /// scroll view; callers only own the inner content.
  final Widget child;

  @override
  State<SlotSheetShell> createState() => _SlotSheetShellState();
}

class _SlotSheetShellState extends State<SlotSheetShell> {
  final ScrollController _scrollController = ScrollController();

  double _dragAccumulated = 0;
  bool _tracking = false;
  static const double _dismissThreshold = 80;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _atTop =>
      !_scrollController.hasClients || _scrollController.offset <= 0;

  void _onPointerDown(PointerDownEvent event) {
    _dragAccumulated = 0;
    _tracking = _atTop;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final dy = event.delta.dy;
    if (!_tracking) {
      // Re-arm once the user scrolls back to the top and starts
      // pulling downward again — common path on overflowing sheets.
      if (_atTop && dy > 0) {
        _tracking = true;
        _dragAccumulated = 0;
      } else {
        return;
      }
    }
    if (!_atTop) {
      _tracking = false;
      _dragAccumulated = 0;
      return;
    }
    _dragAccumulated += dy;
    if (_dragAccumulated < 0) _dragAccumulated = 0;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_dragAccumulated > _dismissThreshold) {
      Navigator.of(context).maybePop();
    }
    _dragAccumulated = 0;
    _tracking = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _dragAccumulated = 0;
    _tracking = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Tokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Tokens.cardBorder),
            left: BorderSide(color: Tokens.cardBorder),
            right: BorderSide(color: Tokens.cardBorder),
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Tokens.cardBorder,
                  borderRadius: BorderRadius.circular(Tokens.radiusProgress),
                ),
              ),
              const SizedBox(height: 16),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}
