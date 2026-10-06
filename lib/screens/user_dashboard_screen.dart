import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_item.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final UserState userState;
  final CartState? cartState;
  final bool isEmbedded;

  const UserDashboardScreen({
    super.key,
    required this.userState,
    this.cartState,
    this.isEmbedded = false,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _orderFilter = 'All'; // 'All', 'Food', 'Daig'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final isLoggedIn = widget.userState.isLoggedIn;
        final user = widget.userState.user;

        if (!isLoggedIn || user == null) {
          return _buildLoggedOutView();
        }

        final content = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 18),
                  _buildWalletAndRewardsCard(user),
                  const SizedBox(height: 22),
                  if (widget.userState.activeOrdersCount > 0) ...[
                    _buildActiveOrderTrackingCard(),
                    const SizedBox(height: 22),
                  ],
                  _buildOrderHistorySection(),
                  const SizedBox(height: 24),
                  _buildSavedAddressesSection(),
                  const SizedBox(height: 24),
                  _buildVouchersSection(),
                  const SizedBox(height: 24),
                  _buildSettingsAndSupportSection(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );

        if (widget.isEmbedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'My Account & Dashboard',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit Profile',
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                onPressed: () => _showEditProfileDialog(user),
              ),
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: _showLogoutConfirmDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: content,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // LOGGED OUT VIEW
  // ---------------------------------------------------------------------------
  Widget _buildLoggedOutView() {
    final body = Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_outline_rounded, size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome to FoodCourt',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in or register to track orders, manage live Daig bookings, use promo vouchers, and check your wallet balance.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          userState: widget.userState,
                          initialIsSignUp: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Log In to FoodCourt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(
                          userState: widget.userState,
                          initialIsSignUp: true,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Create New Account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: body,
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeader(UserProfile user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF6C3CE9), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE9).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 18, color: Color(0xFF38BDF8)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          user.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_city, size: 12, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          user.city,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tier Chip and Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      user.membershipTier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _showEditProfileDialog(user),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
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
    );
  }

  // ---------------------------------------------------------------------------
  // WALLET & REWARDS CARD
  // ---------------------------------------------------------------------------
  Widget _buildWalletAndRewardsCard(UserProfile user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Wallet Balance
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet Balance',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${user.walletBalance.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Coins Balance
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FoodCourt Coins',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user.loyaltyCoins} pts',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
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
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showTopUpWalletDialog,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Top Up Wallet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user.loyaltyCoins} Coins available! Redeemable on checkout for flat discounts.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF2E1065),
                      ),
                    );
                  },
                  icon: const Icon(Icons.card_giftcard, size: 16),
                  label: const Text('Redeem Coins'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
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

  // ---------------------------------------------------------------------------
  // ACTIVE ORDER TRACKING CARD
  // ---------------------------------------------------------------------------
  Widget _buildActiveOrderTrackingCard() {
    final liveOrder = widget.userState.orders.firstWhere(
      (o) => o.status != 'Delivered',
      orElse: () => widget.userState.orders.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delivery_dining, size: 16, color: Color(0xFFB45309)),
                    SizedBox(width: 5),
                    Text(
                      'LIVE ORDER TRACKING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ETA: 18-24 mins',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  liveOrder.restaurantImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.primaryLight,
                    child: const Icon(Icons.restaurant, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveOrder.restaurantName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${liveOrder.id} • ${liveOrder.items.length} items',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${liveOrder.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress steps
          Row(
            children: [
              _buildProgressStep(Icons.receipt_long, 'Placed', true),
              _buildProgressLine(true),
              _buildProgressStep(Icons.soup_kitchen, 'Preparing', true),
              _buildProgressLine(true),
              _buildProgressStep(Icons.two_wheeler, 'On Way', true, isActive: true),
              _buildProgressLine(false),
              _buildProgressStep(Icons.check_circle_outline, 'Delivered', false),
            ],
          ),
          const SizedBox(height: 14),
          // Rider info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.person, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Rider: Ali Shan (0321-4918231) • Honda CD 70',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Calling Rider Ali Shan (+92 321 4918231)...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(IconData icon, String label, bool isDone, {bool isActive = false}) {
    Color bg = isDone ? (isActive ? const Color(0xFFF59E0B) : AppTheme.primary) : AppTheme.border;
    Color fg = isDone ? Colors.white : AppTheme.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: Icon(icon, size: 14, color: fg),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? const Color(0xFFB45309) : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 3,
        color: isDone ? AppTheme.primary : AppTheme.border,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ORDER HISTORY & DAIG BOOKINGS
  // ---------------------------------------------------------------------------
  Widget _buildOrderHistorySection() {
    final allOrders = widget.userState.orders;
    final filteredOrders = allOrders.where((order) {
      if (_orderFilter == 'Food') return !order.isDaigBooking;
      if (_orderFilter == 'Daig') return order.isDaigBooking;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Orders & Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            // Filter chips
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildFilterTabChip('All', _orderFilter == 'All'),
                  _buildFilterTabChip('Food', _orderFilter == 'Food'),
                  _buildFilterTabChip('Daig 🍲', _orderFilter == 'Daig'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (filteredOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                'No orders found under this category.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildOrderCard(filteredOrders[index]);
            },
          ),
      ],
    );
  }

  Widget _buildFilterTabChip(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (label.startsWith('Daig')) {
            _orderFilter = 'Daig';
          } else {
            _orderFilter = label;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(UserOrder order) {
    final isDelivered = order.status == 'Delivered';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  order.restaurantImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: AppTheme.primaryLight,
                    child: Icon(
                      order.isDaigBooking ? Icons.soup_kitchen : Icons.restaurant,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.restaurantName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.isDaigBooking) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SHAHI DEG',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${order.id} • ${_formatDate(order.orderDate)}',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDelivered ? Icons.check_circle : Icons.access_time_filled,
                      size: 13,
                      color: isDelivered ? const Color(0xFF059669) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDelivered ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 10),
          // Items
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 7, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (order.occasion != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🎉 Occasion: ${order.occasion}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C3CE9),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Bottom row: Total & Reorder Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text(
                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (order.rating != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        children: List.generate(
                          order.rating!,
                          (i) => const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _handleReorder(order);
                    },
                    icon: const Icon(Icons.repeat, size: 14),
                    label: const Text('Reorder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVED ADDRESSES SECTION
  // ---------------------------------------------------------------------------
  Widget _buildSavedAddressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved Delivery Addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddNewAddressDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.userState.addresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final addr = widget.userState.addresses[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: addr.isDefault ? AppTheme.primary : AppTheme.border,
                  width: addr.isDefault ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: addr.isDefault ? AppTheme.primaryLight : AppTheme.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      addr.label.toLowerCase().contains('home')
                          ? Icons.home_rounded
                          : addr.label.toLowerCase().contains('office')
                              ? Icons.apartment_rounded
                              : Icons.location_on_rounded,
                      color: addr.isDefault ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              addr.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${addr.fullAddress}, ${addr.city}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!addr.isDefault)
                    TextButton(
                      onPressed: () {
                        widget.userState.setDefaultAddress(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${addr.label}" set as default delivery address.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Set Default', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VOUCHERS & PROMOS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildVouchersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Coupons & Food Discounts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.userState.vouchers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final v = widget.userState.vouchers[index];
              return Container(
                width: 250,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: v.isExclusive
                      ? const LinearGradient(
                          colors: [Color(0xFF2E1065), Color(0xFF6C3CE9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: v.isExclusive ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: v.isExclusive ? Colors.transparent : AppTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          v.discount,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: v.isExclusive ? const Color(0xFFFBBF24) : AppTheme.primary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: v.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied code "${v.code}" to clipboard!'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: v.isExclusive
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  v.code,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: v.isExclusive ? Colors.white : AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy,
                                  size: 11,
                                  color: v.isExclusive ? Colors.white : AppTheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      v.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: v.isExclusive ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${v.minSpend} • ${v.expiry}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: v.isExclusive ? Colors.white.withValues(alpha: 0.75) : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SETTINGS & SUPPORT SECTION
  // ---------------------------------------------------------------------------
  Widget _buildSettingsAndSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.support_agent_rounded,
            title: 'FoodCourt Live Customer Support',
            subtitle: 'Help with active orders & Daig preparation',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting to FoodCourt WhatsApp & Helpline (042-111-366-366)...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildActionTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notification Preferences',
            subtitle: 'Order updates, SMS alerts & Daig status',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications are currently active for all orders.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildActionTile(
            icon: Icons.shield_outlined,
            title: 'Privacy & Food Safety Standards',
            subtitle: '100% Halal certified kitchens & sealed delivery',
            onTap: () {},
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildActionTile(
            icon: Icons.logout,
            title: 'Sign Out / Log Out',
            subtitle: 'Switch accounts or sign in as another user',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: _showLogoutConfirmDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: titleColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGS & ACTIONS
  // ---------------------------------------------------------------------------
  void _showEditProfileDialog(UserProfile user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final cityCtrl = TextEditingController(text: user.city);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City / Location',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.userState.updateProfile(
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  city: cityCtrl.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!'), behavior: SnackBarBehavior.floating),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showTopUpWalletDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Up Wallet Balance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a quick reload amount to instantly add credits to your FoodCourt wallet.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildQuickTopUpButton(ctx, 500),
                  const SizedBox(width: 10),
                  _buildQuickTopUpButton(ctx, 1000),
                  const SizedBox(width: 10),
                  _buildQuickTopUpButton(ctx, 2500),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickTopUpButton(BuildContext ctx, double amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          widget.userState.addFunds(amount);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added Rs. ${amount.toInt()} to your wallet balance!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF059669),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          '+ Rs. ${amount.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 13),
        ),
      ),
    );
  }

  void _showAddNewAddressDialog() {
    final labelCtrl = TextEditingController(text: 'Home');
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Lahore');
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Add Delivery Address', style: TextStyle(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Label (e.g. Home, Office, Gym)',
                        prefixIcon: Icon(Icons.bookmark_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Street Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isDefault,
                      onChanged: (val) {
                        setDialogState(() {
                          isDefault = val ?? false;
                        });
                      },
                      title: const Text('Set as default delivery address', style: TextStyle(fontSize: 13)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (addrCtrl.text.trim().isEmpty) return;
                    widget.userState.addAddress(
                      UserAddress(
                        label: labelCtrl.text.trim(),
                        fullAddress: addrCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        isDefault: isDefault,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New address saved successfully!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Address'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'Are you sure you want to sign out? You can sign back in at any time with any email and password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.userState.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _handleReorder(UserOrder order) {
    if (widget.cartState != null) {
      // Re-add items to cart
      final restId = order.id;
      final restName = order.restaurantName;
      for (final item in order.items) {
        widget.cartState!.addItem(
          FoodItem(
            id: 'reorder-${DateTime.now().millisecondsSinceEpoch}-${item.hashCode}',
            restaurantId: restId,
            name: item,
            description: 'Reordered from $restName',
            price: order.totalAmount / (order.items.isEmpty ? 1 : order.items.length),
            imageUrl: order.restaurantImage,
            category: order.isDaigBooking ? 'Deg' : 'Food',
            rating: 4.8,
          ),
          restId,
          restName,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Items from ${order.restaurantName} added to your cart!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reorder prepared for ${order.restaurantName}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
