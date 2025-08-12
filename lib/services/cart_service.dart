// services/cart_service.dart
import 'package:flutter/foundation.dart';

class CartService with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  int get itemCount => _cartItems.length;

  double get totalPrice {
    return _cartItems.fold(0, (sum, item) {
      return sum + (item['precio'] * item['cantidad']);
    });
  }

  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item['vino_id'] == product['vino_id']);

    if (existingIndex >= 0) {
      _cartItems[existingIndex]['cantidad'] += quantity;
    } else {
      _cartItems.add({
        'vino_id': product['vino_id'],
        'nombre': product['nombre'],
        'precio': product['precio'],
        'cantidad': quantity,
        'imagen_url': product['imagen_url'],
      });
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item['vino_id'] == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    final index = _cartItems.indexWhere((item) => item['vino_id'] == productId);
    if (index >= 0) {
      _cartItems[index]['cantidad'] = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}