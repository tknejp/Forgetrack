import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'ft_expand_chevron.dart';

class ChartBar {
  final String label;
  final double value;
  final bool isToday;

  const ChartBar({
    required this.label,
    required this.value,
    this.isToday = false,
  });
}

class TrendMetric {
  final String label;
  final String value;
  final Color? color;

  const TrendMetric({
    required this.label,
    required this.value,
    this.color,
  });
}

class TrendCard extends StatefulWidget {
  final Domain domain;
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<TrendMetric> metrics;
  final List<ChartBar> bars;
  final bool relativeScale;
  final double? referenceValue;
  final String? referenceLabel;
  final String emptyLabel;
  final bool expandable;
  final bool collapsible;
  final bool initiallyExpanded;
  final double chartHeight;
  final double expandedChartHeight;
  final ValueChanged<int>? onBarTap;
  final bool showTrendLine;

  const TrendCard({
    super.key,
    required this.domain,
    required this.icon,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    required this.bars,
    this.relativeScale = false,
    this.referenceValue,
    this.referenceLabel,
    required this.emptyLabel,
    this.expandable = true,
    this.collapsible = true,
    this.initiallyExpanded = false,
    this.chartHeight = 132,
    this.expandedChartHeight = 176,
    this.onBarTap,
    this.showTrendLine = false,
  });

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.collapsible ? widget.initiallyExpanded : true;
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final domain = widget.domain;

    return GestureDetector(
      onTap: widget.expandable && widget.collapsible
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: domain.cardDecoration(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final effectiveHeight = _expanded
                ? widget.expandedChartHeight - (isCompact ? 12 : 0)
                : widget.chartHeight - (isCompact ? 10 : 0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: domain.dim,
                        borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                        border: Border.all(
                          color: domain.color.withValues(alpha: 0.27),
                        ),
                      ),
                      child: Icon(widget.icon, size: 18, color: domain.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: Tokens.fontSizeBody,
                              fontWeight: FontWeight.w700,
                              color: ft.onSurface,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: Tokens.fontSizeCaption,
                                fontWeight: FontWeight.w500,
                                color: ft.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.expandable && widget.collapsible)
                      ExpandChevron(expanded: _expanded),
                  ],
                ),
                if (widget.metrics.isNotEmpty) ...[
                  const SizedBox(height: Tokens.spaceMd),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final metric in widget.metrics)
                        _TrendMetricChip(
                          metric: metric,
                          accent: domain.color,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Tokens.spaceMd),
                if (widget.bars.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        widget.emptyLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: ft.onSurfaceMuted,
                        ),
                      ),
                    ),
                  )
                else ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    child: TrendChart(
                      bars: widget.bars,
                      domain: domain,
                      height: effectiveHeight,
                      relativeScale: widget.relativeScale,
                      referenceValue: widget.referenceValue,
                      onBarTap: widget.onBarTap,
                      showTrendLine: widget.showTrendLine,
                    ),
                  ),
                  if (widget.referenceValue != null &&
                      widget.referenceLabel != null) ...[
                    const SizedBox(height: 10),
                    _ReferencePill(
                      label:
                          '${widget.referenceLabel!} ${_formatMetricValue(widget.referenceValue!)}',
                      color: domain.color,
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatMetricValue(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class TrendChart extends StatelessWidget {
  final List<ChartBar> bars;
  final Domain domain;
  final double height;
  final bool relativeScale;
  final double? referenceValue;
  final ValueChanged<int>? onBarTap;
  final bool showTrendLine;

  const TrendChart({
    super.key,
    required this.bars,
    required this.domain,
    this.height = 96,
    this.relativeScale = false,
    this.referenceValue,
    this.onBarTap,
    this.showTrendLine = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return SizedBox(height: height);

    final values = [
      ...bars.map((bar) => bar.value),
      if (referenceValue != null) referenceValue!,
    ];

    var maxVal = values.reduce((a, b) => a > b ? a : b);
    var minVal = relativeScale ? values.reduce((a, b) => a < b ? a : b) : 0.0;
    if ((maxVal - minVal).abs() < 0.001) {
      maxVal += relativeScale ? 0.5 : 1;
      minVal -= relativeScale ? 0.5 : 0;
    }
    if (relativeScale) {
      final padding = ((maxVal - minVal).abs() * 0.08).clamp(0.15, 2.0);
      maxVal += padding;
      minVal -= padding;
      // Keep reference line at least 18 % above the chart floor so it stays visible.
      if (referenceValue != null) {
        final refPct = (referenceValue! - minVal) / (maxVal - minVal);
        if (refPct < 0.18) {
          minVal = (referenceValue! - 0.18 * maxVal) / 0.82;
        }
      }
    }
    final range = (maxVal - minVal).clamp(0.001, double.infinity).toDouble();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 340;
          final gap = bars.length >= 10 || isCompact ? 4.0 : 6.0;
          final valueAreaH =
              bars.any((bar) => bar.isToday) ? (isCompact ? 18.0 : 22.0) : 0.0;
          final labelAreaH = isCompact ? 16.0 : 20.0;
          final chartAreaH =
              (constraints.maxHeight - valueAreaH - labelAreaH - 4)
                  .clamp(28.0, constraints.maxHeight)
                  .toDouble();
          final referencePct = referenceValue == null
              ? null
              : ((referenceValue! - minVal) / range).clamp(0.0, 1.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (valueAreaH > 0)
                SizedBox(
                  height: valueAreaH,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < bars.length; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: bars[i].isToday
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatValue(bars[i].value),
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: Tokens.fontSizeTiny,
                                        fontWeight: FontWeight.w700,
                                        color: domain.color,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              SizedBox(
                height: chartAreaH,
                child: Stack(
                  children: [
                    if (referencePct != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: (referencePct * chartAreaH)
                            .clamp(0.0, chartAreaH - 1),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: domain.color.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: domain.glow.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < bars.length; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: _Bar(
                              bar: bars[i],
                              minVal: minVal,
                              range: range,
                              domain: domain,
                              barAreaH: chartAreaH,
                              onTap:
                                  onBarTap == null ? null : () => onBarTap!(i),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showTrendLine && bars.length >= 2)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _TrendLinePainter(
                              bars: bars,
                              minVal: minVal,
                              range: range,
                              gap: gap,
                              color: domain.color,
                              glow: domain.glow,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Tokens.spaceXs),
              SizedBox(
                height: labelAreaH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < bars.length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: Center(
                          child: _ChartLabel(
                            label: _shouldShowLabel(i, bars.length, isCompact)
                                ? bars[i].label
                                : '',
                            isToday: bars[i].isToday,
                            color: domain.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowLabel(int index, int length, bool isCompact) {
    if (!isCompact || length <= 7) return true;
    if (length <= 10) return index.isEven || index == length - 1;
    final stride = (length / 5).ceil();
    return index == 0 || index == length - 1 || index % stride == 0;
  }

  String _formatValue(double value) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _Bar extends StatelessWidget {
  final ChartBar bar;
  final double minVal;
  final double range;
  final Domain domain;
  final double barAreaH;
  final VoidCallback? onTap;

  const _Bar({
    required this.bar,
    required this.minVal,
    required this.range,
    required this.domain,
    required this.barAreaH,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((bar.value - minVal) / range).clamp(0.0, 1.0);
    final barH = (pct * barAreaH).clamp(4.0, barAreaH).toDouble();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          height: barH,
          decoration: BoxDecoration(
            gradient: bar.isToday
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      domain.color,
                      domain.color.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: bar.isToday ? null : domain.color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(5),
            boxShadow: bar.isToday
                ? [BoxShadow(color: domain.glow, blurRadius: 10)]
                : null,
          ),
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.bars,
    required this.minVal,
    required this.range,
    required this.gap,
    required this.color,
    required this.glow,
  });

  final List<ChartBar> bars;
  final double minVal;
  final double range;
  final double gap;
  final Color color;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.length < 2 || size.width <= 0 || size.height <= 0) return;

    // Least-squares linear regression over bar indices vs values.
    final n = bars.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += bars[i].value;
      sumXY += i * bars[i].value;
      sumXX += i * i.toDouble();
    }
    final denom = n * sumXX - sumX * sumX;
    if (denom.abs() < 0.001) return;
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;

    final barWidth = (size.width - gap * (n - 1)) / n;

    double xOf(int i) => i * (barWidth + gap) + barWidth / 2;
    double yOf(double val) =>
        size.height - ((val - minVal) / range).clamp(0.0, 1.0) * size.height;

    final p1 = Offset(xOf(0), yOf(intercept));
    final p2 = Offset(xOf(n - 1), yOf(intercept + slope * (n - 1)));

    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawLine(p1, p2, glowPaint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.minVal != minVal ||
        oldDelegate.range != range ||
        oldDelegate.gap != gap ||
        oldDelegate.color != color ||
        oldDelegate.glow != glow;
  }
}

class _ChartLabel extends StatelessWidget {
  final String label;
  final bool isToday;
  final Color color;

  const _ChartLabel({
    required this.label,
    required this.isToday,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    if (label.isEmpty) return const SizedBox.shrink();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: Tokens.fontSizeTiny,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          color: isToday ? color : ft.onSurfaceFaint,
        ),
      ),
    );
  }
}

class _TrendMetricChip extends StatelessWidget {
  final TrendMetric metric;
  final Color accent;

  const _TrendMetricChip({
    required this.metric,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final valueColor = metric.color ?? accent;

    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label.toUpperCase(),
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: ft.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferencePill extends StatelessWidget {
  final String label;
  final Color color;

  const _ReferencePill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 2,
            color: color.withValues(alpha: 0.45),
          ),
          const SizedBox(width: Tokens.spaceSm),
          Text(
            label,
            style: TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w600,
              color: ft.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
