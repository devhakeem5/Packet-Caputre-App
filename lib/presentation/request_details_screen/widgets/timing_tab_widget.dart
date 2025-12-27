import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Timing tab widget displaying request lifecycle metrics
class TimingTabWidget extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const TimingTabWidget({super.key, required this.requestData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timingData = _extractTimingData();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Request Lifecycle'),
          SizedBox(height: 2.h),
          _buildTimingChart(context, timingData),
          SizedBox(height: 3.h),
          _buildSectionTitle(context, 'Timing Breakdown'),
          SizedBox(height: 1.h),
          _buildTimingList(context, timingData),
          SizedBox(height: 3.h),
          _buildSectionTitle(context, 'Summary'),
          SizedBox(height: 1.h),
          _buildSummaryCard(context, timingData),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTimingChart(BuildContext context, List<_TimingPhase> phases) {
    final theme = Theme.of(context);
    final totalTime = phases.fold<double>(
      0,
      (sum, phase) => sum + phase.duration,
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
        label: 'Request Timing Horizontal Bar Chart',
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: totalTime * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final phase = phases[groupIndex];
                  return BarTooltipItem(
                    '${phase.name}\n${phase.duration.toStringAsFixed(0)}ms',
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
                    if (value.toInt() >= 0 && value.toInt() < phases.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: Text(
                          phases[value.toInt()].shortName,
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
                      '${value.toInt()}ms',
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
              horizontalInterval: totalTime / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: phases.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.duration,
                    color: entry.value.color,
                    width: 8.w,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTimingList(BuildContext context, List<_TimingPhase> phases) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: phases.asMap().entries.map((entry) {
          final index = entry.key;
          final phase = entry.value;
          return Column(
            children: [
              _buildTimingItem(context, phase),
              if (index < phases.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimingItem(BuildContext context, _TimingPhase phase) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4.h,
            decoration: BoxDecoration(
              color: phase.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (phase.description != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    phase.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${phase.duration.toStringAsFixed(0)}ms',
            style: AppTheme.getMonospaceStyle(
              isLight: theme.brightness == Brightness.light,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<_TimingPhase> phases) {
    final theme = Theme.of(context);
    final totalTime = phases.fold<double>(
      0,
      (sum, phase) => sum + phase.duration,
    );
    final slowestPhase = phases.reduce(
      (a, b) => a.duration > b.duration ? a : b,
    );

    return Container(
      width: double.infinity,
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
          _buildSummaryRow(
            context,
            'Total Time',
            '${totalTime.toStringAsFixed(0)}ms',
            theme.colorScheme.secondary,
          ),
          SizedBox(height: 1.5.h),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          SizedBox(height: 1.5.h),
          _buildSummaryRow(
            context,
            'Slowest Phase',
            slowestPhase.name,
            slowestPhase.color,
          ),
          SizedBox(height: 1.h),
          _buildSummaryRow(
            context,
            'Duration',
            '${slowestPhase.duration.toStringAsFixed(0)}ms',
            theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTheme.getMonospaceStyle(
            isLight: theme.brightness == Brightness.light,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ).copyWith(color: valueColor),
        ),
      ],
    );
  }

  List<_TimingPhase> _extractTimingData() {
    final theme = ThemeData();
    return [
      _TimingPhase(
        name: 'DNS Lookup',
        shortName: 'DNS',
        duration: (requestData['dnsLookupTime'] as num?)?.toDouble() ?? 0,
        color: const Color(0xFF3182CE),
        description: 'Time to resolve domain name to IP address',
      ),
      _TimingPhase(
        name: 'TCP Connection',
        shortName: 'TCP',
        duration: (requestData['connectionTime'] as num?)?.toDouble() ?? 0,
        color: const Color(0xFF38A169),
        description: 'Time to establish TCP connection',
      ),
      _TimingPhase(
        name: 'SSL Handshake',
        shortName: 'SSL',
        duration: (requestData['sslHandshakeTime'] as num?)?.toDouble() ?? 0,
        color: const Color(0xFFD69E2E),
        description: 'Time to complete SSL/TLS handshake',
      ),
      _TimingPhase(
        name: 'Request Sent',
        shortName: 'Send',
        duration: (requestData['requestSentTime'] as num?)?.toDouble() ?? 0,
        color: const Color(0xFF805AD5),
        description: 'Time to send request data',
      ),
      _TimingPhase(
        name: 'Waiting',
        shortName: 'Wait',
        duration: (requestData['waitingTime'] as num?)?.toDouble() ?? 0,
        color: const Color(0xFFE53E3E),
        description: 'Time waiting for server response',
      ),
      _TimingPhase(
        name: 'Content Download',
        shortName: 'Download',
        duration: (requestData['downloadTime'] as num?)?.toDouble() ?? 0,
        color: const Color(0xFF00B5D8),
        description: 'Time to download response content',
      ),
    ];
  }
}

class _TimingPhase {
  final String name;
  final String shortName;
  final double duration;
  final Color color;
  final String? description;

  _TimingPhase({
    required this.name,
    required this.shortName,
    required this.duration,
    required this.color,
    this.description,
  });
}
