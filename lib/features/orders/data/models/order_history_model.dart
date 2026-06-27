class OrderHistoryItem {
  final int productId;
  final int quantity;
  final double price;

  const OrderHistoryItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) => OrderHistoryItem(
        productId: json['product_id'] as int? ?? json['ProductID'] as int? ?? 0,
        quantity: json['quantity'] as int? ?? json['Quantity'] as int? ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
}

class OrderHistory {
  final int id;
  final String paymentReference;
  final String paymentMethod;
  final double totalAmount;
  final String status;
  final String createdAt;
  final List<OrderHistoryItem> items;

  const OrderHistory({
    required this.id,
    required this.paymentReference,
    required this.paymentMethod,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? json['Items'] as List<dynamic>? ?? [];
    return OrderHistory(
      id: json['id'] as int? ?? json['ID'] as int? ?? 0,
      paymentReference: json['payment_reference'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      items: rawItems
          .map((e) => OrderHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
