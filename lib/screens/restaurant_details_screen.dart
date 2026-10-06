import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/restaurant.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import '../widgets/food_item_card.dart';
import 'cart_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;
  final CartState cartState;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
    required this.cartState,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  late String _activeCategory;
  bool _isFavorite = false;
  final TextEditingController _itemSearchController = TextEditingController();
  String _itemSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.restaurant.categories.first;
  }

  @override
  void dispose() {
    _itemSearchController.dispose();
    super.dispose();
  }

  List<FoodItem> _getFilteredMenu() {
    return widget.restaurant.menu.where((item) {
      final matchesCategory = _activeCategory == 'All' ||
          item.category.toLowerCase() == _activeCategory.toLowerCase();
      final query = _itemSearchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(cartState: widget.cartState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.cartState,
      builder: (context, _) {
        final filteredMenu = _getFilteredMenu();
        final hasCartItems = widget.cartState.totalItemCount > 0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Sliver App Bar with cover image
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? AppTheme.primary : AppTheme.textPrimary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isFavorite
                                      ? 'Added to your favorites'
                                      : 'Removed from favorites'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined, color: AppTheme.textPrimary, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sharing "${widget.restaurant.name}" link...'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomImage(
                            imageUrl: widget.restaurant.imageUrl,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(100),
                                  Colors.transparent,
                                  Colors.black.withAlpha(120),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Restaurant Info Header Card
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF28A745),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.restaurant.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.star, color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.restaurant.cuisine,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${widget.restaurant.address} (${widget.restaurant.distance})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Badges Row
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildMetricColumn(
                                    icon: Icons.timer_outlined,
                                    title: 'Delivery',
                                    value: widget.restaurant.deliveryTime,
                                  ),
                                ),
                                Container(width: 1, height: 28, color: AppTheme.border),
                                Expanded(
                                  child: _buildMetricColumn(
                                    icon: Icons.delivery_dining_outlined,
                                    title: 'Delivery Fee',
                                    value: widget.restaurant.formattedDeliveryFee,
                                    valueColor: widget.restaurant.deliveryFee == 0
                                        ? AppTheme.success
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Container(width: 1, height: 28, color: AppTheme.border),
                                Expanded(
                                  child: _buildMetricColumn(
                                    icon: Icons.receipt_outlined,
                                    title: 'Min. Order',
                                    value: 'Rs. ${widget.restaurant.minOrder.toInt()}',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Special Discount Banner in Restaurant
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F0FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryLight),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.local_offer_rounded,
                                    size: 18, color: AppTheme.primary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Use CRAVEE40 for 40% OFF on checkout up to Rs. 300!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: TextField(
                        controller: _itemSearchController,
                        onChanged: (val) {
                          setState(() {
                            _itemSearchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search items in this menu...',
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primary),
                          suffixIcon: _itemSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _itemSearchController.clear();
                                    setState(() {
                                      _itemSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Category Selector Tabs
                  SliverToBoxAdapter(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.restaurant.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = widget.restaurant.categories[index];
                          final isSelected = _activeCategory == category;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _activeCategory = category;
                                });
                              }
                            },
                            selectedColor: AppTheme.primary,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primary : AppTheme.border,
                              ),
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),
                  ),

                  // Menu Items Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '$_activeCategory Items (${filteredMenu.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu Items List
                  if (filteredMenu.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.restaurant_menu,
                                size: 40, color: AppTheme.textLight),
                            const SizedBox(height: 8),
                            const Text(
                              'No dishes found in this section',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          16, 4, 16, hasCartItems ? 100 : 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredMenu[index];
                            return FoodItemCard(
                              item: item,
                              restaurantName: widget.restaurant.name,
                              restaurantDeliveryFee: widget.restaurant.deliveryFee,
                              cartState: widget.cartState,
                            );
                          },
                          childCount: filteredMenu.length,
                        ),
                      ),
                    ),
                ],
              ),

              // Bottom Sticky Cart Bar
              if (hasCartItems)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: ElevatedButton(
                        onPressed: _openCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${widget.cartState.totalItemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'View Your Cart',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${widget.cartState.subtotal.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildMetricColumn({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
