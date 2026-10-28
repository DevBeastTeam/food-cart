import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PromoBanner extends StatefulWidget {
  final VoidCallback? onApplyPromo;
  final VoidCallback? onOrderNow;
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

  // Fallback demo banners if backend has not loaded
  static final List<Map<String, dynamic>> _fallbackBanners = [
    {
      'id': 'ban_1',
      'tagText': 'SHAHI PAKWAN SPECIAL',
      'title': '25% OFF Shahi Daig Feast',
      'dishesText': 'Wood-Fire Shahi Daig Booking • Biryani, Pulao, Haleem & Kheer',
      'buttonText': 'Order Daig Now',
      'imageUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80',
      'bgGradient': ['#EA580C', '#C2410C'],
      'sub_admin_id': 'sub_admin_2',
      'discountPercent': 25,
    },
    {
      'id': 'ban_2',
      'tagText': 'SPECIAL BANNU OFFER',
      'title': '40% OFF Bannu Beef Pulao',
      'dishesText': 'Rich bone marrow stock & slow simmered meat • Free Naan & Raita',
      'buttonText': 'Order Pulao',
      'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=700&q=80',
      'bgGradient': ['#D97706', '#B45309'],
      'sub_admin_id': 'sub_admin_1',
      'discountPercent': 40,
    },
    {
      'id': 'ban_3',
      'tagText': 'HERITAGE SHINWARI DEAL',
      'title': '30% OFF Mutton Shinwari',
      'dishesText': 'Cooked fresh in tomatoes & traditional desi ghee • Hot Roghani Naan',
      'buttonText': 'Order Karahi',
      'imageUrl': 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=700&q=80',
      'bgGradient': ['#6C3CE9', '#8B5CF6'],
      'sub_admin_id': 'sub_admin_3',
      'discountPercent': 30,
    },
  ];

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
    // Only auto-scroll when in 'all' mode and multiple banners exist
    if (widget.selectedVendorId == 'all') {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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

    // If specific vendor has no banner yet, provide dynamic branded banner
    return [
      {
        'id': 'vendor_banner_${widget.selectedVendorId}',
        'tagText': 'EXCLUSIVE VENDOR DEAL',
        'title': 'Special Outlet Offer',
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
    final isMultiple = banners.length > 1 && widget.selectedVendorId == 'all';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 175,
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
    final effectiveTag = widget.tagText ?? banner['tagText'] ?? 'SPECIAL OFFER';
    final effectiveTitle = widget.title ?? banner['title'] ?? '40% OFF';
    final effectiveDishes = widget.dishesText ??
        banner['dishesText'] ??
        'Shahi Qorma, Beef Kabab, Degi Biryani, Mutton Karahi, Zarda';
    final effectiveButton = widget.buttonText ?? banner['buttonText'] ?? 'Order Now';
    final effectiveImage = widget.imageUrl ??
        banner['imageUrl'] ??
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80';

    List<Color> effectiveColors = const [
      Color(0xFF6C3CE9),
      Color(0xFF8B5CF6),
      Color(0xFFA855F7),
    ];

    if (banner['bgGradient'] is List) {
      final gradList = banner['bgGradient'] as List;
      if (gradList.length >= 2) {
        effectiveColors = gradList
            .map((c) => _parseHex(c, const Color(0xFF6C3CE9)))
            .toList();
      }
    } else if (widget.bgGradientColors != null) {
      effectiveColors = widget.bgGradientColors!;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: effectiveColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: effectiveColors.first.withAlpha(80),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative illustration / image
          Positioned(
            right: -15,
            bottom: -15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Opacity(
                opacity: 0.28,
                child: Image.network(
                  effectiveImage,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: -25,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
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
                      color: Colors.black.withValues(alpha: 0.25),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        effectiveTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // 2. Title
                Text(
                  effectiveTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // 3. Subtitle / Dishes
                Expanded(
                  child: Text(
                    effectiveDishes,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 4. Action Button
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: widget.onOrderNow ?? widget.onApplyPromo,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            effectiveButton,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
