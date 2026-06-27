import 'package:flutter/material.dart';
import 'package:beer_store_app/core/routes/app_router.dart';

/// Halaman hasil pembayaran.
/// Route arguments (String): 'success' | 'failed' | 'cancelled'
class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final status =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'failed';

    final isSuccess = status == 'success';
    final isCancelled = status == 'cancelled';

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
                      ? 'Pesanan Berhasil!'
                      : isCancelled
                          ? 'Pembayaran Dibatalkan'
                          : 'Pembayaran Gagal',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isSuccess
                      ? 'Terima kasih, pesanan kamu sedang diproses.'
                      : isCancelled
                          ? 'Kamu membatalkan pembayaran.'
                          : 'Terjadi masalah saat memproses pembayaran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.dashboard,
                      (route) => false,
                    ),
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
