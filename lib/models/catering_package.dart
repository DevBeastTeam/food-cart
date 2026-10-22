import 'food_item.dart';

class CateringPackage {
  final String id;
  final String name;
  final String urduName;
  final String occasion; // 'Wedding / Walima', 'Dawat / Family Gathering', 'Niyaz / Milad', 'Birthday / Event'
  final String description;
  final double pricePerHead;
  final int minGuests;
  final String imageUrl;
  final List<String> menuItems;
  final List<String> includes;
  final String badge;
  final String centerId;
  final String centerName;

  const CateringPackage({
    required this.id,
    required this.name,
    required this.urduName,
    required this.occasion,
    required this.description,
    required this.pricePerHead,
    this.minGuests = 50,
    required this.imageUrl,
    required this.menuItems,
    this.includes = const [
      'Fresh Coal-Dum Cooking',
      'Atta-Sealed Hot Cauldrons',
      'Free Mint Zeera Raita & Kachumber Salad',
      'Delivery & Table Setup Support',
    ],
    this.badge = 'Popular Package',
    this.centerId = 'pakwan_shahi',
    this.centerName = 'Shahi Pakwan Center',
  });

  factory CateringPackage.fromJson(Map<String, dynamic> json) {
    return CateringPackage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      urduName: json['urduName'] ?? '',
      occasion: json['occasion'] ?? 'Dawat / Family Gathering',
      description: json['description'] ?? '',
      pricePerHead: (json['pricePerHead'] as num?)?.toDouble() ?? 1200.0,
      minGuests: json['minGuests'] ?? 50,
      imageUrl: json['imageUrl'] ?? '',
      menuItems: List<String>.from(json['menuItems'] ?? []),
      includes: List<String>.from(json['includes'] ?? []),
      badge: json['badge'] ?? '',
      centerId: json['centerId'] ?? 'pakwan_shahi',
      centerName: json['centerName'] ?? 'Shahi Pakwan Center',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'urduName': urduName,
      'occasion': occasion,
      'description': description,
      'pricePerHead': pricePerHead,
      'minGuests': minGuests,
      'imageUrl': imageUrl,
      'menuItems': menuItems,
      'includes': includes,
      'badge': badge,
      'centerId': centerId,
      'centerName': centerName,
    };
  }

  // Convert to FoodItem for seamless cart integration
  FoodItem toFoodItem({
    required int guestCount,
    required String eventDate,
    required String eventTime,
    required String eventLocation,
    String specialRequests = '',
  }) {
    final totalPrice = pricePerHead * guestCount;
    return FoodItem(
      id: 'pkg_${id}_${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: centerId,
      name: '$name ($guestCount Guests)',
      description: 'Event: $occasion • Date: $eventDate ($eventTime) • Venue: $eventLocation. Menu: ${menuItems.join(", ")}'
          '${specialRequests.isNotEmpty ? " • Notes: $specialRequests" : ""}',
      price: totalPrice,
      imageUrl: imageUrl,
      category: 'Catering Package',
      rating: 5.0,
      calories: 0,
      isPopular: true,
      isVegetarian: false,
    );
  }
}
