import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/restaurant.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/restaurant_card.dart';
import 'cart_screen.dart';
import 'restaurant_details_screen.dart';

class RestaurantsScreen extends StatefulWidget {
  final CartState cartState;

  const RestaurantsScreen({
    super.key,
    required this.cartState,
  });

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _quickFilter = 'All'; // 'All', 'Top Rated', 'Fast Delivery', 'Free Delivery'

  final List<Map<String, dynamic>> _foodCategories = [
    {'name': 'All', 'icon': '🍽️'},
    {'name': 'Fast Food', 'icon': '🍟'},
    {'name': 'Burgers', 'icon': '🍔'},
    {'name': 'Pizza', 'icon': '🍕'},
    {'name': 'BBQ', 'icon': '🍢'},
    {'name': 'Biryani', 'icon': '🍚'},
    {'name': 'Chinese', 'icon': '🥡'},
    {'name': 'Desi Food', 'icon': '🥘'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Restaurant> get _filteredRestaurants {
    return SampleData.restaurants.where((rest) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
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

      if (_quickFilter == 'Top Rated' && rest.rating < 4.8) return false;
      if (_quickFilter == 'Free Delivery' && rest.deliveryFee > 0) return false;
      if (_quickFilter == 'Fast Delivery') {
        final timeStr = rest.deliveryTime.split('-').first.replaceAll(RegExp(r'[^0-9]'), '');
        final timeInt = int.tryParse(timeStr) ?? 30;
        if (timeInt > 25) return false;
      }

      return true;
    }).toList();
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

  Widget _buildFilterPill(String filterName, {IconData? icon}) {
    final isSelected = _quickFilter == filterName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _quickFilter = isSelected && filterName != 'All' ? 'All' : filterName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (filterName == 'Top Rated' ? const Color(0xFFF59E0B) : AppTheme.primary),
              ),
              const SizedBox(width: 4),
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

  @override
  Widget build(BuildContext context) {
    final restaurants = _filteredRestaurants;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🍽️ Partner Restaurants & Food Hubs',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${SampleData.restaurants.length} kitchens • Fast Food, Pizza, BBQ & Desi',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openCart,
            icon: Badge(
              isLabelVisible: widget.cartState.totalItemCount > 0,
              label: Text(
                '${widget.cartState.totalItemCount}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Deals Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flat 40% OFF with Code: SHAHI40',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Valid on Fast Food, Pizza, Burgers, BBQ & Biryani orders',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Color(0xFFC2410C),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search Pizza, Burgers, BBQ, Biryani, Chinese...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Specific Food Categories (Fast Food, Pizza, Burgers, BBQ, Biryani, Chinese, Desi Food)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Explore Food Categories',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_selectedCategory != 'All')
                  InkWell(
                    onTap: () => setState(() => _selectedCategory = 'All'),
                    child: const Text(
                      'Clear Filter',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _foodCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _foodCategories[index];
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as String;
                  final isSel = _selectedCategory == name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppTheme.primary : AppTheme.border,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withAlpha(40),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Quick Filter Pills (Top Rated, Fast Delivery, Free Delivery)
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterPill('All'),
                  const SizedBox(width: 6),
                  _buildFilterPill('Top Rated', icon: Icons.star_rounded),
                  const SizedBox(width: 6),
                  _buildFilterPill('Fast Delivery', icon: Icons.electric_bolt_rounded),
                  const SizedBox(width: 6),
                  _buildFilterPill('Free Delivery', icon: Icons.delivery_dining_rounded),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Header Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == 'All'
                      ? 'Available Restaurants (${restaurants.length})'
                      : '$_selectedCategory Restaurants (${restaurants.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Open Now • 11 AM - 2 AM',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Restaurant Cards List
            if (restaurants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 48, color: AppTheme.textLight),
                    const SizedBox(height: 12),
                    const Text(
                      'No restaurants match your search or filter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                          _quickFilter = 'All';
                          _selectedCategory = 'All';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reset All Filters'),
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
                  final rest = restaurants[index];
                  return RestaurantCard(
                    restaurant: rest,
                    onTap: () => _openRestaurant(rest),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
