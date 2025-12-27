import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/widgets/custom_icon_widget.dart';

/// Sort options bottom sheet widget
class SortBottomSheetWidget extends StatelessWidget {
  final String selectedOption;
  final Function(String) onOptionSelected;

  const SortBottomSheetWidget({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortOptions = [
      {'label': 'Newest', 'icon': 'arrow_downward'},
      {'label': 'Oldest', 'icon': 'arrow_upward'},
      {'label': 'Data Size', 'icon': 'data_usage'},
      {'label': 'Response Time', 'icon': 'schedule'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 1.h),
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Text(
                    'Sort By',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.dividerColor),

            // Sort options
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortOptions.length,
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final label = option['label'] as String;
                final icon = option['icon'] as String;
                final isSelected = selectedOption == label;

                return ListTile(
                  leading: CustomIconWidget(
                    iconName: icon,
                    color: isSelected
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  title: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? CustomIconWidget(
                          iconName: 'check',
                          color: theme.colorScheme.secondary,
                          size: 24,
                        )
                      : null,
                  onTap: () => onOptionSelected(label),
                );
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
