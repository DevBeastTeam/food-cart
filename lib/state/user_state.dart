import 'package:flutter/foundation.dart';

class UserAddress {
  final String label;
  final String fullAddress;
  final String city;
  final bool isDefault;

  const UserAddress({
    required this.label,
    required this.fullAddress,
    required this.city,
    this.isDefault = false,
  });

  UserAddress copyWith({
    String? label,
    String? fullAddress,
    String? city,
    bool? isDefault,
  }) {
    return UserAddress(
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class UserOrder {
  final String id;
  final String restaurantName;
  final String restaurantImage;
  final List<String> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status; // 'Delivered', 'On the Way', 'Preparing'
  final bool isDaigBooking;
  final String? occasion;
  final int? rating;

  const UserOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantImage,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.isDaigBooking = false,
    this.occasion,
    this.rating,
  });
}

class UserVoucher {
  final String code;
  final String title;
  final String discount;
  final String minSpend;
  final String expiry;
  final bool isExclusive;

  const UserVoucher({
    required this.code,
    required this.title,
    required this.discount,
    required this.minSpend,
    required this.expiry,
    this.isExclusive = false,
  });
}

class UserProfile {
  String name;
  String email;
  String phone;
  String city;
  String membershipTier;
  double walletBalance;
  int loyaltyCoins;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.city = 'Lahore',
    this.membershipTier = 'FoodCourt Pro ⭐',
    this.walletBalance = 2450.0,
    this.loyaltyCoins = 580,
  });
}

class UserState extends ChangeNotifier {
  bool _isLoggedIn = true;
  UserProfile? _user = UserProfile(
    name: 'Hassan Raza',
    email: 'hassan.raza@foodcourt.pk',
    phone: '+92 300 8472910',
    city: 'Lahore & Islamabad',
    membershipTier: 'FoodCourt Pro ⭐',
    walletBalance: 2450.0,
    loyaltyCoins: 580,
  );

  final List<UserAddress> _addresses = [
    const UserAddress(
      label: 'Home',
      fullAddress: 'House 42, Block H, Phase 5, DHA',
      city: 'Lahore',
      isDefault: true,
    ),
    const UserAddress(
      label: 'Office',
      fullAddress: 'Tower B, 4th Floor, Main Boulevard, Gulberg III',
      city: 'Lahore',
      isDefault: false,
    ),
    const UserAddress(
      label: 'Islamabad Residence',
      fullAddress: 'Apartment 7B, Silver Oaks, F-10/4',
      city: 'Islamabad',
      isDefault: false,
    ),
  ];

  final List<UserOrder> _orders = [
    UserOrder(
      id: 'FC-9481',
      restaurantName: 'Bundu Khan Desi Grill',
      restaurantImage: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80',
      items: ['1x Mutton Seekh Kabab (4 pcs)', '2x Roghani Naan', '1x Mint Raita'],
      totalAmount: 1850.0,
      orderDate: DateTime.now().subtract(const Duration(minutes: 25)),
      status: 'On the Way',
      isDaigBooking: false,
    ),
    UserOrder(
      id: 'FC-8924',
      restaurantName: 'Shahi Pakwan Center (Deg Booking)',
      restaurantImage: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
      items: ['1x Full Shahi Mutton Daig (12 KG)', '4L Zeera Raita', 'Fresh Garden Salad'],
      totalAmount: 26500.0,
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Delivered',
      isDaigBooking: true,
      occasion: 'Family Dawat & Khatam',
      rating: 5,
    ),
    UserOrder(
      id: 'FC-8419',
      restaurantName: 'The Flame Grill Burger Co.',
      restaurantImage: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&q=80',
      items: ['2x Double Smoky Beef Cheddar', '1x Curly Cheesy Fries', '2x Coke Zero'],
      totalAmount: 2240.0,
      orderDate: DateTime.now().subtract(const Duration(days: 4)),
      status: 'Delivered',
      isDaigBooking: false,
      rating: 5,
    ),
    UserOrder(
      id: 'FC-7910',
      restaurantName: 'FoodCourt Mart',
      restaurantImage: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=300&q=80',
      items: ['2x Olpers Milk 1L', '1x Farm Fresh Eggs (12 pcs)', '1x Dawn Bran Bread'],
      totalAmount: 940.0,
      orderDate: DateTime.now().subtract(const Duration(days: 6)),
      status: 'Delivered',
      isDaigBooking: false,
      rating: 4,
    ),
  ];

  final List<UserVoucher> _vouchers = [
    const UserVoucher(
      code: 'CRAVEE40',
      title: '40% Flat Discount',
      discount: '40% OFF',
      minSpend: 'Min. order Rs. 500',
      expiry: 'Valid till 30 Nov 2026',
      isExclusive: true,
    ),
    const UserVoucher(
      code: 'MARTFREE',
      title: 'Free Mart Delivery',
      discount: 'FREE DELIVERY',
      minSpend: 'On FoodCourt Mart above Rs. 399',
      expiry: 'Valid all month',
    ),
    const UserVoucher(
      code: 'PICKUP15',
      title: 'Takeaway Special',
      discount: '15% OFF',
      minSpend: 'On all Self Pick-up orders',
      expiry: 'Unlimited use',
    ),
    const UserVoucher(
      code: 'DAWAT1000',
      title: 'Shahi Deg Booking Voucher',
      discount: 'Rs. 1,000 OFF',
      minSpend: 'On orders of 2 or more Daigs',
      expiry: 'Valid till year-end',
      isExclusive: true,
    ),
  ];

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  UserProfile? get user => _user;
  List<UserAddress> get addresses => List.unmodifiable(_addresses);
  List<UserOrder> get orders => List.unmodifiable(_orders);
  List<UserVoucher> get vouchers => List.unmodifiable(_vouchers);

  UserAddress get defaultAddress {
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  int get activeOrdersCount {
    return _orders.where((o) => o.status != 'Delivered').length;
  }

  // Local / Mock Login (Any email/password works as requested)
  void login({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) {
    final cleanEmail = email.trim();
    final detectedName = name != null && name.trim().isNotEmpty
        ? name.trim()
        : _extractNameFromEmail(cleanEmail);

    _user = UserProfile(
      name: detectedName,
      email: cleanEmail.isNotEmpty ? cleanEmail : 'user@foodcourt.pk',
      phone: phone != null && phone.trim().isNotEmpty ? phone.trim() : '+92 300 1234567',
      city: 'Lahore',
      membershipTier: 'FoodCourt Pro ⭐',
      walletBalance: 2450.0,
      loyaltyCoins: 580,
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  // Local / Mock Sign Up
  void signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    _user = UserProfile(
      name: name.trim().isNotEmpty ? name.trim() : 'Foodie Member',
      email: email.trim().isNotEmpty ? email.trim() : 'member@foodcourt.pk',
      phone: phone.trim().isNotEmpty ? phone.trim() : '+92 300 0000000',
      city: 'Lahore & Islamabad',
      membershipTier: 'FoodCourt Pro ⭐',
      walletBalance: 500.0, // Welcome bonus!
      loyaltyCoins: 100,
    );
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? phone,
    String? city,
  }) {
    if (_user == null) return;
    if (name != null && name.trim().isNotEmpty) _user!.name = name.trim();
    if (phone != null && phone.trim().isNotEmpty) _user!.phone = phone.trim();
    if (city != null && city.trim().isNotEmpty) _user!.city = city.trim();
    notifyListeners();
  }

  void addFunds(double amount) {
    if (_user == null) return;
    _user!.walletBalance += amount;
    notifyListeners();
  }

  void addAddress(UserAddress newAddress) {
    if (newAddress.isDefault) {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
    _addresses.add(newAddress);
    notifyListeners();
  }

  void setDefaultAddress(int index) {
    if (index < 0 || index >= _addresses.length) return;
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: i == index);
    }
    notifyListeners();
  }

  String _extractNameFromEmail(String email) {
    if (!email.contains('@')) return 'Foodie Member';
    final raw = email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ');
    return raw.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
