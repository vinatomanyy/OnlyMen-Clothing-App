import '../state/card_provider.dart';

class Order {
  final String? id;
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final double total;
  final String? status;

  const Order({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    this.status,
  });

  Map<String, dynamic> toJson() => {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': items
            .map((e) => {
                  'product_id': e.product.id,
                  'name': e.product.name,
                  'size': e.size,
                  'color': e.colorName,
                  'quantity': e.quantity,
                  'price': e.product.price,
                })
            .toList(),
        'total': total,
      };
}
