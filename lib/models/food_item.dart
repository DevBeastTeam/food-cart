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
  final double cutPrice;
  final bool showCutPrice;
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
    this.cutPrice = 0.0,
    this.showCutPrice = true,
    this.isDiscounted = false,
    this.promoBadge = '',
    this.subAdminId = '',
  });

  double get effectivePrice {
    if (cutPrice > 0 && price > 0) return price;
    if (isDiscounted && discountPrice > 0) return discountPrice;
    return price;
  }

  String get formattedPrice => 'Rs. ${effectivePrice.toInt()}';

  String get formattedOriginalPrice {
    if (cutPrice > 0) return 'Rs. ${cutPrice.toInt()}';
    return 'Rs. ${price.toInt()}';
  }

  bool get hasDiscount {
    if (showCutPrice && cutPrice > effectivePrice) return true;
    if (isDiscounted && discountPrice > 0 && price > discountPrice) return true;
    return discountPercent > 0;
  }

  double get savingsAmount {
    if (cutPrice > effectivePrice) return cutPrice - effectivePrice;
    if (isDiscounted && discountPrice > 0) return price - discountPrice;
    return 0.0;
  }
}
