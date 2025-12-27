import 'package:flutter/material.dart';
import '../presentation/app_selection_screen/app_selection_screen.dart';
import '../presentation/request_list_screen/request_list_screen.dart';
import '../presentation/main_dashboard_screen/main_dashboard_screen.dart';
import '../presentation/request_details_screen/request_details_screen.dart';
import '../presentation/analytics_dashboard_screen/analytics_dashboard_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String appSelection = '/app-selection-screen';
  static const String requestList = '/request-list-screen';
  static const String mainDashboard = '/main-dashboard-screen';
  static const String requestDetails = '/request-details-screen';
  static const String analyticsDashboard = '/analytics-dashboard-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) =>  MainDashboardScreen(),
    appSelection: (context) =>  AppSelectionScreen(),
    requestList: (context) =>  RequestListScreen(),
    mainDashboard: (context) =>  MainDashboardScreen(),
    requestDetails: (context) =>  RequestDetailsScreen(),
    analyticsDashboard: (context) =>  AnalyticsDashboardScreen(),
    // TODO: Add your other routes here
  };
}
