import 'food_item.dart';

class DaigItem {
  final String id;
  final String name;
  final String urduName;
  final String description;
  final String category; // 'Biryani & Pulao', 'Qorma & Karahi', 'Haleem & Nihari', 'Sweet & Desserts'
  final double fullDaigPrice;
  final double halfDaigPrice;
  final String fullDaigWeight;
  final String halfDaigWeight;
  final String imageUrl;
  final double rating;
  final String deliveryNotice;
  final String badge;
  final List<String> includes;

  const DaigItem({
    required this.id,
    required this.name,
    required this.urduName,
    required this.description,
    required this.category,
    required this.fullDaigPrice,
    required this.halfDaigPrice,
    this.fullDaigWeight = '12 KG (Serves 35-40 Persons)',
    this.halfDaigWeight = '6 KG (Serves 18-20 Persons)',
    required this.imageUrl,
    this.rating = 4.9,
    this.deliveryNotice = 'Order 3-4 hours in advance for fresh dum cooking',
    this.badge = 'Bestseller Daig',
    this.includes = const ['Clay-sealed hot Daig', 'Spicy Raita Tub (2 Litre)', 'Fresh Mint Salad'],
  });

  // Convert to FoodItem for seamless cart integration
  FoodItem toFoodItem({required bool isFullDaig}) {
    final sizeLabel = isFullDaig ? 'Full Daig (12 KG)' : 'Half Daig (6 KG)';
    final price = isFullDaig ? fullDaigPrice : halfDaigPrice;
    final serves = isFullDaig ? 'Serves 35-40' : 'Serves 18-20';

    return FoodItem(
      id: '${id}_${isFullDaig ? "full" : "half"}',
      restaurantId: 'rest_pakwan',
      name: '$name ($sizeLabel)',
      description: '$description • $serves • Freshly cooked on coal dum.',
      price: price,
      imageUrl: imageUrl,
      category: 'Deg',
      rating: rating,
      calories: isFullDaig ? 12000 : 6000,
      isPopular: true,
      isVegetarian: category == 'Sweet & Desserts',
    );
  }
}
