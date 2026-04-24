import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/features/products/presentation/providers/product_provider.dart';
import 'package:beer_store_app/features/products/data/models/product_model.dart';
import 'package:beer_store_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:beer_store_app/features/auth/presentation/providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _query = '';
  final Set<int> _favorites = {}; // simpan id favorite

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  void _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, "/login");
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Beer Store"),
        centerTitle: true,

        /// LOGOUT BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),

      body: switch (productProvider.status) {
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

              /// HEADER + SEARCH
              _HeaderSection(
                onSearch: (value) {
                  setState(() {
                    _query = value.toLowerCase();
                  });
                },
              ),

              /// GRID
              Expanded(
                child: Builder(
                  builder: (_) {
                    final filteredProducts =
                        productProvider.products.where((p) {
                      return p.name
                          .toLowerCase()
                          .contains(_query);
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return const Center(
                        child: Text("Produk tidak ditemukan"),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .72,
                      ),
                      itemBuilder: (_, i) => _ProductCard(
                        product: filteredProducts[i],
                        isFavorite: _favorites.contains(
                            filteredProducts[i].id),
                        onFavorite: () =>
                            _toggleFavorite(filteredProducts[i].id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      },
    );
  }
}

/// ================= HEADER =================
class _HeaderSection extends StatelessWidget {
  final Function(String) onSearch;

  const _HeaderSection({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_bar, size: 28),
              const SizedBox(width: 8),
              Text(
                "Cold Beer",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: "Cari beer favorit...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= PRODUCT CARD =================
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [

            /// CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Rp ${product.price.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const Icon(Icons.add_shopping_cart, size: 18)
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// FAVORITE BUTTON
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onFavorite,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                        isFavorite ? Colors.red : Colors.grey,
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