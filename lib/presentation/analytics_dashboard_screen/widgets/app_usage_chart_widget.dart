import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppUsageChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appUsageData;

  const AppUsageChartWidget({super.key, required this.appUsageData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxRequests = appUsageData.fold<int>(
      0,
      (max, app) => app['requests'] > max ? app['requests'] : max,
    );

    return Container(
      height: 35.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Semantics(
              label: 'App Usage Bar Chart showing requests by application',
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxRequests.toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final app = appUsageData[groupIndex];
                        return BarTooltipItem(
                          '${app['app']}\n${app['requests']} requests\n${app['data']}',
                          theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < appUsageData.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                appUsageData[value.toInt()]['app']
                                    .toString()
                                    .substring(0, 3),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            );
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
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
                  barGroups: appUsageData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['requests'].toDouble(),
                          color: theme.colorScheme.secondary,
                          width: 8.w,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
