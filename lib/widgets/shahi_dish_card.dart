import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/daig_item.dart';
import '../screens/food_detail_screen.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import 'custom_image.dart';

class ShahiDishCard extends StatelessWidget {
  final FoodItem? item;
  final DaigItem? daig;
  final CartState cartState;
  final String restaurantName;
  final VoidCallback? onOrderNow;
  final bool isPakwan;

  const ShahiDishCard({
    super.key,
    this.item,
    this.daig,
    required this.cartState,
    this.restaurantName = 'FoodCourt Central Kitchen',
    this.onOrderNow,
    this.isPakwan = false,
  }) : assert(item != null || daig != null, 'Either item or daig must be provided');

  bool get _isDaigMode => daig != null || isPakwan;

  String get _title => daig?.name ?? item?.name ?? '';
  String get _urduSubtitle => daig?.urduName ?? '';
  String get _imageUrl => daig?.imageUrl ?? item?.imageUrl ?? '';
  String get _description => daig?.description ?? item?.description ?? '';
  String get _category => daig?.category ?? item?.category ?? 'Special Dish';
  double get _rating => daig?.rating ?? item?.rating ?? 4.9;
  bool get _isAvailable => daig?.isAvailable ?? item?.isAvailable ?? true;

  String get _shopName {
    if (daig != null) {
      return daig!.centerName.isNotEmpty ? daig!.centerName : 'Shahi Pakwan Center';
    }
    return restaurantName.isNotEmpty ? restaurantName : 'FoodCourt Kitchen';
  }

  String get _location {
    if (daig != null) {
      return daig!.location.isNotEmpty ? daig!.location : 'Lahore';
    }
    return item?.locationAddress.isNotEmpty == true ? item!.locationAddress : 'FoodCourt Central Kitchen';
  }

  String get _priceDisplay {
    if (daig != null) {
      return 'From Rs. ${daig!.halfDaigPrice.toInt()}';
    }
    return 'Rs. ${item!.effectivePrice.toInt()}';
  }

  String get _cutPriceDisplay {
    if (daig != null) {
      if (daig!.cutPrice > daig!.fullDaigPrice) {
        return 'Rs. ${daig!.cutPrice.toInt()}';
      }
      return '';
    }
    if (item != null && item!.cutPrice > item!.effectivePrice) {
      return 'Rs. ${item!.cutPrice.toInt()}';
    }
    return '';
  }

  void _handleOrder(BuildContext context) {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maafi chahte hain! "$_title" filhal Out of Stock hai 🔴'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (onOrderNow != null) {
      onOrderNow!();
      return;
    }

    if (daig != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(
            daigItem: daig,
            cartState: cartState,
          ),
        ),
      );
    } else if (item != null) {
      cartState.addItem(item!, item!.restaurantId, restaurantName);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Added "$_title" to Cart! 🛍️')),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShahi = _isDaigMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        // Vibrant royal blue gradient for restaurant, Deep orange with slight black gradient for shahi pakwan
        gradient: isShahi
            ? const LinearGradient(
                colors: [
                  Color(0xFFC2410C), // Deep Orange
                  Color(0xFF9A3412), // Rust Orange
                  Color(0xFF18181B), // Soft Black / Charcoal
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.45, 1.0],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF230E4E), // Royal Deep Blue / Navy
                  Color(0xFF38106A), // Rich Midnight Navy Blue
                  Color(0xFF4C1D95), // Vibrant Royal Indigo Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.50, 1.0],
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isShahi
                ? const Color(0xFF7C2D12).withValues(alpha: 0.40)
                : const Color(0xFF2E1065).withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                  daigItem: daig,
                  cartState: cartState,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP: Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_urduSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _urduSubtitle,
                              style: TextStyle(
                                color: isShahi ? const Color(0xFFFDE68A) : const Color(0xFF93C5FD),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            '$_rating',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      CustomImage(
                        imageUrl: _imageUrl,
                        height: 155,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (!_isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.block_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 5),
                                    Text(
                                      'Out of Stock',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Description
                Text(
                  _description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // 4. Category Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 0.9,
                    ),
                  ),
                  child: Text(
                    _category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Price (Left) & Order Now Button (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRICE',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _priceDisplay,
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (_cutPriceDisplay.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _cutPriceDisplay,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11.5,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Order Now button
                    ElevatedButton.icon(
                      onPressed: () => _handleOrder(context),
                      icon: Icon(
                        _isAvailable ? Icons.flash_on_rounded : Icons.block_rounded,
                        size: 15,
                      ),
                      label: Text(_isAvailable ? 'Order Now' : 'Out of Stock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAvailable
                            ? (isShahi ? const Color(0xFFF97316) : AppTheme.primary)
                            : const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.8, color: Colors.white24),
                const SizedBox(height: 9),

                // 6. Bottom: Shop Name: Location with white/silver shimmer effect
                _ShimmerSilverLocationText(
                  text: '$_shopName: $_location',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small silver/white shimmer text for Shop Name: Location
class _ShimmerSilverLocationText extends StatefulWidget {
  final String text;

  const _ShimmerSilverLocationText({required this.text});

  @override
  State<_ShimmerSilverLocationText> createState() => _ShimmerSilverLocationTextState();
}

class _ShimmerSilverLocationTextState extends State<_ShimmerSilverLocationText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                const Color(0xFF94A3B8), // slate grey
                const Color(0xFFCBD5E1), // light silver
                Colors.white,             // white shine
                const Color(0xFFCBD5E1), // light silver
                const Color(0xFF94A3B8), // slate grey
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _LocationShimmerTransform(_ctrl.value),
            ).createShader(bounds);
          },
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationShimmerTransform extends GradientTransform {
  final double slidePercent;
  const _LocationShimmerTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}
