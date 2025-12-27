import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/custom_icon_widget.dart';

class MetricsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final String icon;
//metrics_card_widget.dart
//network_statistics_widget
//
//
//
  const MetricsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = change.startsWith('+');
    final isNegative = change.startsWith('-');

    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF38A169).withValues(alpha: 0.1)
                      : isNegative
                      ? const Color(0xFFE53E3E).withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? const Color(0xFF38A169)
                        : isNegative
                        ? const Color(0xFFE53E3E)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
