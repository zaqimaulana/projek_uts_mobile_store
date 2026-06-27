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
        'success' || 'paid' => Colors.green,
        'pending' => Colors.orange,
        'failed' || 'cancelled' => Colors.red,
        _ => Colors.grey,
      };

  IconData _statusIcon(String status) => switch (status.toLowerCase()) {
        'success' || 'paid' => Icons.check_circle_outline,
        'pending' => Icons.hourglass_empty,
        'failed' => Icons.error_outline,
        'cancelled' => Icons.cancel_outlined,
        _ => Icons.info_outline,
      };

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderHistoryProvider>();

    return switch (provider.status) {
      OrderHistoryStatus.initial || OrderHistoryStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      OrderHistoryStatus.error => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(provider.errorMessage ?? 'Gagal memuat riwayat'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => provider.fetchOrders(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      OrderHistoryStatus.loaded => provider.orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada pesanan',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => provider.fetchOrders(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrderCard(
                  order: provider.orders[i],
                  statusColor: _statusColor(provider.orders[i].status),
                  statusIcon: _statusIcon(provider.orders[i].status),
                  formattedDate: _formatDate(provider.orders[i].createdAt),
                ),
              ),
            ),
    };
  }
}

class _OrderCard extends StatelessWidget {
  final OrderHistory order;
  final Color statusColor;
  final IconData statusIcon;
  final String formattedDate;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Ref: ${order.paymentReference}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} item · ${order.paymentMethod.replaceAll('_', ' ')}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'Rp ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
