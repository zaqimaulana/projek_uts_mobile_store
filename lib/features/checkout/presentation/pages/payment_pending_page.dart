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

class _PaymentPendingPageState extends State<PaymentPendingPage>
    with WidgetsBindingObserver {
  bool _launching = false;
  bool _payLaunched = false;
  bool _submitting = false;
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
    WidgetsBinding.instance.addObserver(this);

    // Cek cold-start callback
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _submitAndNavigate(pending.reference ?? widget.reference));
      return;
    }

    // Subscribe stream (fallback jika lifecycle tidak cukup cepat)
    _callbackSub = GlobalInstitutePayService().onCallback.listen((data) {
      if (!mounted || _submitting) return;
      if (data.isSuccess) {
        _submitAndNavigate(data.reference ?? widget.reference);
      }
    });

    // Auto-launch Dompet Kampus
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _launchDompetKampus());
  }

  @override
  void dispose() {
    _callbackSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat app kembali dari Dompet Kampus, cek apakah ada callback tersimpan
    if (state == AppLifecycleState.resumed && _payLaunched && !_submitting) {
      // Tunggu sebentar agar uriLinkStream sempat fire lebih dulu
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || _submitting) return;
        final pending = GlobalInstitutePayService().consumePendingCallback();
        if (pending != null && pending.isSuccess) {
          _submitAndNavigate(pending.reference ?? widget.reference);
        } else if (mounted) {
          setState(() {}); // refresh tampilan — tombol "Sudah Bayar" muncul
        }
      });
    }
  }

  Future<void> _launchDompetKampus() async {
    if (_submitting) return;
    setState(() => _launching = true);

    final url = GlobalInstitutePayService.buildDeeplinkUrl(
      reference: widget.reference,
      amount: widget.amount,
      description: widget.description,
    );

    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        setState(() {
          _payLaunched = launched;
          _launching = false;
        });
      }
      if (!launched && mounted) {
        _showSnack('Dompet Kampus tidak ditemukan di perangkat ini');
      }
    } catch (_) {
      if (mounted) setState(() => _launching = false);
      _showSnack('Gagal membuka Dompet Kampus');
    }
  }

  Future<void> _submitAndNavigate(String reference) async {
    if (_submitting || !mounted) return;
    setState(() => _submitting = true);

    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    final products = context.read<ProductProvider>();

    await checkout.submitOrder(cart: cart, paymentReference: reference);

    if (!mounted) return;

    final success = checkout.status == CheckoutStatus.success;

    if (success) {
      cart.clearCart();
      products.fetchProducts();
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.paymentResult,
      (route) => route.settings.name == AppRouter.dashboard,
      arguments: success ? 'success' : 'failed',
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
    ));
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
            onPressed: _submitting ? null : _showCancelDialog,
          ),
        ),
        body: _submitting
            ? _buildSubmitting()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Icon + nama ───────────────────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _brandColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 38, color: _brandColor),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Global Institute Pay',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reference,
                      style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fmt(widget.amount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Status card ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _payLaunched
                                  ? Colors.orange.withValues(alpha: 0.12)
                                  : scheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _payLaunched
                                  ? Icons.hourglass_top_rounded
                                  : Icons.open_in_new_rounded,
                              color: _payLaunched
                                  ? Colors.orange
                                  : scheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _payLaunched
                                      ? 'Menunggu konfirmasi pembayaran'
                                      : 'Buka Dompet Kampus untuk bayar',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _payLaunched
                                      ? 'Setelah bayar di Dompet Kampus, halaman ini akan otomatis update'
                                      : 'Tekan tombol di bawah untuk membuka Dompet Kampus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.55),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Tombol buka Dompet Kampus ─────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: (_launching || _submitting)
                            ? null
                            : _launchDompetKampus,
                        icon: _launching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
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

                    // ── Tombol manual (muncul setelah kembali dari DK) ─
                    if (_payLaunched) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.green.shade400),
                            foregroundColor: Colors.green.shade700,
                          ),
                          onPressed: () =>
                              _submitAndNavigate(widget.reference),
                          icon: const Icon(
                              Icons.check_circle_outline_rounded),
                          label: const Text(
                            'Saya Sudah Bayar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
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

  Widget _buildSubmitting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Memproses pesanan...',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
