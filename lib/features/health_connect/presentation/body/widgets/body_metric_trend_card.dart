import 'package:flutter/material.dart';

import '../../../../../shared/theme/design_tokens.dart';
import '../../../../../shared/widgets/trend_chart.dart';
import 'body_period.dart';

class BodyMetricTileData {
  const BodyMetricTileData({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;
}

class BodyMetricTrendCard extends StatelessWidget {
  const BodyMetricTrendCard({
    super.key,
    required this.cardId,
    required this.title,
    required this.icon,
    required this.domain,
    required this.expanded,
    required this.onToggle,
    required this.range,
    required this.dateLabel,
    required this.emptyLabel,
    this.showEmptyLabel = true,
    required this.metrics,
    required this.bars,
    this.referenceValue,
    this.referenceLabel,
    this.onBarTap,
    this.showTrendLine = false,
  });

  final String cardId;
  final String title;
  final IconData icon;
  final Domain domain;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final BodyRange range;
  final String dateLabel;
  final String emptyLabel;
  final bool showEmptyLabel;
  final List<BodyMetricTileData> metrics;
  final List<ChartBar> bars;
  final double? referenceValue;
  final String? referenceLabel;
  final ValueChanged<int>? onBarTap;
  final bool showTrendLine;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggle(cardId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: domain.cardDecoration(),
          child: Column(
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
                      boxShadow: [
                        BoxShadow(
                          color: domain.glow.withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 18, color: domain.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeBody,
                            fontWeight: FontWeight.w700,
                            color: ft.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: Tokens.fontSizeCaption,
                            fontWeight: FontWeight.w500,
                            color: ft.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ft.onSurfaceMuted,
                    size: 24,
                  ),
                ],
              ),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  heightFactor: expanded ? 1.0 : 0.0,
                  child: RepaintBoundary(
                    child: _ExpandedMetricBody(
                      metrics: metrics,
                      bars: bars,
                      domain: domain,
                      emptyLabel: emptyLabel,
                      showEmptyLabel: showEmptyLabel,
                      referenceValue: referenceValue,
                      referenceLabel: referenceLabel,
                      onBarTap: onBarTap,
                      showTrendLine: showTrendLine,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedMetricBody extends StatefulWidget {
  const _ExpandedMetricBody({
    required this.metrics,
    required this.bars,
    required this.domain,
    required this.emptyLabel,
    required this.showTrendLine,
    this.showEmptyLabel = true,
    this.referenceValue,
    this.referenceLabel,
    this.onBarTap,
  });

  final List<BodyMetricTileData> metrics;
  final List<ChartBar> bars;
  final Domain domain;
  final String emptyLabel;
  final bool showEmptyLabel;
  final double? referenceValue;
  final String? referenceLabel;
  final ValueChanged<int>? onBarTap;
  final bool showTrendLine;

  @override
  State<_ExpandedMetricBody> createState() => _ExpandedMetricBodyState();
}

class _ExpandedMetricBodyState extends State<_ExpandedMetricBody> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(_ExpandedMetricBody old) {
    super.didUpdateWidget(old);
    if (old.bars.length != widget.bars.length) {
      _scheduleScrollToEnd();
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _scheduleScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients && _sc.position.maxScrollExtent > 0) {
        _sc.jumpTo(_sc.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Tokens.spaceMd),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            for (final metric in widget.metrics)
              _CompositionMetric(
                label: metric.label,
                value: metric.value,
                color: metric.color ?? widget.domain.color,
              ),
          ],
        ),
        const SizedBox(height: Tokens.spaceMd),
        if (widget.bars.isEmpty && widget.showEmptyLabel)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                widget.emptyLabel,
                style: TextStyle(fontSize: 13, color: ft.onSurfaceMuted),
              ),
            ),
          )
        else if (widget.bars.isNotEmpty) ...[
          LayoutBuilder(
            builder: (ctx, constraints) {
              const minBarW = 34.0;
              const gapW = 5.0;
              final n = widget.bars.length;
              final naturalW = n * minBarW + (n - 1) * gapW;
              final chartW = naturalW > constraints.maxWidth
                  ? naturalW
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _sc,
                child: SizedBox(
                  width: chartW,
                  child: TrendChart(
                    bars: widget.bars,
                    domain: widget.domain,
                    height: 188,
                    relativeScale: true,
                    referenceValue: widget.referenceValue,
                    onBarTap: widget.onBarTap,
                    showTrendLine: widget.showTrendLine,
                  ),
                ),
              );
            },
          ),
          if (widget.referenceValue != null &&
              widget.referenceLabel != null) ...[
            const SizedBox(height: 10),
            _WeightReferencePill(
              label:
                  '${widget.referenceLabel} ${_formatMetricValue(widget.referenceValue!)}',
              color: widget.domain.color,
            ),
          ],
        ],
      ],
    );
  }

  String _formatMetricValue(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _CompositionMetric extends StatelessWidget {
  const _CompositionMetric({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ft.surfaceSubtle,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: ft.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: FontWeight.w600,
              color: ft.onSurfaceMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: Tokens.spaceXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color ?? Tokens.weight.color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightReferencePill extends StatelessWidget {
  const _WeightReferencePill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

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
