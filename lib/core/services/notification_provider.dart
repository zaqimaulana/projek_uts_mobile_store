import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'fcm_service.dart';

class InAppNotification {
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const InAppNotification({
    required this.title,
    required this.body,
    required this.data,
  });
}

class NotificationProvider extends ChangeNotifier {
  InAppNotification? _latest;
  InAppNotification? get latest => _latest;

  void init() {
    FcmService.onForeground = _handleMessage;
  }

  void _handleMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    _latest = InAppNotification(
      title: notif.title ?? 'Notifikasi',
      body: notif.body ?? '',
      data: message.data,
    );
    notifyListeners();
  }

  void clear() {
    _latest = null;
    notifyListeners();
  }
}
