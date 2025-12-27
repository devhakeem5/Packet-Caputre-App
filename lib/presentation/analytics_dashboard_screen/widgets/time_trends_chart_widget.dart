import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TimeTrendsChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> trendsData;
  final String period;

  const TimeTrendsChartWidget({
    super.key,
    required this.trendsData,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxRequests = trendsData.fold<int>(
      0,
      (max, item) => item['requests'] > max ? item['requests'] : max,
    );

    return Container(
      height: 30.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Semantics(
        label: 'Time Trends Line Chart showing request patterns over time',
        child: LineChart(
          LineChartData(
            maxY: maxRequests.toDouble() * 1.2,
            minY: 0,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < trendsData.length) {
                      return LineTooltipItem(
                        '${trendsData[index]['time']}\n${spot.y.toInt()} requests',
                        theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < trendsData.length) {
                      final showEvery = period == '24h'
                          ? 4
                          : period == '7d'
                          ? 1
                          : 5;
                      if (index % showEvery == 0) {
                        return Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Text(
                            trendsData[index]['time'].toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                            ),
                          ),
                        );
                      }
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(1)}k',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxRequests / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: trendsData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value['requests'].toDouble(),
                  );
                }).toList(),
                isCurved: true,
                color: theme.colorScheme.secondary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.secondary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
