import 'package:flutter/material.dart';
import 'package:beer_store_app/features/products/data/models/product_model.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Product"),
      ),

      /// BODY SCROLLABLE (FIX OVERFLOW)
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.local_bar,
                    size: 80,
                  ),
                ),
              ),
            ),

            /// CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// CATEGORY
                  Chip(
                    label: Text(product.category),
                  ),

                  const SizedBox(height: 16),

                  /// PRICE
                  Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// STOCK
                  Row(
                    children: [
                      Icon(
                        product.stock > 0
                            ? Icons.check_circle_outline
                            : Icons.remove_circle_outline,
                        size: 16,
                        color: product.stock > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.stock > 0
                            ? 'Stok: ${product.stock}'
                            : 'Stok habis',
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.grey : Colors.red,
                          fontWeight: product.stock == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// DESCRIPTION TITLE
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// DESCRIPTION TEXT
                  Text(
                    product.description.isEmpty
                        ? "No description"
                        : product.description,
                    style: const TextStyle(height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: product.stock == 0
                          ? null
                          : () {
                              final added =
                                  context.read<CartProvider>().addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(added
                                      ? 'Produk ditambahkan ke cart'
                                      : 'Stok tidak mencukupi'),
                                  backgroundColor:
                                      added ? null : Colors.orange,
                                ),
                              );
                            },
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(
                          product.stock == 0 ? 'Stok Habis' : 'Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}