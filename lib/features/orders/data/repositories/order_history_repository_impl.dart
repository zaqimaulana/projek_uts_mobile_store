import 'package:dio/dio.dart';
import 'package:beer_store_app/core/constants/api_constants.dart';
import 'package:beer_store_app/core/services/dio_client.dart';
import '../models/order_history_model.dart';

class OrderHistoryRepositoryImpl {
  final Dio _dio = DioClient.instance;

  Future<List<OrderHistory>> getOrders() async {
    final response = await _dio.get(ApiConstants.orders);
    final body = response.data;

    List<dynamic> raw;
    if (body is List) {
      raw = body;
    } else if (body is Map && body['data'] is List) {
      raw = body['data'] as List;
    } else {
      raw = [];
    }

    return raw
        .map((e) => OrderHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
