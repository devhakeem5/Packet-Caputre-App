
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

/// Active filter bar showing applied filters with remove functionality
class ActiveFilterBarWidget extends StatelessWidget {
  final Set<String> activeFilters;
  final Function(String) onRemoveFilter;
  final VoidCallback onClearAll;

  const ActiveFilterBarWidget({
    super.key,
    required this.activeFilters,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: activeFilters.map((filter) {
                return Chip(
                  label: Text(filter),
                  deleteIcon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 16,
                  ),
                  onDeleted: () => onRemoveFilter(filter),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                );
              }).toList(),
            ),
          ),
          TextButton(
            onPressed: onClearAll,
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
    );
  }
}
