import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

enum PaymentCallbackStatus { none, success, failed, cancelled }

class PaymentCallbackResult {
  final PaymentCallbackStatus status;
  final String? reference;
  final String? transactionId;
  final String? error;

  const PaymentCallbackResult({
    required this.status,
    this.reference,
    this.transactionId,
    this.error,
  });
}

class PaymentCallbackProvider extends ChangeNotifier {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  PaymentCallbackResult _result = const PaymentCallbackResult(
    status: PaymentCallbackStatus.none,
  );
  PaymentCallbackResult get result => _result;

  void init() {
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'beerstore' || uri.host != 'payment-result') return;

    final status = uri.queryParameters['status'];
    _result = PaymentCallbackResult(
      status: switch (status) {
        'success' => PaymentCallbackStatus.success,
        'failed' => PaymentCallbackStatus.failed,
        'cancelled' => PaymentCallbackStatus.cancelled,
        _ => PaymentCallbackStatus.none,
      },
      reference: uri.queryParameters['reference'],
      transactionId: uri.queryParameters['transaction_id'],
      error: uri.queryParameters['error'],
    );
    notifyListeners();
  }

  void simulate({
    required PaymentCallbackStatus status,
    String? reference,
    String? transactionId,
  }) {
    _result = PaymentCallbackResult(
      status: status,
      reference: reference,
      transactionId: transactionId ??
          'SIM_${DateTime.now().millisecondsSinceEpoch}',
    );
    notifyListeners();
  }

  void reset() {
    _result = const PaymentCallbackResult(status: PaymentCallbackStatus.none);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
