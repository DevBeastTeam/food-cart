import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;
  String _deliveryAddress = 'Home • Gulberg III, Main Blvd, Lahore';
  String _specialInstructions = '';
  String? _promoCode;
  double _promoDiscount = 0.0;
  double _deliveryFee = 49.0;
  final double _serviceFee = 29.0;

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  String get deliveryAddress => _deliveryAddress;
  String get specialInstructions => _specialInstructions;
  String? get promoCode => _promoCode;
  double get promoDiscount => _promoDiscount;
  double get deliveryFee => _items.isEmpty ? 0.0 : _deliveryFee;
  double get serviceFee => _items.isEmpty ? 0.0 : _serviceFee;

  int get totalItemCount =>
      _items.fold<int>(0, (total, item) => total + item.quantity);

  double get subtotal =>
      _items.fold<double>(0.0, (total, item) => total + item.totalPrice);

  double get grandTotal {
    if (_items.isEmpty) return 0.0;
    final total = subtotal + deliveryFee + serviceFee - _promoDiscount;
    return total > 0 ? total : 0.0;
  }

  int getItemQuantity(String foodItemId) {
    for (final item in _items) {
      if (item.foodItem.id == foodItemId) {
        return item.quantity;
      }
    }
    return 0;
  }

  // Add Item to cart. Returns true if added directly,
  // returns false if there is a conflict with a different restaurant.
  bool addItem(FoodItem foodItem, String restId, String restName) {
    if (_items.isNotEmpty && _restaurantId != null && _restaurantId != restId) {
      // Different restaurant conflict
      return false;
    }

    _restaurantId = restId;
    _restaurantName = restName;

    final existingIndex =
        _items.indexWhere((element) => element.foodItem.id == foodItem.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(
        foodItem: foodItem,
        restaurantId: restId,
        restaurantName: restName,
        quantity: 1,
      ));
    }

    _recalculatePromo();
    notifyListeners();
    return true;
  }

  void replaceCartWithItem(
      FoodItem foodItem, String restId, String restName, double restDeliveryFee) {
    _items.clear();
    _restaurantId = restId;
    _restaurantName = restName;
    _deliveryFee = restDeliveryFee;
    _items.add(CartItem(
      foodItem: foodItem,
      restaurantId: restId,
      restaurantName: restName,
      quantity: 1,
    ));
    _recalculatePromo();
    notifyListeners();
  }

  void increment(String foodItemId) {
    final index =
        _items.indexWhere((element) => element.foodItem.id == foodItemId);
    if (index >= 0) {
      _items[index].quantity += 1;
      _recalculatePromo();
      notifyListeners();
    }
  }

  void decrement(String foodItemId) {
    final index =
        _items.indexWhere((element) => element.foodItem.id == foodItemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
        if (_items.isEmpty) {
          _restaurantId = null;
          _restaurantName = null;
          _promoCode = null;
          _promoDiscount = 0.0;
        }
      }
      _recalculatePromo();
      notifyListeners();
    }
  }

  void removeItem(String foodItemId) {
    _items.removeWhere((element) => element.foodItem.id == foodItemId);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
      _promoCode = null;
      _promoDiscount = 0.0;
    }
    _recalculatePromo();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    _promoCode = null;
    _promoDiscount = 0.0;
    _specialInstructions = '';
    notifyListeners();
  }

  bool applyPromo(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'FOODCOURT40' || clean == 'CRAVEE40') {
      _promoCode = clean;
      _recalculatePromo();
      notifyListeners();
      return true;
    } else if (clean == 'FREE' || clean == 'FREEDEL') {
      _promoCode = clean;
      _promoDiscount = _deliveryFee;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromo() {
    _promoCode = null;
    _promoDiscount = 0.0;
    notifyListeners();
  }

  void _recalculatePromo() {
    if (_promoCode == 'FOODCOURT40' || _promoCode == 'CRAVEE40') {
      // 40% discount on subtotal capped at Rs. 300
      final calculated = subtotal * 0.40;
      _promoDiscount = calculated > 300 ? 300.0 : calculated;
    } else if (_promoCode == 'FREE' || _promoCode == 'FREEDEL') {
      _promoDiscount = _deliveryFee;
    } else {
      _promoDiscount = 0.0;
    }
  }

  void setAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setSpecialInstructions(String notes) {
    _specialInstructions = notes;
    notifyListeners();
  }
}
