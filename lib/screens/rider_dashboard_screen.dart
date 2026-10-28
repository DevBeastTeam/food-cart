import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/map_launcher_service.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/rider_google_map_view.dart';

class RiderDashboardScreen extends StatefulWidget {
  final UserState userState;
  final VoidCallback? onSwitchToCustomer;

  const RiderDashboardScreen({
    super.key,
    required this.userState,
    this.onSwitchToCustomer,
  });

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _currentBottomNavIndex = 0; // 0: Analytics, 1: Recent Orders, 2: Completed Orders, 3: Profile
  String? _expandedMapOrderId;
  String _completedFilter = 'All'; // 'All', 'Delivered', 'Cancelled'
  Timer? _riderRefreshTimer;

  @override
  void initState() {
    super.initState();
    ApiService.instance.syncOrdersOnly(userState: widget.userState);
    _riderRefreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        ApiService.instance.syncOrdersOnly(userState: widget.userState);
      }
    });
  }

  @override
  void dispose() {
    _riderRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final allOrders = widget.userState.orders;
        final pendingOrders = allOrders.where((o) =>
            o.status == 'Accepted' ||
            o.status == 'Preparing').toList();
        final inProcessOrders = allOrders.where((o) =>
            o.status == 'On the Way' ||
            o.status == 'Arrived').toList();
        final activeOrders = allOrders.where((o) =>
            o.status != 'Delivered' &&
            o.status != 'Cancelled').toList();
        final completedOrders = allOrders.where((o) => o.status == 'Delivered').toList();
        final rejectedOrders = allOrders.where((o) => o.status == 'Cancelled').toList();

        final totalCompletedCount = completedOrders.length;
        final totalPendingCount = pendingOrders.length;
        final totalInProcessCount = inProcessOrders.length;
        final totalRejectedCount = rejectedOrders.length;
        final totalActiveCount = activeOrders.length;

        final double totalCODCollected = completedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        final double totalRejectedAmount = rejectedOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
        final totalEarnings = (totalCompletedCount * 180) + 450;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: _buildAppBar(),
          body: IndexedStack(
            index: _currentBottomNavIndex,
            children: [
              // Tab 0: Analytics Dashboard
              _buildHomeDashboardTab(
                totalOrdersCount: allOrders.length,
                pendingCount: totalPendingCount,
                inProcessCount: totalInProcessCount,
                completedCount: totalCompletedCount,
                rejectedCount: totalRejectedCount,
                totalCODCollected: totalCODCollected,
                earnings: totalEarnings,
                pendingOrders: activeOrders,
              ),

              // Tab 1: Recent / Active Orders
              _buildRecentOrdersTab(
                activeOrders: activeOrders,
              ),

              // Tab 2: Completed & Rejected Orders Hub
              _buildCompletedOrdersTab(
                completedOrders: completedOrders,
                rejectedOrders: rejectedOrders,
                totalCODCollected: totalCODCollected,
                totalRejectedAmount: totalRejectedAmount,
              ),

              // Tab 3: Profile & Edit Profile
              _buildProfileTab(
                completedCount: totalCompletedCount,
                earnings: totalEarnings,
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(
            pendingBadge: totalActiveCount,
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // APP BAR
  // ----------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    final isOnline = widget.userState.riderIsOnline;

    return AppBar(
      backgroundColor: const Color(0xFF1B2A4A),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userState.riderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '📍 ${widget.userState.riderOutletName} • ${widget.userState.riderVehicle}',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Online / Offline Switch
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Center(
            child: InkWell(
              onTap: () {
                final newStatus = !isOnline;
                widget.userState.setRiderOnlineStatus(newStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newStatus
                          ? 'You are now ONLINE and ready for deliveries!'
                          : 'Shift paused: You are OFFLINE',
                    ),
                    backgroundColor: newStatus ? Colors.green.shade700 : Colors.grey.shade800,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green.shade600 : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (val) {
            if (val == 'customer') {
              if (widget.onSwitchToCustomer != null) {
                widget.onSwitchToCustomer!();
              } else {
                widget.userState.setRole(UserRole.client);
              }
            } else if (val == 'logout') {
              widget.userState.logout();
            } else if (val == 'edit_profile') {
              setState(() => _currentBottomNavIndex = 2);
              _showEditProfileModal(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit_profile',
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit Rider Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'customer',
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text('Switch to Customer App'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout Rider'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 0: HOME / DASHBOARD & ANALYTICS
  // ----------------------------------------------------
  Widget _buildHomeDashboardTab({
    required int totalOrdersCount,
    required int pendingCount,
    required int inProcessCount,
    required int completedCount,
    required int rejectedCount,
    required double totalCODCollected,
    required int earnings,
    required List<UserOrder> pendingOrders,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Card with Shift Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2A4A), Color(0xFF2C3E6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2A4A).withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          widget.userState.riderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.black87),
                          SizedBox(width: 4),
                          Text(
                            '4.9 Rating',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickMetric(
                      label: 'Today Goal',
                      value: '$completedCount / 10',
                      subtext: '80% complete',
                    ),
                    _buildQuickMetric(
                      label: 'Acceptance',
                      value: '98%',
                      subtext: 'High Priority',
                    ),
                    _buildQuickMetric(
                      label: 'Distance',
                      value: '26.8 km',
                      subtext: 'Fuel saving route',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withAlpha(35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.soup_kitchen_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ASSIGNED OUTLET / PAKWAN CENTER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              widget.userState.riderOutletName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CONNECTED',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Analytics Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance Analytics (اینالیٹکس)',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live Sync',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Grid of Main Analytics Cards
          Row(
            children: [
              // Completed Orders Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'مکمل شدہ (Completed)',
                  value: '$completedCount',
                  subtitle: 'Delivered Drops',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  badgeText: '100% on-time',
                ),
              ),
              const SizedBox(width: 12),
              // In-Process Runs Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'پروسیس میں (In-Process)',
                  value: '$inProcessCount',
                  subtitle: 'On the Way / Arrived',
                  icon: Icons.two_wheeler_rounded,
                  color: Colors.blue.shade700,
                  bgColor: Colors.blue.shade50,
                  badgeText: 'En Route',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // Pending Orders Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'پینڈنگ (Pending)',
                  value: '$pendingCount',
                  subtitle: 'Awaiting Pickup',
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.orange.shade800,
                  bgColor: Colors.orange.shade50,
                  badgeText: 'Kitchen Prep',
                ),
              ),
              const SizedBox(width: 12),
              // Rejected Orders Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'ریجیکٹ شدہ (Rejected)',
                  value: '$rejectedCount',
                  subtitle: 'Cancelled Runs',
                  icon: Icons.cancel_rounded,
                  color: Colors.red.shade700,
                  bgColor: Colors.red.shade50,
                  badgeText: 'Cancelled',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Cash on Delivery Card (COD Collected)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade900, Colors.amber.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade900.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'کیش آن ڈیلیوری وصول شدہ رقم (COD Collected)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${totalCODCollected.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Total Cash In Hand to settle with vendor',
                        style: TextStyle(color: Colors.white60, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 4. Weekly Deliveries Analytics Visual Bar Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Completed Orders (Last 7 Days)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Avg: 6.4 / day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWeeklyBarChart(completedCount),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 5. Live Google Map Radar Preview Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF1A73E8)),
                  SizedBox(width: 6),
                  Text(
                    'Live Google Map Radar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  _showFullScreenMapModal(
                    context,
                    order: pendingOrders.isNotEmpty ? pendingOrders.first : null,
                  );
                },
                icon: const Icon(Icons.fullscreen, size: 16),
                label: const Text('Full Screen Map', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Map Preview Widget
          SizedBox(
            height: 210,
            child: RiderGoogleMapView(
              order: pendingOrders.isNotEmpty ? pendingOrders.first : null,
              isFullScreen: false,
            ),
          ),

          const SizedBox(height: 14),

          // Action button to jump to active rides
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _currentBottomNavIndex = 1);
              },
              icon: const Icon(Icons.two_wheeler_rounded, size: 18),
              label: Text('Go to Rides Tab ($pendingCount Pending)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2A4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(subtext, style: const TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(int todayCompleted) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
    final counts = [5, 7, 4, 8, 9, 6, todayCompleted.clamp(1, 15)];
    final maxCount = 12;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (index) {
        final count = counts[index];
        final isToday = index == 6;
        final heightFactor = (count / maxCount).clamp(0.15, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                color: isToday ? const Color(0xFF1B2A4A) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: 70 * heightFactor,
              decoration: BoxDecoration(
                color: isToday ? Colors.amber.shade600 : const Color(0xFF1B2A4A).withAlpha(190),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              days[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                color: isToday ? AppTheme.textPrimary : Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ----------------------------------------------------
  // TAB 1: RECENT / ACTIVE ORDERS
  // ----------------------------------------------------
  Widget _buildRecentOrdersTab({required List<UserOrder> activeOrders}) {
    if (activeOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                'کوئی ایکٹو آرڈر موجود نہیں',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'جب وینڈر آپ کے ذمے کوئی نیا آرڈر لگائے گا، وہ فوری طور پر یہاں نظر آئے گا۔',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        return _buildPendingOrderCard(activeOrders[index]);
      },
    );
  }

  // ----------------------------------------------------
  // TAB 2: COMPLETED & REJECTED ORDERS HUB
  // ----------------------------------------------------
  Widget _buildCompletedOrdersTab({
    required List<UserOrder> completedOrders,
    required List<UserOrder> rejectedOrders,
    required double totalCODCollected,
    required double totalRejectedAmount,
  }) {
    List<UserOrder> displayList;
    if (_completedFilter == 'Delivered') {
      displayList = completedOrders;
    } else if (_completedFilter == 'Cancelled') {
      displayList = rejectedOrders;
    } else {
      displayList = [...completedOrders, ...rejectedOrders]..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Top 2 Summary Cards (Requested: Total completed & prices, Total rejected & prices)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 16),
                        const SizedBox(width: 6),
                        const Text('مکمل شدہ (Completed)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${completedOrders.length} آرڈرز', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('COD: Rs. ${totalCODCollected.toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green.shade800)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cancel_rounded, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 6),
                        const Text('ریجیکٹ شدہ (Rejected)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${rejectedOrders.length} آرڈرز', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Rs. ${totalRejectedAmount.toInt()} ضائع', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Filter chips: All, Delivered, Cancelled
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChoice('All', 'سب (${completedOrders.length + rejectedOrders.length})'),
              const SizedBox(width: 8),
              _buildFilterChoice('Delivered', 'مکمل شدہ (${completedOrders.length})'),
              const SizedBox(width: 8),
              _buildFilterChoice('Cancelled', 'ریجیکٹ شدہ (${rejectedOrders.length})'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (displayList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text('کوئی ہسٹری موجود نہیں (No History)', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          )
        else
          ...displayList.map(_buildCompletedOrderCard),
      ],
    );
  }

  Widget _buildFilterChoice(String value, String label) {
    final isSelected = _completedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _completedFilter = value),
      selectedColor: const Color(0xFF1B2A4A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF1B2A4A) : AppTheme.border),
      ),
    );
  }

  void _showRejectOrderDialog(UserOrder order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            const Text('ریجیکٹ آرڈر (Reject Order)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('کیا آپ آرڈر #${order.id} کو ریجیکٹ کرنا چاہتے ہیں؟', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('ریجیکٹ کرنے کی وجہ درج کریں (Reason):', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'مثلاً بائیک پنکچر، ایریا کوریج سے باہر',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('کینسل'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              widget.userState.rejectOrder(order.id, reason: reason.isNotEmpty ? reason : 'Rider cancelled');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.id} ریجیکٹ کر دیا گیا ہے'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ریجیکٹ کریں (Confirm)'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PENDING ORDER CARD (With Google Map Route button & preview)
  // ----------------------------------------------------
  Widget _buildPendingOrderCard(UserOrder order) {
    final isOnTheWay = order.status == 'On the Way';
    final isArrived = order.status == 'Arrived';
    final isMapExpanded = _expandedMapOrderId == order.id;

    Color statusColor = isArrived
        ? Colors.deepPurple.shade700
        : (isOnTheWay ? Colors.blue.shade700 : Colors.orange.shade800);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isArrived
              ? Colors.deepPurple.shade600
              : (isOnTheWay ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
          width: (isOnTheWay || isArrived) ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isArrived
                    ? Colors.deepPurple.shade700
                    : (isOnTheWay ? const Color(0xFF2563EB) : Colors.black))
                .withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: order.isPakwan ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: order.isPakwan ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(
                    order.isPakwan ? '🍲 شاہی پکوان' : '🍽️ ریسٹورنٹ',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: order.isPakwan ? const Color(0xFF92400E) : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '💵 COD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Rs. ${order.totalAmount.toInt()}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Pickup Point (Central Kitchen / Restaurant)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.storefront_rounded, size: 14, color: Colors.amber.shade900),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PICKUP POINT (Central Kitchen)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            order.restaurantName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Text(
                            '14-C Main Boulevard, Gulberg III, Lahore',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, size: 18, color: AppTheme.primary),
                      tooltip: 'Call Kitchen Manager',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling FoodCourt Central Kitchen: +92 42 111-CRAVEE')),
                        );
                      },
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 13, top: 2, bottom: 2),
                  child: SizedBox(
                    height: 14,
                    child: VerticalDivider(thickness: 1.5, color: AppTheme.border),
                  ),
                ),

                // 2. Dropoff Destination (Customer)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_on_rounded, size: 14, color: Colors.green.shade800),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DROP OFF DESTINATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            order.customerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            order.address,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Starting GPS route to ${order.customerName}... 🛵'),
                                  backgroundColor: const Color(0xFF1A73E8),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              await MapLauncherService.launchRiderNavigation(
                                lat: order.latitude,
                                lng: order.longitude,
                                fallbackAddress: order.address,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF8AB4F8)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions_rounded, size: 14, color: Color(0xFF1A73E8)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Open in Google Maps 🗺️',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (order.eventDate != null && order.eventDate!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFFD97706)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ڈیلیوری وقت: ${order.eventDate}${order.eventTime != null && order.eventTime!.isNotEmpty ? " @ ${order.eventTime}" : ""}${order.occasion != null && order.occasion!.isNotEmpty ? " (${order.occasion})" : ""}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (order.notes != null && order.notes!.isNotEmpty)
                            Text(
                              'Instruction: "${order.notes}"',
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk, size: 18, color: Colors.green),
                      tooltip: 'Call Customer',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${order.customerName}: ${order.customerPhone}')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3. GOOGLE MAP BUTTON & PREVIEW
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.map_rounded, size: 18, color: Color(0xFF1A73E8)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Google Maps GPS Route',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _expandedMapOrderId = isMapExpanded ? null : order.id;
                              });
                            },
                            icon: Icon(
                              isMapExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                            ),
                            label: Text(
                              isMapExpanded ? 'Hide Map' : 'View Route',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1A73E8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showFullScreenMapModal(context, order: order),
                            icon: const Icon(Icons.open_in_full_rounded, size: 16, color: Color(0xFF1A73E8)),
                            tooltip: 'Full Screen GPS',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      // If Map is expanded in this card
                      if (isMapExpanded) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: RiderGoogleMapView(order: order, isFullScreen: false),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 10),

                // Items summary
                Row(
                  children: [
                    const Icon(Icons.fastfood_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.items.join(', '),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Dedicated "Ride by Google Map" Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Launching Google Maps Navigation for Order #${order.id}... 🛵'),
                          backgroundColor: const Color(0xFF1A73E8),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      await MapLauncherService.launchRiderNavigation(
                        lat: order.latitude,
                        lng: order.longitude,
                        fallbackAddress: order.deliveryAddress,
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Ride by Google Map (گوگل میپ پر لوکیشن) 🛵',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Rider Actions Bar
                Row(
                  children: [
                    // Status Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: order.status,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.primary),
                            items: const [
                              DropdownMenuItem(value: 'Accepted', child: Text('Accepted', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Preparing', child: Text('Preparing in Kitchen', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'On the Way', child: Text('On the Way (En Route)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                              DropdownMenuItem(value: 'Arrived', child: Text('Rider Arrived 📍', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B21A8)))),
                              DropdownMenuItem(value: 'Delivered', child: Text('Delivered & Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                            ],
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                widget.userState.updateOrderStatus(order.id, newStatus);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order #${order.id} status updated to "$newStatus"')),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Primary Action Button
                    if (!isOnTheWay && !isArrived)
                      ElevatedButton.icon(
                        onPressed: () async {
                          widget.userState.updateOrderStatus(order.id, 'On the Way');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order #${order.id} started! Launching Google Maps Turn-by-Turn GPS...'),
                              backgroundColor: const Color(0xFF1A73E8),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          await MapLauncherService.launchRiderNavigation(
                            lat: order.latitude,
                            lng: order.longitude,
                            fallbackAddress: order.deliveryAddress,
                          );
                        },
                        icon: const Icon(Icons.two_wheeler, size: 16),
                        label: const Text('Start Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else if (isOnTheWay) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.userState.updateOrderStatus(order.id, 'Arrived');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Customer notified: Rider has Arrived at location for Order #${order.id}! 📍'),
                              backgroundColor: Colors.deepPurple.shade700,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.pin_drop_rounded, size: 14),
                        label: const Text('Arrived 📍', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.userState.updateOrderStatus(order.id, 'Delivered');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order #${order.id} marked Delivered! Cash of Rs. ${order.totalAmount.toInt()} collected.'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 15),
                        label: const Text('Done', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ] else ...[
                      // isArrived
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.userState.updateOrderStatus(order.id, 'Delivered');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Order #${order.id} marked Delivered! Cash of Rs. ${order.totalAmount.toInt()} collected.'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Delivered & Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],

                    const SizedBox(width: 6),
                    // Reject Button
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                      tooltip: 'Reject Order',
                      onPressed: () => _showRejectOrderDialog(order),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // COMPLETED ORDER CARD
  // ----------------------------------------------------
  Widget _buildCompletedOrderCard(UserOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DELIVERED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          order.address,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs. ${order.totalAmount.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const Text(
                          'Rider Fee: Rs. 180',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    const Text(
                      'Customer Rating: 5.0 ⭐',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      'Paid via Cash on Delivery',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: PROFILE & EDIT PROFILE
  // ----------------------------------------------------
  Widget _buildProfileTab({
    required int completedCount,
    required int earnings,
  }) {
    final isOnline = widget.userState.riderIsOnline;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // Rider Avatar Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFF1B2A4A),
                      backgroundImage: const NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.userState.riderName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified FoodCourt Captain • ⭐ 4.9',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isOnline ? Colors.green.shade300 : Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green.shade600 : Colors.grey.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'SHIFT ACTIVE (ONLINE)' : 'SHIFT PAUSED (OFFLINE)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isOnline ? Colors.green.shade800 : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // EDIT PROFILE BUTTON (Requested: "roder side mn rider apna profile edit kr skyn")
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditProfileModal(context),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Rider Profile', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Assigned Pakwan Center / Outlet Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.soup_kitchen_rounded, color: Colors.orange, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AFFILIATED OUTLET / PAKWAN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  widget.userState.riderOutletName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.userState.riderOutletType.toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.userState.riderOutletAddress,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 15, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kitchen Manager: ${widget.userState.riderOutletPhone}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Profile Details Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rider Details & Credentials',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileDetailRow(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: widget.userState.riderName,
                ),
                const Divider(height: 16),
                _buildProfileDetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Contact Phone',
                  value: widget.userState.riderPhone,
                ),
                const Divider(height: 16),
                _buildProfileDetailRow(
                  icon: Icons.two_wheeler_outlined,
                  label: 'Vehicle Model & Plate',
                  value: widget.userState.riderVehicle,
                ),
                const Divider(height: 16),
                _buildProfileDetailRow(
                  icon: Icons.badge_outlined,
                  label: 'CNIC / National ID',
                  value: widget.userState.riderCnic,
                ),
                const Divider(height: 16),
                _buildProfileDetailRow(
                  icon: Icons.location_city_outlined,
                  label: 'City & Delivery Zone',
                  value: widget.userState.riderCity,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Verification Badges
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified Documents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildVerifiedBadge('Valid Driving License', 'Verified ✔'),
                const SizedBox(height: 6),
                _buildVerifiedBadge('Vehicle Registration Book', 'Verified ✔'),
                const SizedBox(height: 6),
                _buildVerifiedBadge('Police Verification Certificate', 'Verified ✔'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick actions
          OutlinedButton.icon(
            onPressed: () {
              if (widget.onSwitchToCustomer != null) {
                widget.onSwitchToCustomer!();
              } else {
                widget.userState.setRole(UserRole.client);
              }
            },
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: const Text('Switch to Customer App'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => widget.userState.logout(),
            icon: const Icon(Icons.logout, size: 16, color: Colors.red),
            label: const Text('Logout Rider Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // EDIT PROFILE MODAL (Requested: Rider apna profile edit kr sky)
  // ----------------------------------------------------
  void _showEditProfileModal(BuildContext context) {
    final nameController = TextEditingController(text: widget.userState.riderName);
    final phoneController = TextEditingController(text: widget.userState.riderPhone);
    final vehicleController = TextEditingController(text: widget.userState.riderVehicle);
    final cityController = TextEditingController(text: widget.userState.riderCity);
    final cnicController = TextEditingController(text: widget.userState.riderCnic);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Rider Profile',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Rider Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle
                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle & Number Plate (e.g. Honda 125 - LED-4921)',
                    prefixIcon: Icon(Icons.two_wheeler),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // City / Zone
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City & Operating Area (e.g. Lahore - Gulberg)',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // CNIC
                TextField(
                  controller: cnicController,
                  decoration: const InputDecoration(
                    labelText: 'CNIC / National ID',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 18),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final vehicle = vehicleController.text.trim();
                      final city = cityController.text.trim();
                      final cnic = cnicController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid rider name')),
                        );
                        return;
                      }

                      widget.userState.updateRiderProfile(
                        name: name,
                        phone: phone,
                        vehicle: vehicle,
                        city: city,
                        cnic: cnic,
                      );

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rider Profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // FULL SCREEN GOOGLE MAP MODAL
  // ----------------------------------------------------
  void _showFullScreenMapModal(BuildContext context, {UserOrder? order}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.94,
          child: RiderGoogleMapView(
            order: order,
            isFullScreen: true,
            onClose: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // BOTTOM NAVIGATION BAR (Requested: 3 tabs - Home/Dashboard, Rides, Profile)
  // ----------------------------------------------------
  Widget _buildBottomNavigationBar({required int pendingBadge}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentBottomNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentBottomNavIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1B2A4A).withAlpha(30),
        destinations: [
          // Tab 0: Analytics
          const NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF1B2A4A)),
            label: 'اینالیٹکس',
          ),

          // Tab 1: Recent Orders
          NavigationDestination(
            icon: Badge(
              label: Text('$pendingBadge'),
              isLabelVisible: pendingBadge > 0,
              backgroundColor: Colors.orange.shade800,
              textColor: Colors.white,
              child: const Icon(Icons.delivery_dining_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$pendingBadge'),
              isLabelVisible: pendingBadge > 0,
              backgroundColor: Colors.orange.shade800,
              textColor: Colors.white,
              child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF1B2A4A)),
            ),
            label: 'ریسنت آرڈرز',
          ),

          // Tab 2: Completed Orders
          const NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded, color: Color(0xFF1B2A4A)),
            label: 'مکمل شدہ',
          ),

          // Tab 3: Profile
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1B2A4A)),
            label: 'پروفائل',
          ),
        ],
      ),
    );
  }
}
