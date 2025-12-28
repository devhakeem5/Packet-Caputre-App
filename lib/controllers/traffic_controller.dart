import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/captured_request.dart';
import '../core/widgets/custom_buttom_bar.dart';
import 'capture_controller.dart';

class TrafficController extends GetxController with GetTickerProviderStateMixin {
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

  // Event Channel
  static const eventChannel = EventChannel('com.example.packet_capture/events');

  @override
  void onInit() {
    super.onInit();
    requestListTabController = TabController(length: 4, vsync: this);
    tabController = TabController(length: 4, vsync: this);

    // Load selected apps from CaptureController
    try {
      final captureController = Get.find<CaptureController>();
      selectedApps.assignAll(captureController.selectedApps);
      print("TrafficController: Loaded ${selectedApps.length} selected apps");
    } catch (e) {
      print("TrafficController: CaptureController not found, starting fresh");
    }

    // Subscribe to native stream
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);

    filteredRequests.assignAll(allRequests); // Initially empty
    _loadPersistentFilters();
  }

  void _onEvent(dynamic event) {
    print("═══════════════════════════════════════════════════════");
    print("Flutter: Received traffic event from native");
    print("Event type: ${event.runtimeType}");
    if (event is Map) {
      print("Event keys: ${event.keys.toList()}");
    }
    
    if (event is Map) {
      try {
        final request = CapturedRequest.fromJson(event);
        final direction = event['direction'] as String? ?? "outgoing";
        final payloadSize = event['payloadSize'] as int? ?? event['size'] as int? ?? 0;
        
        print("Flutter: Parsed packet: ${request.protocol} ${request.method} -> ${request.url} (${direction}, ${payloadSize}B)");
        print("App: ${request.appPackage ?? 'unknown'} (${request.appName ?? 'Unknown App'})");

        // 1. Filter based on selected apps (if any are selected)
        // If apps are selected, only show traffic from those apps
        // If no apps are selected, show all traffic (even without package name)
        if (selectedApps.isNotEmpty) {
          // If apps are selected, we need package name to filter
          if (request.appPackage == null || request.appPackage!.isEmpty) {
            print("Flutter: Skipped event: no app package (apps are selected)");
            return;
          }
          if (!selectedApps.contains(request.appPackage)) {
            print("Flutter: Skipped event: app ${request.appPackage} not in selected apps");
            return;
          }
        } else {
          // If no apps are selected, show all traffic including unknown apps
          // But still prefer to have package name for better display
          if (request.appPackage == null || request.appPackage!.isEmpty) {
            // Use a default name for unknown apps
            print("Flutter: Event without package name (showing as Unknown)");
          }
        }

        // 2. Filter empty payload (Keep-alives/ACKs without data, tunnel-only events)
        if (payloadSize <= 0) {
          print("Flutter: Skipped event: empty payload (tunnel-only/handshake)");
          return;
        }

        // 3. Filter pure connection setup events (SYN-only, etc.)
        // These are already filtered in native, but double-check
        if (request.method == "CONNECT" && payloadSize == 0) {
          print("Flutter: Skipped event: CONNECT tunnel establishment");
          return;
        }

        final totalSize = request.requestSize + request.responseSize;
        final requestMap = {
          "id": request.id,
          "appName": request.appName ?? "Unknown",
          "appPackage": request.appPackage ?? "",
          "appIcon": "", // No icon for now, placeholder or fetch usage
          "semanticLabel": "App Icon",
          "destinationUrl": request.url,
          "domain": request.domain,
          "method": request.method,
          "protocol": request.protocol,
          "statusCode": request.statusCode,
          "timestamp": request.timestamp,
          "requestSize": request.requestSize > 0 ? "${request.requestSize} B" : "0 B",
          "responseSize": request.responseSize > 0 ? "${request.responseSize} B" : "0 B",
          "responseTime": "${request.responseTime} ms",
          "headers": request.headers,
          "direction": direction,
        };

        allRequests.insert(0, requestMap);
        print("✓ Flutter: Displayed traffic event for ${request.appPackage} (${request.protocol} ${request.method}, ${totalSize}B)");
        print("Total requests: ${allRequests.length}");
        print("═══════════════════════════════════════════════════════");
        applyFiltersAndSort();
      } catch (e, stackTrace) {
        print("Flutter: Error parsing event: $e");
        print("Flutter: Stack trace: $stackTrace");
      }
    } else {
      print("Flutter: Received non-map event: ${event.runtimeType}");
    }
  }

  void _onError(Object error) {
    print("EventChannel Error: $error");
  }

  @override
  void onClose() {
    tabController.dispose();
    requestListTabController.dispose();
    super.onClose();
  }

  // Loaded persistent filters from storage
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
