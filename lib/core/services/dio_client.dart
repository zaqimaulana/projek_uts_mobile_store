import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'secure_storage_service.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    /// Interceptor Logging
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('[REQUEST] ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[RESPONSE] ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint('[ERROR TYPE] ${error.type}');
          debugPrint('[ERROR MESSAGE] ${error.message}');
          debugPrint('[ERROR URL] ${error.requestOptions.uri}');
          debugPrint('[ERROR STATUS] ${error.response?.statusCode}');
          debugPrint('[ERROR DATA] ${error.response?.data}');

          if (error.response?.statusCode == 401) {
            await SecureStorageService.clearAll();
          }

          handler.next(error);
        },
      ),
    );

    /// Inject Bearer Token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token =
              await SecureStorageService.getToken();

          if (token != null) {
            options.headers['Authorization'] =
                'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );

    return dio;
  }
}