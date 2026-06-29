import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

void _log(String tag, String message) =>
    debugPrint('[BeerStore/$tag] $message');

class PaymentCallbackData {
  final String status;
  final String? reference;
  final String? transactionId;

  const PaymentCallbackData({
    required this.status,
    this.reference,
    this.transactionId,
  });

  bool get isSuccess => status == 'success';

  @override
  String toString() =>
      'PaymentCallbackData(status=$status, ref=$reference, txnId=$transactionId)';
}

/// Mengelola deeplink keluar ke Dompet Kampus Global
/// dan deeplink masuk (callback pembayaran) ke Beer Store.
class GlobalInstitutePayService {
  static final GlobalInstitutePayService _instance =
      GlobalInstitutePayService._();
  factory GlobalInstitutePayService() => _instance;
  GlobalInstitutePayService._();

  static const _tag = 'GlobalInstitutePay';

  final _callbackController =
      StreamController<PaymentCallbackData>.broadcast();
  Stream<PaymentCallbackData> get onCallback => _callbackController.stream;

  PaymentCallbackData? _pendingCallback;

  /// Ambil callback cold-start, dikosongkan setelah dibaca.
  PaymentCallbackData? consumePendingCallback() {
    final data = _pendingCallback;
    _pendingCallback = null;
    if (data != null) _log(_tag, 'consumePending: $data');
    return data;
  }

  Future<void> init() async {
    _log(_tag, 'init...');
    final appLinks = AppLinks();

    // Kasus 1: cold start — app dibuka oleh deeplink
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) {
        _log(_tag, 'initial link (cold-start): $uri');
        _handleUri(uri, isColdStart: true);
      } else {
        _log(_tag, 'no initial link');
      }
    } catch (e) {
      _log(_tag, 'getInitialLink error: $e');
    }

    // Kasus 2: app sudah berjalan — deeplink masuk via stream
    appLinks.uriLinkStream.listen(
      (uri) {
        _log(_tag, 'uri stream: $uri');
        _handleUri(uri);
      },
      onError: (e) => _log(_tag, 'stream error: $e'),
    );

    _log(_tag, 'init done');
  }

  void _handleUri(Uri uri, {bool isColdStart = false}) {
    _log(
      _tag,
      'handleUri | scheme=${uri.scheme} host=${uri.host} '
      'params=${uri.queryParameters} | coldStart=$isColdStart',
    );

    if (uri.scheme != 'beerstore' || uri.host != 'payment-result') {
      _log(_tag, 'ignored — bukan beerstore://payment-result');
      return;
    }

    final data = PaymentCallbackData(
      status: uri.queryParameters['status'] ?? 'unknown',
      reference: uri.queryParameters['reference'],
      transactionId: uri.queryParameters['transaction_id'],
    );

    _log(_tag, 'callback diterima: $data');

    // Selalu simpan agar bisa di-consume di didChangeAppLifecycleState
    _pendingCallback = data;
    _log(_tag, 'disimpan sebagai pending (coldStart=$isColdStart)');

    _callbackController.add(data);
    _log(_tag, 'event dikirim ke stream');
  }

  /// Bangun URL deeplink ke Dompet Kampus Global.
  static String buildDeeplinkUrl({
    required String reference,
    required double amount,
    String? description,
  }) {
    const callbackUrl = 'beerstore://payment-result';
    final desc = (description != null && description.isNotEmpty)
        ? description
        : 'Pembelian di Beer Store';

    _log(_tag, 'buildDeeplinkUrl:');
    _log(_tag, '  merchant_id  : beer_store');
    _log(_tag, '  merchant_name: Beer Store');
    _log(_tag, '  amount       : ${amount.toInt()}');
    _log(_tag, '  description  : $desc');
    _log(_tag, '  reference    : $reference');
    _log(_tag, '  callback     : $callbackUrl');

    final uri = Uri(
      scheme: 'dompetkampus',
      host: 'pay',
      queryParameters: {
        'merchant_id': 'beer_store',
        'merchant_name': 'Beer Store',
        'amount': amount.toInt().toString(),
        'description': desc,
        'reference': reference,
        'callback': 'beerstore://payment-result',
      },
    );

    final result = uri.toString();
    _log(_tag, 'url: $result');
    return result;
  }
}
