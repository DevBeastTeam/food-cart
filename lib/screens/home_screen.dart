import 'dart:async';
import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/daig_item.dart';
import '../models/food_item.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import '../widgets/daig_card.dart';
import '../widgets/promo_banner.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/shahi_dish_card.dart';
import 'admin_dashboard_screen.dart';
import 'all_places_foods_screen.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'restaurant_details_screen.dart';
import 'rider_dashboard_screen.dart';
import 'user_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final CartState cartState;
  final UserState userState;

  const HomeScreen({
    super.key,
    required this.cartState,
    required this.userState,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All';
  String _quickFilter = 'All'; // 'All', 'Top Rated', 'Fast Delivery', 'Free Delivery'
  String _selectedVendorId = 'all';
  String _selectedVendorName = 'All';
  String _selectedVendorLocation = 'All Locations';
  final TextEditingController _homeSearchController = TextEditingController();
  String _homeSearchQuery = '';
  Timer? _searchDebounce;
  bool _isSearching = false;
  List<FoodItem> _searchResults = [];
  List<DaigItem> _searchDaigResults = [];
  bool _isSearchFieldOpen = false;
  String _activeListingTab = 'restaurant'; // 'restaurant' or 'pakwan'
  int _restaurantPage = 1;
  int _pakwanPage = 1;
  static const int _itemsPerPage = 4;

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsScreen(
          restaurant: restaurant,
          cartState: widget.cartState,
        ),
      ),
    );
  }

  List<Restaurant> get _filteredRestaurants {
    return SampleData.restaurants.where((rest) {
      if (_selectedVendorId != 'all') {
        final matchesVendor = rest.id == _selectedVendorId ||
            rest.name.toLowerCase().trim() == _selectedVendorName.toLowerCase().trim() ||
            rest.address.toLowerCase().contains(_selectedVendorLocation.toLowerCase());
        if (!matchesVendor) return false;
      }

      if (_homeSearchQuery.isNotEmpty) {
        final query = _homeSearchQuery.toLowerCase();
        final matchName = rest.name.toLowerCase().contains(query);
        final matchCuisine = rest.cuisine.toLowerCase().contains(query);
        final matchDish = rest.menu.any((item) =>
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query));
        if (!matchName && !matchCuisine && !matchDish) return false;
      }

      if (_selectedCategory != 'All') {
        final cat = _selectedCategory.toLowerCase();
        final matchesCat = rest.categories.any((c) {
              final cl = c.toLowerCase();
              return cl == cat || cl.contains(cat) || cat.contains(cl);
            }) ||
            rest.cuisine.toLowerCase().contains(cat) ||
            rest.menu.any((m) {
              final mc = m.category.toLowerCase();
              final mn = m.name.toLowerCase();
              return mc == cat || mc.contains(cat) || cat.contains(mc) || mn.contains(cat);
            });
        if (!matchesCat) return false;
      }

      if (_quickFilter == 'Top Rated' && rest.rating < 4.7) return false;
      if (_quickFilter == 'Free Delivery' && rest.deliveryFee > 0) return false;
      if (_quickFilter == 'Fast Delivery') {
        final timeStr = rest.deliveryTime.split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
        final timeInt = int.tryParse(timeStr) ?? 30;
        if (timeInt > 25) return false;
      }

      return true;
    }).toList();
  }

  List<FoodItem> get _currentRestaurantDishes {
    List<FoodItem> list = List<FoodItem>.from(SampleData.allTrendingFoodItems);
    if (_selectedVendorId != 'all') {
      final vendorFiltered = list.where((d) =>
          d.subAdminId == _selectedVendorId ||
          d.restaurantId == _selectedVendorId ||
          d.locationAddress.toLowerCase().contains(_selectedVendorLocation.toLowerCase()) ||
          d.name.toLowerCase().contains(_selectedVendorName.toLowerCase())).toList();
      if (vendorFiltered.isNotEmpty) {
        list = vendorFiltered;
      }
    }
    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      list = list.where((d) =>
          d.category.toLowerCase().contains(cat) ||
          cat.contains(d.category.toLowerCase())).toList();
    }
    if (_quickFilter == 'Top Rated') {
      list = list.where((d) => d.rating >= 4.8).toList();
    } else if (_quickFilter == 'Fast Delivery') {
      list = list.where((d) => d.isPopular).toList();
    }
    return list;
  }

  List<DaigItem> get _currentPakwanDishes {
    List<DaigItem> list = List<DaigItem>.from(SampleData.daigDishes);
    if (_selectedVendorId != 'all') {
      final vendorDaigs = list.where((d) =>
          d.subAdminId == _selectedVendorId ||
          d.centerId == _selectedVendorId ||
          d.centerName.toLowerCase().contains(_selectedVendorName.toLowerCase()) ||
          d.location.toLowerCase().contains(_selectedVendorLocation.toLowerCase())).toList();
      if (vendorDaigs.isNotEmpty) {
        list = vendorDaigs;
      }
    }
    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      list = list.where((d) =>
          d.category.toLowerCase().contains(cat) ||
          cat.contains(d.category.toLowerCase())).toList();
    }
    if (_quickFilter == 'Top Rated') {
      list = list.where((d) => d.rating >= 4.8).toList();
    }
    return list;
  }

  String _resolveLocationHeaderTitle() {
    if (_selectedVendorId != 'all' && _selectedVendorName.isNotEmpty) {
      if (_selectedVendorLocation.isNotEmpty &&
          _selectedVendorLocation != 'All' &&
          _selectedVendorLocation != 'Central Delivery Hub') {
        return '$_selectedVendorName • $_selectedVendorLocation Food Items';
      }
      return '$_selectedVendorName Food Items';
    }
    return 'All Places Food Items';
  }

  void _onSearchChanged(String query) {
    setState(() {
      _homeSearchQuery = query;
    });

    _searchDebounce?.cancel();
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchDaigResults = [];
      });
      return;
    }

    // Immediate local match for zero perceived latency
    final localInitial = SampleData.restaurants
        .expand((r) => r.menu)
        .where((item) =>
            item.name.toLowerCase().contains(clean) ||
            item.description.toLowerCase().contains(clean) ||
            item.category.toLowerCase().contains(clean))
        .toSet()
        .toList();

    final localDaigs = SampleData.daigDishes
        .where((d) =>
            d.name.toLowerCase().contains(clean) ||
            d.urduName.contains(clean) ||
            d.description.toLowerCase().contains(clean))
        .toList();

    setState(() {
      _isSearching = true;
      _searchResults = localInitial;
      _searchDaigResults = localDaigs;
    });

    // Query backend dynamically with 300ms debounce
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final vendorParam = _selectedVendorId == 'all' ? null : _selectedVendorId;
      final backendResults = await ApiService.instance.searchFoodItems(query, subAdminId: vendorParam);
      final backendDaigs = await ApiService.instance.searchDaigItems(query, subAdminId: vendorParam);
      if (mounted && _homeSearchQuery.trim() == query.trim()) {
        setState(() {
          _searchResults = backendResults;
          _searchDaigResults = backendDaigs;
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _homeSearchController.dispose();
    super.dispose();
  }

  void _showVendorLocationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        bool isLoading = true;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            // Trigger shimmer loading completion after 350ms
            if (isLoading) {
              Future.delayed(const Duration(milliseconds: 350), () {
                if (sheetContext.mounted) {
                  setSheetState(() {
                    isLoading = false;
                  });
                }
              });
            }

            final List<Map<String, String>> vendors = [
              for (final r in SampleData.restaurants)
                {
                  'id': r.id,
                  'name': r.name,
                  'address': r.address,
                  'type': 'Restaurant',
                  'imageUrl': r.imageUrl,
                },
              for (final p in SampleData.pakwanCenters)
                {
                  'id': p.id,
                  'name': p.name,
                  'address': p.address,
                  'type': 'Pakwan Center',
                  'imageUrl': p.imageUrl,
                },
            ];

            final filtered = vendors.where((v) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return v['name']!.toLowerCase().contains(q) ||
                  v['address']!.toLowerCase().contains(q) ||
                  v['type']!.toLowerCase().contains(q);
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Location & Vendor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'لوکیشن یا وینڈر منتخب کریں',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Search Field with Shimmer feedback
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      autofocus: false,
                      onChanged: (val) {
                        setSheetState(() {
                          searchQuery = val.trim();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search restaurant, pakwan, or location address...',
                        hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        prefixIcon: Icon(Icons.search, color: AppTheme.primary, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Shimmer Effect Loading while fetching
                  if (isLoading) ...[
                    Expanded(
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (_, __) => _buildShimmerTile(),
                      ),
                    ),
                  ] else ...[
                    // Vendor List
                    Expanded(
                      child: ListView(
                        children: [
                          // 1. ALL OPTION (Top Priority)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _selectedVendorId == 'all'
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            tileColor: _selectedVendorId == 'all'
                                ? AppTheme.primaryLight.withAlpha(80)
                                : Colors.transparent,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _selectedVendorId == 'all' ? AppTheme.primary : AppTheme.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.public_rounded,
                                color: _selectedVendorId == 'all' ? Colors.white : AppTheme.primary,
                                size: 22,
                              ),
                            ),
                            title: const Row(
                              children: [
                                Text(
                                  'All Locations (تمام لوکیشنز)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'All Vendors',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Text(
                              'Show all food dishes, Shahi daigs & offers from every kitchen',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            trailing: _selectedVendorId == 'all'
                                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedVendorId = 'all';
                                _selectedVendorName = 'All';
                                _selectedVendorLocation = 'All Locations';
                                _restaurantPage = 1;
                                _pakwanPage = 1;
                              });
                              Navigator.pop(sheetContext);
                            },
                          ),

                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AppTheme.border),
                          const SizedBox(height: 8),

                          // 2. Individual Vendors / Restaurants
                          ...filtered.map((v) {
                            final isSel = _selectedVendorId == v['id'] ||
                                (_selectedVendorId != 'all' && _selectedVendorName == v['name']);
                            final isPakwan = v['type'] == 'Pakwan Center';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? AppTheme.primary : AppTheme.border.withAlpha(120),
                                ),
                                color: isSel ? AppTheme.primaryLight.withAlpha(50) : Colors.white,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    v['imageUrl']!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 44,
                                      height: 44,
                                      color: AppTheme.surfaceMuted,
                                      child: Icon(
                                        isPakwan ? Icons.soup_kitchen : Icons.restaurant,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        v['name']!,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w700,
                                          color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPakwan ? const Color(0xFFFEF3C7) : const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isPakwan ? 'Pakwan' : 'Restaurant',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: isPakwan ? const Color(0xFFB45309) : const Color(0xFF7E22CE),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        v['address']!,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isSel
                                    ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                                    : const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
                                onTap: () {
                                  setState(() {
                                    _selectedVendorId = v['id']!;
                                    _selectedVendorName = v['name']!;
                                    _selectedVendorLocation = v['address']!;
                                    _restaurantPage = 1;
                                    _pakwanPage = 1;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCart() {
    setState(() {
      _currentNavIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.cartState, widget.userState]),
      builder: (context, _) {
        if (widget.userState.isLoggedIn && widget.userState.currentRole == UserRole.admin) {
          return AdminDashboardScreen(
            userState: widget.userState,
            onSwitchToCustomer: () => widget.userState.setRole(UserRole.client),
          );
        }

        if (widget.userState.isLoggedIn && widget.userState.currentRole == UserRole.rider) {
          return RiderDashboardScreen(
            userState: widget.userState,
            onSwitchToCustomer: () => widget.userState.setRole(UserRole.client),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: _buildBody(),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
          floatingActionButton: widget.cartState.totalItemCount > 0 && _currentNavIndex != 1
              ? _buildFloatingCartButton()
              : null,
        );
      },
    );
  }

  Widget _buildFloatingCartButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: _openCart,
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: Badge(
          label: Text(
            '${widget.cartState.totalItemCount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          backgroundColor: Colors.white,
          textColor: AppTheme.primary,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
        ),
        label: Text(
          'View Cart • Rs. ${widget.cartState.subtotal.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return CartScreen(
          cartState: widget.cartState,
          userState: widget.userState,
          isEmbedded: true,
          onNavigateToOrders: () {
            setState(() {
              _currentNavIndex = 2;
            });
          },
          onStartShopping: () {
            setState(() {
              _currentNavIndex = 0;
            });
          },
        );
      case 2:
        return OrdersScreen(
          userState: widget.userState,
          cartState: widget.cartState,
          isEmbedded: true,
          onStartShopping: () {
            setState(() {
              _currentNavIndex = 0;
            });
          },
        );
      case 3:
        return UserDashboardScreen(
          userState: widget.userState,
          cartState: widget.cartState,
          isEmbedded: true,
        );
      default:
        return _buildHomeTab();
    }
  }

  // ===========================================================================
  // TAB 1: HOME TAB
  // ===========================================================================
  Widget _buildHomeTab() {
    final isLoggedIn = widget.userState.isLoggedIn;
    final user = widget.userState.user;
    final appContent = ApiService.instance.appContent;
    final appSettings = ApiService.instance.appSettings;
    final emergencyAlert = appSettings['emergencyAlert'] as Map<String, dynamic>?;
    final isEmergencyActive = emergencyAlert != null && emergencyAlert['enabled'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Announcement Banner if enabled by Admin
          if (isEmergencyActive) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emergencyAlert['message'] ?? 'Service alert',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Top Bar: Brand, Guest Indicator, Search Toggle & Login Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isSearchFieldOpen) ...[
                // Search Input Field in AppBar with ONLY Bottom Border and NO background or outline
                Expanded(
                  child: TextField(
                    controller: _homeSearchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search biryani, karahi, daig, dishes...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primary),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 20),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primary, width: 1.8),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close Icon Button on right side
                IconButton(
                  onPressed: () {
                    setState(() {
                      _homeSearchController.clear();
                      _onSearchChanged('');
                      _isSearchFieldOpen = false;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textPrimary),
                  tooltip: 'Close search',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ] else ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isLoggedIn) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appContent['heroTitle'] ?? 'Food Court',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: const Text(
                                'Guest (گیسٹ)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Browse food dishes, restaurants & Shahi Daigs',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          appContent['heroTitle'] ?? 'Food Court',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Welcome back, ${user?.name.split(' ').first ?? 'Foodie'}! 👋',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Search Icon Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSearchFieldOpen = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7.5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                if (isLoggedIn && user != null)
                  InkWell(
                    onTap: () => setState(() => _currentNavIndex = 3),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.name.split(' ').first,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            userState: widget.userState,
                            initialIsSignUp: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 15),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Location & Vendor Delivery Chip Dropdown
          InkWell(
            onTap: _showVendorLocationSelector,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 15, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Location: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _selectedVendorId == "all" ? "All" : _selectedVendorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),



          const SizedBox(height: 16),

          if (_homeSearchQuery.trim().isNotEmpty) ...[
            _buildSearchResultsSection(),
          ] else ...[
            // 1. PromoBanner / Carousel FIRST at the top
            if (appContent['showPromoBanner'] != false) ...[
              PromoBanner(
                selectedVendorId: _selectedVendorId,
                onOrderBanner: (banner) {
                  final linkCat = (banner['linkCategory'] ?? '').toString();
                  final title = (banner['title'] ?? '').toString().toLowerCase();
                  setState(() {
                    if (linkCat.contains('Daig') || title.contains('daig')) {
                      _activeListingTab = 'pakwan';
                    } else {
                      _activeListingTab = 'restaurant';
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
            ],

            // 2. Cupertino iOS Tab Bar (Restaurant vs Shahi Pakwan)
            _buildCupertinoCategoryTabBar(),

            const SizedBox(height: 18),

            // 3. Conditional Content based on Selected Tab
            if (_activeListingTab == 'restaurant') ...[
              // Restaurant Items Header with bouncing location pin, marquee title, and View All
              _BouncingMarqueeLocationHeader(
                text: _resolveLocationHeaderTitle(),
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllPlacesFoodsScreen(
                        isPakwan: false,
                        cartState: widget.cartState,
                        selectedVendorId: _selectedVendorId,
                        selectedVendorName: _selectedVendorName,
                        selectedVendorLocation: _selectedVendorLocation,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Single Row of Category Pills (Rectangular subcategory pill style, non-rounded)
              _buildCategoryPillsRow(isPakwan: false),

              const SizedBox(height: 14),

              // Category Menu Dishes
              _buildCategoryDishesSection(),
            ] else ...[
              // Pakwan Items Header with bouncing location pin, marquee title, and View All
              _BouncingMarqueeLocationHeader(
                text: _resolveLocationHeaderTitle(),
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllPlacesFoodsScreen(
                        isPakwan: true,
                        cartState: widget.cartState,
                        selectedVendorId: _selectedVendorId,
                        selectedVendorName: _selectedVendorName,
                        selectedVendorLocation: _selectedVendorLocation,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Single Row of Pakwan Category Pills
              _buildCategoryPillsRow(isPakwan: true),

              const SizedBox(height: 14),

              // Shahi Daigs & Pakwan Dishes Section
              _buildCategoryDishesSection(),
            ],

            const SizedBox(height: 20),
          ],

        ],
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    final query = _homeSearchQuery.trim();
    final clean = query.toLowerCase();

    // Filter matching daig items from backend search results or fallback
    final matchingDaigs = _searchDaigResults.isNotEmpty
        ? _searchDaigResults
        : SampleData.daigDishes
            .where((d) =>
                d.name.toLowerCase().contains(clean) ||
                d.urduName.contains(clean) ||
                d.category.toLowerCase().contains(clean))
            .toList();

    List<FoodItem> filteredResults = List.from(_searchResults);
    if (_quickFilter == 'Top Rated') {
      filteredResults = filteredResults.where((i) => i.rating >= 4.8).toList();
    } else if (_quickFilter == 'Fast Delivery') {
      filteredResults = filteredResults.where((i) => i.isPopular).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Search Results',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filteredResults.length} found',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      if (_isSearching) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dishes matching "$query"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _homeSearchController.clear();
                _onSearchChanged('');
                setState(() => _isSearchFieldOpen = false);
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Quick Filter Pills within search
        SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickFilterPill('All'),
              const SizedBox(width: 6),
              _buildQuickFilterPill('Top Rated', icon: Icons.star_rounded),
              const SizedBox(width: 6),
              _buildQuickFilterPill('Fast Delivery', icon: Icons.electric_bolt_rounded),
              const SizedBox(width: 6),
              _buildQuickFilterPill('Free Delivery', icon: Icons.delivery_dining_rounded),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (filteredResults.isEmpty && !_isSearching) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                Text(
                  'No food items match "$query"',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try searching for Biryani, Pulao, Nihari, Karahi, Haleem, or Naan',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    _homeSearchController.clear();
                    _onSearchChanged('');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View All Menu Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ] else ...[
          ...filteredResults.map(
            (dish) => ShahiDishCard(
              item: dish,
              cartState: widget.cartState,
            ),
          ),
        ],

        // Matching Daig items if any
        if (matchingDaigs.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.soup_kitchen_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Matching Daig Catering (${matchingDaigs.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...matchingDaigs.map(
            (daig) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DaigCard(
                daig: daig,
                cartState: widget.cartState,
              ),
            ),
          ),
        ],

        // Matching Restaurants if any
        if (_filteredRestaurants.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Matching Restaurants (${_filteredRestaurants.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._filteredRestaurants.map(
            (rest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RestaurantCard(
                restaurant: rest,
                onTap: () => _openRestaurant(rest),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickFilterPill(String filterName, {IconData? icon}) {
    final isSelected = _quickFilter == filterName;
    return InkWell(
      onTap: () {
        setState(() {
          _quickFilter = filterName;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : (filterName == 'Top Rated' ? const Color(0xFFF59E0B) : AppTheme.primary),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              filterName,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required ValueChanged<int> onPageChanged,
  }) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final startItem = (currentPage - 1) * _itemsPerPage + 1;
    final endItem = (currentPage * _itemsPerPage).clamp(1, totalItems);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          InkWell(
            onTap: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: currentPage > 1 ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentPage > 1 ? AppTheme.primary.withAlpha(100) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: currentPage > 1 ? AppTheme.primary : AppTheme.textLight,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: currentPage > 1 ? AppTheme.primary : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Page Indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Showing $startItem-$endItem of $totalItems',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Next button
          InkWell(
            onTap: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: currentPage < totalPages ? AppTheme.primary : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: currentPage < totalPages ? Colors.white : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: currentPage < totalPages ? Colors.white : AppTheme.textLight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDishesSection() {
    final isPakwan = _activeListingTab == 'pakwan';

    // 1. Restaurant flow
    if (!isPakwan) {
      final allDishes = _currentRestaurantDishes;
      final totalDishes = allDishes.length;
      final totalPages = (totalDishes / _itemsPerPage).ceil().clamp(1, 999);
      final currentPage = _restaurantPage.clamp(1, totalPages);
      final displayedDishes = allDishes.skip((currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP PAGINATION BAR
          _buildPaginationBar(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: totalDishes,
            onPageChanged: (newPage) => setState(() => _restaurantPage = newPage),
          ),

          const SizedBox(height: 4),

          if (displayedDishes.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.restaurant_outlined, size: 36, color: AppTheme.textLight),
                  SizedBox(height: 8),
                  Text(
                    'No restaurant dishes found for this selection',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...displayedDishes.map(
              (dish) => ShahiDishCard(
                item: dish,
                cartState: widget.cartState,
                isPakwan: false,
              ),
            ),
          ],

          // BOTTOM PAGINATION BAR
          _buildPaginationBar(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: totalDishes,
            onPageChanged: (newPage) => setState(() => _restaurantPage = newPage),
          ),
        ],
      );
    }

    // 2. Pakwan flow
    final allDaigs = _currentPakwanDishes;
    final totalDaigs = allDaigs.length;
    final totalPages = (totalDaigs / _itemsPerPage).ceil().clamp(1, 999);
    final currentPage = _pakwanPage.clamp(1, totalPages);
    final displayedDaigs = allDaigs.skip((currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TOP PAGINATION BAR
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalDaigs,
          onPageChanged: (newPage) => setState(() => _pakwanPage = newPage),
        ),

        const SizedBox(height: 4),

        if (displayedDaigs.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.soup_kitchen_outlined, size: 36, color: AppTheme.textLight),
                SizedBox(height: 8),
                Text(
                  'No pakwan degs found for this selection',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ] else ...[
          ...displayedDaigs.map(
            (daig) => ShahiDishCard(
              daig: daig,
              cartState: widget.cartState,
              isPakwan: true,
            ),
          ),
        ],

        // BOTTOM PAGINATION BAR
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalDaigs,
          onPageChanged: (newPage) => setState(() => _pakwanPage = newPage),
        ),
      ],
    );
  }

  // ===========================================================================
  // CUPERTINO iOS SEGMENTED TAB BAR (RESTAURANT & SHAHI PAKWAN)
  // ===========================================================================
  Widget _buildCupertinoCategoryTabBar() {
    final isRestaurant = _activeListingTab == 'restaurant';
    final isPakwan = _activeListingTab == 'pakwan';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0), // Prominent, clear Cupertino tabs tray
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          // 1. RESTAURANT TAB BUTTON
          Expanded(
            child: CupertinoAnimatedTabButton(
              isSelected: isRestaurant,
              title: 'Restaurant',
              icon: Icons.restaurant_rounded,
              imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&q=80',
              onTap: () {
                if (_activeListingTab != 'restaurant') {
                  setState(() {
                    _activeListingTab = 'restaurant';
                    _selectedCategory = 'All';
                    _restaurantPage = 1;
                  });
                }
              },
              selectedGradientColors: [
                Colors.black.withValues(alpha: 0.30),
                const Color(0xFF1E3A8A).withValues(alpha: 0.90), // Rich Navy Blue
                const Color(0xFF1E40AF).withValues(alpha: 0.92), // Deep Royal Blue
              ],
              borderGradientColors: const [
                Color(0xFF2563EB), // Vibrant Blue
                Color(0xFF0F172A), // Dark Navy
                Color(0xFF3B82F6), // Bright Blue
                Color(0xFF1E3A8A), // Deep Navy
                Color(0xFF2563EB), // Vibrant Blue
              ],
            ),
          ),

          const SizedBox(width: 6),

          // 2. SHAHI PAKWAN TAB BUTTON
          Expanded(
            child: CupertinoAnimatedTabButton(
              isSelected: isPakwan,
              title: 'Shahi Pakwan',
              icon: Icons.outdoor_grill_rounded,
              imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
              onTap: () {
                if (_activeListingTab != 'pakwan') {
                  setState(() {
                    _activeListingTab = 'pakwan';
                    _selectedCategory = 'All';
                    _pakwanPage = 1;
                  });
                }
              },
              selectedGradientColors: [
                Colors.black.withValues(alpha: 0.35),
                const Color(0xFFB45309).withValues(alpha: 0.88),
              ],
              borderGradientColors: const [
                Color(0xFFD97706),
                Color(0xFF451A03), // dark rich tone
                Color(0xFFF59E0B),
                Color(0xFF78350F), // dark rich tone
                Color(0xFFD97706),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPillsRow({required bool isPakwan}) {
    final liveCats = ApiService.instance.categories;
    List<Map<String, dynamic>> effectiveCats = [];

    if (liveCats.isNotEmpty) {
      effectiveCats = liveCats.where((c) {
        final t = (c['type'] ?? 'restaurant').toString().toLowerCase().trim();
        if (isPakwan) {
          return t == 'pakwan' || t == 'both';
        } else {
          return t == 'restaurant' || t == 'both';
        }
      }).map((c) => Map<String, dynamic>.from(c)).toList();
    }

    if (effectiveCats.isEmpty || (isPakwan && effectiveCats.length <= 1)) {
      if (isPakwan) {
        effectiveCats = [
          {'name': 'All', 'icon': '🍽️'},
          {'name': 'Biryani & Pulao', 'icon': '🍲'},
          {'name': 'Qorma & Karahi', 'icon': '🥘'},
          {'name': 'Haleem & Nihari', 'icon': '🥣'},
          {'name': 'Sweet & Desserts', 'icon': '🍨'},
          {'name': 'Shahi Daig Catering', 'icon': '👑'},
        ];
      } else {
        effectiveCats = [
          {'name': 'All', 'icon': '🍽️'},
          {'name': 'Biryani', 'icon': '🍚'},
          {'name': 'Pulao', 'icon': '🍲'},
          {'name': 'Karahi & Handi', 'icon': '🥘'},
          {'name': 'BBQ & Grills', 'icon': '🍢'},
          {'name': 'Fast Food', 'icon': '🍔'},
          {'name': 'Zarda & Meetha', 'icon': '🍮'},
        ];
      }
    }

    final hasAll = effectiveCats.any((c) => (c['name'] ?? '').toString().toLowerCase() == 'all');
    if (!hasAll) {
      effectiveCats.insert(0, {'name': 'All', 'icon': '🍽️'});
    }

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: effectiveCats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = effectiveCats[index];
          final name = (cat['name'] ?? '').toString();
          final icon = (cat['icon'] ?? '').toString();
          final isSelected = _selectedCategory == name;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = name;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon.isNotEmpty) ...[
                    Text(icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  // ===========================================================================
  // BOTTOM NAVIGATION BAR
  // ===========================================================================
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary,
      currentIndex: _currentNavIndex,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      onTap: (idx) {
        setState(() {
          _currentNavIndex = idx;
        });
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_filled, color: AppTheme.primary),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: widget.cartState.totalItemCount > 0,
            label: Text(
              '${widget.cartState.totalItemCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: widget.cartState.totalItemCount > 0,
            label: Text(
              '${widget.cartState.totalItemCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.shopping_bag, color: AppTheme.primary),
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: widget.userState.activeOrdersCount > 0,
            label: Text(
              '${widget.userState.activeOrdersCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.receipt_long_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: widget.userState.activeOrdersCount > 0,
            label: Text(
              '${widget.userState.activeOrdersCount}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orangeAccent,
            child: const Icon(Icons.receipt_long, color: AppTheme.primary),
          ),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person, color: AppTheme.primary),
          label: 'Account',
        ),
      ],
    );
  }
}

/// Animated Cupertino Tab Button with dynamic rotating dark gradient border
class CupertinoAnimatedTabButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String title;
  final IconData icon;
  final String imageUrl;
  final List<Color> selectedGradientColors;
  final List<Color> borderGradientColors;

  const CupertinoAnimatedTabButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.title,
    required this.icon,
    required this.imageUrl,
    required this.selectedGradientColors,
    required this.borderGradientColors,
  });

  @override
  State<CupertinoAnimatedTabButton> createState() => _CupertinoAnimatedTabButtonState();
}

class _CupertinoAnimatedTabButtonState extends State<CupertinoAnimatedTabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.isSelected) {
      _borderController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CupertinoAnimatedTabButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_borderController.isAnimating) {
      _borderController.repeat();
    } else if (!widget.isSelected && _borderController.isAnimating) {
      _borderController.stop();
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) {
          return Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: widget.isSelected
                  ? SweepGradient(
                      transform: GradientRotation(_borderController.value * 2 * 3.14159265),
                      colors: widget.borderGradientColors,
                    )
                  : null,
              border: widget.isSelected
                  ? null
                  : Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1.0),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.selectedGradientColors.first.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            padding: EdgeInsets.all(widget.isSelected ? 2.5 : 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.isSelected ? 12.5 : 14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.isSelected
                            ? widget.selectedGradientColors
                            : [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.black.withValues(alpha: 0.88),
                              ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            size: 16,
                            color: widget.isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ShimmerTabText(
                            text: widget.title,
                            isSelected: widget.isSelected,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w700,
                              color: widget.isSelected ? Colors.white : Colors.white70,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer text sweep effect applied strictly to the selected tab text
class ShimmerTabText extends StatefulWidget {
  final String text;
  final bool isSelected;
  final TextStyle style;

  const ShimmerTabText({
    super.key,
    required this.text,
    required this.isSelected,
    required this.style,
  });

  @override
  State<ShimmerTabText> createState() => _ShimmerTabTextState();
}

class _ShimmerTabTextState extends State<ShimmerTabText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.isSelected) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ShimmerTabText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSelected && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSelected) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final val = _controller.value;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (val - 0.35).clamp(0.0, 1.0),
                val.clamp(0.0, 1.0),
                (val + 0.35).clamp(0.0, 1.0),
              ],
              colors: const [
                Colors.white,
                Color(0xFFFFD54F),
                Colors.white,
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

/// Header with subtle bouncing location pin, auto-scrolling marquee text in grey, and View All button
class _BouncingMarqueeLocationHeader extends StatefulWidget {
  final String text;
  final VoidCallback onViewAll;

  const _BouncingMarqueeLocationHeader({
    required this.text,
    required this.onViewAll,
  });

  @override
  State<_BouncingMarqueeLocationHeader> createState() => _BouncingMarqueeLocationHeaderState();
}

class _BouncingMarqueeLocationHeaderState extends State<_BouncingMarqueeLocationHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOutSine,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startMarqueeLoop();
      }
    });
  }

  Future<void> _startMarqueeLoop() async {
    while (mounted && !_isDisposed) {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted || !_scrollController.hasClients || _isDisposed) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 2) {
        final durationMs = (maxExtent * 45).toInt().clamp(2000, 7500);
        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted || !_scrollController.hasClients || _isDisposed) return;
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant _BouncingMarqueeLocationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startMarqueeLoop();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Subtle Bouncing Location Pin
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -3.5 * _bounceAnimation.value),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 15,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 2. Smaller Grey Marquee Text
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B), // elegant slate grey
                letterSpacing: 0.15,
              ),
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 3. View All Button
        InkWell(
          onTap: widget.onViewAll,
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10.5,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
