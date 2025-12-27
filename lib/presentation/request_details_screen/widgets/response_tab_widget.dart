import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Response tab widget displaying response data with formatting
class ResponseTabWidget extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const ResponseTabWidget({super.key, required this.requestData});

  @override
  State<ResponseTabWidget> createState() => _ResponseTabWidgetState();
}

class _ResponseTabWidgetState extends State<ResponseTabWidget> {
  bool _isFormattedView = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responseBody = widget.requestData['responseBody'] as String? ?? '';
    final isEncrypted = widget.requestData['isEncrypted'] as bool? ?? false;
    final contentType =
        widget.requestData['contentType'] as String? ?? 'text/plain';

    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          child: responseBody.isEmpty
              ? _buildEmptyState(context, isEncrypted)
              : _buildResponseContent(context, responseBody, contentType),
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
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
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
                    hintText: 'Search in response...',
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
                      vertical: 1.h,
                    ),
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
                onPressed: () => _copyToClipboard(
                  context,
                  widget.requestData['responseBody'] as String? ?? '',
                ),
                tooltip: 'Copy response',
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
              isEncrypted
                  ? 'Response data is encrypted'
                  : 'No response data available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              isEncrypted
                  ? 'HTTPS responses cannot be decrypted without SSL pinning bypass'
                  : 'The request may not have completed or no response was captured',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseContent(
    BuildContext context,
    String content,
    String contentType,
  ) {
    final theme = Theme.of(context);
    final displayContent = _getHighlightedContent(content);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: SelectableText(
            displayContent,
            style: AppTheme.getMonospaceStyle(
              isLight: theme.brightness == Brightness.light,
              fontSize: 12,
            ).copyWith(height: 1.5),
          ),
        ),
      ),
    );
  }

  String _getHighlightedContent(String content) {
    if (_searchQuery.isEmpty || !_isFormattedView) {
      return _isFormattedView ? _formatContent(content) : content;
    }

    final formatted = _isFormattedView ? _formatContent(content) : content;
    return formatted;
  }

  String _formatContent(String content) {
    try {
      // Simple JSON formatting
      if (content.trim().startsWith('{') || content.trim().startsWith('[')) {
        return _formatJson(content);
      }
      // Simple XML formatting
      if (content.trim().startsWith('<')) {
        return _formatXml(content);
      }
      return content;
    } catch (e) {
      return content;
    }
  }

  String _formatJson(String json) {
    try {
      final lines = <String>[];
      var indent = 0;
      var inString = false;
      var currentLine = '';

      for (var i = 0; i < json.length; i++) {
        final char = json[i];

        if (char == '"' && (i == 0 || json[i - 1] != '\\')) {
          inString = !inString;
        }

        if (!inString) {
          if (char == '{' || char == '[') {
            currentLine += char;
            lines.add('  ' * indent + currentLine.trim());
            indent++;
            currentLine = '';
            continue;
          } else if (char == '}' || char == ']') {
            if (currentLine.trim().isNotEmpty) {
              lines.add('  ' * indent + currentLine.trim());
            }
            indent--;
            currentLine = char;
            lines.add('  ' * indent + currentLine);
            currentLine = '';
            continue;
          } else if (char == ',') {
            currentLine += char;
            lines.add('  ' * indent + currentLine.trim());
            currentLine = '';
            continue;
          }
        }

        currentLine += char;
      }

      if (currentLine.trim().isNotEmpty) {
        lines.add('  ' * indent + currentLine.trim());
      }

      return lines.join('\n');
    } catch (e) {
      return json;
    }
  }

  String _formatXml(String xml) {
    try {
      final lines = <String>[];
      var indent = 0;
      var currentLine = '';
      var inTag = false;

      for (var i = 0; i < xml.length; i++) {
        final char = xml[i];

        if (char == '<') {
          if (currentLine.trim().isNotEmpty) {
            lines.add('  ' * indent + currentLine.trim());
            currentLine = '';
          }
          inTag = true;
          currentLine += char;
        } else if (char == '>') {
          currentLine += char;
          inTag = false;

          if (currentLine.contains('</')) {
            indent--;
            lines.add('  ' * indent + currentLine.trim());
          } else if (currentLine.contains('/>')) {
            lines.add('  ' * indent + currentLine.trim());
          } else {
            lines.add('  ' * indent + currentLine.trim());
            indent++;
          }
          currentLine = '';
        } else {
          currentLine += char;
        }
      }

      if (currentLine.trim().isNotEmpty) {
        lines.add('  ' * indent + currentLine.trim());
      }

      return lines.join('\n');
    } catch (e) {
      return xml;
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Response copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
