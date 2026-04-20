part of '../weight_card.dart';

class _WeightChart extends StatelessWidget {
  final List<WeightChartPoint> points;
  final WeightChartMode mode;
  final String locale;

  const _WeightChart({
    required this.points,
    required this.mode,
    required this.locale,
  });

  String _xLabel(DateTime date) {
    return switch (mode) {
      WeightChartMode.daily => DateFormat('E', locale).format(date),
      WeightChartMode.weekly => DateFormat('d.M.', locale).format(date),
      WeightChartMode.monthly => DateFormat('MMM', locale).format(date),
    };
  }

  @override
  Widget build(BuildContext context) {
    final weights = points.map((p) => p.weight).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b);
    final maxY = weights.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.25).clamp(0.3, 2.0);

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }

                final total = points.length;
                final show = idx == 0 ||
                    idx == total - 1 ||
                    (total > 4 && idx % (total ~/ 4) == 0);
                if (!show) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _xLabel(points[idx].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: context.tokens.body.accent,
            barWidth: 3,
            dotData: FlDotData(show: points.length <= 10),
            belowBarData: BarAreaData(
              show: true,
              color: context.tokens.body.accent.withValues(alpha: 0.12),
            ),
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].weight),
            ],
          ),
        ],
      ),
    );
  }
}
