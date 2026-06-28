import 'package:flutter/material.dart';
import 'package:beer_store_app/core/routes/app_router.dart';

/// Route arguments (String): 'success' | 'failed' | 'cancelled'
class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final status =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'failed';

    final isSuccess = status == 'success';
    final isCancelled = status == 'cancelled';

    final Color statusColor = isSuccess
        ? Colors.green
        : isCancelled
            ? Colors.orange
            : Colors.red;

    final IconData statusIcon = isSuccess
        ? Icons.check_circle_rounded
        : isCancelled
            ? Icons.cancel_rounded
            : Icons.error_rounded;

    final String title = isSuccess
        ? 'Pesanan Berhasil!'
        : isCancelled
            ? 'Pembayaran Dibatalkan'
            : 'Pembayaran Gagal';

    final String subtitle = isSuccess
        ? 'Terima kasih! Pesanan kamu sedang diproses dan akan segera dikirimkan.'
        : isCancelled
            ? 'Kamu membatalkan proses pembayaran. Silakan coba lagi kapan saja.'
            : 'Terjadi masalah saat memproses pembayaran. Silakan coba lagi.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),

              // ── Status icon ─────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, size: 64, color: statusColor),
              ),

              const SizedBox(height: 28),

              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),

              if (isSuccess) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Pesanan sedang diproses',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // ── Actions ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.dashboard,
                    (route) => false,
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Kembali ke Beranda'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              if (!isSuccess) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
