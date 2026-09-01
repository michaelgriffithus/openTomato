import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../environment/domain/environment_range_evaluator.dart';
import '../contracts/today_contract.dart';

/// 24-hour trace of one metric with the stage band shaded.
class MetricTraceChart extends StatelessWidget {
  final TraceContract? trace;
  final EnvironmentMetric selected;
  final ValueChanged<EnvironmentMetric> onSelect;

  const MetricTraceChart({
    super.key,
    required this.trace,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final t = trace;
    return GlassCardLight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'LAST 24 HOURS',
                  style: AppTextStyles.sectionLabel
                      .copyWith(color: palette.textSecondary),
                ),
              ),
              SegmentedButton<EnvironmentMetric>(
                segments: [
                  for (final m in EnvironmentMetric.values)
                    ButtonSegment(
                      value: m,
                      label: Text(
                        m == EnvironmentMetric.temperature ? 'Temp' : m.label,
                      ),
                    ),
                ],
                selected: {selected},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (s) => onSelect(s.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: t == null || t.points.length < 2
                ? Center(
                    child: Text(
                      'Not enough readings yet.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: palette.textSecondary),
                    ),
                  )
                : _Chart(trace: t),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final TraceContract trace;

  const _Chart({required this.trace});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final startMs = trace.windowStart.millisecondsSinceEpoch.toDouble();
    final endMs = trace.windowEnd.millisecondsSinceEpoch.toDouble();
    final spots = [
      for (final p in trace.points)
        FlSpot(p.at.millisecondsSinceEpoch.toDouble(), p.value),
    ];
    final values = [
      for (final p in trace.points) p.value,
      trace.bandMin,
      trace.bandMax,
    ];
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15 + 0.01;
    final isVpd = trace.metric == EnvironmentMetric.vpd;

    LineChartBarData flat(double y) => LineChartBarData(
          spots: [FlSpot(startMs, y), FlSpot(endMs, y)],
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
        );

    return LineChart(
      LineChartData(
        minX: startMs,
        maxX: endMs,
        minY: minY - pad,
        maxY: maxY + pad,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: palette.chartGridLine, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                isVpd ? v.toStringAsFixed(1) : v.round().toString(),
                style: AppTextStyles.labelSmall
                    .copyWith(color: palette.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (endMs - startMs) / 4,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('H:mm')
                      .format(DateTime.fromMillisecondsSinceEpoch(v.toInt())),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: palette.textSecondary),
                ),
              ),
            ),
          ),
        ),
        betweenBarsData: [
          BetweenBarsData(
            fromIndex: 1,
            toIndex: 2,
            color: palette.rangeBarOptimal.withValues(alpha: .35),
          ),
        ],
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: palette.heroAccent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          flat(trace.bandMin),
          flat(trace.bandMax),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) => [
              for (final s in touched)
                if (s.barIndex == 0)
                  LineTooltipItem(
                    '${isVpd ? s.y.toStringAsFixed(2) : s.y.round()} ${trace.metric.unit}\n'
                    '${DateFormat('H:mm').format(DateTime.fromMillisecondsSinceEpoch(s.x.toInt()))}',
                    AppTextStyles.labelSmall
                        .copyWith(color: palette.textPrimary),
                  )
                else
                  null,
            ],
          ),
        ),
      ),
    );
  }
}
