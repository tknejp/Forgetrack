import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum FtEdgeHandoffDirection {
  previous,
  next,
}

class DragRevealPager<T> extends StatefulWidget {
  const DragRevealPager({
    super.key,
    required this.item,
    required this.hasPrevious,
    required this.hasNext,
    required this.previousOf,
    required this.nextOf,
    required this.builder,
    required this.onCommit,
    this.pageGap = 0,
    this.commitThreshold = 0.12,
    this.velocityThreshold = 120,
  });

  final T item;
  final bool Function(T item) hasPrevious;
  final bool Function(T item) hasNext;
  final T Function(T item) previousOf;
  final T Function(T item) nextOf;
  final Widget Function(BuildContext context, T item) builder;
  final ValueChanged<T> onCommit;
  final double pageGap;
  final double commitThreshold;
  final double velocityThreshold;

  @override
  State<DragRevealPager<T>> createState() => _DragRevealPagerState<T>();
}

class _DragRevealPagerState<T> extends State<DragRevealPager<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offsetController;
  double _viewportWidth = 0;

  // Side (previous/next) pages are pre-warmed one frame after the current
  // item paints. Building them lazily at drag-start used to drop the first
  // frame of the swipe (heavy DayContent build), which felt like the gesture
  // was fighting the user. The wall cost at rest is acceptable — pages are
  // wrapped in RepaintBoundary so they don't repaint while idle.
  bool _sidePagesActive = false;

  double get _dragOffset => _offsetController.value;
  bool get _hasPrevious => widget.hasPrevious(widget.item);
  bool get _hasNext => widget.hasNext(widget.item);
  double get _pageSpan => _viewportWidth + widget.pageGap;

  @override
  void initState() {
    super.initState();
    // No setState listener — AnimatedBuilder below subscribes to the
    // controller and rebuilds only the Transform.translate wrappers, not the
    // cached page subtrees.
    _offsetController = AnimationController.unbounded(vsync: this);
    _scheduleSidePageWarmup();
  }

  @override
  void didUpdateWidget(covariant DragRevealPager<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      if (!_offsetController.isAnimating) {
        _offsetController.value = 0;
      }
      // After a commit the side identities change — rebuild them next frame
      // so the new current page paints first.
      _sidePagesActive = false;
      _scheduleSidePageWarmup();
    }
  }

  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
  }

  void _scheduleSidePageWarmup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sidePagesActive) return;
      setState(() => _sidePagesActive = true);
    });
  }

  void _setDragOffset(double value) {
    if ((_dragOffset - value).abs() < 0.1) return;
    _offsetController.value = value;
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (_offsetController.isAnimating) {
      _offsetController.stop();
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_viewportWidth <= 0) return;

    var nextOffset = _dragOffset + details.delta.dx;
    if (nextOffset > 0 && !_hasPrevious) nextOffset = 0;
    if (nextOffset < 0 && !_hasNext) nextOffset = 0;
    nextOffset = nextOffset.clamp(-_pageSpan, _pageSpan);
    _setDragOffset(nextOffset);
  }

  Future<void> _animateToOffset(
    double targetOffset, {
    T? committedItem,
  }) async {
    if ((_dragOffset - targetOffset).abs() < 0.1) {
      if (committedItem != null) {
        widget.onCommit(committedItem);
      }
      _offsetController.value = 0;
      return;
    }

    await _offsetController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    if (committedItem != null) {
      widget.onCommit(committedItem);
    }
    _offsetController.value = 0;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_viewportWidth <= 0 || _dragOffset.abs() < 0.1) {
      _offsetController.value = 0;
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final progress = _dragOffset.abs() / _pageSpan;

    if (_dragOffset > 0 && _hasPrevious) {
      final shouldCommit = progress >= widget.commitThreshold ||
          velocity >= widget.velocityThreshold;
      _animateToOffset(
        shouldCommit ? _pageSpan : 0,
        committedItem: shouldCommit ? widget.previousOf(widget.item) : null,
      );
      return;
    }

    if (_dragOffset < 0 && _hasNext) {
      final shouldCommit = progress >= widget.commitThreshold ||
          velocity <= -widget.velocityThreshold;
      _animateToOffset(
        shouldCommit ? -_pageSpan : 0,
        committedItem: shouldCommit ? widget.nextOf(widget.item) : null,
      );
      return;
    }

    _animateToOffset(0);
  }

  void _handleHorizontalDragCancel() {
    if (_dragOffset.abs() < 0.1) return;
    _animateToOffset(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final viewportWidth = _viewportWidth;
        final pageSpan = _pageSpan;
        final hasPrevious = _hasPrevious;
        final hasNext = _hasNext;

        // Build each page once per parent rebuild and wrap it in a
        // RepaintBoundary so the rasterized layer can be re-translated by
        // Impeller without re-painting the subtree on every animation tick.
        Widget wrapItem(Widget child) => RepaintBoundary(
              child: SizedBox(width: viewportWidth, child: child),
            );

        final currentPage = wrapItem(widget.builder(context, widget.item));
        final previousPage = (_sidePagesActive && hasPrevious)
            ? wrapItem(widget.builder(context, widget.previousOf(widget.item)))
            : null;
        final nextPage = (_sidePagesActive && hasNext)
            ? wrapItem(widget.builder(context, widget.nextOf(widget.item)))
            : null;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          onHorizontalDragCancel: _handleHorizontalDragCancel,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _offsetController,
              builder: (context, _) {
                final dragOffset = _dragOffset.clamp(-pageSpan, pageSpan);
                final showPrevious = dragOffset > 0 && previousPage != null;
                final showNext = dragOffset < 0 && nextPage != null;
                return Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    if (showPrevious)
                      Transform.translate(
                        offset: Offset(dragOffset - pageSpan, 0),
                        child: previousPage,
                      ),
                    if (showNext)
                      Transform.translate(
                        offset: Offset(dragOffset + pageSpan, 0),
                        child: nextPage,
                      ),
                    Transform.translate(
                      offset: Offset(dragOffset, 0),
                      child: currentPage,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class EdgePageHandoff extends StatefulWidget {
  const EdgePageHandoff({
    super.key,
    required this.child,
    required this.controller,
    required this.currentPage,
    required this.targetPage,
    required this.isEnabled,
    this.commitThreshold = 0.12,
    this.velocityThreshold = 120,
  }) : assert(currentPage != targetPage);

  final Widget child;
  final PageController controller;
  final int currentPage;
  final int targetPage;
  final bool Function() isEnabled;
  final double commitThreshold;
  final double velocityThreshold;

  FtEdgeHandoffDirection get direction => targetPage < currentPage
      ? FtEdgeHandoffDirection.previous
      : FtEdgeHandoffDirection.next;

  @override
  State<EdgePageHandoff> createState() => _EdgePageHandoffState();
}

class _EdgePageHandoffState extends State<EdgePageHandoff> {
  Offset? _startPosition;
  bool _handoffActive = false;
  double? _basePixels;
  VelocityTracker? _velocityTracker;

  bool _matchesDirection(double deltaX) {
    switch (widget.direction) {
      case FtEdgeHandoffDirection.previous:
        return deltaX > 0;
      case FtEdgeHandoffDirection.next:
        return deltaX < 0;
    }
  }

  double _pagePixels(int page, double width) => page * width;

  void _reset() {
    _startPosition = null;
    _handoffActive = false;
    _basePixels = null;
    _velocityTracker = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _startPosition = event.position;
    _handoffActive = false;
    _basePixels = null;
    _velocityTracker = VelocityTracker.withKind(event.kind);
    _velocityTracker!.addPosition(event.timeStamp, event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final startPosition = _startPosition;
    if (startPosition == null || !widget.controller.hasClients) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);

    final delta = event.position - startPosition;
    if (!_handoffActive) {
      if (!widget.isEnabled()) return;
      // Lowered from 12 px to 6 px so the handoff engages almost immediately
      // when the user continues sliding past the day-pager edge — the prior
      // deadband felt like a hitch between the two horizontal swipes.
      if (delta.dx.abs() < 6) return;
      if (delta.dx.abs() <= delta.dy.abs() + 4) return;
      if (!_matchesDirection(delta.dx)) return;

      final position = widget.controller.position;
      if (!position.hasViewportDimension) return;
      _handoffActive = true;
      _basePixels = position.pixels;
    }

    final position = widget.controller.position;
    final width = position.viewportDimension;
    final minPixels =
        _pagePixels(math.min(widget.currentPage, widget.targetPage), width);
    final maxPixels =
        _pagePixels(math.max(widget.currentPage, widget.targetPage), width);
    final nextPixels =
        (_basePixels! - delta.dx).clamp(minPixels, maxPixels).toDouble();

    if ((position.pixels - nextPixels).abs() < 0.1) return;
    widget.controller.jumpTo(nextPixels);
  }

  void _handlePointerEnd({
    required Offset endPosition,
    required Duration endTimeStamp,
  }) {
    if (!_handoffActive || !widget.controller.hasClients) {
      _reset();
      return;
    }

    final position = widget.controller.position;
    final width =
        position.hasViewportDimension ? position.viewportDimension : 0.0;
    if (width <= 0) {
      _reset();
      return;
    }

    // Use the velocity tracker's lift-time estimate (last ~100 ms of motion)
    // instead of averaging over the whole drag. Averaging snap-backed on
    // gestures where the user flicked then paused before lifting — the
    // average was low even though the lift felt fast.
    final velocity =
        _velocityTracker?.getVelocity().pixelsPerSecond.dx ?? 0.0;
    final progress =
        (position.pixels - _pagePixels(widget.currentPage, width)).abs() /
            width;
    final shouldCommit = progress >= widget.commitThreshold ||
        (_matchesDirection(velocity) &&
            velocity.abs() >= widget.velocityThreshold);

    widget.controller.animateToPage(
      shouldCommit ? widget.targetPage : widget.currentPage,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (event) => _handlePointerEnd(
        endPosition: event.position,
        endTimeStamp: event.timeStamp,
      ),
      onPointerCancel: (_) {
        if (widget.controller.hasClients) {
          widget.controller.animateToPage(
            widget.currentPage,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
        _reset();
      },
      child: widget.child,
    );
  }
}
