import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_icon_widget.dart';
import 'widgets/time_period_selector_widget.dart';
import 'widgets/metrics_card_widget.dart';
import 'widgets/app_usage_chart_widget.dart';
import 'widgets/protocol_distribution_chart_widget.dart';
import 'widgets/time_trends_chart_widget.dart';
import 'widgets/network_statistics_widget.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = '24h';
  final List<String> _periods = ['24h', '7d', '30d', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsData = _generateAnalyticsData();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimePeriodSelectorWidget(
                selectedPeriod: _selectedPeriod,
                periods: _periods,
                onPeriodChanged: (period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
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
              ProtocolDistributionChartWidget(
                protocolData: analyticsData['protocols'],
              ),
              SizedBox(height: 3.h),
              _buildSectionTitle(context, 'Time Trends'),
              SizedBox(height: 1.h),
              TimeTrendsChartWidget(
                trendsData: analyticsData['trends'],
                period: _selectedPeriod,
              ),
              SizedBox(height: 3.h),
              _buildSectionTitle(context, 'Network Statistics'),
              SizedBox(height: 1.h),
              NetworkStatisticsWidget(
                statisticsData: analyticsData['statistics'],
              ),
              SizedBox(height: 2.h),
            ],
          ),
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

  Map<String, dynamic> _generateAnalyticsData() {
    return {
      'metrics': [
        {
          'title': 'Total Requests',
          'value': '12,458',
          'change': '+12.5%',
          'icon': 'swap_horiz',
        },
        {
          'title': 'Data Transferred',
          'value': '2.4 GB',
          'change': '+8.3%',
          'icon': 'data_usage',
        },
        {'title': 'Active Apps', 'value': '24', 'change': '+3', 'icon': 'apps'},
        {
          'title': 'Blocked Requests',
          'value': '156',
          'change': '-5.2%',
          'icon': 'block',
        },
      ],
      'appUsage': [
        {'app': 'Chrome', 'requests': 3245, 'data': '856 MB'},
        {'app': 'Instagram', 'requests': 2156, 'data': '542 MB'},
        {'app': 'WhatsApp', 'requests': 1876, 'data': '324 MB'},
        {'app': 'YouTube', 'requests': 1654, 'data': '412 MB'},
        {'app': 'Gmail', 'requests': 1234, 'data': '156 MB'},
        {'app': 'Twitter', 'requests': 987, 'data': '98 MB'},
      ],
      'protocols': [
        {'name': 'HTTPS', 'value': 8456, 'percentage': 67.8},
        {'name': 'HTTP', 'value': 2876, 'percentage': 23.1},
        {'name': 'WebSocket', 'value': 876, 'percentage': 7.0},
        {'name': 'Other', 'value': 250, 'percentage': 2.1},
      ],
      'trends': _generateTrendsData(),
      'statistics': {
        'peakHours': [
          {'hour': '09:00', 'requests': 856},
          {'hour': '12:00', 'requests': 1234},
          {'hour': '15:00', 'requests': 987},
          {'hour': '18:00', 'requests': 1456},
          {'hour': '21:00', 'requests': 1123},
        ],
        'avgResponseTime': '245ms',
        'successRate': '98.5%',
        'errorRate': '1.5%',
      },
    };
  }

  List<Map<String, dynamic>> _generateTrendsData() {
    if (_selectedPeriod == '24h') {
      return List.generate(24, (index) {
        return {
          'time': '${index.toString().padLeft(2, '0')}:00',
          'requests': 300 + (index * 50) + (index % 3 * 100),
        };
      });
    } else if (_selectedPeriod == '7d') {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return List.generate(7, (index) {
        return {
          'time': days[index],
          'requests': 8000 + (index * 500) + (index % 2 * 1000),
        };
      });
    } else {
      return List.generate(30, (index) {
        return {
          'time': 'Day ${index + 1}',
          'requests': 7000 + (index * 200) + (index % 5 * 500),
        };
      });
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh data
    });
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