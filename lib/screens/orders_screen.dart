import 'dart:async';
import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/daig_item.dart';
import '../models/food_item.dart';
import '../services/api_service.dart';
import '../state/cart_state.dart';
import '../state/user_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_image.dart';
import 'food_detail_screen.dart';
import 'auth_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeFilter = 'All'; // 'All', 'Active', 'Delivered'
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.userState,
      builder: (context, _) {
        final isLoggedIn = widget.userState.isLoggedIn;
        final user = widget.userState.user;

        // If not logged in, show login prompt matching profile view design
        if (!isLoggedIn || user == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: !widget.isEmbedded,
              leading: widget.isEmbedded
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
              title: const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            body: _buildLoggedOutView(),
          );
        }

        final allOrders = widget.userState.orders;
        final pendingCount = allOrders.where((o) => o.status.trim().toLowerCase() == 'pending').length;
        final preparingCount = allOrders.where((o) {
          final s = o.status.trim().toLowerCase();
          return s == 'preparing' || s == 'accepted';
        }).length;
        final onTheWayCount = allOrders.where((o) {
          final s = o.status.trim().toLowerCase();
          return s == 'on the way' || s == 'arrived';
        }).length;
        final deliveredCount = allOrders.where((o) => o.status.trim().toLowerCase() == 'delivered').length;
        final cancelledCount = allOrders.where((o) => o.status.trim().toLowerCase() == 'cancelled').length;

        final filteredOrders = allOrders.where((order) {
          final s = order.status.trim().toLowerCase();
          switch (_activeFilter) {
            case 'Pending':
              return s == 'pending';
            case 'Preparing':
              return s == 'preparing' || s == 'accepted';
            case 'On the Way':
              return s == 'on the way' || s == 'arrived';
            case 'Delivered':
              return s == 'delivered';
            case 'Cancelled':
              return s == 'cancelled';
            case 'All':
            default:
              return true;
          }
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'All (${allOrders.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pending', 'Pending ($pendingCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Preparing', 'Preparing ($preparingCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('On the Way', 'On the Way ($onTheWayCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Delivered', 'Delivered ($deliveredCount)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cancelled', 'Cancelled ($cancelledCount)'),
                      ],
                    ),
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

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            automaticallyImplyLeading: !widget.isEmbedded,
            leading: widget.isEmbedded
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: const Text(
              'My Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Total: ${allOrders.length}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8), // Grey color as requested
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: content,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1.2,
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

  Map<String, String> _resolveShopInfoForOrder(UserOrder order) {
    String name = order.restaurantName;
    String address = '14-C Gulberg III, Lahore';
    String image = '';

    final rList = SampleData.restaurants.where((r) =>
        r.name.toLowerCase().trim() == name.toLowerCase().trim() ||
        name.toLowerCase().contains(r.name.toLowerCase()));
    if (rList.isNotEmpty) {
      final r = rList.first;
      name = r.name;
      if (r.address.isNotEmpty) address = r.address;
      image = r.imageUrl;
    }

    if (image.isEmpty) {
      final pList = SampleData.pakwanCenters.where((p) =>
          p.name.toLowerCase().trim() == name.toLowerCase().trim() ||
          name.toLowerCase().contains(p.name.toLowerCase()));
      if (pList.isNotEmpty) {
        final p = pList.first;
        name = p.name;
        if (p.address.isNotEmpty) address = p.address;
        image = p.imageUrl;
      }
    }

    if (image.isEmpty) {
      image = order.restaurantImage;
    }

    return {
      'name': name,
      'address': address,
      'image': image,
    };
  }

  void _openItemDetailForOrder(UserOrder order) {
    FoodItem? matchedFood;
    DaigItem? matchedDaig;

    if (order.foodItemId != null && order.foodItemId!.isNotEmpty) {
      final fMatches = SampleData.allTrendingFoodItems.where((f) => f.id == order.foodItemId);
      if (fMatches.isNotEmpty) matchedFood = fMatches.first;

      final dMatches = SampleData.daigDishes.where((d) => d.id == order.foodItemId);
      if (dMatches.isNotEmpty) matchedDaig = dMatches.first;
    }

    if (matchedFood == null && matchedDaig == null && order.items.isNotEmpty) {
      final rawItem = order.items.first;
      final cleanName = rawItem.replaceFirst(RegExp(r'^\d+\s*x\s*', caseSensitive: false), '').trim().toLowerCase();

      final dMatches = SampleData.daigDishes.where((d) =>
          cleanName.contains(d.name.toLowerCase()) ||
          d.name.toLowerCase().contains(cleanName) ||
          (d.urduName.isNotEmpty && cleanName.contains(d.urduName)));
      if (dMatches.isNotEmpty) {
        matchedDaig = dMatches.first;
      } else {
        final fMatches = SampleData.allTrendingFoodItems.where((f) =>
            cleanName.contains(f.name.toLowerCase()) ||
            f.name.toLowerCase().contains(cleanName));
        if (fMatches.isNotEmpty) {
          matchedFood = fMatches.first;
        }
      }
    }

    if (matchedFood == null && matchedDaig == null) {
      if (order.isPakwan) {
        matchedDaig = SampleData.daigDishes.first;
      } else {
        matchedFood = SampleData.allTrendingFoodItems.first;
      }
    }

    if (widget.cartState != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(
            foodItem: matchedFood,
            daigItem: matchedDaig,
            cartState: widget.cartState!,
          ),
        ),
      );
    }
  }

  Widget _buildOrderCard(UserOrder order) {
    final isPakwan = order.isPakwan;
    final isAccepted = order.status.trim().toLowerCase() == 'accepted';
    final shop = _resolveShopInfoForOrder(order);
    final itemName = order.items.isNotEmpty
        ? order.items.first.replaceFirst(RegExp(r'^\d+\s*x\s*', caseSensitive: false), '')
        : order.restaurantName;
    final hasImage = order.restaurantImage.isNotEmpty && !order.restaurantImage.contains('null');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP ROW: Food Thumbnail + Dish Title + Type Badges Row (Restaurant vs Pakwan) + Status Badge (Right)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomImage(
                    imageUrl: hasImage ? order.restaurantImage : 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),

                // Center Column: Dish Title + Row of 2 Type Badges + Date & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Row containing BOTH Badges (Restaurant & Pakwan)
                      Row(
                        children: [
                          // 🍽️ ریسٹورنٹ Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: !isPakwan ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: !isPakwan ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '🍽️ ریسٹورنٹ',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: !isPakwan ? FontWeight.w800 : FontWeight.w500,
                                color: !isPakwan ? const Color(0xFF1E40AF) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),

                          // 🍲 شاہی پکوان Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPakwan ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isPakwan ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              '🍲 شاہی پکوان',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isPakwan ? FontWeight.w800 : FontWeight.w500,
                                color: isPakwan ? const Color(0xFF92400E) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Order Date & Time + Order ID
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${_formatOrderTime(order.orderDate)} • #${order.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right side: Status Badge (Accepted, Rejected, Preparing, etc.)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(order.status).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getStatusBadgeColor(order.status).withAlpha(80)),
                  ),
                  child: Text(
                    order.status.toLowerCase() == 'cancelled' ? 'REJECTED' : order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _getStatusBadgeColor(order.status),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 2. ORDER FROM & RIDER INFO SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ROW 1: SHOP DETAILS ---
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (shop['image'] != null && shop['image']!.isNotEmpty)
                            ? CustomImage(
                                imageUrl: shop['image']!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                color: Colors.amber.shade100,
                                child: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFFD97706)),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORDER FROM: ${shop['name']}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 11.5, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    shop['address']!,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
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

                  // --- DIVIDER LINE INSIDE CONTAINER ---
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                  ),

                  // --- ROW 2: RIDER DETAILS OR WAITING STATE ---
                  if (order.status == 'Pending') ...[
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wait for Accepting (تصدیق کا انتظار ہے)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Rider details will appear after kitchen accepts order',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (order.status == 'Cancelled') ...[
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade700),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Order Cancelled / Rejected (کوئی رائیڈر مقرر نہیں)',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Rider Assigned and Ready/Active
                    Builder(builder: (context) {
                      final rName = (order.riderName != null && order.riderName!.trim().isNotEmpty)
                          ? order.riderName!
                          : 'Captain Tariq Mehmood';
                      final rPhone = (order.riderPhone != null && order.riderPhone!.trim().isNotEmpty)
                          ? order.riderPhone!
                          : '+92 302 9988776';
                      final rImage = order.riderImage;

                      return Row(
                        children: [
                          // Rider Thumbnail (Rounded 8-10px)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (rImage != null && rImage.isNotEmpty)
                                ? CustomImage(
                                    imageUrl: rImage,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                                    ),
                                    child: const Icon(
                                      Icons.sports_motorsports_rounded,
                                      size: 20,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),

                          // Rider Name and Phone Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'RIDER: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        rName,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded, size: 10.5, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        rPhone,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
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

                          const SizedBox(width: 6),

                          // Action Buttons: Just Call Icon & Just WhatsApp Icon
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Call Action Button (Just Call Icon)
                              InkWell(
                                onTap: () => _callPhone(rPhone),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.call_rounded, size: 17, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // WhatsApp Action Button (Just WhatsApp Icon)
                              InkWell(
                                onTap: () => _openWhatsApp(
                                  phone: rPhone,
                                  riderName: rName,
                                  order: order,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF25D366).withValues(alpha: 0.38),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.chat_bubble_rounded, size: 17, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // 3. STEPPER (Accepted -> Preparing -> On the Way -> Delivered)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: _buildTimelineStepper(order),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 4. BOTTOM ACTION ROW: Price on Left, Cancel Order & View Item on Right
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                // Price (Poore Left mein)
                Text(
                  'Rs. ${order.totalAmount.toInt()}',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),

                // Cancel Order Button (Sirf us waqt agar order accepted ho)
                if (isAccepted) ...[
                  TextButton(
                    onPressed: () => _confirmCancelOrder(order),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // View Item Button (opens FoodDetailScreen for that item)
                ElevatedButton.icon(
                  onPressed: () => _openItemDetailForOrder(order),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
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

  Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 46),
            ),
            const SizedBox(height: 20),
            const Text(
              'Log In to Your Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to view your orders, live track active deliveries, and contact riders.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AuthScreen(userState: widget.userState),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Log In / Register', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    try {
      final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rider Phone: $phone'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[OrdersScreen] Error calling rider: $e');
    }
  }

  Future<void> _openWhatsApp({
    required String phone,
    required String riderName,
    required UserOrder order,
  }) async {
    try {
      final clean = _formatWhatsAppPhone(phone);

      // Customer Name resolution
      String customerName = 'Customer';
      if (widget.userState.user?.name != null && widget.userState.user!.name.trim().isNotEmpty) {
        customerName = widget.userState.user!.name.trim();
      } else if (order.customerName.trim().isNotEmpty) {
        customerName = order.customerName.trim();
      }

      // Customer Delivery Address resolution
      String deliveryAddress = order.deliveryAddress.trim();
      if (deliveryAddress.isEmpty && widget.cartState?.deliveryAddress != null) {
        deliveryAddress = widget.cartState!.deliveryAddress.trim();
      }
      if (deliveryAddress.isEmpty) {
        deliveryAddress = 'Location on Order';
      }

      final message = 'Assalam-o-Alaikum $riderName bhai!\n\n'
          'Main *$customerName* bol raha/rahi hoon FoodCourt se.\n'
          '📦 *Order ID:* #${order.id}\n'
          '📍 *Delivery Address:* $deliveryAddress\n\n'
          'Main order ka wait kar raha/rahi hoon. Kindly apna update de dein ke kab tak deliver ho jayega? Shukriya!';

      final encoded = Uri.encodeComponent(message);

      final whatsappNativeUri = Uri.parse('whatsapp://send?phone=$clean&text=$encoded');
      final whatsappWebUri = Uri.parse('https://wa.me/$clean?text=$encoded');

      if (await canLaunchUrl(whatsappNativeUri)) {
        await launchUrl(whatsappNativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
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

}
