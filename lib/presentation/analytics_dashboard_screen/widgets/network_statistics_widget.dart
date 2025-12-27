import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/custom_icon_widget.dart';

class NetworkStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statisticsData;

  const NetworkStatisticsWidget({super.key, required this.statisticsData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peakHours = statisticsData['peakHours'] as List<Map<String, dynamic>>;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak Usage Hours',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildPeakHoursGrid(context, peakHours),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'timer',
                  label: 'Avg Response',
                  value: statisticsData['avgResponseTime'],
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'check_circle',
                  label: 'Success Rate',
                  value: statisticsData['successRate'],
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'error',
                  label: 'Error Rate',
                  value: statisticsData['errorRate'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursGrid(
    BuildContext context,
    List<Map<String, dynamic>> peakHours,
  ) {
    final theme = Theme.of(context);
    final maxRequests = peakHours.fold<int>(
      0,
      (max, hour) => hour['requests'] > max ? hour['requests'] : max,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: peakHours.map((hour) {
        final heightPercentage = (hour['requests'] / maxRequests) * 100;
        return Column(
          children: [
            Container(
              width: 12.w,
              height: 12.h,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 12.w,
                height: (heightPercentage / 100) * 12.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              hour['hour'],
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.secondary,
          size: 24,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.25.h),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
