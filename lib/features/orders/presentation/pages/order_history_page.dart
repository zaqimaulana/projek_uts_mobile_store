import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/features/orders/presentation/providers/order_history_provider.dart';
import 'package:beer_store_app/features/orders/data/models/order_history_model.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderHistoryProvider>().fetchOrders();
    });
  }

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'success' || 'paid' || 'delivered' => Colors.green,
        'pending' => Colors.orange,
        'processing' => Colors.blue,
        'shipped' => Colors.teal,
        'failed' || 'cancelled' => Colors.red,
        _ => Colors.grey,
      };

  IconData _statusIcon(String status) => switch (status.toLowerCase()) {
        'success' || 'paid' || 'delivered' =>
          Icons.check_circle_rounded,
        'pending' => Icons.hourglass_empty_rounded,
        'processing' => Icons.autorenew_rounded,
        'shipped' => Icons.local_shipping_rounded,
        'failed' => Icons.error_rounded,
        'cancelled' => Icons.cancel_rounded,
        _ => Icons.info_rounded,
      };

  String _statusLabel(String status) => switch (status.toLowerCase()) {
        'pending' => 'Menunggu',
        'processing' => 'Diproses',
        'shipped' => 'Dikirim',
        'delivered' => 'Selesai',
        'cancelled' => 'Dibatalkan',
        'success' || 'paid' => 'Berhasil',
        'failed' => 'Gagal',
        _ => status,
      };

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

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
    final provider = context.watch<OrderHistoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.fetchOrders(),
          ),
        ],
      ),
      body: switch (provider.status) {
        OrderHistoryStatus.initial || OrderHistoryStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        OrderHistoryStatus.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 64, color: scheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Gagal memuat riwayat',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchOrders(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        OrderHistoryStatus.loaded => provider.orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 80,
                        color: scheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pesanan kamu akan muncul di sini',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => provider.fetchOrders(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: provider.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final order = provider.orders[i];
                    return _OrderCard(
                      order: order,
                      statusColor: _statusColor(order.status),
                      statusIcon: _statusIcon(order.status),
                      statusLabel: _statusLabel(order.status),
                      formattedDate: _formatDate(order.createdAt),
                      formattedTotal: _fmt(order.totalAmount),
                    );
                  },
                ),
              ),
      },
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderHistory order;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final String formattedDate;
  final String formattedTotal;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.formattedDate,
    required this.formattedTotal,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: status + tanggal ──────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: scheme.outline.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 12),

            // ── Referensi + metode ────────────────────────
            if (order.paymentReference.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.tag_rounded,
                      size: 13,
                      color: scheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 5),
                  Text(
                    order.paymentReference,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            Row(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 13,
                    color: scheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 5),
                Text(
                  '${order.items.length} item',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (order.paymentMethod.isNotEmpty) ...[
                  Text(
                    '  ·  ',
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.3)),
                  ),
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 13,
                      color: scheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMethod.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── Total ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: scheme.primary,
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
