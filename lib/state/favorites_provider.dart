import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends Notifier<List<String>> {
  static const _key = 'favorites';

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? [];
    state = saved;
  }

  Future<void> toggle(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
    await prefs.setStringList(_key, state);
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);