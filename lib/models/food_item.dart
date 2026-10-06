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
  });

  String get formattedPrice => 'Rs. ${price.toInt()}';
}
