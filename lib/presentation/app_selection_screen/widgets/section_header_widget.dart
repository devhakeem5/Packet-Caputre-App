import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

/// Section header widget for collapsible app categories
class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 1),
            bottom: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Expand/collapse icon
            CustomIconWidget(
              iconName: isExpanded ? 'expand_more' : 'chevron_right',
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),

            SizedBox(width: 2.w),

            // Section title
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // App count badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
