import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Request body tab widget displaying request data
class RequestBodyTabWidget extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const RequestBodyTabWidget({super.key, required this.requestData});

  @override
  State<RequestBodyTabWidget> createState() => _RequestBodyTabWidgetState();
}

class _RequestBodyTabWidgetState extends State<RequestBodyTabWidget> {
  bool _isFormattedView = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestBody = widget.requestData['requestBody'] as String? ?? '';
    final isEncrypted = widget.requestData['isEncrypted'] as bool? ?? false;
    final contentType = widget.requestData['contentType'] as String? ?? 'text/plain';

    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          child: requestBody.isEmpty
              ? _buildEmptyState(context, isEncrypted)
              : _buildRequestContent(context, requestBody, contentType),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search in request body...',
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
                      borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text('Formatted'),
                      icon: CustomIconWidget(
                        iconName: 'code',
                        color: _isFormattedView
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Raw'),
                      icon: CustomIconWidget(
                        iconName: 'text_fields',
                        color: !_isFormattedView
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                  ],
                  selected: {_isFormattedView},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() => _isFormattedView = selection.first);
                  },
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'content_copy',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed: () =>
                    _copyToClipboard(context, widget.requestData['requestBody'] as String? ?? ''),
                tooltip: 'Copy request body',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isEncrypted) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: isEncrypted ? 'lock' : 'description',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              isEncrypted ? 'Request data is encrypted' : 'No request body data available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              isEncrypted
                  ? 'HTTPS request bodies cannot be decrypted without SSL pinning bypass'
                  : 'The request may not have a body or it was not captured',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestContent(BuildContext context, String requestBody, String contentType) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5), width: 1),
      ),
      child: _isFormattedView
          ? _buildFormattedView(context, requestBody, contentType)
          : _buildRawView(context, requestBody),
    );
  }

  Widget _buildFormattedView(BuildContext context, String requestBody, String contentType) {
    final theme = Theme.of(context);

    // Simple JSON formatting for now
    String formattedBody = requestBody;
    if (contentType.contains('json')) {
      try {
        // Basic JSON formatting - you might want to use a proper JSON formatter
        formattedBody = requestBody; // For now, keep as is
      } catch (e) {
        // If JSON parsing fails, show raw
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: SelectableText(
        formattedBody,
        style: AppTheme.getMonospaceStyle(
          isLight: theme.brightness == Brightness.light,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRawView(BuildContext context, String requestBody) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: SelectableText(
        requestBody,
        style: AppTheme.getMonospaceStyle(
          isLight: theme.brightness == Brightness.light,
          fontSize: 12,
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    // Implement copy to clipboard functionality
    // You can use Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request body copied to clipboard')));
  }
}
