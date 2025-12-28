import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/custom_image_widget.dart';

/// App filter widget for filtering requests by application
class AppFilterWidget extends StatelessWidget {
  final Set<String> selectedApps;
  final List<Map<String, dynamic>> allRequests;
  final Function(String) onToggleApp;

  const AppFilterWidget({
    super.key,
    required this.selectedApps,
    required this.allRequests,
    required this.onToggleApp,
  });

  List<Map<String, dynamic>> _getUniqueApps() {
    final Map<String, Map<String, dynamic>> uniqueApps = {};
    for (var request in allRequests) {
      final appPackage = request['appPackage'] as String;
      if (!uniqueApps.containsKey(appPackage)) {
        uniqueApps[appPackage] = {
          'appName': request['appName'],
          'appPackage': appPackage,
          'appIcon': request['appIcon'],
          'semanticLabel': request['semanticLabel'],
        };
      }
    }
    final apps = uniqueApps.values.toList();
    apps.sort(
      (a, b) => (a['appName'] as String).compareTo(b['appName'] as String),
    );
    return apps;
  }

  Widget _buildAppIcon(Map<String, dynamic> app, ThemeData theme) {
    final appIcon = app['appIcon'];
    final semanticLabel = app['semanticLabel'] as String? ?? 'App Icon';
    
    // Check if appIcon is a valid non-empty string
    final hasValidIcon = appIcon is String && 
                        appIcon.isNotEmpty && 
                        appIcon != "null" &&
                        appIcon != "false" &&
                        appIcon != "true";
    
    if (hasValidIcon) {
      try {
        return CustomImageWidget(
          imageUrl: appIcon,
          height: 10.w,
          width: 10.w,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
        );
      } catch (e) {
        // Fallback to icon if image loading fails
        return Icon(
          Icons.apps_outlined,
          size: 10.w,
          color: theme.colorScheme.onSurfaceVariant,
        );
      }
    }
    
    // Default icon when no valid icon is available
    return Icon(
      Icons.apps_outlined,
      size: 10.w,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uniqueApps = _getUniqueApps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter by App',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selectedApps.isNotEmpty)
              TextButton(
                onPressed: () {
                  for (var app in selectedApps.toList()) {
                    onToggleApp(app);
                  }
                },
                child: Text(
                  'Clear All',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        if (selectedApps.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No app filters applied. Select apps to show only their requests.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Showing requests from ${selectedApps.length} app${selectedApps.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        SizedBox(height: 1.h),
        ...uniqueApps.map((app) {
          final appPackage = app['appPackage'] as String;
          final isSelected = selectedApps.contains(appPackage);

          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (_) => onToggleApp(appPackage),
              title: Text(
                app['appName'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                appPackage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              secondary: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAppIcon(app, Theme.of(context)),
              ),
              activeColor: theme.colorScheme.secondary,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 2.w,
                vertical: 0.5.h,
              ),
            ),
          );
        }),
      ],
    );
  }
}
