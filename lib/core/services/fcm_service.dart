import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static Function(RemoteMessage)? onForeground;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    debugPrint('[FCM] Token: $token');
    if (token != null) {
      await sendTokenToBackend(token);
    }

    // Re-kirim saat token diperbarui Firebase
    _messaging.onTokenRefresh.listen(sendTokenToBackend);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      await DioClient.instance.put(
        ApiConstants.fcmToken,
        data: {'fcm_token': token},
      );
      debugPrint('[FCM] Token berhasil dikirim ke backend');
    } catch (e) {
      debugPrint('[FCM] Gagal kirim token (mungkin belum login): $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    debugPrint('[FCM] Foreground: ${notif.title} — ${notif.body}');
    onForeground?.call(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Dibuka dari notifikasi: ${message.data}');
  }

  Future<String?> getToken() => _messaging.getToken();
}
