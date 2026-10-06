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

  double get totalPrice => foodItem.price * quantity;

  String get formattedTotalPrice => 'Rs. ${totalPrice.toInt()}';
}
