import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/map_launcher_service.dart';
import '../services/notification_service.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import 'head_office_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final UserState userState;
  final CartState? cartState;
  final bool isEmbedded;
  final VoidCallback? onStartShopping;

  const OrdersScreen({
    super.key,
    required this.userState,
    this.cartState,
    this.isEmbedded = false,
    this.onStartShopping,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  String _activeFilter = 'All'; // 'All', 'Active', 'Delivered'
  bool _isHeadOfficeCollapsed = false;
  late final AnimationController _textShimmerController;
  late final Animation<double> _textShimmer;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _textShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _textShimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _textShimmerController, curve: Curves.easeInOut),
    );

    // Initial sync
    ApiService.instance.syncOrdersOnly(userState: widget.userState);

    // Auto-refresh order statuses every 12 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted) {
        ApiService.instance.syncOrdersOnly(userState: widget.userState);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _textShimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final allOrders = widget.userState.orders;
        final filteredOrders = allOrders.where((order) {
          if (_activeFilter == 'Active') {
            return order.status != 'Delivered' && order.status != 'Cancelled';
          }
          if (_activeFilter == 'Delivered') {
            return order.status == 'Delivered';
          }
          return true;
        }).toList();

        final content = RefreshIndicator(
          onRefresh: () async {
            await ApiService.instance.syncWithBackend(userState: widget.userState);
          },
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverToBoxAdapter(
              child: _buildHeadOfficeCard(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Orders',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_rounded, size: 12, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Live Auto-Sync 🟢',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'All (${allOrders.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Active',
                            'Active (${allOrders.where((o) => o.status != "Delivered").length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Delivered',
                            'Delivered (${allOrders.where((o) => o.status == "Delivered").length})',
                          ),
                          const SizedBox(width: 12),
                          // Notification Test Buttons
                          InkWell(
                            onTap: () async {
                              await NotificationService.instance.showDemoArrivalTestNotification();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🔔 Local Notification Triggered: "Rider Arrived at Your Location!"'),
                                    backgroundColor: Color(0xFF7E22CE),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC084FC)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_active_rounded, size: 14, color: Color(0xFF7E22CE)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Test Arrival Alert 🔔',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF7E22CE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () async {
                              await NotificationService.instance.scheduleDemoMealReminderInSeconds(seconds: 10);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('⏰ Scheduled Notification set for 10 seconds from now! (Check notification tray)'),
                                    backgroundColor: Colors.teal,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.teal.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: Colors.teal.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Schedule 10s Alert ⏰',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.teal.shade800,
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
              ),
            ),
            if (filteredOrders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildOrderCard(filteredOrders[index]);
                    },
                    childCount: filteredOrders.length,
                  ),
                ),
              ),
            ],
          ),
        );



        if (widget.isEmbedded) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(child: content),
            floatingActionButton: _buildSupportFab(context),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: const Text('My Orders & Tracking'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: content,
          floatingActionButton: _buildSupportFab(context),
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _activeFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filterKey),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(50),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
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

  Widget _buildOrderCard(UserOrder order) {
    final isDelivered = order.status == 'Delivered';
    final isPreparing = order.status == 'Preparing';
    final isAccepted = order.status == 'Accepted';
    final isOnTheWay = order.status == 'On the Way';
    final isArrived = order.status == 'Arrived';
    final isPending = order.status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelivered ? AppTheme.border : AppTheme.primary.withAlpha(90),
          width: isDelivered ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Restaurant Name, Order ID, Date & Category
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: order.isPakwan ? Colors.amber.shade100 : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    order.isPakwan ? Icons.outdoor_grill_rounded : Icons.restaurant_rounded,
                    color: order.isPakwan ? Colors.amber.shade900 : AppTheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.restaurantName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${order.id} • ${_formatOrderTime(order.orderDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(order.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getStatusBadgeColor(order.status).withAlpha(80)),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _getStatusBadgeColor(order.status),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Dish Items & Thumbnail
          InkWell(
            onTap: () => _showItemDetailsSheet(order),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomImage(
                      imageUrl: order.restaurantImage,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...order.items.map(
                          (itemText) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '• $itemText',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (order.eventDate != null && order.eventDate!.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                                  'شیڈول: ${order.eventDate}${order.eventTime != null && order.eventTime!.isNotEmpty ? " @ ${order.eventTime}" : ""}${order.occasion != null && order.occasion!.isNotEmpty ? " • ${order.occasion}" : ""}',
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
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Special Note: "${order.notes}"',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      Text(
                                        'Total: Rs. ${order.totalAmount.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      if (order.originalAmount != null && order.originalAmount! > order.totalAmount)
                                        Text(
                                          'Rs. ${order.originalAmount!.toInt()}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                            decoration: TextDecoration.lineThrough,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (order.discountInfo != null) ...[
                                    const SizedBox(height: 3),
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'View details ›',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Delivery Address Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF9FAFB),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 15, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Deliver to: ${order.deliveryAddress}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Status Tracker Timeline (4 Steps)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineStepper(order),
                const SizedBox(height: 10),
                // Additional Status Detail Bar
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'آرڈر موصول ہو گیا ہے • کچن کی تصدیق کا انتظار ہے (Awaiting Confirmation)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isPreparing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.soup_kitchen_rounded, size: 16, color: Color(0xFFE65100)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.isDaigBooking
                                ? 'Daig preparation underway • Est: ${order.prepTime}'
                                : 'Kitchen is preparing your fresh meal • Est: ${order.prepTime}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isArrived)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC084FC), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7E22CE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pin_drop_rounded, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rider Has Arrived at Your Location! 📍',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF581C87),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.riderName != null
                                        ? '${order.riderName} is outside your address (${order.deliveryAddress}). Please collect your order!'
                                        : 'Rider is waiting outside at your doorstep. Please collect your food!',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B21A8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (order.riderPhone != null && order.riderPhone!.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Calling Rider: ${order.riderPhone}'),
                                      backgroundColor: const Color(0xFF7E22CE),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.call, size: 14, color: Color(0xFF7E22CE)),
                                label: Text(
                                  'Call ${order.riderName ?? "Rider"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7E22CE),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFC084FC)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_active_rounded, size: 13, color: Color(0xFF7E22CE)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Arrived Notification Sent',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7E22CE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else if (isOnTheWay)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1976D2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rider is Arriving at Your Location!',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.riderName != null
                                        ? 'Rider: ${order.riderName} • ${order.riderPhone ?? "Active"}'
                                        : 'Delivery partner has started navigation towards your destination',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBDEFB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded, size: 15, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Delivery Pin: ${order.deliveryAddress}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => MapLauncherService.launchLocationPin(
                                  lat: order.latitude,
                                  lng: order.longitude,
                                  fallbackAddress: order.deliveryAddress,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_rounded, size: 13, color: Color(0xFF1A73E8)),
                                    SizedBox(width: 3),
                                    Text(
                                      'View Pin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A73E8),
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
                  )
                else if (isDelivered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Delivered successfully! Enjoy your authentic meal.',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (order.status == 'Cancelled')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFC62828)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.rejectionReason != null && order.rejectionReason!.trim().isNotEmpty
                                ? 'Order Cancelled: ${order.rejectionReason}'
                                : 'Order cancelled / declined by store manager',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Assigned Rider Contact Bar (with JUST 2 Icons Button)
                if (order.riderPhone != null &&
                    order.riderPhone!.trim().isNotEmpty &&
                    !isDelivered &&
                    order.status != 'Cancelled')
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.two_wheeler_rounded, size: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Rider: ${order.riderName ?? "Assigned"}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF14532D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBBF7D0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                order.riderPhone!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Just 2 Icons Button:
                        // 1. 📞 Call Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _launchRiderCall(order.riderPhone!),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_in_talk_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. 💬 WhatsApp Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _launchRiderWhatsApp(order.riderPhone!, order.riderName ?? 'Rider', order.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons row
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPending) ...[
                      OutlinedButton.icon(
                        onPressed: () => _confirmCancelOrder(order),
                        icon: const Icon(Icons.cancel_outlined, size: 15, color: Colors.red),
                        label: const Text('Cancel Order (کینسل کریں)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isAccepted || isPreparing) ...[
                      OutlinedButton.icon(
                        onPressed: () => _showUpdateNotesDialog(order),
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text('Add Note'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _showItemDetailsSheet(order),
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('View Item'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
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

  Widget _buildTimelineStepper(UserOrder order) {
    if (order.status == 'Pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
            ),
            SizedBox(width: 7),
            Text(
              'Awaiting Kitchen Acceptance (تصدیق کا انتظار ہے)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF92400E),
              ),
            ),
          ],
        ),
      );
    }

    if (order.status == 'Cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF9A9A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFC62828)),
            SizedBox(width: 5),
            Text(
              'Order Cancelled / Rejected',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFC62828),
              ),
            ),
          ],
        ),
      );
    }

    int activeStep = 0;
    switch (order.status) {
      case 'Accepted':
        activeStep = 0;
        break;
      case 'Preparing':
        activeStep = 1;
        break;
      case 'On the Way':
        activeStep = 2;
        break;
      case 'Arrived':
        activeStep = 2;
        break;
      case 'Delivered':
        activeStep = 3;
        break;
      default:
        activeStep = 0;
    }

    final isArrived = order.status == 'Arrived';
    final steps = [
      {'label': 'Accepted', 'icon': Icons.check_rounded},
      {'label': 'Preparing', 'icon': Icons.soup_kitchen_rounded},
      {
        'label': isArrived ? 'Arrived 📍' : 'On the Way',
        'icon': isArrived ? Icons.pin_drop_rounded : Icons.delivery_dining_rounded
      },
      {'label': 'Delivered', 'icon': Icons.check_circle_rounded},
    ];

    return Row(
      children: List.generate(steps.length, (stepIndex) {
        final isDone = activeStep >= stepIndex;
        final isCurrent = activeStep == stepIndex;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: stepIndex == 0
                          ? Colors.transparent
                          : (activeStep >= stepIndex
                              ? AppTheme.primary
                              : AppTheme.border),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.primary : Colors.white,
                      border: Border.all(
                        color: isDone ? AppTheme.primary : AppTheme.border,
                        width: 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(70),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      steps[stepIndex]['icon'] as IconData,
                      size: 12,
                      color: isDone ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: stepIndex == steps.length - 1
                          ? Colors.transparent
                          : (activeStep > stepIndex
                              ? AppTheme.primary
                              : AppTheme.border),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  steps[stepIndex]['label'] as String,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isDone ? FontWeight.w800 : FontWeight.w600,
                    color: isDone ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showItemDetailsSheet(UserOrder order) {
    final hasRider = order.riderName != null && order.riderName!.trim().isNotEmpty;
    final riderPhone = order.riderPhone ?? '+92 300 0000000';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // HERO SECTION: Vendor cover, category badge & physical location
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          CustomImage(
                            imageUrl: order.restaurantImage,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                          // Dark gradient overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha(40),
                                    Colors.black.withAlpha(220),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Top Category Badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: order.isPakwan ? Colors.amber.shade700 : AppTheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    order.isPakwan ? Icons.outdoor_grill_rounded : Icons.restaurant_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    order.isPakwan ? 'شاہی پکوان سینٹر' : 'فوڈ ریسٹورنٹ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Top Order ID
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(160),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                '#${order.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                          // Bottom Info
                          Positioned(
                            bottom: 12,
                            left: 14,
                            right: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.restaurantName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.amberAccent),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Kitchen / Shop: Gulberg III / Central Plaza, Lahore',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // RIDER ASSIGNMENT & STATUS SECTION
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasRider ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasRider ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasRider ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasRider ? Icons.two_wheeler_rounded : Icons.hourglass_top_rounded,
                            color: hasRider ? const Color(0xFF16A34A) : Colors.amber.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasRider ? 'ڈیڈیکیٹڈ رائیڈر تفویض شدہ' : 'رائیڈر تفویض کے انتظار میں',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: hasRider ? const Color(0xFF15803D) : Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasRider ? order.riderName! : 'Kitchen is preparing your food freshly',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (hasRider)
                                Text(
                                  '📞 $riderPhone • Status: ${order.status}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (hasRider) ...[
                          // Just 2 Icons Button:
                          // 1. Call Button
                          IconButton(
                            onPressed: () => _launchRiderCall(riderPhone),
                            icon: const Icon(Icons.phone_in_talk_rounded),
                            color: const Color(0xFF2563EB),
                            tooltip: 'Call Rider',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFDBEAFE),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 2. WhatsApp Button
                          IconButton(
                            onPressed: () => _launchRiderWhatsApp(riderPhone, order.riderName ?? 'Rider', order.id),
                            icon: const Icon(Icons.chat_bubble_rounded),
                            color: const Color(0xFF16A34A),
                            tooltip: 'WhatsApp Rider',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFDCFCE7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ORDER TRACKING TIMELINE
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Status Progression (آرڈر ٹریکنگ)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineStepper(order),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FOOD ITEMS LIST WITH THUMBNAIL, PRICE & CUT PRICE
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ordered Food Items',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${order.items.length} Items',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: AppTheme.border),
                        ...order.items.map((itemText) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomImage(
                                  imageUrl: order.restaurantImage,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      order.isPakwan ? '🍲 Authentic Dum Deg' : '🍽️ Fresh Kitchen Dish',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // PAYMENT & COD INFO
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Mode:',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '💵 کیش آن ڈیلیوری (COD)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount Payable:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            Row(
                              children: [
                                if (order.originalAmount != null && order.originalAmount! > order.totalAmount) ...[
                                  Text(
                                    'Rs. ${order.originalAmount!.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  'Rs. ${order.totalAmount.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (order.discountInfo != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '🎉 ${order.discountInfo}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (order.status == 'Pending') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmCancelOrder(order);
                        },
                        icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                        label: const Text(
                          'آرڈر کینسل کریں (Cancel Order)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('بند کریں (Close)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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

  void _showUpdateNotesDialog(UserOrder order) {
    final controller = TextEditingController(text: order.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Order Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add kitchen notes while your food is being prepared:',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Less spicy, pack extra salad & raita...',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.userState.updateOrderNotes(order.id, controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kitchen instructions updated successfully!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelOrder(UserOrder order) {
    final reasons = [
      'Ordered by mistake (غلطی سے آرڈر ہو گیا)',
      'Changed my mind (ارادہ بدل گیا)',
      'Want to change food items or address',
      'Placed duplicate order',
      'Other reason'
    ];
    String selectedReason = reasons.first;
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cancel Order?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to cancel order #${order.id}? This action cannot be undone once confirmed.',
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reason for cancellation (وجہ بتائیں):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((r) => InkWell(
                    onTap: () => setDialogState(() => selectedReason = r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == r ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: selectedReason == r ? Colors.red.shade700 : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  )),
                  if (selectedReason == 'Other reason') ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: customController,
                      decoration: InputDecoration(
                        hintText: 'Enter reason here...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Back / واپس', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final reason = selectedReason == 'Other reason' && customController.text.trim().isNotEmpty
                      ? customController.text.trim()
                      : selectedReason;
                  Navigator.pop(dialogCtx);

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Cancelling order...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  final res = await widget.userState.cancelOrderAsCustomer(order.id, reason: reason);
                  if (mounted) {
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(res['message'] ?? (res['success'] == true ? 'Order cancelled successfully' : 'Could not cancel order')),
                        backgroundColor: res['success'] == true ? Colors.red.shade700 : Colors.orange.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Yes, Cancel Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Orders Placed Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose from authentic Biryani, Pulao, Karahi & Deg bookings!',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onStartShopping,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Pakistani Food'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWhatsAppPhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('03')) {
      clean = '92${clean.substring(1)}';
    } else if (clean.startsWith('3') && clean.length == 10) {
      clean = '92$clean';
    }
    return clean;
  }

  Future<void> _launchRiderWhatsApp(String phone, String riderName, String orderId) async {
    try {
      final clean = _formatWhatsAppPhone(phone);
      final text = Uri.encodeComponent(
        'Assalam-o-Alaikum $riderName bhai, main FoodCourt order #$orderId ke hawalay se rabta kar raha hoon.',
      );
      final uri = Uri.parse('https://wa.me/$clean?text=$text');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('WhatsApp: $phone'),
              backgroundColor: const Color(0xFF25D366),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[OrdersScreen] Error launching rider WhatsApp: $e');
    }
  }

  Future<void> _launchRiderCall(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling Rider: $phone'),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[OrdersScreen] Error launching rider call: $e');
    }
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Accepted':
        return Colors.blueAccent;
      case 'Preparing':
        return Colors.orangeAccent;
      case 'On the Way':
        return AppTheme.primary;
      case 'Arrived':
        return const Color(0xFF7E22CE);
      case 'Delivered':
        return const Color(0xFF28A745);
      case 'Cancelled':
        return const Color(0xFFDC2626);
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatOrderTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  Widget _buildHeadOfficeCard(BuildContext context) {
    if (_isHeadOfficeCollapsed) {
      // Collapsed state: Compact pill allowing full scroll of orders
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF230E4E), Color(0xFF38106A), Color(0xFF4C1D95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withAlpha(35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF230E4E).withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFFBBF24), size: 16),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'FoodCourt Central Kitchen & HQ (Gulberg III)',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _isHeadOfficeCollapsed = false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 3),
                    Text(
                      'Show HQ',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Expanded state: Big luxury card with dark purple gradient and shimmer effect
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF230E4E),
            Color(0xFF38106A),
            Color(0xFF4C1D95),
            Color(0xFF5B21B6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withAlpha(40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF230E4E).withAlpha(120),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: HQ Badge, Open Status, and Collapse Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFBBF24).withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 12),
                          SizedBox(width: 3),
                          Text(
                            'HQ',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'Open 24/7',
                        style: TextStyle(color: Color(0xFF22C55E), fontSize: 10.5, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Collapse Button
              InkWell(
                onTap: () => setState(() => _isHeadOfficeCollapsed = true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 2),
                      Text(
                        'Hide',
                        style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Big Hero Image with rounded corners and glossy border
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                const CustomImage(
                  imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=700&q=80',
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(140),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.restaurant_rounded, color: Color(0xFFFBBF24), size: 13),
                              SizedBox(width: 4),
                              Flexible(
                                child: AnimatedBuilder(
                                  animation: _textShimmer,
                                  builder: (context, child) {
                                    return ShaderMask(
                                      shaderCallback: (bounds) {
                                        final relativeX = _textShimmer.value;
                                        return LinearGradient(
                                          colors: const [
                                            Colors.white,
                                            Color(0xFFFBBF24),
                                            Colors.white,
                                          ],
                                          end: Alignment(relativeX, 0),
                                        ).createShader(bounds);
                                      },
                                      child: const Text(
                                        'FoodCourt Cooking Center',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
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
          ),

          const SizedBox(height: 12),

          // Title & Route Row
          const Text(
            'FoodCourt Central Kitchen & Headquarters',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFFFBBF24), size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '14-C Main Boulevard, Gulberg III, Lahore, Pakistan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Highlight Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildHeadOfficeBadge('⏱️ 20-30m Dispatch'),
              _buildHeadOfficeBadge('🍲 Shahi Daigs Available'),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HeadOfficeDetailScreen()),
                    );
                  },
                  icon: const Icon(Icons.explore_rounded, size: 16),
                  label: const Text(
                    'View Details & GPS Map',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black87,
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

  Widget _buildHeadOfficeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withAlpha(45)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Floating Action Button for Assigned Rider WhatsApp & Direct Call (with JUST 2 icon buttons)
  Widget _buildSupportFab(BuildContext context) {
    final activeRiderOrders = widget.userState.orders.where((o) =>
      o.status != 'Delivered' &&
      o.status != 'Cancelled' &&
      o.riderPhone != null &&
      o.riderPhone!.trim().isNotEmpty
    ).toList();

    if (activeRiderOrders.isNotEmpty) {
      final activeOrder = activeRiderOrders.first;
      final riderName = activeOrder.riderName ?? 'Rider';
      final riderPhone = activeOrder.riderPhone!;

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: const Color(0xFF22C55E).withAlpha(150), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rider Avatar / Bike Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.two_wheeler_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 125),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Order #${activeOrder.id}',
                    style: const TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Just 2 Icons Button:
            // 1. 📞 Call Rider Icon Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchRiderCall(riderPhone),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 2. 💬 WhatsApp Rider Icon Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchRiderWhatsApp(riderPhone, riderName, activeOrder.id),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FloatingActionButton(
      onPressed: () => _showSupportModal(context),
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      tooltip: 'WhatsApp Live Support',
      child: const Icon(Icons.chat_bubble_rounded, size: 26),
    );
  }

  void _showSupportModal(BuildContext context) {
    final messageController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Color(0xFF25D366), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '24/7 FoodCourt Customer Care',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Direct kitchen contact & order help',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 14),

            // WhatsApp Direct Row
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting WhatsApp chat with +92 300 8472910...'),
                    backgroundColor: Color(0xFF25D366),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF25D366).withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp Call & Chat',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E7E34)),
                          ),
                          Text(
                            '+92 300 8472910 • Instant Response',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF25D366)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // UAN Phone Row
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling FoodCourt Helpline +92 42 111-CRAVEE...'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_in_talk_rounded, color: AppTheme.primary, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Call UAN Helpline',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
                          ),
                          Text(
                            '+92 42 111-CRAVEE (111-272-833)',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick message form
            const Text(
              'Send Quick Message / Query:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'e.g. Please add extra raita and mint chutney to order...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = messageController.text.trim();
                  if (text.isNotEmpty) {
                    widget.userState.sendSupportMessage(
                      subject: 'Customer Query',
                      message: text,
                      customerName: widget.userState.isLoggedIn ? widget.userState.userName : 'Guest Customer',
                      phone: widget.userState.userPhone,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent to Central Kitchen team! We will reply promptly.'),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Message to Kitchen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
