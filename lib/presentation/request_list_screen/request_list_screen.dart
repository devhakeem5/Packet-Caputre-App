import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_buttom_bar.dart';
import '../../core/widgets/custom_icon_widget.dart';
import './widgets/active_filter_bar_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chip_widget.dart';
import './widgets/request_card_widget.dart';
import './widgets/sort_bottom_sheet_widget.dart';
import './widgets/domain_blocklist_widget.dart';
import './widgets/app_filter_widget.dart';
import './widgets/search_history_widget.dart';

/// Request List Screen - Comprehensive view of captured network requests
/// with advanced filtering, search, and sorting capabilities
class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen>
    with TickerProviderStateMixin {
  // Tab controller for request categories
  late TabController _tabController;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  // Active filters
  Set<String> _activeFilters = {};
  String _selectedSortOption = 'Newest';

  // Persistent filters
  Set<String> _blockedDomains = {};
  Set<String> _selectedApps = {};
  List<String> _searchHistory = [];
  bool _httpEnabled = true;
  bool _httpsEnabled = true;

  // Mock data for network requests
  final List<Map<String, dynamic>> _allRequests = [
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
      "headers": {
        "Content-Type": "application/json",
        "User-Agent": "Chrome/120.0.0.0",
      },
    },
    {
      "id": "req_002",
      "appName": "Instagram",
      "appPackage": "com.instagram.android",
      "appIcon": "https://images.unsplash.com/photo-1666408738188-212c470d08b0",
      "semanticLabel":
          "Instagram app icon with gradient colors from purple to orange",
      "destinationUrl": "https://i.instagram.com/api/v1/feed/timeline",
      "domain": "i.instagram.com",
      "method": "POST",
      "protocol": "HTTPS",
      "statusCode": 200,
      "timestamp": DateTime.now().subtract(const Duration(minutes: 12)),
      "requestSize": "5.2 KB",
      "responseSize": "128.5 KB",
      "responseTime": "892 ms",
      "headers": {
        "Content-Type": "application/json",
        "Authorization": "Bearer token_hidden",
      },
    },
    {
      "id": "req_003",
      "appName": "WhatsApp",
      "appPackage": "com.whatsapp",
      "appIcon":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1b3def8dd-1764662218645.png",
      "semanticLabel":
          "WhatsApp messenger icon with green background and white phone symbol",
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
      "semanticLabel":
          "YouTube app icon with red play button on white background",
      "destinationUrl": "https://www.youtube.com/youtubei/v1/player",
      "domain": "www.youtube.com",
      "method": "POST",
      "protocol": "HTTPS",
      "statusCode": 200,
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "requestSize": "8.7 KB",
      "responseSize": "256.3 KB",
      "responseTime": "1245 ms",
      "headers": {
        "Content-Type": "application/json",
        "X-YouTube-Client-Name": "1",
      },
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
      "headers": {
        "Content-Type": "application/json",
        "Authorization": "Bearer token_hidden",
      },
    },
    {
      "id": "req_006",
      "appName": "Spotify",
      "appPackage": "com.spotify.music",
      "appIcon":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1d71ebfa2-1764751041051.png",
      "semanticLabel":
          "Spotify app icon with green background and black circular logo",
      "destinationUrl": "https://api.spotify.com/v1/me/player",
      "domain": "api.spotify.com",
      "method": "GET",
      "protocol": "HTTPS",
      "statusCode": 200,
      "timestamp": DateTime.now().subtract(const Duration(hours: 4)),
      "requestSize": "1.8 KB",
      "responseSize": "12.4 KB",
      "responseTime": "234 ms",
      "headers": {
        "Content-Type": "application/json",
        "Authorization": "Bearer token_hidden",
      },
    },
    {
      "id": "req_007",
      "appName": "Twitter",
      "appPackage": "com.twitter.android",
      "appIcon": "https://images.unsplash.com/photo-1667235326880-324e1a51d40b",
      "semanticLabel":
          "Twitter app icon with blue bird logo on white background",
      "destinationUrl": "https://api.twitter.com/2/timeline/home.json",
      "domain": "api.twitter.com",
      "method": "GET",
      "protocol": "HTTPS",
      "statusCode": 200,
      "timestamp": DateTime.now().subtract(const Duration(hours: 5)),
      "requestSize": "2.9 KB",
      "responseSize": "89.7 KB",
      "responseTime": "678 ms",
      "headers": {
        "Content-Type": "application/json",
        "Authorization": "Bearer token_hidden",
      },
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
      "headers": {
        "Content-Type": "application/json",
        "Cookie": "session_hidden",
      },
    },
  ];

  // Filtered requests based on search and filters
  List<Map<String, dynamic>> _filteredRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filteredRequests = List.from(_allRequests);
    _searchFocusNode.addListener(_onSearchFocusChange);
    _loadPersistentFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  // Load persistent filters from storage
  Future<void> _loadPersistentFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockedDomains = (prefs.getStringList('blocked_domains') ?? []).toSet();
      _selectedApps = (prefs.getStringList('selected_apps') ?? []).toSet();
      _searchHistory = prefs.getStringList('search_history') ?? [];
      _httpEnabled = prefs.getBool('http_enabled') ?? true;
      _httpsEnabled = prefs.getBool('https_enabled') ?? true;
      _applyFiltersAndSort();
    });
  }

  // Save persistent filters to storage
  Future<void> _savePersistentFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_domains', _blockedDomains.toList());
    await prefs.setStringList('selected_apps', _selectedApps.toList());
    await prefs.setStringList('search_history', _searchHistory);
    await prefs.setBool('http_enabled', _httpEnabled);
    await prefs.setBool('https_enabled', _httpsEnabled);
  }

  // Add domain to blocklist
  void _addBlockedDomain(String domain) {
    setState(() {
      _blockedDomains.add(domain.toLowerCase());
      _savePersistentFilters();
      _applyFiltersAndSort();
    });
  }

  // Remove domain from blocklist
  void _removeBlockedDomain(String domain) {
    setState(() {
      _blockedDomains.remove(domain);
      _savePersistentFilters();
      _applyFiltersAndSort();
    });
  }

  // Toggle app filter
  void _toggleAppFilter(String appPackage) {
    setState(() {
      if (_selectedApps.contains(appPackage)) {
        _selectedApps.remove(appPackage);
      } else {
        _selectedApps.add(appPackage);
      }
      _savePersistentFilters();
      _applyFiltersAndSort();
    });
  }

  // Toggle protocol filters
  void _toggleProtocol(String protocol) {
    setState(() {
      if (protocol == 'HTTP') {
        _httpEnabled = !_httpEnabled;
      } else if (protocol == 'HTTPS') {
        _httpsEnabled = !_httpsEnabled;
      }
      _savePersistentFilters();
      _applyFiltersAndSort();
    });
  }

  // Add search to history
  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;
    setState(() {
      _searchHistory.remove(query); // Remove if exists
      _searchHistory.insert(0, query); // Add to beginning
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10); // Keep only 10
      }
      _savePersistentFilters();
    });
  }

  // Clear search history
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
      _savePersistentFilters();
    });
  }

  // Use search history item
  void _useSearchHistory(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    _searchFocusNode.unfocus();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRequests = List.from(_allRequests);
      } else {
        _filteredRequests = _allRequests.where((request) {
          final url = (request["destinationUrl"] as String).toLowerCase();
          final domain = (request["domain"] as String).toLowerCase();
          final appName = (request["appName"] as String).toLowerCase();
          final searchLower = query.toLowerCase();
          return url.contains(searchLower) ||
              domain.contains(searchLower) ||
              appName.contains(searchLower);
        }).toList();
      }
      _applyFiltersAndSort();
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      _addToSearchHistory(query);
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
      _applyFiltersAndSort();
    });
  }

  void _removeFilter(String filter) {
    setState(() {
      _activeFilters.remove(filter);
      _applyFiltersAndSort();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
      _searchController.clear();
      _filteredRequests = List.from(_allRequests);
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allRequests);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
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
    if (_blockedDomains.isNotEmpty) {
      filtered = filtered.where((request) {
        final domain = (request["domain"] as String).toLowerCase();
        return !_blockedDomains.contains(domain);
      }).toList();
    }

    // Apply app filter
    if (_selectedApps.isNotEmpty) {
      filtered = filtered.where((request) {
        final appPackage = request["appPackage"] as String;
        return _selectedApps.contains(appPackage);
      }).toList();
    }

    // Apply protocol toggle
    filtered = filtered.where((request) {
      final protocol = (request["protocol"] as String).toUpperCase();
      if (protocol == 'HTTP' && !_httpEnabled) return false;
      if (protocol == 'HTTPS' && !_httpsEnabled) return false;
      return true;
    }).toList();

    // Apply method filters
    if (_activeFilters.isNotEmpty) {
      filtered = filtered.where((request) {
        final method = request["method"] as String;
        final protocol = request["protocol"] as String;
        return _activeFilters.contains(method) ||
            _activeFilters.contains(protocol);
      }).toList();
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'Newest':
        filtered.sort(
          (a, b) => (b["timestamp"] as DateTime).compareTo(
            a["timestamp"] as DateTime,
          ),
        );
        break;
      case 'Oldest':
        filtered.sort(
          (a, b) => (a["timestamp"] as DateTime).compareTo(
            b["timestamp"] as DateTime,
          ),
        );
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

    setState(() {
      _filteredRequests = filtered;
    });
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheetWidget(
        selectedOption: _selectedSortOption,
        onOptionSelected: (option) {
          setState(() {
            _selectedSortOption = option;
            _applyFiltersAndSort();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.symmetric(vertical: 1.h),
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Advanced Filters',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                // Filter sections
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    children: [
                      // Protocol toggle
                      _buildProtocolToggleSection(),
                      SizedBox(height: 2.h),
                      // App filter
                      AppFilterWidget(
                        selectedApps: _selectedApps,
                        allRequests: _allRequests,
                        onToggleApp: _toggleAppFilter,
                      ),
                      SizedBox(height: 2.h),
                      // Domain blocklist
                      DomainBlocklistWidget(
                        blockedDomains: _blockedDomains,
                        allRequests: _allRequests,
                        onAddDomain: _addBlockedDomain,
                        onRemoveDomain: _removeBlockedDomain,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProtocolToggleSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protocol Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: FilterChip(
                label: const Text('HTTP'),
                selected: _httpEnabled,
                onSelected: (_) => _toggleProtocol('HTTP'),
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.2,
                ),
                checkmarkColor: theme.colorScheme.secondary,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: _httpEnabled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface,
                  fontWeight: _httpEnabled ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: _httpEnabled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: _httpEnabled ? 2 : 1,
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: FilterChip(
                label: const Text('HTTPS'),
                selected: _httpsEnabled,
                onSelected: (_) => _toggleProtocol('HTTPS'),
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.2,
                ),
                checkmarkColor: theme.colorScheme.secondary,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: _httpsEnabled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface,
                  fontWeight: _httpsEnabled ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: _httpsEnabled
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: _httpsEnabled ? 2 : 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _filteredRequests = List.from(_allRequests);
      _applyFiltersAndSort();
    });
  }

  void _onRequestTap(Map<String, dynamic> request) {
    Navigator.pushNamed(context, '/request-details-screen', arguments: request);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Network Activity',
        variant: CustomAppBarVariant.standard,
        actions: [
          // Advanced filters badge
          Stack(
            children: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'tune',
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: _showAdvancedFilters,
                tooltip: 'Advanced filters',
              ),
              if (_blockedDomains.isNotEmpty ||
                  _selectedApps.isNotEmpty ||
                  !_httpEnabled ||
                  !_httpsEnabled)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showSortOptions,
            tooltip: 'Sort options',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              // Show more options menu
            },
            tooltip: 'More options',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with history
          _buildSearchBar(theme),

          // Search history
          if (_isSearchFocused && _searchHistory.isNotEmpty)
            SearchHistoryWidget(
              searchHistory: _searchHistory,
              onSelectHistory: _useSearchHistory,
              onClearHistory: _clearSearchHistory,
            ),

          // Filter chips
          FilterChipWidget(
            activeFilters: _activeFilters,
            onFilterToggle: _toggleFilter,
          ),

          // Active filters bar
          _activeFilters.isNotEmpty
              ? ActiveFilterBarWidget(
                  activeFilters: _activeFilters,
                  onRemoveFilter: _removeFilter,
                  onClearAll: _clearAllFilters,
                )
              : const SizedBox.shrink(),

          // Tab bar
          _buildTabBar(theme),

          // Request list
          Expanded(
            child: _filteredRequests.isEmpty
                ? EmptyStateWidget(
                    onActivateMonitoring: () {
                      Navigator.pushNamed(context, '/main-dashboard-screen');
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      itemCount: _filteredRequests.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final request = _filteredRequests[index];
                        return RequestCardWidget(
                          request: request,
                          onTap: () => _onRequestTap(request),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedItem: CustomBottomBarItem.requests,
        onItemSelected: (item) {
          // Navigation handled by CustomBottomBar
        },
      ),
      floatingActionButton: _filteredRequests.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showSortOptions,
              child: CustomIconWidget(
                iconName: 'sort',
                color: theme.colorScheme.onSecondary,
                size: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isSearchFocused
              ? theme.colorScheme.secondary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
          width: _isSearchFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        decoration: InputDecoration(
          hintText: 'Search requests, domains, IPs...',
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'search',
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: CustomIconWidget(
                    iconName: 'clear',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.secondary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.secondary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'HTTP'),
          Tab(text: 'HTTPS'),
          Tab(text: 'WebSocket'),
        ],
      ),
    );
  }
}
