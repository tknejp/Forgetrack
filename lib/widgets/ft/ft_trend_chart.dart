import 'package:flutter/material.dart';

import '../../theme/ft_design_tokens.dart';

class FtChartBar {
  final String label;
  final double value;
  final bool isToday;

  const FtChartBar({
    required this.label,
    required this.value,
    this.isToday = false,
  });
}

class FtTrendMetric {
  final String label;
  final String value;
  final Color? color;

  const FtTrendMetric({
    required this.label,
    required this.value,
    this.color,
  });
}

class FtTrendCard extends StatefulWidget {
  final FtDomain domain;
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<FtTrendMetric> metrics;
  final List<FtChartBar> bars;
  final bool relativeScale;
  final double? referenceValue;
  final String? referenceLabel;
  final String emptyLabel;
  final bool expandable;
  final bool initiallyExpanded;
  final double chartHeight;
  final double expandedChartHeight;

  const FtTrendCard({
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
    this.initiallyExpanded = false,
    this.chartHeight = 132,
    this.expandedChartHeight = 176,
  });

  @override
  State<FtTrendCard> createState() => _FtTrendCardState();
}

class _FtTrendCardState extends State<FtTrendCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final domain = widget.domain;

    return GestureDetector(
      onTap: widget.expandable ? () => setState(() => _expanded = !_expanded) : null,
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
                        borderRadius: BorderRadius.circular(FtTokens.radiusIcon),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: FtTokens.onSurface,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                fontSize: FtTokens.fontSizeCaption,
                                fontWeight: FontWeight.w500,
                                color: FtTokens.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.expandable)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Color(0x66FFFFFF),
                        ),
                      ),
                  ],
                ),
                if (widget.metrics.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                if (widget.bars.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        widget.emptyLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: FtTokens.onSurfaceMuted,
                        ),
                      ),
                    ),
                  )
                else ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    child: FtTrendChart(
                      bars: widget.bars,
                      domain: domain,
                      height: effectiveHeight,
                      relativeScale: widget.relativeScale,
                      referenceValue: widget.referenceValue,
                    ),
                  ),
                  if (widget.referenceValue != null && widget.referenceLabel != null) ...[
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

class FtTrendChart extends StatelessWidget {
  final List<FtChartBar> bars;
  final FtDomain domain;
  final double height;
  final bool relativeScale;
  final double? referenceValue;

  const FtTrendChart({
    super.key,
    required this.bars,
    required this.domain,
    this.height = 96,
    this.relativeScale = false,
    this.referenceValue,
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
    final range = (maxVal - minVal).clamp(0.001, double.infinity).toDouble();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 340;
          final gap = bars.length >= 10 || isCompact ? 4.0 : 6.0;
          final valueAreaH = bars.any((bar) => bar.isToday)
              ? (isCompact ? 18.0 : 22.0)
              : 0.0;
          final labelAreaH = isCompact ? 16.0 : 20.0;
          final chartAreaH = (constraints.maxHeight - valueAreaH - labelAreaH - 4)
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
                                        fontSize: FtTokens.fontSizeTiny,
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
                        bottom: (referencePct * chartAreaH).clamp(0.0, chartAreaH - 1),
                        child: Container(
                          height: 1,
                          color: domain.color.withValues(alpha: 0.28),
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
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
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
  final FtChartBar bar;
  final double minVal;
  final double range;
  final FtDomain domain;
  final double barAreaH;

  const _Bar({
    required this.bar,
    required this.minVal,
    required this.range,
    required this.domain,
    required this.barAreaH,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((bar.value - minVal) / range).clamp(0.0, 1.0);
    final barH = (pct * barAreaH).clamp(4.0, barAreaH).toDouble();

    return Align(
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
    );
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
    if (label.isEmpty) return const SizedBox.shrink();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: FtTokens.fontSizeTiny,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          color: isToday ? color : const Color(0x59FFFFFF),
        ),
      ),
    );
  }
}

class _TrendMetricChip extends StatelessWidget {
  final FtTrendMetric metric;
  final Color accent;

  const _TrendMetricChip({
    required this.metric,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = metric.color ?? accent;

    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label.toUpperCase(),
            style: const TextStyle(
              fontSize: FtTokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: FtTokens.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 2,
            color: color.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: FtTokens.fontSizeCaption,
              fontWeight: FontWeight.w600,
              color: FtTokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
