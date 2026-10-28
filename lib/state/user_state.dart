import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

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
  final String? rejectionReason;
  final double latitude;
  final double longitude;

  String get address => deliveryAddress;

  bool get isPakwan =>
      isDaigBooking ||
      restaurantName.toLowerCase().contains('pakwan') ||
      items.any((i) =>
          i.toLowerCase().contains('daig') ||
          i.toLowerCase().contains('deg') ||
          i.toLowerCase().contains('qorma') ||
          i.toLowerCase().contains('pulao'));

  String get categoryLabel =>
      isPakwan ? 'شاہی پکوان (Shahi Pakwan)' : 'فوڈ ریسٹورنٹ (Restaurant)';

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
    this.rejectionReason,
    this.latitude = 31.5204,
    this.longitude = 74.3587,
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
    String? rejectionReason,
    double? latitude,
    double? longitude,
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
      rejectionReason: rejectionReason ?? this.rejectionReason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
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
  Timer? _liveSyncTimer;
  final Map<String, String> _lastKnownOrderStatuses = {};

  UserState({bool enablePeriodicSync = true}) {
    _initOrderTracking(enablePeriodicSync: enablePeriodicSync);
  }

  void _initOrderTracking({bool enablePeriodicSync = true}) {
    for (final o in _orders) {
      _lastKnownOrderStatuses[o.id] = o.status;
    }
    // Periodic live sync for active orders every 10 seconds
    if (enablePeriodicSync) {
      _liveSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _pollBackendForUpdates();
      });
    }
  }

  void _pollBackendForUpdates() {
    final hasActive = _orders.any((o) => o.status != 'Delivered' && o.status != 'Cancelled');
    if (hasActive) {
      ApiService.instance.syncWithBackend(userState: this);
    }
  }

  @override
  void dispose() {
    _liveSyncTimer?.cancel();
    super.dispose();
  }

  bool _isLoggedIn = false; // Guest user mode enabled by default
  UserProfile? _user;

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

  String _riderName = 'Captain Ali Raza';
  String _riderPhone = '+92 302 9988776';
  String _riderVehicle = 'Honda CG 125 (LED-4921)';
  String _riderCity = 'Lahore (Gulberg & DHA)';
  String _riderCnic = '35202-8492019-1';
  bool _riderIsOnline = true;
  String _riderOutletName = 'Shahi Pakwan Center (Deg & Catering)';
  String _riderOutletId = 'sub_admin_2';
  String _riderOutletPhone = '+92 301 4455667';
  String _riderOutletAddress = 'Bungalow 18-C, Model Town, Lahore';
  String _riderOutletType = 'pakwan';

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  UserProfile? get user => _user;
  String get userName => _user?.name ?? 'Hassan Raza';
  String get userPhone => _user?.phone ?? '+92 300 8472910';
  String get riderName => _riderName;
  String get riderPhone => _riderPhone;
  String get riderVehicle => _riderVehicle;
  String get riderCity => _riderCity;
  String get riderCnic => _riderCnic;
  bool get riderIsOnline => _riderIsOnline;
  String get riderOutletName => _riderOutletName;
  String get riderOutletId => _riderOutletId;
  String get riderOutletPhone => _riderOutletPhone;
  String get riderOutletAddress => _riderOutletAddress;
  String get riderOutletType => _riderOutletType;

  void setRiderOutlet({
    required String outletName,
    required String outletId,
    String? outletPhone,
    String? outletAddress,
    String? outletType,
  }) {
    _riderOutletName = outletName;
    _riderOutletId = outletId;
    if (outletPhone != null && outletPhone.isNotEmpty) _riderOutletPhone = outletPhone;
    if (outletAddress != null && outletAddress.isNotEmpty) _riderOutletAddress = outletAddress;
    if (outletType != null && outletType.isNotEmpty) _riderOutletType = outletType;
    notifyListeners();
  }
  List<UserAddress> get addresses => List.unmodifiable(_addresses);
  List<UserOrder> get orders => List.unmodifiable(_orders);

  void updateRiderProfile({
    String? name,
    String? phone,
    String? vehicle,
    String? city,
    String? cnic,
  }) {
    if (name != null && name.trim().isNotEmpty) _riderName = name.trim();
    if (phone != null && phone.trim().isNotEmpty) _riderPhone = phone.trim();
    if (vehicle != null && vehicle.trim().isNotEmpty) _riderVehicle = vehicle.trim();
    if (city != null && city.trim().isNotEmpty) _riderCity = city.trim();
    if (cnic != null && cnic.trim().isNotEmpty) _riderCnic = cnic.trim();
    notifyListeners();
  }

  void setRiderOnlineStatus(bool isOnline) {
    _riderIsOnline = isOnline;
    notifyListeners();
  }

  void toggleRiderOnlineStatus() {
    _riderIsOnline = !_riderIsOnline;
    notifyListeners();
  }

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
    String? restaurantId,
    String? subAdminId,
    double? latitude,
    double? longitude,
  }) {
    final newId = 'FC-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
    final orderLat = latitude ?? 31.5204;
    final orderLng = longitude ?? 74.3587;
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
      latitude: orderLat,
      longitude: orderLng,
    );
    _orders.insert(0, newOrder);
    _lastKnownOrderStatuses[newId] = 'Accepted';
    notifyListeners();

    // Trigger instant local notification for order confirmation
    NotificationService.instance.showStatusUpdateNotification(
      orderId: newId,
      newStatus: 'Accepted',
      restaurantName: restaurantName,
      address: deliveryAddress,
    );

    // If Daig booking, schedule reminder for 2 hours before the event
    if (isDaigBooking) {
      NotificationService.instance.scheduleDaigBookingReminder(
        orderId: newId,
        occasion: occasion ?? 'Special Dawat',
        eventTime: DateTime.now().add(const Duration(hours: 4)),
      );
    }

    // Persist new order to PHP SQLite backend
    ApiService.instance.sendOrderToBackend({
      'id': newId,
      'restaurantName': restaurantName,
      'restaurantId': restaurantId ?? '',
      'restaurantImage': restaurantImage,
      'items': items,
      'totalAmount': totalAmount,
      'originalAmount': originalAmount,
      'discountInfo': discountInfo,
      'deliveryAddress': deliveryAddress,
      'prepTime': prepTime,
      'customerName': _user?.name ?? 'Guest User',
      'customerPhone': _user?.phone ?? '+92 300 0000000',
      'isDaigBooking': isDaigBooking,
      'occasion': occasion,
      'notes': notes ?? '',
      'sub_admin_id': subAdminId ?? '',
      'latitude': orderLat,
      'longitude': orderLng,
    });
  }

  void syncOrdersFromBackend(List<UserOrder> syncedOrders) {
    for (final order in syncedOrders) {
      final prevStatus = _lastKnownOrderStatuses[order.id];
      if (prevStatus != null &&
          prevStatus.trim().toLowerCase() != order.status.trim().toLowerCase()) {
        debugPrint(
            '[UserState] Live status changed for order ${order.id}: "$prevStatus" -> "${order.status}"');
        // Trigger local notification for customer!
        NotificationService.instance.showStatusUpdateNotification(
          orderId: order.id,
          newStatus: order.status,
          restaurantName: order.restaurantName,
          riderName: order.riderName,
          address: order.deliveryAddress,
        );
      }
      _lastKnownOrderStatuses[order.id] = order.status;
    }
    _orders.clear();
    _orders.addAll(syncedOrders);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus, {String? prepTime}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      final prevStatus = _orders[idx].status;
      _orders[idx].status = newStatus;
      if (prepTime != null && prepTime.isNotEmpty) {
        _orders[idx].prepTime = prepTime;
      }
      if (prevStatus.trim().toLowerCase() != newStatus.trim().toLowerCase()) {
        _lastKnownOrderStatuses[orderId] = newStatus;
        // Trigger local notification
        NotificationService.instance.showStatusUpdateNotification(
          orderId: orderId,
          newStatus: newStatus,
          restaurantName: _orders[idx].restaurantName,
          riderName: _orders[idx].riderName,
          address: _orders[idx].deliveryAddress,
        );
      }
      notifyListeners();
      ApiService.instance.updateOrderStatusOnBackend(orderId, newStatus, prepTime: prepTime);
    }
  }

  void assignRider(String orderId, {String? riderName, String? riderPhone}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx].riderName = riderName ?? 'Ali Raza (Rider #R-41)';
      _orders[idx].riderPhone = riderPhone ?? '+92 301 5551234';
      _orders[idx].status = 'On the Way';
      _lastKnownOrderStatuses[orderId] = 'On the Way';
      NotificationService.instance.showStatusUpdateNotification(
        orderId: orderId,
        newStatus: 'On the Way',
        restaurantName: _orders[idx].restaurantName,
        riderName: _orders[idx].riderName,
        address: _orders[idx].deliveryAddress,
      );
      notifyListeners();
      ApiService.instance.updateOrderStatusOnBackend(orderId, 'On the Way');
    }
  }

  void updateOrderNotes(String orderId, String notes) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx].notes = notes;
      notifyListeners();
    }
  }

  void rejectOrder(String orderId, {String? reason}) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      final rejectReason = reason ?? 'Rider unavailable or cancelled delivery';
      _orders[idx].status = 'Cancelled';
      _orders[idx] = _orders[idx].copyWith(
        status: 'Cancelled',
        rejectionReason: rejectReason,
      );
      _lastKnownOrderStatuses[orderId] = 'Cancelled';
      NotificationService.instance.showStatusUpdateNotification(
        orderId: orderId,
        newStatus: 'Cancelled',
        restaurantName: _orders[idx].restaurantName,
        riderName: _orders[idx].riderName,
        address: _orders[idx].deliveryAddress,
      );
      notifyListeners();
      ApiService.instance.updateOrderStatusOnBackend(
        orderId,
        'Cancelled',
        notes: rejectReason,
        rejectionReason: rejectReason,
      );
    }
  }

  // Live Login with PHP SQLite Backend Authentication
  Future<bool> login({
    required String email,
    required String password,
    String? name,
    String? phone,
    UserRole? role,
  }) async {
    final cleanEmail = email.trim();
    final detectedName = name != null && name.trim().isNotEmpty
        ? name.trim()
        : _extractNameFromEmail(cleanEmail);

    // Call live PHP SQLite backend API
    final apiRes = await ApiService.instance.login(email: cleanEmail, password: password);
    if (apiRes != null && apiRes['user'] != null) {
      final u = apiRes['user'] as Map<String, dynamic>;
      final roleStr = (u['role'] as String? ?? 'client').toLowerCase();
      if (roleStr.contains('admin')) {
        _currentRole = UserRole.admin;
      } else if (roleStr.contains('rider')) {
        _currentRole = UserRole.rider;
      } else {
        _currentRole = UserRole.client;
      }

      _user = UserProfile(
        name: u['name'] ?? detectedName,
        email: u['email'] ?? cleanEmail,
        phone: u['phone'] ?? (phone != null && phone.trim().isNotEmpty ? phone.trim() : '+92 300 1234567'),
        city: u['city'] ?? 'Lahore',
        membershipTier: u['membershipTier'] ?? (_currentRole == UserRole.admin
            ? 'Admin Manager 🛠️'
            : (_currentRole == UserRole.rider ? 'Delivery Rider 🛵' : 'Valued Member')),
        walletBalance: (u['walletBalance'] as num?)?.toDouble() ?? 2450.0,
        loyaltyCoins: (u['loyaltyCoins'] as num?)?.toInt() ?? 580,
      );
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    // Fallback: Local offline authentication
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
    return true;
  }

  // Live Registration on PHP SQLite Backend
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.client,
  }) async {
    _currentRole = role;
    final roleStr = role == UserRole.rider ? 'rider' : (role == UserRole.admin ? 'admin' : 'client');

    // Register on live PHP SQLite backend
    final apiRes = await ApiService.instance.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: roleStr,
    );

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
    return apiRes != null;
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
