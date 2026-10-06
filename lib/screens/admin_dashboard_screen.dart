import 'package:flutter/material.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserState userState;
  final VoidCallback? onSwitchToCustomer;

  const AdminDashboardScreen({
    super.key,
    required this.userState,
    this.onSwitchToCustomer,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _filter = 'All'; // 'All', 'Accepted', 'Preparing', 'On the Way', 'Delivered'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final orders = widget.userState.orders;
        final filtered = orders.where((o) {
          if (_filter == 'All') return true;
          return o.status == _filter;
        }).toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 2,
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.amberAccent, size: 22),
                SizedBox(width: 8),
                Text(
                  'Admin & Kitchen Hub',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  widget.userState.setRole(UserRole.client);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Switched to Customer App view'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.person, color: Colors.white, size: 16),
                label: const Text('Customer View', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              IconButton(
                tooltip: 'Log Out',
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => widget.userState.logout(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Grid
                _buildStatsGrid(orders),

                const SizedBox(height: 18),

                // Filter Chips
                Row(
                  children: [
                    const Text(
                      'Live Orders:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _filter,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Orders')),
                        DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
                        DropdownMenuItem(value: 'Preparing', child: Text('In Kitchen')),
                        DropdownMenuItem(value: 'On the Way', child: Text('On the Way')),
                        DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filter = val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textLight),
                        const SizedBox(height: 10),
                        Text(
                          'No orders in "$_filter" status',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((order) => _buildAdminOrderCard(order)),

                const SizedBox(height: 20),

                // Support Messages Section
                _buildSupportInboxCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(List<UserOrder> orders) {
    final pendingCount = orders.where((o) => o.status == 'Accepted').length;
    final cookingCount = orders.where((o) => o.status == 'Preparing').length;
    final onTheWayCount = orders.where((o) => o.status == 'On the Way').length;
    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatTile('Total Revenue', 'Rs. ${totalRevenue.toInt()}', Icons.attach_money_rounded, Colors.green),
              _buildStatTile('New Orders', '$pendingCount', Icons.notifications_active_rounded, Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatTile('Cooking Now', '$cookingCount', Icons.soup_kitchen_rounded, Colors.orange),
              _buildStatTile('Dispatched', '$onTheWayCount', Icons.delivery_dining_rounded, AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOrderCard(UserOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.status == 'Accepted' ? Colors.blue.withAlpha(120) : AppTheme.border,
          width: order.status == 'Accepted' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${order.id}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.restaurantName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: AppTheme.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImage(
                  imageUrl: order.restaurantImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.map((it) => Text('• $it', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 4),
                    Text(
                      'Deliver to: ${order.deliveryAddress}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.notes != null) ...[
                      const SizedBox(height: 2),
                      Text('Note: "${order.notes}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.primary)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs. ${order.totalAmount.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  if (order.discountInfo != null)
                    Text(order.discountInfo!, style: const TextStyle(fontSize: 10, color: Color(0xFF28A745), fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Admin Action Controls Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (order.status == 'Accepted') ...[
                ElevatedButton.icon(
                  onPressed: () => _showSetPrepTimeDialog(order),
                  icon: const Icon(Icons.soup_kitchen_rounded, size: 14),
                  label: const Text('Start Cooking (Prep)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    widget.userState.updateOrderStatus(order.id, 'Cancelled');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order #${order.id} rejected.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 11.5)),
                ),
              ] else if (order.status == 'Preparing') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    widget.userState.assignRider(order.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rider assigned & dispatched for #${order.id}!')),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining_rounded, size: 15),
                  label: const Text('Assign Rider (On the Way)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _showSetPrepTimeDialog(order),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text('Prep: ${order.prepTime}', style: const TextStyle(fontSize: 11)),
                ),
              ] else if (order.status == 'On the Way') ...[
                ElevatedButton.icon(
                  onPressed: () {
                    widget.userState.updateOrderStatus(order.id, 'Delivered');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order #${order.id} marked as Delivered!')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                  label: const Text('Mark as Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ] else if (order.status == 'Delivered') ...[
                const Chip(
                  avatar: Icon(Icons.check, size: 14, color: Colors.green),
                  label: Text('Fulfilled & Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  backgroundColor: Color(0xFFEDFBF5),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showSetPrepTimeDialog(UserOrder order) {
    String selected = order.isDaigBooking ? '2 hours (Daig)' : '25 mins';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Kitchen Prep Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Estimated time until meal is packed for delivery rider:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['15 mins', '25 mins', '40 mins', '1.5 hours', '2.5 hours (Daig)'].map((time) {
                return ChoiceChip(
                  label: Text(time),
                  selected: selected == time,
                  onSelected: (val) {
                    if (val) {
                      widget.userState.updateOrderStatus(order.id, 'Preparing', prepTime: time);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order #${order.id} set to Preparing ($time)')),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportInboxCard() {
    return Container(
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
              Icon(Icons.headset_mic_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Customer Support & Kitchen Inquiries',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Live kitchen hotline: +92 42 111-CRAVEE (272-833)\nWhatsApp Support: +92 300 8472910',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All customer support chats synchronized.')),
              );
            },
            icon: const Icon(Icons.sync, size: 16),
            label: const Text('Refresh Helpline Log'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.blue;
      case 'Preparing':
        return Colors.orange;
      case 'On the Way':
        return AppTheme.primary;
      case 'Delivered':
        return const Color(0xFF28A745);
      default:
        return AppTheme.textSecondary;
    }
  }
}
