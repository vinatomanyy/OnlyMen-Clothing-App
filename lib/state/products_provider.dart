import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../data/mock_repository.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return MockRepository.getProducts();
});

final bestsellersProvider = FutureProvider<List<Product>>((ref) async {
  final all = await MockRepository.getProducts();
  return all.where((p) => p.isBestseller).toList();
});

final newArrivalsProvider = FutureProvider<List<Product>>((ref) async {
  final all = await MockRepository.getProducts();
  return all.where((p) => p.isNew).toList();
});

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final all = await MockRepository.getProducts();
  if (category == 'all') return all;
  return all.where((p) => p.category == category).toList();
});

final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  final all = await MockRepository.getProducts();
  try {
    return all.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final all = await MockRepository.getProducts();
  return all
      .where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.brand.toLowerCase().contains(query.toLowerCase()) ||
          p.category.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'all');
