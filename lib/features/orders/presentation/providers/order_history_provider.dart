import 'package:flutter/material.dart';
import 'package:beer_store_app/features/orders/data/models/order_history_model.dart';
import 'package:beer_store_app/features/orders/data/repositories/order_history_repository_impl.dart';

enum OrderHistoryStatus { initial, loading, loaded, error }

class OrderHistoryProvider extends ChangeNotifier {
  final OrderHistoryRepositoryImpl _repository = OrderHistoryRepositoryImpl();

  OrderHistoryStatus _status = OrderHistoryStatus.initial;
  List<OrderHistory> _orders = [];
  String? _errorMessage;

  OrderHistoryStatus get status => _status;
  List<OrderHistory> get orders => _orders;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrders() async {
    _status = OrderHistoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _repository.getOrders();
      _status = OrderHistoryStatus.loaded;
    } catch (e) {
      _status = OrderHistoryStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }
}
