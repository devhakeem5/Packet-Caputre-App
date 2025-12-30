import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/app_icon_widget.dart';

class NetworkRequestItemWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;
  final VoidCallback onBlockDomain;
  final VoidCallback onSaveRequest;
  final VoidCallback onShare;
  final VoidCallback onExport;

  const NetworkRequestItemWidget({
    super.key,
    required this.request,
    required this.onTap,
    required this.onBlockDomain,
    required this.onSaveRequest,
    required this.onShare,
    required this.onExport,
  });

  Color _getProtocolColor(String protocol) {
    switch (protocol.toUpperCase()) {
      case 'HTTPS':
        return const Color(0xFF38A169);
      case 'HTTP':
        return const Color(0xFFD69E2E);
      case 'WSS':
        return const Color(0xFF3182CE);
      default:
        return const Color(0xFF718096);
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF3182CE);
      case 'POST':
        return const Color(0xFF38A169);
      case 'PUT':
        return const Color(0xFFD69E2E);
      case 'DELETE':
        return const Color(0xFFE53E3E);
      case 'PATCH':
        return const Color(0xFF805AD5);
      default:
        return const Color(0xFF718096);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    }
  }

  Widget _buildAppIcon(Map<String, dynamic> request, ThemeData theme) {
    return AppIconWidget(packageName: request["appPackage"] as String?, size: 40);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print(request);
    return Slidable(
      key: ValueKey(request["id"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onBlockDomain(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.block,
            label: 'Block',
          ),
          SlidableAction(
            onPressed: (_) => onSaveRequest(),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.bookmark_add_outlined,
            label: 'Save',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildContextMenu(context, theme),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                request["appName"] as String? ?? 'appName',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.2.h),
                              decoration: BoxDecoration(
                                color: (request["isSystemApp"] == true)
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (request["isSystemApp"] == true)
                                      ? Colors.orange.withValues(alpha: 0.5)
                                      : Colors.blue.withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                (request["isSystemApp"] == true) ? "SYS" : "USER",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                  color: (request["isSystemApp"] == true)
                                      ? Colors.orange[800]
                                      : Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.25.h),
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
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _getProtocolColor(
                        request["protocol"] as String,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request["protocol"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getProtocolColor(request["protocol"] as String),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _getMethodColor(request["method"] as String).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request["method"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getMethodColor(request["method"] as String),
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      request["domain"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatTimestamp(request["timestamp"] as DateTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'data_usage',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        request["requestSize"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 2.h),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            title: Text('Share', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              onShare();
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            title: Text('Export', style: theme.textTheme.bodyLarge),
            onTap: () {
              Navigator.pop(context);
              onExport();
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
