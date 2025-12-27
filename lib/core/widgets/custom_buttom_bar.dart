import 'package:flutter/material.dart';

/// Navigation item configuration for the bottom navigation bar
enum CustomBottomBarItem { dashboard, apps, requests, settings }

/// Custom bottom navigation bar widget for network monitoring application
/// Implements bottom-heavy primary actions with thumb-reachable controls
/// Follows Material Design guidelines with 48dp minimum touch targets
class CustomBottomBar extends StatelessWidget {
  /// Currently selected navigation item
  final CustomBottomBarItem selectedItem;

  /// Callback when navigation item is tapped
  final ValueChanged<CustomBottomBarItem> onItemSelected;

  /// Whether to show labels for all items (default: true)
  final bool showLabels;

  /// Custom elevation for the bottom bar (default: 8.0)
  final double elevation;

  const CustomBottomBar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
    this.showLabels = true,
    this.elevation = 8.0,
  });

  /// Get the route path for a navigation item
  String _getRoutePath(CustomBottomBarItem item) {
    switch (item) {
      case CustomBottomBarItem.dashboard:
        return '/main-dashboard-screen';
      case CustomBottomBarItem.apps:
        return '/app-selection-screen';
      case CustomBottomBarItem.requests:
        return '/request-list-screen';
      case CustomBottomBarItem.settings:
        return '/request-details-screen'; // Settings/configuration screen
    }
  }

  /// Get the icon for a navigation item
  IconData _getIcon(CustomBottomBarItem item, bool isSelected) {
    switch (item) {
      case CustomBottomBarItem.dashboard:
        return isSelected ? Icons.monitor_heart : Icons.monitor_heart_outlined;
      case CustomBottomBarItem.apps:
        return isSelected ? Icons.apps : Icons.apps_outlined;
      case CustomBottomBarItem.requests:
        return isSelected ? Icons.list_alt : Icons.list_alt_outlined;
      case CustomBottomBarItem.settings:
        return isSelected ? Icons.settings : Icons.settings_outlined;
    }
  }

  /// Get the label for a navigation item
  String _getLabel(CustomBottomBarItem item) {
    switch (item) {
      case CustomBottomBarItem.dashboard:
        return 'Monitor';
      case CustomBottomBarItem.apps:
        return 'Apps';
      case CustomBottomBarItem.requests:
        return 'Activity';
      case CustomBottomBarItem.settings:
        return 'Settings';
    }
  }

  /// Handle navigation item tap with proper navigation
  void _handleItemTap(BuildContext context, CustomBottomBarItem item) {
    if (item != selectedItem) {
      onItemSelected(item);

      // Navigate to the corresponding route
      final routePath = _getRoutePath(item);
      Navigator.pushReplacementNamed(context, routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomNavTheme = theme.bottomNavigationBarTheme;

    return Container(
      decoration: BoxDecoration(
        color: bottomNavTheme.backgroundColor ?? colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: elevation,
            offset: Offset(0, -elevation / 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64, // Standard bottom nav height
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: CustomBottomBarItem.values.map((item) {
              final isSelected = item == selectedItem;
              final icon = _getIcon(item, isSelected);
              final label = _getLabel(item);

              return Expanded(
                child: _BottomNavItem(
                  icon: icon,
                  label: label,
                  isSelected: isSelected,
                  showLabel: showLabels,
                  onTap: () => _handleItemTap(context, item),
                  selectedColor:
                      bottomNavTheme.selectedItemColor ?? colorScheme.secondary,
                  unselectedColor:
                      bottomNavTheme.unselectedItemColor ??
                      colorScheme.onSurfaceVariant,
                  selectedLabelStyle: bottomNavTheme.selectedLabelStyle,
                  unselectedLabelStyle: bottomNavTheme.unselectedLabelStyle,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Individual bottom navigation item widget
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;
    final labelStyle = isSelected ? selectedLabelStyle : unselectedLabelStyle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with smooth transition
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),

            // Label with fade transition
            if (showLabel) ...[
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: (labelStyle ?? const TextStyle()).copyWith(
                  color: color,
                  fontSize: 12,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Extension to provide easy access to bottom bar in widget tree
extension CustomBottomBarExtension on BuildContext {
  /// Show the custom bottom bar with the current selected item
  Widget buildBottomBar({
    required CustomBottomBarItem selectedItem,
    required ValueChanged<CustomBottomBarItem> onItemSelected,
    bool showLabels = true,
    double elevation = 8.0,
  }) {
    return CustomBottomBar(
      selectedItem: selectedItem,
      onItemSelected: onItemSelected,
      showLabels: showLabels,
      elevation: elevation,
    );
  }
}
