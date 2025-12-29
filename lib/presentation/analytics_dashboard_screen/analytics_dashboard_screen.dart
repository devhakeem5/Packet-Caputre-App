import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import 'widgets/app_usage_chart_widget.dart';
import 'widgets/metrics_card_widget.dart';
import 'widgets/network_statistics_widget.dart';
import 'widgets/protocol_distribution_chart_widget.dart';
import 'widgets/time_trends_chart_widget.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final String _selectedPeriod = 'All Time'; // Simplified for live session
  final TrafficController trafficController = Get.find<TrafficController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using Obx to react to traffic updates
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Analytics Dashboard',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _handleExport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Obx(() {
            final analyticsData = _generateRealAnalyticsData();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simplified Period Selector
                Row(
                  children: [Text("Current Session Activity", style: theme.textTheme.titleMedium)],
                ),
                SizedBox(height: 2.h),
                _buildMetricsGrid(context, analyticsData),
                SizedBox(height: 3.h),
                _buildSectionTitle(context, 'App Usage'),
                SizedBox(height: 1.h),
                AppUsageChartWidget(appUsageData: analyticsData['appUsage']),
                SizedBox(height: 3.h),
                _buildSectionTitle(context, 'Protocol Distribution'),
                SizedBox(height: 1.h),
                ProtocolDistributionChartWidget(protocolData: analyticsData['protocols']),
                SizedBox(height: 3.h),
                _buildSectionTitle(context, 'Time Trends (Requests/min)'),
                SizedBox(height: 1.h),
                TimeTrendsChartWidget(trendsData: analyticsData['trends'], period: _selectedPeriod),
                SizedBox(height: 3.h),
                _buildSectionTitle(context, 'Network Statistics'),
                SizedBox(height: 1.h),
                NetworkStatisticsWidget(statisticsData: analyticsData['statistics']),
                SizedBox(height: 2.h),
              ],
            );
          }),
        ),
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

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> data) {
    final metrics = data['metrics'] as List<Map<String, dynamic>>;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        return MetricsCardWidget(
          title: metrics[index]['title'],
          value: metrics[index]['value'],
          change: metrics[index]['change'],
          icon: metrics[index]['icon'],
        );
      },
    );
  }

  Map<String, dynamic> _generateRealAnalyticsData() {
    final requests = trafficController.allRequests;
    final totalRequests = requests.length;

    // Calculate Data Transferred
    int totalBytes = 0;
    int blockedCount = 0;
    Map<String, int> appRequestCounts = {};
    Map<String, int> appDataCounts = {};
    Map<String, int> protocolCounts = {};

    for (var r in requests) {
      final reqSize = r['bytesSent'] as int? ?? 0;
      final resSize = r['bytesReceived'] as int? ?? 0;
      totalBytes += reqSize + resSize;

      if ((r['statusCode'] as int? ?? 0) == 0 || (r['statusCode'] as int? ?? 0) >= 400) {
        // Approximate "blocked" or "failed" if status is 0 or error
        // Actually native might not send status 0 for blocked, but let's assume errors.
        if (r['statusCode'] == 0) blockedCount++;
      }

      final appName = r['appName'] as String? ?? "Unknown";
      appRequestCounts[appName] = (appRequestCounts[appName] ?? 0) + 1;
      appDataCounts[appName] = (appDataCounts[appName] ?? 0) + (reqSize + resSize);

      final protocol = r['protocol'] as String? ?? "Other";
      protocolCounts[protocol] = (protocolCounts[protocol] ?? 0) + 1;
    }

    // Format Data Size
    String dataSizeStr;
    if (totalBytes > 1024 * 1024 * 1024) {
      dataSizeStr = "${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
    } else if (totalBytes > 1024 * 1024) {
      dataSizeStr = "${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    } else {
      dataSizeStr = "${(totalBytes / 1024).toStringAsFixed(2)} KB";
    }

    // App Usage Data
    List<Map<String, dynamic>> appUsage = [];
    appRequestCounts.forEach((app, count) {
      final bytes = appDataCounts[app]!;
      String sizeStr = bytes > 1024 * 1024
          ? "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB"
          : "${(bytes / 1024).toStringAsFixed(1)} KB";
      appUsage.add({'app': app, 'requests': count, 'data': sizeStr, 'rawBytes': bytes});
    });
    appUsage.sort((a, b) => (b['rawBytes'] as int).compareTo(a['rawBytes'] as int));
    if (appUsage.length > 5) appUsage = appUsage.sublist(0, 5);

    // Protocol Data
    List<Map<String, dynamic>> protocolData = [];
    protocolCounts.forEach((proto, count) {
      protocolData.add({
        'name': proto,
        'value': count,
        'percentage': totalRequests > 0 ? (count / totalRequests * 100) : 0.0,
      });
    });

    return {
      'metrics': [
        {
          'title': 'Total Requests',
          'value': totalRequests.toString(),
          'change': '', // Live
          'icon': 'swap_horiz',
        },
        {'title': 'Data Transferred', 'value': dataSizeStr, 'change': '', 'icon': 'data_usage'},
        {
          'title': 'Active Apps',
          'value': appRequestCounts.length.toString(),
          'change': '',
          'icon': 'apps',
        },
        {
          'title': 'Failed/Blocked', // Renamed for clarity
          'value': blockedCount.toString(),
          'change': '',
          'icon': 'block',
        },
      ],
      'appUsage': appUsage,
      'protocols': protocolData,
      'trends': _generateTrendsData(requests),
      'statistics': {
        'peakHours': [], // Complex to calc live
        'avgResponseTime': 'N/A',
        'successRate': totalRequests > 0
            ? "${((totalRequests - blockedCount) / totalRequests * 100).toStringAsFixed(1)}%"
            : "100%",
        'errorRate': totalRequests > 0
            ? "${(blockedCount / totalRequests * 100).toStringAsFixed(1)}%"
            : "0%",
      },
    };
  }

  List<Map<String, dynamic>> _generateTrendsData(List<Map<String, dynamic>> requests) {
    // Bucket by minute (last 30 mins)
    Map<int, int> buckets = {};
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      buckets[i] = 0;
    }

    for (var r in requests) {
      final ts = r['timestamp'] as DateTime?;
      if (ts != null) {
        final diff = now.difference(ts).inMinutes;
        if (diff >= 0 && diff < 30) {
          // Determine bucket index (0 = now, 29 = 30 mins ago) - Chart usually shows Left->Right (Old->New)
          // So if diff is 0 (now), it should be last.
          // Let's just track raw counts per minute ago
          buckets[diff] = (buckets[diff] ?? 0) + 1;
        }
      }
    }

    // Convert to list for chart (Oldest -> Newest)
    return List.generate(30, (index) {
      // index 0 -> 29 mins ago
      // index 29 -> 0 mins ago
      final minAgo = 29 - index;
      return {'time': '${minAgo}m', 'requests': buckets[minAgo] ?? 0};
    });
  }

  Future<void> _handleRefresh() async {
    // Data is live, but trigger UI rebuild just in case
    setState(() {});
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting analytics report...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
