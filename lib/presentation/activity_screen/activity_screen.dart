import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_buttom_bar.dart';
import '../request_list_screen/widgets/request_card_widget.dart';

/// Activity Screen - Live network traffic feed with real-time updates
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TrafficController trafficController = Get.find<TrafficController>();
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Live Activity',
        actions: [
          Obx(
            () => IconButton(
              icon: CustomIconWidget(
                iconName: _autoScroll ? 'pause' : 'play_arrow',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _autoScroll = !_autoScroll;
                });
              },
              tooltip: _autoScroll ? 'Pause auto-scroll' : 'Resume auto-scroll',
            ),
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'delete_sweep',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _confirmClearAll,
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(context),
          Expanded(
            child: Obx(() {
              final requests = trafficController.filteredRequests;

              // Auto-scroll when new request arrives
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              if (requests.isEmpty) {
                return _buildEmptyState(context);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Just rebuild, data is already live
                  setState(() {});
                },
                child: ListView.separated(
                  controller: _scrollController,
                  reverse: true, // Show newest at top
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return RequestCardWidget(
                      request: request,
                      onTap: () => _navigateToDetails(request),
                      onSaveToggle: () => trafficController.toggleSaveRequest(request),
                    );
                  },
                ),
              );
            }),
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

  Widget _buildStatsBar(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final totalRequests = trafficController.filteredRequests.length;
      final allRequests = trafficController.allRequests.length;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Displaying',
                '$totalRequests',
                theme.colorScheme.primary,
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Total Captured',
                '$allRequests',
                theme.colorScheme.secondary,
              ),
            ),
            Container(
              width: 1,
              height: 30,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Auto-scroll',
                _autoScroll ? 'ON' : 'OFF',
                _autoScroll ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final captureController = Get.find<CaptureController>();

    return Obx(() {
      final isRunning = captureController.isRunning.value;

      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: isRunning ? 'hourglass_empty' : 'play_circle_outline',
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 80,
              ),
              SizedBox(height: 3.h),
              Text(
                isRunning ? 'Waiting for traffic...' : 'Start monitoring to capture traffic',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                isRunning
                    ? 'Network requests will appear here in real-time as they are captured'
                    : 'Tap the start button on the dashboard to begin capturing network traffic',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (!isRunning) ...[
                SizedBox(height: 4.h),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    // Use the correct method from CaptureController
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Monitoring'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  void _navigateToDetails(Map<String, dynamic> request) {
    Get.toNamed(AppRoutes.requestDetails, arguments: request);
  }

  void _confirmClearAll() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Requests?'),
        content: const Text(
          'This will remove all captured requests from the list. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              trafficController.allRequests.clear();
              trafficController.applyFiltersAndSort();
              Get.snackbar(
                'Success',
                'All requests cleared',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
