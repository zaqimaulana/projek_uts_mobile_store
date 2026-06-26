import 'package:dio/dio.dart';
import 'package:beer_store_app/core/constants/api_constants.dart';
import 'package:beer_store_app/core/services/dio_client.dart';
import '../models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final Dio _dio = DioClient.instance;

  @override
  Future<OrderResponse> createOrder(OrderRequest request) async {
    final response = await _dio.post(
      ApiConstants.orders,
      data: request.toJson(),
    );
    return OrderResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
