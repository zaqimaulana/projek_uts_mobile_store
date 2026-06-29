import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/core/routes/app_router.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/features/products/data/models/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;

  ProductModel get p => widget.product;

  String _fmt(double price) {
    final s = (price * _qty).toInt().toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }

  String _fmtSingle(double price) {
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

  void _addToCart({bool goToCheckout = false}) {
    final cart = context.read<CartProvider>();
    bool ok = true;
    for (int i = 0; i < _qty; i++) {
      ok = cart.addToCart(p);
      if (!ok) break;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok tidak mencukupi'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (goToCheckout) {
      Navigator.pushNamed(context, AppRouter.checkout);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} (${_qty}x) ditambahkan ke cart'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final outOfStock = p.stock == 0;
    final primary = Theme.of(context).colorScheme.primary;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Image ──────────────────────────────
                SizedBox(
                  height: screenH * 0.42,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.local_bar,
                              size: 80, color: Colors.grey),
                        ),
                      ),
                      // Dark gradient at top for back button visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      if (outOfStock)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Text(
                              'STOK HABIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Product Info ────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Name
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Rating (static)
                      Row(
                        children: [
                          ...List.generate(
                              4,
                              (_) => const Icon(Icons.star,
                                  size: 16,
                                  color: Colors.amber)),
                          const Icon(Icons.star_half,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            '4.5  ·  128 ulasan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Price + Stock
                      Row(
                        children: [
                          Text(
                            _fmtSingle(p.price),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          const Text(' / botol',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey)),
                          const Spacer(),
                          // Stock badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.stock > 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                color: p.stock > 0
                                    ? Colors.green.shade200
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  p.stock > 0
                                      ? Icons.inventory_2_outlined
                                      : Icons.remove_circle_outline,
                                  size: 13,
                                  color: p.stock > 0
                                      ? Colors.green.shade700
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  p.stock > 0
                                      ? 'Stok: ${p.stock}'
                                      : 'Habis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.stock > 0
                                        ? Colors.green.shade700
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Description
                      const Text(
                        'Deskripsi Produk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.description.isEmpty
                            ? 'Tidak ada deskripsi.'
                            : p.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Quantity selector
                      if (!outOfStock) ...[
                        const Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _QtyButton(
                              icon: Icons.remove,
                              onTap: _qty > 1
                                  ? () =>
                                      setState(() => _qty--)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '$_qty',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QtyButton(
                              icon: Icons.add,
                              onTap: _qty < p.stock
                                  ? () =>
                                      setState(() => _qty++)
                                  : null,
                            ),
                            const Spacer(),
                            Text(
                              'Total: ${_fmt(p.price)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Back Button Overlay ─────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.black87),
              ),
            ),
          ),

          // ── Bottom Bar ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Add to Cart
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: outOfStock
                          ? null
                          : () => _addToCart(),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: outOfStock
                              ? Colors.grey
                              : primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: primary,
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined,
                          size: 18),
                      label: const Text('+ Keranjang',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Buy Now
                  Expanded(
                    child: ElevatedButton(
                      onPressed: outOfStock
                          ? null
                          : () => _addToCart(goToCheckout: true),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Beli Sekarang',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Qty Button ────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }
}
