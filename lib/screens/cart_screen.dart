import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../state/user_state.dart';
import '../widgets/custom_image.dart';
import 'auth_screen.dart';

class CartScreen extends StatefulWidget {
  final CartState cartState;
  final UserState? userState;
  final bool isEmbedded;
  final VoidCallback? onNavigateToOrders;
  final VoidCallback? onStartShopping;

  const CartScreen({
    super.key,
    required this.cartState,
    this.userState,
    this.isEmbedded = false,
    this.onNavigateToOrders,
    this.onStartShopping,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedEventDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedEventTime = const TimeOfDay(hour: 14, minute: 0);
  String _selectedOccasion = 'دعوت / مہمانی (Dawat)';

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.cartState.specialInstructions;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isPakwanCart() {
    return widget.cartState.items.any((i) =>
        i.foodItem.category.toLowerCase().contains('daig') ||
        i.foodItem.name.toLowerCase().contains('daig') ||
        i.foodItem.category.toLowerCase().contains('deg') ||
        i.foodItem.category.toLowerCase().contains('pakwan') ||
        (widget.cartState.restaurantName?.toLowerCase().contains('pakwan') ?? false));
  }

  void _handleCheckout(BuildContext context) {
    if (widget.cartState.items.isEmpty) return;

    final outOfStockItems = widget.cartState.items.where((i) => !i.foodItem.isAvailable).toList();
    if (outOfStockItems.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aapki cart mein "${outOfStockItems.first.foodItem.name}" Out of Stock ho chuka hai 🔴 Baraye meherbani remove karein.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Guest Mode Check: If user is not logged in, intercept with Toast containing direct Login button
    final isLoggedIn = widget.userState?.isLoggedIn ?? false;
    if (!isLoggedIn && widget.userState != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'پلیز لاگ ان فرسٹ ٹو سبمٹ ارڈر',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Please login first to submit order',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B2A4A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          duration: const Duration(seconds: 7),
          action: SnackBarAction(
            label: 'لاگ ان کریں (Login)',
            textColor: Colors.amberAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuthScreen(userState: widget.userState!),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    final restName = widget.cartState.restaurantName ?? 'Pakistani Food Court';
    final itemsList = widget.cartState.items
        .map((i) => '${i.quantity}x ${i.foodItem.name}')
        .toList();
    final totalAmount = widget.cartState.grandTotal;
    final totalSavings = widget.cartState.totalSavings;
    final originalAmount = totalSavings > 0 ? (totalAmount + totalSavings) : totalAmount;
    final discountInfo = totalSavings > 0 ? 'Special Promo: Saved Rs. ${totalSavings.toInt()}' : null;
    final deliveryAddress = widget.cartState.deliveryAddress;
    final isDaig = _isPakwanCart();
    final prepTime = isDaig ? '2-3 hours (Daig preparation)' : '25-35 mins';
    final image = widget.cartState.items.first.foodItem.imageUrl;
    final notes = widget.cartState.specialInstructions;

    final formattedDate = '${_selectedEventDate.day.toString().padLeft(2, '0')}-${_selectedEventDate.month.toString().padLeft(2, '0')}-${_selectedEventDate.year}';
    final formattedTime = _selectedEventTime.format(context);
    final eventNote = isDaig ? 'تقریب: $formattedDate @ $formattedTime ($_selectedOccasion)' : null;
    final finalNotes = notes.isNotEmpty
        ? (eventNote != null ? '$notes | $eventNote' : notes)
        : eventNote;

    widget.userState?.placeOrder(
      restaurantName: restName,
      restaurantId: widget.cartState.restaurantId,
      subAdminId: widget.cartState.subAdminId,
      restaurantImage: image,
      items: itemsList,
      totalAmount: totalAmount,
      originalAmount: originalAmount,
      discountInfo: discountInfo,
      deliveryAddress: deliveryAddress,
      prepTime: prepTime,
      isDaigBooking: isDaig,
      occasion: isDaig ? _selectedOccasion : null,
      eventDate: isDaig ? formattedDate : null,
      eventTime: isDaig ? formattedTime : null,
      notes: finalNotes,
    );

    widget.cartState.clearCart();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Order placed successfully! Tracking your meal live...',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (widget.onNavigateToOrders != null) {
      widget.onNavigateToOrders!();
    } else if (!widget.isEmbedded && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildPakwanScheduleCard(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedEventDate.day == now.day &&
        _selectedEventDate.month == now.month &&
        _selectedEventDate.year == now.year;

    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = _selectedEventDate.day == tomorrow.day &&
        _selectedEventDate.month == tomorrow.month &&
        _selectedEventDate.year == tomorrow.year;

    final formattedDateText = isToday
        ? 'Today (آج)'
        : (isTomorrow ? 'Tomorrow (کل)' : '${_selectedEventDate.day}/${_selectedEventDate.month}/${_selectedEventDate.year}');

    final occasions = [
      'دعوت / مہمانی (Dawat)',
      'نیاز / ختم (Niaz)',
      'ولیمہ / شادی (Walima)',
      'سالگرہ / پارٹی (Party)',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقریب کی تاریخ اور وقت (Delivery Schedule)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'پکوان / دیگ کی ڈیلیوری کے لیے مطلوبہ وقت منتخب کریں',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFFDE68A)),
          const SizedBox(height: 12),

          // 1. DATE SELECTOR
          const Text(
            '1. تقریب کی تاریخ (Event Date):',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('آج (Today)'),
                selected: isToday,
                onSelected: (val) {
                  if (val) setState(() => _selectedEventDate = DateTime.now());
                },
                selectedColor: const Color(0xFFD97706),
                labelStyle: TextStyle(
                  color: isToday ? Colors.white : const Color(0xFF78350F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              ChoiceChip(
                label: const Text('کل (Tomorrow) 🌟'),
                selected: isTomorrow,
                onSelected: (val) {
                  if (val) setState(() => _selectedEventDate = DateTime.now().add(const Duration(days: 1)));
                },
                selectedColor: const Color(0xFFD97706),
                labelStyle: TextStyle(
                  color: isTomorrow ? Colors.white : const Color(0xFF78350F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFFD97706)),
                label: Text(
                  !isToday && !isTomorrow ? '${_selectedEventDate.day}/${_selectedEventDate.month}/${_selectedEventDate.year}' : 'دیگر تاریخ 📅',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF78350F)),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedEventDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setState(() => _selectedEventDate = picked);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. TIME SELECTOR
          const Text(
            '2. مطلوبہ وقت (Delivery Time):',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('دوپہر ۲ بجے (2:00 PM) ⭐'),
                selected: _selectedEventTime.hour == 14 && _selectedEventTime.minute == 0,
                onSelected: (val) {
                  if (val) setState(() => _selectedEventTime = const TimeOfDay(hour: 14, minute: 0));
                },
                selectedColor: const Color(0xFFD97706),
                labelStyle: TextStyle(
                  color: (_selectedEventTime.hour == 14 && _selectedEventTime.minute == 0) ? Colors.white : const Color(0xFF78350F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              ChoiceChip(
                label: const Text('دوپہر ۱:۳۰ (Lunch 1:30 PM)'),
                selected: _selectedEventTime.hour == 13 && _selectedEventTime.minute == 30,
                onSelected: (val) {
                  if (val) setState(() => _selectedEventTime = const TimeOfDay(hour: 13, minute: 30));
                },
                selectedColor: const Color(0xFFD97706),
                labelStyle: TextStyle(
                  color: (_selectedEventTime.hour == 13 && _selectedEventTime.minute == 30) ? Colors.white : const Color(0xFF78350F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              ChoiceChip(
                label: const Text('رات ۸:۳۰ (Dinner 8:30 PM)'),
                selected: _selectedEventTime.hour == 20 && _selectedEventTime.minute == 30,
                onSelected: (val) {
                  if (val) setState(() => _selectedEventTime = const TimeOfDay(hour: 20, minute: 30));
                },
                selectedColor: const Color(0xFFD97706),
                labelStyle: TextStyle(
                  color: (_selectedEventTime.hour == 20 && _selectedEventTime.minute == 30) ? Colors.white : const Color(0xFF78350F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFD97706)),
                label: Text(
                  _selectedEventTime.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF78350F)),
                ),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedEventTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedEventTime = picked);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. OCCASION SELECTOR
          const Text(
            '3. تقریب کی نوعیت (Occasion):',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: occasions.map((occ) {
              final isSel = _selectedOccasion == occ;
              return ChoiceChip(
                label: Text(occ),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedOccasion = occ);
                },
                selectedColor: const Color(0xFFD97706),
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF78350F),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'شیڈول: $formattedDateText کو ${_selectedEventTime.format(context)} بجے ($_selectedOccasion)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFoodDetailSheet(CartItem cartItem) {
    final item = cartItem.foodItem;
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
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Quantity in cart: ${cartItem.quantity}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.cartState,
      builder: (context, _) {
        final isEmpty = widget.cartState.items.isEmpty;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('My Cart'),
            automaticallyImplyLeading: !widget.isEmbedded,
            leading: widget.isEmbedded
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            actions: [
              if (!isEmpty)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Cart?'),
                        content: const Text('Are you sure you want to remove all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.cartState.clearCart();
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: isEmpty
              ? _buildEmptyCart(context)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: _buildCartContent(context),
                  ),
                ),
          bottomNavigationBar: null,
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Good food is always cooking! Explore popular restaurants around you and add your favorite dishes to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onStartShopping != null) {
                  widget.onStartShopping!();
                } else if (Navigator.canPop(context)) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text('Browse Pakistani Food'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Restaurant Banner Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER FROM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.cartState.restaurantName ?? 'Restaurant',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
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

        const SizedBox(height: 14),

        // Delivery Address Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.near_me_outlined,
                    color: AppTheme.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DELIVERY ADDRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.cartState.deliveryAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

        const SizedBox(height: 16),

        const Text(
          'Order Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        ...widget.cartState.items.map(_buildCartItemTile),

        const SizedBox(height: 16),

        if (_isPakwanCart()) ...[
          _buildPakwanScheduleCard(context),
        ],

        // Cash on Delivery Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'کیش آن ڈیلیوری (Cash on Delivery - COD)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pay cash to the rider when food arrives at your address',
                      style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleCheckout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Send Order (کیش آن ڈیلیوری)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildCartItemTile(CartItem cartItem) {
    final isPakwan = cartItem.foodItem.category.toLowerCase().contains('daig') ||
        cartItem.foodItem.category.toLowerCase().contains('pakwan') ||
        cartItem.foodItem.name.toLowerCase().contains('daig') ||
        cartItem.foodItem.name.toLowerCase().contains('deg');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: () => _showFoodDetailSheet(cartItem),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: Stack(
          children: [
            CustomImage(
              imageUrl: cartItem.foodItem.imageUrl,
              width: 64,
              height: 64,
              borderRadius: 10,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isPakwan ? Colors.amber.shade800 : AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPakwan ? 'پکوان' : 'ریسٹورنٹ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cartItem.foodItem.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!cartItem.foodItem.isAvailable)
              Container(
                margin: const EdgeInsets.only(top: 2, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: const Text(
                  'Out of Stock 🔴 (ختم ہے)',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            if (cartItem.foodItem.locationAddress.isNotEmpty)
              Text(
                '📍 ${cartItem.foodItem.locationAddress}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                cartItem.formattedTotalPrice,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              if (cartItem.hasDiscount) ...[
                const SizedBox(width: 6),
                Text(
                  cartItem.formattedOriginalTotalPrice,
                  style: const TextStyle(
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '${cartItem.foodItem.discountPercent}% OFF',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => widget.cartState.decrement(cartItem.foodItem.id),
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '${cartItem.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
            ),
            IconButton(
              onPressed: () => widget.cartState.increment(cartItem.foodItem.id),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19),
              onPressed: () => widget.cartState.removeItem(cartItem.foodItem.id),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

}
