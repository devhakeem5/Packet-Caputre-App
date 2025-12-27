import 'package:get/get.dart';

class CaptureController extends GetxController {
  RxBool isRunning = false.obs;
  Rxn<String> selectedPackageName = Rxn<String>();

  void startCapture() {
    isRunning.value = true;
    // TODO: Implement capture logic
  }

  void stopCapture() {
    isRunning.value = false;
    // TODO: Implement stop logic
  }
}