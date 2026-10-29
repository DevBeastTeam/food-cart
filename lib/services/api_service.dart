import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/sample_data.dart';
import '../models/daig_item.dart';
import '../models/food_item.dart';
import '../models/restaurant.dart';
import '../state/user_state.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  /// Production Hostinger URL live on food.aztemp.com
  static const String liveProductionUrl = 'https://food.aztemp.com/api';

  /// Base URL override (defaults to live production Hostinger server)
  static String? customBaseUrl = liveProductionUrl;

  // Dynamic Base URL based on platform & environment
  String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return liveProductionUrl;
  }

  bool _isBackendConnected = false;
  bool get isBackendConnected => _isBackendConnected;

  Map<String, dynamic> _appContent = {};
  Map<String, dynamic> get appContent => _appContent;

  Map<String, dynamic> _appSettings = {};
  Map<String, dynamic> get appSettings => _appSettings;

  List<Map<String, dynamic>> _activeDeals = [];
  List<Map<String, dynamic>> get activeDeals => _activeDeals;

  List<Map<String, dynamic>> _promoBanners = [];
  List<Map<String, dynamic>> get promoBanners => _promoBanners;

  // Initialize and sync data from backend on app launch
  Future<void> syncWithBackend({UserState? userState}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/content')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = _safeJsonDecode(res.body);
        if (decoded != null && decoded['data'] is Map<String, dynamic>) {
          _isBackendConnected = true;
          final data = decoded['data'] as Map<String, dynamic>;
          _appContent = data;

          // Sync Addresses into SampleData
          if (data['addresses'] is List) {
            final List<String> fetchedAddrs = List<String>.from(data['addresses']);
            if (fetchedAddrs.isNotEmpty) {
              SampleData.sampleAddresses.clear();
              SampleData.sampleAddresses.addAll(fetchedAddrs);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Content sync offline/fallback: $e');
    }

    // Sync Restaurants & Menu Items
    try {
      final res = await http.get(Uri.parse('$baseUrl/restaurants')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = _safeJsonDecode(res.body);
        final list = decoded != null && decoded['data'] is List ? (decoded['data'] as List) : null;
        if (list != null && list.isNotEmpty) {
          final foodRes = await http.get(Uri.parse('$baseUrl/food-items')).timeout(const Duration(seconds: 4));
          final decodedFood = _safeJsonDecode(foodRes.body);
          final allFood = foodRes.statusCode == 200 && decodedFood != null && decodedFood['data'] is List
              ? (decodedFood['data'] as List).map((i) => _parseFoodItem(i)).toList()
              : <FoodItem>[];

          final List<Restaurant> parsedRestaurants = [];
          for (final r in list) {
            final restaurantMenu = allFood.where((f) => f.restaurantId == r['id']).toList();
            parsedRestaurants.add(Restaurant(
              id: r['id'],
              name: r['name'],
              cuisine: r['cuisine'],
              imageUrl: r['imageUrl'],
              rating: (r['rating'] as num).toDouble(),
              reviewCount: r['reviewCount'] as int,
              deliveryTime: r['deliveryTime'],
              deliveryFee: (r['deliveryFee'] as num).toDouble(),
              minOrder: (r['minOrder'] as num).toDouble(),
              distance: r['distance'],
              address: r['address'],
              badge: r['badge'] ?? '',
              isFeatured: r['isFeatured'] ?? false,
              categories: List<String>.from(r['categories'] ?? ['All']),
              menu: restaurantMenu,
            ));
          }

          if (parsedRestaurants.isNotEmpty) {
            SampleData.restaurants.clear();
            SampleData.restaurants.addAll(parsedRestaurants);
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Restaurants sync offline/fallback: $e');
    }

    // Sync Daig Dishes
    try {
      final res = await http.get(Uri.parse('$baseUrl/daig-items')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = _safeJsonDecode(res.body);
        final list = decoded != null && decoded['data'] is List ? (decoded['data'] as List) : null;
        if (list != null) {
          final List<DaigItem> parsedDaigs = [];
          for (final d in list) {
            final discPct = (d['discountPercent'] as num?)?.toInt() ?? 0;
            parsedDaigs.add(DaigItem(
              id: d['id'],
              name: d['name'],
              urduName: d['urduName'] ?? '',
              description: d['description'] ?? '',
              category: d['category'] ?? 'Biryani & Pulao',
              fullDaigPrice: (d['fullDaigPrice'] as num).toDouble(),
              halfDaigPrice: (d['halfDaigPrice'] as num).toDouble(),
              fullDaigWeight: d['fullDaigWeight'] ?? '12 KG',
              halfDaigWeight: d['halfDaigWeight'] ?? '6 KG',
              imageUrl: d['imageUrl'],
              rating: (d['rating'] as num?)?.toDouble() ?? 4.9,
              badge: d['badge'] ?? '',
              deliveryNotice: d['deliveryNotice'] ?? '',
              includes: List<String>.from(d['includes'] ?? []),
              discountPercent: discPct,
              discountPrice: (d['discountPrice'] as num?)?.toDouble() ?? 0.0,
              cutPrice: (d['cutPrice'] as num?)?.toDouble() ?? 0.0,
              showCutPrice: d['showCutPrice'] == 1 || d['showCutPrice'] == true || d['showCutPrice'] == null,
              location: d['location'] ?? 'Main Pakwan Kitchen, Islamabad (G-9 Markaz)',
              isDiscounted: d['isDiscounted'] == 1 || d['isDiscounted'] == true || discPct > 0,
              promoBadge: d['promoBadge'] ?? '',
              subAdminId: d['sub_admin_id'] ?? 'sub_admin_2',
              isAvailable: d['isAvailable'] == true || d['isAvailable'] == 1 || d['isVisible'] == true || d['isVisible'] == 1 || d['isVisible'] == null,
            ));
          }
          if (parsedDaigs.isNotEmpty) {
            SampleData.daigDishes.clear();
            SampleData.daigDishes.addAll(parsedDaigs);
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Daig dishes sync offline/fallback: $e');
    }

    // Sync Banners & Deals
    try {
      final bannerRes = await http.get(Uri.parse('$baseUrl/banners')).timeout(const Duration(seconds: 3));
      if (bannerRes.statusCode == 200) {
        final decoded = _safeJsonDecode(bannerRes.body);
        if (decoded != null && decoded['data'] is List) {
          _promoBanners = List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      final dealsRes = await http.get(Uri.parse('$baseUrl/deals')).timeout(const Duration(seconds: 3));
      if (dealsRes.statusCode == 200) {
        final decoded = _safeJsonDecode(dealsRes.body);
        if (decoded != null && decoded['data'] is List) {
          _activeDeals = List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      final settingsRes = await http.get(Uri.parse('$baseUrl/settings')).timeout(const Duration(seconds: 3));
      if (settingsRes.statusCode == 200) {
        final decoded = _safeJsonDecode(settingsRes.body);
        if (decoded != null && decoded['data'] is Map<String, dynamic>) {
          _appSettings = decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Secondary sync offline/fallback: $e');
    }

    // Sync Live Orders with UserState
    if (userState != null) {
      try {
        final orderRes = await http.get(Uri.parse('$baseUrl/orders')).timeout(const Duration(seconds: 4));
        if (orderRes.statusCode == 200) {
          final decoded = _safeJsonDecode(orderRes.body);
          final list = decoded != null && decoded['data'] is List ? (decoded['data'] as List) : null;
          if (list != null) {
            final List<UserOrder> syncedOrders = [];
            for (final o in list) {
              syncedOrders.add(UserOrder(
                id: o['id'],
                restaurantName: o['restaurantName'] ?? 'FoodCourt Central Kitchen',
                restaurantImage: o['restaurantImage'] ?? '',
                items: List<String>.from(o['items'] ?? []),
                totalAmount: (o['totalAmount'] as num).toDouble(),
                originalAmount: (o['originalAmount'] as num?)?.toDouble(),
                discountInfo: o['discountInfo'],
                orderDate: DateTime.tryParse(o['orderDate'] ?? '') ?? DateTime.now(),
                status: o['status'] ?? 'Accepted',
                isDaigBooking: o['isDaigBooking'] ?? false,
                occasion: o['occasion'],
                eventDate: o['event_date'] ?? o['eventDate'],
                eventTime: o['event_time'] ?? o['eventTime'],
                deliveryAddress: o['deliveryAddress'] ?? 'Lahore',
                prepTime: o['prepTime'] ?? '25 mins',
                riderName: o['riderName'],
                riderPhone: o['riderPhone'],
                customerName: o['customerName'] ?? 'Hassan Raza',
                customerPhone: o['customerPhone'] ?? '+92 300 8472910',
                notes: o['notes'],
                rejectionReason: o['rejectionReason'],
                latitude: (o['latitude'] as num?)?.toDouble() ?? 31.5204,
                longitude: (o['longitude'] as num?)?.toDouble() ?? 74.3587,
              ));
            }
            if (syncedOrders.isNotEmpty) {
              userState.syncOrdersFromBackend(syncedOrders);
            }
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Orders sync offline/fallback: $e');
      }
    }
  }

  // Fast periodic orders-only sync for real-time live customer tracking
  Future<void> syncOrdersOnly({required UserState userState}) async {
    try {
      final orderRes = await http.get(Uri.parse('$baseUrl/orders')).timeout(const Duration(seconds: 4));
      if (orderRes.statusCode == 200) {
        final decoded = _safeJsonDecode(orderRes.body);
        final list = decoded != null && decoded['data'] is List ? (decoded['data'] as List) : null;
        if (list != null) {
          final List<UserOrder> syncedOrders = [];
          for (final o in list) {
            syncedOrders.add(UserOrder(
              id: o['id'],
              restaurantName: o['restaurantName'] ?? 'FoodCourt Central Kitchen',
              restaurantImage: o['restaurantImage'] ?? '',
              items: List<String>.from(o['items'] ?? []),
              totalAmount: (o['totalAmount'] as num).toDouble(),
              originalAmount: (o['originalAmount'] as num?)?.toDouble(),
              discountInfo: o['discountInfo'],
              orderDate: DateTime.tryParse(o['orderDate'] ?? '') ?? DateTime.now(),
              status: o['status'] ?? 'Accepted',
              isDaigBooking: o['isDaigBooking'] == true || o['isDaigBooking'] == 1,
              occasion: o['occasion'],
              eventDate: o['event_date'] ?? o['eventDate'],
              eventTime: o['event_time'] ?? o['eventTime'],
              deliveryAddress: o['deliveryAddress'] ?? 'Lahore',
              prepTime: o['prepTime'] ?? '25 mins',
              riderName: o['riderName'],
              riderPhone: o['riderPhone'],
              customerName: o['customerName'] ?? 'Hassan Raza',
              customerPhone: o['customerPhone'] ?? '+92 300 8472910',
              notes: o['notes'],
              rejectionReason: o['rejectionReason'],
              latitude: (o['latitude'] as num?)?.toDouble() ?? 31.5204,
              longitude: (o['longitude'] as num?)?.toDouble() ?? 74.3587,
            ));
          }
          if (syncedOrders.isNotEmpty) {
            userState.syncOrdersFromBackend(syncedOrders);
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Orders auto-sync error: $e');
    }
  }

  // Push new order placed in Flutter app to backend
  Future<bool> sendOrderToBackend(Map<String, dynamic> orderPayload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderPayload),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 201 || res.statusCode == 200) {
        _isBackendConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ApiService] Failed to send order to backend: $e');
      return false;
    }
  }

  // Update order status on backend (for rider/admin)
  Future<bool> updateOrderStatusOnBackend(
    String orderId,
    String status, {
    String? prepTime,
    String? notes,
    String? rejectionReason,
    String? riderName,
    String? riderPhone,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (prepTime != null) body['prepTime'] = prepTime;
      if (notes != null) body['notes'] = notes;
      if (rejectionReason != null) body['rejectionReason'] = rejectionReason;
      if (riderName != null) body['riderName'] = riderName;
      if (riderPhone != null) body['riderPhone'] = riderPhone;

      final res = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Failed to update order status on backend: $e');
      return false;
    }
  }

  // Cancel order by customer (Strictly allowed only when status is Pending)
  Future<Map<String, dynamic>> cancelCustomerOrder(String orderId, {String? reason}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason ?? 'Cancelled by customer'}),
      ).timeout(const Duration(seconds: 8));

      final data = _safeJsonDecode(res.body);
      if (res.statusCode == 200 && data != null && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Order cancelled successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Could not cancel order. Kitchen may have already accepted it.',
        };
      }
    } catch (e) {
      debugPrint('[ApiService] Cancel order error: $e');
      return {
        'success': false,
        'message': 'Failed to reach server. Please check your internet connection.',
      };
    }
  }

  dynamic _safeJsonDecode(String body) {
    try {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return jsonDecode(trimmed);
      }
    } catch (_) {}
    return null;
  }

  // Authenticate user with PHP SQLite backend
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    UserState? userState,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      final data = _safeJsonDecode(res.body);
      if (res.statusCode == 200 && data != null && data['success'] == true) {
        _isBackendConnected = true;
        final resData = data['data'] as Map<String, dynamic>?;
        final uMap = resData?['user'] as Map<String, dynamic>?;
        if (uMap != null && userState != null) {
          final role = uMap['role'] ?? 'client';
          if (role == 'rider') {
            userState.setRole(UserRole.rider);
            final outletName = uMap['outlet_name'] ?? uMap['assigned_outlet']?['businessName'] ?? 'Shahi Pakwan Center';
            final outletId = uMap['assigned_sub_admin_id'] ?? uMap['assigned_outlet']?['id'] ?? 'sub_admin_2';
            final outletPhone = uMap['outlet_phone'] ?? uMap['assigned_outlet']?['phone'] ?? '+92 301 4455667';
            final outletAddress = uMap['outlet_address'] ?? uMap['assigned_outlet']?['address'] ?? 'Model Town, Lahore';
            final outletType = uMap['outlet_type'] ?? uMap['assigned_outlet']?['businessType'] ?? 'pakwan';

            userState.setRiderOutlet(
              outletName: outletName,
              outletId: outletId,
              outletPhone: outletPhone,
              outletAddress: outletAddress,
              outletType: outletType,
            );
            userState.updateRiderProfile(
              name: uMap['name'],
              phone: uMap['phone'],
            );
          }
        }
        return resData;
      } else if (data != null) {
        debugPrint('[ApiService] Login rejected: ${data['message']}');
      }
    } catch (e) {
      debugPrint('[ApiService] Login API exception: $e');
    }
    return null;
  }

  // Register new customer account in PHP SQLite backend
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'client',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(res.body);
      if ((res.statusCode == 201 || res.statusCode == 200) && data['success'] == true) {
        _isBackendConnected = true;
        return data['data'] as Map<String, dynamic>?;
      } else {
        debugPrint('[ApiService] Register rejected: ${data['message']}');
      }
    } catch (e) {
      debugPrint('[ApiService] Register API exception: $e');
    }
    return null;
  }

  // Upload image to PHP backend storage (uploads/ folder)
  Future<String?> uploadImage(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data']?['url'] as String?;
      }
    } catch (e) {
      debugPrint('[ApiService] File upload error: $e');
    }
    return null;
  }


  // Search food items from backend with local fallback
  Future<List<FoodItem>> searchFoodItems(String query, {String? subAdminId, int? page, int? limit}) async {
    final cleanQuery = query.trim().toLowerCase();

    try {
      var uriStr = '$baseUrl/food-items?search=${Uri.encodeComponent(cleanQuery)}';
      if (subAdminId != null && subAdminId != 'all' && subAdminId.isNotEmpty) {
        uriStr += '&sub_admin_id=$subAdminId';
      }
      if (page != null && page > 0) uriStr += '&page=$page';
      if (limit != null && limit > 0) uriStr += '&limit=$limit';

      final res = await http
          .get(Uri.parse(uriStr))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] is List) {
          final list = body['data'] as List;
          return list.map((i) => _parseFoodItem(i)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Search backend error/fallback: $e');
    }

    if (cleanQuery.isEmpty) return SampleData.allTrendingFoodItems;

    // Fallback: search synced/local items
    final List<FoodItem> localMatches = [];
    final seenIds = <String>{};
    for (final rest in SampleData.restaurants) {
      for (final item in rest.menu) {
        if (seenIds.add(item.id)) {
          final nameMatches = item.name.toLowerCase().contains(cleanQuery);
          final descMatches = item.description.toLowerCase().contains(cleanQuery);
          final catMatches = item.category.toLowerCase().contains(cleanQuery);
          if (nameMatches || descMatches || catMatches) {
            localMatches.add(item);
          }
        }
      }
    }
    return localMatches;
  }

  Future<List<DaigItem>> searchDaigItems(String query, {String? subAdminId, int? page, int? limit}) async {
    final cleanQuery = query.trim().toLowerCase();
    try {
      var uriStr = '$baseUrl/daig-items?search=${Uri.encodeComponent(cleanQuery)}';
      if (subAdminId != null && subAdminId != 'all' && subAdminId.isNotEmpty) {
        uriStr += '&sub_admin_id=$subAdminId';
      }
      if (page != null && page > 0) uriStr += '&page=$page';
      if (limit != null && limit > 0) uriStr += '&limit=$limit';

      final res = await http.get(Uri.parse(uriStr)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['data'] is List) {
          final list = body['data'] as List;
          return list.map((d) => _parseDaigItem(d)).toList();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Search daig backend error: $e');
    }

    return SampleData.daigDishes.where((d) {
      if (cleanQuery.isEmpty) return true;
      return d.name.toLowerCase().contains(cleanQuery) ||
          d.urduName.contains(cleanQuery) ||
          d.description.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  Map<String, dynamic>? getVendorActiveOffer(String vendorId) {
    if (_promoBanners.isEmpty) return null;
    if (vendorId.isEmpty || vendorId == 'all') {
      return _promoBanners.first;
    }
    try {
      return _promoBanners.firstWhere(
        (b) => (b['sub_admin_id'] ?? '').toString() == vendorId || (b['id'] ?? '').toString().contains(vendorId),
        orElse: () => _promoBanners.first,
      );
    } catch (_) {
      return _promoBanners.isNotEmpty ? _promoBanners.first : null;
    }
  }

  DaigItem _parseDaigItem(Map<String, dynamic> d) {
    final discPct = (d['discountPercent'] as num?)?.toInt() ?? 0;
    return DaigItem(
      id: d['id'] ?? 'daig_1',
      name: d['name'] ?? '',
      urduName: d['urduName'] ?? '',
      description: d['description'] ?? '',
      category: d['category'] ?? 'Biryani & Pulao',
      fullDaigPrice: (d['fullDaigPrice'] as num?)?.toDouble() ?? 12000.0,
      halfDaigPrice: (d['halfDaigPrice'] as num?)?.toDouble() ?? 6500.0,
      imageUrl: d['imageUrl'] ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=700&q=80',
      rating: (d['rating'] as num?)?.toDouble() ?? 4.9,
      badge: d['badge'] ?? 'Bestseller Daig',
      deliveryNotice: d['deliveryNotice'] ?? 'Order 3-4 hours in advance for fresh coal-dum cooking',
      discountPercent: discPct,
      discountPrice: (d['discountPrice'] as num?)?.toDouble() ?? 0.0,
      cutPrice: (d['cutPrice'] as num?)?.toDouble() ?? 0.0,
      showCutPrice: d['showCutPrice'] == 1 || d['showCutPrice'] == true || d['showCutPrice'] == null,
      isDiscounted: d['isDiscounted'] == 1 || d['isDiscounted'] == true || discPct > 0,
      promoBadge: d['promoBadge'] ?? '',
      location: d['location'] ?? 'Main Pakwan Kitchen, Lahore',
      subAdminId: d['sub_admin_id'] ?? '',
      centerId: d['sub_admin_id'] ?? 'pakwan_shahi',
      centerName: d['centerName'] ?? 'Shahi Pakwan Center',
    );
  }

  FoodItem _parseFoodItem(Map<String, dynamic> i) {
    final discPct = (i['discountPercent'] as num?)?.toInt() ?? 0;
    return FoodItem(
      id: i['id'],
      restaurantId: i['restaurantId'] ?? 'rest_1',
      name: i['name'],
      description: i['description'] ?? '',
      price: (i['price'] as num).toDouble(),
      imageUrl: i['imageUrl'] ?? '',
      category: i['category'] ?? 'Pulao',
      rating: (i['rating'] as num?)?.toDouble() ?? 4.9,
      calories: i['calories'] ?? 450,
      isPopular: i['isPopular'] ?? true,
      isVegetarian: i['isVegetarian'] ?? false,
      badges: List<String>.from(i['badges'] ?? ['Special']),
      discountPercent: discPct,
      discountPrice: (i['discountPrice'] as num?)?.toDouble() ?? 0.0,
      cutPrice: (i['cutPrice'] as num?)?.toDouble() ?? 0.0,
      showCutPrice: i['showCutPrice'] == 1 || i['showCutPrice'] == true || i['showCutPrice'] == null,
      isDiscounted: i['isDiscounted'] == 1 || i['isDiscounted'] == true || discPct > 0,
      promoBadge: i['promoBadge'] ?? '',
      subAdminId: i['sub_admin_id'] ?? '',
      locationAddress: i['locationAddress'] ?? i['location'] ?? 'FoodCourt Central Kitchen, 14-C Gulberg III, Lahore',
      isAvailable: i['isAvailable'] == true || i['isAvailable'] == 1 || i['isVisible'] == true || i['isVisible'] == 1 || i['isVisible'] == null,
    );
  }
}
