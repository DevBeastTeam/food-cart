import 'package:flutter/material.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/rider_map_preview.dart';

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
  int _selectedBottomNavIndex = 0;
  bool _isOnline = true;
  String _activeFilter = 'All'; // 'All', 'On the Way', 'Preparing', 'Accepted'

  // Controllers for Profile Edit
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleController;

  // Controllers for Password Change
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userState.riderName);
    _phoneController = TextEditingController(text: widget.userState.riderPhone);
    _vehicleController = TextEditingController(text: widget.userState.riderVehicle);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final allOrders = widget.userState.orders;
        final uncompletedOrders = allOrders.where((o) => o.status != 'Delivered' && o.status != 'Cancelled').toList();
        final completedOrders = allOrders.where((o) => o.status == 'Delivered').toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          appBar: _buildAppBar(),
          body: _buildCurrentTab(allOrders, uncompletedOrders, completedOrders),
          bottomNavigationBar: _buildBottomNavigationBar(uncompletedOrders.length, completedOrders.length),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    String title;
    switch (_selectedBottomNavIndex) {
      case 0:
        title = 'Rider Analytics';
        break;
      case 1:
        title = 'Active Rides';
        break;
      case 2:
        title = 'Completed Rides';
        break;
      case 3:
        title = 'Rider Profile';
        break;
      default:
        title = 'Rider Console';
    }

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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Fast Fleet • Lahore Central',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Online / Offline Switch
        Center(
          child: InkWell(
            onTap: () {
              setState(() => _isOnline = !_isOnline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isOnline ? 'You are now Online and receiving delivery requests' : 'Shift paused: You are now Offline',
                  ),
                  backgroundColor: _isOnline ? Colors.green.shade700 : Colors.grey.shade800,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.shade600 : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isOnline ? 'ONLINE' : 'OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Profile Avatar in AppBar (Click navigates to Profile tab as requested!)
        IconButton(
          tooltip: 'My Profile',
          onPressed: () {
            setState(() {
              _selectedBottomNavIndex = 3;
            });
          },
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: _selectedBottomNavIndex == 3 ? Colors.amber.shade400 : Colors.white24,
            child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
          ),
        ),

        // Overflow menu
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
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'customer',
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Switch to Customer App'),
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

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR (4 Buttons: Home, Rides, Completed, Profile)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar(int activeCount, int completedCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedBottomNavIndex,
        onDestinationSelected: _onBottomNavTapped,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1B2A4A).withAlpha(30),
        elevation: 0,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.analytics_outlined, color: Colors.black54),
            selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF1B2A4A)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.two_wheeler_outlined, color: Colors.black54),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF1B2A4A)),
            ),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: completedCount > 0,
              label: Text('$completedCount'),
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.check_circle_outline_rounded, color: Colors.black54),
            ),
            selectedIcon: Badge(
              isLabelVisible: completedCount > 0,
              label: Text('$completedCount'),
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.check_circle_rounded, color: Colors.green),
            ),
            label: 'Completed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Colors.black54),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1B2A4A)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB BODY SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildCurrentTab(List<UserOrder> allOrders, List<UserOrder> uncompletedOrders, List<UserOrder> completedOrders) {
    switch (_selectedBottomNavIndex) {
      case 0:
        return _buildHomeAnalyticsTab(allOrders, uncompletedOrders, completedOrders);
      case 1:
        return _buildActiveRidesTab(uncompletedOrders);
      case 2:
        return _buildCompletedRidesTab(completedOrders);
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeAnalyticsTab(allOrders, uncompletedOrders, completedOrders);
    }
  }

  // ===========================================================================
  // TAB 0: HOME / ANALYTICS
  // ===========================================================================
  Widget _buildHomeAnalyticsTab(List<UserOrder> allOrders, List<UserOrder> uncompletedOrders, List<UserOrder> completedOrders) {
    final acceptedCount = allOrders.where((o) => o.status == 'Accepted').length;
    final preparingCount = allOrders.where((o) => o.status == 'Preparing').length;
    final onTheWayCount = allOrders.where((o) => o.status == 'On the Way').length;
    final deliveredCount = completedOrders.length;
    final cancelledCount = allOrders.where((o) => o.status == 'Cancelled').length;
    final totalRidesCount = allOrders.length;
    final totalEarnings = (deliveredCount * 180) + 450; // Base pay + delivery incentives

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rider Greeting & Shift Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2A4A), Color(0xFF2E406A)],
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
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      backgroundImage: const NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
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
                                  widget.userState.riderName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '⭐ 4.9',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.userState.riderVehicle} • ${widget.userState.riderPhone}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),
                // Earnings Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TODAY'S PAYOUT",
                          style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. $totalEarnings',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedBottomNavIndex = 1; // Jump to Rides
                        });
                      },
                      icon: const Icon(Icons.two_wheeler, size: 16),
                      label: Text('Active Runs (${uncompletedOrders.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade400,
                        foregroundColor: Colors.black87,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Analytics Section Title
          const Row(
            children: [
              Icon(Icons.query_stats_rounded, size: 20, color: Color(0xFF1B2A4A)),
              SizedBox(width: 8),
              Text(
                'Ride Analytics & Metrics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid of Analytics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildMetricCard(
                title: 'Total Rides',
                value: '$totalRidesCount',
                subtitle: 'All assigned tasks',
                icon: Icons.all_inbox_rounded,
                color: const Color(0xFF1B2A4A),
                bgColor: const Color(0xFFF1F5F9),
              ),
              _buildMetricCard(
                title: 'Delivered',
                value: '$deliveredCount',
                subtitle: 'Completed drops',
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
              ),
              _buildMetricCard(
                title: 'Accepted',
                value: '$acceptedCount',
                subtitle: 'Queued orders',
                icon: Icons.thumb_up_alt_rounded,
                color: Colors.deepPurple,
                bgColor: Colors.deepPurple.shade50,
              ),
              _buildMetricCard(
                title: 'On the Way',
                value: '$onTheWayCount',
                subtitle: 'Current in-transit',
                icon: Icons.navigation_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
              ),
              _buildMetricCard(
                title: 'In Kitchen',
                value: '$preparingCount',
                subtitle: 'Being prepared',
                icon: Icons.soup_kitchen_rounded,
                color: Colors.orange.shade800,
                bgColor: Colors.orange.shade50,
              ),
              _buildMetricCard(
                title: 'Cancelled',
                value: '$cancelledCount',
                subtitle: 'Dropped / Void',
                icon: Icons.cancel_rounded,
                color: Colors.red.shade700,
                bgColor: Colors.red.shade50,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Efficiency & Quality Performance Indicators
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
                  'Fleet Performance Insights',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _buildProgressMetric(
                  label: 'Delivery Success Rate',
                  percentage: totalRidesCount > 0 ? (deliveredCount / (totalRidesCount - cancelledCount)).clamp(0.0, 1.0) : 0.96,
                  displayValue: '96.2%',
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _buildProgressMetric(
                  label: 'Customer Satisfaction Score',
                  percentage: 0.98,
                  displayValue: '4.9 / 5.0 ⭐',
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 12),
                _buildProgressMetric(
                  label: 'On-Time Dispatch Rate',
                  percentage: 0.92,
                  displayValue: '92.4%',
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Weekly Volume Bar Chart Simulation
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Deliveries Trend',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Avg 8 / day',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildDayBar('Mon', 7, false),
                    _buildDayBar('Tue', 9, false),
                    _buildDayBar('Wed', 6, false),
                    _buildDayBar('Thu', 11, false),
                    _buildDayBar('Fri', 14, false),
                    _buildDayBar('Sat', 16, true), // Weekend peak
                    _buildDayBar('Sun', 12, false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric({
    required String label,
    required double percentage,
    required String displayValue,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            Text(displayValue, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDayBar(String day, int count, bool isToday) {
    final double height = (count * 4.5).clamp(20.0, 80.0);
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isToday ? const Color(0xFF1B2A4A) : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF1B2A4A) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? const Color(0xFF1B2A4A) : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: ACTIVE / UNCOMPLETED RIDES
  // ===========================================================================
  Widget _buildActiveRidesTab(List<UserOrder> uncompletedOrders) {
    final filteredOrders = uncompletedOrders.where((o) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'On the Way') return o.status == 'On the Way';
      if (_activeFilter == 'Preparing') return o.status == 'Preparing';
      if (_activeFilter == 'Accepted') return o.status == 'Accepted';
      return true;
    }).toList();

    return Column(
      children: [
        // Sub-filter tabs
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActiveFilterChip('All', 'All Active (${uncompletedOrders.length})'),
                const SizedBox(width: 8),
                _buildActiveFilterChip('On the Way', 'On the Way (${uncompletedOrders.where((o) => o.status == 'On the Way').length})'),
                const SizedBox(width: 8),
                _buildActiveFilterChip('Preparing', 'Preparing (${uncompletedOrders.where((o) => o.status == 'Preparing').length})'),
                const SizedBox(width: 8),
                _buildActiveFilterChip('Accepted', 'Accepted (${uncompletedOrders.where((o) => o.status == 'Accepted').length})'),
              ],
            ),
          ),
        ),

        // List of Active Rides
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.two_wheeler_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Active Rides Available',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'All current orders have been delivered or there are no new orders matching this filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildActiveRideTile(filteredOrders[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2A4A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRideTile(UserOrder order) {
    final isOnTheWay = order.status == 'On the Way';
    Color badgeColor;
    if (isOnTheWay) {
      badgeColor = const Color(0xFF2563EB);
    } else if (order.status == 'Preparing') {
      badgeColor = Colors.orange.shade800;
    } else {
      badgeColor = Colors.deepPurple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnTheWay ? const Color(0xFF2563EB) : AppTheme.border,
          width: isOnTheWay ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnTheWay ? const Color(0xFF2563EB) : Colors.black).withAlpha(16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showRideDetailsBottomSheet(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Order ID, Status, Amount
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
                      color: badgeColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 12),

              // Route Preview: Pickup -> Dropoff
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Indicator
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 26,
                        color: const Color(0xFFCBD5E1),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup
                        Text(
                          'FROM: ${order.restaurantName}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        // Drop
                        Text(
                          'TO: ${order.customerName} • ${order.address}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Items summary & Action Row
              Row(
                children: [
                  const Icon(Icons.fastfood_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.items.join(', '),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showRideDetailsBottomSheet(order),
                    icon: const Icon(Icons.navigation_rounded, size: 14),
                    label: const Text('View & Route', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: COMPLETED RIDES (Checkmark Icon on Bottom Nav)
  // ===========================================================================
  Widget _buildCompletedRidesTab(List<UserOrder> completedOrders) {
    if (completedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 14),
              const Text(
                'No Completed Deliveries Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completed delivery runs will appear here with receipts, ratings, and route summaries.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedOrders.length,
      itemBuilder: (context, index) {
        final order = completedOrders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showCompletedRideDetailsSheet(order),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'DELIVERED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
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
                        'Paid Rs. ${order.totalAmount.toInt()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'To: ${order.customerName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Text(
                    order.address,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Picked from: ${order.restaurantName}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${order.rating ?? 5}.0',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showCompletedRideDetailsSheet(order),
                      icon: const Icon(Icons.map_outlined, size: 14),
                      label: const Text('View Location & Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: RIDER PROFILE (Manage Profile, Name, Password, Shift)
  // ===========================================================================
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Summary Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1B2A4A),
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.userState.riderName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'FoodCourt Delivery Partner • ID #R-4921',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Active Duty Verified Partner',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 1. Personal & Contact Info Edit Section
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
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Color(0xFF1B2A4A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Manage Personal Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Rider Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle & Plate Number',
                  prefixIcon: Icon(Icons.two_wheeler_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.userState.updateRiderProfile(
                      name: _nameController.text,
                      phone: _phoneController.text,
                      vehicle: _vehicleController.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rider profile details updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save Profile Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2A4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Password & Security Management Section
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
              const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: Color(0xFF1B2A4A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Change Password & Security',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_newPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a new password')),
                      );
                      return;
                    }
                    if (_newPasswordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Update Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Shift Settings & Quick Navigation
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shift & App Settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Duty Status (Online / Receiving Orders)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: Text(_isOnline ? 'Active on delivery roster' : 'Paused shift', style: const TextStyle(fontSize: 11)),
                  value: _isOnline,
                  onChanged: (val) {
                    setState(() => _isOnline = val);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: AppTheme.primary),
                  title: const Text('Switch to Customer Food App', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Order food or browse restaurants', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    if (widget.onSwitchToCustomer != null) {
                      widget.onSwitchToCustomer!();
                    } else {
                      widget.userState.setRole(UserRole.client);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout Rider Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    widget.userState.logout();
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // RIDE DETAILS BOTTOM SHEET (With Interactive Map & Navigation)
  // ===========================================================================
  void _showRideDetailsBottomSheet(UserOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isOnTheWay = order.status == 'On the Way';
            final isDelivered = order.status == 'Delivered';

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.96,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.id}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Status: ${order.status}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isOnTheWay ? const Color(0xFF2563EB) : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Text(
                                    'Collect: Rs. ${order.totalAmount.toInt()}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // DEMO MAP NAVIGATION PREVIEW WIDGET
                            const Text(
                              'Live Map Route & Navigation',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 220,
                              child: RiderMapPreview(
                                pickupAddress: order.restaurantName,
                                deliveryAddress: order.address,
                                customerName: order.customerName,
                                onOpenGoogleMaps: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.navigation_rounded, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text('Routing to: ${order.address} via Google Maps navigation'),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF1B2A4A),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Pickup Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 16, color: Colors.amber.shade900),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'PICKUP: RESTAURANT / KITCHEN',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.restaurantName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  const Text(
                                    '14-C Main Boulevard, Gulberg III, Lahore',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Calling Kitchen: +92 42 111-CRAVEE')),
                                          );
                                        },
                                        icon: const Icon(Icons.call, size: 14),
                                        label: const Text('Call Kitchen', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Dropoff Destination Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 16, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'DROP-OFF: CUSTOMER DESTINATION',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.customerName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    order.address,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                  ),
                                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Text(
                                        'Note: "${order.notes}"',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Calling customer ${order.customerName}: ${order.customerPhone}')),
                                          );
                                        },
                                        icon: const Icon(Icons.phone_in_talk, size: 14, color: Colors.green),
                                        label: const Text('Call Customer', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Items List
                            const Text(
                              'Order Items Checklist',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: order.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_box_outlined, size: 16, color: Color(0xFF1B2A4A)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Actions Bar: Update status
                            if (!isDelivered) ...[
                              Row(
                                children: [
                                  if (!isOnTheWay)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          widget.userState.updateOrderStatus(order.id, 'On the Way');
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Order #${order.id} marked as On the Way!'),
                                              backgroundColor: const Color(0xFF2563EB),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.two_wheeler, size: 18),
                                        label: const Text('Start Run (On the Way)'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          widget.userState.updateOrderStatus(order.id, 'Delivered');
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Order #${order.id} marked Delivered! Rs. ${order.totalAmount.toInt()} collected.'),
                                              backgroundColor: Colors.green.shade700,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                                        label: const Text('Mark Delivered & Collect Cash'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // COMPLETED RIDE DETAILS SHEET (With Receipt & Location Review)
  // ===========================================================================
  void _showCompletedRideDetailsSheet(UserOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        // Success Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery Successfully Completed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                    Text(
                                      'Order #${order.id} • Cash Collected: Rs. ${order.totalAmount.toInt()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Completed Route & Location Overview (Re-view location as requested)
                        const Text(
                          'Delivery Location & Completed Route',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: RiderMapPreview(
                            pickupAddress: order.restaurantName,
                            deliveryAddress: order.address,
                            customerName: order.customerName,
                            onOpenGoogleMaps: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Viewing past delivery location in Google Maps: ${order.address}'),
                                  backgroundColor: const Color(0xFF1B2A4A),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Customer Details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivered To:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                              const SizedBox(height: 2),
                              Text(order.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                              Text(order.address, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              Text('Phone: ${order.customerPhone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Delivered Items
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Delivered Items:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                              const SizedBox(height: 6),
                              ...order.items.map((i) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check, size: 14, color: Colors.green),
                                        const SizedBox(width: 6),
                                        Text(i, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Close button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Close Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
