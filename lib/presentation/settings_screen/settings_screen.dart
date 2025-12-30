import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../../controllers/traffic_controller.dart';
import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';

/// Settings Screen - Configure app behavior and filters
class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final TrafficController trafficController = Get.find<TrafficController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(title: 'Settings', variant: CustomAppBarVariant.withBackButton),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        children: [
          _buildSectionHeader(context, 'Traffic Filtering'),

          Obx(
            () => _buildSwitchTile(
              context,
              title: 'Hide Unknown Apps',
              subtitle: 'Hide network requests from unidentified applications',
              value: trafficController.hideUnknownApps.value,
              onChanged: (value) {
                trafficController.toggleHideUnknownApps();
              },
              icon: Icons.visibility_off_outlined,
            ),
          ),

          Obx(
            () => _buildSwitchTile(
              context,
              title: 'Encrypted Traffic Filter',
              subtitle: 'Hide requests that could not be decrypted',
              value: trafficController.hideEncryptedTraffic.value,
              onChanged: (value) {
                trafficController.toggleHideEncryptedTraffic();
              },
              icon: Icons.lock_outline,
            ),
          ),

          Obx(
            () => _buildSwitchTile(
              context,
              title: 'Enable HTTP Filtering',
              subtitle: 'Show HTTP (port 80) requests',
              value: trafficController.httpEnabled.value,
              onChanged: (value) {
                trafficController.toggleProtocol('HTTP');
              },
              icon: Icons.http_outlined,
            ),
          ),

          Obx(
            () => _buildSwitchTile(
              context,
              title: 'Enable HTTPS Filtering',
              subtitle: 'Show HTTPS (port 443) requests',
              value: trafficController.httpsEnabled.value,
              onChanged: (value) {
                trafficController.toggleProtocol('HTTPS');
              },
              icon: Icons.https_outlined,
            ),
          ),

          Obx(
            () => _buildListTile(
              context,
              title: trafficController.isCaGenerated.value
                  ? 'Re-install CA Certificate'
                  : 'Install CA Certificate',
              subtitle: 'Required for HTTPS/SSL decryption',
              icon: Icons.security,
              onTap: () {
                _showInstallCaDialog(context);
              },
              trailing: trafficController.isCaGenerated.value
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),

          SizedBox(height: 2.h),
          _buildSectionHeader(context, 'About'),

          _buildListTile(
            context,
            title: 'Version',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            onTap: () {},
          ),

          _buildListTile(
            context,
            title: 'Clear Search History',
            subtitle: 'Remove all saved search queries',
            icon: Icons.history,
            onTap: () {
              trafficController.clearSearchHistory();
              Get.snackbar('Success', 'Search history cleared', duration: Duration(seconds: 2));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 7.w, top: 0.5.h),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        activeThumbColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: theme.colorScheme.onSurface),
        title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _showInstallCaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install Root CA'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To inspect HTTPS traffic, you must install the Root CA certificate manually.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildStep(
                context,
                '1',
                'Save the Certificate file',
                action: TextButton.icon(
                  onPressed: () {
                    // Trigger save
                    trafficController.saveRootCa();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Certificate'),
                ),
              ),
              _buildStep(
                context,
                '2',
                'Open System Settings',
                action: TextButton.icon(
                  onPressed: () {
                    const AndroidIntent(action: 'android.settings.SECURITY_SETTINGS').launch();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ),
              _buildStep(
                context,
                '3',
                'Navigate to:\nEncryption & Credentials > Install a certificate > CA certificate',
              ),
              _buildStep(context, '4', 'Select "Install Anyway" if warned.'),
              _buildStep(context, '5', 'Select the saved file.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              trafficController.verifyRootCa();
            },
            child: const Text('Verify Installation'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
                if (action != null) action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
