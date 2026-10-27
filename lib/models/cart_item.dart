import 'food_item.dart';

class CartItem {
  final FoodItem foodItem;
  final String restaurantId;
  final String restaurantName;
  int quantity;
  final String specialInstructions;

  CartItem({
    required this.foodItem,
    required this.restaurantId,
    required this.restaurantName,
    this.quantity = 1,
    this.specialInstructions = '',
  });

  double get totalPrice => foodItem.effectivePrice * quantity;

  double get originalTotalPrice => foodItem.price * quantity;

  bool get hasDiscount => foodItem.isDiscounted && foodItem.savingsAmount > 0;

  String get formattedTotalPrice => 'Rs. ${totalPrice.toInt()}';

  String get formattedOriginalTotalPrice => 'Rs. ${originalTotalPrice.toInt()}';
}
