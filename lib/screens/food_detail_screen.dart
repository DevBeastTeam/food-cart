import 'dart:async';
import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/food_item.dart';
import '../models/daig_item.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_image.dart';
import 'cart_screen.dart';
import 'head_office_detail_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem? foodItem;
  final DaigItem? daigItem;
  final CartState cartState;

  const FoodDetailScreen({
    super.key,
    this.foodItem,
    this.daigItem,
    required this.cartState,
  }) : assert(foodItem != null || daigItem != null, 'Either foodItem or daigItem must be provided');

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;
  late String _selectedPortion;
  final TextEditingController _notesController = TextEditingController();
  String _selectedSpiceLevel = 'Medium';
  String _selectedOccasion = 'Family Gathering';

  bool get _isDaig => widget.daigItem != null;

  @override
  void initState() {
    super.initState();
    if (_isDaig) {
      _selectedPortion = 'Large (12-14 KG)';
    } else {
      final badges = widget.foodItem?.badges ?? [];
      _selectedPortion = badges.isNotEmpty ? badges.first : '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    if (_isDaig) {
      final daig = widget.daigItem!;
      if (_selectedPortion.contains('Small') || _selectedPortion.contains('6 KG')) {
        return daig.halfDaigPrice;
      } else if (_selectedPortion.contains('Medium') || _selectedPortion.contains('10 KG')) {
        return daig.mediumDaigPrice;
      } else {
        return daig.fullDaigPrice;
      }
    } else {
      return widget.foodItem!.effectivePrice;
    }
  }

  double get _totalPrice => _unitPrice * _quantity;

  void _handleAddToCart() {
    final name = _isDaig ? widget.daigItem!.name : widget.foodItem!.name;
    final isAvailable = _isDaig ? widget.daigItem!.isAvailable : widget.foodItem!.isAvailable;

    if (!isAvailable) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maafi chahte hain! "$name" filhal Out of Stock hai 🔴'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FoodItem itemToAdd;
    String restId;
    String restName;

    if (_isDaig) {
      final daig = widget.daigItem!;
      String sizeKey = 'large';
      if (_selectedPortion.contains('Small') || _selectedPortion.contains('6 KG')) {
        sizeKey = 'half';
      } else if (_selectedPortion.contains('Medium') || _selectedPortion.contains('10 KG')) {
        sizeKey = 'medium';
      }

      itemToAdd = daig.toFoodItem(
        sizeName: sizeKey,
        notes: _notesController.text.trim(),
        occasion: _selectedOccasion,
        spiceLevel: _selectedSpiceLevel,
      );
      restId = daig.centerId;
      restName = daig.centerName;
    } else {
      final f = widget.foodItem!;
      final portionSuffix = _selectedPortion.isNotEmpty && _selectedPortion != 'Standard Portion' ? ' ($_selectedPortion)' : '';
      itemToAdd = FoodItem(
        id: '${f.id}_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: f.restaurantId,
        name: '${f.name}$portionSuffix',
        description: _notesController.text.trim().isNotEmpty
            ? '${f.description} • Note: ${_notesController.text.trim()}'
            : f.description,
        price: f.price,
        imageUrl: f.imageUrl,
        category: f.category,
        rating: f.rating,
        calories: f.calories,
        isPopular: f.isPopular,
        isVegetarian: f.isVegetarian,
        locationAddress: f.locationAddress,
        badges: f.badges,
        badge: f.badge,
        discountPercent: f.discountPercent,
        discountPrice: f.discountPrice,
        cutPrice: f.cutPrice,
        showCutPrice: f.showCutPrice,
        isDiscounted: f.isDiscounted,
        promoBadge: f.promoBadge,
        subAdminId: f.subAdminId,
        isAvailable: f.isAvailable,
      );
      restId = f.restaurantId;
      restName = 'FoodCourt Central Kitchen';
    }

    for (int i = 0; i < _quantity; i++) {
      widget.cartState.addItem(itemToAdd, restId, restName);
    }

    AppTheme.showAddToCartToast(
      context,
      itemName: name,
      quantity: _quantity,
      onViewCart: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CartScreen(cartState: widget.cartState),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isDaig ? widget.daigItem!.name : widget.foodItem!.name;
    final urduName = _isDaig ? widget.daigItem!.urduName : '';
    final imageUrl = _isDaig ? widget.daigItem!.imageUrl : widget.foodItem!.imageUrl;
    final description = _isDaig ? widget.daigItem!.description : widget.foodItem!.description;
    final rating = _isDaig ? widget.daigItem!.rating : widget.foodItem!.rating;
    final address = _isDaig ? widget.daigItem!.location : widget.foodItem!.locationAddress;
    final isAvailable = _isDaig ? widget.daigItem!.isAvailable : widget.foodItem!.isAvailable;
    final subAdminId = _isDaig ? widget.daigItem!.subAdminId : widget.foodItem!.subAdminId;
    final activeOffer = ApiService.instance.getVendorActiveOffer(subAdminId);

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
            color: AppTheme.textPrimary,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Shop Info Collapsible Card (Matching HQ design with Shop Image & Offer Carousel)
            _ShopInfoCollapsibleCard(
              foodItem: widget.foodItem,
              daigItem: widget.daigItem,
              isDaig: _isDaig,
            ),

            if (!_isDaig && widget.foodItem != null)
              _buildRestaurantItemView(context, isAvailable)
            else
              _buildDaigItemView(
                title: title,
                urduName: urduName,
                imageUrl: imageUrl,
                description: description,
                rating: rating,
                address: address,
                isAvailable: isAvailable,
                activeOffer: activeOffer,
              ),

            const SizedBox(height: 24),

            // Bottom Quantity & Order Floating Action Bar
            _buildBottomActionBar(isAvailable),
          ],
        ),
      ),
    );
  }

  /// Restaurant Food Item View with generous gap, smooth gradient fade, rounded top thumbnail,
  /// type & category badges, and vendor-only details.
  Widget _buildRestaurantItemView(BuildContext context, bool isAvailable) {
    final food = widget.foodItem!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Generous Gap with Subtle Smooth Gradient Blend (Grey fading into White)
        Container(
          height: 26,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0x60F1F5F9),
                Color(0xFFF1F5F9),
              ],
            ),
          ),
        ),

        // 2. Main Restaurant Food Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with Top-Left and Top-Right Rounded Corners & Badges
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'food_img_${food.id}',
                        child: CustomImage(
                          imageUrl: food.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Soft gradient overlay on image for readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(90),
                                Colors.transparent,
                                Colors.black.withAlpha(60),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badges on Thumbnail: Type & Category
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            // Type Badge: Grey background with Type: 🍽️ ریسٹورنٹ
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xE61E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withAlpha(50), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Type: ',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '🍽️ ریسٹورنٹ (Restaurant)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Category Badge (e.g. Biryani, Pulao, Zarda, etc.)
                            if (food.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withAlpha(60), width: 0.8),
                                ),
                                child: Text(
                                  food.category,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE68A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Out of stock or Discount badge
                      if (!isAvailable)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OUT OF STOCK 🔴',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                      else if (food.isDiscounted && food.discountPercent > 0)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              food.promoBadge.isNotEmpty
                                  ? food.promoBadge
                                  : '${food.discountPercent}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Details Content Below Image
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title on Left, Price on Right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${_unitPrice.toInt()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                              ),
                              if (food.showCutPrice && food.cutPrice > food.effectivePrice) ...[
                                const SizedBox(height: 1),
                                Text(
                                  'Rs. ${food.cutPrice.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Vendor Description
                      if (food.description.trim().isNotEmpty) ...[
                        Text(
                          food.description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Vendor Specific Fields (Calories / Vegetarian if set)
                      if (food.calories > 0 || food.isVegetarian) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (food.calories > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥 ', style: TextStyle(fontSize: 10)),
                                    Text(
                                      '${food.calories} kcal',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (food.isVegetarian)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.eco_rounded, size: 12, color: Color(0xFF16A34A)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Vegetarian',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Portion Variations (if vendor created multiple portion badges, e.g. Single / Family)
                      if (food.badges.length > 1) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        const Text(
                          'Available Portions / Variations',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: food.badges.map((p) {
                            final isSel = _selectedPortion == p;
                            return InkWell(
                              onTap: () => setState(() => _selectedPortion = p),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primary : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? AppTheme.primary : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Kitchen Notes / Special Instructions
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      const Text(
                        'Special Instructions (Optional)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Less oil, extra raita, mild spices, cutlery needed...',
                          hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
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
      ],
    );
  }

  /// Daig Item View (Shahi Cauldrons Booking)
  Widget _buildDaigItemView({
    required String title,
    required String urduName,
    required String imageUrl,
    required String description,
    required double rating,
    required String address,
    required bool isAvailable,
    required Map<String, dynamic>? activeOffer,
  }) {
    final daig = widget.daigItem!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Generous Gap with Subtle Smooth Gradient Blend (Grey fading into White)
        Container(
          height: 26,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0x60F1F5F9),
                Color(0xFFF1F5F9),
              ],
            ),
          ),
        ),

        // 2. Main Pakwan Food Card with Rounded Top Corners & Badges
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with Top-Left and Top-Right Rounded Corners (18px) & Badges
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'food_img_${daig.id}',
                        child: CustomImage(
                          imageUrl: imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Soft gradient overlay on image for readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(90),
                                Colors.transparent,
                                Colors.black.withAlpha(60),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Badges on Thumbnail: Type & Category
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            // Type Badge: Grey background with Type: 🍲 شاہی پکوان
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xE61E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withAlpha(50), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Type: ',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '🍲 شاہی پکوان (Shahi Pakwan)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Category Badge (e.g. Biryani & Pulao, Deg Cauldron)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withAlpha(60), width: 0.8),
                              ),
                              child: Text(
                                daig.category.isNotEmpty ? daig.category : 'Deg Cauldron',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom Badges: Authentic Shahi Cauldrons / Out of stock
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(170),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFF59E0B).withAlpha(140), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('👑 ', style: TextStyle(fontSize: 10)),
                                  Text(
                                    'Authentic Shahi Cauldrons',
                                    style: TextStyle(
                                      color: Color(0xFFFDE68A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'OUT OF STOCK 🔴',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$rating',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Details Content Below Image
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title on Left, Price on Right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                    height: 1.25,
                                  ),
                                ),
                                if (urduName.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    urduName,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${_unitPrice.toInt()}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                '/ Cauldron',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description directly below Title & Price
                      if (description.trim().isNotEmpty) ...[
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Daig Includes list (if present)
                      if (daig.includes.isNotEmpty) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 12),
                        const Text(
                          'Includes with this Daig cauldron:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: daig.includes.map((inc) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    inc,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Selection / Customization Options for Daig
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Cauldron Size',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDaigPortionOption(
                  title: 'Small Deg (6 KG)',
                  subtitle: daig.halfDaigWeight,
                  price: daig.halfDaigPrice,
                  portionKey: 'Small (6 KG)',
                ),
                const SizedBox(height: 8),
                _buildDaigPortionOption(
                  title: 'Medium Deg (10 KG)',
                  subtitle: daig.mediumDaigWeight,
                  price: daig.mediumDaigPrice,
                  portionKey: 'Medium (10 KG)',
                ),
                const SizedBox(height: 8),
                _buildDaigPortionOption(
                  title: 'Large Deg (12-14 KG)',
                  subtitle: daig.fullDaigWeight,
                  price: daig.fullDaigPrice,
                  portionKey: 'Large (12-14 KG)',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Spice Level',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Mild (ہلکی مرچ)', 'Medium (مناسب)', 'Extra Spicy (تیز چٹپٹی)'].map((spice) {
                    final isSel = _selectedSpiceLevel == spice;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedSpiceLevel = spice),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              spice.split(' ').first,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Occasion / Gathering',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Family Gathering', 'Dawat / Party', 'Wedding / Valima', 'Khatam / Niaz', 'Charity / Sadqa'].map((occ) {
                    final isSel = _selectedOccasion == occ;
                    return InkWell(
                      onTap: () => setState(() => _selectedOccasion = occ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFB45309) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? const Color(0xFFB45309) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          occ,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSel ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Special Instructions (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Less oil, extra raita, mild spices, specific delivery time...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Sticky Bottom Action Bar with Quantity Counter and Add to Cart Button
  Widget _buildBottomActionBar(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quantity Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    color: AppTheme.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    color: AppTheme.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Order Button with Price
            Expanded(
              child: ElevatedButton(
                onPressed: isAvailable ? _handleAddToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAvailable ? AppTheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white70,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rs. ${_totalPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDaigPortionOption({
    required String title,
    required String subtitle,
    required double price,
    required String portionKey,
  }) {
    final isSel = _selectedPortion.contains(portionKey.split(' ').first);
    return InkWell(
      onTap: () => setState(() => _selectedPortion = portionKey),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: isSel ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSel ? AppTheme.primary : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${price.toInt()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSel ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable / Collapsible Shop Info Card matching Orders Screen HQ design
class _ShopInfoCollapsibleCard extends StatefulWidget {
  final FoodItem? foodItem;
  final DaigItem? daigItem;
  final bool isDaig;

  const _ShopInfoCollapsibleCard({
    this.foodItem,
    this.daigItem,
    required this.isDaig,
  });

  @override
  State<_ShopInfoCollapsibleCard> createState() => _ShopInfoCollapsibleCardState();
}

class _ShopInfoCollapsibleCardState extends State<_ShopInfoCollapsibleCard>
    with SingleTickerProviderStateMixin {
  bool _isCollapsed = true;
  late final AnimationController _textShimmerController;
  late final Animation<double> _textShimmer;
  late final PageController _carouselController;
  int _carouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _textShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _textShimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _textShimmerController, curve: Curves.easeInOut),
    );
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted || !_carouselController.hasClients) return;
      final sid = widget.isDaig
          ? (widget.daigItem?.subAdminId ?? '')
          : (widget.foodItem?.subAdminId ?? '');
      final hasOffer = _hasOfferForSid(sid);
      final totalPages = hasOffer ? 2 : 1;
      if (totalPages > 1) {
        final next = (_carouselIndex + 1) % totalPages;
        _carouselController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _hasOfferForSid(String sid) {
    if (ApiService.instance.getVendorActiveOffer(sid) != null) return true;
    const demoList = ['sub_admin_1', 'sub_admin_2', 'sub_admin_3', 'sub_admin_4'];
    return demoList.contains(sid) || widget.isDaig;
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _textShimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sid = widget.isDaig
        ? (widget.daigItem?.subAdminId ?? '')
        : (widget.foodItem?.subAdminId ?? '');
    final restId = widget.isDaig
        ? (widget.daigItem?.centerId ?? '')
        : (widget.foodItem?.restaurantId ?? '');

    String shopName = '';
    String shopLocation = '';
    String shopImage = '';
    String shopPhone = '';

    if (widget.isDaig && widget.daigItem != null) {
      shopName = widget.daigItem!.centerName;
      shopLocation = widget.daigItem!.location;
      for (final p in SampleData.pakwanCenters) {
        if (p.id == widget.daigItem!.centerId ||
            p.name.toLowerCase().trim() == widget.daigItem!.centerName.toLowerCase().trim()) {
          shopImage = p.imageUrl;
          shopPhone = p.phone;
          break;
        }
      }
      if (shopImage.isEmpty) {
        shopImage = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80';
      }
      if (shopPhone.isEmpty) {
        shopPhone = '+92 300 8472910';
      }
    } else if (widget.foodItem != null) {
      final f = widget.foodItem!;
      shopLocation = f.locationAddress;
      for (final r in SampleData.restaurants) {
        if (r.id == f.restaurantId) {
          shopName = r.name;
          shopLocation = r.address;
          shopImage = r.imageUrl;
          break;
        }
      }
      if (shopName.isEmpty) {
        switch (sid) {
          case 'sub_admin_1':
            shopName = 'Bannu Beef Pulao & Nalli Nihari';
            shopLocation = 'Shop 12, Block K, Gulberg III, Lahore';
            shopImage = 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80';
            shopPhone = '+92 300 1122334';
            break;
          case 'sub_admin_2':
            shopName = 'Shahi Pakwan Center';
            shopLocation = 'Bungalow 18-C, Model Town, Lahore';
            shopImage = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80';
            shopPhone = '+92 301 4455667';
            break;
          case 'sub_admin_3':
            shopName = 'Dawat Khana Desi Heritage';
            shopLocation = 'Main Boulevard, Phase 5, DHA, Lahore';
            shopImage = 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=700&q=80';
            shopPhone = '+92 322 1122334';
            break;
          case 'sub_admin_4':
            shopName = 'Madina Pakwan & Catering Service';
            shopLocation = 'Commercial Plaza 8, Block G, Johar Town, Lahore';
            shopImage = 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=700&q=80';
            shopPhone = '+92 333 4455667';
            break;
          default:
            shopName = 'FoodCourt Special Kitchen';
            shopLocation = f.locationAddress.isNotEmpty ? f.locationAddress : '14-C Gulberg III, Lahore';
            shopImage = 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=700&q=80';
            shopPhone = '+92 300 8472910';
            break;
        }
      }
    }

    // Check supported types (Restaurant / Shahi Pakwan)
    final hasRestaurant = SampleData.allTrendingFoodItems.any((item) =>
        item.subAdminId == sid ||
        item.restaurantId == restId ||
        (shopName.isNotEmpty && item.name.toLowerCase().contains(shopName.toLowerCase())));

    final hasPakwan = SampleData.daigDishes.any((item) =>
        item.subAdminId == sid ||
        item.centerId == restId ||
        (shopName.isNotEmpty && item.centerName.toLowerCase().contains(shopName.toLowerCase())));

    String supportedText = '';
    if (hasRestaurant && hasPakwan) {
      supportedText = 'Restaurant & Shahi Pakwan';
    } else if (hasPakwan) {
      supportedText = 'Shahi Pakwan';
    } else {
      supportedText = 'Restaurant';
    }

    // Check offer
    String offerDiscountText = '30% OFF';
    String offerTitle = 'Special Discount Deal';
    final hasOffer = _hasOfferForSid(sid);
    final bannerOffer = ApiService.instance.getVendorActiveOffer(sid);
    if (bannerOffer != null) {
      offerDiscountText = bannerOffer['offerText'] ?? 'HOT DEAL';
      offerTitle = bannerOffer['title'] ?? 'Exclusive Kitchen Offer';
    } else {
      switch (sid) {
        case 'sub_admin_1':
          offerDiscountText = '40% OFF';
          offerTitle = 'Bannu Beef Pulao Feast Deal';
          break;
        case 'sub_admin_2':
          offerDiscountText = '25% OFF';
          offerTitle = 'Wood-Fire Shahi Daig Deal';
          break;
        case 'sub_admin_3':
          offerDiscountText = '30% OFF';
          offerTitle = 'Shinwari Mutton Karahi Offer';
          break;
        case 'sub_admin_4':
          offerDiscountText = '20% OFF';
          offerTitle = 'Special Degi Biryani & Daig';
          break;
        default:
          offerDiscountText = '15% OFF';
          offerTitle = 'Certified Kitchen Special Deal';
          break;
      }
    }

    // 1. COLLAPSED STATE (Full-width, zero-gap flush header, without rounded bottom)
    if (_isCollapsed) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF230E4E), Color(0xFF38106A), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            bottom: BorderSide(color: Colors.white.withAlpha(35), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF230E4E).withAlpha(80),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5.5),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, color: Color(0xFFFBBF24), size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF94A3B8), // Grey location icon
                        size: 11.5,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shopLocation,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8), // Grey text as requested
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _isCollapsed = false),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 3),
                    Text(
                      'Show Shop',
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. EXPANDED STATE (Full-width, zero-gap luxury gradient card, without rounded bottom)
    final bool hasValidShopImage = shopImage.isNotEmpty && !shopImage.contains('null');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF230E4E),
            Color(0xFF38106A),
            Color(0xFF4C1D95),
            Color(0xFF5B21B6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(40), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF230E4E).withAlpha(120),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row: Shop Icon + Shop Name + Grey Location + Hide Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFFBBF24), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF94A3B8), // Grey location icon
                          size: 11.5,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            shopLocation,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8), // Grey text as requested
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Hide Button
              InkWell(
                onTap: () => setState(() => _isCollapsed = true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 3),
                      Text(
                        'Hide',
                        style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 1. Carousel (Shop Image & Offer Banner)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 130,
              child: PageView(
                controller: _carouselController,
                onPageChanged: (idx) => setState(() => _carouselIndex = idx),
                children: [
                  // Slide 1: Shop Image (or fallback "No Shop Image Available" if empty)
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasValidShopImage)
                        CustomImage(
                          imageUrl: shopImage,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          color: const Color(0xFF1E1B4B),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_rounded, size: 36, color: Colors.white38),
                              SizedBox(height: 6),
                              Text(
                                'No Shop Image',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(150),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 10,
                        right: 10,
                        child: Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.storefront_rounded, color: Color(0xFFFBBF24), size: 13),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: AnimatedBuilder(
                                        animation: _textShimmer,
                                        builder: (context, child) {
                                          final relativeX = _textShimmer.value;
                                          return ShaderMask(
                                            shaderCallback: (bounds) {
                                              return LinearGradient(
                                                colors: const [
                                                  Colors.white,
                                                  Color(0xFFFBBF24),
                                                  Colors.white,
                                                ],
                                                end: Alignment(relativeX, 0),
                                              ).createShader(bounds);
                                            },
                                            child: Text(
                                              shopName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Slide 2: Active Offer Slide (if offer exists)
                  if (hasOffer)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFF9A3412), Color(0xFF1E1E2D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      offerDiscountText,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Limited Time Offer 🔥',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                offerTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '• Valid on all orders from this kitchen',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Carousel dot indicator if multiple slides
          if (hasOffer) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (idx) {
                final isActive = idx == _carouselIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  height: 4,
                  width: isActive ? 14 : 5,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFFBBF24) : Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 10),

          // 2. Supported Types Row
          Row(
            children: [
              const Text(
                'Supported: ',
                style: TextStyle(
                  color: Color(0xFF94A3B8), // Grey text
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  supportedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 3. Contact / WhatsApp Row (if phone provided)
          if (shopPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF22C55E), size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Contact: ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      shopPhone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 4. View Shop Location Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HeadOfficeDetailScreen()),
                    );
                  },
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: const Text(
                    'View Shop Location',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
