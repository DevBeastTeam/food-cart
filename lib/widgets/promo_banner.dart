import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PromoBanner extends StatefulWidget {
  final VoidCallback? onApplyPromo;
  final VoidCallback? onOrderNow;
  final void Function(Map<String, dynamic> banner)? onOrderBanner;
  final VoidCallback? onDismiss;
  final String? tagText;
  final String? title;
  final String? dishesText;
  final String? buttonText;
  final String? imageUrl;
  final List<Color>? bgGradientColors;
  final String selectedVendorId;

  const PromoBanner({
    super.key,
    this.onApplyPromo,
    this.onOrderNow,
    this.onOrderBanner,
    this.onDismiss,
    this.tagText,
    this.title,
    this.dishesText,
    this.buttonText,
    this.imageUrl,
    this.bgGradientColors,
    this.selectedVendorId = 'all',
  });

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static Color _parseHex(dynamic hex, Color fallback) {
    if (hex == null || hex is! String) return fallback;
    try {
      String clean = hex.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  // Fallback demo banners for vendors offering promotions
  static final List<Map<String, dynamic>> _fallbackBanners = [
    {
      'id': 'ban_2',
      'shop_name': 'Bannu Beef Pulao',
      'offerText': '40% OFF',
      'tagText': 'BANNU BEEF PULAO',
      'title': 'Bannu Beef Pulao Feast',
      'dishesText': 'Rich bone marrow stock & slow simmered beef • Free Naan & Raita',
      'buttonText': 'Order Now',
      'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
      'bgGradient': ['#D97706', '#92400E'],
      'sub_admin_id': 'sub_admin_1',
      'discountPercent': 40,
    },
    {
      'id': 'ban_1',
      'shop_name': 'Shahi Pakwan Center',
      'offerText': '25% OFF',
      'tagText': 'SHAHI PAKWAN CENTER',
      'title': 'Wood-Fire Shahi Daig Booking',
      'dishesText': 'Biryani, Pulao, Zarda, Haleem & Kheer Cauldrons • Dum Cooked',
      'buttonText': 'Order Now',
      'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80',
      'bgGradient': ['#EA580C', '#9A3412'],
      'sub_admin_id': 'sub_admin_2',
      'discountPercent': 25,
    },
    {
      'id': 'ban_3',
      'shop_name': 'Shinwari Karahi',
      'offerText': '30% OFF',
      'tagText': 'SHINWARI KARAHI',
      'title': 'Shinwari Mutton Karahi',
      'dishesText': 'Cooked fresh in tomatoes & traditional desi ghee • Hot Roghani Naan',
      'buttonText': 'Order Now',
      'imageUrl': 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=700&q=80',
      'bgGradient': ['#DC2626', '#7F1D1D'],
      'sub_admin_id': 'sub_admin_3',
      'discountPercent': 30,
    },
    {
      'id': 'ban_4',
      'shop_name': 'Madina Pakwan',
      'offerText': '20% OFF',
      'tagText': 'MADINA PAKWAN',
      'title': 'Special Degi Biryani & Daig',
      'dishesText': 'Authentic Lahore wedding feast & fresh cauldrons for all events',
      'buttonText': 'Order Now',
      'imageUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=700&q=80',
      'bgGradient': ['#059669', '#065F46'],
      'sub_admin_id': 'sub_admin_4',
      'discountPercent': 20,
    },
  ];

  static String _resolveShopName(Map<String, dynamic> banner) {
    final rawShop = banner['shop_name'];
    if (rawShop != null && rawShop.toString().trim().isNotEmpty && rawShop.toString() != 'Food Court Hub') {
      return rawShop.toString().trim();
    }
    final sid = (banner['sub_admin_id'] ?? '').toString();
    switch (sid) {
      case 'sub_admin_1':
        return 'Bannu Beef Pulao';
      case 'sub_admin_2':
        return 'Shahi Pakwan Center';
      case 'sub_admin_3':
        return 'Shinwari Karahi';
      case 'sub_admin_4':
        return 'Madina Pakwan';
      default:
        final tag = (banner['tagText'] ?? '').toString();
        if (tag.isNotEmpty && !tag.toUpperCase().contains('OFFER') && !tag.toUpperCase().contains('DEAL')) {
          return tag;
        }
        return 'Food Court Special';
    }
  }

  static String _resolveOfferText(Map<String, dynamic> banner) {
    if (banner['offerText'] != null && banner['offerText'].toString().trim().isNotEmpty) {
      return banner['offerText'].toString().trim();
    }
    final disc = banner['discountPercent'];
    if (disc != null) {
      final d = int.tryParse(disc.toString()) ?? 0;
      if (d > 0) return '$d% OFF';
    }
    final title = (banner['title'] ?? '').toString();
    final offMatch = RegExp(r'(\d+%\s*OFF)', caseSensitive: false).firstMatch(title);
    if (offMatch != null) {
      return offMatch.group(1)!.toUpperCase();
    }
    final tag = (banner['tagText'] ?? '').toString();
    final tagMatch = RegExp(r'(\d+%\s*OFF)', caseSensitive: false).firstMatch(tag);
    if (tagMatch != null) {
      return tagMatch.group(1)!.toUpperCase();
    }
    return 'HOT OFFER';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant PromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVendorId != widget.selectedVendorId) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    // Auto-scroll when multiple banners exist
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final list = _getEffectiveBanners();
      if (list.length <= 1) return;
      final nextPage = (_currentPage + 1) % list.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getEffectiveBanners() {
    final live = ApiService.instance.promoBanners;
    final allList = live.isNotEmpty ? live : _fallbackBanners;

    if (widget.selectedVendorId == 'all' || widget.selectedVendorId.isEmpty) {
      return allList;
    }

    // Filter by selected vendor ID
    final vendorList = allList.where((b) {
      final sid = (b['sub_admin_id'] ?? '').toString();
      final id = (b['id'] ?? '').toString();
      return sid == widget.selectedVendorId || id.contains(widget.selectedVendorId);
    }).toList();

    if (vendorList.isNotEmpty) {
      return vendorList;
    }

    // Dynamic branded banner for the selected vendor
    final shopName = _resolveShopName({'sub_admin_id': widget.selectedVendorId});
    return [
      {
        'id': 'vendor_banner_${widget.selectedVendorId}',
        'shop_name': shopName,
        'offerText': 'SPECIAL DEAL',
        'tagText': shopName.toUpperCase(),
        'title': '$shopName Exclusive Offer',
        'dishesText': 'Order fresh specialty dishes & catering from this certified kitchen.',
        'buttonText': 'Order Now',
        'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80',
        'bgGradient': ['#FF9500', '#EA580C'],
        'sub_admin_id': widget.selectedVendorId,
        'discountPercent': 15,
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    final banners = _getEffectiveBanners();
    final isMultiple = banners.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: (idx) {
              setState(() {
                _currentPage = idx;
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerCard(banner);
            },
          ),
        ),
        if (isMultiple) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (idx) {
              final isActive = idx == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isActive ? 22 : 6,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final shopName = _resolveShopName(banner);
    final offerText = _resolveOfferText(banner);
    final effectiveTitle = widget.title ?? banner['title'] ?? 'Special Feast';
    final effectiveDishes = widget.dishesText ??
        banner['dishesText'] ??
        banner['description'] ??
        'Freshly prepared specialty dishes & catering deals';
    final effectiveImage = widget.imageUrl ??
        banner['imageUrl'] ??
        'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80';

    List<Color> effectiveColors = const [
      Color(0xFFEA580C),
      Color(0xFF9A3412),
      Color(0xFF1E1E2D),
    ];

    if (banner['bgGradient'] is List) {
      final gradList = banner['bgGradient'] as List;
      if (gradList.length >= 2) {
        effectiveColors = gradList
            .map((c) => _parseHex(c, const Color(0xFFEA580C)))
            .toList();
      }
    } else if (widget.bgGradientColors != null) {
      effectiveColors = widget.bgGradientColors!;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: effectiveColors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Background Image covering card
            Positioned.fill(
              child: Image.network(
                effectiveImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),

            // 2. Gradient with transparent overlay colors
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveColors.first.withValues(alpha: 0.88),
                      effectiveColors.last.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle dark left vignette for sharp text contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            if (widget.onDismiss != null)
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDismiss,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Shop Name Tag
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white70,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  shopName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
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
                  const SizedBox(height: 7),

                  // Title
                  Text(
                    effectiveTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Description
                  Expanded(
                    child: Text(
                      effectiveDishes,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Bottom Right: Percentage Off outlined with silver shimmer + Order Now button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (offerText.isNotEmpty) ...[
                          ShimmerOutlinedOfferTag(text: offerText),
                          const SizedBox(width: 8),
                        ],
                        ShimmerOrderButton(
                          text: 'Order Now',
                          onTap: () {
                            if (widget.onOrderBanner != null) {
                              widget.onOrderBanner!(banner);
                            } else if (widget.onOrderNow != null) {
                              widget.onOrderNow!();
                            } else if (widget.onApplyPromo != null) {
                              widget.onApplyPromo!();
                            }
                          },
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
    );
  }
}

/// Outlined discount percentage tag with a continuous silver text & border shimmer
class ShimmerOutlinedOfferTag extends StatefulWidget {
  final String text;

  const ShimmerOutlinedOfferTag({super.key, required this.text});

  @override
  State<ShimmerOutlinedOfferTag> createState() => _ShimmerOutlinedOfferTagState();
}

class _ShimmerOutlinedOfferTagState extends State<ShimmerOutlinedOfferTag>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 1.1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Content: local offer icon + offer percentage
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),

              // Diagonal Silver Sheen sweeping across the outline badge
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(-80.0 + _controller.value * 200.0, 0),
                  child: Transform.rotate(
                    angle: 0.45,
                    child: Container(
                      width: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            const Color(0xFFCBD5E1).withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0.95),
                            const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Order Now Button with a continuous light silver shimmer sweep effect
class ShimmerOrderButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;

  const ShimmerOrderButton({
    super.key,
    this.onTap,
    this.text = 'Order Now',
  });

  @override
  State<ShimmerOrderButton> createState() => _ShimmerOrderButtonState();
}

class _ShimmerOrderButtonState extends State<ShimmerOrderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Text & Arrow Icon
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order Now',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),

                  // Diagonal Pure Silver Shimmer Sheen sweeping across the button
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(-100.0 + _controller.value * 260.0, 0),
                      child: Transform.rotate(
                        angle: 0.45,
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                                Colors.white.withValues(alpha: 0.95),
                                const Color(0xFFE2E8F0).withValues(alpha: 0.65),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
