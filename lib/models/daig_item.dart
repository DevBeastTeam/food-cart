import 'food_item.dart';

class DaigItem {
  final String id;
  final String name;
  final String urduName;
  final String description;
  final String category; // 'Biryani & Pulao', 'Qorma & Karahi', 'Haleem & Nihari', 'Sweet & Desserts'
  final double fullDaigPrice;
  final double halfDaigPrice;
  final double? customMediumPrice;
  final String fullDaigWeight;
  final String mediumDaigWeight;
  final String halfDaigWeight;
  final String imageUrl;
  final double rating;
  final String deliveryNotice;
  final String badge;
  final List<String> includes;
  final String centerId;
  final String centerName;

  double get mediumDaigPrice =>
      customMediumPrice ?? (((fullDaigPrice + halfDaigPrice) / 2) / 100).round() * 100.0;

  const DaigItem({
    required this.id,
    required this.name,
    required this.urduName,
    required this.description,
    required this.category,
    required this.fullDaigPrice,
    required this.halfDaigPrice,
    this.customMediumPrice,
    this.fullDaigWeight = 'Large (12-14 KG • Serves 35-45)',
    this.mediumDaigWeight = 'Medium (10 KG • Serves 25-30)',
    this.halfDaigWeight = 'Small (6 KG • Serves 15-20)',
    required this.imageUrl,
    this.rating = 4.9,
    this.deliveryNotice = 'Order 3-4 hours in advance for fresh coal-dum cooking',
    this.badge = 'Bestseller Daig',
    this.includes = const [
      'Clay-sealed hot Daig cauldron',
      'Spicy Zeera Raita Tub (2 Litre)',
      'Fresh Mint & Kachumber Salad',
    ],
    this.centerId = 'rest_pakwan',
    this.centerName = 'Shahi Pakwan Center',
  });

  // Convert to FoodItem for seamless cart integration
  FoodItem toFoodItem({
    required String sizeName, // 'small', 'medium', 'large'
    String occasion = '',
    String notes = '',
  }) {
    final double price;
    final String label;
    final String serves;

    switch (sizeName.toLowerCase()) {
      case 'small':
      case 'half':
        price = halfDaigPrice;
        label = 'Small Deg (6 KG)';
        serves = 'Serves 15-20';
        break;
      case 'medium':
        price = mediumDaigPrice;
        label = 'Medium Deg (10 KG)';
        serves = 'Serves 25-30';
        break;
      case 'large':
      case 'full':
      default:
        price = fullDaigPrice;
        label = 'Large Deg (12-14 KG)';
        serves = 'Serves 35-45';
        break;
    }

    final extraInfo = [
      serves,
      if (occasion.isNotEmpty) 'Occasion: $occasion',
      if (notes.isNotEmpty) 'Notes: $notes',
      'Fresh coal dum cooked',
    ].join(' • ');

    return FoodItem(
      id: '${id}_${sizeName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: centerId,
      name: '$name ($label)',
      description: '$description • $extraInfo',
      price: price,
      imageUrl: imageUrl,
      category: 'Deg',
      rating: rating,
      calories: sizeName == 'small' ? 6000 : (sizeName == 'medium' ? 9500 : 13000),
      isPopular: true,
      isVegetarian: category == 'Sweet & Desserts',
    );
  }
}
