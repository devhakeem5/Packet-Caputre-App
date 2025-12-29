import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Request card widget displaying network request information
class RequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;

  const RequestCardWidget({
    super.key,
    required this.request,
    required this.onTap,
  });

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'HTTP':
        return const Color(0xFFD69E2E); // Warning amber
      case 'HTTPS':
        return const Color(0xFF38A169); // Success green
      case 'WebSocket':
        return const Color(0xFF3182CE); // Accent blue
      default:
        return const Color(0xFF718096); // Secondary gray
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return const Color(0xFF38A169); // Success
    } else if (statusCode >= 300 && statusCode < 400) {
      return const Color(0xFF3182CE); // Info
    } else if (statusCode >= 400 && statusCode < 500) {
      return const Color(0xFFD69E2E); // Warning
    } else {
      return const Color(0xFFE53E3E); // Error
    }
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
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    }
  }

  Widget _buildAppIcon(Map<String, dynamic> request, ThemeData theme) {
    final appIcon = request["appIcon"];
    final semanticLabel = request["semanticLabel"] as String? ?? 'App Icon';
    
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
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
        );
      } catch (e) {
        // Fallback to icon if image loading fails
        return Icon(
          Icons.apps_outlined,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant,
        );
      }
    }
    
    // Default icon when no valid icon is available
    return Icon(
      Icons.apps_outlined,
      size: 40,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final protocol = request["protocol"] as String;
    final statusCode = request["statusCode"] as int;
    final timestamp = request["timestamp"] as DateTime;

    return Slidable(
      key: ValueKey(request["id"]),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              // View details action
              onTap();
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.visibility,
            label: 'Details',
          ),
          SlidableAction(
            onPressed: (_) {
              // Share action
            },
            backgroundColor: const Color(0xFF3182CE),
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              // Export action
            },
            backgroundColor: const Color(0xFF38A169),
            foregroundColor: Colors.white,
            icon: Icons.download,
            label: 'Export',
          ),
          SlidableAction(
            onPressed: (_) {
              // Block action
            },
            backgroundColor: const Color(0xFFE53E3E),
            foregroundColor: Colors.white,
            icon: Icons.block,
            label: 'Block',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          // Show context menu
          _showContextMenu(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: _getProtocolColor(protocol), width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App info row
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildAppIcon(request, theme),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request["appName"] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            request["appPackage"] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Method badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        request["method"] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),

                // URL
                Text(
                  request["destinationUrl"] as String? ??'Null',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),

                // Status and metrics row
                Row(
                  children: [
                    // Status code
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          statusCode,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusCode.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(statusCode),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),

                    // Protocol
                    CustomIconWidget(
                      iconName: protocol == 'WebSocket' ? 'swap_horiz' : 'lock',
                      color: _getProtocolColor(protocol),
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      protocol,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 3.w),

                    // Response time
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      request["responseTime"] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),

                    // Timestamp
                    Text(
                      _formatTimestamp(timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),

                // Data transfer row
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'arrow_upward',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      request["requestSize"] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    CustomIconWidget(
                      iconName: 'arrow_downward',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      request["responseSize"] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Copy URL', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                // Copy URL to clipboard
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'info',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('View App Details', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                // Navigate to app details
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'filter_alt',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Filter by Domain', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                // Apply domain filter
              },
            ),
          ],
        ),
      ),
    );
  }
}
