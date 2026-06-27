import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../data/supabase_repository.dart';

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return SupabaseRepository.getProducts();
});

final bestsellersProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return SupabaseRepository.getBestsellers();
});

final newArrivalsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return SupabaseRepository.getNewArrivals();
});

final productsByCategoryProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, category) async {
  if (category == 'all') return SupabaseRepository.getProducts();
  return SupabaseRepository.getProductsByCategory(category);
});

final productByIdProvider =
    FutureProvider.autoDispose.family<Product?, String>((ref, id) async {
  return SupabaseRepository.getProductById(id);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return SupabaseRepository.searchProducts(query);
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');
