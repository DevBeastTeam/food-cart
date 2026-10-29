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
  bool _isFavorite = false;

  bool get _isDaig => widget.daigItem != null;

  @override
  void initState() {
    super.initState();
    if (_isDaig) {
      _selectedPortion = 'Large (12-14 KG)';
    } else {
      final badges = widget.foodItem?.badges ?? [];
      _selectedPortion = badges.isNotEmpty ? badges.first : 'Standard Portion';
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
      );
      restId = daig.centerId;
      restName = daig.centerName;
    } else {
      final f = widget.foodItem!;
      itemToAdd = FoodItem(
        id: '${f.id}_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: f.restaurantId,
        name: '${f.name} ($_selectedPortion)',
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added $_quantity x "$name" to your cart! 🛍️',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.amberAccent,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CartScreen(cartState: widget.cartState),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
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

            // 1. Big Image Header with Badges
            Stack(
              children: [
                Hero(
                  tag: 'food_img_${_isDaig ? widget.daigItem!.id : widget.foodItem!.id}',
                  child: CustomImage(
                    imageUrl: imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top floating badges
                Positioned(
                  top: 14,
                  left: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$rating',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '100% Halal',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom image overlay info
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isDaig ? 'Authentic Shahi Cauldrons' : 'Fresh Kitchen Prep',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. Dish Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Urdu name
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (urduName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      urduName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Pricing and Unit Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rs. ${_unitPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isDaig ? '/ Cauldron' : '/ Serving',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Preparation Location
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PREPARATION & DISPATCH SOURCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Offer Banner if any
                  if (activeOffer != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_rounded, color: Color(0xFFB45309), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Special Offer: ${activeOffer['title'] ?? ''} (${activeOffer['discountPercent']}% OFF)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'About this dish',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  // Daig Includes list if Daig
                  if (_isDaig && widget.daigItem!.includes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Includes with this Daig cauldron:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.daigItem!.includes.map(
                      (inc) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                inc,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Portion / Size Selection
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
                    Text(
                      _isDaig ? 'Select Cauldron Size' : 'Select Portion Option',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isDaig) ...[
                      _buildDaigPortionOption(
                        title: 'Small Deg (6 KG)',
                        subtitle: widget.daigItem!.halfDaigWeight,
                        price: widget.daigItem!.halfDaigPrice,
                        portionKey: 'Small (6 KG)',
                      ),
                      const SizedBox(height: 8),
                      _buildDaigPortionOption(
                        title: 'Medium Deg (10 KG)',
                        subtitle: widget.daigItem!.mediumDaigWeight,
                        price: widget.daigItem!.mediumDaigPrice,
                        portionKey: 'Medium (10 KG)',
                      ),
                      const SizedBox(height: 8),
                      _buildDaigPortionOption(
                        title: 'Large Deg (12-14 KG)',
                        subtitle: widget.daigItem!.fullDaigWeight,
                        price: widget.daigItem!.fullDaigPrice,
                        portionKey: 'Large (12-14 KG)',
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (widget.foodItem?.badges.isNotEmpty == true
                                ? widget.foodItem!.badges
                                : ['Single Platter (1kg)', 'Family Pack (3kg)', 'Desi Ghee Regular'])
                            .map((p) {
                          final isSel = _selectedPortion == p;
                          return InkWell(
                            onTap: () => setState(() => _selectedPortion = p),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.primary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? AppTheme.primary : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 12.5,
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
                    ],

                    // Spice Level if Daig
                    if (_isDaig) ...[
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
                    ],

                    const SizedBox(height: 16),

                    // Cooking Instructions
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

            const SizedBox(height: 24),

            // 4. Quantity and Order Floating Sticky Bar
            Container(
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
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  'Rs. ${_totalPrice.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Row(
                              children: [
                                Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
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
            shopName = 'Bannu Beef Pulao';
            shopLocation = 'Tariq Road, PECHS, Karachi';
            shopImage = 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80';
            shopPhone = '+92 300 1234567';
            break;
          case 'sub_admin_2':
            shopName = 'Shahi Pakwan Center';
            shopLocation = 'Burns Road, Saddar, Karachi';
            shopImage = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80';
            shopPhone = '+92 300 8472910';
            break;
          case 'sub_admin_3':
            shopName = 'Shinwari Karahi';
            shopLocation = 'Gulshan-e-Iqbal, Block 4, Karachi';
            shopImage = 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=700&q=80';
            shopPhone = '+92 301 7654321';
            break;
          case 'sub_admin_4':
            shopName = 'Madina Pakwan';
            shopLocation = 'Nazimabad No. 2, Karachi';
            shopImage = 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=700&q=80';
            shopPhone = '+92 301 5551234';
            break;
          default:
            shopName = 'FoodCourt Special Kitchen';
            shopLocation = f.locationAddress.isNotEmpty ? f.locationAddress : 'Central Delivery Hub, Karachi';
            shopImage = 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=700&q=80';
            shopPhone = '+92 300 9876543';
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

    // 1. COLLAPSED STATE
    if (_isCollapsed) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF230E4E), Color(0xFF38106A), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withAlpha(35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF230E4E).withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1.5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shopLocation,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
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
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _isCollapsed = false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 3),
                    Text(
                      'Show Shop',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. EXPANDED STATE (Luxury Dark Purple Gradient Card matching Orders Screen HQ)
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        border: Border.all(
          color: Colors.white.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF230E4E).withAlpha(120),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Shop Badge, Open Status, and Collapse Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded, color: Color(0xFFFBBF24), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'SHOP',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'Open Daily',
                        style: TextStyle(color: Color(0xFF22C55E), fontSize: 10.5, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Collapse Button
              InkWell(
                onTap: () => setState(() => _isCollapsed = true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 2),
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

          const SizedBox(height: 10),

          // Carousel (Shop Image & Offer Banner)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 125,
              child: PageView(
                controller: _carouselController,
                onPageChanged: (idx) => setState(() => _carouselIndex = idx),
                children: [
                  // Slide 1: Shop Image with dark gradient and shimmering badge
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomImage(
                        imageUrl: shopImage,
                        fit: BoxFit.cover,
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

          // Shop Title
          Text(
            shopName,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFFBBF24), size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shopLocation,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Supported Types Row
          Row(
            children: [
              const Text(
                'Supported: ',
                style: TextStyle(
                  color: Color(0xFF94A3B8), // Grey text
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  supportedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Contact Number Row (if provided)
          if (shopPhone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF22C55E), size: 13),
                  const SizedBox(width: 5),
                  const Text(
                    'Contact: ',
                    style: TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      shopPhone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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

          // Action Button Row: "View Shop Location"
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
                    padding: const EdgeInsets.symmetric(vertical: 9),
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
