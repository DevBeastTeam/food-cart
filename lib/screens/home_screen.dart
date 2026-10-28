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
import '../widgets/category_chip.dart';
import '../widgets/custom_image.dart';
import '../widgets/daig_card.dart';
import '../widgets/promo_banner.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/shahi_dish_card.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'pakwan_centers_screen.dart';
import 'restaurant_details_screen.dart';
import 'restaurants_screen.dart';
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
  bool _showAllDaigs = false;
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

              // Search Icon Button (Turns into Cross 'X' Button when Search is Open)
              InkWell(
                onTap: () {
                  setState(() {
                    _isSearchFieldOpen = !_isSearchFieldOpen;
                    if (!_isSearchFieldOpen) {
                      _homeSearchController.clear();
                      _onSearchChanged('');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: _isSearchFieldOpen ? const Color(0xFFDC2626) : AppTheme.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isSearchFieldOpen ? const Color(0xFFDC2626) : AppTheme.border,
                    ),
                  ),
                  child: Icon(
                    _isSearchFieldOpen ? Icons.close_rounded : Icons.search_rounded,
                    size: 19,
                    color: _isSearchFieldOpen ? Colors.white : AppTheme.textPrimary,
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
                  const Text(
                    'Deliver to: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Location: ${_selectedVendorId == "all" ? "All" : _selectedVendorName}',
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

          // 2. Expandable Real-Time Live Search Bar
          if (_isSearchFieldOpen || _homeSearchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _homeSearchController,
                autofocus: _isSearchFieldOpen && _homeSearchQuery.isEmpty,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Pulao, Biryani, Mutton, Beef, Karahi, Daig...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textPrimary),
                    tooltip: 'Close search',
                    onPressed: () {
                      setState(() {
                        _homeSearchController.clear();
                        _onSearchChanged('');
                        _isSearchFieldOpen = false;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (_homeSearchQuery.trim().isNotEmpty) ...[
            _buildSearchResultsSection(),
          ] else ...[
            // 3. TWO PRIMARY MAIN FEATURE CARDS (Restaurants & Pakwan Centers)
            _buildMainFeatureSelectionCards(),

            const SizedBox(height: 16),

            if (appContent['showPromoBanner'] != false) ...[
              PromoBanner(
                selectedVendorId: _selectedVendorId,
                onOrderNow: () {
                  setState(() {
                    _selectedCategory = 'Biryani';
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // 4. Cuisines for you (Horizontal Carousel)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appContent['cuisinesSectionTitle'] ?? 'Cuisines for you',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_selectedCategory != 'All')
                  InkWell(
                    onTap: () => setState(() => _selectedCategory = 'All'),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: SampleData.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = SampleData.categories[index];
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as String;
                  return CategoryChip(
                    label: name,
                    icon: icon,
                    isSelected: _selectedCategory == name,
                    onTap: () {
                      setState(() {
                        _selectedCategory = name;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 5. Quick Filter Pills (Horizontal)
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

            const SizedBox(height: 20),

            // 6. Shahi Daig Catering Spotlight (Pakwan Center)
            _buildDaigSpotlightCard(),

            const SizedBox(height: 22),

            // 7. Top Restaurants Section
            _buildRestaurantsSection(),

            const SizedBox(height: 24),

            // 8. Category Menu Dishes (Shahi Daig Design)
            _buildCategoryDishesSection(),

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

  Widget _buildListingTabSwitcher() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // 1. Restaurant Tab
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeListingTab = 'restaurant';
                  _restaurantPage = 1;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeListingTab == 'restaurant' ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeListingTab == 'restaurant'
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(70),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_rounded,
                      size: 16,
                      color: _activeListingTab == 'restaurant' ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Restaurants (ریسٹورنٹ)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _activeListingTab == 'restaurant' ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 2. Pakwan & Deg Tab
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeListingTab = 'pakwan';
                  _pakwanPage = 1;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeListingTab == 'pakwan' ? const Color(0xFFD97706) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeListingTab == 'pakwan'
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD97706).withAlpha(70),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.soup_kitchen_rounded,
                      size: 16,
                      color: _activeListingTab == 'pakwan' ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shahi Pakwan (شاہی پکوان)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _activeListingTab == 'pakwan' ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

      final String title = _selectedVendorId != 'all'
          ? '🍽️ $_selectedVendorName Restaurant Dishes'
          : (_selectedCategory == 'All'
              ? '🍽️ Restaurant Dishes (تمام ریسٹورنٹ پکوان)'
              : '🍽️ $_selectedCategory Dishes');
      final String subtitle = _selectedVendorId != 'all'
          ? 'Fresh restaurant dishes from $_selectedVendorLocation'
          : 'Live menu dishes from all partnered vendors & kitchens';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListingTabSwitcher(),

          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalDishes Dishes',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),

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

    final String title = _selectedVendorId != 'all'
        ? '🍲 $_selectedVendorName Shahi Degs'
        : (_selectedCategory == 'All'
            ? '🍲 Shahi Pakwan & Degs (شاہی دیگیں)'
            : '🍲 $_selectedCategory Pakwan Degs');
    final String subtitle = _selectedVendorId != 'all'
        ? 'Directly from $_selectedVendorLocation'
        : 'Authentic cauldrons & catering prepared by expert ustaads';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListingTabSwitcher(),

        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalDaigs Degs',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),

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
            (daig) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DaigCard(
                daig: daig,
                cartState: widget.cartState,
              ),
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
  // 2 MAIN FEATURE SELECTION CARDS (RESTAURANTS & PAKWAN CENTERS)
  // ===========================================================================
  Widget _buildMainFeatureSelectionCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 650;
        final cardHeight = isDesktop ? 165.0 : 152.0;

        return Row(
          children: [
            // 1. RESTAURANTS CARD
            Expanded(
              child: _buildFeatureCard(
                title: 'Restaurants',
                subtitle: 'Fast Food • Pizza • Burgers',
                badgeText: 'RESTAURANTS',
                badgeIcon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFFF4B3A),
                glowColor: const Color(0xFFFF4B3A),
                borderColor: const Color(0xFFFF4B3A).withAlpha(120),
                icon: Icons.storefront_rounded,
                imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&q=80',
                buttonText: 'Order Food',
                height: cardHeight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RestaurantsScreen(cartState: widget.cartState),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // 2. PAKWAN CENTERS CARD
            Expanded(
              child: _buildFeatureCard(
                title: 'Pakwan Centers',
                subtitle: 'Shahi Degs • Catering',
                badgeText: 'PAKWAN & DEGS',
                badgeIcon: Icons.workspace_premium_rounded,
                accentColor: const Color(0xFFD97706),
                glowColor: const Color(0xFFF59E0B),
                borderColor: const Color(0xFFF59E0B).withAlpha(140),
                icon: Icons.soup_kitchen_rounded,
                imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&q=80',
                buttonText: 'Book Daig',
                height: cardHeight,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PakwanCentersScreen(cartState: widget.cartState),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData badgeIcon,
    required Color accentColor,
    required Color glowColor,
    required Color borderColor,
    required IconData icon,
    required String imageUrl,
    required String buttonText,
    required double height,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glowColor.withAlpha(50),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background appetizing image (clearly visible)
              CustomImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fallbackIcon: icon,
              ),

              // Multi-stop clean gradient: clear on top for delicious imagery, dark at bottom for contrast
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.black.withAlpha(60),
                      Colors.black.withAlpha(195),
                      Colors.black.withAlpha(235),
                    ],
                    stops: const [0.0, 0.40, 0.72, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Content overlay
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: White Frosted Circle Icon + Glowing Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: accentColor, size: 17),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withAlpha(110),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, color: Colors.white, size: 10),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    badgeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom info: Title, Subtitle, CTA Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withAlpha(90),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaigSpotlightCard() {
    List<DaigItem> allDaigs = List<DaigItem>.from(SampleData.daigDishes);
    if (_selectedVendorId != 'all') {
      final vendorDaigs = allDaigs.where((d) =>
          d.subAdminId == _selectedVendorId ||
          d.centerId == _selectedVendorId ||
          d.centerName.toLowerCase().contains(_selectedVendorName.toLowerCase()) ||
          d.location.toLowerCase().contains(_selectedVendorLocation.toLowerCase())).toList();
      if (vendorDaigs.isNotEmpty) {
        allDaigs = vendorDaigs;
      }
    }
    final displayedDaigs = _showAllDaigs ? allDaigs : allDaigs.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFFBBF24), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApiService.instance.appContent['daigSpotlightTitle'] ?? '🍲 Pakwan Center & Shahi Daig Catering',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ApiService.instance.appContent['daigSpotlightSubtitle'] ?? 'Sealed hot cauldrons for Dawats, Weddings & Niyaz (${allDaigs.length} Degs available)',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (allDaigs.length > 2)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllDaigs = !_showAllDaigs;
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: const Color(0xFFFBBF24),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _showAllDaigs ? 'Show Less' : 'View All (${allDaigs.length})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Daig Item Cards
          ...displayedDaigs.map(
            (daig) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DaigCard(
                daig: daig,
                cartState: widget.cartState,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsSection() {
    final restaurants = _filteredRestaurants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory == 'All'
                        ? '🍽️ Top Restaurants (${restaurants.length})'
                        : '🍽️ $_selectedCategory Restaurants (${restaurants.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Order directly from popular partner restaurants & kitchens',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (restaurants.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 36, color: AppTheme.textLight),
                const SizedBox(height: 8),
                const Text(
                  'No restaurants match your search or filter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _quickFilter = 'All';
                      _homeSearchQuery = '';
                      _homeSearchController.clear();
                    });
                  },
                  child: const Text('Reset Filters'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return RestaurantCard(
                restaurant: restaurant,
                onTap: () => _openRestaurant(restaurant),
              );
            },
          ),
      ],
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
