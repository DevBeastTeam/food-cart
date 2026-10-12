import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PromoBanner extends StatelessWidget {
  final VoidCallback? onApplyPromo;
  final VoidCallback? onOrderNow;
  final VoidCallback? onDismiss;
  final String? tagText;
  final String? title;
  final String? dishesText;
  final String? buttonText;
  final String? imageUrl;
  final List<Color>? bgGradientColors;

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
  });

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

  @override
  Widget build(BuildContext context) {
    // Check if backend provided active banners
    final banners = ApiService.instance.promoBanners;
    final activeBanner = banners.isNotEmpty ? banners.first : null;

    final effectiveTag = tagText ?? activeBanner?['tagText'] ?? 'SPECIAL OFFER';
    final effectiveTitle = title ?? activeBanner?['title'] ?? '40% OFF';
    final effectiveDishes = dishesText ??
        activeBanner?['dishesText'] ??
        'Shahi Qorma, Beef Kabab, Degi Biryani, Mutton Karahi, Zarda';
    final effectiveButton = buttonText ?? activeBanner?['buttonText'] ?? 'Order Now';
    final effectiveImage = imageUrl ??
        activeBanner?['imageUrl'] ??
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80';

    List<Color> effectiveColors = bgGradientColors ?? const [
      Color(0xFF6C3CE9),
      Color(0xFF8B5CF6),
      Color(0xFFA855F7),
    ];

    if (bgGradientColors == null && activeBanner?['bgGradient'] is List) {
      final gradList = activeBanner!['bgGradient'] as List;
      if (gradList.length >= 2) {
        effectiveColors = gradList
            .map((c) => _parseHex(c, const Color(0xFF6C3CE9)))
            .toList();
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: effectiveColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            right: -15,
            bottom: -15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Opacity(
                opacity: 0.22,
                child: Image.network(
                  effectiveImage,
                  width: 140,
                  height: 140,
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
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          if (onDismiss != null)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDismiss,
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
                // 1. Special Offer Announcement Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.amberAccent, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        effectiveTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Main Title
                Text(
                  effectiveTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),

                // 3. Comma-separated Pakistani Dishes
                Text(
                  effectiveDishes,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Button on Bottom Right
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onOrderNow ?? onApplyPromo,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
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

