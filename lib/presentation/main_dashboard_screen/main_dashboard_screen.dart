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

  final TrafficController trafficController = Get.put(TrafficController());

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
        Get.toNamed('/settings-screen');
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

  // Purely clearing visual list if needed, but TrafficController holds truth
  void stopMonitoring() {
    // Optional: trafficController.allRequests.clear();
  }

  Future<void> handleRefresh() async {
    // No-op or reload logic if needed
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
                  () =>
                      captureController.isRunning.value ||
                          trafficController.filteredRequests.isNotEmpty
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
                                        monitoredAppsCount:
                                            0, // trafficController.selectedApps.length via Obx?
                                        dataCaptured:
                                            "0 MB", // Should compute from trafficController
                                      ),
                                      SizedBox(height: 2.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Live Network Feed',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          // Loading indicator only if strictly needed
                                        ],
                                      ),
                                      SizedBox(height: 1.h),
                                    ],
                                  ),
                                ),
                              ),
                              trafficController.filteredRequests.isEmpty
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
                                        final request = trafficController.filteredRequests[index];
                                        return NetworkRequestItemWidget(
                                          request: request,
                                          onTap: () => handleRequestTap(request),
                                          onBlockDomain: () => handleBlockDomain(request),
                                          onAddToFavorites: () => handleAddToFavorites(request),
                                          onShare: () => handleShare(request),
                                          onExport: () => handleExport(request),
                                        );
                                      }, childCount: trafficController.filteredRequests.length),
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
