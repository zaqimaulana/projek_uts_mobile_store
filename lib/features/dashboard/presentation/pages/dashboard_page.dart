import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/core/services/notification_provider.dart';
import 'package:beer_store_app/features/cart/presentation/pages/cart_page.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/features/orders/presentation/pages/order_history_page.dart';
import 'package:beer_store_app/features/orders/presentation/providers/order_history_provider.dart';
import 'package:beer_store_app/features/products/data/models/product_model.dart';
import 'package:beer_store_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:beer_store_app/features/products/presentation/providers/product_provider.dart';
import 'package:beer_store_app/features/profile/presentation/pages/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _query = '';
  final Set<int> _favorites = {};

  static const List<String> _titles = ['Beer Store', 'Pesanan', 'Profil'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<NotificationProvider>().addListener(_onNotification);
    });
  }

  @override
  void dispose() {
    context.read<NotificationProvider>().removeListener(_onNotification);
    super.dispose();
  }

  void _onNotification() {
    final notif = context.read<NotificationProvider>().latest;
    if (notif == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (notif.body.isNotEmpty) Text(notif.body),
          ],
        ),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () {
            context.read<NotificationProvider>().clear();
            setState(() => _selectedIndex = 1);
            context.read<OrderHistoryProvider>().fetchOrders();
          },
        ),
      ),
    );

    context.read<NotificationProvider>().clear();
  }

  void _toggleFavorite(int id) => setState(() {
        _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
      });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: _selectedIndex != 0,
        actions: _selectedIndex == 0
            ? [
                // Cart
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      ),
                    ),
                    if (cart.totalItems > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cart.totalItems.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            query: _query,
            favorites: _favorites,
            onSearch: (v) => setState(() => _query = v.toLowerCase()),
            onToggleFavorite: _toggleFavorite,
          ),
          const OrderHistoryPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          if (i == 1) context.read<OrderHistoryProvider>().fetchOrders();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_bar_outlined),
            selectedIcon: Icon(Icons.local_bar),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: false,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: const Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String query;
  final Set<int> favorites;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onToggleFavorite;

  const _HomeTab({
    required this.query,
    required this.favorites,
    required this.onSearch,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return switch (productProvider.status) {
      ProductStatus.loading || ProductStatus.initial =>
        const Center(child: CircularProgressIndicator()),
      ProductStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(productProvider.error ?? 'Error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => productProvider.fetchProducts(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ProductStatus.loaded => RefreshIndicator(
          onRefresh: () => productProvider.fetchProducts(),
          child: Column(
            children: [
              _SearchBar(onSearch: onSearch),
              Expanded(
                child: Builder(builder: (_) {
                  final filtered = productProvider.products
                      .where((p) => p.name.toLowerCase().contains(query))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Produk tidak ditemukan'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: .72,
                    ),
                    itemBuilder: (_, i) => _ProductCard(
                      product: filtered[i],
                      isFavorite: favorites.contains(filtered[i].id),
                      onFavorite: () => onToggleFavorite(filtered[i].id),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
    };
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  const _SearchBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Cari beer favorit...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final outOfStock = product.stock == 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.local_bar, size: 48),
                          ),
                        ),
                        if (outOfStock)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            alignment: Alignment.center,
                            child: const Text(
                              'Stok Habis',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rp ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              color: outOfStock ? Colors.grey : null,
                            ),
                            onPressed: outOfStock
                                ? null
                                : () {
                                    final added = cart.addToCart(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(added
                                            ? 'Ditambahkan ke cart'
                                            : 'Stok tidak mencukupi'),
                                        backgroundColor:
                                            added ? null : Colors.orange,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Favorite button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavorite,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
