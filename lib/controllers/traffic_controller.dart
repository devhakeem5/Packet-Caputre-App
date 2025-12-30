import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/captured_request.dart';
import '../core/utils/certificate_manager.dart';
import '../core/widgets/custom_buttom_bar.dart';
import 'capture_controller.dart';

class TrafficController extends GetxController with GetTickerProviderStateMixin {
  // Requests data
  RxList<CapturedRequest> requests = <CapturedRequest>[].obs;

  // Mock data for network requests
  RxList<Map<String, dynamic>> allRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> filteredRequests = <Map<String, dynamic>>[].obs;

  // Maximum requests to store in memory (prevent OOM on low-end devices)
  static const int MAX_REQUESTS = 1000;

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
  RxBool hideUnknownApps = false.obs;
  RxBool hideSystemApps = false.obs; // New: Hide system apps filter
  RxBool hideEncryptedTraffic = false.obs; // New: Encrypted traffic filter

  // Saved Requests (Persistent)
  RxList<Map<String, dynamic>> savedRequests = <Map<String, dynamic>>[].obs;
  final _storage = const FlutterSecureStorage();
  static const _savedRequestsKey = 'saved_requests_secure';

  // Tab controllers
  late TabController requestListTabController;

  // Bottom bar selection
  Rx<CustomBottomBarItem> selectedBottomBarItem = CustomBottomBarItem.dashboard.obs;

  // Event Channel
  static const eventChannel = EventChannel('com.example.packet_capture/events');

  final CertificateManager certificateManager = CertificateManager();
  RxBool isCaGenerated = false.obs;

  @override
  void onInit() {
    super.onInit();
    requestListTabController = TabController(length: 4, vsync: this);

    _loadPersistentFilters();
    _loadSavedRequests(); // Load securely saved requests
    // _loadRequestHistory(); // Disabled: Only loading explicitly saved requests now

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
    _checkCaStatus();
  }

  Future<void> _checkCaStatus() async {
    isCaGenerated.value = await certificateManager.caExists();
  }

  Future<void> saveRootCa() async {
    try {
      if (!isCaGenerated.value) {
        await certificateManager.exportCertificateToDownloads();
        isCaGenerated.value = true;
      }

      // Share/Save the certificate file
      await certificateManager.shareCertificate();
    } catch (e) {
      print("Error saving certificate: $e");
      Get.snackbar("Error", "Failed to save certificate: $e");
    }
  }

  Future<void> verifyRootCa() async {
    final verified = await certificateManager.verifyInstallation();
    if (verified) {
      Get.snackbar(
        "Verification",
        "Certificate is accessible. Please confirm it is installed in Settings > Encryption & Credentials.",
      );
    } else {
      Get.snackbar("Error", "Certificate file verification failed.");
    }
  }

  void _subscribeToNativeEvents() {
    eventChannel.receiveBroadcastStream().listen(
      _onEvent,
      onError: (error) {
        print("Flutter: Error receiving traffic event: $error");
      },
    );
  }

  // Load saved request history from SharedPreferences
  Future<void> _loadRequestHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('request_history');

      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        final savedRequests = decoded.cast<Map<String, dynamic>>().toList();

        // Restore saved requests (newest first)
        allRequests.addAll(savedRequests);
        print("Loaded ${savedRequests.length} saved requests from history");
        applyFiltersAndSort();
      }
    } catch (e) {
      print("Error loading request history: $e");
    }
  }

  // Save request history to SharedPreferences (keep last 100 requests)
  Future<void> _saveRequestHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save only last 100 requests to avoid growing storage
      final requestsToSave = allRequests.take(100).toList();
      final encoded = jsonEncode(requestsToSave);

      await prefs.setString('request_history', encoded);
    } catch (e) {
      print("Error saving request history: $e");
    }
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

        print(
          "Flutter: Parsed packet: ${request.protocol} ${request.method} -> ${request.url} ($direction, ${payloadSize}B)",
        );
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

        // 2. Filter ONLY pure handshake/ACK packets (no method, no URL)
        // Allow all HTTP/HTTPS proxy events even if they have 0 payload initially
        if (payloadSize <= 0 && request.method.isEmpty) {
          print("Flutter: Skipped event: empty handshake packet");
          return;
        }

        // 3. Filter pure connection setup events (SYN-only, etc.)
        // These are already filtered in native, but double-check
        if (request.method == "CONNECT" && payloadSize == 0) {
          print("Flutter: Skipped event: CONNECT tunnel establishment");
          return;
        }

        final totalSize = request.requestSize + request.responseSize;
        // Parse URL to extract IP and port information
        final uri = Uri.tryParse(request.url);
        String? destIp;
        int? destPort;

        if (uri != null) {
          destIp = uri.host;
          destPort = uri.hasPort ? uri.port : null;
        }

        final requestMap = {
          "id": request.id,
          "appName": request.appName ?? "Unknown",
          "appPackage": request.appPackage ?? "",
          "packageName": request.appPackage ?? "", // Same as appPackage for consistency
          "appIcon": "", // No icon for now, placeholder or fetch usage
          "semanticLabel": "App Icon",
          "url": request.url, // Changed from destinationUrl to url to match RequestDetailsScreen
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

          // Additional fields for Overview tab
          "appVersion": "N/A",
          "destinationIp": destIp ?? request.domain,
          "port": destPort,
          "protocolVersion": "N/A",
          "requestId": request.id,
          "connectionType": direction == "incoming" ? "Inbound" : "Outbound",
          "isEncrypted":
              request.protocol.toUpperCase().contains("HTTPS") ||
              request.protocol.toUpperCase().contains("TLS"),

          // Data transfer fields (convert from string to int)
          "bytesSent": request.requestSize,
          "bytesReceived": request.responseSize,

          // Headers tab fields
          "requestHeaders": request.headers,
          "responseHeaders": event['responseHeaders'] ?? {},

          // Response tab fields
          "responseBody": event['responseBody'] ?? "",
          "requestBody": event['requestBody'] ?? "",
          "contentType":
              (event['responseHeaders'] ?? {})['Content-Type'] ?? "application/octet-stream",

          // Timing tab fields
          "dnsLookupTime": 0,
          "connectionTime": 0,
          "sslHandshakeTime": 0,
          "requestSentTime": 0,
          "waitingTime": 0,
          "downloadTime": request.responseTime,
          "isDecrypted": request.isDecrypted, // Add decryption status
          "isSystemApp": request.isSystemApp,
        };

        allRequests.insert(0, requestMap);

        // Cleanup old requests if limit exceeded (FIFO - First In, First Out)
        if (allRequests.length > MAX_REQUESTS) {
          final removed = allRequests.length - MAX_REQUESTS;
          allRequests.removeRange(MAX_REQUESTS, allRequests.length);
          print("Memory cleanup: Removed $removed old requests (limit: $MAX_REQUESTS)");
        }

        print(
          "✓ Flutter: Displayed traffic event for ${request.appPackage} (${request.protocol} ${request.method}, ${totalSize}B)",
        );
        print("Total requests: ${allRequests.length}");
        print("═══════════════════════════════════════════════════════");
        applyFiltersAndSort();

        // Save history periodically (every 10 requests to avoid excessive I/O)
        if (allRequests.length % 10 == 0) {
          _saveRequestHistory();
        }
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
    hideUnknownApps.value = prefs.getBool('hide_unknown_apps') ?? false;
    hideSystemApps.value = prefs.getBool('hide_system_apps') ?? false;
    hideEncryptedTraffic.value = prefs.getBool('hide_encrypted_traffic') ?? false;
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
    await prefs.setBool('hide_unknown_apps', hideUnknownApps.value);
    await prefs.setBool('hide_system_apps', hideSystemApps.value);
    await prefs.setBool('hide_encrypted_traffic', hideEncryptedTraffic.value);
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

  // Toggle hide unknown apps
  void toggleHideUnknownApps() {
    hideUnknownApps.value = !hideUnknownApps.value;
    _savePersistentFilters();
    applyFiltersAndSort();
  }

  // Toggle encrypted traffic filter
  void toggleHideEncryptedTraffic() async {
    hideEncryptedTraffic.value = !hideEncryptedTraffic.value;
    _savePersistentFilters();
    applyFiltersAndSort();
  }

  // Toggle hide system apps
  void toggleHideSystemApps() async {
    hideSystemApps.value = !hideSystemApps.value;
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
        final url = (request["url"] as String).toLowerCase();
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

    // Apply unknown apps filter
    if (hideUnknownApps.value) {
      filtered = filtered.where((request) {
        final appName = request["appName"] as String?;
        final appPackage = request["appPackage"] as String?;
        // Keep only if we have valid app name (not Unknown) and package
        return appName != null &&
            appName != "Unknown" &&
            appName != "Unknown App" &&
            appPackage != null &&
            appPackage.isNotEmpty;
      }).toList();
    }

    // Apply Hide System Apps Filter
    if (hideSystemApps.value) {
      filtered = filtered.where((request) {
        final isSystem = request["isSystemApp"] as bool? ?? false;
        return !isSystem;
      }).toList();
    }

    // Apply Encrypted Traffic Filter
    // User wants: "Show All" or "Show Unencrypted Only"
    // "Show unencrypted only" means hideEncryptedTraffic = true
    if (hideEncryptedTraffic.value) {
      filtered = filtered.where((request) {
        final isDecrypted = request["isDecrypted"] as bool? ?? false;
        // If it's NOT decrypted (meaning it's encrypted/tunnelled), hide it.
        // So we only keep isDecrypted == true.
        if (!isDecrypted) {
          return false;
        }
        return true;
      }).toList();
    }

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

  // --- Saved Requests (Secure Storage) ---

  Future<void> _loadSavedRequests() async {
    try {
      final jsonStr = await _storage.read(key: _savedRequestsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final loaded = decoded.cast<Map<String, dynamic>>();
        savedRequests.assignAll(loaded);

        // Add saved requests to the main list so they are displayed
        allRequests.addAll(loaded);
        applyFiltersAndSort();
      }
    } catch (e) {
      print("Error loading saved requests: $e");
    }
  }

  Future<void> _persistSavedRequests() async {
    try {
      final jsonStr = jsonEncode(savedRequests);
      await _storage.write(key: _savedRequestsKey, value: jsonStr);
    } catch (e) {
      print("Error saving requests to secure storage: $e");
    }
  }

  void toggleSaveRequest(Map<String, dynamic> request) {
    // Check if already saved (by ID)
    final index = savedRequests.indexWhere((r) => r['id'] == request['id']);
    if (index >= 0) {
      // Already saved, so remove it
      savedRequests.removeAt(index);
      Get.snackbar('Removed', 'Request removed from Saved', duration: Duration(seconds: 1));
    } else {
      // Not saved, add it
      // Create a copy to ensure strictly encodable data
      final cleanRequest = Map<String, dynamic>.from(request);
      savedRequests.add(cleanRequest);
      Get.snackbar('Saved', 'Request saved securely', duration: Duration(seconds: 1));
    }
    _persistSavedRequests();
    applyFiltersAndSort(); // Re-apply to update UI if needed
  }

  bool isRequestSaved(Map<String, dynamic> request) {
    return savedRequests.any((r) => r['id'] == request['id']);
  }
}
