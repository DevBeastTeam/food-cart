import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/food_item.dart';
import '../models/daig_item.dart';
import '../services/api_service.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shahi_dish_card.dart';
import 'cart_screen.dart';

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
  int _currentPage = 1;
  final int _itemsPerPage = 10;

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

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required ValueChanged<int> onPageChanged,
  }) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final canGoBack = currentPage > 1;
    final canGoForward = currentPage < totalPages;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Double Arrow Left (Full back to First Page)
          InkWell(
            onTap: canGoBack ? () => onPageChanged(1) : null,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canGoBack ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: canGoBack ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.first_page_rounded,
                size: 17,
                color: canGoBack ? AppTheme.primary : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 2. Single Arrow Left (Previous Page)
          InkWell(
            onTap: canGoBack ? () => onPageChanged(currentPage - 1) : null,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canGoBack ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: canGoBack ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 17,
                color: canGoBack ? AppTheme.primary : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 3. Middle Page Numbers (Scrollable horizontally if extra pages)
          Flexible(
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int page = 1; page <= totalPages; page++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: page == currentPage ? null : () => onPageChanged(page),
                          borderRadius: BorderRadius.circular(7),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: page == currentPage ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: page == currentPage ? AppTheme.primary : const Color(0xFFCBD5E1),
                                width: 1.1,
                              ),
                              boxShadow: page == currentPage
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.35),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              '$page',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: page == currentPage ? FontWeight.w900 : FontWeight.w700,
                                color: page == currentPage ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 4. Single Arrow Right (Next Page)
          InkWell(
            onTap: canGoForward ? () => onPageChanged(currentPage + 1) : null,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canGoForward ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: canGoForward ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: canGoForward ? AppTheme.primary : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 5. Double Arrow Right (Full forward to Last Page)
          InkWell(
            onTap: canGoForward ? () => onPageChanged(totalPages) : null,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: canGoForward ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: canGoForward ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.last_page_rounded,
                size: 17,
                color: canGoForward ? AppTheme.primary : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
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
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
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

          // 3. Food Items List with Top & Bottom Pagination
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
        final t = (c['type'] ?? 'restaurant').toString().toLowerCase().trim();
        if (widget.isPakwan) {
          return t == 'pakwan' || t == 'both';
        } else {
          return t == 'restaurant' || t == 'both';
        }
      }).map((c) => Map<String, dynamic>.from(c)).toList();
    }

    if (effectiveCats.isEmpty || (widget.isPakwan && effectiveCats.length <= 1)) {
      if (widget.isPakwan) {
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
                _currentPage = 1;
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
                      _currentPage = 1;
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

    final totalItems = items.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999);
    final currentPage = _currentPage.clamp(1, totalPages);
    final pageItems = items.skip((currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Top Pagination Bar
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          onPageChanged: (p) => setState(() => _currentPage = p),
        ),

        const SizedBox(height: 6),

        // Food Items Cards (Navy Blue luxury gradient)
        ...pageItems.map(
          (dish) => ShahiDishCard(
            item: dish,
            cartState: widget.cartState,
            isPakwan: false,
          ),
        ),

        // Bottom Pagination Bar
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          onPageChanged: (p) => setState(() => _currentPage = p),
        ),
      ],
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
                      _currentPage = 1;
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

    final totalItems = items.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999);
    final currentPage = _currentPage.clamp(1, totalPages);
    final pageItems = items.skip((currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Top Pagination Bar
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          onPageChanged: (p) => setState(() => _currentPage = p),
        ),

        const SizedBox(height: 6),

        // Shahi Daig Cards (Deep Orange with subtle black gradient)
        ...pageItems.map(
          (daig) => ShahiDishCard(
            daig: daig,
            cartState: widget.cartState,
            isPakwan: true,
          ),
        ),

        // Bottom Pagination Bar
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: totalItems,
          onPageChanged: (p) => setState(() => _currentPage = p),
        ),
      ],
    );
  }
}
