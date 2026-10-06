import 'food_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final double deliveryFee;
  final double minOrder;
  final String distance;
  final String address;
  final String badge;
  final bool isFeatured;
  final List<String> categories;
  final List<FoodItem> menu;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
    required this.distance,
    required this.address,
    this.badge = '',
    this.isFeatured = false,
    required this.categories,
    required this.menu,
  });

  String get formattedDeliveryFee =>
      deliveryFee == 0 ? 'Free Delivery' : 'Rs. ${deliveryFee.toInt()} Delivery';
}
