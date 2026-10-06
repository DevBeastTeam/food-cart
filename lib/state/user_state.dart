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

enum UserRole {
  client, // Customer ordering food
  rider,  // Delivery Rider
  admin,  // Kitchen and Restaurant Manager
}

class UserOrder {
  final String id;
  final String restaurantName;
  final String restaurantImage;
  final List<String> items;
  final double totalAmount;
  final double? originalAmount;
  final String? discountInfo;
  final DateTime orderDate;
  String status; // 'Accepted', 'Preparing', 'On the Way', 'Delivered', 'Cancelled'
  final bool isDaigBooking;
  final String? occasion;
  final int? rating;
  final String deliveryAddress;
  String prepTime;
  final String? foodItemId;
  String? notes;
  String? riderName;
  String? riderPhone;
  final String customerName;
  final String customerPhone;

  String get address => deliveryAddress;

  UserOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantImage,
    required this.items,
    required this.totalAmount,
    this.originalAmount,
    this.discountInfo,
    required this.orderDate,
    required this.status,
    this.isDaigBooking = false,
    this.occasion,
    this.rating,
    this.deliveryAddress = 'Home • Gulberg III, Main Blvd, Lahore',
    this.prepTime = '25-35 mins',
    this.foodItemId,
    this.notes,
    this.riderName,
    this.riderPhone,
    this.customerName = 'Hassan Raza',
    this.customerPhone = '+92 300 8472910',
  });

  UserOrder copyWith({
    String? status,
    String? notes,
    int? rating,
    String? prepTime,
    String? riderName,
    String? riderPhone,
    String? discountInfo,
    String? customerName,
    String? customerPhone,
  }) {
    return UserOrder(
      id: id,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      items: items,
      totalAmount: totalAmount,
      originalAmount: originalAmount,
      discountInfo: discountInfo ?? this.discountInfo,
      orderDate: orderDate,
      status: status ?? this.status,
      isDaigBooking: isDaigBooking,
      occasion: occasion,
      rating: rating ?? this.rating,
      deliveryAddress: deliveryAddress,
      prepTime: prepTime ?? this.prepTime,
      foodItemId: foodItemId,
      notes: notes ?? this.notes,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
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
    this.membershipTier = 'FoodCourt Member',
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
    membershipTier: 'FoodCourt Member',
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
      restaurantName: 'Dawat Khana Desi Heritage',
      restaurantImage: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80',
      items: ['1x Shahi Qorma Special', '2x Roghani Naan', '1x Kheer'],
      totalAmount: 1850.0,
      originalAmount: 2150.0,
      discountInfo: '40% OFF applied (Saved Rs. 300)',
      orderDate: DateTime.now().subtract(const Duration(minutes: 15)),
      status: 'Preparing',
      prepTime: '20 mins',
      customerName: 'Hassan Raza',
      customerPhone: '+92 300 8472910',
      deliveryAddress: 'House 42, Block H, Phase 5, DHA, Lahore',
      isDaigBooking: false,
    ),
    UserOrder(
      id: 'FC-8924',
      restaurantName: 'Shahi Pakwan Center (Deg Booking)',
      restaurantImage: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
      items: ['1x Full Shahi Mutton Daig (12 KG)', '4L Zeera Raita', 'Fresh Garden Salad'],
      totalAmount: 26500.0,
      originalAmount: 27500.0,
      discountInfo: 'Rs. 1,000 OFF Voucher applied',
      orderDate: DateTime.now().subtract(const Duration(minutes: 50)),
      status: 'Accepted',
      prepTime: '2 hours',
      customerName: 'Chaudhry Tariq',
      customerPhone: '+92 301 4455667',
      deliveryAddress: 'Bungalow 18-C, Model Town, Lahore',
      isDaigBooking: true,
      occasion: 'Family Dawat & Khatam',
    ),
    UserOrder(
      id: 'FC-8419',
      restaurantName: 'Bannu Beef Pulao & Nalli Nihari',
      restaurantImage: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=300&q=80',
      items: ['1x Special Bannu Beef Pulao (Double Nalli)', '2x Shami Kabab'],
      totalAmount: 1450.0,
      originalAmount: 1750.0,
      discountInfo: 'Flat 40% OFF applied',
      orderDate: DateTime.now().subtract(const Duration(minutes: 35)),
      status: 'On the Way',
      prepTime: 'Rider on route',
      riderName: 'Captain Ali Raza',
      riderPhone: '+92 302 9988776',
      customerName: 'Usman Ghani',
      customerPhone: '+92 321 8877665',
      deliveryAddress: 'Tower B, 4th Floor, Main Blvd, Gulberg III, Lahore',
      isDaigBooking: false,
    ),
    UserOrder(
      id: 'FC-8312',
      restaurantName: 'FoodCourt Central Kitchen',
      restaurantImage: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300&q=80',
      items: ['2x Degi Mutton Biryani (Single Platter)', '1x Mint Margarita'],
      totalAmount: 2100.0,
      originalAmount: 2400.0,
      discountInfo: 'CRAVEE40 applied',
      orderDate: DateTime.now().subtract(const Duration(minutes: 10)),
      status: 'Accepted',
      prepTime: '15 mins',
      customerName: 'Dr. Ayesha Malik',
      customerPhone: '+92 333 4455112',
      deliveryAddress: 'Doctors Hostel, CMH Cantt, Lahore',
      isDaigBooking: false,
    ),
    UserOrder(
      id: 'FC-8205',
      restaurantName: 'Waris Nihari & Sheermal House',
      restaurantImage: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&q=80',
      items: ['1x Maghaz Nalli Nihari', '3x Kulcha Naan'],
      totalAmount: 1350.0,
      originalAmount: 1550.0,
      discountInfo: 'Free Delivery',
      orderDate: DateTime.now().subtract(const Duration(minutes: 25)),
      status: 'Preparing',
      prepTime: '18 mins',
      customerName: 'Bilal Farooq',
      customerPhone: '+92 300 9988112',
      deliveryAddress: 'Plaza 14, Commercial Area, Cavalry Ground, Lahore',
      isDaigBooking: false,
    ),
    UserOrder(
      id: 'FC-8110',
      restaurantName: 'Karachi Student Biryani Center',
      restaurantImage: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
      items: ['2x Double Chicken Biryani', '2x Cold Drink (500ml)'],
      totalAmount: 1100.0,
      originalAmount: 1300.0,
      discountInfo: 'Rs. 200 OFF applied',
      orderDate: DateTime.now().subtract(const Duration(minutes: 40)),
      status: 'On the Way',
      prepTime: '5 mins away',
      riderName: 'Captain Ali Raza',
      riderPhone: '+92 302 9988776',
      customerName: 'Hamza Sheikh',
      customerPhone: '+92 304 5566778',
      deliveryAddress: 'Flat 302, Pace Woodlands, Bedian Road, Lahore',
      isDaigBooking: false,
    ),
    UserOrder(
      id: 'FC-8055',
      restaurantName: 'Shahi Pakwan Center (Deg Booking)',
      restaurantImage: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
      items: ['1x Half Beef Degi Yakhni Pulao (6 KG)', '2L Podina Raita'],
      totalAmount: 7400.0,
      originalAmount: 8400.0,
      discountInfo: 'DAWAT1000 applied (Saved Rs. 1,000)',
      orderDate: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      status: 'Preparing',
      prepTime: '45 mins',
      customerName: 'Malik Sohail',
      customerPhone: '+92 322 1122334',
      deliveryAddress: 'House 95, Sector Y, Phase 3, DHA, Lahore',
      isDaigBooking: true,
      occasion: 'Mehndi Function',
    ),
    UserOrder(
      id: 'FC-7910',
      restaurantName: 'Butt Karahi & Shinwari Dera',
      restaurantImage: 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300&q=80',
      items: ['1x Desi Ghee Mutton Shinwari (1 KG)', '4x Roghani Naan', '1x Zeera Raita'],
      totalAmount: 3200.0,
      originalAmount: 3500.0,
      discountInfo: 'Free Delivery coupon applied',
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Delivered',
      prepTime: 'Completed',
      customerName: 'Hassan Raza',
      customerPhone: '+92 300 8472910',
      deliveryAddress: 'House 42, Block H, Phase 5, DHA, Lahore',
      isDaigBooking: false,
      rating: 5,
    ),
    UserOrder(
      id: 'FC-7820',
      restaurantName: 'Bundu Khan Grill & BBQ',
      restaurantImage: 'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?w=300&q=80',
      items: ['1x Chicken Reshmi Kabab (4 Pcs)', '1x Malai Boti', '2x Paratha'],
      totalAmount: 1680.0,
      originalAmount: 1880.0,
      discountInfo: 'Saved Rs. 200',
      orderDate: DateTime.now().subtract(const Duration(days: 3)),
      status: 'Delivered',
      prepTime: 'Completed',
      customerName: 'Zainab Bibi',
      customerPhone: '+92 305 7788990',
      deliveryAddress: 'House 12, Street 4, Gulshan-e-Ravi, Lahore',
      isDaigBooking: false,
      rating: 5,
    ),
    UserOrder(
      id: 'FC-7750',
      restaurantName: 'Gourmet Sweets & Bakers',
      restaurantImage: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=300&q=80',
      items: ['1 KG Shahi Motichoor Laddu', '1x Pistachio Kulfi Tub'],
      totalAmount: 1250.0,
      originalAmount: 1400.0,
      discountInfo: 'Weekend Sweet Deal applied',
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Delivered',
      prepTime: 'Completed',
      customerName: 'Khurram Shehzad',
      customerPhone: '+92 331 6677889',
      deliveryAddress: 'House 7, Eden City, Airport Road, Lahore',
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
  String get userName => _user?.name ?? 'Hassan Raza';
  String get userPhone => _user?.phone ?? '+92 300 8472910';
  String get riderName => 'Captain Ali Raza';
  String get riderPhone => '+92 302 9988776';
  List<UserAddress> get addresses => List.unmodifiable(_addresses);
  List<UserOrder> get orders => List.unmodifiable(_orders);
  List<UserVoucher> get vouchers => List.unmodifiable(_vouchers);

  UserAddress get defaultAddress {
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  UserRole _currentRole = UserRole.client;
  UserRole get currentRole => _currentRole;

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void sendSupportMessage({
    required String subject,
    required String message,
    String? customerName,
    String? phone,
  }) {
    notifyListeners();
  }

  int get activeOrdersCount {
    return _orders.where((o) => o.status != 'Delivered' && o.status != 'Cancelled').length;
  }

  void placeOrder({
    required String restaurantName,
    required String restaurantImage,
    required List<String> items,
    required double totalAmount,
    double? originalAmount,
    String? discountInfo,
    required String deliveryAddress,
    required String prepTime,
    bool isDaigBooking = false,
    String? occasion,
    String? foodItemId,
    String? notes,
  }) {
    final newId = 'FC-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    final newOrder = UserOrder(
      id: newId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      items: items,
      totalAmount: totalAmount,
      originalAmount: originalAmount,
      discountInfo: discountInfo,
      orderDate: DateTime.now(),
      status: 'Accepted',
      isDaigBooking: isDaigBooking,
      occasion: occasion,
      deliveryAddress: deliveryAddress,
      prepTime: prepTime,
      foodItemId: foodItemId,
      notes: notes,
    );
    _orders.insert(0, newOrder);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus, {String? prepTime}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx].status = newStatus;
      if (prepTime != null && prepTime.isNotEmpty) {
        _orders[idx].prepTime = prepTime;
      }
      notifyListeners();
    }
  }

  void assignRider(String orderId, {String? riderName, String? riderPhone}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx].riderName = riderName ?? 'Ali Raza (Rider #R-41)';
      _orders[idx].riderPhone = riderPhone ?? '+92 301 5551234';
      _orders[idx].status = 'On the Way';
      notifyListeners();
    }
  }

  void updateOrderNotes(String orderId, String notes) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx].notes = notes;
      notifyListeners();
    }
  }

  // Local / Mock Login with Role support
  void login({
    required String email,
    required String password,
    String? name,
    String? phone,
    UserRole? role,
  }) {
    final cleanEmail = email.trim();
    final detectedName = name != null && name.trim().isNotEmpty
        ? name.trim()
        : _extractNameFromEmail(cleanEmail);

    if (role != null) {
      _currentRole = role;
    } else if (cleanEmail == 'admin@gmail.com' || cleanEmail == 'admin@foodcourt.pk') {
      _currentRole = UserRole.admin;
    } else if (cleanEmail.contains('rider')) {
      _currentRole = UserRole.rider;
    } else {
      _currentRole = UserRole.client;
    }

    _user = UserProfile(
      name: detectedName,
      email: cleanEmail.isNotEmpty ? cleanEmail : 'user@foodcourt.pk',
      phone: phone != null && phone.trim().isNotEmpty ? phone.trim() : '+92 300 1234567',
      city: 'Lahore',
      membershipTier: _currentRole == UserRole.admin
          ? 'Admin Manager 🛠️'
          : (_currentRole == UserRole.rider ? 'Delivery Rider 🛵' : 'Valued Member'),
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
    UserRole role = UserRole.client,
  }) {
    _currentRole = role;
    _user = UserProfile(
      name: name.trim().isNotEmpty ? name.trim() : 'Foodie Member',
      email: email.trim().isNotEmpty ? email.trim() : 'member@foodcourt.pk',
      phone: phone.trim().isNotEmpty ? phone.trim() : '+92 300 0000000',
      city: 'Lahore & Islamabad',
      membershipTier: role == UserRole.rider ? 'Delivery Rider 🛵' : 'FoodCourt Pro ⭐',
      walletBalance: 500.0,
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
