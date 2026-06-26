import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/core/routes/app_router.dart';
import 'package:beer_store_app/core/services/payment_callback_provider.dart';

class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<PaymentCallbackProvider>().result;

    final isSuccess = result.status == PaymentCallbackStatus.success;
    final isCancelled = result.status == PaymentCallbackStatus.cancelled;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess
                      ? Icons.check_circle_outline
                      : isCancelled
                          ? Icons.cancel_outlined
                          : Icons.error_outline,
                  color: isSuccess
                      ? Colors.green
                      : isCancelled
                          ? Colors.orange
                          : Colors.red,
                  size: 96,
                ),
                const SizedBox(height: 24),
                Text(
                  isSuccess
                      ? 'Pembayaran Berhasil!'
                      : isCancelled
                          ? 'Pembayaran Dibatalkan'
                          : 'Pembayaran Gagal',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (result.transactionId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'ID Transaksi: ${result.transactionId}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
                if (result.reference != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${result.reference}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (!isSuccess && result.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.error!,
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<PaymentCallbackProvider>().reset();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.dashboard,
                        (route) => false,
                      );
                    },
                    child: const Text('Kembali ke Beranda'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
