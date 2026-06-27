import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message diterima saat app tidak aktif
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static Function(RemoteMessage)? onForeground;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Register background handler sebelum apapun
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Minta izin notifikasi
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Ambil FCM token (untuk dikirim ke backend agar bisa push notif)
    final token = await _messaging.getToken();
    debugPrint('[FCM] Token: $token');

    // Foreground: tampilkan notifikasi saat app aktif
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap notifikasi saat app di background (dibuka dari notif)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    debugPrint('[FCM] Foreground: ${notif.title} — ${notif.body}');
    onForeground?.call(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Dibuka dari notifikasi: ${message.data}');
    // Navigasi ke halaman status transaksi jika diperlukan
  }

  Future<String?> getToken() => _messaging.getToken();
}
