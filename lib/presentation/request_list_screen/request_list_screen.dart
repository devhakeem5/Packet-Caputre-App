import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import './widgets/active_filter_bar_widget.dart';
import './widgets/app_filter_widget.dart';
import './widgets/domain_blocklist_widget.dart';
import './widgets/request_card_widget.dart';
import './widgets/search_history_widget.dart';
import './widgets/sort_bottom_sheet_widget.dart';

/// Request List Screen - Comprehensive view of captured network requests
/// with advanced filtering, search, and sorting capabilities
class RequestListScreen extends StatelessWidget {
  RequestListScreen({super.key});

  final TrafficController trafficController = Get.find<TrafficController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Activity',
        variant: CustomAppBarVariant.withBackButton,
        actions: [
          // Sort button
          IconButton(
            icon: CustomIconWidget(iconName: 'sort', size: 24, color: theme.colorScheme.onSurface),
            onPressed: () => _showSortBottomSheet(context),
          ),
          // Filter button
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: TextField(
              onChanged: trafficController.onSearchChanged,
              onSubmitted: trafficController.onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search requests...',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: Obx(
                  () => trafficController.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => trafficController.onSearchChanged(''),
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // Active filters bar
          Obx(
            () => trafficController.activeFilters.isNotEmpty
                ? ActiveFilterBarWidget(
                    activeFilters: trafficController.activeFilters,
                    onRemoveFilter: trafficController.removeFilter,
                    onClearAll: trafficController.clearAllFilters,
                  )
                : const SizedBox.shrink(),
          ),

          // Tab bar for request categories
          TabBar(
            controller: trafficController.requestListTabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Active'),
              Tab(text: 'Blocked'),
              Tab(text: 'Errors'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
          ),

          // Request list
          Expanded(
            child: TabBarView(
              controller: trafficController.requestListTabController,
              children: [
                // All requests (Saved)
                Obx(
                  () => trafficController.savedRequests.isEmpty
                      ? _buildEmptyState(theme, 'No saved requests')
                      : ListView.builder(
                          itemCount: trafficController.savedRequests.length,
                          itemBuilder: (context, index) {
                            final request = trafficController.savedRequests[index];
                            return RequestCardWidget(
                              request: request,
                              onTap: () => _navigateToDetails(request),
                              onSaveToggle: () => trafficController.toggleSaveRequest(request),
                            );
                          },
                        ),
                ),

                // Active requests (Saved)
                Obx(
                  () => trafficController.savedRequests.where((r) => r['statusCode'] == 200).isEmpty
                      ? _buildEmptyState(theme, 'No active saved requests')
                      : ListView.builder(
                          itemCount: trafficController.savedRequests
                              .where((r) => r['statusCode'] == 200)
                              .length,
                          itemBuilder: (context, index) {
                            final request = trafficController.savedRequests
                                .where((r) => r['statusCode'] == 200)
                                .toList()[index];
                            return RequestCardWidget(
                              request: request,
                              onTap: () => _navigateToDetails(request),
                              onSaveToggle: () => trafficController.toggleSaveRequest(request),
                            );
                          },
                        ),
                ),

                // Blocked requests (Saved)
                Obx(
                  () =>
                      trafficController.savedRequests
                          .where((r) => trafficController.blockedDomains.contains(r['domain']))
                          .isEmpty
                      ? _buildEmptyState(theme, 'No blocked saved requests')
                      : ListView.builder(
                          itemCount: trafficController.savedRequests
                              .where((r) => trafficController.blockedDomains.contains(r['domain']))
                              .length,
                          itemBuilder: (context, index) {
                            final request = trafficController.savedRequests
                                .where(
                                  (r) => trafficController.blockedDomains.contains(r['domain']),
                                )
                                .toList()[index];
                            return RequestCardWidget(
                              request: request,
                              onTap: () => _navigateToDetails(request),
                              onSaveToggle: () => trafficController.toggleSaveRequest(request),
                            );
                          },
                        ),
                ),

                // Error requests (Saved)
                Obx(
                  () => trafficController.savedRequests.where((r) => r['statusCode'] >= 400).isEmpty
                      ? _buildEmptyState(theme, 'No error saved requests')
                      : ListView.builder(
                          itemCount: trafficController.savedRequests
                              .where((r) => r['statusCode'] >= 400)
                              .length,
                          itemBuilder: (context, index) {
                            final request = trafficController.savedRequests
                                .where((r) => r['statusCode'] >= 400)
                                .toList()[index];
                            return RequestCardWidget(
                              request: request,
                              onTap: () => _navigateToDetails(request),
                              onSaveToggle: () => trafficController.toggleSaveRequest(request),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'web',
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your filters or search terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Show sort bottom sheet
  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SortBottomSheetWidget(
        selectedOption: trafficController.selectedSortOption.value,
        onOptionSelected: (option) {
          trafficController.selectedSortOption.value = option;
          trafficController.applyFiltersAndSort();
          Navigator.pop(context);
        },
      ),
    );
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              // Visibility Filters (Simplified)
              Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visibility Settings', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 2.h),

                    // Hide System Apps
                    Obx(
                      () => SwitchListTile(
                        title: const Text('Hide System Apps'),
                        subtitle: const Text('Show only user-installed applications'),
                        value: trafficController.hideSystemApps.value,
                        onChanged: (val) => trafficController.toggleHideSystemApps(),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    SizedBox(height: 1.h),
                    Text(
                      'Encrypted Traffic',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    // Show All vs Unencrypted Only
                    Obx(
                      () => Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text('Show All Requests'),
                            value: false, // hideEncryptedTraffic = false
                            groupValue: trafficController.hideEncryptedTraffic.value,
                            onChanged: (val) {
                              if (val != null && val == false) {
                                // User wants to show all (encrypted + unencrypted)
                                if (trafficController.hideEncryptedTraffic.value == true) {
                                  trafficController.toggleHideEncryptedTraffic();
                                }
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<bool>(
                            title: const Text('Show Unencrypted Requests Only'),
                            value: true, // hideEncryptedTraffic = true
                            groupValue: trafficController.hideEncryptedTraffic.value,
                            onChanged: (val) {
                              if (val != null && val == true) {
                                // User wants to hide encrypted traffic
                                if (trafficController.hideEncryptedTraffic.value == false) {
                                  trafficController.toggleHideEncryptedTraffic();
                                }
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // App filters
              AppFilterWidget(
                selectedApps: trafficController.selectedApps,
                allRequests: trafficController.allRequests,
                onToggleApp: trafficController.toggleAppFilter,
              ),

              // Domain blocklist
              DomainBlocklistWidget(
                blockedDomains: trafficController.blockedDomains,
                allRequests: trafficController.allRequests,
                onAddDomain: trafficController.addBlockedDomain,
                onRemoveDomain: trafficController.removeBlockedDomain,
              ),

              // Search history
              SearchHistoryWidget(
                searchHistory: trafficController.searchHistory,
                onSelectHistory: trafficController.useSearchHistory,
                onClearHistory: trafficController.clearSearchHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to request details
  void _navigateToDetails(Map<String, dynamic> request) {
    Get.toNamed('/request-details-screen', arguments: request);
  }
}
