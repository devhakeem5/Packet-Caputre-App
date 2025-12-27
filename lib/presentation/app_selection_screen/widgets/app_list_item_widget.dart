import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

//app_list_item_widget
//
//
/// Individual app list item widget with swipe actions
class AppListItemWidget extends StatelessWidget {
  final Map<String, dynamic> app;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const AppListItemWidget({
    super.key,
    required this.app,
    required this.isSelected,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(app["id"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              Navigator.pushNamed(context, '/request-list-screen');
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.list_alt,
            label: 'Requests',
          ),
          SlidableAction(
            onPressed: (context) {
              onTap();
            },
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.info_outline,
            label: 'Info',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              // App icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImageWidget(
                  imageUrl: app["icon"] as String?,
                  imageBytes: app["iconBytes"] as Uint8List?,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  semanticLabel: app["semanticLabel"] as String?,
                ),
              ),

              SizedBox(width: 3.w),

              // App info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app["name"] as String,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      app["packageName"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (app["lastActivity"] != null) ...[
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'access_time',
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatLastActivity(app["lastActivity"] as DateTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: 'data_usage',
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            app["dataUsage"] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Selection switch
              Switch(
                value: isSelected,
                onChanged: (value) => onToggle(),
                activeThumbColor: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
