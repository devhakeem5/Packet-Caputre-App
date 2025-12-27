import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

class VpnStatusCardWidget extends StatelessWidget {
  final bool isActive;
  final int monitoredAppsCount;
  final String dataCaptured;

  const VpnStatusCardWidget({
    super.key,
    required this.isActive,
    required this.monitoredAppsCount,
    required this.dataCaptured,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF38A169)
                      : theme.colorScheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'VPN Connection',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'shield',
                  label: 'Status',
                  value: isActive ? 'Active' : 'Inactive',
                  valueColor: isActive
                      ? const Color(0xFF38A169)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'apps',
                  label: 'Apps',
                  value: monitoredAppsCount.toString(),
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'data_usage',
                  label: 'Data',
                  value: dataCaptured,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.secondary,
          size: 24,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.25.h),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
