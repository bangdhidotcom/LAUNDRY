import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/user_service.dart';

class AppProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<ServicePrice> _services = [];
  bool _isLoading = false;
  final List<OrderItem> _cart = [];

  List<ServicePrice> get services => _services;
  bool get isLoading => _isLoading;
  List<OrderItem> get cart => _cart;
  int get totalCartPrice => _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));

  AppProvider() { _init(); }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await fetchServices();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchServices() async {
    _services = await _userService.getServices();
    notifyListeners();
  }

  void addToCart(ServicePrice service) {
    final index = _cart.indexWhere((item) => item.serviceName == service.name);
    if (index != -1) {
      final existing = _cart[index];
      _cart[index] = OrderItem(
        serviceName: existing.serviceName, price: existing.price, quantity: existing.quantity + 1, unit: existing.unit,
      );
    } else {
      _cart.add(OrderItem(serviceName: service.name, price: service.price, quantity: 1, unit: service.unit));
    }
    notifyListeners();
  }

  void removeFromCart(String serviceName) {
    _cart.removeWhere((item) => item.serviceName == serviceName);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<bool> checkout({
    required String name,
    required String phone,
    required String address,
    // Parameter Baru
    double? lat,
    double? lng,
    required String deliveryMethod,
    DateTime? pickupSchedule,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _userService.currentUserId;
      if (userId == null) throw Exception("Gagal login user");

      final newOrder = Order(
        userId: userId,
        customerName: name,
        customerPhone: phone,
        address: address,
        items: _cart,
        totalPrice: totalCartPrice,
        orderDate: DateTime.now(),
        status: 'pending',
        // Field Baru
        latitude: lat,
        longitude: lng,
        deliveryMethod: deliveryMethod,
        pickupSchedule: pickupSchedule,
      );

      await _userService.createOrder(newOrder);

      clearCart();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Stream<List<Order>> get myOrdersStream => _userService.getMyOrdersStream();
}