class FoodItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int calories;
  final bool isPopular;
  final bool isVegetarian;
  final String locationAddress;
  final List<String> badges;
  final String badge;
  final int discountPercent;
  final double discountPrice;
  final bool isDiscounted;
  final String promoBadge;
  final String subAdminId;

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.9,
    this.calories = 420,
    this.isPopular = true,
    this.isVegetarian = false,
    this.locationAddress = 'FoodCourt Central Kitchen, 14-C Gulberg III, Lahore',
    this.badges = const ['Single Platter (1kg)', 'Family Pack (3kg)', 'Desi Ghee', 'Special Raita Included'],
    this.badge = 'Most Ordered',
    this.discountPercent = 0,
    this.discountPrice = 0.0,
    this.isDiscounted = false,
    this.promoBadge = '',
    this.subAdminId = '',
  });

  double get effectivePrice =>
      (isDiscounted && discountPrice > 0) ? discountPrice : price;

  String get formattedPrice => 'Rs. ${effectivePrice.toInt()}';

  String get formattedOriginalPrice => 'Rs. ${price.toInt()}';

  double get savingsAmount =>
      (isDiscounted && discountPrice > 0) ? (price - discountPrice) : 0.0;
}
