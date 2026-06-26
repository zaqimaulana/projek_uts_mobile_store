import '../../data/models/order_model.dart';

abstract class OrderRepository {
  Future<OrderResponse> createOrder(OrderRequest request);
}
