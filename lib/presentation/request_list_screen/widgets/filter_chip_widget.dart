import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Filter chip widget for quick access to common filters
class FilterChipWidget extends StatelessWidget {
  final Set<String> activeFilters;
  final Function(String) onFilterToggle;

  const FilterChipWidget({
    super.key,
    required this.activeFilters,
    required this.onFilterToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ['GET', 'POST', 'PUT', 'DELETE', 'HTTPS', 'WebSocket'];

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isActive = activeFilters.contains(filter);

          return FilterChip(
            label: Text(filter),
            selected: isActive,
            onSelected: (_) => onFilterToggle(filter),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.2),
            checkmarkColor: theme.colorScheme.secondary,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: isActive
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isActive
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
              width: isActive ? 2 : 1,
            ),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          );
        },
      ),
    );
  }
}
