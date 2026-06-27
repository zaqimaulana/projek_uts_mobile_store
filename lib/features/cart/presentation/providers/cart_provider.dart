import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:beer_store_app/features/cart/data/models/cart_item.dart';
import 'package:beer_store_app/features/products/data/models/product_model.dart';

class CartProvider extends ChangeNotifier {
  static const String _cartKey = 'cart_items';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final List<CartItem> _items = [];

  CartProvider() {
    _loadCart();
  }

  List<CartItem> get items => _items;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.total);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.qty);

  // Returns false jika stok tidak cukup.
  bool addToCart(ProductModel product) {
    final index = _items.indexWhere((e) => e.product.id == product.id);
    final currentQty = index >= 0 ? _items[index].qty : 0;

    if (product.stock > 0 && currentQty >= product.stock) {
      return false;
    }

    if (index >= 0) {
      _items[index].qty++;
    } else {
      _items.add(CartItem(product: product));
    }

    notifyListeners();
    _saveCart();
    return true;
  }

  void removeFromCart(int productId) {
    _items.removeWhere((e) => e.product.id == productId);
    notifyListeners();
    _saveCart();
  }

  // Returns false jika sudah melebihi stok.
  bool increaseQty(int productId) {
    final item = _items.firstWhere((e) => e.product.id == productId);
    if (item.product.stock > 0 && item.qty >= item.product.stock) {
      return false;
    }
    item.qty++;
    notifyListeners();
    _saveCart();
    return true;
  }

  void decreaseQty(int productId) {
    final item = _items.firstWhere((e) => e.product.id == productId);
    if (item.qty > 1) {
      item.qty--;
    } else {
      removeFromCart(productId);
      return;
    }
    notifyListeners();
    _saveCart();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _saveCart();
  }

  Future<void> _saveCart() async {
    try {
      final json = jsonEncode(_items.map((e) => e.toJson()).toList());
      await _storage.write(key: _cartKey, value: json);
    } catch (_) {}
  }

  Future<void> _loadCart() async {
    try {
      final json = await _storage.read(key: _cartKey);
      if (json == null || json.isEmpty) return;
      final list = jsonDecode(json) as List;
      _items.clear();
      _items.addAll(
        list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)),
      );
      notifyListeners();
    } catch (_) {
      // Cart rusak di storage → abaikan, mulai dari kosong
    }
  }
}
