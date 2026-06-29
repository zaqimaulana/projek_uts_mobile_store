class ApiConstants {
  static const String baseUrl = 'http://10.199.252.156:8081/v1';

  static const String verifyToken = '/auth/verify-token';
  static const String fcmToken = '/auth/fcm-token';
  static const String products = '/products';
  static const String orders = '/orders';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}