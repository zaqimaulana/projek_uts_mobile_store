import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:beer_store_app/core/routes/app_router.dart';
import 'package:beer_store_app/core/services/global_institute_pay_service.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:beer_store_app/features/products/presentation/providers/product_provider.dart';

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

class _PaymentPendingPageState extends State<PaymentPendingPage> {
  bool _launching = false;
  bool _payLaunched = false;
  StreamSubscription<PaymentCallbackData>? _callbackSub;

  static const _brandColor = Color(0xFF1A237E);

  String _fmt(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchDompetKampus());
    _callbackSub = GlobalInstitutePayService().onCallback.listen(_onCallback);
  }

  @override
  void dispose() {
    _callbackSub?.cancel();
    super.dispose();
  }

  void _onCallback(PaymentCallbackData data) {
    if (!mounted) return;
    if (data.isSuccess) {
      _sudahBayar();
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.paymentResult,
        (route) => route.settings.name == AppRouter.dashboard,
        arguments: data.status,
      );
    }
  }

  Future<void> _launchDompetKampus() async {
    setState(() => _launching = true);
    final url = GlobalInstitutePayService.buildDeeplinkUrl(
      reference: widget.reference,
      amount: widget.amount,
      description: widget.description,
    );
    try {
      final launched = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() {
          _payLaunched = launched;
          _launching = false;
        });
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dompet Kampus tidak ditemukan'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _sudahBayar() {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    final products = context.read<ProductProvider>();

    // Submit order di background, cart langsung dikosongkan
    checkout.submitOrder(cart: cart, paymentReference: widget.reference)
        .then((_) => products.fetchProducts())
        .catchError((_) {});

    cart.clearCart();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.paymentResult,
      (route) => route.settings.name == AppRouter.dashboard,
      arguments: 'success',
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text('Kembali ke beranda? Pesanan belum dibuat.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Lanjut Bayar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRouter.dashboard, (r) => false);
            },
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selesaikan Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelDialog,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Icon ─────────────────────────────────────────
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded,
                    size: 38, color: _brandColor),
              ),
              const SizedBox(height: 12),
              const Text('Global Institute Pay',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.reference,
                  style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.45))),
              const SizedBox(height: 6),
              Text(_fmt(widget.amount),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary)),

              const SizedBox(height: 32),

              // ── Tombol buka Dompet Kampus ─────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _launching ? null : _launchDompetKampus,
                  icon: _launching
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    _payLaunched
                        ? 'Buka Ulang Dompet Kampus'
                        : 'Buka Dompet Kampus Global',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),

              // ── Tombol sudah bayar (muncul setelah DK dibuka) ─
              if (_payLaunched) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sudahBayar,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Saya Sudah Bayar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
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
