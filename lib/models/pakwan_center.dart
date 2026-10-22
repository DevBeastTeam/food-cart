class PakwanCenter {
  final String id;
  final String name;
  final String urduName;
  final String description;
  final String address;
  final String phone;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String experienceYears;
  final String minAdvanceNotice;
  final List<String> specialties;
  final bool isVerified;
  final String city;

  const PakwanCenter({
    required this.id,
    required this.name,
    required this.urduName,
    required this.description,
    required this.address,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    this.experienceYears = '25+ Years Experience',
    this.minAdvanceNotice = '3-4 Hours Notice',
    this.specialties = const ['Biryani Degs', 'Pulao Degs', 'Mutton Korma', 'Zarda & Meetha'],
    this.isVerified = true,
    this.city = 'Lahore',
  });

  factory PakwanCenter.fromJson(Map<String, dynamic> json) {
    return PakwanCenter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      urduName: json['urduName'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: json['reviewCount'] ?? 100,
      imageUrl: json['imageUrl'] ?? '',
      experienceYears: json['experienceYears'] ?? '20+ Years',
      minAdvanceNotice: json['minAdvanceNotice'] ?? '3-4 Hours',
      specialties: List<String>.from(json['specialties'] ?? []),
      isVerified: json['isVerified'] ?? true,
      city: json['city'] ?? 'Lahore',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'urduName': urduName,
      'description': description,
      'address': address,
      'phone': phone,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'experienceYears': experienceYears,
      'minAdvanceNotice': minAdvanceNotice,
      'specialties': specialties,
      'isVerified': isVerified,
      'city': city,
    };
  }
}
