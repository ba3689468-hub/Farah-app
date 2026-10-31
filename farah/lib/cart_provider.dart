import 'package:flutter_riverpod/flutter_riverpod.dart';

// نموذج المنتج داخل السلة
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, this.quantity = 1});
}

// إدارة حالة السلة
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(CartItem item) {
    final index = state.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      state[index].quantity++;
      state = [...state]; // تحديث الحالة
    } else {
      state = [...state, item];
    }
  }

  void removeFromCart(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  double get totalPrice => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

// المزود (Provider) الذي سنستدعيه في الواجهة
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
