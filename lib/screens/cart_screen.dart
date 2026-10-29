import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/daig_item.dart';
import '../models/food_item.dart';
import '../data/sample_data.dart';
import '../services/notification_service.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import '../state/user_state.dart';
import '../widgets/custom_image.dart';
import 'auth_screen.dart';
import 'food_detail_screen.dart';

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

    // Trigger local notification pop-up
    NotificationService.instance.showOrderNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'آپ کا آرڈر سبمٹ ہو چکا ہے! 🎉',
      body: 'Order placed successfully! Tracking your meal live...',
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'آپ کا آرڈر کامیابی سے سبمٹ ہو گیا ہے!',
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

  Map<String, String> _getShopDetails(FoodItem item) {
    String name = '';
    String location = item.locationAddress;

    if (item.restaurantId.isNotEmpty) {
      final rList = SampleData.restaurants.where((r) => r.id == item.restaurantId);
      if (rList.isNotEmpty) {
        final r = rList.first;
        name = r.name;
        if (r.address.isNotEmpty) location = r.address;
      }
    }

    if (name.isEmpty) {
      final pList = SampleData.pakwanCenters.where((p) => p.id == item.restaurantId);
      if (pList.isNotEmpty) {
        final p = pList.first;
        name = p.name;
        if (p.address.isNotEmpty) location = p.address;
      }
    }

    if (name.isEmpty && item.subAdminId.isNotEmpty) {
      switch (item.subAdminId) {
        case 'sub_admin_1':
          name = 'Bannu Beef Pulao & Nalli Nihari';
          location = 'Shop 12, Block K, Gulberg III, Lahore';
          break;
        case 'sub_admin_2':
          name = 'Shahi Pakwan Center';
          location = 'Bungalow 18-C, Model Town, Lahore';
          break;
        case 'sub_admin_3':
          name = 'Dawat Khana Desi Heritage';
          location = 'Main Boulevard, Phase 5, DHA, Lahore';
          break;
        case 'sub_admin_4':
          name = 'Madina Pakwan & Catering Service';
          location = 'Commercial Plaza 8, Block G, Johar Town, Lahore';
          break;
        default:
          name = 'FoodCourt Special Kitchen';
          if (location.isEmpty) location = '14-C Gulberg III, Lahore';
          break;
      }
    }

    if (name.isEmpty) {
      name = widget.cartState.restaurantName ?? 'FoodCourt Special Kitchen';
    }
    if (location.isEmpty) {
      location = '14-C Gulberg III, Lahore';
    }

    return {
      'name': name,
      'location': location,
    };
  }

  void _openItemDetail(CartItem cartItem) {
    DaigItem? matchedDaig;
    final isDaig = cartItem.foodItem.category.toLowerCase().contains('daig') ||
        cartItem.foodItem.category.toLowerCase().contains('pakwan') ||
        cartItem.foodItem.name.toLowerCase().contains('daig') ||
        cartItem.foodItem.name.toLowerCase().contains('deg');
    if (isDaig) {
      final matches = SampleData.daigDishes.where((d) => d.id == cartItem.foodItem.id);
      if (matches.isNotEmpty) {
        matchedDaig = matches.first;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(
          foodItem: matchedDaig == null ? cartItem.foodItem : null,
          daigItem: matchedDaig,
          cartState: widget.cartState,
        ),
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Clear Cart? (کارٹ خالی کریں؟)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?\nکیا آپ واقعی تمام اشیاء کارٹ سے ہٹانا چاہتے ہیں؟',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel (کینسل)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.cartState.clearCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Clear (ہاں خالی کریں)', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.cartState.totalItemCount} Items',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
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
          bottomNavigationBar: isEmpty ? null : _buildBottomCheckoutBar(context),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // List of unified item cards
        ...widget.cartState.items.map(_buildCartItemCard),

        const SizedBox(height: 10),

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

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem cartItem) {
    final isPakwan = cartItem.foodItem.category.toLowerCase().contains('daig') ||
        cartItem.foodItem.category.toLowerCase().contains('pakwan') ||
        cartItem.foodItem.name.toLowerCase().contains('daig') ||
        cartItem.foodItem.name.toLowerCase().contains('deg');
    final shop = _getShopDetails(cartItem.foodItem);

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
          // Top section: ListTile / Item row
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => _openItemDetail(cartItem),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail with Type Pill (🍲 شاہی پکوان / 🍽️ ریسٹورنٹ)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomImage(
                          imageUrl: cartItem.foodItem.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPakwan ? const Color(0xFFD97706) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            isPakwan ? '🍲 شاہی پکوان' : '🍽️ ریسٹورنٹ',
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
                  const SizedBox(width: 12),

                  // Title, Price, Out of stock, Quantity selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItem.foodItem.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Price and Discount
                        Row(
                          children: [
                            Text(
                              cartItem.formattedTotalPrice,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
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
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
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

                        if (!cartItem.foodItem.isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Out of Stock 🔴 (ختم ہے)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),

                        const SizedBox(height: 6),

                        // Quantity Selector Controls
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => widget.cartState.decrement(cartItem.foodItem.id),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      child: Icon(Icons.remove, size: 16, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => widget.cartState.increment(cartItem.foodItem.id),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      child: Icon(Icons.add, size: 16, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => widget.cartState.removeItem(cartItem.foodItem.id),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Trailing Arrow Button to open Detail Page
                  IconButton(
                    onPressed: () => _openItemDetail(cartItem),
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    tooltip: 'View Item Details',
                  ),
                ],
              ),
            ),
          ),

          // Clean Divider Line
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Bottom Shop Info (Shop Name + Grey Location with Pin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        shop['name']!,
                        style: const TextStyle(
                          fontSize: 12,
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
                    const Icon(Icons.location_on_rounded, size: 12.5, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop['location']!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
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
    );
  }

  Widget _buildBottomCheckoutBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Clear Cart button with confirmation dialog
            OutlinedButton.icon(
              onPressed: () => _showClearCartConfirmation(context),
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
              label: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                backgroundColor: Colors.red.shade50.withAlpha(80),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),

            // Total Price Info
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Rs. ${widget.cartState.grandTotal.toInt()}',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Right: Expanded "سبمٹ آرڈر (Submit Order)" Button with Continuous Shimmer
            Expanded(
              child: _SubmitOrderShimmerButton(
                onPressed: () => _handleCheckout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmering Submit Order Action Button
class _SubmitOrderShimmerButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SubmitOrderShimmerButton({required this.onPressed});

  @override
  State<_SubmitOrderShimmerButton> createState() => _SubmitOrderShimmerButtonState();
}

class _SubmitOrderShimmerButtonState extends State<_SubmitOrderShimmerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF16A34A),
                  Color(0xFF22C55E),
                  Color(0xFF86EFAC),
                  Color(0xFF22C55E),
                  Color(0xFF16A34A),
                ],
                stops: [
                  0.0,
                  (_controller.value - 0.2).clamp(0.0, 1.0),
                  _controller.value.clamp(0.0, 1.0),
                  (_controller.value + 0.2).clamp(0.0, 1.0),
                  1.0,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withAlpha(100),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'سبمٹ آرڈر (Submit Order)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
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
}
