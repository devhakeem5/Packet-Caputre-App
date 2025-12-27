import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/monitoring_toggle_widget.dart';
import './widgets/network_request_item_widget.dart';
import './widgets/vpn_status_card_widget.dart';

class MainDashboardScreen extends StatelessWidget {
  MainDashboardScreen({super.key});

  final CaptureController captureController = Get.put(CaptureController());

  RxBool isRefreshing = false.obs;
  RxInt monitoredAppsCount = 0.obs;
  RxString dataCaptured = "0 MB".obs;
  RxList<Map<String, dynamic>> networkRequests = <Map<String, dynamic>>[].obs;

  void handleTabChange(int index) {
    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        Get.toNamed('/app-selection-screen');
        break;
      case 2:
        Get.toNamed('/request-list-screen');
        break;
      case 3:
        Get.toNamed('/request-details-screen');
        break;
    }
  }

  void toggleMonitoring() {
    if (captureController.isRunning.value) {
      captureController.stopCapture();
    } else {
      captureController.startCapture();
    }
  }

  void startMonitoring() {
    // TODO: Implement actual monitoring
    simulateNetworkTraffic();
  }

  void stopMonitoring() {
    networkRequests.clear();
    monitoredAppsCount.value = 0;
    dataCaptured.value = "0 MB";
  }

  void simulateNetworkTraffic() {
    if (!captureController.isRunning.value) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (captureController.isRunning.value) {
        final newRequest = generateMockRequest();
        networkRequests.insert(0, newRequest);
        if (networkRequests.length > 50) {
          networkRequests.removeLast();
        }
        updateDataCaptured();
        simulateNetworkTraffic();
      }
    });
  }

  Map<String, dynamic> generateMockRequest() {
    final apps = [
      {
        "name": "Chrome",
        "package": "com.android.chrome",
        "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1f5d028f0-1764656770781.png",
        "semanticLabel": "Chrome browser icon with red, yellow, green, and blue colors",
      },
      {
        "name": "WhatsApp",
        "package": "com.whatsapp",
        "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1b3def8dd-1764662218645.png",
        "semanticLabel": "WhatsApp messenger icon with green background and white phone symbol",
      },
      {
        "name": "Instagram",
        "package": "com.instagram.android",
        "icon": "https://images.unsplash.com/photo-1666408738188-212c470d08b0",
        "semanticLabel": "Instagram icon with gradient colors from purple to orange",
      },
      {
        "name": "YouTube",
        "package": "com.google.android.youtube",
        "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1cf52285e-1764675872914.png",
        "semanticLabel": "YouTube icon with red background and white play button",
      },
      {
        "name": "Gmail",
        "package": "com.google.android.gm",
        "icon": "https://images.unsplash.com/photo-1704642325848-8cbee46aab53",
        "semanticLabel": "Gmail icon with red, blue, yellow, and green envelope design",
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

  void updateDataCaptured() {
    final totalKB = networkRequests.fold<int>(0, (sum, request) {
      final sizeStr = (request["dataSize"] as String).replaceAll(" KB", "");
      return sum + int.parse(sizeStr);
    });
    final totalMB = (totalKB / 1024).toStringAsFixed(2);
    dataCaptured.value = "$totalMB MB";
  }

  Future<void> handleRefresh() async {
    isRefreshing.value = true;

    await Future.delayed(const Duration(milliseconds: 800));

    if (captureController.isRunning.value) {
      for (int i = 0; i < 5; i++) {
        networkRequests.insert(0, generateMockRequest());
      }
      if (networkRequests.length > 50) {
        networkRequests.removeRange(50, networkRequests.length);
      }
      updateDataCaptured();
    }
    isRefreshing.value = false;
  }

  void handleRequestTap(Map<String, dynamic> request) {
    Get.toNamed('/request-details-screen', arguments: request);
  }

  void handleBlockDomain(Map<String, dynamic> request) {
    Get.snackbar(
      'Blocked',
      'Domain ${request["hostname"]} blocked',
      duration: Duration(seconds: 2),
    );
  }

  void handleAddToFavorites(Map<String, dynamic> request) {
    Get.snackbar(
      'Added',
      'Added ${request["hostname"]} to favorites',
      duration: Duration(seconds: 2),
    );
  }

  void handleShare(Map<String, dynamic> request) {
    Get.snackbar(
      'Sharing',
      'Sharing request from ${request["appName"]}',
      duration: Duration(seconds: 2),
    );
  }

  void handleExport(Map<String, dynamic> request) {
    Get.snackbar('Exporting', 'Exporting request data', duration: Duration(seconds: 2));
  }

  void openAppSelection() {
    Get.toNamed('/app-selection-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'NetWatch Pro',
          variant: CustomAppBarVariant.withStatus,
          monitoringStatus: captureController.isRunning.value
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
                onTap: handleTabChange,
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
                child: Obx(
                  () => captureController.isRunning.value || networkRequests.isNotEmpty
                      ? RefreshIndicator(
                          onRefresh: handleRefresh,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(4.w),
                                  child: Column(
                                    children: [
                                      MonitoringToggleWidget(
                                        isMonitoring: captureController.isRunning.value,
                                        onToggle: toggleMonitoring,
                                      ),
                                      SizedBox(height: 2.h),
                                      VpnStatusCardWidget(
                                        isActive: captureController.isRunning.value,
                                        monitoredAppsCount: monitoredAppsCount.value,
                                        dataCaptured: dataCaptured.value,
                                      ),
                                      SizedBox(height: 2.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Live Network Feed',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          if (isRefreshing.value)
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
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
                              networkRequests.isEmpty
                                  ? SliverFillRemaining(
                                      child: Center(
                                        child: Text(
                                          'Waiting for network activity...',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate((context, index) {
                                        final request = networkRequests[index];
                                        return NetworkRequestItemWidget(
                                          request: request,
                                          onTap: () => handleRequestTap(request),
                                          onBlockDomain: () => handleBlockDomain(request),
                                          onAddToFavorites: () => handleAddToFavorites(request),
                                          onShare: () => handleShare(request),
                                          onExport: () => handleExport(request),
                                        );
                                      }, childCount: networkRequests.length),
                                    ),
                            ],
                          ),
                        )
                      : EmptyStateWidget(onStartMonitoring: toggleMonitoring),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: buildFloatingActionButton(context),
      ),
    );
  }

  Widget buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      onPressed: () {
        Get.toNamed('/analytics-dashboard-screen');
      },
      backgroundColor: theme.colorScheme.secondary,
      tooltip: 'Analytics',
      child: CustomIconWidget(
        iconName: 'analytics',
        color: theme.colorScheme.onSecondary,
        size: 24,
      ),
    );
  }
}
