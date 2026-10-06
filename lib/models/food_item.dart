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

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.7,
    this.calories = 420,
    this.isPopular = false,
    this.isVegetarian = false,
  });

  String get formattedPrice => 'Rs. ${price.toInt()}';
}
