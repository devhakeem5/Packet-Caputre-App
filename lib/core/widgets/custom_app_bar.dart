import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different screen contexts
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with back button for navigation
  withBackButton,

  /// App bar with search functionality
  withSearch,

  /// App bar with monitoring status indicator
  withStatus,

  /// Minimal app bar with only essential elements
  minimal,
}

/// Monitoring status for status indicator variant
enum MonitoringStatus { active, inactive, paused, error }

/// Custom app bar widget for network monitoring application
/// Implements clean, data-focused design with professional sophistication
/// Follows Material Design guidelines with proper elevation and spacing
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display in the app bar
  final String title;

  /// Variant of the app bar to display
  final CustomAppBarVariant variant;

  /// Optional subtitle text (displayed below title)
  final String? subtitle;

  /// Optional leading widget (overrides default back button)
  final Widget? leading;

  /// List of action widgets to display on the right
  final List<Widget>? actions;

  /// Whether to show elevation shadow
  final bool showElevation;

  /// Custom elevation value (default: 0 for flat design)
  final double elevation;

  /// Background color (defaults to theme surface color)
  final Color? backgroundColor;

  /// Foreground color for text and icons (defaults to theme onSurface)
  final Color? foregroundColor;

  /// Monitoring status for status indicator variant
  final MonitoringStatus? monitoringStatus;

  /// Callback for search functionality
  final ValueChanged<String>? onSearchChanged;

  /// Search query text for search variant
  final String? searchQuery;

  /// Whether the search bar is focused
  final bool isSearchFocused;

  /// Callback when search focus changes
  final ValueChanged<bool>? onSearchFocusChanged;

  const CustomAppBar({
    super.key,
    required this.title,
    this.variant = CustomAppBarVariant.standard,
    this.subtitle,
    this.leading,
    this.actions,
    this.showElevation = false,
    this.elevation = 0.0,
    this.backgroundColor,
    this.foregroundColor,
    this.monitoringStatus,
    this.onSearchChanged,
    this.searchQuery,
    this.isSearchFocused = false,
    this.onSearchFocusChanged,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    variant == CustomAppBarVariant.withSearch && isSearchFocused
        ? 120.0 // Extended height for search
        : subtitle != null
        ? 72.0 // Height with subtitle
        : 56.0, // Standard height
  );

  /// Get status color based on monitoring status
  Color _getStatusColor(BuildContext context, MonitoringStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case MonitoringStatus.active:
        return const Color(0xFF38A169); // Success green
      case MonitoringStatus.inactive:
        return colorScheme.onSurfaceVariant;
      case MonitoringStatus.paused:
        return const Color(0xFFD69E2E); // Warning amber
      case MonitoringStatus.error:
        return const Color(0xFFE53E3E); // Error red
    }
  }

  /// Get status label text
  String _getStatusLabel(MonitoringStatus status) {
    switch (status) {
      case MonitoringStatus.active:
        return 'Monitoring Active';
      case MonitoringStatus.inactive:
        return 'Monitoring Inactive';
      case MonitoringStatus.paused:
        return 'Monitoring Paused';
      case MonitoringStatus.error:
        return 'Connection Error';
    }
  }

  /// Build leading widget based on variant
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (variant == CustomAppBarVariant.withBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    }

    return null;
  }

  /// Build title widget based on variant
  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        foregroundColor ?? theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

    if (variant == CustomAppBarVariant.withStatus && monitoringStatus != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.appBarTheme.titleTextStyle?.copyWith(color: textColor)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(context, monitoringStatus!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusLabel(monitoringStatus!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.appBarTheme.titleTextStyle?.copyWith(color: textColor)),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    return Text(title, style: theme.appBarTheme.titleTextStyle?.copyWith(color: textColor));
  }

  /// Build search bar for search variant
  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSearchFocused
              ? colorScheme.secondary
              : colorScheme.outline.withValues(alpha: 0.5),
          width: isSearchFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        onTap: () => onSearchFocusChanged?.call(true),
        decoration: InputDecoration(
          hintText: 'Search requests, domains, IPs...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: searchQuery != null && searchQuery!.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () => onSearchChanged?.call(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarColor = backgroundColor ?? theme.appBarTheme.backgroundColor ?? colorScheme.surface;
    final textColor = foregroundColor ?? theme.appBarTheme.foregroundColor ?? colorScheme.onSurface;

    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    if (variant == CustomAppBarVariant.withSearch) {
      return AppBar(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: showElevation ? elevation : 0,
        // leading: _buildLeading(context),
        title: isSearchFocused ? null : _buildTitle(context),
        actions: isSearchFocused ? null : actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildSearchBar(context),
        ),
      );
    }

    return AppBar(
      backgroundColor: appBarColor,
      foregroundColor: textColor,
      elevation: showElevation ? elevation : 0,
      // leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: actions,
      centerTitle: variant == CustomAppBarVariant.minimal,
    );
  }
}

/// Extension to provide easy access to app bar variants
extension CustomAppBarExtension on BuildContext {
  /// Build a standard app bar
  PreferredSizeWidget buildStandardAppBar({
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      variant: CustomAppBarVariant.standard,
    );
  }

  /// Build an app bar with back button
  PreferredSizeWidget buildAppBarWithBack({
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      actions: actions,
      variant: CustomAppBarVariant.withBackButton,
    );
  }

  /// Build an app bar with search
  PreferredSizeWidget buildSearchAppBar({
    required String title,
    required ValueChanged<String> onSearchChanged,
    String? searchQuery,
    bool isSearchFocused = false,
    ValueChanged<bool>? onSearchFocusChanged,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      title: title,
      variant: CustomAppBarVariant.withSearch,
      onSearchChanged: onSearchChanged,
      searchQuery: searchQuery,
      isSearchFocused: isSearchFocused,
      onSearchFocusChanged: onSearchFocusChanged,
      actions: actions,
    );
  }

  /// Build an app bar with monitoring status
  PreferredSizeWidget buildStatusAppBar({
    required String title,
    required MonitoringStatus status,
    List<Widget>? actions,
  }) {
    return CustomAppBar(
      title: title,
      variant: CustomAppBarVariant.withStatus,
      monitoringStatus: status,
      actions: actions,
    );
  }
}
