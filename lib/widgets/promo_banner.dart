import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/sample_data.dart';
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

  static const List<Color> _tagOutlineColors = [
    Color(0xFFFBBF24), // Vibrant Amber / Yellow
    Color(0xFF60A5FA), // Vibrant Electric Blue
    Color(0xFFF87171), // Vibrant Coral Red
    Color(0xFF34D399), // Vibrant Emerald Green
    Color(0xFFA78BFA), // Vibrant Lavender Violet
    Colors.white,      // Pure White
  ];

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
      'location': 'Tariq Road, PECHS, Karachi',
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
      'location': 'Burns Road, Saddar, Karachi',
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
      'location': 'Gulshan-e-Iqbal, Block 4, Karachi',
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
      'location': 'Nazimabad No. 2, Karachi',
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

  static String _resolveShopLocation(Map<String, dynamic> banner) {
    if (banner['location'] != null && banner['location'].toString().trim().isNotEmpty) {
      return banner['location'].toString().trim();
    }
    if (banner['address'] != null && banner['address'].toString().trim().isNotEmpty) {
      return banner['address'].toString().trim();
    }
    final sid = (banner['sub_admin_id'] ?? '').toString();
    switch (sid) {
      case 'sub_admin_1':
        return 'Tariq Road, PECHS, Karachi';
      case 'sub_admin_2':
        return 'Burns Road, Saddar, Karachi';
      case 'sub_admin_3':
        return 'Gulshan-e-Iqbal, Block 4, Karachi';
      case 'sub_admin_4':
        return 'Nazimabad No. 2, Karachi';
      default:
        final shop = _resolveShopName(banner).toLowerCase();
        for (final r in SampleData.restaurants) {
          if (r.name.toLowerCase().contains(shop) || shop.contains(r.name.toLowerCase())) {
            return r.address;
          }
        }
        for (final p in SampleData.pakwanCenters) {
          if (p.name.toLowerCase().contains(shop) || shop.contains(p.name.toLowerCase())) {
            return p.address;
          }
        }
        return 'Central Hub, Karachi';
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
    final shopLocation = _resolveShopLocation({'sub_admin_id': widget.selectedVendorId});
    return [
      {
        'id': 'vendor_banner_${widget.selectedVendorId}',
        'shop_name': shopName,
        'location': shopLocation,
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
              return _buildBannerCard(banner, index);
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

  Widget _buildBannerCard(Map<String, dynamic> banner, int index) {
    final shopName = _resolveShopName(banner);
    final shopLocation = _resolveShopLocation(banner);
    final offerText = _resolveOfferText(banner);
    final tagColor = _tagOutlineColors[index % _tagOutlineColors.length];
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title (reduced font size) + 60% Smaller Outlined Percentage Tag with Shimmer
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          effectiveTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5, // reduced font size as requested
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (offerText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ShimmerOutlinedOfferTag(
                          text: offerText,
                          color: tagColor,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Row 2: Description
                  Expanded(
                    child: Text(
                      effectiveDishes,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Row 3: Shop Name & Location (minimal gap) on Left + Compact Order Now Button on Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1.5), // Minimal vertical gap as requested!
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 11,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    shopLocation,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 9.5,
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
                      CleanOrderButton(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined discount percentage tag with dynamic outline color and shimmer using flutter_animate
class ShimmerOutlinedOfferTag extends StatelessWidget {
  final String text;
  final Color color;

  const ShimmerOutlinedOfferTag({
    super.key,
    required this.text,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent, // STRICTLY NO BLACK - pure outline!
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color,
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            color: color,
            size: 9.5,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 2200.ms,
            delay: 300.ms,
            colors: [
              color.withValues(alpha: 0.40),
              Colors.white,
              color.withValues(alpha: 0.40),
            ],
            blendMode: BlendMode.srcIn,
          ),
    );
  }
}

/// Clean Compact Order Now Button without shimmer
class CleanOrderButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;

  const CleanOrderButton({
    super.key,
    this.onTap,
    this.text = 'Order Now',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 3.5),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 12,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef ShimmerOrderButton = CleanOrderButton;
