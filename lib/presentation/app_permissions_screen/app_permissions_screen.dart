import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:packet_capture/core/utils/permission_descriptions.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/capture_controller.dart';
import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';

class AppPermissionsScreen extends StatefulWidget {
  final String packageName;
  final String appName;
  final Uint8List? appIconBytes;

  const AppPermissionsScreen({
    super.key,
    required this.packageName,
    required this.appName,
    this.appIconBytes,
  });

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen> {
  final CaptureController controller = Get.find<CaptureController>();
  late Future<List<Map<String, dynamic>>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _permissionsFuture = controller.getAppPermissions(widget.packageName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'App Permissions', variant: CustomAppBarVariant.withBackButton),
      body: Column(
        children: [
          // App Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.appIconBytes != null
                      ? Image.memory(widget.appIconBytes!, width: 60, height: 60, fit: BoxFit.cover)
                      : Container(
                          width: 60,
                          height: 60,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.android, color: theme.colorScheme.primary, size: 32),
                        ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appName,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.packageName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Permissions List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _permissionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        SizedBox(height: 2.h),
                        Text('Failed to load permissions', style: theme.textTheme.titleMedium),
                        Text(
                          snapshot.error.toString(),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final permissions = snapshot.data ?? [];

                if (permissions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        SizedBox(height: 2.h),
                        Text('No permissions requested', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: permissions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
                  itemBuilder: (context, index) {
                    final perm = permissions[index];
                    final name = perm['name'] as String;

                    // Use custom descriptions if available
                    final customDetail = PermissionDescriptions.get(name);
                    final fallbackDetail = PermissionDescriptions.getOrDefault(name);

                    final label = customDetail?.nameEn ?? fallbackDetail.nameEn;
                    final labelAr = customDetail?.nameAr ?? fallbackDetail.nameAr;
                    final description = customDetail?.description ?? fallbackDetail.description;

                    // Prioritize native iconBytes if available, otherwise use custom icon
                    final iconBytes = perm['iconBytes'] as Uint8List?;
                    final iconData = customDetail?.icon ?? fallbackDetail.icon;

                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: iconBytes != null
                              ? Image.memory(iconBytes, width: 24, height: 24)
                              : Icon(iconData, color: theme.colorScheme.secondary, size: 24),
                        ),
                        title: Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          onPressed: () => _showPermissionDetails(context, labelAr, description),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDetails(BuildContext context, String label, String description) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info, color: theme.colorScheme.primary),
            SizedBox(width: 2.w),
            Expanded(child: Text(label, style: theme.textTheme.titleLarge)),
          ],
        ),
        content: Text(description, style: theme.textTheme.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
      ),
    );
  }
}
