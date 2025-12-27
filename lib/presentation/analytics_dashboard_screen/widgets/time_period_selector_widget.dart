import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TimePeriodSelectorWidget extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final Function(String) onPeriodChanged;

  const TimePeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                margin: EdgeInsets.all(0.5.h),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.onSecondary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
