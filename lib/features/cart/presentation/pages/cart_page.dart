import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/core/routes/app_router.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text("Cart kosong"),
            )
          : Column(
              children: [

                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];

                      return ListTile(
                        leading: Image.network(
                          item.product.imageUrl,
                          width: 50,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.local_bar),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text(
                          "Rp ${item.product.price}",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  cart.decreaseQty(
                                item.product.id,
                              ),
                            ),

                            Text(item.qty.toString()),

                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final ok = cart.increaseQty(item.product.id);
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Stok tidak mencukupi'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                /// TOTAL
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total"),
                          Text(
                            "Rp ${cart.totalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.checkout);
                          },
                          child: const Text("Checkout"),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}