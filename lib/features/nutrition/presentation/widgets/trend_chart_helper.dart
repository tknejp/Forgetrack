import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../../shared/widgets/trend_chart.dart';

/// Thin wrapper that gives the bare [TrendChart] the same scroll-to-end
/// behavior the `TrendCard` uses for `scrollableMinBarWidth`. Lets us drop
/// a chart anywhere (not just inside `TrendCard`) without re-implementing
/// the controller plumbing.
class TrendChartHelper extends StatefulWidget {
  const TrendChartHelper({
    super.key,
    required this.bars,
    required this.domain,
    this.referenceValue,
    this.onBarTap,
    this.scrollableMinBarWidth,
    this.height = 188,
  });

  final List<ChartBar> bars;
  final Domain domain;
  final double? referenceValue;
  final ValueChanged<int>? onBarTap;
  final double? scrollableMinBarWidth;
  final double height;

  @override
  State<TrendChartHelper> createState() => _TrendChartHelperState();
}

class _TrendChartHelperState extends State<TrendChartHelper> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(covariant TrendChartHelper old) {
    super.didUpdateWidget(old);
    if (old.bars.length != widget.bars.length) _scheduleScrollToEnd();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _scheduleScrollToEnd() {
    if (widget.scrollableMinBarWidth == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_sc.hasClients && _sc.position.maxScrollExtent > 0) {
        _sc.jumpTo(_sc.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chart = TrendChart(
      bars: widget.bars,
      domain: widget.domain,
      height: widget.height,
      referenceValue: widget.referenceValue,
      onBarTap: widget.onBarTap,
    );
    if (widget.scrollableMinBarWidth == null) return chart;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const gapW = 5.0;
        final n = widget.bars.length;
        final naturalW = n * widget.scrollableMinBarWidth! + (n - 1) * gapW;
        final chartW =
            naturalW > constraints.maxWidth ? naturalW : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _sc,
          child: SizedBox(width: chartW, child: chart),
        );
      },
    );
  }
}
