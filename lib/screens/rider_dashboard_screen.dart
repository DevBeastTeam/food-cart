import 'package:flutter/material.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';

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
  bool _isOnline = true;
  String _filter = 'Active'; // 'Active', 'All', 'Delivered'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final allOrders = widget.userState.orders;
        final riderOrders = allOrders.where((o) {
          if (_filter == 'Active') {
            return o.status == 'Preparing' || o.status == 'On the Way';
          } else if (_filter == 'Delivered') {
            return o.status == 'Delivered';
          }
          return true;
        }).toList();

        final activeDeliveries = allOrders.where((o) => o.status == 'On the Way').length;
        final completedDeliveries = allOrders.where((o) => o.status == 'Delivered').length;
        final earnings = completedDeliveries * 180 + 450; // Base pay + drop fee

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FA),
          appBar: AppBar(
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rider Delivery Console',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
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
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() => _isOnline = !_isOnline);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isOnline ? 'You are now Online and receiving deliveries' : 'Shift paused: You are Offline',
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
                            width: 8,
                            height: 8,
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
          ),
          body: CustomScrollView(
            slivers: [
              // Rider Profile & Shift Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  color: const Color(0xFF1B2A4A),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withAlpha(30),
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
                                          fontSize: 16,
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
                                const SizedBox(height: 2),
                                Text(
                                  'Bike: Honda 125 (LED-4921) • ${widget.userState.riderPhone}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Active Runs', '$activeDeliveries', Icons.sports_motorsports_rounded),
                            Container(width: 1, height: 26, color: Colors.white24),
                            _buildStatItem('Completed', '$completedDeliveries', Icons.check_circle_outline),
                            Container(width: 1, height: 26, color: Colors.white24),
                            _buildStatItem('Earnings', 'Rs. $earnings', Icons.account_balance_wallet_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Text(
                        'Assigned Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _buildChip('Active', 'Active (${allOrders.where((o) => o.status == 'Preparing' || o.status == 'On the Way').length})'),
                      const SizedBox(width: 6),
                      _buildChip('Delivered', 'Done ($completedDeliveries)'),
                    ],
                  ),
                ),
              ),

              // Deliveries List
              if (riderOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Tasks in This Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'All current orders have been picked up or delivered.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRiderOrderCard(riderOrders[index]),
                      childCount: riderOrders.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.amber.shade300, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildChip(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2A4A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B2A4A) : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRiderOrderCard(UserOrder order) {
    final isOnTheWay = order.status == 'On the Way';
    final isDelivered = order.status == 'Delivered';

    Color statusColor;
    if (isDelivered) {
      statusColor = Colors.green.shade700;
    } else if (isOnTheWay) {
      statusColor = Colors.blue.shade700;
    } else {
      statusColor = Colors.orange.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnTheWay ? Colors.blue.shade300 : AppTheme.border,
          width: isOnTheWay ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
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
              color: statusColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Collect: Rs. ${order.totalAmount.toInt()}',
                  style: TextStyle(
                    fontSize: 13,
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
                // 1. Pickup Point (Central Kitchen)
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
                          const SizedBox(height: 1),
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
                    height: 16,
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
                          const SizedBox(height: 1),
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
                          SnackBar(content: Text('Calling customer ${order.customerName}: ${order.customerPhone}')),
                        );
                      },
                    ),
                  ],
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
                    if (order.discountInfo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          order.discountInfo!,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Rider Actions Bar
                if (!isDelivered) ...[
                  Row(
                    children: [
                      // Status Selection Dropdown / Selector (As requested in audio: "وہ سلیکٹ کر سکتا ہے اپنا سٹیٹس")
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
                                DropdownMenuItem(value: 'Accepted', child: Text('Accepted', style: TextStyle(fontSize: 12.5))),
                                DropdownMenuItem(value: 'Preparing', child: Text('Preparing in Kitchen', style: TextStyle(fontSize: 12.5))),
                                DropdownMenuItem(value: 'On the Way', child: Text('On the Way (Out for Delivery)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                                DropdownMenuItem(value: 'Delivered', child: Text('Delivered & Paid', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
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
                      // Primary Button
                      if (!isOnTheWay)
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.userState.updateOrderStatus(order.id, 'On the Way');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order #${order.id} is now On the Way!'),
                                backgroundColor: Colors.blue.shade700,
                              ),
                            );
                          },
                          icon: const Icon(Icons.two_wheeler, size: 16),
                          label: const Text('Start Run'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.userState.updateOrderStatus(order.id, 'Delivered');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order #${order.id} marked Delivered! Cash collected.'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: const Text('Delivered'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Delivered Successfully • Paid Rs. ${order.totalAmount.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
