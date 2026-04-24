import 'package:flutter/material.dart';
import 'package:beer_store_app/features/products/data/models/product_model.dart';

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

      /// 🔥 BODY SCROLLABLE (FIX OVERFLOW)
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
                  Text(
                    "Stock : ${product.stock}",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Added to cart"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text("Add to Cart"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
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