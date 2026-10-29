import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final CartState cartState;
  final UserState userState;

  const SplashScreen({
    super.key,
    required this.cartState,
    required this.userState,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();

    // Auto-proceed to Home Screen after 2.6 seconds if user doesn't press Get Started
    _autoNavTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        _goToHome();
      }
    });
  }

  void _goToHome() {
    _autoNavTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => HomeScreen(
          cartState: widget.cartState,
          userState: widget.userState,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background subtle aura matching Navy Blue / Royal Purple theme
          Positioned(
            top: -60,
            left: -60,
            right: -60,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF6C3CE9).withValues(alpha: 0.10),
                    const Color(0xFF1E1B4B).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // TOP HERO SECTION: Female Delivery Courier with Cap, Bags & Parcel
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Soft background backdrop card
                          Container(
                            width: size.width * 0.86,
                            height: size.height * 0.42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),

                          // Main Delivery Courier Character Image (Female rider holding parcels & bags)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: SizedBox(
                              width: size.width * 0.86,
                              height: size.height * 0.42,
                              child: Image.asset(
                                'assets/images/delivery_courier.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.network(
                                  'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=800&q=80',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                          // Floating Pill #Fresh on Top-Right with Sparkle (Shimmer Effect)
                          Positioned(
                            top: 18,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#Fresh',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('✨', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat(period: const Duration(seconds: 3)))
                                .shimmer(duration: const Duration(milliseconds: 1400), color: Colors.amberAccent.withValues(alpha: 0.6)),
                          ),

                          // Floating Pill #Delicious on Mid-Left with Sparkle (Shimmer Effect)
                          Positioned(
                            bottom: 60,
                            left: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#Delicious',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('🔥', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat(period: const Duration(seconds: 3)))
                                .shimmer(duration: const Duration(milliseconds: 1400), color: Colors.white.withValues(alpha: 0.7)),
                          ),

                          // 3 Floating Food Dish Cards Layered at Bottom (Matching Image Mockup)
                          Positioned(
                            bottom: -24,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFoodDishThumb(
                                  imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&q=80',
                                  label: 'Biryani',
                                ),
                                const SizedBox(width: 12),
                                _buildFoodDishThumb(
                                  imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80',
                                  label: 'BBQ',
                                  isElevated: true,
                                ),
                                const SizedBox(width: 12),
                                _buildFoodDishThumb(
                                  imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
                                  label: 'Fast Food',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  // BOTTOM BRANDING SECTION: Food Court + Multi Vendor (with Shimmer)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Food Court & Multi Vendor Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Food Court',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Multi Vendor Badge with continuous shimmer effect
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4C1D95), Color(0xFF6C3CE9), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C3CE9).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront_rounded, color: Colors.amberAccent, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Multi Vendor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat(period: const Duration(seconds: 2)))
                              .shimmer(duration: const Duration(milliseconds: 1300), color: Colors.amberAccent.withValues(alpha: 0.8)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Platform Description (Customer, Multi-Vendor, Rider)
                      const Text(
                        'Rider, Customer & Multi-Vendor Food & Shahi Pakwan Platform.\nOrder fresh food, groceries & authentic catering daigs instantly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // GET STARTED BUTTON (with Shimmer Effect)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _goToHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF31105E), Color(0xFF6C3CE9)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C3CE9).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat(period: const Duration(seconds: 2)))
                          .shimmer(duration: const Duration(milliseconds: 1400), color: Colors.white.withValues(alpha: 0.4)),

                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Small floating rounded food dish preview cards beneath the character
  Widget _buildFoodDishThumb({
    required String imageUrl,
    required String label,
    bool isElevated = false,
  }) {
    return Container(
      width: 76,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: isElevated ? 0.22 : 0.14),
            blurRadius: isElevated ? 14 : 10,
            offset: Offset(0, isElevated ? 6 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.5),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFF1F5F9),
            alignment: Alignment.center,
            child: const Icon(Icons.fastfood_rounded, color: AppTheme.primary, size: 24),
          ),
        ),
      ),
    )
        .animate(delay: isElevated ? 150.ms : 0.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
