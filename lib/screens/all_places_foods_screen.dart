import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/food_item.dart';
import '../models/daig_item.dart';
import '../services/api_service.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import 'cart_screen.dart';
import 'food_detail_screen.dart';

class AllPlacesFoodsScreen extends StatefulWidget {
  final bool isPakwan;
  final CartState cartState;
  final String selectedVendorId;
  final String selectedVendorName;
  final String selectedVendorLocation;

  const AllPlacesFoodsScreen({
    super.key,
    required this.isPakwan,
    required this.cartState,
    this.selectedVendorId = 'all',
    this.selectedVendorName = '',
    this.selectedVendorLocation = '',
  });

  @override
  State<AllPlacesFoodsScreen> createState() => _AllPlacesFoodsScreenState();
}

class _AllPlacesFoodsScreenState extends State<AllPlacesFoodsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodItem> get _filteredRestaurantItems {
    List<FoodItem> items = List<FoodItem>.from(SampleData.allTrendingFoodItems);

    if (widget.selectedVendorId != 'all') {
      final vendorFiltered = items.where((d) =>
          d.subAdminId == widget.selectedVendorId ||
          d.restaurantId == widget.selectedVendorId ||
          d.locationAddress.toLowerCase().contains(widget.selectedVendorLocation.toLowerCase()) ||
          d.name.toLowerCase().contains(widget.selectedVendorName.toLowerCase())).toList();
      if (vendorFiltered.isNotEmpty) {
        items = vendorFiltered;
      }
    }

    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      items = items.where((d) =>
          d.category.toLowerCase().contains(cat) ||
          cat.contains(d.category.toLowerCase())).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q)).toList();
    }

    return items;
  }

  List<DaigItem> get _filteredPakwanItems {
    List<DaigItem> items = List<DaigItem>.from(SampleData.daigDishes);

    if (widget.selectedVendorId != 'all') {
      final vendorFiltered = items.where((d) =>
          d.subAdminId == widget.selectedVendorId ||
          d.centerId == widget.selectedVendorId ||
          d.centerName.toLowerCase().contains(widget.selectedVendorName.toLowerCase()) ||
          d.location.toLowerCase().contains(widget.selectedVendorLocation.toLowerCase())).toList();
      if (vendorFiltered.isNotEmpty) {
        items = vendorFiltered;
      }
    }

    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      items = items.where((d) =>
          d.category.toLowerCase().contains(cat) ||
          cat.contains(d.category.toLowerCase())).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.urduName.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q)).toList();
    }

    return items;
  }

  void _handleQuickOrderRestaurant(FoodItem item) {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maafi chahte hain! "${item.name}" filhal Out of Stock hai 🔴'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.cartState.addItem(item, item.restaurantId, 'FoodCourt Central Kitchen');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Added "${item.name}" to cart! 🛍️')),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.amberAccent,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CartScreen(cartState: widget.cartState)),
            );
          },
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.selectedVendorId != 'all' && widget.selectedVendorName.isNotEmpty
        ? '${widget.selectedVendorName} Foods'
        : 'All Places Foods';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.cartState,
            builder: (context, _) {
              final count = widget.cartState.totalItemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CartScreen(cartState: widget.cartState),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Field directly under AppBar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.isPakwan
                      ? 'Search Shahi cauldrons, degs, pulao, haleem...'
                      : 'Search dishes, biryani, karahi, fast food...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Category Buttons (Horizontal single row, rectangular non-rounded pills)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryPills(),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // 3. Food Items List
          Expanded(
            child: widget.isPakwan ? _buildPakwanList() : _buildRestaurantList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final liveCats = ApiService.instance.categories;
    List<Map<String, dynamic>> effectiveCats = [];

    if (liveCats.isNotEmpty) {
      effectiveCats = liveCats.where((c) {
        final t = (c['type'] ?? 'restaurant').toString();
        if (widget.isPakwan) {
          return t == 'pakwan' || t == 'both';
        } else {
          return t == 'restaurant' || t == 'both';
        }
      }).map((c) => Map<String, dynamic>.from(c)).toList();
    }

    if (effectiveCats.isEmpty) {
      if (widget.isPakwan) {
        effectiveCats = [
          {'name': 'All', 'icon': '🍽️'},
          {'name': 'Biryani & Pulao', 'icon': '🍲'},
          {'name': 'Qorma & Karahi', 'icon': '🥘'},
          {'name': 'Haleem & Nihari', 'icon': '🥣'},
          {'name': 'Sweet & Desserts', 'icon': '🍨'},
        ];
      } else {
        effectiveCats = [
          {'name': 'All', 'icon': '🍽️'},
          {'name': 'Biryani', 'icon': '🍚'},
          {'name': 'Karahi & Handi', 'icon': '🥘'},
          {'name': 'BBQ & Grills', 'icon': '🍢'},
          {'name': 'Fast Food', 'icon': '🍔'},
          {'name': 'Chinese & Soups', 'icon': '🍜'},
          {'name': 'Desserts', 'icon': '🍰'},
        ];
      }
    } else {
      final hasAll = effectiveCats.any((c) => (c['name'] ?? '').toString().toLowerCase() == 'all');
      if (!hasAll) {
        effectiveCats.insert(0, {'name': 'All', 'icon': '🍽️'});
      }
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: effectiveCats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = effectiveCats[index];
          final name = cat['name']?.toString() ?? '';
          final icon = cat['icon']?.toString() ?? '🍽️';
          final isSelected = _selectedCategory.toLowerCase() == name.toLowerCase();

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = name;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
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

  Widget _buildRestaurantList() {
    final items = _filteredRestaurantItems;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text(
                'No food items match your criteria',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching for another dish or clear category filter',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = 'All';
                      _searchController.clear();
                    });
                  },
                  child: const Text('Reset Filters'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRestaurantFoodTile(item);
      },
    );
  }

  Widget _buildRestaurantFoodTile(FoodItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FoodDetailScreen(
                  foodItem: item,
                  cartState: widget.cartState,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Leading Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      CustomImage(
                        imageUrl: item.imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                      if (!item.isAvailable)
                        Container(
                          width: 76,
                          height: 76,
                          color: Colors.black.withValues(alpha: 0.6),
                          alignment: Alignment.center,
                          child: const Text(
                            'OUT OF\nSTOCK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Middle Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Rs. ${item.effectivePrice.toInt()}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (item.cutPrice > item.effectivePrice) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Rs. ${item.cutPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // 3. Trailing Order Now text button
                          TextButton(
                            onPressed: () => _handleQuickOrderRestaurant(item),
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Order Now',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.add_rounded, size: 14),
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
      ),
    );
  }

  Widget _buildPakwanList() {
    final items = _filteredPakwanItems;

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.soup_kitchen_outlined, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text(
                'No Shahi Daigs match your criteria',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching for another daig or clear category filter',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = 'All';
                      _searchController.clear();
                    });
                  },
                  child: const Text('Reset Filters'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildPakwanFoodTile(item);
      },
    );
  }

  Widget _buildPakwanFoodTile(DaigItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FoodDetailScreen(
                  daigItem: item,
                  cartState: widget.cartState,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Leading Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      CustomImage(
                        imageUrl: item.imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                      if (!item.isAvailable)
                        Container(
                          width: 76,
                          height: 76,
                          color: Colors.black.withValues(alpha: 0.6),
                          alignment: Alignment.center,
                          child: const Text(
                            'OUT OF\nSTOCK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Middle Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (item.urduName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.urduName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'From Rs. ${item.halfDaigPrice.toInt()}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                          const Spacer(),
                          // 3. Trailing Order Now text button
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FoodDetailScreen(
                                    daigItem: item,
                                    cartState: widget.cartState,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Order Now',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.add_rounded, size: 14),
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
      ),
    );
  }
}
