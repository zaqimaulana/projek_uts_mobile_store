class OrderItemRequest {
  final int productId;
  final int quantity;
  final double price;

  const OrderItemRequest({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'price': price,
      };
}

class OrderRequest {
  final List<OrderItemRequest> items;
  final double totalAmount;
  final String paymentReference;
  final String paymentMethod;

  const OrderRequest({
    required this.items,
    required this.totalAmount,
    required this.paymentReference,
    this.paymentMethod = 'dompet_kampus',
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'payment_reference': paymentReference,
        'payment_method': paymentMethod,
      };
}

class OrderResponse {
  final int id;
  final String status;
  final String? message;

  const OrderResponse({
    required this.id,
    required this.status,
    this.message,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return OrderResponse(
      id: data['id'] as int? ?? data['ID'] as int? ?? 0,
      status: data['status'] as String? ?? '',
      message: json['message'] as String?,
    );
  }
}
