import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/core/services/payment_callback_provider.dart';
import 'package:beer_store_app/core/services/payment_deeplink_service.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'payment_result_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Dengarkan callback dari Dompet Kampus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCallbackProvider>().addListener(_onCallback);
    });
  }

  void _onCallback() {
    final result = context.read<PaymentCallbackProvider>().result;
    if (result.status == PaymentCallbackStatus.none) return;

    if (result.status == PaymentCallbackStatus.success) {
      context.read<CartProvider>().clearCart();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PaymentResultPage()),
    );
  }

  Future<void> _bayar() async {
    final cart = context.read<CartProvider>();
    setState(() => _loading = true);

    final reference = PaymentDeeplinkService.generateReference();
    final berhasil = await PaymentDeeplinkService.pay(
      amount: cart.totalPrice,
      reference: reference,
      description: 'Pembelian di Beer Store (${cart.totalItems} item)',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!berhasil) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplikasi Dompet Kampus tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Jika berhasil dibuka, tunggu callback dari _onCallback
  }

  @override
  void dispose() {
    context.read<PaymentCallbackProvider>().removeListener(_onCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final item = cart.items[i];
                return ListTile(
                  leading: Image.network(
                    item.product.imageUrl,
                    width: 50,
                    errorBuilder: (_, __, ___) => const Icon(Icons.local_bar),
                  ),
                  title: Text(item.product.name),
                  subtitle: Text('${item.qty}x'),
                  trailing: Text(
                    'Rp ${item.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${cart.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _bayar,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.account_balance_wallet),
                    label: const Text('Bayar dengan Dompet Kampus'),
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
