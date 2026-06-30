import 'package:flutter/material.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/features/checkout/data/models/order_model.dart';
import 'package:beer_store_app/features/checkout/data/repositories/order_repository_impl.dart';

enum CheckoutStatus { idle, submitting, success, error }

class CheckoutProvider extends ChangeNotifier {
  final OrderRepositoryImpl _repository = OrderRepositoryImpl();

  CheckoutStatus _status = CheckoutStatus.idle;
  String? _errorMessage;
  OrderResponse? _lastOrder;

  CheckoutStatus get status => _status;
  String? get errorMessage => _errorMessage;
  OrderResponse? get lastOrder => _lastOrder;

  Future<bool> submitOrder({
    required CartProvider cart,
    required String paymentReference,
    String paymentStatus = 'paid',
  }) async {
    _status = CheckoutStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = OrderRequest(
        items: cart.items
            .map((item) => OrderItemRequest(
                  productId: item.product.id,
                  quantity: item.qty,
                  price: item.product.price,
                ))
            .toList(),
        totalAmount: cart.totalPrice,
        paymentReference: paymentReference,
        paymentStatus: paymentStatus,
      );

      _lastOrder = await _repository.createOrder(request);
      _status = CheckoutStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CheckoutStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      await _repository.updateOrderStatus(orderId, status);
      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() {
    _status = CheckoutStatus.idle;
    _errorMessage = null;
    _lastOrder = null;
    notifyListeners();
  }
}
