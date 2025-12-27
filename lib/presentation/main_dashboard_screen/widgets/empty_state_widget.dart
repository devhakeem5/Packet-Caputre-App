import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onStartMonitoring;

  const EmptyStateWidget({super.key, required this.onStartMonitoring});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'monitor_heart',
                  color: theme.colorScheme.secondary,
                  size: 80,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Start Network Monitoring',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Monitor network traffic from your apps in real-time. Track requests, analyze data usage, and debug network issues.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: onStartMonitoring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38A169),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'play_arrow',
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Start Monitoring',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Setup Guide',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildSetupStep(
                    context,
                    number: '1',
                    title: 'Grant VPN Permission',
                    description:
                        'Allow NetWatch Pro to create a local VPN connection',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildSetupStep(
                    context,
                    number: '2',
                    title: 'Select Apps to Monitor',
                    description:
                        'Choose which apps you want to track network activity for',
                  ),
                  SizedBox(height: 1.5.h),
                  _buildSetupStep(
                    context,
                    number: '3',
                    title: 'Start Monitoring',
                    description:
                        'Begin capturing and analyzing network requests in real-time',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
