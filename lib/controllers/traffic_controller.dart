import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/captured_request.dart';
import '../core/widgets/custom_buttom_bar.dart';

class TrafficController extends GetxController with GetSingleTickerProviderStateMixin {
  // Requests data
  RxList<CapturedRequest> requests = <CapturedRequest>[].obs;

  // Mock data for network requests
  RxList<Map<String, dynamic>> allRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredRequests = <Map<String, dynamic>>[].obs;

  // Search and filter state
  RxString searchQuery = ''.obs;
  RxBool isSearchFocused = false.obs;
  RxSet<String> activeFilters = <String>{}.obs;
  RxString selectedSortOption = 'Newest'.obs;

  // Persistent filters
  RxSet<String> blockedDomains = <String>{}.obs;
  RxSet<String> selectedApps = <String>{}.obs;
  RxList<String> searchHistory = <String>[].obs;
  RxBool httpEnabled = true.obs;
  RxBool httpsEnabled = true.obs;

  // Tab controllers
  late TabController tabController;
  late TabController requestListTabController;

  // Bottom bar selection
  Rx<CustomBottomBarItem> selectedBottomBarItem = CustomBottomBarItem.requests.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeMockData();
    requestListTabController = TabController(length: 4, vsync: this);
    tabController = TabController(length: 4, vsync: this);
    filteredRequests.assignAll(allRequests);
    _loadPersistentFilters();
  }

  @override
  void onClose() {
    tabController.dispose();
    requestListTabController.dispose();
    super.onClose();
  }

  void _initializeMockData() {
    allRequests.assignAll([
      {
        "id": "req_001",
        "appName": "Chrome Browser",
        "appPackage": "com.android.chrome",
        "appIcon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1f5d028f0-1764656770781.png",
        "semanticLabel":
            "Chrome browser icon with red, yellow, green, and blue colors in circular design",
        "destinationUrl": "https://api.github.com/users/octocat",
        "domain": "api.github.com",
        "method": "GET",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
        "requestSize": "2.4 KB",
        "responseSize": "15.8 KB",
        "responseTime": "245 ms",
        "headers": {"Content-Type": "application/json", "User-Agent": "Chrome/120.0.0.0"},
      },
      {
        "id": "req_002",
        "appName": "Instagram",
        "appPackage": "com.instagram.android",
        "appIcon": "https://images.unsplash.com/photo-1666408738188-212c470d08b0",
        "semanticLabel": "Instagram app icon with gradient colors from purple to orange",
        "destinationUrl": "https://i.instagram.com/api/v1/feed/timeline",
        "domain": "i.instagram.com",
        "method": "POST",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(minutes: 12)),
        "requestSize": "5.2 KB",
        "responseSize": "128.5 KB",
        "responseTime": "892 ms",
        "headers": {"Content-Type": "application/json", "Authorization": "Bearer token_hidden"},
      },
      {
        "id": "req_003",
        "appName": "WhatsApp",
        "appPackage": "com.whatsapp",
        "appIcon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1b3def8dd-1764662218645.png",
        "semanticLabel": "WhatsApp messenger icon with green background and white phone symbol",
        "destinationUrl": "https://web.whatsapp.com/ws",
        "domain": "web.whatsapp.com",
        "method": "GET",
        "protocol": "WebSocket",
        "statusCode": 101,
        "timestamp": DateTime.now().subtract(const Duration(hours: 1)),
        "requestSize": "1.2 KB",
        "responseSize": "0 KB",
        "responseTime": "156 ms",
        "headers": {"Upgrade": "websocket", "Connection": "Upgrade"},
      },
      {
        "id": "req_004",
        "appName": "YouTube",
        "appPackage": "com.google.android.youtube",
        "appIcon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_18583e273-1764662218552.png",
        "semanticLabel": "YouTube app icon with red play button on white background",
        "destinationUrl": "https://www.youtube.com/youtubei/v1/player",
        "domain": "www.youtube.com",
        "method": "POST",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
        "requestSize": "8.7 KB",
        "responseSize": "256.3 KB",
        "responseTime": "1245 ms",
        "headers": {"Content-Type": "application/json", "X-YouTube-Client-Name": "1"},
      },
      {
        "id": "req_005",
        "appName": "Gmail",
        "appPackage": "com.google.android.gm",
        "appIcon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_116066d30-1764656771637.png",
        "semanticLabel": "Gmail app icon with red and white envelope design",
        "destinationUrl": "https://mail.google.com/sync/u/0/i/s",
        "domain": "mail.google.com",
        "method": "POST",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(hours: 3)),
        "requestSize": "3.1 KB",
        "responseSize": "45.2 KB",
        "responseTime": "567 ms",
        "headers": {"Content-Type": "application/json", "Authorization": "Bearer token_hidden"},
      },
      {
        "id": "req_006",
        "appName": "Spotify",
        "appPackage": "com.spotify.music",
        "appIcon":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1d71ebfa2-1764751041051.png",
        "semanticLabel": "Spotify app icon with green background and black circular logo",
        "destinationUrl": "https://api.spotify.com/v1/me/player",
        "domain": "api.spotify.com",
        "method": "GET",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(hours: 4)),
        "requestSize": "1.8 KB",
        "responseSize": "12.4 KB",
        "responseTime": "234 ms",
        "headers": {"Content-Type": "application/json", "Authorization": "Bearer token_hidden"},
      },
      {
        "id": "req_007",
        "appName": "Twitter",
        "appPackage": "com.twitter.android",
        "appIcon": "https://images.unsplash.com/photo-1667235326880-324e1a51d40b",
        "semanticLabel": "Twitter app icon with blue bird logo on white background",
        "destinationUrl": "https://api.twitter.com/2/timeline/home.json",
        "domain": "api.twitter.com",
        "method": "GET",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
        "requestSize": "2.9 KB",
        "responseSize": "89.7 KB",
        "responseTime": "678 ms",
        "headers": {"Content-Type": "application/json", "Authorization": "Bearer token_hidden"},
      },
      {
        "id": "req_008",
        "appName": "Netflix",
        "appPackage": "com.netflix.mediaclient",
        "appIcon": "https://images.unsplash.com/photo-1662338035252-74cdac76bd2a",
        "semanticLabel": "Netflix app icon with red background and white N logo",
        "destinationUrl": "https://www.netflix.com/api/shakti/browse",
        "domain": "www.netflix.com",
        "method": "GET",
        "protocol": "HTTPS",
        "statusCode": 200,
        "timestamp": DateTime.now().subtract(const Duration(hours: 6)),
        "requestSize": "4.5 KB",
        "responseSize": "342.1 KB",
        "responseTime": "1567 ms",
        "headers": {"Content-Type": "application/json", "Cookie": "session_hidden"},
      },
    ]);
  }

  // Load persistent filters from storage
  Future<void> _loadPersistentFilters() async {
    final prefs = await SharedPreferences.getInstance();
    blockedDomains.assignAll((prefs.getStringList('blocked_domains') ?? []).toSet());
    selectedApps.assignAll((prefs.getStringList('selected_apps') ?? []).toSet());
    searchHistory.assignAll(prefs.getStringList('search_history') ?? []);
    httpEnabled.value = prefs.getBool('http_enabled') ?? true;
    httpsEnabled.value = prefs.getBool('https_enabled') ?? true;
    applyFiltersAndSort();
  }

  // Save persistent filters to storage
  Future<void> _savePersistentFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_domains', blockedDomains.toList());
    await prefs.setStringList('selected_apps', selectedApps.toList());
    await prefs.setStringList('search_history', searchHistory);
    await prefs.setBool('http_enabled', httpEnabled.value);
    await prefs.setBool('https_enabled', httpsEnabled.value);
  }

  // Add domain to blocklist
  void addBlockedDomain(String domain) {
    blockedDomains.add(domain.toLowerCase());
    _savePersistentFilters();
    applyFiltersAndSort();
  }

  // Remove domain from blocklist
  void removeBlockedDomain(String domain) {
    blockedDomains.remove(domain);
    _savePersistentFilters();
    applyFiltersAndSort();
  }

  // Toggle app filter
  void toggleAppFilter(String appPackage) {
    if (selectedApps.contains(appPackage)) {
      selectedApps.remove(appPackage);
    } else {
      selectedApps.add(appPackage);
    }
    _savePersistentFilters();
    applyFiltersAndSort();
  }

  // Toggle protocol filters
  void toggleProtocol(String protocol) {
    if (protocol == 'HTTP') {
      httpEnabled.value = !httpEnabled.value;
    } else if (protocol == 'HTTPS') {
      httpsEnabled.value = !httpsEnabled.value;
    }
    _savePersistentFilters();
    applyFiltersAndSort();
  }

  // Add search to history
  void addToSearchHistory(String query) {
    if (query.isEmpty) return;
    searchHistory.remove(query); // Remove if exists
    searchHistory.insert(0, query); // Add to beginning
    if (searchHistory.length > 10) {
      searchHistory.value = searchHistory.sublist(0, 10); // Keep only 10
    }
    _savePersistentFilters();
  }

  // Clear search history
  void clearSearchHistory() {
    searchHistory.clear();
    _savePersistentFilters();
  }

  // Use search history item
  void useSearchHistory(String query) {
    searchQuery.value = query;
    onSearchChanged(query);
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    applyFiltersAndSort();
  }

  void onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      addToSearchHistory(query);
    }
  }

  void toggleFilter(String filter) {
    if (activeFilters.contains(filter)) {
      activeFilters.remove(filter);
    } else {
      activeFilters.add(filter);
    }
    applyFiltersAndSort();
  }

  void removeFilter(String filter) {
    activeFilters.remove(filter);
    applyFiltersAndSort();
  }

  void clearAllFilters() {
    activeFilters.clear();
    searchQuery.value = '';
    filteredRequests.assignAll(allRequests);
    applyFiltersAndSort();
  }

  void applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(allRequests);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final searchLower = searchQuery.value.toLowerCase();
      filtered = filtered.where((request) {
        final url = (request["destinationUrl"] as String).toLowerCase();
        final domain = (request["domain"] as String).toLowerCase();
        final appName = (request["appName"] as String).toLowerCase();
        return url.contains(searchLower) ||
            domain.contains(searchLower) ||
            appName.contains(searchLower);
      }).toList();
    }

    // Apply domain blocklist
    if (blockedDomains.isNotEmpty) {
      filtered = filtered.where((request) {
        final domain = (request["domain"] as String).toLowerCase();
        return !blockedDomains.contains(domain);
      }).toList();
    }

    // Apply app filter
    if (selectedApps.isNotEmpty) {
      filtered = filtered.where((request) {
        final appPackage = request["appPackage"] as String;
        return selectedApps.contains(appPackage);
      }).toList();
    }

    // Apply protocol toggle
    filtered = filtered.where((request) {
      final protocol = (request["protocol"] as String).toUpperCase();
      if (protocol == 'HTTP' && !httpEnabled.value) return false;
      if (protocol == 'HTTPS' && !httpsEnabled.value) return false;
      return true;
    }).toList();

    // Apply method filters
    if (activeFilters.isNotEmpty) {
      filtered = filtered.where((request) {
        final method = request["method"] as String;
        final protocol = request["protocol"] as String;
        return activeFilters.contains(method) || activeFilters.contains(protocol);
      }).toList();
    }

    // Apply sorting
    switch (selectedSortOption.value) {
      case 'Newest':
        filtered.sort((a, b) => (b["timestamp"] as DateTime).compareTo(a["timestamp"] as DateTime));
        break;
      case 'Oldest':
        filtered.sort((a, b) => (a["timestamp"] as DateTime).compareTo(b["timestamp"] as DateTime));
        break;
      case 'Data Size':
        filtered.sort((a, b) {
          final aSize = _parseSize(a["responseSize"] as String);
          final bSize = _parseSize(b["responseSize"] as String);
          return bSize.compareTo(aSize);
        });
        break;
      case 'Response Time':
        filtered.sort((a, b) {
          final aTime = _parseTime(a["responseTime"] as String);
          final bTime = _parseTime(b["responseTime"] as String);
          return bTime.compareTo(aTime);
        });
        break;
    }

    filteredRequests.assignAll(filtered);
  }

  double _parseSize(String size) {
    final parts = size.split(' ');
    final value = double.tryParse(parts[0]) ?? 0;
    final unit = parts.length > 1 ? parts[1] : 'KB';
    return unit == 'MB' ? value * 1024 : value;
  }

  double _parseTime(String time) {
    return double.tryParse(time.replaceAll(' ms', '')) ?? 0;
  }
}
