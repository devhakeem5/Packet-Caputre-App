import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CaptureController extends GetxController {
  RxBool isRunning = false.obs;
  Rxn<String> selectedPackageName = Rxn<String>();

  static const platform = MethodChannel('com.example.packet_capture/methods');

  Future<void> startCapture() async {
    try {
      if (selectedPackageName.value != null) {
        // Pass selected package
      }
      await platform.invokeMethod('startCapture');
      isRunning.value = true;
    } on PlatformException catch (e) {
      print("Failed to start capture: '${e.message}'.");
    }
  }

  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
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
