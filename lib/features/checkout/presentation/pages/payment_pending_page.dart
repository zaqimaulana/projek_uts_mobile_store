import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:beer_store_app/core/routes/app_router.dart';
import 'package:beer_store_app/core/services/global_institute_pay_service.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/features/checkout/presentation/providers/checkout_provider.dart';

void _log(String msg) => debugPrint('[BeerStore/PaymentPending] $msg');

class PaymentPendingPage extends StatefulWidget {
  final String reference;
  final double amount;
  final String description;

  const PaymentPendingPage({
    super.key,
    required this.reference,
    required this.amount,
    required this.description,
  });

  @override
  State<PaymentPendingPage> createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage>
    with WidgetsBindingObserver {
  bool _payLaunched = false;
  bool _navigating = false;
  StreamSubscription<PaymentCallbackData>? _callbackSub;

  @override
  void initState() {
    super.initState();
    _log('─────────────────────────────────────────');
    _log('initState | ref=${widget.reference} amount=${widget.amount}');

    WidgetsBinding.instance.addObserver(this);

    // Auto-launch Dompet Kampus Global setelah frame pertama
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _launchDompetKampus());

    // Periksa callback yang masuk saat cold start
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null) {
      _log('cold-start callback ditemukan: $pending');
      if (pending.isSuccess) {
        _log('cold-start berhasil → jadwalkan navigasi');
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _onPaymentSuccess(pending));
      } else {
        _log('cold-start gagal: status=${pending.status}');
      }
    } else {
      _log('tidak ada pending cold-start callback');
    }

    // Subscribe stream callback (app berjalan di background/foreground)
    _log('subscribe GlobalInstitutePayService.onCallback...');
    _callbackSub = GlobalInstitutePayService().onCallback.listen((data) {
      _log('callback dari stream: $data');
      if (!mounted || _navigating) return;
      if (data.isSuccess) {
        _log('status sukses → _onPaymentSuccess');
        _onPaymentSuccess(data);
      } else {
        _log('status gagal: ${data.status}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Pembayaran ${data.status} — silakan coba lagi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    _log('initState selesai');
  }

  @override
  void dispose() {
    _log('dispose');
    _callbackSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log('AppLifecycle: $state | payLaunched=$_payLaunched');
  }

  Future<void> _launchDompetKampus() async {
    _log('─── _launchDompetKampus ───');
    _log('ref=${widget.reference} | amount=${widget.amount}');

    final deeplinkUrl = GlobalInstitutePayService.buildDeeplinkUrl(
      reference: widget.reference,
      amount: widget.amount,
      description: widget.description,
    );

    final uri = Uri.parse(deeplinkUrl);
    _log('URI: $uri');

    final canLaunch = await canLaunchUrl(uri);
    _log('canLaunchUrl → $canLaunch');
    if (!canLaunch) {
      _log(
        'canLaunchUrl=false — tetap mencoba launchUrl...\n'
        'Kemungkinan penyebab:\n'
        '1. APK belum di-rebuild setelah perubahan AndroidManifest.xml\n'
        '2. Aplikasi Dompet Kampus Global belum terinstal',
      );
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      _log('launchUrl → $launched');
      if (launched) {
        _log('Dompet Kampus Global berhasil dibuka');
        setState(() => _payLaunched = true);
      } else {
        _log('launchUrl=false — aplikasi ada tapi tidak merespons');
        if (!mounted) return;
        _showAppNotFoundDialog();
      }
    } catch (e) {
      _log('exception launchUrl: $e → Dompet Kampus kemungkinan tidak terinstal');
      if (!mounted) return;
      _showAppNotFoundDialog();
    }
  }

  void _onPaymentSuccess(PaymentCallbackData data) {
    if (_navigating) return;
    _navigating = true;
    _log('_onPaymentSuccess → submit order lalu navigasi');
    _submitOrderThenNavigate(data.reference ?? widget.reference);
  }

  Future<void> _submitOrderThenNavigate(String reference) async {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();

    _log('submitOrder | ref=$reference items=${cart.totalItems} total=${cart.totalPrice}');
    await checkout.submitOrder(cart: cart, paymentReference: reference);

    if (!mounted) return;

    _log('submitOrder done | status=${checkout.status}');

    if (checkout.status == CheckoutStatus.success) {
      cart.clearCart();
      _log('cart di-clear');
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.paymentResult,
      (route) => route.settings.name == AppRouter.dashboard,
      arguments: checkout.status == CheckoutStatus.success ? 'success' : 'failed',
    );
  }

  void _showAppNotFoundDialog() {
    _log('menampilkan dialog: aplikasi tidak ditemukan');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aplikasi Tidak Ditemukan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi Dompet Kampus Global tidak terinstal di perangkat ini.',
            ),
            SizedBox(height: 12),
            Text(
              'Pastikan Dompet Kampus Global sudah terinstal, '
              'kemudian tekan tombol di bawah untuk mencoba lagi.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchDompetKampus();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
          'Kembali ke beranda? Pembayaran yang sudah dilakukan di Dompet Kampus tetap tercatat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lanjutkan Bayar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.dashboard,
                (route) => false,
              );
            },
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  static const _brandColor = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selesaikan Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelConfirmation,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Header icon ─────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0x1A1A237E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 46,
                  color: _brandColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bayar dengan Dompet Kampus Global',
                textAlign: TextAlign.center,
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.reference} · ${_formatPrice(widget.amount)}',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              // ── Info keamanan ─────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _brandColor.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: _brandColor, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran akan diverifikasi dengan PIN dan kode 2FA '
                        'di aplikasi Dompet Kampus Global',
                        style: TextStyle(
                          fontSize: 12,
                          color: _brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Langkah pembayaran ────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepItem(
                      number: '1',
                      text: _payLaunched
                          ? 'Aplikasi Dompet Kampus Global sudah dibuka'
                          : 'Kamu akan diarahkan ke Dompet Kampus Global',
                      done: _payLaunched,
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      number: '2',
                      text:
                          'Masukkan PIN dan kode 2FA, lalu konfirmasi '
                          'pembayaran ${_formatPrice(widget.amount)}',
                      done: false,
                    ),
                    const SizedBox(height: 14),
                    const _StepItem(
                      number: '3',
                      text:
                          'Kembali ke aplikasi — status diperbarui '
                          'otomatis via callback',
                      done: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Tombol buka Dompet Kampus ─────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(
                    _payLaunched
                        ? 'Buka Kembali Dompet Kampus Global'
                        : 'Buka Dompet Kampus Global',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _launchDompetKampus,
                ),
              ),

              if (_payLaunched) ...[
                const SizedBox(height: 16),
                Text(
                  'Menunggu konfirmasi pembayaran dari '
                  'Dompet Kampus Global...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step item widget ──────────────────────────────────────────────

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  final bool done;

  const _StepItem({
    required this.number,
    required this.text,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? Colors.green
                : Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
