import 'dart:async';
import 'package:flutter/material.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _foodSlideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Diagonal slide from top-right towards corner
    _foodSlideAnimation = Tween<Offset>(
      begin: const Offset(0.35, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _animController.forward();

    // Auto-proceed to Home Screen after 3.5 seconds
    _autoNavTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _goToHome();
      }
    });
  }

  void _goToHome() {
    _autoNavTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
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

  void _goToLogin() {
    _autoNavTimer?.cancel();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          userState: widget.userState,
          initialIsSignUp: false,
        ),
      ),
    ).then((_) {
      if (mounted) _goToHome();
    });
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. DIAGONAL HALF-CUT ANIMATED FOOD COMPOSITION (Top-Right towards bottom)
            Positioned(
              top: -40,
              right: -50,
              width: size.width * 0.85,
              height: size.height * 0.52,
              child: SlideTransition(
                position: _foodSlideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildHalfCutFoodComposition(),
                  ),
                ),
              ),
            ),

            // 2. MAIN APP INFO & BRANDING CONTAINER (Clean White Aesthetics)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withAlpha(50)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu_rounded, color: AppTheme.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'FOOD COURT & SHAHI PAKWAN',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Big Hero Title
                  const Text(
                    'Food Court',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'شاہی پکوان و ریسٹورنٹس (ملٹی وینڈرز)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Feature Pills Required by Client
                  _buildFeatureRow(
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF7E22CE),
                    title: 'Multi-Vendor Food App (ملٹی وینڈرز فوڈ ایپ)',
                    subtitle: 'Order from verified top restaurants & traditional kitchens',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    icon: Icons.two_wheeler_rounded,
                    color: const Color(0xFFD97706),
                    title: 'Location-Based Dedicated Riders (لوکیشن رائیڈرز)',
                    subtitle: 'Direct fleet dispatch from your nearest kitchen outlet',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    icon: Icons.soup_kitchen_rounded,
                    color: const Color(0xFFDC2626),
                    title: 'Shahi Daig Catering (شاہی دیگیں کیٹرنگ)',
                    subtitle: 'Sealed hot 12 KG / 6 KG wood-dum cauldons for events & Dawats',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFF059669),
                    title: '24/7 Fast Customer Support (کسٹمر سپورٹ)',
                    subtitle: 'Instant phone and WhatsApp assistance on every order',
                  ),

                  const Spacer(flex: 3),

                  // 3. BOTTOM BUTTONS: Continue as Guest / Login
                  Row(
                    children: [
                      // Explore Menu as Guest Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goToHome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppTheme.primary.withAlpha(100),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Explore as Guest (گیسٹ)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Login Icon/Button
                      OutlinedButton(
                        onPressed: _goToLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.login_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Login',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Browse dishes, daigs & offers without login • Login required at checkout',
                      style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
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

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textSecondary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Diagonal half-cut overlapping image arrangement
  Widget _buildHalfCutFoodComposition() {
    return Stack(
      children: [
        // Main Giant Circular Dish (Cut at top-right corner)
        Positioned(
          top: 0,
          right: 0,
          width: 260,
          height: 260,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(45),
                  blurRadius: 28,
                  offset: const Offset(4, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFFEF3C7)),
              ),
            ),
          ),
        ),

        // Overlapping Shahi Deg Cauldron badge
        Positioned(
          bottom: 20,
          left: 10,
          width: 140,
          height: 140,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(55),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFFDE68A)),
              ),
            ),
          ),
        ),

        // Small floating appetizing BBQ chip
        Positioned(
          top: 140,
          right: 170,
          width: 75,
          height: 75,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.orange),
              ),
            ),
          ),
        ),

        // Floating "100% Halal Desi Ghee" Badge
        Positioned(
          bottom: 10,
          right: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👑', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Text(
                  'Pure Desi Ghee',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
