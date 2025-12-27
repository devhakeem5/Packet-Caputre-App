import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';

import '../../core/widgets/custom_buttom_bar.dart';
import './widgets/headers_tab_widget.dart';
import './widgets/overview_tab_widget.dart';
import './widgets/response_tab_widget.dart';
import './widgets/timing_tab_widget.dart';

/// Request Details Screen - Displays comprehensive information about individual network requests
class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CustomBottomBarItem _selectedBottomBarItem = CustomBottomBarItem.requests;

  // Mock request data
  final Map<String, dynamic> _requestData = {
    'requestId': 'req_1735272568067',
    'url': 'https://api.example.com/v1/users/profile',
    'method': 'GET',
    'statusCode': 200,
    'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
    'packageName': 'com.example.netwatch',
    'appName': 'NetWatch Pro',
    'appVersion': '1.0.0',
    'destinationIp': '192.168.1.100',
    'port': 443,
    'protocol': 'HTTPS',
    'protocolVersion': 'HTTP/2',
    'isEncrypted': true,
    'connectionType': 'WiFi',
    'bytesSent': 1024,
    'bytesReceived': 4096,
    'contentType': 'application/json',
    'dnsLookupTime': 12.5,
    'connectionTime': 45.3,
    'sslHandshakeTime': 78.9,
    'requestSentTime': 5.2,
    'waitingTime': 123.4,
    'downloadTime': 34.7,
    'requestHeaders': {
      'User-Agent': 'NetWatch/1.0.0 (Android 13)',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
      'Content-Type': 'application/json',
      'X-Request-ID': 'req_1735272568067',
    },
    'responseHeaders': {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Length': '4096',
      'Server': 'nginx/1.21.0',
      'Date': 'Fri, 27 Dec 2024 03:54:28 GMT',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'X-Response-Time': '123ms',
      'X-RateLimit-Limit': '1000',
      'X-RateLimit-Remaining': '999',
    },
    'responseBody': '''
{
  "status": "success",
  "data": {
    "user": {
      "id": "usr_12345",
      "name": "John Doe",
      "email": "john.doe@example.com",
      "profile": {
        "avatar": "https://example.com/avatars/john.jpg",
        "bio": "Network monitoring enthusiast",
        "location": "San Francisco, CA"
      },
      "settings": {
        "notifications": true,
        "theme": "dark",
        "language": "en"
      }
    }
  },
  "timestamp": "2024-12-27T03:54:28Z"
}
''',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            icon: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _handleShare,
            tooltip: 'Share request',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showMoreOptions,
            tooltip: 'More options',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRequestHeader(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                OverviewTabWidget(requestData: _requestData),
                HeadersTabWidget(requestData: _requestData),
                ResponseTabWidget(requestData: _requestData),
                TimingTabWidget(requestData: _requestData),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedItem: _selectedBottomBarItem,
        onItemSelected: (item) {
          setState(() => _selectedBottomBarItem = item);
        },
      ),
    );
  }

  Widget _buildRequestHeader(BuildContext context) {
    final theme = Theme.of(context);
    final url = _requestData['url'] as String;
    final method = _requestData['method'] as String;
    final statusCode = _requestData['statusCode'] as int;
    final timestamp = _requestData['timestamp'] as DateTime;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMethodBadge(context, method),
              SizedBox(width: 2.w),
              _buildStatusBadge(context, statusCode),
              const Spacer(),
              Text(
                _formatTimestamp(timestamp),
                style: AppTheme.getCaptionMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          GestureDetector(
            onLongPress: () => _copyToClipboard(context, url),
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

  Widget _buildMethodBadge(BuildContext context, String method) {
    final theme = Theme.of(context);
    final color = _getMethodColor(method);

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

  Widget _buildStatusBadge(BuildContext context, int statusCode) {
    final theme = Theme.of(context);
    final color = _getStatusColor(statusCode);

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

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Headers'),
          Tab(text: 'Response'),
          Tab(text: 'Timing'),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
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

  Color _getStatusColor(int statusCode) {
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

  String _formatTimestamp(DateTime timestamp) {
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

  void _handleShare() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
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
                _showToast('Exported as cURL command');
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
                _showToast('Exported as JSON');
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
                _showToast('Exported as HAR file');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
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
                _copyToClipboard(context, _requestData['url'] as String);
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
                _showToast('Request replayed');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: theme.colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Delete Request',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showToast('Request deleted');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
