import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../data/supabase_repository.dart';

final reviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, productId) async {
  return SupabaseRepository.getReviews(productId: productId);
});