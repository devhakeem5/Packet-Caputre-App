import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/traffic_controller.dart';
import '../../core/widgets/custom_buttom_bar.dart';
import '../app_selection_screen/app_selection_screen.dart';
import '../main_dashboard_screen/main_dashboard_screen.dart';
import '../request_list_screen/request_list_screen.dart';
import '../settings_screen/settings_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final TrafficController trafficController = Get.put(TrafficController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        switch (trafficController.selectedBottomBarItem.value) {
          case CustomBottomBarItem.dashboard:
            return MainDashboardScreen();
          case CustomBottomBarItem.apps:
            return AppSelectionScreen();
          case CustomBottomBarItem.requests:
            return RequestListScreen();
          case CustomBottomBarItem.settings:
            return SettingsScreen();
        }
      }),
      bottomNavigationBar: Obx(
        () => CustomBottomBar(
          selectedItem: trafficController.selectedBottomBarItem.value,
          onItemSelected: (item) {
            trafficController.selectedBottomBarItem.value = item;
          },
        ),
      ),
    );
  }
}
