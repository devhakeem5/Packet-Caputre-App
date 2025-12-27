import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_buttom_bar.dart';
import './widgets/headers_tab_widget.dart';
import './widgets/overview_tab_widget.dart';
import './widgets/response_tab_widget.dart';
import './widgets/timing_tab_widget.dart';

/// Request Details Screen - Displays comprehensive information about individual network requests
class RequestDetailsScreen extends StatelessWidget {
  RequestDetailsScreen({super.key});

  final TrafficController trafficController = Get.put(TrafficController());

  // Get arguments passed from navigation
  final Map<String, dynamic> requestData = Get.arguments ?? {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Request Details',
        variant: CustomAppBarVariant.withBackButton,
        actions: [
          IconButton(
            icon: CustomIconWidget(iconName: 'share', color: theme.colorScheme.onSurface, size: 24),
            onPressed: handleShare,
            tooltip: 'Share request',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: showMoreOptions,
            tooltip: 'More options',
          ),
        ],
      ),
      body: Column(
        children: [
          buildRequestHeader(context),
          buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: trafficController.tabController,
              children: [
                OverviewTabWidget(requestData: requestData),
                HeadersTabWidget(requestData: requestData),
                ResponseTabWidget(requestData: requestData),
                TimingTabWidget(requestData: requestData),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => CustomBottomBar(
          selectedItem: trafficController.selectedBottomBarItem.value,
          onItemSelected: (item) => trafficController.selectedBottomBarItem.value = item,
        ),
      ),
    );
  }

  Widget buildRequestHeader(BuildContext context) {
    final theme = Theme.of(context);
    final url = requestData['url'] as String;
    final method = requestData['method'] as String;
    final statusCode = requestData['statusCode'] as int;
    final timestamp = requestData['timestamp'] as DateTime;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              buildMethodBadge(context, method),
              SizedBox(width: 2.w),
              buildStatusBadge(context, statusCode),
              const Spacer(),
              Text(
                formatTimestamp(timestamp),
                style: AppTheme.getCaptionMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          GestureDetector(
            onLongPress: () => copyToClipboard(context, url),
            child: Text(
              url,
              style: AppTheme.getMonospaceStyle(
                isLight: theme.brightness == Brightness.light,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ).copyWith(color: theme.colorScheme.secondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMethodBadge(BuildContext context, String method) {
    final theme = Theme.of(context);
    final color = getMethodColor(method);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        method,
        style: AppTheme.getMonospaceStyle(
          isLight: theme.brightness == Brightness.light,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ).copyWith(color: color),
      ),
    );
  }

  Widget buildStatusBadge(BuildContext context, int statusCode) {
    final theme = Theme.of(context);
    final color = getStatusColor(statusCode);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        statusCode.toString(),
        style: AppTheme.getMonospaceStyle(
          isLight: theme.brightness == Brightness.light,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ).copyWith(color: color),
      ),
    );
  }

  Widget buildTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: TabBar(
        controller: trafficController.tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Headers'),
          Tab(text: 'Response'),
          Tab(text: 'Timing'),
        ],
      ),
    );
  }

  Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF3182CE);
      case 'POST':
        return const Color(0xFF38A169);
      case 'PUT':
        return const Color(0xFFD69E2E);
      case 'DELETE':
        return const Color(0xFFE53E3E);
      case 'PATCH':
        return const Color(0xFF805AD5);
      default:
        return const Color(0xFF718096);
    }
  }

  Color getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return const Color(0xFF38A169);
    } else if (statusCode >= 300 && statusCode < 400) {
      return const Color(0xFF3182CE);
    } else if (statusCode >= 400 && statusCode < 500) {
      return const Color(0xFFD69E2E);
    } else if (statusCode >= 500) {
      return const Color(0xFFE53E3E);
    }
    return const Color(0xFF718096);
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  void handleShare() {
    final theme = Theme.of(Get.context!);
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'code',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Export as cURL'),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Success', 'Exported as cURL command', duration: Duration(seconds: 2));
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'description',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Export as JSON'),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Success', 'Exported as JSON', duration: Duration(seconds: 2));
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'archive',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Export as HAR'),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Success', 'Exported as HAR file', duration: Duration(seconds: 2));
              },
            ),
          ],
        ),
      ),
    );
  }

  void showMoreOptions() {
    final theme = Theme.of(Get.context!);
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(context);
                copyToClipboard(Get.context!, requestData['url'] as String);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'replay',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Replay Request'),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Success', 'Request replayed', duration: Duration(seconds: 2));
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: theme.colorScheme.error,
                size: 24,
              ),
              title: Text('Delete Request', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Success', 'Request deleted', duration: Duration(seconds: 2));
              },
            ),
          ],
        ),
      ),
    );
  }

  void copyToClipboard(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard'), duration: const Duration(seconds: 2)),
    );
  }
}
