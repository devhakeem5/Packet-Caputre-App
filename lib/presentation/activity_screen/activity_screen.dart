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
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Saved',
        actions: [
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
              final requests = trafficController.savedRequests;

              if (requests.isEmpty) {
                return _buildEmptyState(context);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Just rebuild
                  setState(() {});
                },
                child: ListView.separated(
                  // Remove controller: _scrollController, or keep if you want to remember position, but auto-scroll is likely unwanted for a saved list.
                  // reverse: true usually meant "newest at bottom" for chat-like interfaces. usage here depends on order.
                  // If savedRequests adds to end, reverse: true puts newest at top.
                  itemCount: requests.length,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  separatorBuilder: (context, index) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    // Reverse index to show newest saved first if list is appended
                    final reversedIndex = requests.length - 1 - index;
                    final request = requests[reversedIndex];
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
      final savedCount = trafficController.savedRequests.length;

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
                'Saved Requests',
                '$savedCount',
                theme.colorScheme.primary,
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

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'bookmark_border',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 80,
            ),
            SizedBox(height: 3.h),
            Text(
              'No saved requests',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Requests you save will appear here permanently',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> request) {
    Get.toNamed(AppRoutes.requestDetails, arguments: request);
  }

  void _confirmClearAll() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Saved Requests?'),
        content: const Text(
          'This will remove all saved requests from the list. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              trafficController.savedRequests.clear();
              trafficController.persistSavedRequests();
              Get.snackbar(
                'Success',
                'All saved requests cleared',
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
