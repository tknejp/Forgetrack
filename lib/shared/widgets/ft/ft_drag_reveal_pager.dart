import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FtEdgeHandoffDirection {
  previous,
  next,
}

class FtDragRevealPager<T> extends StatefulWidget {
  const FtDragRevealPager({
    super.key,
    required this.item,
    required this.hasPrevious,
    required this.hasNext,
    required this.previousOf,
    required this.nextOf,
    required this.builder,
    required this.onCommit,
    this.pageGap = 0,
    this.commitThreshold = 0.25,
    this.velocityThreshold = 300,
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
  State<FtDragRevealPager<T>> createState() => _FtDragRevealPagerState<T>();
}

class _FtDragRevealPagerState<T> extends State<FtDragRevealPager<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _offsetController;
  double _viewportWidth = 0;

  double get _dragOffset => _offsetController.value;
  bool get _hasPrevious => widget.hasPrevious(widget.item);
  bool get _hasNext => widget.hasNext(widget.item);
  double get _pageSpan => _viewportWidth + widget.pageGap;

  @override
  void initState() {
    super.initState();
    _offsetController = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant FtDragRevealPager<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item && !_offsetController.isAnimating) {
      _offsetController.value = 0;
    }
  }

  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
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
        final dragOffset = _dragOffset.clamp(-_pageSpan, _pageSpan);
        final previousItem = dragOffset > 0 && _hasPrevious
            ? widget.previousOf(widget.item)
            : null;
        final nextItem =
            dragOffset < 0 && _hasNext ? widget.nextOf(widget.item) : null;

        Widget wrapItem(Widget child) => SizedBox(
              width: _viewportWidth,
              child: child,
            );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          onHorizontalDragCancel: _handleHorizontalDragCancel,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                if (previousItem != null)
                  Transform.translate(
                    offset: Offset(dragOffset - _pageSpan, 0),
                    child: wrapItem(widget.builder(context, previousItem)),
                  ),
                if (nextItem != null)
                  Transform.translate(
                    offset: Offset(dragOffset + _pageSpan, 0),
                    child: wrapItem(widget.builder(context, nextItem)),
                  ),
                Transform.translate(
                  offset: Offset(dragOffset, 0),
                  child: wrapItem(widget.builder(context, widget.item)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FtEdgePageHandoff extends StatefulWidget {
  const FtEdgePageHandoff({
    super.key,
    required this.child,
    required this.controller,
    required this.currentPage,
    required this.targetPage,
    required this.isEnabled,
    this.commitThreshold = 0.25,
    this.velocityThreshold = 300,
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
  State<FtEdgePageHandoff> createState() => _FtEdgePageHandoffState();
}

class _FtEdgePageHandoffState extends State<FtEdgePageHandoff> {
  Offset? _startPosition;
  Duration? _startTimeStamp;
  bool _handoffActive = false;
  double? _basePixels;

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
    _startTimeStamp = null;
    _handoffActive = false;
    _basePixels = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _startPosition = event.position;
    _startTimeStamp = event.timeStamp;
    _handoffActive = false;
    _basePixels = null;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final startPosition = _startPosition;
    if (startPosition == null || !widget.controller.hasClients) return;

    final delta = event.position - startPosition;
    if (!_handoffActive) {
      if (!widget.isEnabled()) return;
      if (delta.dx.abs() < 12) return;
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
    final startPosition = _startPosition;
    final startTimeStamp = _startTimeStamp;
    if (width <= 0 || startPosition == null || startTimeStamp == null) {
      _reset();
      return;
    }

    final elapsed = math.max(
        1, endTimeStamp.inMicroseconds - startTimeStamp.inMicroseconds);
    final velocity = (endPosition.dx - startPosition.dx) /
        (elapsed / Duration.microsecondsPerSecond).toDouble();
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
