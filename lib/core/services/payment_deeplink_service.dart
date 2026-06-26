import 'package:url_launcher/url_launcher.dart';

class PaymentDeeplinkService {
  static const String _callbackScheme = 'beerstore://payment-result';
  static const String _merchantId = 'beer_store';
  static const String _merchantName = 'Beer Store';

  /// Membuka aplikasi Dompet Kampus untuk membayar.
  static Future<bool> pay({
    required double amount,
    required String reference,
    String description = 'Pembelian di Beer Store',
  }) async {
    final uri = Uri(
      scheme: 'dompetkampus',
      host: 'pay',
      queryParameters: {
        'merchant_id': _merchantId,
        'merchant_name': _merchantName,
        'amount': amount.toStringAsFixed(0),
        'description': description,
        'reference': reference,
        'callback': _callbackScheme,
      },
    );

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Buat reference unik berdasarkan timestamp.
  static String generateReference() =>
      'ORDER_${DateTime.now().millisecondsSinceEpoch}';
}
