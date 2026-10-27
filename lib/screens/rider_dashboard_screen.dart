import 'package:flutter/material.dart';
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

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentBottomNavIndex = 0; // 0: Home/Dashboard, 1: Rides, 2: Profile
  late TabController _ridesTabController;
  String? _expandedMapOrderId;

  @override
  void initState() {
    super.initState();
    _ridesTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ridesTabController.dispose();
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
            o.status == 'Preparing' ||
            o.status == 'On the Way').toList();
        final completedOrders = allOrders.where((o) => o.status == 'Delivered').toList();

        final totalCompletedCount = completedOrders.length;
        final totalPendingCount = pendingOrders.length;
        final totalEarnings = (totalCompletedCount * 180) + 450;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: _buildAppBar(),
          body: IndexedStack(
            index: _currentBottomNavIndex,
            children: [
              // Tab 0: Home / Analytics Dashboard
              _buildHomeDashboardTab(
                pendingCount: totalPendingCount,
                completedCount: totalCompletedCount,
                earnings: totalEarnings,
                pendingOrders: pendingOrders,
              ),

              // Tab 1: Rides (Top TabBar with 2 tabs: Pending & Completed)
              _buildRidesTab(
                pendingOrders: pendingOrders,
                completedOrders: completedOrders,
              ),

              // Tab 2: Profile & Edit Profile
              _buildProfileTab(
                completedCount: totalCompletedCount,
                earnings: totalEarnings,
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(
            pendingBadge: totalPendingCount,
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
    required int pendingCount,
    required int completedCount,
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
                'Performance Analytics',
                style: TextStyle(
                  fontSize: 17,
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
              // Completed Orders Card (Requested prominently)
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Orders Completed',
                  value: '$completedCount',
                  subtitle: 'Total Successful Drops',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  bgColor: Colors.green.shade50,
                  badgeText: '+100% on-time',
                ),
              ),
              const SizedBox(width: 12),
              // Pending/Active Runs Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Pending Rides',
                  value: '$pendingCount',
                  subtitle: 'In Kitchen & Transit',
                  icon: Icons.sports_motorsports_rounded,
                  color: Colors.orange.shade800,
                  bgColor: Colors.orange.shade50,
                  badgeText: 'Action required',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // Total Earnings Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Rider Earnings',
                  value: 'Rs. $earnings',
                  subtitle: 'Base Pay + Drop Bonus',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF1B2A4A),
                  bgColor: const Color(0xFFE8EEF8),
                  badgeText: 'Weekly payout',
                ),
              ),
              const SizedBox(width: 12),
              // Customer Satisfaction Card
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Customer Reviews',
                  value: '4.9 ⭐',
                  subtitle: 'Based on 184 drops',
                  icon: Icons.thumb_up_alt_rounded,
                  color: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  badgeText: 'Top Performer',
                ),
              ),
            ],
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
  // TAB 1: RIDES (TOP TABBAR: PENDING RIDES & COMPLETED RIDES)
  // ----------------------------------------------------
  Widget _buildRidesTab({
    required List<UserOrder> pendingOrders,
    required List<UserOrder> completedOrders,
  }) {
    return Column(
      children: [
        // Top 2 Tabs Header (Requested: "rider pages me oper 2 tab or 1 for pending rides second for completed")
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _ridesTabController,
            labelColor: const Color(0xFF1B2A4A),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF1B2A4A),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Pending Rides (${pendingOrders.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Completed (${completedOrders.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _ridesTabController,
            children: [
              // Sub Tab 1: Pending Rides
              _buildPendingRidesList(pendingOrders),

              // Sub Tab 2: Completed Rides
              _buildCompletedRidesList(completedOrders),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRidesList(List<UserOrder> pendingOrders) {
    if (pendingOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.done_all_rounded, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                'No Pending Deliveries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'You have completed all active deliveries! New incoming requests will notify you here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: pendingOrders.length,
      itemBuilder: (context, index) {
        return _buildPendingOrderCard(pendingOrders[index]);
      },
    );
  }

  Widget _buildCompletedRidesList(List<UserOrder> completedOrders) {
    if (completedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                'No Completed Orders Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Once you deliver pending orders, your history and earned delivery fees will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: completedOrders.length,
      itemBuilder: (context, index) {
        return _buildCompletedOrderCard(completedOrders[index]);
      },
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
                const Spacer(),
                Text(
                  'Collect: Rs. ${order.totalAmount.toInt()}',
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
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                        label: const Text('Start Run & GPS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    else if (isOnTheWay) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          await MapLauncherService.launchRiderNavigation(
                            lat: order.latitude,
                            lng: order.longitude,
                            fallbackAddress: order.deliveryAddress,
                          );
                        },
                        icon: const Icon(Icons.navigation_rounded, size: 14, color: Color(0xFF1A73E8)),
                        label: const Text('GPS', style: TextStyle(fontSize: 11, color: Color(0xFF1A73E8))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A73E8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 5),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.deepPurple.shade700),
                            const SizedBox(width: 4),
                            Text('At Doorstep', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
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
          // Tab 1: Home / Dashboard
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF1B2A4A)),
            label: 'Home',
          ),

          // Tab 2: Rides (with badge for pending orders)
          NavigationDestination(
            icon: Badge(
              label: Text('$pendingBadge'),
              isLabelVisible: pendingBadge > 0,
              backgroundColor: Colors.orange.shade800,
              textColor: Colors.white,
              child: const Icon(Icons.two_wheeler_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$pendingBadge'),
              isLabelVisible: pendingBadge > 0,
              backgroundColor: Colors.orange.shade800,
              textColor: Colors.white,
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF1B2A4A)),
            ),
            label: 'Rides',
          ),

          // Tab 3: Profile
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1B2A4A)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
