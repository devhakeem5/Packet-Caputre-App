import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

/// Search bar widget for filtering apps
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChanged;
  final bool isFocused;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFocusChanged,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? theme.colorScheme.secondary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: () => onFocusChanged(true),
        decoration: InputDecoration(
          hintText: 'Search apps by name or package...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'search',
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: CustomIconWidget(
                    iconName: 'clear',
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
