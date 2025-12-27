import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ProtocolDistributionChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> protocolData;

  const ProtocolDistributionChartWidget({
    super.key,
    required this.protocolData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.secondary,
      const Color(0xFF38A169),
      const Color(0xFFD69E2E),
      theme.colorScheme.onSurfaceVariant,
    ];

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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Semantics(
              label: 'Protocol Distribution Pie Chart',
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 12.w,
                  sections: protocolData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return PieChartSectionData(
                      value: data['value'].toDouble(),
                      title: '${data['percentage'].toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 15.w,
                      titleStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: protocolData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.5.h),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${data['value']} requests',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
