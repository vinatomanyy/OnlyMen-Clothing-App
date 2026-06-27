import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final String size;
  final String colorName;
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    required this.colorName,
    this.quantity = 1,
  });
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(Product product, String size, String colorName) {
    final index = state.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.colorName == colorName,
    );
    if (index >= 0) {
      final updated = [...state];
      updated[index].quantity++;
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(product: product, size: size, colorName: colorName),
      ];
    }
  }

  void remove(String productId, String size, String colorName) {
    state = state
        .where((item) =>
            !(item.product.id == productId &&
                item.size == size &&
                item.colorName == colorName))
        .toList();
  }

  void updateQuantity(String productId, String size, String colorName, int qty) {
    if (qty <= 0) {
      remove(productId, size, colorName);
      return;
    }
    final updated = [...state];
    final index = updated.indexWhere(
      (item) =>
          item.product.id == productId &&
          item.size == size &&
          item.colorName == colorName,
    );
    if (index >= 0) {
      updated[index].quantity = qty;
      state = updated;
    }
  }

  void clear() => state = [];

  void refreshPrices(Map<String, Product> fresh) {
    state = state.map((item) {
      final p = fresh[item.product.id];
      if (p == null || identical(p, item.product)) return item;
      return CartItem(product: p, size: item.size, colorName: item.colorName, quantity: item.quantity);
    }).toList();
  }

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});