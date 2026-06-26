import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/core/services/payment_callback_provider.dart';
import 'package:beer_store_app/core/services/payment_deeplink_service.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/features/checkout/presentation/providers/checkout_provider.dart';
import 'payment_result_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _openingPayment = false;
  bool _navigating = false;
  String? _pendingReference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCallbackProvider>().addListener(_onPaymentCallback);
    });
  }

  @override
  void dispose() {
    context.read<PaymentCallbackProvider>().removeListener(_onPaymentCallback);
    super.dispose();
  }

  void _onPaymentCallback() {
    if (_navigating) return;
    final result = context.read<PaymentCallbackProvider>().result;
    if (result.status == PaymentCallbackStatus.none) return;

    _navigating = true;

    if (result.status == PaymentCallbackStatus.success) {
      _submitOrderThenNavigate(result.reference ?? _pendingReference ?? '');
    } else {
      _goToResultPage();
    }
  }

  Future<void> _submitOrderThenNavigate(String reference) async {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();

    await checkout.submitOrder(cart: cart, paymentReference: reference);

    if (!mounted) return;

    if (checkout.status == CheckoutStatus.success) {
      cart.clearCart();
    }

    _goToResultPage();
  }

  void _showSimulasiDialog(String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Dompet Kampus Tidak Tersedia'),
        content: const Text(
          'Aplikasi Dompet Kampus tidak terinstall.\nPilih simulasi hasil pembayaran:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentCallbackProvider>().simulate(
                    status: PaymentCallbackStatus.cancelled,
                    reference: reference,
                  );
            },
            child: const Text('Batalkan'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentCallbackProvider>().simulate(
                    status: PaymentCallbackStatus.failed,
                    reference: reference,
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Gagal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentCallbackProvider>().simulate(
                    status: PaymentCallbackStatus.success,
                    reference: reference,
                  );
            },
            child: const Text('Berhasil'),
          ),
        ],
      ),
    );
  }

  void _goToResultPage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PaymentResultPage()),
    );
  }

  Future<void> _bayar() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() => _openingPayment = true);

    final reference = PaymentDeeplinkService.generateReference();
    _pendingReference = reference;

    final berhasil = await PaymentDeeplinkService.pay(
      amount: cart.totalPrice,
      reference: reference,
      description: 'Pembelian di Beer Store (${cart.totalItems} item)',
    );

    if (!mounted) return;
    setState(() => _openingPayment = false);

    if (!berhasil) {
      _showSimulasiDialog(reference);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();

    final isSubmitting = checkout.status == CheckoutStatus.submitting;
    final isLoading = _openingPayment || isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Ringkasan Pesanan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...cart.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.local_bar, size: 40),
                          ),
                        ),
                        title: Text(
                          item.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.qty}x  ×  Rp ${item.product.price.toStringAsFixed(0)}',
                        ),
                        trailing: Text(
                          'Rp ${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
                const Divider(height: 24),
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_wallet),
                      SizedBox(width: 12),
                      Text('Dompet Kampus'),
                    ],
                  ),
                ),
                if (checkout.status == CheckoutStatus.error) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gagal membuat order: ${checkout.errorMessage}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (${cart.totalItems} item)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Rp ${cart.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _bayar,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.account_balance_wallet),
                    label: Text(
                      isSubmitting
                          ? 'Menyimpan pesanan...'
                          : _openingPayment
                              ? 'Membuka Dompet Kampus...'
                              : 'Bayar dengan Dompet Kampus',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
