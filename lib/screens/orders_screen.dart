import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
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

        final content = CustomScrollView(
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
                    const Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
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
          // Header: Restaurant Name, Order ID, Date
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                if (isPreparing)
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
                else if (isOnTheWay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF1565C0)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Rider is on the way with your hot meal!',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0),
                            ),
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
                  ),

                // Action buttons row
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
      case 'Delivered':
        activeStep = 3;
        break;
      default:
        activeStep = 0;
    }

    final steps = [
      {'label': 'Accepted', 'icon': Icons.check_rounded},
      {'label': 'Preparing', 'icon': Icons.soup_kitchen_rounded},
      {'label': 'On the Way', 'icon': Icons.delivery_dining_rounded},
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomImage(
                    imageUrl: order.restaurantImage,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Order ID: #${order.id}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Paid: Rs. ${order.totalAmount.toInt()}',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          ),
                          if (order.originalAmount != null && order.originalAmount! > order.totalAmount) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Rs. ${order.originalAmount!.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 8),
            const Text(
              'Ordered Items & Recipes:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF28A745)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Delivery Address:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.deliveryAddress,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated Preparation: ${order.prepTime}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
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

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.blueAccent;
      case 'Preparing':
        return Colors.orangeAccent;
      case 'On the Way':
        return AppTheme.primary;
      case 'Delivered':
        return const Color(0xFF28A745);
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

  // Floating Action Button with JUST WhatsApp icon
  Widget _buildSupportFab(BuildContext context) {
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
