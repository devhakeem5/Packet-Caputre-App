import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/custom_icon_widget.dart';

/// Search history widget for quick access to previous searches
class SearchHistoryWidget extends StatelessWidget {
  final List<String> searchHistory;
  final Function(String) onSelectHistory;
  final VoidCallback onClearHistory;

  const SearchHistoryWidget({
    super.key,
    required this.searchHistory,
    required this.onSelectHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: 30.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'history',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Recent Searches',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onClearHistory,
                  child: Text(
                    'Clear',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
              itemCount: searchHistory.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, index) {
                final query = searchHistory[index];
                return ListTile(
                  leading: CustomIconWidget(
                    iconName: 'search',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(query, style: theme.textTheme.bodyMedium),
                  trailing: CustomIconWidget(
                    iconName: 'north_west',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onTap: () => onSelectHistory(query),
                  contentPadding: EdgeInsets.symmetric(horizontal: 2.w),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
