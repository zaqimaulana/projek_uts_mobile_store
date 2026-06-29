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
  final Set<int> _favorites = {};

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

  void _toggleFavorite(int id) => setState(
      () => _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id));

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            favorites: _favorites,
            onToggleFavorite: _toggleFavorite,
            onOpenCart: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
            cartCount: cart.totalItems,
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final Set<int> favorites;
  final ValueChanged<int> onToggleFavorite;
  final VoidCallback onOpenCart;
  final int cartCount;

  const _HomeTab({
    required this.favorites,
    required this.onToggleFavorite,
    required this.onOpenCart,
    required this.cartCount,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _query = '';
  String _selectedCategory = 'Semua';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar ─────────────────────────────────────────
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Beer Store',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Craft Beer Terpilih',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: widget.onOpenCart,
                ),
                if (widget.cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        widget.cartCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari bir favoritmu...',
                  hintStyle:
                      const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: Colors.grey),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Content ───────────────────────────────────────────────
        switch (productProvider.status) {
          ProductStatus.loading || ProductStatus.initial =>
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ProductStatus.error => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(productProvider.error ?? 'Terjadi kesalahan'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => productProvider.fetchProducts(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ProductStatus.loaded => _ProductContent(
              products: productProvider.products,
              query: _query,
              selectedCategory: _selectedCategory,
              favorites: widget.favorites,
              onToggleFavorite: widget.onToggleFavorite,
              onSelectCategory: (c) =>
                  setState(() => _selectedCategory = c),
              onRefresh: () async => productProvider.fetchProducts(),
            ),
        },
      ],
    );
  }
}

// ── Product Content (loaded state) ───────────────────────────────────────────

class _ProductContent extends StatelessWidget {
  final List<ProductModel> products;
  final String query;
  final String selectedCategory;
  final Set<int> favorites;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<String> onSelectCategory;
  final Future<void> Function() onRefresh;

  const _ProductContent({
    required this.products,
    required this.query,
    required this.selectedCategory,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onSelectCategory,
    required this.onRefresh,
  });

  List<String> get _categories {
    final cats = products.map((p) => p.category).toSet().toList()..sort();
    return ['Semua', ...cats];
  }

  List<ProductModel> get _filtered => products.where((p) {
        final matchQ = p.name.toLowerCase().contains(query);
        final matchC =
            selectedCategory == 'Semua' || p.category == selectedCategory;
        return matchQ && matchC;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final categories = _categories;

    return SliverMainAxisGroup(
      slivers: [
        // ── Promo Banner ──────────────────────────────────────────
        SliverToBoxAdapter(child: _PromoBanner()),

        // ── Category Chips ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final sel = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () => onSelectCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal,
                          color: sel
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // ── Section Header ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCategory == 'Semua'
                      ? 'Semua Produk'
                      : selectedCategory,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${filtered.length} produk',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),

        // ── Grid / Empty ──────────────────────────────────────────
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 56, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Produk tidak ditemukan',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ProductCard(
                  product: filtered[i],
                  isFavorite: favorites.contains(filtered[i].id),
                  onFavorite: () => onToggleFavorite(filtered[i].id),
                ),
                childCount: filtered.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.67,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Promo Banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -28,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'SPECIAL OFFER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Craft Beer\nPremium Terbaik',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.local_bar, size: 52, color: Colors.white24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
  });

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
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final outOfStock = product.stock == 0;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.local_bar,
                            size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (outOfStock)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14)),
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const Text(
                          'HABIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  // Favorite
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 14,
                          color:
                              isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Category label
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info area ─────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 11, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '4.5',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '·',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          product.stock > 0
                              ? 'Stok ${product.stock}'
                              : 'Habis',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.stock > 0
                                ? Colors.green.shade600
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _fmt(product.price),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: outOfStock
                              ? null
                              : () {
                                  final ok = cart.addToCart(product);
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? '${product.name} ditambahkan ke cart'
                                          : 'Stok tidak mencukupi'),
                                      backgroundColor: ok
                                          ? Colors.green.shade700
                                          : Colors.orange,
                                      duration:
                                          const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  );
                                },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: outOfStock
                                  ? Colors.grey.shade200
                                  : primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: outOfStock
                                  ? Colors.grey.shade400
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
