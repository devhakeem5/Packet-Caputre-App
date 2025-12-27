import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_buttom_bar.dart';
import './widgets/app_list_item_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/section_header_widget.dart';

/// App Selection Screen for configuring which applications to monitor
/// Provides intuitive selection interface with search, filtering, and bulk operations
class AppSelectionScreen extends StatelessWidget {
  AppSelectionScreen({super.key});

  final CaptureController captureController = Get.put(CaptureController());

  // Search and filter state
  RxString searchQuery = ''.obs;
  RxBool isSearchFocused = false.obs;
  final TextEditingController searchController = TextEditingController();

  // Selection state
  RxSet<String> selectedApps = <String>{}.obs;
  RxBool showSystemApps = true.obs;
  RxBool showUserApps = true.obs;

  // Refresh state
  RxBool isRefreshing = false.obs;

  // Mock data for installed applications
  final List<Map<String, dynamic>> _installedApps = [
    {
      "id": "com.android.chrome",
      "name": "Chrome",
      "packageName": "com.android.chrome",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1f5d028f0-1764656770781.png",
      "semanticLabel": "Chrome browser icon with circular red, yellow, green, and blue design",
      "isSystemApp": true,
      "lastActivity": DateTime.now().subtract(const Duration(minutes: 5)),
      "dataUsage": "45.2 MB",
      "requestCount": 127,
    },
    {
      "id": "com.google.android.gms",
      "name": "Google Play Services",
      "packageName": "com.google.android.gms",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_109f6385e-1764662428585.png",
      "semanticLabel": "Google Play Services icon with colorful triangle design",
      "isSystemApp": true,
      "lastActivity": DateTime.now().subtract(const Duration(minutes: 2)),
      "dataUsage": "128.5 MB",
      "requestCount": 342,
    },
    {
      "id": "com.android.vending",
      "name": "Google Play Store",
      "packageName": "com.android.vending",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_109f6385e-1764662428585.png",
      "semanticLabel": "Google Play Store icon with colorful triangle play button",
      "isSystemApp": true,
      "lastActivity": DateTime.now().subtract(const Duration(hours: 1)),
      "dataUsage": "23.8 MB",
      "requestCount": 56,
    },
    {
      "id": "com.whatsapp",
      "name": "WhatsApp",
      "packageName": "com.whatsapp",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1b3def8dd-1764662218645.png",
      "semanticLabel": "WhatsApp icon with green background and white phone symbol",
      "isSystemApp": false,
      "lastActivity": DateTime.now().subtract(const Duration(minutes: 15)),
      "dataUsage": "67.3 MB",
      "requestCount": 189,
    },
    {
      "id": "com.instagram.android",
      "name": "Instagram",
      "packageName": "com.instagram.android",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1578531c9-1765127398454.png",
      "semanticLabel": "Instagram icon with gradient background and camera symbol",
      "isSystemApp": false,
      "lastActivity": DateTime.now().subtract(const Duration(minutes: 30)),
      "dataUsage": "156.7 MB",
      "requestCount": 423,
    },
    {
      "id": "com.spotify.music",
      "name": "Spotify",
      "packageName": "com.spotify.music",
      "icon": "https://images.unsplash.com/photo-1658489958427-325ded050829",
      "semanticLabel": "Spotify icon with green background and white sound waves",
      "isSystemApp": false,
      "lastActivity": DateTime.now().subtract(const Duration(hours: 2)),
      "dataUsage": "89.4 MB",
      "requestCount": 234,
    },
    {
      "id": "com.twitter.android",
      "name": "Twitter",
      "packageName": "com.twitter.android",
      "icon": "https://images.unsplash.com/photo-1667235326880-324e1a51d40b",
      "semanticLabel": "Twitter icon with blue background and white bird symbol",
      "isSystemApp": false,
      "lastActivity": DateTime.now().subtract(const Duration(minutes: 45)),
      "dataUsage": "34.2 MB",
      "requestCount": 98,
    },
    {
      "id": "com.facebook.katana",
      "name": "Facebook",
      "packageName": "com.facebook.katana",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_10c75a2a9-1766489371419.png",
      "semanticLabel": "Facebook icon with blue background and white f letter",
      "isSystemApp": false,
      "lastActivity": DateTime.now().subtract(const Duration(hours: 3)),
      "dataUsage": "112.8 MB",
      "requestCount": 267,
    },
    {
      "id": "com.google.android.youtube",
      "name": "YouTube",
      "packageName": "com.google.android.youtube",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1cf52285e-1764675872914.png",
      "semanticLabel": "YouTube icon with red background and white play button",
      "isSystemApp": false,
      "lastActivity": DateTime.now().subtract(const Duration(minutes: 20)),
      "dataUsage": "234.5 MB",
      "requestCount": 512,
    },
    {
      "id": "com.android.settings",
      "name": "Settings",
      "packageName": "com.android.settings",
      "icon": "https://img.rocket.new/generatedImages/rocket_gen_img_1422638a1-1765366081051.png",
      "semanticLabel": "Settings icon with gray gear symbol on white background",
      "isSystemApp": true,
      "lastActivity": DateTime.now().subtract(const Duration(hours: 5)),
      "dataUsage": "2.1 MB",
      "requestCount": 12,
    },
  ];

  // Filter apps based on search query
  List<Map<String, dynamic>> get filteredApps {
    if (searchQuery.value.isEmpty) {
      return _installedApps;
    }

    return _installedApps.where((app) {
      final name = (app["name"] as String).toLowerCase();
      final packageName = (app["packageName"] as String).toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query) || packageName.contains(query);
    }).toList();
  }

  // Get system apps
  List<Map<String, dynamic>> get systemApps {
    return filteredApps.where((app) => app["isSystemApp"] == true).toList();
  }

  // Get user apps
  List<Map<String, dynamic>> get userApps {
    return filteredApps.where((app) => app["isSystemApp"] == false).toList();
  }

  // Handle app selection toggle
  void selectAll() {
    selectedApps.addAll(filteredApps.map((app) => app["id"] as String));
  }

  void clearAll() {
    selectedApps.clear();
  }

  // Toggle app selection
  void toggleAppSelection(String appId) {
    if (selectedApps.contains(appId)) {
      selectedApps.remove(appId);
    } else {
      selectedApps.add(appId);
    }
  }

  Future<void> handleRefresh() async {
    isRefreshing.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isRefreshing.value = false;
    Get.snackbar('Success', 'App list updated', duration: Duration(seconds: 2));
  }

  // Handle select all

  // Handle search query change
  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  // Handle search focus change
  void onSearchFocusChanged(bool focused) {
    isSearchFocused.value = focused;
  }

  // Handle done button press
  void handleDone() {
    // Save selection and navigate back
    Get.back();
    Get.snackbar(
      'Success',
      '${selectedApps.length} apps selected for monitoring',
      duration: Duration(seconds: 2),
    );
  }

  // Handle section toggle
  void toggleSection(bool isSystemApps) {
    if (isSystemApps) {
      showSystemApps.value = !showSystemApps.value;
    } else {
      showUserApps.value = !showUserApps.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Select Apps',
        variant: CustomAppBarVariant.withBackButton,
        actions: [
          // Selection counter
          Center(
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Obx(
                () => Text(
                  '${selectedApps.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Done button
          TextButton(
            onPressed: handleDone,
            child: Text(
              'Done',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          SearchBarWidget(
            controller: searchController,
            onChanged: onSearchChanged,
            onFocusChanged: onSearchFocusChanged,
            isFocused: isSearchFocused.value,
          ),

          // Bulk action buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: selectAll,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h)),
                    child: Text('Select All'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: clearAll,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 1.5.h)),
                    child: Text('Clear All'),
                  ),
                ),
              ],
            ),
          ),

          // App list
          Expanded(
            child: RefreshIndicator(
              onRefresh: handleRefresh,
              child: filteredApps.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      children: [
                        // System Apps Section
                        if (systemApps.isNotEmpty) ...[
                          SectionHeaderWidget(
                            title: 'System Apps',
                            count: systemApps.length,
                            isExpanded: showSystemApps.value,
                            onToggle: () => toggleSection(true),
                          ),
                          if (showSystemApps.value)
                            ...systemApps.map(
                              (app) => AppListItemWidget(
                                app: app,
                                isSelected: selectedApps.contains(app["id"]),
                                onToggle: () => toggleAppSelection(app["id"] as String),
                                onTap: () => showAppDetails(app),
                              ),
                            ),
                        ],

                        // User Apps Section
                        if (userApps.isNotEmpty) ...[
                          SectionHeaderWidget(
                            title: 'User Apps',
                            count: userApps.length,
                            isExpanded: showUserApps.value,
                            onToggle: () => toggleSection(false),
                          ),
                          if (showUserApps.value)
                            ...userApps.map(
                              (app) => AppListItemWidget(
                                app: app,
                                isSelected: selectedApps.contains(app["id"]),
                                onToggle: () => toggleAppSelection(app["id"] as String),
                                onTap: () => showAppDetails(app),
                              ),
                            ),
                        ],

                        SizedBox(height: 2.h),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedItem: CustomBottomBarItem.apps,
        onItemSelected: (item) {
          // Handle navigation through bottom bar
        },
      ),
    );
  }

  // Build empty state
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            'No apps found',
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: 1.h),
          Text(
            searchQuery.value.isEmpty ? 'No applications installed' : 'Try a different search term',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Show app details dialog
  void showAppDetails(Map<String, dynamic> app) {
    final theme = Theme.of(Get.context!);

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImageWidget(
                    imageUrl: app["icon"] as String,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    semanticLabel: app["semanticLabel"] as String,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app["name"] as String, style: theme.textTheme.titleLarge),
                      SizedBox(height: 0.5.h),
                      Text(
                        app["packageName"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // App statistics
            _buildStatRow('Data Usage', app["dataUsage"] as String, theme),
            _buildStatRow('Total Requests', '${app["requestCount"]}', theme),
            _buildStatRow(
              'Last Activity',
              _formatLastActivity(app["lastActivity"] as DateTime),
              theme,
            ),
            _buildStatRow('Type', (app["isSystemApp"] as bool) ? 'System App' : 'User App', theme),

            SizedBox(height: 3.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/request-list-screen');
                    },
                    icon: CustomIconWidget(
                      iconName: 'list_alt',
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    label: Text('View Requests'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      toggleAppSelection(app["id"] as String);
                    },
                    icon: CustomIconWidget(
                      iconName: selectedApps.contains(app["id"]) ? 'check_circle' : 'add_circle',
                      size: 20,
                      color: theme.colorScheme.onSecondary,
                    ),
                    label: Obx(
                      () => Text(selectedApps.contains(app["id"]) ? 'Monitoring' : 'Monitor'),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  // Build stat row
  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Format last activity time
  String _formatLastActivity(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
