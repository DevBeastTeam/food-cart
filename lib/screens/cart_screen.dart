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

  void _handleCheckout(BuildContext context) {
    if (widget.cartState.items.isEmpty) return;

    // Auth guard: If user is not logged in, redirect to login page
    final isLoggedIn = widget.userState?.isLoggedIn ?? false;
    if (!isLoggedIn && widget.userState != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in or create an account to place your order!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScreen(userState: widget.userState!),
        ),
      );
      return;
    }

    final restName = widget.cartState.restaurantName ?? 'Pakistani Food Court';
    final itemsList = widget.cartState.items
        .map((i) => '${i.quantity}x ${i.foodItem.name}')
        .toList();
    final totalAmount = widget.cartState.grandTotal;
    final deliveryAddress = widget.cartState.deliveryAddress;
    final isDaig = widget.cartState.items.any((i) =>
        i.foodItem.category == 'Daig' || i.foodItem.name.contains('Daig'));
    final prepTime = isDaig ? '2-3 hours (Daig preparation)' : '25-35 mins';
    final image = widget.cartState.items.first.foodItem.imageUrl;
    final notes = widget.cartState.specialInstructions;

    widget.userState?.placeOrder(
      restaurantName: restName,
      restaurantImage: image,
      items: itemsList,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      prepTime: prepTime,
      isDaigBooking: isDaig,
      notes: notes.isNotEmpty ? notes : null,
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

        const SizedBox(height: 20),

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
              'Send Order',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showFoodDetailSheet(cartItem),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: CustomImage(
          imageUrl: cartItem.foodItem.imageUrl,
          width: 64,
          height: 64,
          borderRadius: 10,
          fit: BoxFit.cover,
        ),
        title: Text(
          cartItem.foodItem.name,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Rs. ${(cartItem.foodItem.price * cartItem.quantity).toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => widget.cartState.decrement(cartItem.foodItem.id),
              icon: const Icon(Icons.remove_circle_outline, size: 22),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '${cartItem.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            IconButton(
              onPressed: () => widget.cartState.increment(cartItem.foodItem.id),
              icon: const Icon(Icons.add_circle_outline, size: 22),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => widget.cartState.removeItem(cartItem.foodItem.id),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

}
