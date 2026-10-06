import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/restaurant.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import 'cart_screen.dart';
import 'restaurant_details_screen.dart';
import '../state/user_state.dart';
import 'auth_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...SampleData.sampleAddresses.map((address) {
                final isSelected = widget.cartState.deliveryAddress == address;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 22)
                      : null,
                  onTap: () {
                    widget.cartState.setAddress(address);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

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

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(cartState: widget.cartState),
      ),
    );
  }

  // _getFilteredRestaurants removed - using mobile filter approach instead

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.cartState, widget.userState]),
      builder: (context, _) {
        final isNarrow = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: _buildMobileBody(isNarrow),
          bottomNavigationBar: _buildBottomNavigationBar(isNarrow),
          floatingActionButton: widget.cartState.totalItemCount > 0 && _currentNavIndex != 2
              ? _buildFloatingCartButton()
              : null,
        );
      },
    );
  }

  Widget _buildFloatingCartButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton.extended(
        onPressed: _openCart,
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: Badge(
          label: Text(
            '${widget.cartState.totalItemCount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          backgroundColor: Colors.white,
          textColor: AppTheme.primary,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
        ),
        label: Text(
          'Cart • Rs. ${widget.cartState.subtotal.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBody([bool isNarrow = false]) {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomeMobile(isNarrow);
      case 1:
        return _buildSearchMobile(isNarrow);
      case 2:
        return _buildCartScreenMobile();
      case 3:
        return _buildProfileMobile(isNarrow);
      default:
        return _buildHomeMobile(isNarrow);
    }
  }

  Widget _buildHomeMobile([bool isNarrow = false]) {
    final isLoggedIn = widget.userState.isLoggedIn;
    final user = widget.userState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar with Greeting & User Auth/Avatar
          Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _showAddressSelector,
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.cartState.deliveryAddress.split('•').first.trim(),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLoggedIn
                            ? 'Welcome back, ${user?.name.split(' ').first ?? 'Foodie'}! 👋'
                            : 'Sign in to order faster & get discounts',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoggedIn && user != null)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentNavIndex = 3; // Switch to Profile/Dashboard Tab
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
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
                    icon: const Icon(Icons.login, size: 14),
                    label: const Text('Log In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
            ),
          ),

          // Search bar
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search food, dishes, restaurants...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // Category chips (mobile grid)
          const SizedBox(height: 16),
          const Text(
            'Popular Cuisines',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: SampleData.categories.map((cat) {
              final isSelected = _selectedCategory == cat['name'] as String;
              return FilterChip(
                selected: isSelected,
                label: Text(cat['name'] as String, style: const TextStyle(fontSize: 13)),
                onSelected: (val) {
                  setState(() {
                    _selectedCategory = cat['name'] as String;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                selectedColor: AppTheme.primaryLight,
                checkmarkColor: AppTheme.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Restaurants grid
          const Text(
            'Top Restaurants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          // Restaurant grid - 2 columns on mobile
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: SampleData.restaurants.length,
            itemBuilder: (context, index) {
              return _buildRestaurantCardMobile(SampleData.restaurants[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCardMobile(Restaurant restaurant) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openRestaurant(restaurant),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Restaurant image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomImage(
                  imageUrl: restaurant.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // Restaurant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.cuisine,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.starGold, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          restaurant.deliveryTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
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

  Widget _buildSearchMobile([bool isNarrow = false]) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search & Discover',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search food, dishes, restaurants...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: SampleData.categories.map((cat) {
              return FilterChip(
                label: Text(cat['name'] as String, style: const TextStyle(fontSize: 13)),
                onSelected: (val) {
                  setState(() {
                    _selectedCategory = cat['name'] as String;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                selected: _selectedCategory == (cat['name'] as String),
                selectedColor: AppTheme.primaryLight,
                checkmarkColor: AppTheme.primary,
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppTheme.border),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Popular Restaurants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          // Placeholder - would show filtered restaurants
          const Text(
            'Search to find restaurants',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMobile([bool isNarrow = false]) {
    return UserDashboardScreen(
      userState: widget.userState,
      cartState: widget.cartState,
      isEmbedded: true,
    );
  }

  Widget _buildCartScreenMobile() {
    return CartScreen(cartState: widget.cartState);
  }


  Widget _buildBottomNavigationBar([bool isNarrow = false]) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary,
      currentIndex: _currentNavIndex,
      onTap: (idx) {
        setState(() {
          _currentNavIndex = idx;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_filled, color: AppTheme.primary),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search, color: AppTheme.primary),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag, color: AppTheme.primary),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person, color: AppTheme.primary),
          label: 'Profile',
        ),
      ],
    );
  }
}
