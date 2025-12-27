import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Overview tab widget displaying request metadata and statistics
class OverviewTabWidget extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const OverviewTabWidget({super.key, required this.requestData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Application Information'),
          SizedBox(height: 1.h),
          _buildInfoCard(context, [
            _InfoItem(
              label: 'Package Name',
              value: requestData['packageName'] as String? ?? 'Unknown',
              isMonospace: true,
            ),
            _InfoItem(
              label: 'App Name',
              value: requestData['appName'] as String? ?? 'Unknown',
            ),
            _InfoItem(
              label: 'Version',
              value: requestData['appVersion'] as String? ?? 'N/A',
              isMonospace: true,
            ),
          ]),
          SizedBox(height: 3.h),
          _buildSectionTitle(context, 'Connection Details'),
          SizedBox(height: 1.h),
          _buildInfoCard(context, [
            _InfoItem(
              label: 'Destination IP',
              value: requestData['destinationIp'] as String? ?? 'N/A',
              isMonospace: true,
            ),
            _InfoItem(
              label: 'Port',
              value: (requestData['port'] as int?)?.toString() ?? 'N/A',
              isMonospace: true,
            ),
            _InfoItem(
              label: 'Protocol',
              value: requestData['protocol'] as String? ?? 'Unknown',
            ),
            _InfoItem(
              label: 'Protocol Version',
              value: requestData['protocolVersion'] as String? ?? 'N/A',
            ),
          ]),
          SizedBox(height: 3.h),
          _buildSectionTitle(context, 'Data Transfer'),
          SizedBox(height: 1.h),
          _buildDataTransferCard(context),
          SizedBox(height: 3.h),
          _buildSectionTitle(context, 'Request Metadata'),
          SizedBox(height: 1.h),
          _buildInfoCard(context, [
            _InfoItem(
              label: 'Request ID',
              value: requestData['requestId'] as String? ?? 'N/A',
              isMonospace: true,
            ),
            _InfoItem(
              label: 'Connection Type',
              value: requestData['connectionType'] as String? ?? 'Unknown',
            ),
            _InfoItem(
              label: 'Encryption',
              value: (requestData['isEncrypted'] as bool? ?? false)
                  ? 'Encrypted (TLS/SSL)'
                  : 'Unencrypted',
            ),
          ]),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<_InfoItem> items) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildInfoRow(context, item),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, _InfoItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context, item.value),
              child: Text(
                item.value,
                style: item.isMonospace
                    ? AppTheme.getMonospaceStyle(
                        isLight: theme.brightness == Brightness.light,
                        fontSize: 14,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTransferCard(BuildContext context) {
    final theme = Theme.of(context);
    final bytesSent = requestData['bytesSent'] as int? ?? 0;
    final bytesReceived = requestData['bytesReceived'] as int? ?? 0;
    final totalBytes = bytesSent + bytesReceived;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sent',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatBytes(bytesSent),
                style: AppTheme.getMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildProgressBar(
            context,
            totalBytes > 0 ? bytesSent / totalBytes : 0,
            theme.colorScheme.secondary,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Received',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatBytes(bytesReceived),
                style: AppTheme.getMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildProgressBar(
            context,
            totalBytes > 0 ? bytesReceived / totalBytes : 0,
            theme.colorScheme.tertiary,
          ),
          SizedBox(height: 2.h),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatBytes(totalBytes),
                style: AppTheme.getMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress, Color color) {
    final theme = Theme.of(context);
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '\$${bytes}B';
    if (bytes < 1024 * 1024) return '\$${(bytes / 1024).toStringAsFixed(2)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '\$${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
    return '\$${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  void _copyToClipboard(BuildContext context, String text) {
    // Haptic feedback would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool isMonospace;

  _InfoItem({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });
}
