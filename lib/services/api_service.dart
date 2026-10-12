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

  // Dynamic Base URL based on platform
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
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
        _isBackendConnected = true;
        final data = jsonDecode(res.body)['data'] as Map<String, dynamic>;
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
    } catch (e) {
      debugPrint('[ApiService] Content sync offline/fallback: $e');
    }

    // Sync Restaurants & Menu Items
    try {
      final res = await http.get(Uri.parse('$baseUrl/restaurants')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List;
        if (list.isNotEmpty) {
          final foodRes = await http.get(Uri.parse('$baseUrl/food-items')).timeout(const Duration(seconds: 4));
          final allFood = foodRes.statusCode == 200 
              ? (jsonDecode(foodRes.body)['data'] as List).map((i) => _parseFoodItem(i)).toList()
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
        final list = jsonDecode(res.body)['data'] as List;
        final List<DaigItem> parsedDaigs = [];
        for (final d in list) {
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
          ));
        }
        if (parsedDaigs.isNotEmpty) {
          SampleData.daigDishes.clear();
          SampleData.daigDishes.addAll(parsedDaigs);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Daig dishes sync offline/fallback: $e');
    }

    // Sync Banners & Deals
    try {
      final bannerRes = await http.get(Uri.parse('$baseUrl/banners')).timeout(const Duration(seconds: 3));
      if (bannerRes.statusCode == 200) {
        _promoBanners = List<Map<String, dynamic>>.from(jsonDecode(bannerRes.body)['data']);
      }
      final dealsRes = await http.get(Uri.parse('$baseUrl/deals')).timeout(const Duration(seconds: 3));
      if (dealsRes.statusCode == 200) {
        _activeDeals = List<Map<String, dynamic>>.from(jsonDecode(dealsRes.body)['data']);
      }
      final settingsRes = await http.get(Uri.parse('$baseUrl/settings')).timeout(const Duration(seconds: 3));
      if (settingsRes.statusCode == 200) {
        _appSettings = jsonDecode(settingsRes.body)['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] Secondary sync offline/fallback: $e');
    }

    // Sync Live Orders with UserState
    if (userState != null) {
      try {
        final orderRes = await http.get(Uri.parse('$baseUrl/orders')).timeout(const Duration(seconds: 4));
        if (orderRes.statusCode == 200) {
          final list = jsonDecode(orderRes.body)['data'] as List;
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
              deliveryAddress: o['deliveryAddress'] ?? 'Lahore',
              prepTime: o['prepTime'] ?? '25 mins',
              riderName: o['riderName'],
              riderPhone: o['riderPhone'],
              customerName: o['customerName'] ?? 'Hassan Raza',
              customerPhone: o['customerPhone'] ?? '+92 300 8472910',
              notes: o['notes'],
            ));
          }
          if (syncedOrders.isNotEmpty) {
            userState.syncOrdersFromBackend(syncedOrders);
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Orders sync offline/fallback: $e');
      }
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
      return res.statusCode == 201;
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
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (prepTime != null) body['prepTime'] = prepTime;
      if (notes != null) body['notes'] = notes;

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


  // Search food items from backend with local fallback
  Future<List<FoodItem>> searchFoodItems(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/food-items?search=${Uri.encodeComponent(cleanQuery)}'))
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

  FoodItem _parseFoodItem(Map<String, dynamic> i) {
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
    );
  }
}
