  import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/custom_icon_widget.dart';

/// Domain blocklist widget for filtering out specific domains
class DomainBlocklistWidget extends StatefulWidget {
  final Set<String> blockedDomains;
  final List<Map<String, dynamic>> allRequests;
  final Function(String) onAddDomain;
  final Function(String) onRemoveDomain;

  const DomainBlocklistWidget({
    super.key,
    required this.blockedDomains,
    required this.allRequests,
    required this.onAddDomain,
    required this.onRemoveDomain,
  });

  @override
  State<DomainBlocklistWidget> createState() => _DomainBlocklistWidgetState();
}

class _DomainBlocklistWidgetState extends State<DomainBlocklistWidget> {
  final TextEditingController _domainController = TextEditingController();
  bool _showAddField = false;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  void _addDomain() {
    final domain = _domainController.text.trim().toLowerCase();
    if (domain.isNotEmpty && !widget.blockedDomains.contains(domain)) {
      widget.onAddDomain(domain);
      _domainController.clear();
      setState(() {
        _showAddField = false;
      });
    }
  }

  List<String> _getAvailableDomains() {
    final domains = widget.allRequests
        .map((r) => (r['domain'] as String).toLowerCase())
        .toSet()
        .toList();
    domains.sort();
    return domains;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableDomains = _getAvailableDomains();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Domain Blocklist',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAddField = !_showAddField;
                });
              },
              icon: CustomIconWidget(
                iconName: _showAddField ? 'close' : 'add',
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              label: Text(
                _showAddField ? 'Cancel' : 'Add',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_showAddField) SizedBox(height: 1.h),
        if (_showAddField)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  decoration: InputDecoration(
                    hintText: 'Enter domain (e.g., example.com)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  onSubmitted: (_) => _addDomain(),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: _addDomain,
                icon: CustomIconWidget(
                  iconName: 'check',
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: 1.h),
        if (widget.blockedDomains.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'No blocked domains. Add domains to hide their requests.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.blockedDomains.isNotEmpty)
          Column(
            children: [
              ...widget.blockedDomains.map((domain) {
                return Container(
                  margin: EdgeInsets.only(bottom: 1.h),
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'block',
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          domain,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.onRemoveDomain(domain),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        if (availableDomains.isNotEmpty && !_showAddField)
          SizedBox(height: 1.h),
        if (availableDomains.isNotEmpty && !_showAddField)
          Text(
            'Quick Add from Requests',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (availableDomains.isNotEmpty && !_showAddField)
          SizedBox(height: 0.5.h),
        if (availableDomains.isNotEmpty && !_showAddField)
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: availableDomains
                .where((d) => !widget.blockedDomains.contains(d))
                .take(5)
                .map((domain) {
                  return ActionChip(
                    label: Text(domain),
                    onPressed: () => widget.onAddDomain(domain),
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    labelStyle: theme.textTheme.labelSmall,
                  );
                })
                .toList(),
          ),
      ],
    );
  }
}
