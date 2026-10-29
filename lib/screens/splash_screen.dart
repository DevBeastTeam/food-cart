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

    // Auto-proceed to Home Screen after 7 seconds
    _autoNavTimer = Timer(const Duration(seconds: 7), () {
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
          // ── LAYER 1: Girl image perfectly centered & uncropped with bottom fade ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/delivery_courier.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=800&q=80',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Smooth gradient overlay: 100% clear at top, dissolves to white at bottom
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.45, 0.70, 0.88, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LAYER 3: Side characters + floating overlays ─────────────────
          SafeArea(
            child: Stack(
              children: [

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // TOP LEFT — Pakwan Chef (piche se kaam kar raha hai, fades at bottom)
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                Positioned(
                  top: 0,
                  left: 0,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white.withValues(alpha: 0.5), Colors.transparent],
                      stops: const [0.0, 0.6, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.85,
                      child: Column(
                        children: [
                          // Chef hat icon header
                          Container(
                            margin: const EdgeInsets.only(left: 10, top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👨‍🍳', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Shahi Pakwan', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                    Text('Kitchen', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Daig cooking visual
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200&q=80',
                                width: 70,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 70, height: 72,
                                  child: Center(child: Text('🫕', style: TextStyle(fontSize: 36))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Steam / cooking indicator
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('🔥 Cooking Now', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(period: const Duration(seconds: 3)))
                      .shimmer(duration: const Duration(milliseconds: 1800), color: Colors.amber.withValues(alpha: 0.3)),
                ),

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // TOP RIGHT — Delivery Rider + Shahi Pakwan Daig cards (fades at bottom)
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                Positioned(
                  top: 0,
                  right: 0,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white.withValues(alpha: 0.4), Colors.transparent],
                      stops: const [0.0, 0.55, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Opacity(
                      opacity: 0.88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Rider pill (Theme Deep Purple / Royal Violet matching Get Started button)
                          Container(
                            margin: const EdgeInsets.only(right: 10, top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF31105E), Color(0xFF6C3CE9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF6C3CE9).withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🏍️', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rider On Way', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                                    Text('Home Delivery', style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 9, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(period: const Duration(seconds: 2)))
                              .shimmer(duration: const Duration(milliseconds: 1200), color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(height: 6),
                          // Daig / Pakwan card
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5), width: 1),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=200&q=80',
                                    width: 68,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(
                                      width: 68, height: 60,
                                      child: Center(child: Text('🍛', style: TextStyle(fontSize: 30))),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Shahi Daig', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Second daig card
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=200&q=80',
                                    width: 60,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(
                                      width: 60, height: 52,
                                      child: Center(child: Text('🍚', style: TextStyle(fontSize: 26))),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text('Degi Biryani', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LAYER 4: Bottom content floating over gradient ────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Food Dish Thumb Row — Pulao, Pizza, Parcel themed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFoodDishThumb(
                          imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&q=80',
                          label: 'Pulao 🍚',
                        ),
                        const SizedBox(width: 12),
                        _buildFoodDishThumb(
                          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
                          label: 'Pizza 🍕',
                          isElevated: true,
                        ),
                        const SizedBox(width: 12),
                        _buildFoodDishThumb(
                          imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400&q=80',
                          label: 'Parcel 📦',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Food Court + Multi Vendor Title Row
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

                        // Multi Vendor Outlined Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C3CE9).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6C3CE9),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storefront_rounded, color: Color(0xFF6C3CE9), size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Multi Vendor',
                                style: TextStyle(
                                  color: Color(0xFF6C3CE9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(period: const Duration(seconds: 2)))
                            .shimmer(duration: const Duration(milliseconds: 1300), color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description with Grey & Black Shimmer
                    Text(
                      'Availability: All nearby cities restaurant foods • Desi Foods\nShahi Pakwan • Riders • Home Delivery',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(period: const Duration(seconds: 2)))
                        .shimmer(
                          duration: const Duration(milliseconds: 1400),
                          color: const Color(0xFF94A3B8),
                        ),

                    const SizedBox(height: 20),

                    // GET STARTED BUTTON
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
                        .animate(onPlay: (c) => c.repeat(period: const Duration(seconds: 2)))
                        .shimmer(duration: const Duration(milliseconds: 1400), color: Colors.white.withValues(alpha: 0.4)),
                  ],
                ),
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
