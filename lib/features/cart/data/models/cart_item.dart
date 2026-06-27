import 'package:beer_store_app/features/products/data/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int qty;

  CartItem({
    required this.product,
    this.qty = 1,
  });

  double get total => product.price * qty;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'qty': qty,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
        qty: json['qty'] as int? ?? 1,
      );
}