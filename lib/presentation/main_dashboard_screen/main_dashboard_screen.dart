import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/monitoring_toggle_widget.dart';
import './widgets/network_request_item_widget.dart';
import './widgets/vpn_status_card_widget.dart';
// /empty_state_widget
//
//
//
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMonitoring = false;
  bool _isRefreshing = false;
  int _monitoredAppsCount = 0;
  String _dataCaptured = "0 MB";
  final List<Map<String, dynamic>> _networkRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _handleTabChange(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        Navigator.pushNamed(context, '/app-selection-screen');
        break;
      case 2:
        Navigator.pushNamed(context, '/request-list-screen');
        break;
      case 3:
        Navigator.pushNamed(context, '/request-details-screen');
        break;
    }
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
      if (_isMonitoring) {
        _startMonitoring();
      } else {
        _stopMonitoring();
      }
    });
  }

  void _startMonitoring() {
    setState(() {
      _monitoredAppsCount = 12;
      _dataCaptured = "0 MB";
    });
    _simulateNetworkTraffic();
  }

  void _stopMonitoring() {
    setState(() {
      _networkRequests.clear();
      _monitoredAppsCount = 0;
      _dataCaptured = "0 MB";
    });
  }

  void _simulateNetworkTraffic() {
    if (!_isMonitoring) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (_isMonitoring && mounted) {
        setState(() {
          final newRequest = _generateMockRequest();
          _networkRequests.insert(0, newRequest);
          if (_networkRequests.length > 50) {
            _networkRequests.removeLast();
          }
          _updateDataCaptured();
        });
        _simulateNetworkTraffic();
      }
    });
  }

  Map<String, dynamic> _generateMockRequest() {
    final apps = [
      {
        "name": "Chrome",
        "package": "com.android.chrome",
        "icon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1f5d028f0-1764656770781.png",
        "semanticLabel":
            "Chrome browser icon with red, yellow, green, and blue colors",
      },
      {
        "name": "WhatsApp",
        "package": "com.whatsapp",
        "icon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1b3def8dd-1764662218645.png",
        "semanticLabel":
            "WhatsApp messenger icon with green background and white phone symbol",
      },
      {
        "name": "Instagram",
        "package": "com.instagram.android",
        "icon": "https://images.unsplash.com/photo-1666408738188-212c470d08b0",
        "semanticLabel":
            "Instagram icon with gradient colors from purple to orange",
      },
      {
        "name": "YouTube",
        "package": "com.google.android.youtube",
        "icon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1cf52285e-1764675872914.png",
        "semanticLabel":
            "YouTube icon with red background and white play button",
      },
      {
        "name": "Gmail",
        "package": "com.google.android.gm",
        "icon": "https://images.unsplash.com/photo-1704642325848-8cbee46aab53",
        "semanticLabel":
            "Gmail icon with red, blue, yellow, and green envelope design",
      },
    ];

    final domains = [
      "api.example.com",
      "cdn.cloudflare.com",
      "graph.facebook.com",
      "api.twitter.com",
      "storage.googleapis.com",
      "api.instagram.com",
      "www.youtube.com",
      "mail.google.com",
    ];

    final methods = ["GET", "POST", "PUT", "DELETE", "PATCH"];
    final protocols = ["HTTPS", "HTTP", "WSS"];

    final app = (apps..shuffle()).first;
    final domain = (domains..shuffle()).first;
    final method = (methods..shuffle()).first;
    final protocol = (protocols..shuffle()).first;

    return {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "appName": app["name"],
      "packageName": app["package"],
      "appIcon": app["icon"],
      "appIconSemanticLabel": app["semanticLabel"],
      "hostname": domain,
      "method": method,
      "protocol": protocol,
      "timestamp": DateTime.now(),
      "dataSize": "${(50 + (DateTime.now().millisecond % 950))} KB",
    };
  }

  void _updateDataCaptured() {
    final totalKB = _networkRequests.fold<int>(0, (sum, request) {
      final sizeStr = (request["dataSize"] as String).replaceAll(" KB", "");
      return sum + int.parse(sizeStr);
    });
    final totalMB = (totalKB / 1024).toStringAsFixed(2);
    _dataCaptured = "\$${totalMB} MB";
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (_isMonitoring && mounted) {
      setState(() {
        for (int i = 0; i < 5; i++) {
          _networkRequests.insert(0, _generateMockRequest());
        }
        if (_networkRequests.length > 50) {
          _networkRequests.removeRange(50, _networkRequests.length);
        }
        _updateDataCaptured();
        _isRefreshing = false;
      });
    } else {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _handleRequestTap(Map<String, dynamic> request) {
    Navigator.pushNamed(context, '/request-details-screen', arguments: request);
  }

  void _handleBlockDomain(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Domain ${request["hostname"]} blocked'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAddToFavorites(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${request["hostname"]} to favorites'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing request from ${request["appName"]}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleExport(Map<String, dynamic> request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting request data'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAppSelection() {
    Navigator.pushNamed(context, '/app-selection-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'NetWatch Pro',
        variant: CustomAppBarVariant.withStatus,
        monitoringStatus: _isMonitoring
            ? MonitoringStatus.active
            : MonitoringStatus.inactive,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Apps'),
                Tab(text: 'History'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              child: _isMonitoring || _networkRequests.isNotEmpty
                  ? RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                children: [
                                  MonitoringToggleWidget(
                                    isMonitoring: _isMonitoring,
                                    onToggle: _toggleMonitoring,
                                  ),
                                  SizedBox(height: 2.h),
                                  VpnStatusCardWidget(
                                    isActive: _isMonitoring,
                                    monitoredAppsCount: _monitoredAppsCount,
                                    dataCaptured: _dataCaptured,
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Live Network Feed',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      if (_isRefreshing)
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  theme.colorScheme.secondary,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 1.h),
                                ],
                              ),
                            ),
                          ),
                          _networkRequests.isEmpty
                              ? SliverFillRemaining(
                                  child: Center(
                                    child: Text(
                                      'Waiting for network activity...',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final request = _networkRequests[index];
                                    return NetworkRequestItemWidget(
                                      request: request,
                                      onTap: () => _handleRequestTap(request),
                                      onBlockDomain: () =>
                                          _handleBlockDomain(request),
                                      onAddToFavorites: () =>
                                          _handleAddToFavorites(request),
                                      onShare: () => _handleShare(request),
                                      onExport: () => _handleExport(request),
                                    );
                                  }, childCount: _networkRequests.length),
                                ),
                        ],
                      ),
                    )
                  : EmptyStateWidget(onStartMonitoring: _toggleMonitoring),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/analytics-dashboard-screen');
      },
      backgroundColor: theme.colorScheme.secondary,
      child: CustomIconWidget(
        iconName: 'analytics',
        color: theme.colorScheme.onSecondary,
        size: 24,
      ),
      tooltip: 'Analytics',
    );
  }
}
