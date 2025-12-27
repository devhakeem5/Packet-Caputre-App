import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

class MonitoringToggleWidget extends StatelessWidget {
  final bool isMonitoring;
  final VoidCallback onToggle;

  const MonitoringToggleWidget({
    super.key,
    required this.isMonitoring,
    required this.onToggle,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Monitoring',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      isMonitoring
                          ? 'Capturing network traffic'
                          : 'Tap to start monitoring',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: isMonitoring
                      ? const Color(0xFF38A169).withValues(alpha: 0.1)
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.1,
                        ),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: isMonitoring ? 'pause' : 'play_arrow',
                  color: isMonitoring
                      ? const Color(0xFF38A169)
                      : theme.colorScheme.onSurfaceVariant,
                  size: 32,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isMonitoring
                    ? theme.colorScheme.error
                    : const Color(0xFF38A169),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
