import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaptureController extends GetxController {
  RxBool isRunning = false.obs;
  RxSet<String> selectedApps = <String>{}.obs;
  Rxn<String> selectedPackageName = Rxn<String>(); // Kept for backward compatibility

  static const platform = MethodChannel('com.example.packet_capture/methods');
  static const String _selectedAppsKey = 'selected_apps_for_monitoring';

  @override
  void onInit() {
    super.onInit();
    _loadSelectedApps();
  }

  Future<void> _loadSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApps = prefs.getStringList(_selectedAppsKey) ?? [];
      selectedApps.assignAll(savedApps.toSet());
      print("Loaded ${selectedApps.length} saved apps for monitoring");
    } catch (e) {
      print("Error loading selected apps: $e");
    }
  }

  Future<void> _saveSelectedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_selectedAppsKey, selectedApps.toList());
      print("Saved ${selectedApps.length} apps for monitoring");
    } catch (e) {
      print("Error saving selected apps: $e");
    }
  }

  void updateSelectedApps(Set<String> apps) {
    selectedApps.assignAll(apps);
    _saveSelectedApps();
    // Update backward compatibility field
    selectedPackageName.value = apps.isNotEmpty ? apps.first : null;
  }

  Future<void> startCapture() async {
    try {
      // VPN now captures all traffic - filtering happens in Flutter
      await platform.invokeMethod('startCapture');
      isRunning.value = true;
    } on PlatformException catch (e) {
      print("Failed to start capture: '${e.message}'.");
    }
  }

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      // Add delay to show loading indicator
      await Future.delayed(Duration(milliseconds: 100));
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      print("Flutter received ${result.length} apps from native");
      return result.cast<Map<dynamic, dynamic>>().map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      print("Failed to get apps: '${e.message}'.");
      return [];
    }
  }

  Future<void> stopCapture() async {
    try {
      await platform.invokeMethod('stopCapture');
      isRunning.value = false;
    } on PlatformException catch (e) {
      print("Failed to stop capture: '${e.message}'.");
    }
  }
}
