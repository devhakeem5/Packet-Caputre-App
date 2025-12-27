import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Empty state widget shown when no requests are captured
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onActivateMonitoring;

  const EmptyStateWidget({super.key, required this.onActivateMonitoring});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            CustomImageWidget(
              imageUrl:
                  'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400',
              width: 60.w,
              height: 30.h,
              fit: BoxFit.contain,
              semanticLabel:
                  'Network monitoring illustration with connected devices and data flow visualization',
            ),
            SizedBox(height: 3.h),

            // Title
            Text(
              'No Network Activity',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),

            // Description
            Text(
              'Start monitoring to capture network requests from your apps. All captured data will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Action button
            ElevatedButton.icon(
              onPressed: onActivateMonitoring,
              icon: CustomIconWidget(
                iconName: 'play_arrow',
                color: theme.colorScheme.onSecondary,
                size: 24,
              ),
              label: const Text('Start Monitoring'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              ),
            ),
            SizedBox(height: 2.h),

            // Secondary action
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/app-selection-screen');
              },
              child: const Text('Select Apps to Monitor'),
            ),
          ],
        ),
      ),
    );
  }
}
