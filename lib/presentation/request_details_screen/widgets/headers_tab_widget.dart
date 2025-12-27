  import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Headers tab widget displaying request and response headers
class HeadersTabWidget extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const HeadersTabWidget({super.key, required this.requestData});

  @override
  State<HeadersTabWidget> createState() => _HeadersTabWidgetState();
}

class _HeadersTabWidgetState extends State<HeadersTabWidget> {
  String _searchQuery = '';
  bool _isRequestHeadersExpanded = true;
  bool _isResponseHeadersExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestHeaders =
        widget.requestData['requestHeaders'] as Map<String, dynamic>? ?? {};
    final responseHeaders =
        widget.requestData['responseHeaders'] as Map<String, dynamic>? ?? {};

    final filteredRequestHeaders = _filterHeaders(requestHeaders);
    final filteredResponseHeaders = _filterHeaders(responseHeaders);

    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            children: [
              _buildHeaderSection(
                context,
                'Request Headers',
                filteredRequestHeaders,
                _isRequestHeadersExpanded,
                (value) => setState(() => _isRequestHeadersExpanded = value),
              ),
              SizedBox(height: 2.h),
              _buildHeaderSection(
                context,
                'Response Headers',
                filteredResponseHeaders,
                _isResponseHeadersExpanded,
                (value) => setState(() => _isResponseHeadersExpanded = value),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search headers...',
          prefixIcon: CustomIconWidget(
            iconName: 'search',
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: CustomIconWidget(
                    iconName: 'clear',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: theme.colorScheme.secondary,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    String title,
    Map<String, dynamic> headers,
    bool isExpanded,
    ValueChanged<bool> onExpansionChanged,
  ) {
    final theme = Theme.of(context);
    final headerCount = headers.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: isExpanded ? Radius.zero : const Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      headerCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: isExpanded ? 'expand_less' : 'expand_more',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            if (headers.isEmpty)
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No headers available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...headers.entries.map((entry) {
                return _buildHeaderItem(
                  context,
                  entry.key,
                  entry.value.toString(),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderItem(BuildContext context, String key, String value) {
    final theme = Theme.of(context);
    final isHighlighted =
        _searchQuery.isNotEmpty &&
        (key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            value.toLowerCase().contains(_searchQuery.toLowerCase()));

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onLongPress: () => _copyToClipboard(context, '\$key: \$value'),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      key,
                      style: AppTheme.getMonospaceStyle(
                        isLight: theme.brightness == Brightness.light,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ).copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'content_copy',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onPressed: () =>
                        _copyToClipboard(context, '\$key: \$value'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: AppTheme.getMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 12,
                ).copyWith(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _filterHeaders(Map<String, dynamic> headers) {
    if (_searchQuery.isEmpty) return headers;

    return Map.fromEntries(
      headers.entries.where((entry) {
        final key = entry.key.toLowerCase();
        final value = entry.value.toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return key.contains(query) || value.contains(query);
      }),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
